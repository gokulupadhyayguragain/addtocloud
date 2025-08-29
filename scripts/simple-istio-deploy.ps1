# Simple Istio Service Mesh Deployment for AddToCloud
# This script installs Istio on available Kubernetes clusters

Write-Host "Installing Istio Service Mesh..." -ForegroundColor Blue

# Check if kubectl is available
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Get available contexts
$contexts = kubectl config get-contexts -o name 2>$null
$awsContext = $contexts | Where-Object { $_ -like "*addtocloud-prod-eks*" }
$azureContext = $contexts | Where-Object { $_ -like "*aks-addtocloud-prod*" }

Write-Host "Available clusters:" -ForegroundColor Yellow
if ($awsContext) { Write-Host "  - AWS EKS: $awsContext" -ForegroundColor Green }
if ($azureContext) { Write-Host "  - Azure AKS: $azureContext" -ForegroundColor Green }

# Check if Istio is already installed
$istioInstalled = $false
try {
    istioctl version 2>$null
    $istioInstalled = $true
    Write-Host "Istio CLI is already available" -ForegroundColor Green
}
catch {
    Write-Host "Istio CLI not found, will use kubectl to install" -ForegroundColor Yellow
}

# Function to install Istio using kubectl (without istioctl)
function Install-IstioWithKubectl {
    param([string]$Context, [string]$ClusterName)
    
    Write-Host "Installing Istio on $ClusterName using kubectl..." -ForegroundColor Yellow
    kubectl config use-context $Context
    
    # Create istio-system namespace
    kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Istio base
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/manifests/charts/base/crds/crd-all.gen.yaml
    
    # Install Istiod
    $istiodManifest = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: istiod
  namespace: istio-system
  labels:
    app: istiod
    release: istiod
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
  namespace: istio-system
  labels:
    app: istiod
    istio.io/rev: default
    install.operator.istio.io/owning-resource: unknown
    operator.istio.io/component: Pilot
    release: istiod
spec:
  selector:
    matchLabels:
      app: istiod
      istio.io/rev: default
  template:
    metadata:
      labels:
        app: istiod
        istio.io/rev: default
      annotations:
        prometheus.io/port: "15014"
        prometheus.io/scrape: "true"
        sidecar.istio.io/inject: "false"
    spec:
      serviceAccountName: istiod
      containers:
      - name: discovery
        image: docker.io/istio/pilot:1.19.5
        ports:
        - containerPort: 8080
          protocol: TCP
        - containerPort: 15010
          protocol: TCP
        - containerPort: 15011
          protocol: TCP
        env:
        - name: CLUSTER_ID
          value: "$ClusterName"
        - name: PILOT_TRACE_SAMPLING
          value: "1"
        - name: PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION
          value: "true"
        resources:
          requests:
            cpu: 500m
            memory: 2048Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: config-volume
          mountPath: /etc/istio/config
        - name: istio-token
          mountPath: /var/run/secrets/tokens
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: istio
      - name: istio-token
        projected:
          sources:
          - serviceAccountToken:
              path: istio-token
              expirationSeconds: 43200
              audience: istio-ca
---
apiVersion: v1
kind: Service
metadata:
  name: istiod
  namespace: istio-system
  labels:
    app: istiod
    istio.io/rev: default
    release: istiod
spec:
  ports:
  - port: 15010
    name: grpc-xds
    protocol: TCP
  - port: 15011
    name: https-dns
    protocol: TCP
  - port: 15014
    name: http-monitoring
    protocol: TCP
  - port: 443
    name: https-webhook
    targetPort: 15017
    protocol: TCP
  selector:
    app: istiod
    istio.io/rev: default
"@
    
    $istiodManifest | kubectl apply -f -
    
    # Install Istio ingress gateway
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/manifests/charts/gateways/istio-ingress/templates/deployment.yaml
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/manifests/charts/gateways/istio-ingress/templates/service.yaml
    
    # Label default namespace for injection
    kubectl label namespace default istio-injection=enabled --overwrite
    
    Write-Host "Istio installation completed on $ClusterName" -ForegroundColor Green
}

# Function to deploy sample application and gateway
function Deploy-SampleApp {
    param([string]$Context, [string]$ClusterName)
    
    Write-Host "Deploying sample application on $ClusterName..." -ForegroundColor Yellow
    kubectl config use-context $Context
    
    $sampleApp = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addtocloud-api
  labels:
    app: addtocloud-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: addtocloud-api
  template:
    metadata:
      labels:
        app: addtocloud-api
    spec:
      containers:
      - name: api
        image: nginx:latest
        ports:
        - containerPort: 80
        env:
        - name: CLUSTER_NAME
          value: "$ClusterName"
---
apiVersion: v1
kind: Service
metadata:
  name: addtocloud-api
  labels:
    app: addtocloud-api
spec:
  ports:
  - port: 8080
    targetPort: 80
    name: http
  selector:
    app: addtocloud-api
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: addtocloud-gateway
  namespace: default
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
  - addtocloud-gateway
  http:
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: addtocloud-api
        port:
          number: 8080
"@
    
    $sampleApp | kubectl apply -f -
    Write-Host "Sample application deployed on $ClusterName" -ForegroundColor Green
}

# Deploy to AWS EKS
if ($awsContext) {
    try {
        Write-Host "`nDeploying to AWS EKS..." -ForegroundColor Blue
        kubectl config use-context $awsContext
        kubectl get nodes --timeout=10s | Out-Null
        
        Install-IstioWithKubectl $awsContext "aws-primary"
        Deploy-SampleApp $awsContext "AWS-EKS"
        
        Write-Host "Getting AWS load balancer endpoint..." -ForegroundColor Yellow
        Start-Sleep 30  # Wait for load balancer
        $awsEndpoint = kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
        if ($awsEndpoint) {
            Write-Host "AWS EKS Endpoint: $awsEndpoint" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to deploy to AWS EKS: $_" -ForegroundColor Red
    }
}

# Deploy to Azure AKS
if ($azureContext) {
    try {
        Write-Host "`nDeploying to Azure AKS..." -ForegroundColor Blue
        kubectl config use-context $azureContext
        kubectl get nodes --timeout=10s | Out-Null
        
        Install-IstioWithKubectl $azureContext "azure-secondary"
        Deploy-SampleApp $azureContext "Azure-AKS"
        
        Write-Host "Getting Azure load balancer endpoint..." -ForegroundColor Yellow
        Start-Sleep 30  # Wait for load balancer
        $azureEndpoint = kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($azureEndpoint) {
            Write-Host "Azure AKS Endpoint: $azureEndpoint" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to deploy to Azure AKS: $_" -ForegroundColor Red
    }
}

Write-Host "`nService mesh deployment completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Blue
Write-Host "1. Configure Cloudflare DNS to point to the load balancer endpoints"
Write-Host "2. Set up SSL certificates"
Write-Host "3. Deploy your actual applications"
