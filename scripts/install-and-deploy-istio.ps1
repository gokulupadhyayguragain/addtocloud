# Install Istio CLI and Deploy Service Mesh
# This script downloads and installs Istio, then deploys it to your clusters

param(
    [string]$IstioVersion = "1.19.5"
)

Write-Host "🌐 Installing Istio CLI and deploying service mesh..." -ForegroundColor Blue

# Download and install Istio CLI
$istioPath = "$env:USERPROFILE\.istio"
$istioBin = "$istioPath\bin"

if (-not (Test-Path $istioPath)) {
    New-Item -ItemType Directory -Path $istioPath -Force | Out-Null
}

if (-not (Test-Path "$istioBin\istioctl.exe")) {
    Write-Host "📥 Downloading Istio $IstioVersion..." -ForegroundColor Yellow
    
    $downloadUrl = "https://github.com/istio/istio/releases/download/$IstioVersion/istio-$IstioVersion-win.zip"
    $zipPath = "$istioPath\istio-$IstioVersion-win.zip"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $istioPath -Force
        
        # Move files to the correct location
        if (Test-Path "$istioPath\istio-$IstioVersion\bin\istioctl.exe") {
            if (-not (Test-Path $istioBin)) {
                New-Item -ItemType Directory -Path $istioBin -Force | Out-Null
            }
            Copy-Item "$istioPath\istio-$IstioVersion\bin\istioctl.exe" "$istioBin\istioctl.exe" -Force
        }
        
        Remove-Item $zipPath -Force
        Write-Host "✅ Istio CLI installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to download Istio: $_" -ForegroundColor Red
        exit 1
    }
}

# Add Istio to PATH for this session
$env:PATH += ";$istioBin"

# Verify installation
try {
    $istioVersion = & "$istioBin\istioctl.exe" version --client --short
    Write-Host "✅ Istio CLI version: $istioVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to verify Istio installation" -ForegroundColor Red
    exit 1
}

# Now deploy Istio to clusters
Write-Host "`n🚀 Deploying Istio to Kubernetes clusters..." -ForegroundColor Blue

# Get available contexts
$contexts = kubectl config get-contexts -o name
$awsContext = $contexts | Where-Object { $_ -like "*addtocloud-prod-eks*" }
$azureContext = $contexts | Where-Object { $_ -like "*aks-addtocloud-prod*" }

# Deploy to AWS EKS
if ($awsContext) {
    Write-Host "📦 Installing Istio on AWS EKS..." -ForegroundColor Yellow
    kubectl config use-context $awsContext
    
    # Check connectivity
    $nodes = kubectl get nodes --timeout=10s 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AWS EKS cluster is accessible" -ForegroundColor Green
        
        # Install Istio
        & "$istioBin\istioctl.exe" install --set values.pilot.env.CLUSTER_ID=aws-primary -y
        kubectl label namespace default istio-injection=enabled --overwrite
        
        # Deploy Gateway
        $gatewayYaml = @"
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
"@
        
        $gatewayYaml | kubectl apply -f -
        Write-Host "✅ Istio deployed to AWS EKS" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Cannot access AWS EKS cluster" -ForegroundColor Red
    }
}

# Deploy to Azure AKS
if ($azureContext) {
    Write-Host "📦 Installing Istio on Azure AKS..." -ForegroundColor Yellow
    kubectl config use-context $azureContext
    
    # Check connectivity
    $nodes = kubectl get nodes --timeout=10s 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure AKS cluster is accessible" -ForegroundColor Green
        
        # Install Istio
        & "$istioBin\istioctl.exe" install --set values.pilot.env.CLUSTER_ID=azure-secondary -y
        kubectl label namespace default istio-injection=enabled --overwrite
        
        # Deploy Gateway (same as AWS)
        $gatewayYaml | kubectl apply -f -
        Write-Host "✅ Istio deployed to Azure AKS" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Cannot access Azure AKS cluster" -ForegroundColor Red
    }
}

# Get load balancer endpoints
Write-Host "`n🌐 Load Balancer Endpoints:" -ForegroundColor Blue

if ($awsContext) {
    Write-Host "AWS EKS:" -ForegroundColor Yellow
    kubectl --context=$awsContext get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    Write-Host ""
}

if ($azureContext) {
    Write-Host "Azure AKS:" -ForegroundColor Yellow
    kubectl --context=$azureContext get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    Write-Host ""
}

Write-Host "`n🎉 Service mesh deployment completed!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Blue
Write-Host "  1. Deploy your applications to the clusters"
Write-Host "  2. Configure DNS in Cloudflare to point to the load balancers"
Write-Host "  3. Set up SSL certificates"
Write-Host "  4. Configure monitoring and observability"
