# Azure AKS Cluster Setup Script
# This script creates and configures an Azure AKS cluster for AddToCloud

param(
    [string]$ResourceGroupName = "addtocloud-rg",
    [string]$ClusterName = "addtocloud-aks",
    [string]$Location = "East US",
    [string]$NodeCount = "3",
    [string]$NodeSize = "Standard_D4s_v3"
)

Write-Host "🚀 Setting up Azure AKS cluster for AddToCloud..." -ForegroundColor Blue

# Login to Azure (if not already logged in)
try {
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
} catch {
    Connect-AzAccount
}

# Create Resource Group
Write-Host "📦 Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

# Create AKS cluster
Write-Host "⚙️  Creating AKS cluster: $ClusterName" -ForegroundColor Yellow
New-AzAksCluster `
    -ResourceGroupName $ResourceGroupName `
    -Name $ClusterName `
    -Location $Location `
    -NodeCount $NodeCount `
    -NodeVmSize $NodeSize `
    -EnableManagedIdentity `
    -EnableAutoScaling `
    -MinCount 2 `
    -MaxCount 10 `
    -EnableAddOns monitoring,http_application_routing `
    -GenerateSshKeys

# Get AKS credentials
Write-Host "🔑 Getting AKS credentials..." -ForegroundColor Yellow
Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Force

# Create Azure Container Registry
$acrName = "addtocloudacr"
Write-Host "📁 Creating Azure Container Registry: $acrName" -ForegroundColor Yellow
New-AzContainerRegistry `
    -ResourceGroupName $ResourceGroupName `
    -Name $acrName `
    -Sku "Standard" `
    -Location $Location `
    -EnableAdminUser

# Attach ACR to AKS
Write-Host "🔗 Attaching ACR to AKS cluster..." -ForegroundColor Yellow
Update-AzAksCluster `
    -ResourceGroupName $ResourceGroupName `
    -Name $ClusterName `
    -AttachAcr $acrName

# Install NGINX Ingress Controller
Write-Host "🌐 Installing NGINX Ingress Controller..." -ForegroundColor Yellow
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace ingress-nginx `
    --create-namespace `
    --set controller.replicaCount=2 `
    --set controller.nodeSelector."kubernetes\.io/os"=linux `
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux

# Install cert-manager for SSL/TLS
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

Write-Host "✅ Azure AKS cluster setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Cluster Information:" -ForegroundColor Cyan
Write-Host "├── Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "├── Cluster Name: $ClusterName" -ForegroundColor White
Write-Host "├── Location: $Location" -ForegroundColor White
Write-Host "├── Node Count: $NodeCount" -ForegroundColor White
Write-Host "├── Node Size: $NodeSize" -ForegroundColor White
Write-Host "└── ACR Name: $acrName" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run: kubectl get nodes" -ForegroundColor White
Write-Host "2. Run: kubectl get namespaces" -ForegroundColor White
Write-Host "3. Deploy AddToCloud: .\deploy-multicloud.ps1 azure" -ForegroundColor White
