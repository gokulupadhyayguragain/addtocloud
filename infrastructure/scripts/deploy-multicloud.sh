#!/bin/bash

# AddToCloud Multi-Cloud Deployment Script
# This script deploys AddToCloud to Azure AKS, AWS EKS, and GCP GKE

set -e

echo "🚀 Starting AddToCloud Multi-Cloud Deployment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_IMAGE="addtocloud/frontend:latest"
BACKEND_IMAGE="addtocloud/backend:latest"
NAMESPACE="addtocloud"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

log_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "docker is not installed. Please install docker first."
        exit 1
    fi
    
    # Check if kustomize is installed
    if ! command -v kustomize &> /dev/null; then
        log_error "kustomize is not installed. Please install kustomize first."
        exit 1
    fi
    
    log_success "All prerequisites are met"
}

# Build and tag Docker images
build_images() {
    log_info "Building Docker images..."
    
    # Build frontend
    docker build -f infrastructure/docker/Dockerfile.frontend -t $FRONTEND_IMAGE .
    log_success "Frontend image built successfully"
    
    # Build backend
    docker build -f infrastructure/docker/Dockerfile.backend -t $BACKEND_IMAGE .
    log_success "Backend image built successfully"
}

# Deploy to Azure AKS
deploy_azure() {
    log_info "Deploying to Azure AKS..."
    
    # Set Azure context (assumes AKS cluster is already created)
    if kubectl config get-contexts | grep -q "azure-aks"; then
        kubectl config use-context azure-aks
    else
        log_warning "Azure AKS context not found. Please configure your AKS cluster first."
        return 1
    fi
    
    # Tag and push images to ACR
    ACR_NAME="addtocloudacr.azurecr.io"
    docker tag $FRONTEND_IMAGE $ACR_NAME/addtocloud/frontend:latest
    docker tag $BACKEND_IMAGE $ACR_NAME/addtocloud/backend:latest
    
    docker push $ACR_NAME/addtocloud/frontend:latest
    docker push $ACR_NAME/addtocloud/backend:latest
    
    # Apply Kubernetes manifests
    kustomize build infrastructure/kubernetes/overlays/azure | kubectl apply -f -
    
    log_success "Deployment to Azure AKS completed"
}

# Deploy to AWS EKS
deploy_aws() {
    log_info "Deploying to AWS EKS..."
    
    # Set AWS context (assumes EKS cluster is already created)
    if kubectl config get-contexts | grep -q "aws-eks"; then
        kubectl config use-context aws-eks
    else
        log_warning "AWS EKS context not found. Please configure your EKS cluster first."
        return 1
    fi
    
    # Tag and push images to ECR
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION="us-west-2"
    ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    
    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Create repositories if they don't exist
    aws ecr describe-repositories --repository-names addtocloud/frontend --region $AWS_REGION || aws ecr create-repository --repository-name addtocloud/frontend --region $AWS_REGION
    aws ecr describe-repositories --repository-names addtocloud/backend --region $AWS_REGION || aws ecr create-repository --repository-name addtocloud/backend --region $AWS_REGION
    
    docker tag $FRONTEND_IMAGE $ECR_REGISTRY/addtocloud/frontend:latest
    docker tag $BACKEND_IMAGE $ECR_REGISTRY/addtocloud/backend:latest
    
    docker push $ECR_REGISTRY/addtocloud/frontend:latest
    docker push $ECR_REGISTRY/addtocloud/backend:latest
    
    # Apply Kubernetes manifests
    kustomize build infrastructure/kubernetes/overlays/aws | kubectl apply -f -
    
    log_success "Deployment to AWS EKS completed"
}

# Deploy to GCP GKE
deploy_gcp() {
    log_info "Deploying to GCP GKE..."
    
    # Set GCP context (assumes GKE cluster is already created)
    if kubectl config get-contexts | grep -q "gcp-gke"; then
        kubectl config use-context gcp-gke
    else
        log_warning "GCP GKE context not found. Please configure your GKE cluster first."
        return 1
    fi
    
    # Tag and push images to GCR
    GCP_PROJECT_ID="addtocloud-project"
    GCR_HOSTNAME="gcr.io"
    
    docker tag $FRONTEND_IMAGE $GCR_HOSTNAME/$GCP_PROJECT_ID/frontend:latest
    docker tag $BACKEND_IMAGE $GCR_HOSTNAME/$GCP_PROJECT_ID/backend:latest
    
    docker push $GCR_HOSTNAME/$GCP_PROJECT_ID/frontend:latest
    docker push $GCR_HOSTNAME/$GCP_PROJECT_ID/backend:latest
    
    # Apply Kubernetes manifests
    kustomize build infrastructure/kubernetes/overlays/gcp | kubectl apply -f -
    
    log_success "Deployment to GCP GKE completed"
}

# Monitor deployment status
monitor_deployment() {
    log_info "Monitoring deployment status..."
    
    local context=$1
    kubectl config use-context $context
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=addtocloud-frontend -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=addtocloud-backend -n $NAMESPACE --timeout=300s
    
    # Get deployment status
    kubectl get pods -n $NAMESPACE
    kubectl get services -n $NAMESPACE
    
    log_success "Deployment monitoring completed for $context"
}

# Main deployment function
main() {
    check_prerequisites
    build_images
    
    # Deploy to all clouds
    if [ "$1" == "azure" ] || [ "$1" == "all" ]; then
        deploy_azure
    fi
    
    if [ "$1" == "aws" ] || [ "$1" == "all" ]; then
        deploy_aws
    fi
    
    if [ "$1" == "gcp" ] || [ "$1" == "all" ]; then
        deploy_gcp
    fi
    
    log_success "🎉 Multi-cloud deployment completed successfully!"
    
    echo ""
    echo "📊 Deployment Summary:"
    echo "├── Frontend: 399 pages with professional UI"
    echo "├── Backend: Go microservices with REST/GraphQL APIs"
    echo "├── Databases: PostgreSQL, MongoDB, Redis"
    echo "├── Cloud Providers: Azure AKS, AWS EKS, GCP GKE"
    echo "└── Features: Auto-scaling, SSL/TLS, Load balancing"
    echo ""
    
    # Display access URLs
    echo "🌐 Access URLs:"
    echo "├── Production: https://addtocloud.tech"
    echo "├── API: https://api.addtocloud.tech"
    echo "└── WWW: https://www.addtocloud.tech"
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [azure|aws|gcp|all]"
    echo ""
    echo "Examples:"
    echo "  $0 all      # Deploy to all cloud providers"
    echo "  $0 azure    # Deploy to Azure AKS only"
    echo "  $0 aws      # Deploy to AWS EKS only"
    echo "  $0 gcp      # Deploy to GCP GKE only"
    exit 1
fi

main $1
