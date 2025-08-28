#!/bin/bash

# =============================================================================
# AddToCloud Complete Infrastructure Deployment Script
# =============================================================================
# This script automates the complete deployment of AddToCloud platform
# across Azure AKS, AWS EKS, and GCP GKE clusters

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="addtocloud"
ENVIRONMENT="production"
NAMESPACE="addtocloud"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Cloud providers to deploy (can be overridden)
DEPLOY_AZURE=${DEPLOY_AZURE:-true}
DEPLOY_AWS=${DEPLOY_AWS:-true}
DEPLOY_GCP=${DEPLOY_GCP:-true}

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running on Windows (Git Bash/WSL) or Linux/macOS
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        info "Detected Windows environment (Git Bash)"
    fi
    
    # Required tools
    local tools=("kubectl" "helm" "terraform" "docker")
    
    # Cloud CLI tools
    if [[ "$DEPLOY_AZURE" == "true" ]]; then
        tools+=("az")
    fi
    
    if [[ "$DEPLOY_AWS" == "true" ]]; then
        tools+=("aws")
    fi
    
    if [[ "$DEPLOY_GCP" == "true" ]]; then
        tools+=("gcloud")
    fi
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool is not installed. Please install it first."
        else
            info "✓ $tool is installed"
        fi
    done
    
    # Check Terraform version
    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    info "✓ Terraform version: $tf_version"
    
    # Check kubectl version
    if kubectl version --client &> /dev/null; then
        info "✓ kubectl is working"
    else
        warn "kubectl might not be properly configured"
    fi
}

# Setup environment
setup_environment() {
    log "Setting up environment..."
    
    # Create necessary directories
    mkdir -p "$ROOT_DIR/infrastructure/terraform/states"
    mkdir -p "$ROOT_DIR/secrets"
    mkdir -p "$ROOT_DIR/logs"
    
    # Check if .env file exists
    if [[ ! -f "$ROOT_DIR/.env" ]]; then
        warn ".env file not found. Creating from template..."
        if [[ -f "$ROOT_DIR/.env.example" ]]; then
            cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
            warn "Please update .env file with your actual values"
        else
            error ".env.example file not found. Cannot create .env file."
        fi
    fi
    
    # Source environment variables
    if [[ -f "$ROOT_DIR/.env" ]]; then
        set -a
        source "$ROOT_DIR/.env"
        set +a
        info "✓ Environment variables loaded"
    fi
}

# Generate secrets
generate_secrets() {
    log "Generating application secrets..."
    
    local secrets_file="$ROOT_DIR/secrets/generated-secrets.env"
    
    # Generate JWT secrets
    local jwt_secret=$(openssl rand -hex 32)
    local jwt_refresh_secret=$(openssl rand -hex 32)
    local session_secret=$(openssl rand -hex 32)
    
    # Generate encryption keys
    local encryption_key=$(openssl rand -hex 32)
    local api_secret=$(openssl rand -hex 32)
    
    # Generate database passwords
    local db_password=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)
    local redis_password=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-16)
    
    # Create secrets file
    cat > "$secrets_file" << EOF
# Generated secrets for AddToCloud platform
# Generated on: $(date)

# JWT and Session Secrets
JWT_SECRET=$jwt_secret
JWT_REFRESH_SECRET=$jwt_refresh_secret
SESSION_SECRET=$session_secret

# Encryption Keys
ENCRYPTION_KEY=$encryption_key
API_SECRET_KEY=$api_secret

# Database Passwords
POSTGRES_PASSWORD=$db_password
REDIS_PASSWORD=$redis_password

# Webhook Secrets
WEBHOOK_SECRET=$(openssl rand -hex 16)
GITHUB_WEBHOOK_SECRET=$(openssl rand -hex 16)

# Application Keys
APP_SECRET_KEY=$(openssl rand -hex 32)
CSRF_SECRET_KEY=$(openssl rand -hex 16)
EOF
    
    chmod 600 "$secrets_file"
    info "✓ Secrets generated and saved to $secrets_file"
    
    # Source the generated secrets
    set -a
    source "$secrets_file"
    set +a
}

# Deploy to Azure AKS
deploy_azure() {
    if [[ "$DEPLOY_AZURE" != "true" ]]; then
        info "Skipping Azure deployment"
        return 0
    fi
    
    log "Deploying to Azure AKS..."
    
    cd "$ROOT_DIR/infrastructure/terraform/azure"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        warn "terraform.tfvars not found in Azure directory"
        if [[ -f "../terraform.tfvars.example" ]]; then
            cp "../terraform.tfvars.example" "terraform.tfvars"
            warn "Please update terraform.tfvars with your Azure credentials"
            return 1
        fi
    fi
    
    # Initialize Terraform
    terraform init -backend-config="key=azure-${ENVIRONMENT}.tfstate"
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    # Get AKS credentials
    local resource_group=$(terraform output -raw resource_group_name)
    local cluster_name=$(terraform output -raw cluster_name)
    
    az aks get-credentials --resource-group "$resource_group" --name "$cluster_name" --overwrite-existing
    
    info "✓ Azure AKS cluster deployed and configured"
}

# Deploy to AWS EKS
deploy_aws() {
    if [[ "$DEPLOY_AWS" != "true" ]]; then
        info "Skipping AWS deployment"
        return 0
    fi
    
    log "Deploying to AWS EKS..."
    
    cd "$ROOT_DIR/infrastructure/terraform/aws"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        warn "terraform.tfvars not found in AWS directory"
        if [[ -f "../terraform.tfvars.example" ]]; then
            cp "../terraform.tfvars.example" "terraform.tfvars"
            warn "Please update terraform.tfvars with your AWS credentials"
            return 1
        fi
    fi
    
    # Initialize Terraform
    terraform init -backend-config="key=aws-${ENVIRONMENT}.tfstate"
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    # Get EKS credentials
    local cluster_name=$(terraform output -raw cluster_name)
    local region=$(terraform output -raw region)
    
    aws eks update-kubeconfig --region "$region" --name "$cluster_name"
    
    info "✓ AWS EKS cluster deployed and configured"
}

# Deploy to GCP GKE
deploy_gcp() {
    if [[ "$DEPLOY_GCP" != "true" ]]; then
        info "Skipping GCP deployment"
        return 0
    fi
    
    log "Deploying to GCP GKE..."
    
    cd "$ROOT_DIR/infrastructure/terraform/gcp"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        warn "terraform.tfvars not found in GCP directory"
        if [[ -f "../terraform.tfvars.example" ]]; then
            cp "../terraform.tfvars.example" "terraform.tfvars"
            warn "Please update terraform.tfvars with your GCP credentials"
            return 1
        fi
    fi
    
    # Initialize Terraform
    terraform init -backend-config="prefix=gcp-${ENVIRONMENT}"
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    # Get GKE credentials
    local cluster_name=$(terraform output -raw cluster_name)
    local zone=$(terraform output -raw zone)
    local project_id=$(terraform output -raw project_id)
    
    gcloud container clusters get-credentials "$cluster_name" --zone "$zone" --project "$project_id"
    
    info "✓ GCP GKE cluster deployed and configured"
}

# Install Istio service mesh
install_istio() {
    log "Installing Istio service mesh..."
    
    # Check if Istio is already installed
    if kubectl get namespace istio-system &> /dev/null; then
        info "Istio namespace already exists, checking installation..."
        if kubectl get pods -n istio-system | grep -q "istiod"; then
            info "✓ Istio is already installed"
            return 0
        fi
    fi
    
    # Download and install Istio
    local istio_version="${ISTIO_VERSION:-1.20.0}"
    
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows (Git Bash)
        curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$istio_version TARGET_ARCH=x86_64 sh -
    else
        # Linux/macOS
        curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$istio_version sh -
    fi
    
    # Add istioctl to PATH temporarily
    export PATH="$PWD/istio-$istio_version/bin:$PATH"
    
    # Install Istio
    istioctl install --set values.defaultRevision=default -y
    
    # Enable sidecar injection for addtocloud namespace
    kubectl label namespace "$NAMESPACE" istio-injection=enabled --overwrite
    
    info "✓ Istio service mesh installed"
}

# Deploy Kubernetes resources
deploy_kubernetes() {
    log "Deploying Kubernetes resources..."
    
    cd "$ROOT_DIR"
    
    # Create namespace
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secrets from generated secrets file
    local secrets_file="$ROOT_DIR/secrets/generated-secrets.env"
    if [[ -f "$secrets_file" ]]; then
        kubectl create secret generic app-secrets \
            --from-env-file="$secrets_file" \
            --namespace="$NAMESPACE" \
            --dry-run=client -o yaml | kubectl apply -f -
        
        info "✓ Application secrets created in Kubernetes"
    fi
    
    # Deploy database services
    if [[ -f "infrastructure/kubernetes/deployments/postgres.yaml" ]]; then
        kubectl apply -f infrastructure/kubernetes/deployments/postgres.yaml -n "$NAMESPACE"
        info "✓ PostgreSQL deployed"
    fi
    
    if [[ -f "infrastructure/kubernetes/deployments/redis.yaml" ]]; then
        kubectl apply -f infrastructure/kubernetes/deployments/redis.yaml -n "$NAMESPACE"
        info "✓ Redis deployed"
    fi
    
    # Deploy monitoring stack
    if [[ -f "infrastructure/kubernetes/deployments/monitoring.yaml" ]]; then
        kubectl apply -f infrastructure/kubernetes/deployments/monitoring.yaml -n "$NAMESPACE"
        info "✓ Monitoring stack deployed"
    fi
    
    # Deploy application
    if [[ -f "infrastructure/kubernetes/deployments/app.yaml" ]]; then
        kubectl apply -f infrastructure/kubernetes/deployments/app.yaml -n "$NAMESPACE"
        info "✓ Application deployed"
    fi
    
    # Deploy Istio configurations
    if [[ -d "infrastructure/istio" ]]; then
        kubectl apply -f infrastructure/istio/ -n "$NAMESPACE"
        info "✓ Istio configurations applied"
    fi
}

# Build and push Docker images
build_and_push_images() {
    log "Building and pushing Docker images..."
    
    cd "$ROOT_DIR"
    
    # Get registry information from Terraform outputs
    local registry_url=""
    local image_tag="latest"
    
    # Determine which registry to use based on deployed cloud
    if [[ "$DEPLOY_AWS" == "true" ]]; then
        registry_url=$(cd infrastructure/terraform/aws && terraform output -raw ecr_registry_url 2>/dev/null || echo "")
    elif [[ "$DEPLOY_AZURE" == "true" ]]; then
        registry_url=$(cd infrastructure/terraform/azure && terraform output -raw acr_login_server 2>/dev/null || echo "")
    elif [[ "$DEPLOY_GCP" == "true" ]]; then
        registry_url=$(cd infrastructure/terraform/gcp && terraform output -raw artifact_registry_url 2>/dev/null || echo "")
    fi
    
    if [[ -n "$registry_url" ]]; then
        # Build and push backend image
        docker build -t "$registry_url/${PROJECT_NAME}-backend:$image_tag" -f infrastructure/docker/Dockerfile.backend .
        docker push "$registry_url/${PROJECT_NAME}-backend:$image_tag"
        
        # Build and push frontend image
        docker build -t "$registry_url/${PROJECT_NAME}-frontend:$image_tag" -f infrastructure/docker/Dockerfile.frontend .
        docker push "$registry_url/${PROJECT_NAME}-frontend:$image_tag"
        
        info "✓ Docker images built and pushed to $registry_url"
    else
        warn "No container registry found. Skipping image push."
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check if pods are running
    local retries=30
    local count=0
    
    while [[ $count -lt $retries ]]; do
        local pods_ready=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -c "Running" || echo "0")
        local total_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)
        
        if [[ $pods_ready -eq $total_pods && $total_pods -gt 0 ]]; then
            info "✓ All pods are running ($pods_ready/$total_pods)"
            break
        else
            info "Waiting for pods to be ready ($pods_ready/$total_pods)..."
            sleep 10
            ((count++))
        fi
    done
    
    if [[ $count -eq $retries ]]; then
        warn "Some pods might not be ready. Please check manually."
    fi
    
    # Show deployment status
    kubectl get all -n "$NAMESPACE"
    
    # Get service URLs
    if kubectl get service -n "$NAMESPACE" &> /dev/null; then
        info "Service endpoints:"
        kubectl get service -n "$NAMESPACE" -o wide
    fi
    
    # Get Istio gateway information
    if kubectl get gateway -n "$NAMESPACE" &> /dev/null; then
        info "Istio gateway configuration:"
        kubectl get gateway -n "$NAMESPACE" -o wide
    fi
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    
    # Remove Terraform plan files
    find "$ROOT_DIR/infrastructure/terraform" -name "tfplan" -delete 2>/dev/null || true
    
    # Remove temporary Istio installation
    if [[ -d "istio-*" ]]; then
        rm -rf istio-*
    fi
}

# Main deployment function
main() {
    log "Starting AddToCloud infrastructure deployment..."
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-azure)
                DEPLOY_AZURE=false
                shift
                ;;
            --skip-aws)
                DEPLOY_AWS=false
                shift
                ;;
            --skip-gcp)
                DEPLOY_GCP=false
                shift
                ;;
            --only-k8s)
                DEPLOY_AZURE=false
                DEPLOY_AWS=false
                DEPLOY_GCP=false
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --skip-azure    Skip Azure AKS deployment"
                echo "  --skip-aws      Skip AWS EKS deployment"
                echo "  --skip-gcp      Skip GCP GKE deployment"
                echo "  --only-k8s      Only deploy Kubernetes resources (skip cloud infrastructure)"
                echo "  --help          Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Execute deployment steps
    check_prerequisites
    setup_environment
    generate_secrets
    
    # Deploy cloud infrastructure
    deploy_azure
    deploy_aws
    deploy_gcp
    
    # Install service mesh and deploy applications
    install_istio
    build_and_push_images
    deploy_kubernetes
    verify_deployment
    
    log "🎉 AddToCloud deployment completed successfully!"
    
    info "Next steps:"
    info "1. Update your DNS settings to point to the load balancer"
    info "2. Configure SSL certificates"
    info "3. Set up monitoring alerts"
    info "4. Test all application endpoints"
    
    # Show useful commands
    info "Useful commands:"
    info "  kubectl get all -n $NAMESPACE"
    info "  kubectl logs -f deployment/addtocloud-backend -n $NAMESPACE"
    info "  kubectl logs -f deployment/addtocloud-frontend -n $NAMESPACE"
    info "  istioctl proxy-status"
}

# Run main function
main "$@"
