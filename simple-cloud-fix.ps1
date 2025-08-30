# Simple Cloud Deployment Fixes

Write-Host "🚀 SIMPLE CLOUD DEPLOYMENT FIXES" -ForegroundColor Green
Write-Host ""

# Fix 1: Azure AKS - Use different resource group
Write-Host "1️⃣ FIXING AZURE AKS..." -ForegroundColor Cyan
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure"

# Use a different environment name to avoid conflicts
Write-Host "Deploying with new resource group name..." -ForegroundColor Yellow
terraform apply -var="project_name=addtocloud" -var="environment=prod-new" -auto-approve

Write-Host ""

# Fix 2: GCP GKE - Use the correct project ID
Write-Host "2️⃣ FIXING GCP GKE..." -ForegroundColor Green
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"

# Enable PATH for gcloud
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"

# Use the actual project ID we found: static-operator-469115-h1
Write-Host "Deploying with correct project ID..." -ForegroundColor Yellow
terraform apply -var="gcp_project_id=static-operator-469115-h1" -var="project_name=addtocloud" -var="environment=production" -auto-approve

Write-Host ""

# Check AWS status
Write-Host "3️⃣ CHECKING AWS EKS..." -ForegroundColor Yellow
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"
terraform show

Write-Host ""
Write-Host "✅ DEPLOYMENT FIXES COMPLETED!" -ForegroundColor Green
Write-Host "Check each cloud console to verify deployments." -ForegroundColor Cyan
