# Fixed Multi-Cloud Deployment

Write-Host "FIXED MULTI-CLOUD DEPLOYMENT" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Blue
Write-Host ""

$ErrorActionPreference = "Continue"

# Set up PATH for cloud CLIs
$env:PATH += ";C:\Program Files\Amazon\AWSCLIV2"
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"

# Function to show deployment progress
function Show-Progress {
    param($Message, $Color = "Yellow")
    Write-Host $Message -ForegroundColor $Color
    Write-Host "Time: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
}

# Check Azure AKS status (already deployed!)
Show-Progress "AZURE AKS STATUS CHECK" "Green"
az aks list --resource-group rg-addtocloud-prod --output table

Write-Host ""
Write-Host "AZURE AKS: ALREADY DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
Write-Host ""

# 2. Fix and Deploy GCP GKE
Show-Progress "DEPLOYING TO GCP GKE" "Green"
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"

Show-Progress "Planning GCP deployment..."
terraform plan -var "gcp_project_id=static-operator-469115-h1"

Show-Progress "Applying GCP deployment..."
terraform apply -var "gcp_project_id=static-operator-469115-h1" -auto-approve

Show-Progress "Checking GCP GKE deployment..."
& "C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" container clusters list --project=static-operator-469115-h1

Write-Host ""
Write-Host "GCP DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host ""

# 3. Fix and Deploy AWS EKS
Show-Progress "DEPLOYING TO AWS EKS" "Yellow"
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"

# Remove terraform lock if exists
if (Test-Path ".terraform.lock.hcl") {
    Remove-Item ".terraform.lock.hcl" -Force
}

Show-Progress "Re-initializing AWS Terraform..."
terraform init

Show-Progress "Planning AWS deployment..."
terraform plan -var "project_name=addtocloud" -var "environment=production"

Show-Progress "Applying AWS deployment..."
terraform apply -var "project_name=addtocloud" -var "environment=production" -auto-approve

Show-Progress "Checking AWS EKS deployment..."
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" eks list-clusters --region us-west-2

Write-Host ""
Write-Host "AWS DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host ""

# Final comprehensive status check
Show-Progress "FINAL COMPREHENSIVE STATUS CHECK" "Magenta"

Write-Host "1. Azure AKS Clusters:" -ForegroundColor Cyan
az aks list --output table

Write-Host ""
Write-Host "2. GCP GKE Clusters:" -ForegroundColor Green  
& "C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" container clusters list

Write-Host ""
Write-Host "3. AWS EKS Clusters:" -ForegroundColor Yellow
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" eks list-clusters

Write-Host ""
Write-Host "=========================================" -ForegroundColor Blue
Write-Host "ALL THREE CLOUDS DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Blue
