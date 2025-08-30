# Comprehensive Multi-Cloud Fix

Write-Host "COMPREHENSIVE MULTI-CLOUD FIX" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Blue
Write-Host ""

$ErrorActionPreference = "Continue"

# Set up PATH for cloud CLIs
$env:PATH += ";C:\Program Files\Amazon\AWSCLIV2"
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"

function Show-Progress {
    param($Message, $Color = "Yellow")
    Write-Host $Message -ForegroundColor $Color
    Write-Host "Time: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
}

# Fix GCP GKE resource conflicts
Show-Progress "FIXING GCP GKE RESOURCE CONFLICTS" "Green"
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"

Show-Progress "Importing existing GCP resources..."
terraform import google_compute_subnetwork.main "projects/static-operator-469115-h1/regions/us-central1/subnetworks/addtocloud-subnet" 2>$null
terraform import google_compute_firewall.allow_internal "projects/static-operator-469115-h1/global/firewalls/addtocloud-allow-internal" 2>$null

Show-Progress "Continuing GCP deployment..."
terraform apply -var "gcp_project_id=static-operator-469115-h1" -auto-approve

Show-Progress "Checking GCP clusters..."
& "C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" container clusters list --project=static-operator-469115-h1

Write-Host ""

# Deploy AWS EKS
Show-Progress "DEPLOYING AWS EKS" "Yellow"
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"

# Clean up any locks
Remove-Item ".terraform\*.tmp" -Force -ErrorAction SilentlyContinue
Remove-Item ".terraform.lock.hcl" -Force -ErrorAction SilentlyContinue

Show-Progress "Re-initializing AWS..."
terraform init -upgrade

Show-Progress "Applying AWS deployment..."
terraform apply -var "project_name=addtocloud" -var "environment=production" -auto-approve

Show-Progress "Checking AWS clusters..."
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" eks list-clusters --region us-west-2

Write-Host ""
Write-Host "=========================================" -ForegroundColor Blue
Write-Host "FINAL STATUS OF ALL THREE CLOUDS" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Blue

Show-Progress "Azure AKS Status" "Cyan"
az aks list --output table

Show-Progress "GCP GKE Status" "Green"
& "C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" container clusters list --project=static-operator-469115-h1

Show-Progress "AWS EKS Status" "Yellow"
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" eks list-clusters --region us-west-2

Write-Host ""
Write-Host "=========================================" -ForegroundColor Blue
Write-Host "ENTERPRISE MULTI-CLOUD DEPLOYMENT DONE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Blue
