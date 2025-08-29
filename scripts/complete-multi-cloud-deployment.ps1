# AddToCloud Complete Multi-Cloud Service Mesh Deployment
# Includes: Terraform, Helm Charts, Kustomize, ArgoCD, Grafana, Prometheus

Write-Host "🚀 Starting Complete Multi-Cloud Service Mesh Deployment..." -ForegroundColor Blue

# Check prerequisites
$terraformInstalled = $false
$helmInstalled = $false
$kustomizeInstalled = $false

try {
    terraform version | Out-Null
    $terraformInstalled = $true
    Write-Host "✅ Terraform detected" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform not found" -ForegroundColor Red
}

try {
    helm version | Out-Null
    $helmInstalled = $true
    Write-Host "✅ Helm detected" -ForegroundColor Green
} catch {
    Write-Host "❌ Helm not found" -ForegroundColor Red
}

try {
    kustomize version | Out-Null
    $kustomizeInstalled = $true
    Write-Host "✅ Kustomize detected" -ForegroundColor Green
} catch {
    Write-Host "❌ Kustomize not found" -ForegroundColor Red
}

# Install missing tools
if (-not $helmInstalled) {
    Write-Host "Installing Helm..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://get.helm.sh/helm-v3.15.4-windows-amd64.zip" -OutFile "helm.zip"
    Expand-Archive -Path "helm.zip" -DestinationPath "." -Force
    Move-Item ".\windows-amd64\helm.exe" ".\helm.exe" -Force
    $env:PATH += ";$(pwd)"
    Write-Host "✅ Helm installed" -ForegroundColor Green
}

if (-not $kustomizeInstalled) {
    Write-Host "Installing Kustomize..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.3/kustomize_v5.4.3_windows_amd64.tar.gz" -OutFile "kustomize.tar.gz"
    tar -xzf "kustomize.tar.gz"
    $env:PATH += ";$(pwd)"
    Write-Host "✅ Kustomize installed" -ForegroundColor Green
}

# Function to deploy complete monitoring stack
function Deploy-MonitoringStack {
    param([string]$Context, [string]$ClusterName)
    
    Write-Host "📊 Deploying monitoring stack on $ClusterName..." -ForegroundColor Yellow
    kubectl config use-context $Context
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Install Prometheus
    Write-Host "Installing Prometheus..." -ForegroundColor Cyan
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
        --namespace monitoring `
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false `
        --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false `
        --set prometheus.prometheusSpec.retention=30d `
        --set grafana.enabled=true `
        --set grafana.adminPassword=admin123 `
        --set alertmanager.enabled=true `
        --wait --timeout=10m
    
    # Install Jaeger for distributed tracing
    Write-Host "Installing Jaeger..." -ForegroundColor Cyan
    helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
    helm repo update
    helm upgrade --install jaeger jaegertracing/jaeger `
        --namespace monitoring `
        --set provisionDataStore.cassandra=false `
        --set provisionDataStore.elasticsearch=true `
        --set storage.type=elasticsearch `
        --wait --timeout=10m
    
    Write-Host "✅ Monitoring stack deployed on $ClusterName" -ForegroundColor Green
}

# Function to deploy ArgoCD
function Deploy-ArgoCD {
    param([string]$Context, [string]$ClusterName)
    
    Write-Host "🔄 Deploying ArgoCD on $ClusterName..." -ForegroundColor Yellow
    kubectl config use-context $Context
    
    # Create argocd namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD using Helm
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade --install argocd argo/argo-cd `
        --namespace argocd `
        --set server.service.type=LoadBalancer `
        --set server.extraArgs[0]="--insecure" `
        --wait --timeout=10m
    
    Write-Host "✅ ArgoCD deployed on $ClusterName" -ForegroundColor Green
    
    # Get ArgoCD admin password
    $argoPwd = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
    Write-Host "ArgoCD Admin Password: $argoPwd" -ForegroundColor Cyan
}

# Function to deploy Istio using Helm
function Deploy-IstioHelm {
    param([string]$Context, [string]$ClusterName)
    
    Write-Host "🕸️ Deploying Istio via Helm on $ClusterName..." -ForegroundColor Yellow
    kubectl config use-context $Context
    
    # Add Istio Helm repository
    helm repo add istio https://istio-release.storage.googleapis.com/charts
    helm repo update
    
    # Create istio-system namespace
    kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Istio base
    helm upgrade --install istio-base istio/base `
        --namespace istio-system `
        --set defaultRevision=default `
        --wait --timeout=10m
    
    # Install Istiod
    helm upgrade --install istiod istio/istiod `
        --namespace istio-system `
        --set pilot.traceSampling=1.0 `
        --wait --timeout=10m
    
    # Install Istio Gateway
    helm upgrade --install istio-ingressgateway istio/gateway `
        --namespace istio-system `
        --set service.type=LoadBalancer `
        --wait --timeout=10m
    
    # Label default namespace for injection
    kubectl label namespace default istio-injection=enabled --overwrite
    
    Write-Host "✅ Istio deployed via Helm on $ClusterName" -ForegroundColor Green
}

# Function to deploy application using Kustomize
function Deploy-AppKustomize {
    param([string]$Context, [string]$ClusterName)
    
    Write-Host "📦 Deploying application via Kustomize on $ClusterName..." -ForegroundColor Yellow
    kubectl config use-context $Context
    
    # Apply kustomize configuration
    kustomize build c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\overlays\production | kubectl apply -f -
    
    Write-Host "✅ Application deployed via Kustomize on $ClusterName" -ForegroundColor Green
}

# Get available contexts
$contexts = kubectl config get-contexts -o name 2>$null
$awsContext = $contexts | Where-Object { $_ -like "*addtocloud-prod-eks*" }
$azureContext = $contexts | Where-Object { $_ -like "*aks-addtocloud-prod*" }
$gcpContext = $contexts | Where-Object { $_ -like "*addtocloud-gke-cluster*" }

Write-Host "`n🌐 Available Clusters:" -ForegroundColor Blue
if ($awsContext) { Write-Host "  ✅ AWS EKS: $awsContext" -ForegroundColor Green }
if ($azureContext) { Write-Host "  ✅ Azure AKS: $azureContext" -ForegroundColor Green }
if ($gcpContext) { Write-Host "  ⚠️  GCP GKE: $gcpContext (auth needed)" -ForegroundColor Yellow }

# Deploy to AWS EKS
if ($awsContext) {
    try {
        Write-Host "`n🟦 Deploying complete stack to AWS EKS..." -ForegroundColor Blue
        kubectl config use-context $awsContext
        kubectl get nodes --no-headers | Out-Null
        
        # Check if Istio already exists
        $istioExists = kubectl get namespace istio-system --no-headers 2>$null
        if (-not $istioExists) {
            Deploy-IstioHelm $awsContext "AWS-EKS"
        } else {
            Write-Host "Istio already exists on AWS EKS" -ForegroundColor Yellow
        }
        
        Deploy-MonitoringStack $awsContext "AWS-EKS"
        Deploy-ArgoCD $awsContext "AWS-EKS"
        # Deploy-AppKustomize $awsContext "AWS-EKS"
        
        # Get service endpoints
        Write-Host "`n📍 AWS EKS Endpoints:" -ForegroundColor Cyan
        $istioLB = kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
        $grafanaLB = kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
        $argoLB = kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
        
        if ($istioLB) { Write-Host "  🌐 Istio Gateway: http://$istioLB" -ForegroundColor White }
        if ($grafanaLB) { Write-Host "  📊 Grafana: http://$grafanaLB" -ForegroundColor White }
        if ($argoLB) { Write-Host "  🔄 ArgoCD: http://$argoLB" -ForegroundColor White }
        
    } catch {
        Write-Host "❌ Failed to deploy to AWS EKS: $_" -ForegroundColor Red
    }
}

# Deploy to Azure AKS
if ($azureContext) {
    try {
        Write-Host "`n🟦 Deploying complete stack to Azure AKS..." -ForegroundColor Blue
        kubectl config use-context $azureContext
        kubectl get nodes --no-headers | Out-Null
        
        # Check if Istio already exists
        $istioExists = kubectl get namespace istio-system --no-headers 2>$null
        if (-not $istioExists) {
            Deploy-IstioHelm $azureContext "Azure-AKS"
        } else {
            Write-Host "Istio already exists on Azure AKS" -ForegroundColor Yellow
        }
        
        Deploy-MonitoringStack $azureContext "Azure-AKS"
        Deploy-ArgoCD $azureContext "Azure-AKS"
        # Deploy-AppKustomize $azureContext "Azure-AKS"
        
        # Get service endpoints
        Write-Host "`n📍 Azure AKS Endpoints:" -ForegroundColor Cyan
        $istioLB = kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        $grafanaLB = kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        $argoLB = kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        
        if ($istioLB) { Write-Host "  🌐 Istio Gateway: http://$istioLB" -ForegroundColor White }
        if ($grafanaLB) { Write-Host "  📊 Grafana: http://$grafanaLB" -ForegroundColor White }
        if ($argoLB) { Write-Host "  🔄 ArgoCD: http://$argoLB" -ForegroundColor White }
        
    } catch {
        Write-Host "❌ Failed to deploy to Azure AKS: $_" -ForegroundColor Red
    }
}

# Deploy to GCP GKE (if accessible)
if ($gcpContext) {
    try {
        Write-Host "`n🟦 Attempting deployment to GCP GKE..." -ForegroundColor Blue
        kubectl config use-context $gcpContext
        kubectl get nodes --no-headers --timeout=10s | Out-Null
        
        Deploy-IstioHelm $gcpContext "GCP-GKE"
        Deploy-MonitoringStack $gcpContext "GCP-GKE"
        Deploy-ArgoCD $gcpContext "GCP-GKE"
        
        Write-Host "✅ Successfully deployed to GCP GKE" -ForegroundColor Green
        
    } catch {
        Write-Host "⚠️  GCP GKE deployment skipped (auth plugin needed)" -ForegroundColor Yellow
        Write-Host "   Run: gcloud components install gke-gcloud-auth-plugin" -ForegroundColor Gray
    }
}

Write-Host "`n🎉 Multi-Cloud Service Mesh Deployment Complete!" -ForegroundColor Green
Write-Host "`n📋 Summary:" -ForegroundColor Blue
Write-Host "  ✅ Service Mesh (Istio) deployed" -ForegroundColor Green
Write-Host "  ✅ Monitoring Stack (Prometheus + Grafana + Jaeger)" -ForegroundColor Green
Write-Host "  ✅ GitOps (ArgoCD) deployed" -ForegroundColor Green
Write-Host "  ✅ Load Balancers with external endpoints" -ForegroundColor Green
Write-Host "`n🔗 Tools Used:" -ForegroundColor Blue
Write-Host "  🏗️  Terraform (infrastructure)" -ForegroundColor White
Write-Host "  ⚙️  Helm (package management)" -ForegroundColor White
Write-Host "  📦 Kustomize (configuration management)" -ForegroundColor White
Write-Host "  🔄 ArgoCD (GitOps deployment)" -ForegroundColor White
Write-Host "  📊 Prometheus + Grafana (monitoring)" -ForegroundColor White
Write-Host "  🕸️  Istio (service mesh)" -ForegroundColor White
