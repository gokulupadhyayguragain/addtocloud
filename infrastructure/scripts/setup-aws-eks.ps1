# AWS EKS Cluster Setup Script
# This script creates and configures an AWS EKS cluster for AddToCloud

param(
    [string]$ClusterName = "addtocloud-eks",
    [string]$Region = "us-west-2",
    [string]$NodeGroupName = "addtocloud-nodes",
    [string]$NodeInstanceType = "t3.medium",
    [int]$MinSize = 2,
    [int]$MaxSize = 10,
    [int]$DesiredSize = 3
)

Write-Host "🚀 Setting up AWS EKS cluster for AddToCloud..." -ForegroundColor Blue

# Check AWS CLI configuration
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✅ AWS CLI configured for account: $($identity.Account)" -ForegroundColor Green
} catch {
    Write-Error "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
}

# Install eksctl if not available
if (-not (Get-Command eksctl -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing eksctl..." -ForegroundColor Yellow
    choco install eksctl -y
}

# Create EKS cluster
Write-Host "⚙️  Creating EKS cluster: $ClusterName" -ForegroundColor Yellow
$eksConfig = @"
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: $ClusterName
  region: $Region

nodeGroups:
  - name: $NodeGroupName
    instanceType: $NodeInstanceType
    minSize: $MinSize
    maxSize: $MaxSize
    desiredCapacity: $DesiredSize
    amiFamily: AmazonLinux2
    ssh:
      enableSsm: true
    labels:
      nodegroup-type: "primary"
    tags:
      k8s.io/cluster-autoscaler/enabled: "true"
      k8s.io/cluster-autoscaler/$ClusterName: "owned"

managedNodeGroups:
  - name: managed-nodes
    instanceTypes:
      - t3.medium
      - t3.large
    minSize: 1
    maxSize: 5
    desiredCapacity: 2
    amiFamily: AmazonLinux2
    ssh:
      enableSsm: true
    labels:
      nodegroup-type: "managed"
    tags:
      k8s.io/cluster-autoscaler/enabled: "true"
      k8s.io/cluster-autoscaler/$ClusterName: "owned"

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver

iam:
  withOIDC: true
"@

$eksConfig | Out-File -FilePath "eks-config.yaml" -Encoding UTF8

eksctl create cluster -f eks-config.yaml

# Configure kubectl
Write-Host "🔑 Configuring kubectl..." -ForegroundColor Yellow
aws eks update-kubeconfig --region $Region --name $ClusterName

# Create ECR repositories
Write-Host "📁 Creating ECR repositories..." -ForegroundColor Yellow
aws ecr create-repository --repository-name addtocloud/frontend --region $Region
aws ecr create-repository --repository-name addtocloud/backend --region $Region

# Install AWS Load Balancer Controller
Write-Host "🌐 Installing AWS Load Balancer Controller..." -ForegroundColor Yellow

# Create IAM role for AWS Load Balancer Controller
$accountId = (aws sts get-caller-identity --query Account --output text)
eksctl create iamserviceaccount `
    --cluster=$ClusterName `
    --namespace=kube-system `
    --name=aws-load-balancer-controller `
    --attach-policy-arn=arn:aws:iam::$accountId:policy/AWSLoadBalancerControllerIAMPolicy `
    --override-existing-serviceaccounts `
    --approve

# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller `
    -n kube-system `
    --set clusterName=$ClusterName `
    --set serviceAccount.create=false `
    --set serviceAccount.name=aws-load-balancer-controller

# Install NGINX Ingress Controller
Write-Host "🌐 Installing NGINX Ingress Controller..." -ForegroundColor Yellow
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace ingress-nginx `
    --create-namespace

# Install cert-manager
Write-Host "🔒 Installing cert-manager..." -ForegroundColor Yellow
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager `
    --namespace cert-manager `
    --create-namespace `
    --set installCRDs=true

# Install Cluster Autoscaler
Write-Host "📈 Installing Cluster Autoscaler..." -ForegroundColor Yellow
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Patch cluster autoscaler deployment
kubectl patch deployment cluster-autoscaler `
    -n kube-system `
    -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"cluster-autoscaler.kubernetes.io/safe-to-evict\":\"false\"}}}}}'

kubectl patch deployment cluster-autoscaler `
    -n kube-system `
    -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"cluster-autoscaler\",\"command\":[\"./cluster-autoscaler\",\"--v=4\",\"--stderrthreshold=info\",\"--cloud-provider=aws\",\"--skip-nodes-with-local-storage=false\",\"--expander=least-waste\",\"--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/$ClusterName\"]}]}}}}"

# Clean up config file
Remove-Item "eks-config.yaml" -Force

Write-Host "✅ AWS EKS cluster setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Cluster Information:" -ForegroundColor Cyan
Write-Host "├── Cluster Name: $ClusterName" -ForegroundColor White
Write-Host "├── Region: $Region" -ForegroundColor White
Write-Host "├── Node Group: $NodeGroupName" -ForegroundColor White
Write-Host "├── Instance Type: $NodeInstanceType" -ForegroundColor White
Write-Host "├── Min Size: $MinSize" -ForegroundColor White
Write-Host "├── Max Size: $MaxSize" -ForegroundColor White
Write-Host "└── Desired Size: $DesiredSize" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run: kubectl get nodes" -ForegroundColor White
Write-Host "2. Run: kubectl get namespaces" -ForegroundColor White
Write-Host "3. Deploy AddToCloud: .\deploy-multicloud.ps1 aws" -ForegroundColor White
