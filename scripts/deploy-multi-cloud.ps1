# Multi-Cloud Deployment Script
# Deploys AddToCloud platform across AWS, GCP, and Azure

Write-Host "🚀 Starting Multi-Cloud Deployment for AddToCloud Platform" -ForegroundColor Green
Write-Host ""

# Check prerequisites
Write-Host "📋 Checking Prerequisites..." -ForegroundColor Blue

# Check required tools
$tools = @("kubectl", "terraform", "aws", "gcloud", "az", "argocd", "helm")
foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "✅ $tool is installed" -ForegroundColor Green
    } else {
        Write-Host "❌ $tool is not installed" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🌐 Multi-Cloud Infrastructure Deployment" -ForegroundColor Blue
Write-Host ""

# 1. Deploy Frontend to Cloudflare Pages
Write-Host "1️⃣ Deploying Frontend to Cloudflare Pages..." -ForegroundColor Cyan
Set-Location "apps\frontend"
npm run build
npm run export

# Deploy to Cloudflare (requires Wrangler CLI)
if (Get-Command wrangler -ErrorAction SilentlyContinue) {
    wrangler pages publish out --project-name addtocloud-frontend
    Write-Host "✅ Frontend deployed to Cloudflare Pages" -ForegroundColor Green
} else {
    Write-Host "⚠️ Wrangler CLI not found. Manual deployment required." -ForegroundColor Yellow
}

Set-Location "..\..\"

# 2. Deploy AWS EKS Infrastructure
Write-Host ""
Write-Host "2️⃣ Deploying AWS EKS Cluster..." -ForegroundColor Cyan
Set-Location "infrastructure\terraform\aws"

terraform init
terraform plan -var-file="production.tfvars"
terraform apply -auto-approve -var-file="production.tfvars"

# Configure kubectl for EKS
aws eks update-kubeconfig --region us-east-1 --name addtocloud-eks-primary

Write-Host "✅ AWS EKS cluster deployed" -ForegroundColor Green
Set-Location "..\..\..\"

# 3. Deploy GCP GKE Infrastructure
Write-Host ""
Write-Host "3️⃣ Deploying GCP GKE Cluster..." -ForegroundColor Cyan
Set-Location "infrastructure\terraform\gcp"

terraform init
terraform plan -var-file="production.tfvars"
terraform apply -auto-approve -var-file="production.tfvars"

# Configure kubectl for GKE
gcloud container clusters get-credentials addtocloud-gke-secondary --zone us-central1

Write-Host "✅ GCP GKE cluster deployed" -ForegroundColor Green
Set-Location "..\..\..\"

# 4. Deploy Azure AKS Infrastructure
Write-Host ""
Write-Host "4️⃣ Deploying Azure AKS Cluster..." -ForegroundColor Cyan
Set-Location "infrastructure\terraform\azure"

terraform init
terraform plan -var-file="production.tfvars"
terraform apply -auto-approve -var-file="production.tfvars"

# Configure kubectl for AKS
az aks get-credentials --resource-group addtocloud-rg --name addtocloud-aks-tertiary

Write-Host "✅ Azure AKS cluster deployed" -ForegroundColor Green
Set-Location "..\..\..\"

# 5. Deploy ArgoCD for GitOps
Write-Host ""
Write-Host "5️⃣ Setting up ArgoCD for GitOps..." -ForegroundColor Cyan

# Install ArgoCD on all clusters
$contexts = @("addtocloud-eks-primary", "addtocloud-gke-secondary", "addtocloud-aks-tertiary")

foreach ($context in $contexts) {
    kubectl config use-context $context
    
    # Create ArgoCD namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    Write-Host "✅ ArgoCD installed on $context" -ForegroundColor Green
}

# 6. Deploy Applications with ArgoCD
Write-Host ""
Write-Host "6️⃣ Deploying Applications with ArgoCD..." -ForegroundColor Cyan

# Apply ArgoCD applications
kubectl apply -f devops\argocd\applications.yaml

Write-Host "✅ ArgoCD applications configured" -ForegroundColor Green

# 7. Setup Monitoring Stack
Write-Host ""
Write-Host "7️⃣ Setting up Monitoring Stack..." -ForegroundColor Cyan

# Install Prometheus and Grafana using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

foreach ($context in $contexts) {
    kubectl config use-context $context
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Prometheus
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
        --namespace monitoring `
        --values infrastructure\monitoring\prometheus\values.yaml
    
    Write-Host "✅ Monitoring stack installed on $context" -ForegroundColor Green
}

# 8. Configure DNS and SSL
Write-Host ""
Write-Host "8️⃣ Configuring DNS and SSL..." -ForegroundColor Cyan

# Setup cert-manager for SSL certificates
foreach ($context in $contexts) {
    kubectl config use-context $context
    
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
    
    Write-Host "✅ Cert-manager installed on $context" -ForegroundColor Green
}

# 9. Final Status Check
Write-Host ""
Write-Host "🔍 Final Deployment Status Check..." -ForegroundColor Blue
Write-Host ""

Write-Host "Frontend Deployment:" -ForegroundColor Yellow
Write-Host "  🌐 Cloudflare Pages: https://addtocloud.tech" -ForegroundColor Cyan
Write-Host "  📊 Analytics: Available in Cloudflare Dashboard" -ForegroundColor Cyan
Write-Host ""

Write-Host "Backend Deployments:" -ForegroundColor Yellow
foreach ($context in $contexts) {
    kubectl config use-context $context
    $status = kubectl get deployment addtocloud-backend -n addtocloud -o jsonpath='{.status.readyReplicas}' 2>$null
    if ($status) {
        Write-Host "  ✅ $context`: $status pods ready" -ForegroundColor Green
    } else {
        Write-Host "  ⏳ $context`: Deployment in progress..." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Monitoring:" -ForegroundColor Yellow
Write-Host "  📊 Grafana: http://grafana.addtocloud.tech" -ForegroundColor Cyan
Write-Host "  📈 Prometheus: http://prometheus.addtocloud.tech" -ForegroundColor Cyan
Write-Host ""

Write-Host "GitOps:" -ForegroundColor Yellow
Write-Host "  🔄 ArgoCD: http://argocd.addtocloud.tech" -ForegroundColor Cyan
Write-Host "  📦 Applications: Auto-synced from Git" -ForegroundColor Cyan
Write-Host ""

Write-Host "🎉 Multi-Cloud Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Blue
Write-Host "1. Configure DNS records for your domains" -ForegroundColor White
Write-Host "2. Set up monitoring alerts" -ForegroundColor White
Write-Host "3. Configure backup strategies" -ForegroundColor White
Write-Host "4. Run security scans" -ForegroundColor White
Write-Host "5. Load test the application" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Quick Links:" -ForegroundColor Blue
Write-Host "  App: https://addtocloud.tech" -ForegroundColor Cyan
Write-Host "  API: https://api.addtocloud.tech" -ForegroundColor Cyan
Write-Host "  Docs: https://docs.addtocloud.tech" -ForegroundColor Cyan
Write-Host ""
Write-Host "Happy Cloud Computing! ☁️" -ForegroundColor Green
