# PowerShell deployment script for AddToCloud Credential Service

Write-Host "🚀 Deploying AddToCloud Credential Service..." -ForegroundColor Green

# Build Docker image
Write-Host "📦 Building credential service image..." -ForegroundColor Cyan
docker build -t addtocloud/credential-service:latest -f apps/credential-service/Dockerfile .

# Create namespace
Write-Host "🏗️ Creating namespace..." -ForegroundColor Cyan
kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -

# Deploy the credential service
Write-Host "📋 Applying Kubernetes manifests..." -ForegroundColor Cyan
kubectl apply -f infrastructure/kubernetes/credential-service.yaml

# Wait for deployment
Write-Host "⏳ Waiting for deployment to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/credential-service -n addtocloud

# Get service information
Write-Host "🌐 Service endpoints:" -ForegroundColor Green
kubectl get services -n addtocloud

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📧 To configure email notifications, update the secret:" -ForegroundColor Cyan
Write-Host "kubectl patch secret email-secret -n addtocloud --type='json' -p='[{""op"":""replace"",""path"":""/data/smtp-username"",""value"":""$(([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('your-email@gmail.com'))))""}]'" -ForegroundColor Yellow
Write-Host "kubectl patch secret email-secret -n addtocloud --type='json' -p='[{""op"":""replace"",""path"":""/data/smtp-password"",""value"":""$(([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('your-app-password'))))""}]'" -ForegroundColor Yellow
