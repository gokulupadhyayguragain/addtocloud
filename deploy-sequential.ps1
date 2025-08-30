# Sequential Multi-Cloud Deployment

Write-Host "SEQUENTIAL MULTI-CLOUD DEPLOYMENT" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Blue
Write-Host ""

$ErrorActionPreference = "Continue"

# Function to show deployment progress
function Show-Progress {
    param($Message, $Color = "Yellow")
    Write-Host $Message -ForegroundColor $Color
    Write-Host "Time: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
}

# 1. Deploy to Azure AKS
Show-Progress "STEP 1: DEPLOYING TO AZURE AKS" "Cyan"
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure"

Show-Progress "Initializing Terraform..."
terraform init

Show-Progress "Importing existing Azure resources..."
terraform import azurerm_resource_group.addtocloud "/subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod" 2>$null
terraform import azurerm_virtual_network.addtocloud "/subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod/providers/Microsoft.Network/virtualNetworks/vnet-addtocloud-prod" 2>$null

Show-Progress "Planning Azure deployment..."
terraform plan -out=azure.tfplan

Show-Progress "Applying Azure deployment..."
terraform apply -auto-approve azure.tfplan

Show-Progress "Checking Azure AKS deployment..."
az aks list --resource-group rg-addtocloud-prod --output table

Write-Host ""
Write-Host "AZURE DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host ""

# 2. Deploy to GCP GKE
Show-Progress "STEP 2: DEPLOYING TO GCP GKE" "Green"
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"

Show-Progress "Initializing Terraform..."
terraform init

Show-Progress "Planning GCP deployment..."
terraform plan -var="gcp_project_id=static-operator-469115-h1" -out=gcp.tfplan

Show-Progress "Applying GCP deployment..."
terraform apply -auto-approve gcp.tfplan

Show-Progress "Checking GCP GKE deployment..."
gcloud container clusters list --project=static-operator-469115-h1

Write-Host ""
Write-Host "GCP DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host ""

# 3. Deploy to AWS EKS
Show-Progress "STEP 3: DEPLOYING TO AWS EKS" "Yellow"
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"

Show-Progress "Initializing Terraform..."
terraform init

Show-Progress "Planning AWS deployment..."
terraform plan -var="project_name=addtocloud" -var="environment=production" -out=aws.tfplan

Show-Progress "Applying AWS deployment..."
terraform apply -auto-approve aws.tfplan

Show-Progress "Checking AWS EKS deployment..."
aws eks list-clusters --region us-west-2

Write-Host ""
Write-Host "ALL DEPLOYMENTS COMPLETED!" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Blue

# Final status check
Show-Progress "FINAL STATUS CHECK" "Magenta"

Write-Host "Azure AKS Clusters:" -ForegroundColor Cyan
az aks list --output table 2>$null

Write-Host "GCP GKE Clusters:" -ForegroundColor Green  
gcloud container clusters list 2>$null

Write-Host "AWS EKS Clusters:" -ForegroundColor Yellow
aws eks list-clusters 2>$null

Write-Host ""
Write-Host "MULTI-CLOUD DEPLOYMENT COMPLETE!" -ForegroundColor Green
