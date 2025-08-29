#!/bin/bash

# Multi-Cloud Istio Service Mesh Deployment Script
# Deploys Istio across AWS EKS and Azure AKS clusters

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cluster contexts
AWS_CONTEXT="arn:aws:eks:us-west-2:741448922544:cluster/addtocloud-prod-eks"
AZURE_CONTEXT="aks-addtocloud-prod"
GCP_CONTEXT="gke_static-operator-469115-h1_us-central1-a_addtocloud-gke-cluster"

echo -e "${BLUE}🌩️ Starting Multi-Cloud Istio Service Mesh Deployment${NC}"
echo "======================================================="

# Function to check if kubectl context exists
check_context() {
    local context=$1
    if kubectl config get-contexts "$context" &>/dev/null; then
        echo -e "${GREEN}✅ Context '$context' found${NC}"
        return 0
    else
        echo -e "${RED}❌ Context '$context' not found${NC}"
        return 1
    fi
}

# Function to install Istio on a cluster
install_istio_on_cluster() {
    local context=$1
    local cluster_id=$2
    local cluster_name=$3
    
    echo -e "${YELLOW}📦 Installing Istio on $cluster_name...${NC}"
    
    # Switch to the cluster context
    kubectl config use-context "$context"
    
    # Check if cluster is accessible
    if ! kubectl get nodes &>/dev/null; then
        echo -e "${RED}❌ Cannot access cluster $cluster_name${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Cluster $cluster_name is accessible${NC}"
    
    # Install Istio
    istioctl install --set values.pilot.env.CLUSTER_ID="$cluster_id" \
                     --set values.istiodRemote.enabled=false \
                     --set values.pilot.env.ENABLE_CROSS_CLUSTER_WORKLOAD_ENTRY=true \
                     --set values.pilot.env.PILOT_ENABLE_REMOTE_JWKS=true \
                     --set meshConfig.trustDomain="addtocloud.local" \
                     --set meshConfig.defaultConfig.proxyStatsMatcher.inclusionRegexps=".*outlier_detection.*" \
                     --set meshConfig.defaultConfig.proxyStatsMatcher.exclusionRegexps=".*osconfig.*" \
                     -y
    
    # Label the default namespace for Istio injection
    kubectl label namespace default istio-injection=enabled --overwrite
    
    # Wait for Istio to be ready
    echo -e "${YELLOW}⏳ Waiting for Istio to be ready on $cluster_name...${NC}"
    kubectl wait --for=condition=available --timeout=300s deployment/istiod -n istio-system
    
    echo -e "${GREEN}✅ Istio installed successfully on $cluster_name${NC}"
}

# Function to create namespace and secrets
setup_multicluster_networking() {
    echo -e "${YELLOW}🔗 Setting up multi-cluster networking...${NC}"
    
    # Create istio-system namespace on all clusters if not exists
    for context in "$AWS_CONTEXT" "$AZURE_CONTEXT"; do
        kubectl --context="$context" create namespace istio-system --dry-run=client -o yaml | kubectl --context="$context" apply -f -
    done
    
    # Create cross-cluster secrets
    echo -e "${YELLOW}📝 Creating cross-cluster secrets...${NC}"
    
    # AWS to Azure
    istioctl x create-remote-secret \
        --context="$AWS_CONTEXT" \
        --name=aws-cluster \
        --server="$(kubectl --context="$AWS_CONTEXT" config view --raw -o jsonpath='{.clusters[0].cluster.server}')" | \
        kubectl apply --context="$AZURE_CONTEXT" -f -
    
    # Azure to AWS
    istioctl x create-remote-secret \
        --context="$AZURE_CONTEXT" \
        --name=azure-cluster \
        --server="$(kubectl --context="$AZURE_CONTEXT" config view --raw -o jsonpath='{.clusters[0].cluster.server}')" | \
        kubectl apply --context="$AWS_CONTEXT" -f -
    
    echo -e "${GREEN}✅ Multi-cluster networking configured${NC}"
}

# Function to deploy Istio gateway and virtual services
deploy_istio_gateway() {
    local context=$1
    local cluster_name=$2
    
    echo -e "${YELLOW}🌐 Deploying Istio Gateway on $cluster_name...${NC}"
    
    kubectl --context="$context" apply -f - << EOF
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: addtocloud-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
    tls:
      httpsRedirect: true
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: addtocloud-tls
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: addtocloud-api
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - istio-system/addtocloud-gateway
  http:
  - match:
    - uri:
        prefix: "/api"
    route:
    - destination:
        host: addtocloud-api
        port:
          number: 8080
  - match:
    - uri:
        prefix: "/health"
    route:
    - destination:
        host: addtocloud-api
        port:
          number: 8080
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: addtocloud-frontend
        port:
          number: 3000
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: addtocloud-api
  namespace: default
spec:
  host: addtocloud-api
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 10
    circuitBreaker:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
EOF

    echo -e "${GREEN}✅ Istio Gateway deployed on $cluster_name${NC}"
}

# Function to verify installation
verify_installation() {
    local context=$1
    local cluster_name=$2
    
    echo -e "${YELLOW}🔍 Verifying Istio installation on $cluster_name...${NC}"
    
    # Check Istio pods
    echo "Istio system pods:"
    kubectl --context="$context" get pods -n istio-system
    
    # Check gateway
    echo -e "\nIstio gateway:"
    kubectl --context="$context" get gateway -A
    
    # Check virtual services
    echo -e "\nVirtual services:"
    kubectl --context="$context" get virtualservice -A
    
    # Get load balancer IP/hostname
    echo -e "\nLoad balancer details:"
    kubectl --context="$context" get svc istio-ingressgateway -n istio-system
    
    echo -e "${GREEN}✅ Verification complete for $cluster_name${NC}"
}

# Main deployment function
main() {
    echo -e "${BLUE}🚀 Starting multi-cloud service mesh deployment...${NC}"
    
    # Check prerequisites
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed${NC}"
        exit 1
    fi
    
    if ! command -v istioctl &> /dev/null; then
        echo -e "${RED}❌ istioctl is not installed${NC}"
        echo -e "${YELLOW}💡 Install Istio CLI: https://istio.io/latest/docs/setup/getting-started/#download${NC}"
        exit 1
    fi
    
    # Check cluster contexts
    echo -e "${YELLOW}🔍 Checking cluster contexts...${NC}"
    
    aws_available=false
    azure_available=false
    
    if check_context "$AWS_CONTEXT"; then
        aws_available=true
    fi
    
    if check_context "$AZURE_CONTEXT"; then
        azure_available=true
    fi
    
    if [ "$aws_available" = false ] && [ "$azure_available" = false ]; then
        echo -e "${RED}❌ No available clusters found${NC}"
        exit 1
    fi
    
    # Install Istio on available clusters
    if [ "$aws_available" = true ]; then
        install_istio_on_cluster "$AWS_CONTEXT" "aws-primary" "AWS EKS"
        deploy_istio_gateway "$AWS_CONTEXT" "AWS EKS"
    fi
    
    if [ "$azure_available" = true ]; then
        install_istio_on_cluster "$AZURE_CONTEXT" "azure-secondary" "Azure AKS"
        deploy_istio_gateway "$AZURE_CONTEXT" "Azure AKS"
    fi
    
    # Setup multi-cluster networking if both clusters are available
    if [ "$aws_available" = true ] && [ "$azure_available" = true ]; then
        setup_multicluster_networking
    fi
    
    # Verify installations
    if [ "$aws_available" = true ]; then
        echo -e "\n${BLUE}🔍 Verifying AWS EKS installation...${NC}"
        verify_installation "$AWS_CONTEXT" "AWS EKS"
    fi
    
    if [ "$azure_available" = true ]; then
        echo -e "\n${BLUE}🔍 Verifying Azure AKS installation...${NC}"
        verify_installation "$AZURE_CONTEXT" "Azure AKS"
    fi
    
    echo -e "\n${GREEN}🎉 Multi-cloud service mesh deployment completed!${NC}"
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "  1. Deploy your applications with Istio sidecar injection"
    echo -e "  2. Configure SSL certificates for HTTPS"
    echo -e "  3. Set up monitoring with Prometheus and Grafana"
    echo -e "  4. Configure Cloudflare load balancing"
    
    # Display load balancer endpoints
    echo -e "\n${BLUE}🌐 Load Balancer Endpoints:${NC}"
    if [ "$aws_available" = true ]; then
        echo -e "${YELLOW}AWS EKS:${NC}"
        kubectl --context="$AWS_CONTEXT" get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' && echo
    fi
    
    if [ "$azure_available" = true ]; then
        echo -e "${YELLOW}Azure AKS:${NC}"
        kubectl --context="$AZURE_CONTEXT" get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo
    fi
}

# Run main function
main "$@"
