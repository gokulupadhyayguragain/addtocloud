# Multi-Cloud Deployment Status Checker

Write-Host "MULTI-CLOUD DEPLOYMENT STATUS" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Blue
Write-Host ""

# Check Azure AKS
Write-Host "1. AZURE AKS STATUS" -ForegroundColor Cyan
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure"
Write-Host "Resources in Azure state:" -ForegroundColor Yellow
terraform state list
Write-Host ""

Write-Host "Azure AKS cluster status:" -ForegroundColor Yellow
az aks list --resource-group rg-addtocloud-prod --output table 2>$null
Write-Host ""

# Check GCP GKE
Write-Host "2. GCP GKE STATUS" -ForegroundColor Green
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"
Write-Host "Resources in GCP state:" -ForegroundColor Yellow
terraform state list
Write-Host ""

Write-Host "GCP GKE cluster status:" -ForegroundColor Yellow
gcloud container clusters list --project=static-operator-469115-h1 2>$null
Write-Host ""

# Check AWS EKS
Write-Host "3. AWS EKS STATUS" -ForegroundColor Yellow
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"
Write-Host "Resources in AWS state:" -ForegroundColor Yellow
terraform state list
Write-Host ""

Write-Host "AWS EKS cluster status:" -ForegroundColor Yellow
aws eks list-clusters --region us-west-2 2>$null
Write-Host ""

Write-Host "STATUS CHECK COMPLETED!" -ForegroundColor Green
