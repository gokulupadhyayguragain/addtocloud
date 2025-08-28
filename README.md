# AddToCloud Enterprise Platform

## Overview
AddToCloud is an enterprise cloud service platform providing PaaS, FaaS, IaaS, and SaaS services with multi-cloud deployment capabilities across Azure AKS, AWS EKS, and GCP GKE.

## 🚀 Quick Start

### Prerequisites
- **Docker** and **Docker Desktop**
- **Kubernetes CLI** (kubectl)
- **Terraform** (v1.0+)
- **Helm** (v3.0+)
- **Cloud CLI Tools**:
  - Azure CLI (`az`)
  - AWS CLI (`aws`)
  - Google Cloud CLI (`gcloud`)

### One-Command Deployment

#### Windows (PowerShell)
```powershell
# Deploy to all clouds
.\scripts\deploy-all.ps1

# Deploy to specific cloud only
.\scripts\deploy-all.ps1 -SkipAzure -SkipGCP  # AWS only
.\scripts\deploy-all.ps1 -SkipAWS -SkipGCP   # Azure only
.\scripts\deploy-all.ps1 -SkipAzure -SkipAWS # GCP only

# Deploy only Kubernetes resources (skip cloud infrastructure)
.\scripts\deploy-all.ps1 -OnlyK8s
```

#### Linux/macOS/Git Bash
```bash
# Deploy to all clouds
./scripts/deploy-all.sh

# Deploy to specific cloud only
./scripts/deploy-all.sh --skip-azure --skip-gcp  # AWS only
./scripts/deploy-all.sh --skip-aws --skip-gcp    # Azure only
./scripts/deploy-all.sh --skip-azure --skip-aws  # GCP only

# Deploy only Kubernetes resources
./scripts/deploy-all.sh --only-k8s
```

## 🏗️ Architecture

### Technology Stack
- **Frontend**: Next.js 14 (Pure JavaScript), Tailwind CSS, Three.js
- **Backend**: Go 1.21+ microservices with Gin framework
- **Databases**: PostgreSQL (primary), MongoDB (documents), Redis (caching)
- **Infrastructure**: Docker, Kubernetes, Istio service mesh
- **Cloud Platforms**: Azure AKS, AWS EKS, GCP GKE
- **DevOps**: Terraform, ArgoCD, GitHub Actions, Ansible
- **Monitoring**: Grafana, Prometheus, Jaeger
- **Domain/CDN**: Cloudflare with addtocloud.tech

### Features
- **Multi-cloud Support**: Seamless deployment across Azure, AWS, and GCP
- **Cloud Services Catalog**: 360+ cloud services from major providers
- **Payment Integration**: Payoneer payment processing
- **Enterprise Security**: OAuth 2.0, JWT, RBAC, encryption at rest
- **Auto-scaling**: Horizontal and vertical pod autoscaling
- **Service Mesh**: Istio for traffic management, security, and observability
- **CI/CD Pipeline**: GitOps with ArgoCD and GitHub Actions
- **Monitoring**: Real-time metrics, logging, and distributed tracing

## 📋 Prerequisites Setup

### 1. Install Required Tools

#### Windows (Chocolatey)
```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools
choco install docker-desktop kubernetes-cli terraform helm azure-cli awscli gcloudsdk -y
```

#### macOS (Homebrew)
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install docker kubectl terraform helm azure-cli awscli google-cloud-sdk
```

#### Linux (Ubuntu/Debian)
```bash
# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install helm

# Cloud CLIs
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Azure CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install  # AWS CLI
curl https://sdk.cloud.google.com | bash && exec -l $SHELL  # Google Cloud CLI
```

### 2. Cloud Provider Setup

#### Azure
```bash
# Login to Azure
az login

# Create service principal for Terraform
az ad sp create-for-rbac --name "addtocloud-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Note down the output:
# - appId (client_id)
# - password (client_secret)
# - tenant (tenant_id)
```

#### AWS
```bash
# Configure AWS credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

#### Google Cloud
```bash
# Login to GCP
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Create service account for Terraform
gcloud iam service-accounts create addtocloud-terraform --display-name="AddToCloud Terraform"

# Grant permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:addtocloud-terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create addtocloud-key.json \
  --iam-account=addtocloud-terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/addtocloud-key.json"
```

## ⚙️ Configuration

### 1. Environment Variables
Copy and customize the environment file:
```bash
cp .env.example .env
# Edit .env with your actual values
```

### 2. Terraform Variables
```bash
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
# Edit terraform.tfvars with your cloud provider credentials
```

### 3. Secrets Configuration
The deployment script automatically generates secure secrets. For manual configuration, see:
- `SECRETS-GUIDE.md` - Comprehensive secrets setup guide
- `secrets/generated-secrets.env` - Auto-generated secrets (created during deployment)

## 🚀 Deployment

### Automated Deployment
The easiest way to deploy AddToCloud is using our automated deployment scripts:

```bash
# Windows PowerShell
.\scripts\deploy-all.ps1

# Linux/macOS/Git Bash
./scripts/deploy-all.sh
```

The script will:
1. ✅ Check all prerequisites
2. ✅ Generate secure secrets
3. ✅ Deploy cloud infrastructure (Terraform)
4. ✅ Install Istio service mesh
5. ✅ Build and push Docker images
6. ✅ Deploy Kubernetes resources
7. ✅ Verify deployment status

### Manual Deployment
For step-by-step manual deployment, see:
- `docs/deployment/manual-deployment.md`
- `docs/deployment/cloud-specific-setup.md`

### Development Environment
For local development:
```bash
# Windows
.\scripts\setup-dev.ps1

# Linux/macOS
./scripts/setup-dev.sh
```

## 📊 Monitoring & Operations

### Access Dashboards
After deployment, access your monitoring dashboards:

```bash
# Grafana Dashboard
kubectl port-forward -n addtocloud svc/grafana 3000:3000
# Open: http://localhost:3000

# Prometheus Metrics
kubectl port-forward -n addtocloud svc/prometheus 9090:9090
# Open: http://localhost:9090

# Istio Kiali Service Mesh
kubectl port-forward -n istio-system svc/kiali 20001:20001
# Open: http://localhost:20001

# Jaeger Tracing
kubectl port-forward -n istio-system svc/jaeger 16686:16686
# Open: http://localhost:16686
```

### Useful Commands
```bash
# Check all resources
kubectl get all -n addtocloud

# View application logs
kubectl logs -f deployment/addtocloud-backend -n addtocloud
kubectl logs -f deployment/addtocloud-frontend -n addtocloud

# Check Istio service mesh status
istioctl proxy-status

# View Istio configuration
istioctl analyze -n addtocloud

# Port forward to application
kubectl port-forward -n addtocloud svc/addtocloud-frontend 3000:3000
kubectl port-forward -n addtocloud svc/addtocloud-backend 8080:8080
```

## 🔧 Development

### Local Development Setup
```bash
# Install frontend dependencies
cd frontend
npm install

# Install backend dependencies
cd ../backend
go mod download

# Start development servers
npm run dev          # Frontend (Next.js)
go run cmd/main.go   # Backend (Go)
```

### Project Structure
```
addtocloud/
├── frontend/                 # Next.js React application
│   ├── components/          # React components
│   ├── pages/              # Next.js pages
│   ├── styles/             # Tailwind CSS styles
│   └── utils/              # Utility functions
├── backend/                 # Go microservices
│   ├── cmd/                # Application entry points
│   ├── internal/           # Internal packages
│   ├── pkg/                # Public packages
│   └── migrations/         # Database migrations
├── infrastructure/          # Infrastructure as Code
│   ├── terraform/          # Terraform configurations
│   ├── kubernetes/         # Kubernetes manifests
│   ├── docker/             # Docker configurations
│   └── istio/              # Istio service mesh configs
├── devops/                 # DevOps configurations
│   ├── github-actions/     # CI/CD workflows
│   ├── argocd/             # GitOps configurations
│   └── ansible/            # Configuration management
├── scripts/                # Deployment and utility scripts
└── docs/                   # Documentation
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Terraform Authentication Errors
```bash
# Azure
az login
az account set --subscription "your-subscription-id"

# AWS
aws configure
# or
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# GCP
gcloud auth application-default login
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

#### 2. Kubernetes Connection Issues
```bash
# Check current context
kubectl config current-context

# List available contexts
kubectl config get-contexts

# Switch context
kubectl config use-context your-cluster-context
```

#### 3. Docker Issues
```bash
# Check Docker status
docker version
docker info

# Restart Docker Desktop (Windows/macOS)
# Or restart Docker service (Linux)
sudo systemctl restart docker
```

#### 4. Pod Startup Issues
```bash
# Check pod status
kubectl get pods -n addtocloud

# Describe problematic pod
kubectl describe pod POD_NAME -n addtocloud

# Check pod logs
kubectl logs POD_NAME -n addtocloud

# Check events
kubectl get events -n addtocloud --sort-by='.lastTimestamp'
```

### Getting Help
- 📖 Check the `docs/` directory for detailed documentation
- 🐛 Report issues on GitHub
- 💬 Join our community discussions
- 📧 Contact support: support@addtocloud.tech

## 📚 Documentation

### Quick Links
- [API Documentation](docs/api/)
- [Architecture Guide](docs/architecture/)
- [Deployment Guide](docs/deployment/)
- [User Guides](docs/user-guides/)
- [Development Setup](docs/development/)

### Additional Resources
- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Istio Documentation](https://istio.io/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Go Documentation](https://golang.org/doc)

## 🤝 Contributing
We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments
- Kubernetes community
- Istio project
- Terraform team
- Next.js team
- Go community
- All open source contributors

---

**AddToCloud** - Enterprise Cloud Platform
🌐 [addtocloud.tech](https://addtocloud.tech) | 📧 [contact@addtocloud.tech](mailto:contact@addtocloud.tech)
