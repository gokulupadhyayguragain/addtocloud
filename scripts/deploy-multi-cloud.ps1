# AddToCloud Enterprise Multi-Cloud Deployment Script
# Deploy to Azure AKS, AWS EKS, and GCP GKE clusters

param(
    [string]$Environment = "production",
    [string]$Version = "latest",
    [switch]$BuildImages,
    [switch]$DeployInfra,
    [switch]$DeployApps,
    [switch]$All
)

Write-Host "🚀 AddToCloud Enterprise Multi-Cloud Deployment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Configuration
$PROJECT_NAME = "addtocloud"
$REPO_NAME = "ghcr.io/gokulupadhyayguragain"
$CLUSTERS = @{
    "azure" = @{
        "name" = "aks-addtocloud-prod"
        "resource_group" = "rg-addtocloud-prod" 
        "context" = "aks-addtocloud-prod"
    }
    "aws" = @{
        "name" = "addtocloud-eks-prod"
        "region" = "us-east-1"
        "context" = "addtocloud-eks-prod"
    }
    "gcp" = @{
        "name" = "addtocloud-gke-prod"
        "zone" = "us-central1-a"
        "project" = "addtocloud-prod"
        "context" = "gke_addtocloud-prod_us-central1-a_addtocloud-gke-prod"
    }
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n✅ $Message" -ForegroundColor Green
}

function Build-ContainerImages {
    Write-Step "Building container images for OTP-enabled backend..."
    
    # Build backend with OTP support
    Write-Host "📦 Building OTP-enabled backend image..."
    docker build -f infrastructure/docker/Dockerfile.backend -t "$REPO_NAME/addtocloud-backend:$Version" ./backend/ --build-arg MAIN_FILE=main-otp-admin.go
    
    # Build frontend
    Write-Host "� Building frontend image..."
    docker build -f infrastructure/docker/Dockerfile.frontend -t "$REPO_NAME/addtocloud-frontend:$Version" ./frontend/
    
    # Push images
    Write-Host "📤 Pushing images to GitHub Container Registry..."
    docker push "$REPO_NAME/addtocloud-backend:$Version"
    docker push "$REPO_NAME/addtocloud-frontend:$Version"
    
    Write-Step "Container images built and pushed successfully!"
}

function Deploy-Infrastructure {
    Write-Step "Deploying infrastructure to multi-cloud..."
    
    # Deploy Azure AKS
    Write-Host "🏗️  Deploying Azure AKS infrastructure..."
    Push-Location infrastructure/terraform/azure
    try {
        terraform init
        terraform plan -var="environment=$Environment"
        terraform apply -auto-approve -var="environment=$Environment"
        az aks get-credentials --resource-group rg-addtocloud-prod --name aks-addtocloud-prod --overwrite-existing
    }
    finally {
        Pop-Location
    }
    
    # Deploy AWS EKS
    Write-Host "🏗️  Deploying AWS EKS infrastructure..."
    Push-Location infrastructure/terraform/aws
    try {
        terraform init
        terraform apply -auto-approve -var="environment=$Environment"
        aws eks update-kubeconfig --region us-east-1 --name addtocloud-eks-prod
    }
    finally {
        Pop-Location
    }
    
    # Deploy GCP GKE  
    Write-Host "🏗️  Deploying GCP GKE infrastructure..."
    Push-Location infrastructure/terraform/gcp
    try {
        terraform init
        terraform apply -auto-approve -var="environment=$Environment"
        gcloud container clusters get-credentials addtocloud-gke-prod --zone us-central1-a --project addtocloud-prod
    }
    finally {
        Pop-Location
    }
    
    Write-Step "Multi-cloud infrastructure deployed successfully!"
}

function Deploy-Applications {
    Write-Step "Deploying applications to all clusters..."
    
    foreach ($cloud in $CLUSTERS.Keys) {
        $cluster = $CLUSTERS[$cloud]
        Write-Host "🚀 Deploying to $cloud cluster: $($cluster.name)"
        
        kubectl config use-context $cluster.context
        
        # Create namespace YAML
        $namespaceYaml = @"
apiVersion: v1
kind: Namespace  
metadata:
  name: addtocloud-prod
  labels:
    istio-injection: enabled
    cloud-provider: $cloud
    environment: $Environment
"@
        
        # Apply namespace
        $namespaceYaml | kubectl apply -f -
        
        # Deploy secrets
        kubectl create secret generic db-credentials `
            --from-literal=username=addtocloudadmin `
            --from-literal=password=$env:DB_PASSWORD `
            --namespace=addtocloud-prod `
            --dry-run=client -o yaml | kubectl apply -f -
            
        kubectl create secret generic otp-email-config `
            --from-literal=smtp-host=$env:SMTP_HOST `
            --from-literal=smtp-port=$env:SMTP_PORT `
            --from-literal=smtp-user=$env:SMTP_USER `
            --from-literal=smtp-pass=$env:SMTP_PASS `
            --namespace=addtocloud-prod `
            --dry-run=client -o yaml | kubectl apply -f -
        
        # Deploy applications
        kubectl apply -f infrastructure/kubernetes/deployments/app.yaml
        kubectl apply -f infrastructure/kubernetes/services/
        kubectl apply -f infrastructure/istio/gateways/
        kubectl apply -f infrastructure/istio/virtualservices/
        
        # Wait for rollout
        kubectl rollout status deployment/frontend -n addtocloud-prod --timeout=300s
        kubectl rollout status deployment/backend -n addtocloud-prod --timeout=300s
        
        Write-Host "✅ Deployment to $cloud completed!"
    }
}

function Setup-ArgoCD {
    Write-Step "Setting up ArgoCD GitOps..."
    
    foreach ($cloud in $CLUSTERS.Keys) {
        $cluster = $CLUSTERS[$cloud]
        kubectl config use-context $cluster.context
        
        # Install ArgoCD
        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Apply ArgoCD applications
        kubectl apply -f devops/argocd/applications.yaml
        
        Write-Host "✅ ArgoCD setup completed on $cloud!"
    }
}

function Verify-Deployment {
    Write-Step "Verifying deployments across all clusters..."
    
    foreach ($cloud in $CLUSTERS.Keys) {
        $cluster = $CLUSTERS[$cloud]
        Write-Host "`n🔍 Checking $cloud cluster status..."
        
        kubectl config use-context $cluster.context
        kubectl get pods -n addtocloud-prod
        kubectl get svc -n addtocloud-prod
        kubectl get ingress -n addtocloud-prod
    }
}

# Check prerequisites
Write-Host "📋 Checking Prerequisites..." -ForegroundColor Blue

# Check required tools
$tools = @("kubectl", "terraform", "aws", "gcloud", "az", "argocd", "helm")
foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "✅ $tool is installed" -ForegroundColor Green
    } else {
        Write-Host "❌ $tool is not installed" -ForegroundColor Red
# Main execution logic
try {
    if ($All) {
        $BuildImages = $true
        $DeployInfra = $true
        $DeployApps = $true
    }
    
    if ($BuildImages) {
        Build-ContainerImages
    }
    
    if ($DeployInfra) {
        Deploy-Infrastructure
    }
    
    if ($DeployApps) {
        Deploy-Applications
        Setup-ArgoCD
    }
    
    Verify-Deployment
    
    Write-Host "`n🎉 AddToCloud Enterprise Multi-Cloud Deployment Completed!" -ForegroundColor Green
    Write-Host "📊 Monitoring: Available on all clusters via Istio" -ForegroundColor Cyan
    Write-Host "🔄 GitOps: ArgoCD managing continuous deployment" -ForegroundColor Cyan
    Write-Host "🌐 Access: https://addtocloud.tech" -ForegroundColor Cyan
    Write-Host "🔐 Admin: OTP authentication at /admin-login" -ForegroundColor Cyan
    
    # Display cluster access information
    Write-Host "`n📋 Cluster Access Information:" -ForegroundColor Yellow
    Write-Host "Azure AKS: az aks get-credentials --resource-group rg-addtocloud-prod --name aks-addtocloud-prod"
    Write-Host "AWS EKS: aws eks update-kubeconfig --region us-east-1 --name addtocloud-eks-prod"
    Write-Host "GCP GKE: gcloud container clusters get-credentials addtocloud-gke-prod --zone us-central1-a --project addtocloud-prod"
    
}
catch {
    Write-Host "`n❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
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
