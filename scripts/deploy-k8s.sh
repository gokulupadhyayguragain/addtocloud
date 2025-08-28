#!/bin/bash

# =============================================================================
# AddToCloud Secrets Generator and Kubernetes Deployment Script
# =============================================================================

set -e

PROJECT_NAME="addtocloud"
NAMESPACE="addtocloud"

echo "🚀 Starting AddToCloud secrets generation and Kubernetes deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to generate secure passwords
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate hex keys
generate_hex_key() {
    openssl rand -hex 16
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    local deps=("kubectl" "openssl" "base64")
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            print_error "$dep is not installed. Please install it first."
            exit 1
        fi
    done
    
    print_status "All dependencies are installed ✓"
}

# Generate all secrets
generate_secrets() {
    print_status "Generating secure secrets..."
    
    # Database passwords
    export POSTGRES_PASSWORD=$(generate_password)
    export MONGODB_PASSWORD=$(generate_password)
    export REDIS_PASSWORD=$(generate_password)
    
    # JWT and encryption
    export JWT_SECRET=$(openssl rand -base64 32)
    export ENCRYPTION_KEY=$(generate_hex_key)
    export SESSION_SECRET=$(openssl rand -base64 32)
    
    # Create secrets file
    cat > .env.secrets << EOF
# =============================================================================
# AddToCloud Generated Secrets - Keep Secure!
# Generated on: $(date)
# =============================================================================

# Database Passwords
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
MONGODB_PASSWORD=${MONGODB_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}

# JWT and Encryption
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
SESSION_SECRET=${SESSION_SECRET}

# Cloud Provider Credentials (UPDATE THESE)
AZURE_SUBSCRIPTION_ID=your-azure-subscription-id
AZURE_CLIENT_ID=your-azure-client-id
AZURE_CLIENT_SECRET=your-azure-client-secret
AZURE_TENANT_ID=your-azure-tenant-id

AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key

GCP_PROJECT_ID=your-gcp-project-id

# Payment Providers (UPDATE THESE)
STRIPE_SECRET_KEY=sk_live_your-stripe-secret-key
STRIPE_PUBLISHABLE_KEY=pk_live_your-stripe-publishable-key
STRIPE_WEBHOOK_SECRET=whsec_your-stripe-webhook-secret

PAYONEER_API_KEY=your-payoneer-api-key
PAYONEER_WEBHOOK_SECRET=your-payoneer-webhook-secret

# Email Configuration (UPDATE THESE)
SMTP_HOST=smtp.gmail.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Analytics (UPDATE THESE)
GOOGLE_ANALYTICS_ID=GA-XXXXXXXXX-X
MIXPANEL_TOKEN=your-mixpanel-token

# Communication (UPDATE THESE)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/your/webhook/url
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your/webhook/url
EOF

    print_status "Secrets generated and saved to .env.secrets ✓"
    print_warning "Remember to update cloud provider and service credentials in .env.secrets"
}

# Create Kubernetes namespace
create_namespace() {
    print_status "Creating Kubernetes namespace: $NAMESPACE"
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace $NAMESPACE istio-injection=enabled --overwrite
    
    print_status "Namespace created and labeled for Istio injection ✓"
}

# Create Kubernetes secrets
create_k8s_secrets() {
    print_status "Creating Kubernetes secrets..."
    
    # Database secrets
    kubectl create secret generic database-secrets \
        --from-literal=postgres-password="$POSTGRES_PASSWORD" \
        --from-literal=mongodb-password="$MONGODB_PASSWORD" \
        --from-literal=redis-password="$REDIS_PASSWORD" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # JWT and encryption secrets
    kubectl create secret generic jwt-secrets \
        --from-literal=jwt-secret="$JWT_SECRET" \
        --from-literal=encryption-key="$ENCRYPTION_KEY" \
        --from-literal=session-secret="$SESSION_SECRET" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_status "Kubernetes secrets created ✓"
}

# Deploy databases
deploy_databases() {
    print_status "Deploying databases to Kubernetes..."
    
    # Apply persistent volume claims and secrets
    kubectl apply -f infrastructure/kubernetes/databases/secrets-and-storage.yaml -n $NAMESPACE
    
    # Apply database deployments
    kubectl apply -f infrastructure/kubernetes/databases/databases.yaml -n $NAMESPACE
    
    print_status "Databases deployed ✓"
}

# Wait for databases to be ready
wait_for_databases() {
    print_status "Waiting for databases to be ready..."
    
    kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s -n $NAMESPACE
    kubectl wait --for=condition=ready pod -l app=mongodb --timeout=300s -n $NAMESPACE
    kubectl wait --for=condition=ready pod -l app=redis --timeout=300s -n $NAMESPACE
    
    print_status "All databases are ready ✓"
}

# Deploy applications
deploy_applications() {
    print_status "Deploying AddToCloud applications..."
    
    # Apply backend deployment
    kubectl apply -f infrastructure/kubernetes/deployments/backend.yaml -n $NAMESPACE
    
    # Apply frontend deployment
    kubectl apply -f infrastructure/kubernetes/deployments/frontend.yaml -n $NAMESPACE
    
    # Apply services
    kubectl apply -f infrastructure/kubernetes/services/ -n $NAMESPACE
    
    print_status "Applications deployed ✓"
}

# Deploy Istio configurations
deploy_istio() {
    if [ "$1" = "--skip-istio" ]; then
        print_warning "Skipping Istio deployment"
        return
    fi
    
    print_status "Deploying Istio configurations..."
    
    # Check if Istio is installed
    if ! kubectl get namespace istio-system &> /dev/null; then
        print_warning "Istio system namespace not found. Please install Istio first."
        print_warning "Run: curl -L https://istio.io/downloadIstio | sh -"
        return
    fi
    
    # Apply Istio configs
    kubectl apply -f infrastructure/istio/ -n $NAMESPACE
    
    print_status "Istio configurations deployed ✓"
}

# Display connection information
display_info() {
    print_status "Deployment completed! 🎉"
    echo ""
    echo "============================================================================="
    echo "AddToCloud Platform Deployment Information"
    echo "============================================================================="
    echo ""
    
    # Get service information
    echo "📋 Services:"
    kubectl get services -n $NAMESPACE
    echo ""
    
    # Get pod status
    echo "🚀 Pods:"
    kubectl get pods -n $NAMESPACE
    echo ""
    
    # Database connection strings
    echo "🗄️  Database Connection Information:"
    echo "PostgreSQL: postgres://addtocloud:\${POSTGRES_PASSWORD}@postgres-service.$NAMESPACE.svc.cluster.local:5432/addtocloud"
    echo "MongoDB:    mongodb://mongodb-service.$NAMESPACE.svc.cluster.local:27017/addtocloud"
    echo "Redis:      redis://redis-service.$NAMESPACE.svc.cluster.local:6379"
    echo ""
    
    # Port forwarding commands
    echo "🔗 Port Forwarding Commands:"
    echo "Backend:   kubectl port-forward service/backend-service 8080:8080 -n $NAMESPACE"
    echo "Frontend:  kubectl port-forward service/frontend-service 3000:3000 -n $NAMESPACE"
    echo "Postgres:  kubectl port-forward service/postgres-service 5432:5432 -n $NAMESPACE"
    echo "MongoDB:   kubectl port-forward service/mongodb-service 27017:27017 -n $NAMESPACE"
    echo "Redis:     kubectl port-forward service/redis-service 6379:6379 -n $NAMESPACE"
    echo ""
    
    # Next steps
    echo "📝 Next Steps:"
    echo "1. Update cloud provider credentials in .env.secrets"
    echo "2. Configure external services (Stripe, Payoneer, etc.)"
    echo "3. Set up domain and SSL certificates"
    echo "4. Configure monitoring and logging"
    echo ""
    
    print_warning "⚠️  Keep .env.secrets file secure and never commit to version control!"
}

# Cleanup function
cleanup() {
    if [ "$1" = "--cleanup" ]; then
        print_warning "Cleaning up AddToCloud deployment..."
        kubectl delete namespace $NAMESPACE --ignore-not-found=true
        rm -f .env.secrets
        print_status "Cleanup completed"
        exit 0
    fi
}

# Main execution flow
main() {
    echo "==============================================================================="
    echo "🌩️  AddToCloud Kubernetes Deployment Script"
    echo "==============================================================================="
    echo ""
    
    # Handle cleanup
    cleanup "$1"
    
    # Check dependencies
    check_dependencies
    
    # Generate secrets
    generate_secrets
    
    # Create namespace
    create_namespace
    
    # Create Kubernetes secrets
    create_k8s_secrets
    
    # Deploy databases
    deploy_databases
    
    # Wait for databases
    wait_for_databases
    
    # Deploy applications
    deploy_applications
    
    # Deploy Istio (optional)
    deploy_istio "$1"
    
    # Display information
    display_info
    
    echo ""
    print_status "AddToCloud deployment completed successfully! 🚀"
}

# Script usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --cleanup      Remove all AddToCloud resources from Kubernetes"
    echo "  --skip-istio   Skip Istio service mesh deployment"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full deployment with Istio"
    echo "  $0 --skip-istio      # Deploy without Istio"
    echo "  $0 --cleanup         # Remove all resources"
}

# Handle command line arguments
case "${1:-}" in
    --help)
        usage
        exit 0
        ;;
    --cleanup)
        cleanup "$1"
        ;;
    *)
        main "$1"
        ;;
esac
