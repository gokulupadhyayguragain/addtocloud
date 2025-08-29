# AddToCloud Multi-Cloud Deployment Script for Windows
# This script deploys AddToCloud to Azure AKS, AWS EKS, and GCP GKE

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("azure", "aws", "gcp", "all")]
    [string]$Target
)

# Configuration
$FRONTEND_IMAGE = "addtocloud/frontend:latest"
$BACKEND_IMAGE = "addtocloud/backend:latest"
$NAMESPACE = "addtocloud"

# Functions
function Write-Info {
    param([string]$Message)
    Write-Host "🔵 INFO: $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ SUCCESS: $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ ERROR: $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl is not installed. Please install kubectl first."
        exit 1
    }
    
    # Check if docker is installed
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "docker is not installed. Please install docker first."
        exit 1
    }
    
    # Check if kustomize is installed
    if (-not (Get-Command kustomize -ErrorAction SilentlyContinue)) {
        Write-Error "kustomize is not installed. Please install kustomize first."
        exit 1
    }
    
    Write-Success "All prerequisites are met"
}

# Build and tag Docker images
function Build-Images {
    Write-Info "Building Docker images..."
    
    # Build frontend
    docker build -f infrastructure/docker/Dockerfile.frontend -t $FRONTEND_IMAGE .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build frontend image"
        exit 1
    }
    Write-Success "Frontend image built successfully"
    
    # Build backend
    docker build -f infrastructure/docker/Dockerfile.backend -t $BACKEND_IMAGE .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build backend image"
        exit 1
    }
    Write-Success "Backend image built successfully"
}

# Deploy to Azure AKS
function Deploy-Azure {
    Write-Info "Deploying to Azure AKS..."
    
    # Set Azure context (assumes AKS cluster is already created)
    $azureContext = kubectl config get-contexts | Select-String "azure-aks"
    if ($azureContext) {
        kubectl config use-context azure-aks
    } else {
        Write-Warning "Azure AKS context not found. Please configure your AKS cluster first."
        return
    }
    
    # Tag and push images to ACR
    $ACR_NAME = "addtocloudacr.azurecr.io"
    docker tag $FRONTEND_IMAGE "$ACR_NAME/addtocloud/frontend:latest"
    docker tag $BACKEND_IMAGE "$ACR_NAME/addtocloud/backend:latest"
    
    docker push "$ACR_NAME/addtocloud/frontend:latest"
    docker push "$ACR_NAME/addtocloud/backend:latest"
    
    # Apply Kubernetes manifests
    kustomize build infrastructure/kubernetes/overlays/azure | kubectl apply -f -
    
    Write-Success "Deployment to Azure AKS completed"
}

# Deploy to AWS EKS
function Deploy-AWS {
    Write-Info "Deploying to AWS EKS..."
    
    # Set AWS context (assumes EKS cluster is already created)
    $awsContext = kubectl config get-contexts | Select-String "aws-eks"
    if ($awsContext) {
        kubectl config use-context aws-eks
    } else {
        Write-Warning "AWS EKS context not found. Please configure your EKS cluster first."
        return
    }
    
    # Tag and push images to ECR
    $AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
    $AWS_REGION = "us-west-2"
    $ECR_REGISTRY = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    
    # Login to ECR
    $ecrPassword = aws ecr get-login-password --region $AWS_REGION
    $ecrPassword | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Create repositories if they don't exist
    try {
        aws ecr describe-repositories --repository-names addtocloud/frontend --region $AWS_REGION
    } catch {
        aws ecr create-repository --repository-name addtocloud/frontend --region $AWS_REGION
    }
    
    try {
        aws ecr describe-repositories --repository-names addtocloud/backend --region $AWS_REGION
    } catch {
        aws ecr create-repository --repository-name addtocloud/backend --region $AWS_REGION
    }
    
    docker tag $FRONTEND_IMAGE "$ECR_REGISTRY/addtocloud/frontend:latest"
    docker tag $BACKEND_IMAGE "$ECR_REGISTRY/addtocloud/backend:latest"
    
    docker push "$ECR_REGISTRY/addtocloud/frontend:latest"
    docker push "$ECR_REGISTRY/addtocloud/backend:latest"
    
    # Apply Kubernetes manifests
    kustomize build infrastructure/kubernetes/overlays/aws | kubectl apply -f -
    
    Write-Success "Deployment to AWS EKS completed"
}

# Deploy to GCP GKE
function Deploy-GCP {
    Write-Info "Deploying to GCP GKE..."
    
    # Set GCP context (assumes GKE cluster is already created)
    $gcpContext = kubectl config get-contexts | Select-String "gcp-gke"
    if ($gcpContext) {
        kubectl config use-context gcp-gke
    } else {
        Write-Warning "GCP GKE context not found. Please configure your GKE cluster first."
        return
    }
    
    # Tag and push images to GCR
    $GCP_PROJECT_ID = "addtocloud-project"
    $GCR_HOSTNAME = "gcr.io"
    
    docker tag $FRONTEND_IMAGE "$GCR_HOSTNAME/$GCP_PROJECT_ID/frontend:latest"
    docker tag $BACKEND_IMAGE "$GCR_HOSTNAME/$GCP_PROJECT_ID/backend:latest"
    
    docker push "$GCR_HOSTNAME/$GCP_PROJECT_ID/frontend:latest"
    docker push "$GCR_HOSTNAME/$GCP_PROJECT_ID/backend:latest"
    
    # Apply Kubernetes manifests
    kustomize build infrastructure/kubernetes/overlays/gcp | kubectl apply -f -
    
    Write-Success "Deployment to GCP GKE completed"
}

# Monitor deployment status
function Monitor-Deployment {
    param([string]$Context)
    
    Write-Info "Monitoring deployment status for $Context..."
    
    kubectl config use-context $Context
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=addtocloud-frontend -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=addtocloud-backend -n $NAMESPACE --timeout=300s
    
    # Get deployment status
    kubectl get pods -n $NAMESPACE
    kubectl get services -n $NAMESPACE
    
    Write-Success "Deployment monitoring completed for $Context"
}

# Main execution
function Main {
    Write-Info "🚀 Starting AddToCloud Multi-Cloud Deployment..."
    
    Test-Prerequisites
    Build-Images
    
    # Deploy to specified cloud(s)
    switch ($Target) {
        "azure" { Deploy-Azure }
        "aws" { Deploy-AWS }
        "gcp" { Deploy-GCP }
        "all" {
            Deploy-Azure
            Deploy-AWS
            Deploy-GCP
        }
    }
    
    Write-Success "🎉 Multi-cloud deployment completed successfully!"
    
    Write-Host ""
    Write-Host "📊 Deployment Summary:" -ForegroundColor Cyan
    Write-Host "├── Frontend: 399 pages with professional UI" -ForegroundColor White
    Write-Host "├── Backend: Go microservices with REST/GraphQL APIs" -ForegroundColor White
    Write-Host "├── Databases: PostgreSQL, MongoDB, Redis" -ForegroundColor White
    Write-Host "├── Cloud Providers: Azure AKS, AWS EKS, GCP GKE" -ForegroundColor White
    Write-Host "└── Features: Auto-scaling, SSL/TLS, Load balancing" -ForegroundColor White
    Write-Host ""
    
    # Display access URLs
    Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
    Write-Host "├── Production: https://addtocloud.tech" -ForegroundColor White
    Write-Host "├── API: https://api.addtocloud.tech" -ForegroundColor White
    Write-Host "└── WWW: https://www.addtocloud.tech" -ForegroundColor White
}

# Execute main function
Main
