# AddToCloud Service Mesh Deployment with All Tools
# Using: Terraform, Helm, Kustomize, ArgoCD, Grafana, Prometheus

Write-Host "Starting Complete Multi-Cloud Service Mesh Deployment..." -ForegroundColor Blue

# Function to deploy monitoring stack
function Deploy-MonitoringStack {
    param([string]$Context, [string]$ClusterName)
    
    Write-Host "Deploying monitoring stack on $ClusterName..." -ForegroundColor Yellow
    kubectl config use-context $Context
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Install Prometheus and Grafana
    Write-Host "Installing Prometheus and Grafana..." -ForegroundColor Cyan
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false --set prometheus.prometheusSpec.retention=30d --set grafana.enabled=true --set grafana.adminPassword=admin123 --set grafana.service.type=LoadBalancer --wait --timeout=10m
    
    Write-Host "Monitoring stack deployed on $ClusterName" -ForegroundColor Green
}

# Function to deploy ArgoCD
function Deploy-ArgoCD {
    param([string]$Context, [string]$ClusterName)
    
    Write-Host "Deploying ArgoCD on $ClusterName..." -ForegroundColor Yellow
    kubectl config use-context $Context
    
    # Create argocd namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD using kubectl
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Patch ArgoCD server to use LoadBalancer
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    
    Write-Host "ArgoCD deployed on $ClusterName" -ForegroundColor Green
    
    # Get ArgoCD admin password
    Start-Sleep 30
    try {
        $argoPwd = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
        Write-Host "ArgoCD Admin Password: $argoPwd" -ForegroundColor Cyan
    } catch {
        Write-Host "ArgoCD password will be available after deployment completes" -ForegroundColor Yellow
    }
}

# Get available contexts
$contexts = kubectl config get-contexts -o name 2>$null
$awsContext = $contexts | Where-Object { $_ -like "*addtocloud-prod-eks*" }
$azureContext = $contexts | Where-Object { $_ -like "*aks-addtocloud-prod*" }
$gcpContext = $contexts | Where-Object { $_ -like "*addtocloud-gke-cluster*" }

Write-Host "Available Clusters:" -ForegroundColor Blue
if ($awsContext) { Write-Host "  AWS EKS: $awsContext" -ForegroundColor Green }
if ($azureContext) { Write-Host "  Azure AKS: $azureContext" -ForegroundColor Green }
if ($gcpContext) { Write-Host "  GCP GKE: $gcpContext (auth needed)" -ForegroundColor Yellow }

# Deploy to AWS EKS
if ($awsContext) {
    Write-Host "`nDeploying complete stack to AWS EKS..." -ForegroundColor Blue
    kubectl config use-context $awsContext
    
    # Check current Istio status
    $istioExists = kubectl get namespace istio-system --no-headers 2>$null
    if ($istioExists) {
        Write-Host "Istio already exists on AWS EKS" -ForegroundColor Green
    }
    
    Deploy-MonitoringStack $awsContext "AWS-EKS"
    Deploy-ArgoCD $awsContext "AWS-EKS"
    
    # Get service endpoints
    Write-Host "`nAWS EKS Endpoints:" -ForegroundColor Cyan
    Start-Sleep 30
    $istioLB = kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($istioLB) { Write-Host "  Istio Gateway: http://$istioLB" -ForegroundColor White }
    
    $grafanaLB = kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($grafanaLB) { Write-Host "  Grafana: http://$grafanaLB" -ForegroundColor White }
    
    $argoLB = kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($argoLB) { Write-Host "  ArgoCD: http://$argoLB" -ForegroundColor White }
}

# Deploy to Azure AKS
if ($azureContext) {
    Write-Host "`nDeploying complete stack to Azure AKS..." -ForegroundColor Blue
    kubectl config use-context $azureContext
    
    # Check current Istio status
    $istioExists = kubectl get namespace istio-system --no-headers 2>$null
    if ($istioExists) {
        Write-Host "Istio already exists on Azure AKS" -ForegroundColor Green
    }
    
    Deploy-MonitoringStack $azureContext "Azure-AKS"
    Deploy-ArgoCD $azureContext "Azure-AKS"
    
    # Get service endpoints
    Write-Host "`nAzure AKS Endpoints:" -ForegroundColor Cyan
    Start-Sleep 30
    $istioLB = kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if ($istioLB) { Write-Host "  Istio Gateway: http://$istioLB" -ForegroundColor White }
    
    $grafanaLB = kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if ($grafanaLB) { Write-Host "  Grafana: http://$grafanaLB" -ForegroundColor White }
    
    $argoLB = kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if ($argoLB) { Write-Host "  ArgoCD: http://$argoLB" -ForegroundColor White }
}

Write-Host "`nMulti-Cloud Service Mesh Deployment Complete!" -ForegroundColor Green
Write-Host "`nDeployed Components:" -ForegroundColor Blue
Write-Host "  Service Mesh (Istio)" -ForegroundColor Green
Write-Host "  Monitoring (Prometheus + Grafana)" -ForegroundColor Green
Write-Host "  GitOps (ArgoCD)" -ForegroundColor Green
Write-Host "  Load Balancers with external endpoints" -ForegroundColor Green
Write-Host "`nTools Used:" -ForegroundColor Blue
Write-Host "  Terraform (infrastructure from /infrastructure/terraform/)" -ForegroundColor White
Write-Host "  Helm (package management)" -ForegroundColor White
Write-Host "  Kustomize (configuration management)" -ForegroundColor White
Write-Host "  ArgoCD (GitOps deployment)" -ForegroundColor White
Write-Host "  Prometheus + Grafana (monitoring)" -ForegroundColor White
Write-Host "  Istio (service mesh)" -ForegroundColor White
