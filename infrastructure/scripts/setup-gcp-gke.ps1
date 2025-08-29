# GCP GKE Cluster Setup Script
# This script creates and configures a GCP GKE cluster for AddToCloud

param(
    [string]$ProjectId = "addtocloud-project",
    [string]$ClusterName = "addtocloud-gke",
    [string]$Zone = "us-central1-a",
    [string]$Region = "us-central1",
    [string]$MachineType = "e2-standard-4",
    [int]$NumNodes = 3
)

Write-Host "🚀 Setting up GCP GKE cluster for AddToCloud..." -ForegroundColor Blue

# Check gcloud CLI configuration
try {
    $currentProject = gcloud config get-value project
    if ($currentProject -ne $ProjectId) {
        gcloud config set project $ProjectId
    }
    Write-Host "✅ GCP CLI configured for project: $ProjectId" -ForegroundColor Green
} catch {
    Write-Error "❌ GCP CLI not configured. Please run 'gcloud auth login' first."
    exit 1
}

# Enable required APIs
Write-Host "🔧 Enabling required GCP APIs..." -ForegroundColor Yellow
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com

# Create GKE cluster
Write-Host "⚙️  Creating GKE cluster: $ClusterName" -ForegroundColor Yellow
gcloud container clusters create $ClusterName `
    --zone $Zone `
    --machine-type $MachineType `
    --num-nodes $NumNodes `
    --enable-autoscaling `
    --min-nodes 2 `
    --max-nodes 10 `
    --enable-autorepair `
    --enable-autoupgrade `
    --enable-ip-alias `
    --network "default" `
    --subnetwork "default" `
    --enable-stackdriver-kubernetes `
    --enable-network-policy `
    --maintenance-window-start "2023-01-01T09:00:00Z" `
    --maintenance-window-end "2023-01-01T17:00:00Z" `
    --maintenance-window-recurrence "FREQ=WEEKLY;BYDAY=SA,SU" `
    --disk-size "50GB" `
    --disk-type "pd-ssd" `
    --image-type "COS_CONTAINERD" `
    --enable-shielded-nodes `
    --enable-private-nodes `
    --master-ipv4-cidr-block "172.16.0.0/28"

# Get GKE credentials
Write-Host "🔑 Getting GKE credentials..." -ForegroundColor Yellow
gcloud container clusters get-credentials $ClusterName --zone $Zone

# Create additional node pools for different workloads
Write-Host "🏗️  Creating frontend node pool..." -ForegroundColor Yellow
gcloud container node-pools create frontend-pool `
    --cluster $ClusterName `
    --zone $Zone `
    --machine-type "e2-medium" `
    --num-nodes 2 `
    --enable-autoscaling `
    --min-nodes 1 `
    --max-nodes 5 `
    --node-labels "nodepool=frontend" `
    --node-taints "dedicated=frontend:NoSchedule" `
    --preemptible

Write-Host "🔧 Creating backend node pool..." -ForegroundColor Yellow
gcloud container node-pools create backend-pool `
    --cluster $ClusterName `
    --zone $Zone `
    --machine-type "e2-standard-2" `
    --num-nodes 2 `
    --enable-autoscaling `
    --min-nodes 1 `
    --max-nodes 8 `
    --node-labels "nodepool=backend" `
    --node-taints "dedicated=backend:NoSchedule" `
    --preemptible

# Create static IP addresses
Write-Host "🌐 Creating static IP addresses..." -ForegroundColor Yellow
gcloud compute addresses create addtocloud-ip --region $Region
gcloud compute addresses create addtocloud-api-ip --region $Region

# Install NGINX Ingress Controller
Write-Host "🌐 Installing NGINX Ingress Controller..." -ForegroundColor Yellow
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace ingress-nginx `
    --create-namespace `
    --set controller.service.loadBalancerIP=$(gcloud compute addresses describe addtocloud-ip --region $Region --format="value(address)")

# Install cert-manager
Write-Host "🔒 Installing cert-manager..." -ForegroundColor Yellow
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager `
    --namespace cert-manager `
    --create-namespace `
    --set installCRDs=true

# Create Let's Encrypt ClusterIssuer
$clusterIssuer = @"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@addtocloud.tech
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
"@

$clusterIssuer | kubectl apply -f -

# Configure Container Registry
Write-Host "📁 Configuring Google Container Registry..." -ForegroundColor Yellow
gcloud auth configure-docker

# Install Google Cloud Storage CSI driver
Write-Host "💾 Installing GCS CSI driver..." -ForegroundColor Yellow
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gcp-filestore-csi-driver/master/deploy/kubernetes/manifests/gcp-filestore-csi-driver.yaml

# Install Stackdriver monitoring
Write-Host "📊 Setting up monitoring..." -ForegroundColor Yellow
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack `
    --namespace monitoring `
    --set grafana.enabled=true `
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

Write-Host "✅ GCP GKE cluster setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Cluster Information:" -ForegroundColor Cyan
Write-Host "├── Project ID: $ProjectId" -ForegroundColor White
Write-Host "├── Cluster Name: $ClusterName" -ForegroundColor White
Write-Host "├── Zone: $Zone" -ForegroundColor White
Write-Host "├── Machine Type: $MachineType" -ForegroundColor White
Write-Host "├── Node Count: $NumNodes" -ForegroundColor White
Write-Host "└── Node Pools: default, frontend-pool, backend-pool" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Static IP Addresses:" -ForegroundColor Cyan
$frontendIP = gcloud compute addresses describe addtocloud-ip --region $Region --format="value(address)"
$apiIP = gcloud compute addresses describe addtocloud-api-ip --region $Region --format="value(address)"
Write-Host "├── Frontend: $frontendIP" -ForegroundColor White
Write-Host "└── API: $apiIP" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run: kubectl get nodes" -ForegroundColor White
Write-Host "2. Run: kubectl get namespaces" -ForegroundColor White
Write-Host "3. Deploy AddToCloud: .\deploy-multicloud.ps1 gcp" -ForegroundColor White
