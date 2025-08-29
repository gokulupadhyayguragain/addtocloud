# AddToCloud CLI Setup and Authentication Guide

## ✅ CLI Tools Status
- AWS CLI: ✅ v2.28.20 
- Azure CLI: ✅ v2.76.0
- Google Cloud SDK: ✅ v536.0.1

## 🔐 Authentication Setup

### AWS Authentication
```powershell
# Configure AWS credentials
aws configure
# Or set environment variables
$env:AWS_ACCESS_KEY_ID = "your-access-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret-key" 
$env:AWS_DEFAULT_REGION = "us-west-2"

# Test authentication
aws sts get-caller-identity
```

### Azure Authentication  
```powershell
# Login to Azure
az login

# Set subscription (if multiple)
az account set --subscription "your-subscription-id"

# Test authentication
az account show
```

### Google Cloud Authentication
```powershell
# Initialize gcloud
gcloud init

# Authenticate
gcloud auth login

# Set project
gcloud config set project your-project-id

# Test authentication
gcloud auth list
```

## 🚀 Deploy Enterprise Multi-Cloud Stack

### Option 1: Complete Automated Deployment
```powershell
# Deploy to all clouds with GitHub Actions
git push origin main  # Triggers enterprise-multi-cloud.yml workflow
```

### Option 2: Manual Multi-Cloud Deployment
```powershell
# Authenticate all clouds first, then:
bash ./scripts/deploy-enterprise-multi-cloud.sh production "aws azure gcp"
```

### Option 3: Individual Cloud Deployment
```powershell
# AWS only
bash ./scripts/deploy-enterprise-multi-cloud.sh production "aws"

# Azure only  
bash ./scripts/deploy-enterprise-multi-cloud.sh production "azure"

# GCP only
bash ./scripts/deploy-enterprise-multi-cloud.sh production "gcp"
```

### Option 4: Ansible Automation
```powershell
cd devops/ansible
ansible-playbook deploy-multi-cloud.yml -e env=production -e cloud_providers="aws,azure,gcp"
```

## 📊 What Gets Deployed

### Infrastructure (Terraform)
- AWS: EKS cluster in us-west-2
- Azure: AKS cluster in West US 2  
- GCP: GKE cluster in us-west1

### Service Mesh (Istio)
- Cross-cluster service mesh federation
- mTLS for secure communication
- Traffic management and policies

### Applications
- Frontend: 406-page Next.js app
- Backend: Go API with cloud services
- Databases: PostgreSQL, Redis, MongoDB

### Monitoring
- Prometheus multi-cloud federation
- Grafana enterprise dashboards
- Service mesh observability

### GitOps
- ArgoCD for continuous deployment
- Automated configuration management

## 🌐 Expected URLs After Deployment
- AWS: `http://<aws-load-balancer>/`
- Azure: `http://<azure-load-balancer>/`  
- GCP: `http://<gcp-load-balancer>/`
- Monitoring: `http://<load-balancer>/grafana`

---
Next: Authenticate to your cloud providers and run deployment! 🚀
