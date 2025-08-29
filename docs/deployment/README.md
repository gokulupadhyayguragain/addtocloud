# 🚀 Multi-Cloud Deployment Guide

This guide provides step-by-step instructions for deploying the AddToCloud platform across AWS, Azure, and Google Cloud Platform with Istio service mesh.

## 📋 Prerequisites

### Required Tools
```bash
# Core tools
node --version     # v18.0.0+
go version        # go1.21+
docker --version  # 20.0.0+
terraform --version # 1.5.0+

# Kubernetes tools
kubectl version --client  # v1.28+
helm version             # v3.12+

# Cloud CLI tools
aws --version            # aws-cli/2.13+
az --version            # azure-cli 2.50+
gcloud version          # Google Cloud SDK 440.0+

# Service mesh
istioctl version        # 1.19+
```

### Cloud Prerequisites

#### AWS Setup
```bash
# Configure AWS credentials
aws configure
# or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Verify access
aws sts get-caller-identity
```

#### Azure Setup
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Verify access
az account show
```

#### GCP Setup
```bash
# Authenticate with Google Cloud
gcloud auth login

# Set project
gcloud config set project your-project-id

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

## 🏗️ Infrastructure Deployment

### Step 1: Deploy AWS Infrastructure

```bash
# Navigate to AWS terraform directory
cd infrastructure/terraform/aws

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="node_count=3" -var="project_name=addtocloud" -var="environment=prod"

# Apply the configuration
terraform apply -auto-approve

# Verify outputs
terraform output
```

**Expected AWS Resources:**
- EKS Cluster: `addtocloud-prod-eks`
- RDS PostgreSQL: `addtocloud-prod-postgres`
- ECR Repository: `addtocloud-prod`
- VPC with public/private subnets
- IAM roles and security groups

### Step 2: Deploy Azure Infrastructure

```bash
# Navigate to Azure terraform directory
cd ../azure

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply -auto-approve

# Verify outputs
terraform output
```

**Expected Azure Resources:**
- AKS Cluster: `aks-addtocloud-prod`
- PostgreSQL Flexible Server
- Azure Container Registry: `addtocloudacr2025`
- Virtual Network and subnets
- Resource Group: `addtocloud-prod`

### Step 3: Deploy GCP Infrastructure

```bash
# Navigate to GCP terraform directory
cd ../gcp

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply -auto-approve

# Verify outputs
terraform output
```

**Expected GCP Resources:**
- GKE Cluster: `addtocloud-gke-cluster`
- Cloud SQL PostgreSQL
- Artifact Registry
- VPC and firewall rules
- Service accounts and IAM bindings

## 🔧 Kubernetes Configuration

### Step 1: Configure kubectl for All Clusters

```bash
# AWS EKS
aws eks update-kubeconfig --name addtocloud-prod-eks --region us-west-2

# Azure AKS
az aks get-credentials --name aks-addtocloud-prod --resource-group addtocloud-prod

# GCP GKE
gcloud container clusters get-credentials addtocloud-gke-cluster --zone us-central1-a
```

### Step 2: Verify Cluster Connectivity

```bash
# Check all contexts
kubectl config get-contexts

# Test each cluster
kubectl --context="arn:aws:eks:us-west-2:ACCOUNT:cluster/addtocloud-prod-eks" get nodes
kubectl --context="aks-addtocloud-prod" get nodes
kubectl --context="gke_PROJECT_us-central1-a_addtocloud-gke-cluster" get nodes
```

## 🕸️ Service Mesh Deployment

### Step 1: Install Istio on All Clusters

Create the Istio installation script:

```bash
# Create deployment script
cat > scripts/deploy-istio.sh << 'EOF'
#!/bin/bash

# Install Istio on AWS EKS
echo "Installing Istio on AWS EKS..."
kubectl config use-context arn:aws:eks:us-west-2:ACCOUNT:cluster/addtocloud-prod-eks
istioctl install --set values.pilot.env.CLUSTER_ID=aws-primary -y
kubectl label namespace default istio-injection=enabled

# Install Istio on Azure AKS
echo "Installing Istio on Azure AKS..."
kubectl config use-context aks-addtocloud-prod
istioctl install --set values.pilot.env.CLUSTER_ID=azure-secondary -y
kubectl label namespace default istio-injection=enabled

# Install Istio on GCP GKE
echo "Installing Istio on GCP GKE..."
kubectl config use-context gke_PROJECT_us-central1-a_addtocloud-gke-cluster
istioctl install --set values.pilot.env.CLUSTER_ID=gcp-tertiary -y
kubectl label namespace default istio-injection=enabled

echo "Istio installation complete on all clusters!"
EOF

chmod +x scripts/deploy-istio.sh
./scripts/deploy-istio.sh
```

### Step 2: Configure Multi-Cluster Service Mesh

```bash
# Create multi-cluster setup script
cat > scripts/setup-multicluster.sh << 'EOF'
#!/bin/bash

# Create cluster secrets for cross-cluster communication
echo "Setting up multi-cluster service mesh..."

# Get cluster endpoints and certificates
AWS_ENDPOINT=$(terraform -chdir=infrastructure/terraform/aws output -raw cluster_endpoint)
AWS_CERT=$(terraform -chdir=infrastructure/terraform/aws output -raw cluster_certificate_authority_data)

AZURE_ENDPOINT=$(kubectl --context=aks-addtocloud-prod config view --raw -o jsonpath='{.clusters[0].cluster.server}')
GCP_ENDPOINT=$(kubectl --context=gke_PROJECT_us-central1-a_addtocloud-gke-cluster config view --raw -o jsonpath='{.clusters[0].cluster.server}')

# Install cross-cluster secrets
istioctl x create-remote-secret --context=arn:aws:eks:us-west-2:ACCOUNT:cluster/addtocloud-prod-eks --name=aws-cluster | kubectl apply --context=aks-addtocloud-prod -f -
istioctl x create-remote-secret --context=aks-addtocloud-prod --name=azure-cluster | kubectl apply --context=arn:aws:eks:us-west-2:ACCOUNT:cluster/addtocloud-prod-eks -f -

echo "Multi-cluster service mesh setup complete!"
EOF

chmod +x scripts/setup-multicluster.sh
./scripts/setup-multicluster.sh
```

### Step 3: Deploy Istio Gateway and VirtualServices

```bash
# Create Istio configuration
kubectl apply -f - << 'EOF'
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
      weight: 60  # Primary traffic to AWS
    - destination:
        host: addtocloud-api.azure
        port:
          number: 8080
      weight: 30  # Secondary traffic to Azure
    - destination:
        host: addtocloud-api.gcp
        port:
          number: 8080
      weight: 10  # Tertiary traffic to GCP
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: addtocloud-frontend
        port:
          number: 3000
EOF
```

## 📦 Application Deployment

### Step 1: Build and Push Container Images

```bash
# Build the application
docker build -t addtocloud:latest .

# Tag for multiple registries
docker tag addtocloud:latest ghcr.io/gokulupadhyayguragain/addtocloud:latest

# Push to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
docker push ghcr.io/gokulupadhyayguragain/addtocloud:latest
```

### Step 2: Deploy to All Clusters

```bash
# Create deployment manifests
cat > infrastructure/kubernetes/deployments/app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addtocloud-api
  labels:
    app: addtocloud-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: addtocloud-api
  template:
    metadata:
      labels:
        app: addtocloud-api
    spec:
      containers:
      - name: api
        image: ghcr.io/gokulupadhyayguragain/addtocloud:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: token
---
apiVersion: v1
kind: Service
metadata:
  name: addtocloud-api
spec:
  selector:
    app: addtocloud-api
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addtocloud-frontend
  labels:
    app: addtocloud-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: addtocloud-frontend
  template:
    metadata:
      labels:
        app: addtocloud-frontend
    spec:
      containers:
      - name: frontend
        image: ghcr.io/gokulupadhyayguragain/addtocloud:frontend-latest
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: addtocloud-frontend
spec:
  selector:
    app: addtocloud-frontend
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF

# Deploy to all clusters
for context in $(kubectl config get-contexts -o name); do
  echo "Deploying to $context..."
  kubectl --context=$context apply -f infrastructure/kubernetes/deployments/
done
```

## 📊 Monitoring Setup

### Step 1: Deploy Prometheus and Grafana

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy monitoring stack to each cluster
for context in $(kubectl config get-contexts -o name); do
  echo "Deploying monitoring to $context..."
  kubectl --context=$context create namespace monitoring
  
  # Install Prometheus
  helm --kube-context=$context install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --set grafana.enabled=true \
    --set grafana.adminPassword=admin123
done
```

### Step 2: Configure Grafana Dashboards

```bash
# Create Grafana dashboard for multi-cloud monitoring
cat > monitoring/grafana/dashboards/multicloud-overview.json << 'EOF'
{
  "dashboard": {
    "title": "AddToCloud Multi-Cloud Overview",
    "panels": [
      {
        "title": "Cluster Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{cluster=~'aws-primary|azure-secondary|gcp-tertiary'}",
            "legendFormat": "{{cluster}}"
          }
        ]
      },
      {
        "title": "Request Rate by Cloud",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(istio_requests_total[5m])",
            "legendFormat": "{{source_cluster}} -> {{destination_cluster}}"
          }
        ]
      }
    ]
  }
}
EOF
```

## 🔍 Verification and Testing

### Step 1: Verify Infrastructure

```bash
# Check all clusters are running
echo "=== Cluster Status ==="
kubectl --context=arn:aws:eks:us-west-2:ACCOUNT:cluster/addtocloud-prod-eks get nodes
kubectl --context=aks-addtocloud-prod get nodes
kubectl --context=gke_PROJECT_us-central1-a_addtocloud-gke-cluster get nodes

# Check Istio installation
echo "=== Istio Status ==="
for context in $(kubectl config get-contexts -o name); do
  echo "Checking Istio on $context..."
  kubectl --context=$context get pods -n istio-system
done
```

### Step 2: Test Service Mesh Connectivity

```bash
# Deploy test application
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test
        image: curlimages/curl
        command: ["sleep", "3600"]
EOF

# Test cross-cluster connectivity
kubectl exec -it deployment/test-app -- curl -I http://addtocloud-api.default.svc.cluster.local:8080/health
```

### Step 3: Performance Testing

```bash
# Install load testing tool
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-test
  template:
    metadata:
      labels:
        app: load-test
    spec:
      containers:
      - name: hey
        image: williamyeh/hey
        command: ["sleep", "3600"]
EOF

# Run load test
kubectl exec -it deployment/load-test -- hey -n 1000 -c 10 http://addtocloud-api:8080/health
```

## 🌐 Cloudflare Integration

### Step 1: Configure DNS

```bash
# Get load balancer IPs
AWS_LB=$(kubectl --context=arn:aws:eks:us-west-2:ACCOUNT:cluster/addtocloud-prod-eks get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
AZURE_LB=$(kubectl --context=aks-addtocloud-prod get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
GCP_LB=$(kubectl --context=gke_PROJECT_us-central1-a_addtocloud-gke-cluster get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Configure these in Cloudflare:"
echo "AWS: $AWS_LB"
echo "Azure: $AZURE_LB"
echo "GCP: $GCP_LB"
```

### Step 2: Setup Load Balancing

```bash
# Cloudflare Load Balancer Configuration (via API or Dashboard)
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/load_balancers" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "name": "addtocloud.com",
    "default_pool_ids": ["aws-pool", "azure-pool", "gcp-pool"],
    "description": "Multi-cloud load balancer for AddToCloud",
    "enabled": true,
    "proxied": true
  }'
```

## 🎯 Troubleshooting

### Common Issues

#### 1. Cluster Not Visible
```bash
# Check kubectl contexts
kubectl config get-contexts

# Verify cloud credentials
aws sts get-caller-identity
az account show
gcloud auth list
```

#### 2. Istio Installation Fails
```bash
# Check cluster resources
kubectl get nodes
kubectl top nodes

# Verify Istio requirements
istioctl verify-install
```

#### 3. Cross-Cluster Communication Issues
```bash
# Check Istio certificates
kubectl get secrets -n istio-system | grep cacerts

# Verify endpoint connectivity
kubectl get endpoints -A
```

## 📈 Scaling and Optimization

### Auto-scaling Configuration

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: addtocloud-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: addtocloud-api
  minReplicas: 3
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

This deployment guide ensures your AddToCloud platform is properly deployed across all three cloud providers with full service mesh connectivity and monitoring capabilities.
