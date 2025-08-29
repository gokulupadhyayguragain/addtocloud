# Multi-Cloud Istio Service Mesh Deployment Script for Windows PowerShell
# Deploys Istio across AWS EKS and Azure AKS clusters

param(
    [switch]$SkipInstallation = $false,
    [switch]$VerifyOnly = $false
)

# Cluster contexts
$AWS_CONTEXT = "arn:aws:eks:us-west-2:741448922544:cluster/addtocloud-prod-eks"
$AZURE_CONTEXT = "aks-addtocloud-prod"
$GCP_CONTEXT = "gke_static-operator-469115-h1_us-central1-a_addtocloud-gke-cluster"

# Helper functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-ClusterContext {
    param([string]$Context)
    
    try {
        kubectl config get-contexts $Context 2>$null
        return $true
    }
    catch {
        return $false
    }
}

function Test-ClusterConnectivity {
    param([string]$Context)
    
    try {
        kubectl --context=$Context get nodes --timeout=10s 2>$null
        return $true
    }
    catch {
        return $false
    }
}

function Install-IstioOnCluster {
    param(
        [string]$Context,
        [string]$ClusterId,
        [string]$ClusterName
    )
    
    Write-ColorOutput "📦 Installing Istio on $ClusterName..." "Yellow"
    
    # Switch to the cluster context
    kubectl config use-context $Context
    
    # Check if cluster is accessible
    if (-not (Test-ClusterConnectivity $Context)) {
        Write-ColorOutput "❌ Cannot access cluster $ClusterName" "Red"
        return $false
    }
    
    Write-ColorOutput "✅ Cluster $ClusterName is accessible" "Green"
    
    # Install Istio
    $istioInstallArgs = @(
        "install"
        "--set", "values.pilot.env.CLUSTER_ID=$ClusterId"
        "--set", "values.istiodRemote.enabled=false"
        "--set", "values.pilot.env.ENABLE_CROSS_CLUSTER_WORKLOAD_ENTRY=true"
        "--set", "values.pilot.env.PILOT_ENABLE_REMOTE_JWKS=true"
        "--set", "meshConfig.trustDomain=addtocloud.local"
        "--set", "meshConfig.defaultConfig.proxyStatsMatcher.inclusionRegexps=.*outlier_detection.*"
        "--set", "meshConfig.defaultConfig.proxyStatsMatcher.exclusionRegexps=.*osconfig.*"
        "-y"
    )
    
    & istioctl @istioInstallArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Failed to install Istio on $ClusterName" "Red"
        return $false
    }
    
    # Label the default namespace for Istio injection
    kubectl label namespace default istio-injection=enabled --overwrite
    
    # Wait for Istio to be ready
    Write-ColorOutput "⏳ Waiting for Istio to be ready on $ClusterName..." "Yellow"
    kubectl wait --for=condition=available --timeout=300s deployment/istiod -n istio-system
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Istio installed successfully on $ClusterName" "Green"
        return $true
    } else {
        Write-ColorOutput "❌ Istio installation timed out on $ClusterName" "Red"
        return $false
    }
}

function Deploy-IstioGateway {
    param(
        [string]$Context,
        [string]$ClusterName
    )
    
    Write-ColorOutput "🌐 Deploying Istio Gateway on $ClusterName..." "Yellow"
    
    $gatewayManifest = @"
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: addtocloud-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
    tls:
      httpsRedirect: true
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: addtocloud-tls
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: addtocloud-api
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - istio-system/addtocloud-gateway
  http:
  - match:
    - uri:
        prefix: "/api"
    route:
    - destination:
        host: addtocloud-api
        port:
          number: 8080
  - match:
    - uri:
        prefix: "/health"
    route:
    - destination:
        host: addtocloud-api
        port:
          number: 8080
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: addtocloud-frontend
        port:
          number: 3000
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: addtocloud-api
  namespace: default
spec:
  host: addtocloud-api
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 10
    circuitBreaker:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
"@

    $gatewayManifest | kubectl --context=$Context apply -f -
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Istio Gateway deployed on $ClusterName" "Green"
        return $true
    } else {
        Write-ColorOutput "❌ Failed to deploy Istio Gateway on $ClusterName" "Red"
        return $false
    }
}

function Setup-MulticlusterNetworking {
    Write-ColorOutput "🔗 Setting up multi-cluster networking..." "Yellow"
    
    # Create istio-system namespace on all clusters if not exists
    @($AWS_CONTEXT, $AZURE_CONTEXT) | ForEach-Object {
        kubectl --context=$_ create namespace istio-system --dry-run=client -o yaml | kubectl --context=$_ apply -f -
    }
    
    # Create cross-cluster secrets
    Write-ColorOutput "📝 Creating cross-cluster secrets..." "Yellow"
    
    try {
        # AWS to Azure
        $awsSecret = istioctl x create-remote-secret --context=$AWS_CONTEXT --name=aws-cluster
        $awsSecret | kubectl apply --context=$AZURE_CONTEXT -f -
        
        # Azure to AWS
        $azureSecret = istioctl x create-remote-secret --context=$AZURE_CONTEXT --name=azure-cluster
        $azureSecret | kubectl apply --context=$AWS_CONTEXT -f -
        
        Write-ColorOutput "✅ Multi-cluster networking configured" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "❌ Failed to configure multi-cluster networking: $_" "Red"
        return $false
    }
}

function Get-LoadBalancerEndpoints {
    Write-ColorOutput "`n🌐 Load Balancer Endpoints:" "Blue"
    
    if (Test-ClusterContext $AWS_CONTEXT) {
        Write-ColorOutput "AWS EKS:" "Yellow"
        $awsEndpoint = kubectl --context=$AWS_CONTEXT get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
        if ($awsEndpoint) {
            Write-Host "  $awsEndpoint"
        } else {
            Write-Host "  Pending..." -ForegroundColor Yellow
        }
    }
    
    if (Test-ClusterContext $AZURE_CONTEXT) {
        Write-ColorOutput "Azure AKS:" "Yellow"
        $azureEndpoint = kubectl --context=$AZURE_CONTEXT get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($azureEndpoint) {
            Write-Host "  $azureEndpoint"
        } else {
            Write-Host "  Pending..." -ForegroundColor Yellow
        }
    }
}

function Test-Prerequisites {
    Write-ColorOutput "🔍 Checking prerequisites..." "Yellow"
    
    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "❌ kubectl is not installed or not in PATH" "Red"
        return $false
    }
    
    # Check istioctl
    if (-not (Get-Command istioctl -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "❌ istioctl is not installed or not in PATH" "Red"
        Write-ColorOutput "💡 Install Istio CLI: https://istio.io/latest/docs/setup/getting-started/#download" "Yellow"
        return $false
    }
    
    Write-ColorOutput "✅ Prerequisites check passed" "Green"
    return $true
}

function Verify-Installation {
    param(
        [string]$Context,
        [string]$ClusterName
    )
    
    Write-ColorOutput "🔍 Verifying Istio installation on $ClusterName..." "Yellow"
    
    Write-ColorOutput "Istio system pods:" "Cyan"
    kubectl --context=$Context get pods -n istio-system
    
    Write-ColorOutput "`nIstio gateway:" "Cyan"
    kubectl --context=$Context get gateway -A
    
    Write-ColorOutput "`nVirtual services:" "Cyan"
    kubectl --context=$Context get virtualservice -A
    
    Write-ColorOutput "`nLoad balancer details:" "Cyan"
    kubectl --context=$Context get svc istio-ingressgateway -n istio-system
    
    Write-ColorOutput "✅ Verification complete for $ClusterName" "Green"
}

# Main execution
function Main {
    Write-ColorOutput "🌩️ Starting Multi-Cloud Istio Service Mesh Deployment" "Blue"
    Write-ColorOutput "=======================================================" "Blue"
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Check cluster contexts
    Write-ColorOutput "🔍 Checking cluster contexts..." "Yellow"
    
    $awsAvailable = Test-ClusterContext $AWS_CONTEXT
    $azureAvailable = Test-ClusterContext $AZURE_CONTEXT
    
    if ($awsAvailable) {
        Write-ColorOutput "✅ AWS EKS context found" "Green"
        $awsConnectable = Test-ClusterConnectivity $AWS_CONTEXT
        if ($awsConnectable) {
            Write-ColorOutput "✅ AWS EKS cluster is accessible" "Green"
        } else {
            Write-ColorOutput "⚠️ AWS EKS cluster context found but not accessible" "Yellow"
            $awsAvailable = $false
        }
    } else {
        Write-ColorOutput "❌ AWS EKS context not found" "Red"
    }
    
    if ($azureAvailable) {
        Write-ColorOutput "✅ Azure AKS context found" "Green"
        $azureConnectable = Test-ClusterConnectivity $AZURE_CONTEXT
        if ($azureConnectable) {
            Write-ColorOutput "✅ Azure AKS cluster is accessible" "Green"
        } else {
            Write-ColorOutput "⚠️ Azure AKS cluster context found but not accessible" "Yellow"
            $azureAvailable = $false
        }
    } else {
        Write-ColorOutput "❌ Azure AKS context not found" "Red"
    }
    
    if (-not $awsAvailable -and -not $azureAvailable) {
        Write-ColorOutput "❌ No accessible clusters found" "Red"
        exit 1
    }
    
    if ($VerifyOnly) {
        if ($awsAvailable) {
            Verify-Installation $AWS_CONTEXT "AWS EKS"
        }
        if ($azureAvailable) {
            Verify-Installation $AZURE_CONTEXT "Azure AKS"
        }
        return
    }
    
    # Install Istio on available clusters
    $installations = @()
    
    if ($awsAvailable -and -not $SkipInstallation) {
        $awsInstalled = Install-IstioOnCluster $AWS_CONTEXT "aws-primary" "AWS EKS"
        if ($awsInstalled) {
            Deploy-IstioGateway $AWS_CONTEXT "AWS EKS"
            $installations += "AWS"
        }
    }
    
    if ($azureAvailable -and -not $SkipInstallation) {
        $azureInstalled = Install-IstioOnCluster $AZURE_CONTEXT "azure-secondary" "Azure AKS"
        if ($azureInstalled) {
            Deploy-IstioGateway $AZURE_CONTEXT "Azure AKS"
            $installations += "Azure"
        }
    }
    
    # Setup multi-cluster networking if both clusters are available
    if ($awsAvailable -and $azureAvailable -and $installations.Count -eq 2) {
        Setup-MulticlusterNetworking
    }
    
    # Verify installations
    if ($awsAvailable) {
        Write-ColorOutput "`n🔍 Verifying AWS EKS installation..." "Blue"
        Verify-Installation $AWS_CONTEXT "AWS EKS"
    }
    
    if ($azureAvailable) {
        Write-ColorOutput "`n🔍 Verifying Azure AKS installation..." "Blue"
        Verify-Installation $AZURE_CONTEXT "Azure AKS"
    }
    
    Write-ColorOutput "`n🎉 Multi-cloud service mesh deployment completed!" "Green"
    Write-ColorOutput "📋 Next steps:" "Blue"
    Write-Host "  1. Deploy your applications with Istio sidecar injection"
    Write-Host "  2. Configure SSL certificates for HTTPS"
    Write-Host "  3. Set up monitoring with Prometheus and Grafana"
    Write-Host "  4. Configure Cloudflare load balancing"
    
    # Display load balancer endpoints
    Get-LoadBalancerEndpoints
}

# Execute main function
Main
