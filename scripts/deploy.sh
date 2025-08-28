#!/bin/bash

# AddToCloud Platform - Linux Deployment Script
# Supports deployment to AKS, EKS, and GKE
# Author: GitHub Copilot for gokulupadhyayguragain
# Version: 2.0.0

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="addtocloud-prod"
APP_NAME="addtocloud"
VERSION=${GITHUB_SHA:-$(date +%Y%m%d-%H%M%S)}

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking required dependencies..."
    
    dependencies=("kubectl" "docker" "helm")
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "$dep is not installed. Please install it first."
            exit 1
        else
            log_success "$dep is available"
        fi
    done
}

setup_namespace() {
    log_info "Setting up namespace: $NAMESPACE"
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace "$NAMESPACE" istio-injection=enabled --overwrite
    
    log_success "Namespace $NAMESPACE is ready"
}

deploy_to_eks() {
    log_info "Deploying to Amazon EKS..."
    
    # Set EKS context
    aws eks update-kubeconfig --region ${AWS_REGION:-us-east-1} --name ${EKS_CLUSTER_NAME:-addtocloud-eks}
    
    # Deploy using Kubernetes manifests
    kubectl apply -f infrastructure/kubernetes/deployments/ -n "$NAMESPACE"
    kubectl apply -f infrastructure/kubernetes/services/ -n "$NAMESPACE"
    
    # Wait for deployment
    kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=300s
    kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=300s
    
    log_success "Successfully deployed to EKS"
}

deploy_to_aks() {
    log_info "Deploying to Azure AKS..."
    
    # Set AKS context
    az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP:-addtocloud-rg} --name ${AKS_CLUSTER_NAME:-addtocloud-aks}
    
    # Deploy using Kubernetes manifests
    kubectl apply -f infrastructure/kubernetes/deployments/ -n "$NAMESPACE"
    kubectl apply -f infrastructure/kubernetes/services/ -n "$NAMESPACE"
    
    # Wait for deployment
    kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=300s
    kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=300s
    
    log_success "Successfully deployed to AKS"
}

deploy_to_gke() {
    log_info "Deploying to Google GKE..."
    
    # Set GKE context
    gcloud container clusters get-credentials ${GKE_CLUSTER_NAME:-addtocloud-gke} \
        --zone ${GKE_ZONE:-us-central1-a} \
        --project ${GCP_PROJECT_ID}
    
    # Deploy using Kubernetes manifests
    kubectl apply -f infrastructure/kubernetes/deployments/ -n "$NAMESPACE"
    kubectl apply -f infrastructure/kubernetes/services/ -n "$NAMESPACE"
    
    # Wait for deployment
    kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=300s
    kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=300s
    
    log_success "Successfully deployed to GKE"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pod status
    kubectl get pods -n "$NAMESPACE"
    
    # Check service status
    kubectl get services -n "$NAMESPACE"
    
    # Check ingress
    kubectl get ingress -n "$NAMESPACE"
    
    # Health check
    FRONTEND_POD=$(kubectl get pods -n "$NAMESPACE" -l app=frontend -o jsonpath='{.items[0].metadata.name}')
    BACKEND_POD=$(kubectl get pods -n "$NAMESPACE" -l app=backend -o jsonpath='{.items[0].metadata.name}')
    
    if [ ! -z "$FRONTEND_POD" ] && [ ! -z "$BACKEND_POD" ]; then
        log_success "All pods are running successfully"
        
        # Port forward for local testing (optional)
        log_info "To test locally, run:"
        log_info "kubectl port-forward -n $NAMESPACE service/frontend 3000:3000"
        log_info "kubectl port-forward -n $NAMESPACE service/backend 8080:8080"
    else
        log_error "Some pods are not running. Check deployment status."
        exit 1
    fi
}

setup_monitoring() {
    log_info "Setting up monitoring..."
    
    # Apply Prometheus configuration
    kubectl apply -f infrastructure/monitoring/prometheus/ -n "$NAMESPACE"
    
    # Apply Grafana configuration
    kubectl apply -f infrastructure/monitoring/grafana/ -n "$NAMESPACE"
    
    log_success "Monitoring setup completed"
}

cleanup() {
    log_warning "Cleaning up resources..."
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    log_success "Cleanup completed"
}

show_help() {
    echo "AddToCloud Platform Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  eks        Deploy to Amazon EKS"
    echo "  aks        Deploy to Azure AKS"
    echo "  gke        Deploy to Google GKE"
    echo "  all        Deploy to all cloud providers"
    echo "  verify     Verify deployment status"
    echo "  monitor    Setup monitoring"
    echo "  cleanup    Remove all resources"
    echo "  help       Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION           AWS region (default: us-east-1)"
    echo "  EKS_CLUSTER_NAME     EKS cluster name (default: addtocloud-eks)"
    echo "  AKS_RESOURCE_GROUP   Azure resource group (default: addtocloud-rg)"
    echo "  AKS_CLUSTER_NAME     AKS cluster name (default: addtocloud-aks)"
    echo "  GKE_CLUSTER_NAME     GKE cluster name (default: addtocloud-gke)"
    echo "  GKE_ZONE             GKE zone (default: us-central1-a)"
    echo "  GCP_PROJECT_ID       GCP project ID (required for GKE)"
    echo ""
    echo "Examples:"
    echo "  $0 eks                Deploy only to EKS"
    echo "  $0 all                Deploy to all cloud providers"
    echo "  $0 verify             Check deployment status"
}

# Main execution
main() {
    case "${1:-help}" in
        "eks")
            check_dependencies
            setup_namespace
            deploy_to_eks
            verify_deployment
            ;;
        "aks")
            check_dependencies
            setup_namespace
            deploy_to_aks
            verify_deployment
            ;;
        "gke")
            if [ -z "$GCP_PROJECT_ID" ]; then
                log_error "GCP_PROJECT_ID environment variable is required for GKE deployment"
                exit 1
            fi
            check_dependencies
            setup_namespace
            deploy_to_gke
            verify_deployment
            ;;
        "all")
            log_info "Deploying to all cloud providers..."
            check_dependencies
            setup_namespace
            
            # Deploy to EKS
            if [ ! -z "$AWS_REGION" ]; then
                deploy_to_eks
            else
                log_warning "Skipping EKS deployment - AWS_REGION not set"
            fi
            
            # Deploy to AKS
            if [ ! -z "$AKS_RESOURCE_GROUP" ]; then
                deploy_to_aks
            else
                log_warning "Skipping AKS deployment - AKS_RESOURCE_GROUP not set"
            fi
            
            # Deploy to GKE
            if [ ! -z "$GCP_PROJECT_ID" ]; then
                deploy_to_gke
            else
                log_warning "Skipping GKE deployment - GCP_PROJECT_ID not set"
            fi
            
            verify_deployment
            ;;
        "verify")
            verify_deployment
            ;;
        "monitor")
            setup_monitoring
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
