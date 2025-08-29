#!/bin/bash
# AddToCloud Enterprise Multi-Cloud Deployment Script
# Uses: Terraform + Kubernetes + Istio + Helm + Kustomize + Ansible + Prometheus + Grafana

set -e

echo "🚀 AddToCloud Enterprise Multi-Cloud Deployment"
echo "================================================"

# Configuration
ENVIRONMENT=${1:-production}
CLOUD_PROVIDERS=${2:-"aws azure gcp"}
PROJECT_NAME="addtocloud"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Check prerequisites
check_tools() {
    log "Checking required tools..."
    
    tools=("terraform" "kubectl" "helm" "istioctl" "kustomize" "ansible" "docker")
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            warn "$tool not found. Installing..."
            case $tool in
                "terraform")
                    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
                    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
                    sudo apt-get update && sudo apt-get install terraform
                    ;;
                "kubectl")
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                    ;;
                "helm")
                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                    ;;
                "istioctl")
                    curl -L https://istio.io/downloadIstio | sh -
                    sudo mv istio-*/bin/istioctl /usr/local/bin/
                    ;;
                "kustomize")
                    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
                    sudo mv kustomize /usr/local/bin/
                    ;;
                "ansible")
                    sudo apt update && sudo apt install ansible -y
                    ;;
            esac
        else
            log "✅ $tool found"
        fi
    done
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    local cloud=$1
    log "🏗️  Deploying $cloud infrastructure with Terraform..."
    
    cd infrastructure/terraform/$cloud
    terraform init
    terraform workspace new $ENVIRONMENT-$cloud || terraform workspace select $ENVIRONMENT-$cloud
    terraform plan -var-file="../terraform.tfvars" -out=tfplan
    terraform apply tfplan
    cd ../../..
}

# Configure Kubernetes cluster
configure_cluster() {
    local cloud=$1
    log "⚙️  Configuring $cloud Kubernetes cluster..."
    
    case $cloud in
        "aws")
            aws eks update-kubeconfig --region us-west-2 --name $PROJECT_NAME-aws-$ENVIRONMENT
            kubectl config rename-context $(kubectl config current-context) aws-$ENVIRONMENT
            ;;
        "azure")
            az aks get-credentials --resource-group $PROJECT_NAME-azure-$ENVIRONMENT --name $PROJECT_NAME-azure-$ENVIRONMENT
            kubectl config rename-context $(kubectl config current-context) azure-$ENVIRONMENT
            ;;
        "gcp")
            gcloud container clusters get-credentials $PROJECT_NAME-gcp-$ENVIRONMENT --zone us-west1-a
            kubectl config rename-context $(kubectl config current-context) gcp-$ENVIRONMENT
            ;;
    esac
}

# Install Istio Service Mesh
install_istio() {
    local cloud=$1
    log "🕸️  Installing Istio service mesh on $cloud..."
    
    kubectl config use-context $cloud-$ENVIRONMENT
    istioctl install --set values.global.meshID=$cloud-mesh --set values.global.network=$cloud-network -y
    kubectl label namespace default istio-injection=enabled
    kubectl apply -f infrastructure/istio/
}

# Deploy monitoring stack
deploy_monitoring() {
    local cloud=$1
    log "📊 Deploying monitoring stack (Prometheus + Grafana) on $cloud..."
    
    kubectl config use-context $cloud-$ENVIRONMENT
    
    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Create monitoring namespace
    kubectl create namespace monitoring || true
    
    # Install Prometheus
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set grafana.adminPassword=admin123 \
        --set prometheus.prometheusSpec.retention=15d \
        --values infrastructure/monitoring/prometheus/values-$cloud.yaml
    
    # Install custom Grafana dashboards
    kubectl create configmap grafana-dashboards \
        --from-file=infrastructure/monitoring/grafana/dashboards/ \
        --namespace monitoring || true
}

# Deploy application with Helm and Kustomize
deploy_application() {
    local cloud=$1
    log "🚀 Deploying AddToCloud application on $cloud..."
    
    kubectl config use-context $cloud-$ENVIRONMENT
    
    # Create application namespace
    kubectl create namespace $PROJECT_NAME-prod || true
    kubectl label namespace $PROJECT_NAME-prod istio-injection=enabled
    
    # Deploy with Helm
    helm upgrade --install $PROJECT_NAME-platform infrastructure/helm \
        --namespace $PROJECT_NAME-prod \
        --values infrastructure/helm/values-$cloud.yaml \
        --set global.environment=$ENVIRONMENT \
        --set global.cloud=$cloud
    
    # Apply Kustomize overlays
    kustomize build infrastructure/kustomize/overlays/$ENVIRONMENT/$cloud | kubectl apply -f -
}

# Setup ArgoCD for GitOps
setup_argocd() {
    local cloud=$1
    log "🔄 Setting up ArgoCD GitOps on $cloud..."
    
    kubectl config use-context $cloud-$ENVIRONMENT
    
    # Install ArgoCD
    kubectl create namespace argocd || true
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
    
    # Apply application configurations
    kubectl apply -f devops/argocd/applications/$cloud-$ENVIRONMENT.yaml
}

# Configure cross-cluster service mesh
configure_mesh_federation() {
    log "🌐 Configuring cross-cluster service mesh federation..."
    
    # Create shared root certificates
    kubectl config use-context aws-$ENVIRONMENT
    kubectl get secret cacerts -n istio-system -o yaml > /tmp/cacerts.yaml
    
    for cloud in azure gcp; do
        if kubectl config get-contexts | grep -q "$cloud-$ENVIRONMENT"; then
            kubectl config use-context $cloud-$ENVIRONMENT
            kubectl apply -f /tmp/cacerts.yaml
        fi
    done
    
    # Apply cross-cluster configurations
    kubectl apply -f infrastructure/istio/cross-cluster/
}

# Verify deployments
verify_deployment() {
    local cloud=$1
    log "✅ Verifying $cloud deployment..."
    
    kubectl config use-context $cloud-$ENVIRONMENT
    
    echo "Pods in $PROJECT_NAME-prod namespace:"
    kubectl get pods -n $PROJECT_NAME-prod
    
    echo "Services in $PROJECT_NAME-prod namespace:"
    kubectl get svc -n $PROJECT_NAME-prod
    
    echo "Ingress gateways:"
    kubectl get svc -n istio-system istio-ingressgateway
    
    echo "Istio proxy status:"
    istioctl proxy-status
}

# Main deployment flow
main() {
    log "Starting AddToCloud Enterprise Multi-Cloud Deployment"
    
    # Check prerequisites
    check_tools
    
    # Deploy to each cloud provider
    for cloud in $CLOUD_PROVIDERS; do
        log "🌥️  Processing $cloud cloud deployment..."
        
        # Deploy infrastructure
        deploy_infrastructure $cloud
        
        # Configure cluster
        configure_cluster $cloud
        
        # Install service mesh
        install_istio $cloud
        
        # Deploy monitoring
        deploy_monitoring $cloud
        
        # Deploy application
        deploy_application $cloud
        
        # Setup GitOps
        setup_argocd $cloud
        
        # Verify deployment
        verify_deployment $cloud
        
        log "✅ $cloud deployment completed successfully!"
    done
    
    # Configure cross-cluster mesh if multiple clouds
    if [[ $(echo $CLOUD_PROVIDERS | wc -w) -gt 1 ]]; then
        configure_mesh_federation
    fi
    
    log "🎉 Enterprise Multi-Cloud Deployment Completed!"
    log "🌐 Access your applications:"
    
    for cloud in $CLOUD_PROVIDERS; do
        kubectl config use-context $cloud-$ENVIRONMENT
        INGRESS_IP=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
        INGRESS_HOSTNAME=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
        
        echo "  $cloud: http://${INGRESS_IP:-$INGRESS_HOSTNAME}"
        echo "  $cloud Grafana: http://${INGRESS_IP:-$INGRESS_HOSTNAME}/grafana (admin/admin123)"
    done
}

# Run deployment
main "$@"
