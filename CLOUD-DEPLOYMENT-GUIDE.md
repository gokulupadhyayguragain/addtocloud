# 🚀 AddToCloud: Quick Cloud Setup Guide

## Cloud Credentials Setup

Before deploying to EKS, AKS, and GKE, you need to configure credentials for all three clouds.

### 🟧 AWS Setup (for EKS)
```powershell
# Option 1: AWS CLI Configure
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)

# Option 2: Environment Variables
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_DEFAULT_REGION="us-east-1"

# Verify
aws sts get-caller-identity
```

### 🔵 Azure Setup (for AKS)
```powershell
# Login to Azure
az login
# This opens browser for authentication

# Set subscription (if you have multiple)
az account list
az account set --subscription "your-subscription-id"

# Verify
az account show
```

### 🟢 GCP Setup (for GKE)
```powershell
# Login to Google Cloud
gcloud auth login
# This opens browser for authentication

# Set project
gcloud config set project your-project-id

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# Verify
gcloud config list
gcloud projects list
```

## 🚀 Quick Deployment Commands

### Option 1: Deploy to ALL Clouds at Once
```powershell
# Run the comprehensive deployment script
.\deploy-to-clouds.ps1
```

### Option 2: Deploy One Cloud at a Time
```powershell
# AWS EKS only
cd infrastructure\terraform\aws
terraform init
terraform apply -var="project_name=addtocloud" -var="environment=production"

# Azure AKS only  
cd ..\azure
terraform init
terraform apply -var="project_name=addtocloud" -var="environment=production"

# GCP GKE only
cd ..\gcp
terraform init
terraform apply -var="project_name=addtocloud" -var="environment=production"
```

### Option 3: Use Existing Multi-Cloud Scripts
```powershell
# Full enterprise deployment
.\scripts\deploy-multi-cloud.ps1

# Complete deployment with storage
.\scripts\deploy-complete-multicloud.ps1

# All clouds with Cloudflare
.\scripts\deploy-cloudflare.ps1
```

## 🎯 What Gets Deployed

### AWS EKS
- **Cluster**: `addtocloud-eks-cluster` (3 nodes)
- **Region**: us-east-1
- **Database**: RDS PostgreSQL
- **Storage**: EFS for persistent volumes
- **Load Balancer**: ALB with Ingress

### Azure AKS
- **Cluster**: `addtocloud-aks-cluster` (3 nodes)  
- **Region**: East US
- **Database**: Azure Database for PostgreSQL
- **Storage**: Azure Files for persistent volumes
- **Load Balancer**: Azure Load Balancer

### GCP GKE
- **Cluster**: `addtocloud-gke-cluster` (3 nodes)
- **Region**: us-central1
- **Database**: Cloud SQL PostgreSQL
- **Storage**: Filestore for persistent volumes
- **Load Balancer**: Google Cloud Load Balancer

## 🔗 After Deployment

### Check Cluster Status
```powershell
# AWS EKS
aws eks update-kubeconfig --region us-east-1 --name addtocloud-eks-cluster
kubectl get nodes

# Azure AKS
az aks get-credentials --resource-group addtocloud-rg --name addtocloud-aks-cluster
kubectl get nodes

# GCP GKE  
gcloud container clusters get-credentials addtocloud-gke-cluster --zone us-central1-a
kubectl get nodes
```

### Access Your Apps
```powershell
# Get service URLs
kubectl get svc -n addtocloud --all-namespaces

# Port forward to test
kubectl port-forward svc/addtocloud-frontend 3000:3000 -n addtocloud
kubectl port-forward svc/addtocloud-backend 8080:8080 -n addtocloud
```

## 💡 Pro Tips

1. **Start with One Cloud**: Deploy GCP first (fastest), then AWS, then Azure
2. **Cost Management**: All clouds have free tiers, but watch your usage
3. **DNS Setup**: Point `api.addtocloud.tech` to your load balancers
4. **Monitoring**: Each cloud includes monitoring - check cloud consoles
5. **Security**: All deployments use managed identity/service accounts

## ⚡ Quick Start (5 minutes)

If you want to deploy RIGHT NOW:

```powershell
# 1. Set up credentials (do all three)
aws configure
az login  
gcloud auth login

# 2. Deploy everything
.\deploy-to-clouds.ps1

# 3. Wait 5-10 minutes, then check
kubectl get all -n addtocloud --context=addtocloud-eks-cluster
kubectl get all -n addtocloud --context=addtocloud-aks-cluster  
kubectl get all -n addtocloud --context=addtocloud-gke-cluster
```

You'll have AddToCloud running on **all three major clouds** in about 10 minutes! 🎉
