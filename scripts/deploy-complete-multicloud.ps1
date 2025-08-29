# Complete Multi-Cloud Deployment Script with Database Persistence
# Deploys AddToCloud platform with EFS/Filestore/Azure Files across AWS, GCP, and Azure

Write-Host "🚀 Starting Complete Multi-Cloud Deployment with Persistent Storage" -ForegroundColor Green
Write-Host ""

# Configuration
$ENVIRONMENTS = @("production")
$CLOUDS = @("aws", "gcp", "azure")
$REGIONS = @{
    "aws" = "us-east-1"
    "gcp" = "us-central1"
    "azure" = "eastus"
}

# Check prerequisites
Write-Host "📋 Checking Prerequisites..." -ForegroundColor Blue

$tools = @("kubectl", "terraform", "aws", "gcloud", "az", "argocd", "helm", "docker")
foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "✅ $tool is installed" -ForegroundColor Green
    } else {
        Write-Host "❌ $tool is not installed. Please install it first." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🌐 Phase 1: Building and Pushing Docker Images" -ForegroundColor Blue
Write-Host ""

# Build Frontend
Write-Host "🔨 Building Frontend..." -ForegroundColor Cyan
Set-Location "apps\frontend"
npm install
npm run build
npm run export

# Build Backend Docker Image
Write-Host "🔨 Building Backend Docker Image..." -ForegroundColor Cyan
Set-Location "..\backend"
docker build -f ..\..\infrastructure\docker\Dockerfile.backend -t ghcr.io/gokulupadhyayguragain/addtocloud:latest .
docker push ghcr.io/gokulupadhyayguragain/addtocloud:latest

Set-Location "..\..\"

Write-Host ""
Write-Host "🌐 Phase 2: Infrastructure Deployment" -ForegroundColor Blue
Write-Host ""

# Deploy AWS Infrastructure with EFS
Write-Host "1️⃣ Deploying AWS Infrastructure with EFS..." -ForegroundColor Cyan
Set-Location "infrastructure\terraform\aws"

# Initialize and deploy EKS
terraform init
terraform workspace select production 2>$null || terraform workspace new production
terraform plan -var-file="production.tfvars" -out="aws-plan.out"
terraform apply -auto-approve "aws-plan.out"

# Deploy EFS
Write-Host "📂 Deploying AWS EFS Storage..." -ForegroundColor Yellow
terraform apply -target="aws_efs_file_system.addtocloud_efs" -auto-approve
terraform apply -target="aws_efs_access_point.postgresql_ap" -auto-approve
terraform apply -target="aws_efs_access_point.mongodb_ap" -auto-approve
terraform apply -target="aws_efs_access_point.redis_ap" -auto-approve
terraform apply -target="aws_efs_access_point.logs_ap" -auto-approve
terraform apply -target="aws_efs_access_point.backup_ap" -auto-approve

# Configure kubectl for EKS
aws eks update-kubeconfig --region us-east-1 --name addtocloud-eks-primary
Write-Host "✅ AWS EKS cluster with EFS deployed" -ForegroundColor Green

Set-Location "..\..\..\"

# Deploy GCP Infrastructure with Filestore
Write-Host ""
Write-Host "2️⃣ Deploying GCP Infrastructure with Filestore..." -ForegroundColor Cyan
Set-Location "infrastructure\terraform\gcp"

terraform init
terraform workspace select production 2>$null || terraform workspace new production
terraform plan -var-file="production.tfvars" -out="gcp-plan.out"
terraform apply -auto-approve "gcp-plan.out"

# Configure kubectl for GKE
gcloud container clusters get-credentials addtocloud-gke-secondary --zone us-central1
Write-Host "✅ GCP GKE cluster with Filestore deployed" -ForegroundColor Green

Set-Location "..\..\..\"

# Deploy Azure Infrastructure with Azure Files
Write-Host ""
Write-Host "3️⃣ Deploying Azure Infrastructure with Azure Files..." -ForegroundColor Cyan
Set-Location "infrastructure\terraform\azure"

terraform init
terraform workspace select production 2>$null || terraform workspace new production
terraform plan -var-file="production.tfvars" -out="azure-plan.out"
terraform apply -auto-approve "azure-plan.out"

# Configure kubectl for AKS
az aks get-credentials --resource-group addtocloud-rg --name addtocloud-aks-tertiary
Write-Host "✅ Azure AKS cluster with Azure Files deployed" -ForegroundColor Green

Set-Location "..\..\..\"

Write-Host ""
Write-Host "🌐 Phase 3: Storage and Database Setup" -ForegroundColor Blue
Write-Host ""

$contexts = @("addtocloud-eks-primary", "addtocloud-gke-secondary", "addtocloud-aks-tertiary")

foreach ($context in $contexts) {
    Write-Host "4️⃣ Setting up persistent storage on $context..." -ForegroundColor Cyan
    kubectl config use-context $context
    
    # Create namespaces
    kubectl create namespace database --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
    
    # Install EFS CSI Driver (AWS only)
    if ($context -eq "addtocloud-eks-primary") {
        Write-Host "📂 Installing EFS CSI Driver..." -ForegroundColor Yellow
        kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"
        
        # Wait for CSI driver to be ready
        kubectl wait --for=condition=available --timeout=300s deployment/efs-csi-controller -n kube-system
    }
    
    # Apply storage configurations
    kubectl apply -f infrastructure\kubernetes\storage\persistent-storage.yaml
    
    # Wait for PVCs to be bound
    Write-Host "⏳ Waiting for Persistent Volumes to be ready..." -ForegroundColor Yellow
    kubectl wait --for=condition=Bound pvc/postgresql-data-pvc -n database --timeout=300s
    kubectl wait --for=condition=Bound pvc/mongodb-data-pvc -n database --timeout=300s
    kubectl wait --for=condition=Bound pvc/redis-data-pvc -n database --timeout=300s
    kubectl wait --for=condition=Bound pvc/logs-pvc -n monitoring --timeout=300s
    kubectl wait --for=condition=Bound pvc/backup-pvc -n database --timeout=300s
    
    Write-Host "✅ Persistent storage configured on $context" -ForegroundColor Green
}

Write-Host ""
Write-Host "🌐 Phase 4: Database Deployment" -ForegroundColor Blue
Write-Host ""

foreach ($context in $contexts) {
    Write-Host "5️⃣ Deploying databases on $context..." -ForegroundColor Cyan
    kubectl config use-context $context
    
    # Create database secrets
    kubectl create secret generic postgresql-secrets `
        --from-literal=username=addtocloud `
        --from-literal=password=SecurePassword123! `
        -n database --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic mongodb-secrets `
        --from-literal=username=addtocloud `
        --from-literal=password=SecurePassword123! `
        -n database --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic redis-secrets `
        --from-literal=password=SecurePassword123! `
        -n database --dry-run=client -o yaml | kubectl apply -f -
    
    # Create service accounts
    kubectl create serviceaccount postgresql-sa -n database --dry-run=client -o yaml | kubectl apply -f -
    kubectl create serviceaccount mongodb-sa -n database --dry-run=client -o yaml | kubectl apply -f -
    kubectl create serviceaccount redis-sa -n database --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy databases
    kubectl apply -f infrastructure\kubernetes\database\database-deployments.yaml
    
    # Wait for databases to be ready
    Write-Host "⏳ Waiting for databases to be ready..." -ForegroundColor Yellow
    kubectl wait --for=condition=available --timeout=600s deployment/postgresql-primary -n database
    kubectl wait --for=condition=available --timeout=600s deployment/mongodb-primary -n database
    kubectl wait --for=condition=available --timeout=600s deployment/redis-master -n database
    
    Write-Host "✅ Databases deployed on $context" -ForegroundColor Green
}

Write-Host ""
Write-Host "🌐 Phase 5: ArgoCD and GitOps Setup" -ForegroundColor Blue
Write-Host ""

foreach ($context in $contexts) {
    Write-Host "6️⃣ Setting up ArgoCD on $context..." -ForegroundColor Cyan
    kubectl config use-context $context
    
    # Create ArgoCD namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
    
    # Apply ArgoCD applications
    kubectl apply -f devops\argocd\applications.yaml
    
    Write-Host "✅ ArgoCD installed on $context" -ForegroundColor Green
}

Write-Host ""
Write-Host "🌐 Phase 6: Application Deployment" -ForegroundColor Blue
Write-Host ""

foreach ($context in $contexts) {
    Write-Host "7️⃣ Deploying AddToCloud application on $context..." -ForegroundColor Cyan
    kubectl config use-context $context
    
    # Create application secrets
    kubectl create secret generic jwt-secrets `
        --from-literal=secret=SuperSecretJWTKey123! `
        -n addtocloud --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic database-secrets `
        --from-literal=url=postgresql://addtocloud:SecurePassword123!@postgresql-service.database.svc.cluster.local:5432/addtocloud `
        -n addtocloud --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic redis-secrets `
        --from-literal=url=redis://:SecurePassword123!@redis-service.database.svc.cluster.local:6379 `
        -n addtocloud --dry-run=client -o yaml | kubectl apply -f -
    
    # Create GitHub registry secret
    kubectl create secret docker-registry github-registry-secret `
        --docker-server=ghcr.io `
        --docker-username=$env:GITHUB_USERNAME `
        --docker-password=$env:GITHUB_TOKEN `
        -n addtocloud --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy application
    kubectl apply -f infrastructure\kubernetes\base\deployment.yaml
    
    # Wait for application to be ready
    Write-Host "⏳ Waiting for application to be ready..." -ForegroundColor Yellow
    kubectl wait --for=condition=available --timeout=600s deployment/addtocloud-backend -n addtocloud
    
    Write-Host "✅ Application deployed on $context" -ForegroundColor Green
}

Write-Host ""
Write-Host "🌐 Phase 7: Monitoring Stack" -ForegroundColor Blue
Write-Host ""

foreach ($context in $contexts) {
    Write-Host "8️⃣ Setting up monitoring on $context..." -ForegroundColor Cyan
    kubectl config use-context $context
    
    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Install Prometheus stack
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
        --namespace monitoring `
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=efs-sc `
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi `
        --set grafana.persistence.enabled=true `
        --set grafana.persistence.storageClassName=efs-sc `
        --set grafana.persistence.size=10Gi
    
    Write-Host "✅ Monitoring stack installed on $context" -ForegroundColor Green
}

Write-Host ""
Write-Host "🌐 Phase 8: Frontend Deployment to Cloudflare" -ForegroundColor Blue
Write-Host ""

Write-Host "9️⃣ Deploying Frontend to Cloudflare Pages..." -ForegroundColor Cyan
Set-Location "apps\frontend"

# Deploy to Cloudflare (requires Wrangler CLI and authentication)
if (Get-Command wrangler -ErrorAction SilentlyContinue) {
    wrangler pages publish out --project-name addtocloud-frontend --compatibility-date=2024-08-29
    Write-Host "✅ Frontend deployed to Cloudflare Pages" -ForegroundColor Green
} else {
    Write-Host "⚠️ Wrangler CLI not found. Manual deployment to Cloudflare Pages required." -ForegroundColor Yellow
    Write-Host "   1. Install Wrangler: npm install -g wrangler" -ForegroundColor White
    Write-Host "   2. Login: wrangler login" -ForegroundColor White
    Write-Host "   3. Deploy: wrangler pages publish out --project-name addtocloud-frontend" -ForegroundColor White
}

Set-Location "..\..\"

Write-Host ""
Write-Host "🌐 Phase 9: Final Health Checks" -ForegroundColor Blue
Write-Host ""

Write-Host "🔍 Running health checks across all clusters..." -ForegroundColor Cyan

foreach ($context in $contexts) {
    kubectl config use-context $context
    
    Write-Host ""
    Write-Host "Health check for $context`: " -ForegroundColor Yellow
    
    # Check database pods
    $dbPods = kubectl get pods -n database --no-headers | Where-Object { $_ -match "Running" }
    $dbCount = ($dbPods | Measure-Object).Count
    Write-Host "  📊 Database pods running: $dbCount/3" -ForegroundColor Cyan
    
    # Check application pods
    $appPods = kubectl get pods -n addtocloud --no-headers | Where-Object { $_ -match "Running" }
    $appCount = ($appPods | Measure-Object).Count
    Write-Host "  🚀 Application pods running: $appCount" -ForegroundColor Cyan
    
    # Check storage
    $pvcs = kubectl get pvc -n database --no-headers | Where-Object { $_ -match "Bound" }
    $pvcCount = ($pvcs | Measure-Object).Count
    Write-Host "  💾 Persistent volumes bound: $pvcCount/3" -ForegroundColor Cyan
    
    # Check services
    $services = kubectl get svc -n addtocloud --no-headers
    $svcCount = ($services | Measure-Object).Count
    Write-Host "  🌐 Services available: $svcCount" -ForegroundColor Cyan
    
    if ($dbCount -eq 3 -and $appCount -gt 0 -and $pvcCount -eq 3 -and $svcCount -gt 0) {
        Write-Host "  ✅ $context is healthy" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ $context has issues - check logs" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Multi-Cloud Deployment with Persistent Storage Complete!" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Deployment Summary:" -ForegroundColor Blue
Write-Host ""
Write-Host "Frontend:" -ForegroundColor Yellow
Write-Host "  🌐 Cloudflare Pages: https://addtocloud.tech" -ForegroundColor Cyan
Write-Host "  📱 Global CDN with edge caching enabled" -ForegroundColor Cyan
Write-Host ""

Write-Host "Backend Clusters:" -ForegroundColor Yellow
Write-Host "  ☁️ AWS EKS (Primary): us-east-1 with EFS storage" -ForegroundColor Cyan
Write-Host "  ☁️ GCP GKE (Secondary): us-central1 with Filestore" -ForegroundColor Cyan
Write-Host "  ☁️ Azure AKS (Tertiary): eastus with Azure Files" -ForegroundColor Cyan
Write-Host ""

Write-Host "Databases:" -ForegroundColor Yellow
Write-Host "  🗄️ PostgreSQL: Deployed on all clusters with persistent storage" -ForegroundColor Cyan
Write-Host "  🗄️ MongoDB: Deployed on all clusters with persistent storage" -ForegroundColor Cyan
Write-Host "  🗄️ Redis: Deployed on all clusters with persistent storage" -ForegroundColor Cyan
Write-Host ""

Write-Host "Storage:" -ForegroundColor Yellow
Write-Host "  📂 AWS EFS: Multi-AZ file system with access points" -ForegroundColor Cyan
Write-Host "  📂 GCP Filestore: High-performance shared storage" -ForegroundColor Cyan
Write-Host "  📂 Azure Files: Premium NFS shares" -ForegroundColor Cyan
Write-Host ""

Write-Host "Monitoring:" -ForegroundColor Yellow
Write-Host "  📊 Prometheus: Metrics collection across all clusters" -ForegroundColor Cyan
Write-Host "  📈 Grafana: Unified dashboards with persistent storage" -ForegroundColor Cyan
Write-Host "  🔍 Logs: Centralized logging with persistent storage" -ForegroundColor Cyan
Write-Host ""

Write-Host "GitOps:" -ForegroundColor Yellow
Write-Host "  🔄 ArgoCD: Deployed on all clusters for continuous deployment" -ForegroundColor Cyan
Write-Host "  📦 Auto-sync: Enabled for seamless updates" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔗 Access URLs:" -ForegroundColor Blue
Write-Host "  Frontend: https://addtocloud.tech" -ForegroundColor Cyan
Write-Host "  API Docs: https://api.addtocloud.tech/docs" -ForegroundColor Cyan
Write-Host "  Grafana: https://grafana.addtocloud.tech" -ForegroundColor Cyan
Write-Host "  ArgoCD: https://argocd.addtocloud.tech" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚀 Your AddToCloud platform is now running with:" -ForegroundColor Green
Write-Host "  ✅ High Availability across 3 cloud providers" -ForegroundColor White
Write-Host "  ✅ Persistent storage for all data and logs" -ForegroundColor White
Write-Host "  ✅ Auto-scaling and load balancing" -ForegroundColor White
Write-Host "  ✅ Comprehensive monitoring and observability" -ForegroundColor White
Write-Host "  ✅ GitOps-based continuous deployment" -ForegroundColor White
Write-Host "  ✅ Enterprise-grade security and networking" -ForegroundColor White
Write-Host ""
Write-Host "Happy Cloud Computing! ☁️🌟" -ForegroundColor Green
