#!/bin/bash

# =============================================================================
# AddToCloud Multi-Cloud Deployment Script (Cloudflare Frontend)
# =============================================================================
# This script deploys frontend to Cloudflare and backend to multi-cloud

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="addtocloud"
ENVIRONMENT="${ENVIRONMENT:-production}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Deployment flags
DEPLOY_FRONTEND=${DEPLOY_FRONTEND:-true}
DEPLOY_BACKEND=${DEPLOY_BACKEND:-true}
DEPLOY_AZURE=${DEPLOY_AZURE:-true}
DEPLOY_AWS=${DEPLOY_AWS:-true}
DEPLOY_GCP=${DEPLOY_GCP:-true}

# Logging functions
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

success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Show help
show_help() {
    cat << EOF
AddToCloud Deployment Script

Usage: $0 [OPTIONS]

Options:
    --frontend-only          Deploy only frontend to Cloudflare
    --backend-only           Deploy only backend to clouds
    --skip-azure            Skip Azure deployment
    --skip-aws              Skip AWS deployment
    --skip-gcp              Skip GCP deployment
    --environment ENV       Set environment (development|staging|production)
    --help                  Show this help message

Examples:
    $0                                    # Deploy everything
    $0 --frontend-only                    # Deploy only frontend
    $0 --backend-only --skip-azure        # Deploy backend to AWS and GCP only
    $0 --environment staging              # Deploy to staging environment

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --frontend-only)
                DEPLOY_FRONTEND=true
                DEPLOY_BACKEND=false
                shift
                ;;
            --backend-only)
                DEPLOY_FRONTEND=false
                DEPLOY_BACKEND=true
                shift
                ;;
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
            --environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    local tools=("node" "npm" "docker" "kubectl" "terraform")
    
    # Add cloud CLI tools based on deployment flags
    if [[ "$DEPLOY_FRONTEND" == "true" ]]; then
        tools+=("wrangler")
    fi
    
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
    
    success "All prerequisites checked"
}

# Setup environment
setup_environment() {
    log "Setting up environment for $ENVIRONMENT..."
    
    # Create necessary directories
    mkdir -p "$ROOT_DIR/logs"
    mkdir -p "$ROOT_DIR/tmp"
    
    # Load environment variables
    if [[ -f "$ROOT_DIR/.env" ]]; then
        set -a
        source "$ROOT_DIR/.env"
        set +a
        info "✓ Environment variables loaded"
    fi
    
    # Load environment-specific variables
    local env_file="$ROOT_DIR/.env.$ENVIRONMENT"
    if [[ -f "$env_file" ]]; then
        set -a
        source "$env_file"
        set +a
        info "✓ Environment-specific variables loaded"
    fi
    
    success "Environment setup complete"
}

# Deploy frontend to Cloudflare
deploy_frontend() {
    if [[ "$DEPLOY_FRONTEND" != "true" ]]; then
        info "Skipping frontend deployment"
        return 0
    fi
    
    log "Deploying frontend to Cloudflare Pages..."
    
    cd "$ROOT_DIR/frontend"
    
    # Install dependencies
    info "Installing frontend dependencies..."
    npm ci
    
    # Set environment variables for build
    export NEXT_PUBLIC_ENVIRONMENT="$ENVIRONMENT"
    
    case "$ENVIRONMENT" in
        production)
            export NEXT_PUBLIC_API_URL="https://api.addtocloud.tech"
            export NEXT_PUBLIC_APP_URL="https://addtocloud.tech"
            ;;
        staging)
            export NEXT_PUBLIC_API_URL="https://staging-api.addtocloud.tech"
            export NEXT_PUBLIC_APP_URL="https://staging.addtocloud.tech"
            ;;
        development)
            export NEXT_PUBLIC_API_URL="http://localhost:8080"
            export NEXT_PUBLIC_APP_URL="http://localhost:3000"
            ;;
    esac
    
    # Build and export
    info "Building frontend for static export..."
    npm run build:export
    
    # Deploy to Cloudflare
    info "Deploying to Cloudflare Pages..."
    if [[ "$ENVIRONMENT" == "production" ]]; then
        wrangler pages deploy out --project-name addtocloud-frontend --env production
    else
        wrangler pages deploy out --project-name addtocloud-frontend --env "$ENVIRONMENT"
    fi
    
    success "Frontend deployed to Cloudflare Pages"
}

# Build Docker images
build_docker_images() {
    log "Building Docker images..."
    
    cd "$ROOT_DIR"
    
    # Build backend image
    info "Building backend Docker image..."
    docker build -t "addtocloud-backend:latest" -f infrastructure/docker/Dockerfile.backend .
    
    # Build frontend image (for development/backup)
    info "Building frontend Docker image..."
    docker build -t "addtocloud-frontend:latest" -f infrastructure/docker/Dockerfile.frontend .
    
    success "Docker images built successfully"
}

# Deploy to Azure
deploy_azure() {
    if [[ "$DEPLOY_AZURE" != "true" ]]; then
        info "Skipping Azure deployment"
        return 0
    fi
    
    log "Deploying to Azure AKS..."
    
    cd "$ROOT_DIR/infrastructure/terraform/azure"
    
    # Initialize Terraform
    info "Initializing Terraform for Azure..."
    terraform init -input=false
    
    # Plan deployment
    info "Planning Azure infrastructure..."
    terraform plan -out=tfplan \
        -var="environment=$ENVIRONMENT" \
        -var="project_name=$PROJECT_NAME"
    
    # Apply deployment
    info "Applying Azure infrastructure..."
    terraform apply tfplan
    
    # Get AKS credentials
    local resource_group=$(terraform output -raw resource_group_name)
    local cluster_name=$(terraform output -raw cluster_name)
    
    info "Getting AKS credentials..."
    az aks get-credentials --resource-group "$resource_group" --name "$cluster_name" --overwrite-existing
    
    # Deploy to Kubernetes
    info "Deploying to AKS..."
    kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f "$ROOT_DIR/infrastructure/kubernetes/deployments/" -n addtocloud
    kubectl apply -f "$ROOT_DIR/infrastructure/istio/" -n addtocloud
    
    success "Azure deployment completed"
}

# Deploy to AWS
deploy_aws() {
    if [[ "$DEPLOY_AWS" != "true" ]]; then
        info "Skipping AWS deployment"
        return 0
    fi
    
    log "Deploying to AWS EKS..."
    
    cd "$ROOT_DIR/infrastructure/terraform/aws"
    
    # Initialize Terraform
    info "Initializing Terraform for AWS..."
    terraform init -input=false
    
    # Plan deployment
    info "Planning AWS infrastructure..."
    terraform plan -out=tfplan \
        -var="environment=$ENVIRONMENT" \
        -var="project_name=$PROJECT_NAME"
    
    # Apply deployment
    info "Applying AWS infrastructure..."
    terraform apply tfplan
    
    # Get EKS credentials
    local cluster_name=$(terraform output -raw cluster_name)
    local region=$(terraform output -raw region)
    
    info "Getting EKS credentials..."
    aws eks update-kubeconfig --region "$region" --name "$cluster_name"
    
    # Deploy to Kubernetes
    info "Deploying to EKS..."
    kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f "$ROOT_DIR/infrastructure/kubernetes/deployments/" -n addtocloud
    kubectl apply -f "$ROOT_DIR/infrastructure/istio/" -n addtocloud
    
    success "AWS deployment completed"
}

# Deploy to GCP
deploy_gcp() {
    if [[ "$DEPLOY_GCP" != "true" ]]; then
        info "Skipping GCP deployment"
        return 0
    fi
    
    log "Deploying to GCP GKE..."
    
    cd "$ROOT_DIR/infrastructure/terraform/gcp"
    
    # Initialize Terraform
    info "Initializing Terraform for GCP..."
    terraform init -input=false
    
    # Plan deployment
    info "Planning GCP infrastructure..."
    terraform plan -out=tfplan \
        -var="environment=$ENVIRONMENT" \
        -var="project_name=$PROJECT_NAME"
    
    # Apply deployment
    info "Applying GCP infrastructure..."
    terraform apply tfplan
    
    # Get GKE credentials
    local cluster_name=$(terraform output -raw cluster_name)
    local zone=$(terraform output -raw zone)
    local project_id=$(terraform output -raw project_id)
    
    info "Getting GKE credentials..."
    gcloud container clusters get-credentials "$cluster_name" --zone "$zone" --project "$project_id"
    
    # Deploy to Kubernetes
    info "Deploying to GKE..."
    kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f "$ROOT_DIR/infrastructure/kubernetes/deployments/" -n addtocloud
    kubectl apply -f "$ROOT_DIR/infrastructure/istio/" -n addtocloud
    
    success "GCP deployment completed"
}

# Verify deployments
verify_deployments() {
    log "Verifying deployments..."
    
    if [[ "$DEPLOY_FRONTEND" == "true" ]]; then
        info "Frontend deployed to Cloudflare Pages"
        case "$ENVIRONMENT" in
            production)
                info "Frontend URL: https://addtocloud.tech"
                ;;
            staging)
                info "Frontend URL: https://staging.addtocloud.tech"
                ;;
            development)
                info "Frontend URL: Check Cloudflare Pages dashboard"
                ;;
        esac
    fi
    
    if [[ "$DEPLOY_BACKEND" == "true" ]]; then
        info "Backend services status:"
        
        if [[ "$DEPLOY_AZURE" == "true" ]] || [[ "$DEPLOY_AWS" == "true" ]] || [[ "$DEPLOY_GCP" == "true" ]]; then
            kubectl get pods -n addtocloud 2>/dev/null || true
            kubectl get services -n addtocloud 2>/dev/null || true
        fi
    fi
    
    success "Deployment verification completed"
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    
    # Remove Terraform plan files
    find "$ROOT_DIR/infrastructure/terraform" -name "tfplan" -delete 2>/dev/null || true
    
    # Clean up Docker
    docker system prune -f &>/dev/null || true
    
    info "Cleanup completed"
}

# Main deployment function
main() {
    # Set up trap for cleanup
    trap cleanup EXIT
    
    log "🚀 Starting AddToCloud deployment..."
    info "Environment: $ENVIRONMENT"
    info "Frontend: $DEPLOY_FRONTEND"
    info "Backend: $DEPLOY_BACKEND (Azure: $DEPLOY_AZURE, AWS: $DEPLOY_AWS, GCP: $DEPLOY_GCP)"
    
    # Execute deployment steps
    check_prerequisites
    setup_environment
    
    # Deploy frontend to Cloudflare
    deploy_frontend
    
    # Deploy backend to clouds
    if [[ "$DEPLOY_BACKEND" == "true" ]]; then
        build_docker_images
        deploy_azure
        deploy_aws
        deploy_gcp
    fi
    
    # Verify deployments
    verify_deployments
    
    success "🎉 AddToCloud deployment completed successfully!"
    
    # Show useful information
    echo ""
    info "📋 Next steps:"
    info "1. Check your domain DNS settings"
    info "2. Verify SSL certificates"
    info "3. Test all application endpoints"
    info "4. Monitor deployment health"
    
    echo ""
    info "🔧 Useful commands:"
    info "  kubectl get all -n addtocloud"
    info "  kubectl logs -f deployment/addtocloud-backend -n addtocloud"
    info "  wrangler pages deployment list --project-name addtocloud-frontend"
}

# Parse arguments and run main function
parse_arguments "$@"
main
