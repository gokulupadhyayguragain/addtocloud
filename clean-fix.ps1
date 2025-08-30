# Final Deployment Fix - Clean Version

Write-Host "FINAL DEPLOYMENT FIX - CLEAN VERSION" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Blue
Write-Host ""

# Set up environment
$env:PATH += ";C:\Program Files\Amazon\AWSCLIV2"
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"

# Fix Azure AKS
Write-Host "1. FIXING AZURE AKS" -ForegroundColor Cyan
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure"

Write-Host "Importing Azure resources..." -ForegroundColor Yellow
terraform import azurerm_resource_group.addtocloud "/subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod"
terraform import azurerm_virtual_network.addtocloud "/subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod/providers/Microsoft.Network/virtualNetworks/vnet-addtocloud-prod"
terraform import azurerm_container_registry.addtocloud "/subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod/providers/Microsoft.ContainerRegistry/registries/addtocloudacr2025"
terraform import azurerm_postgresql_flexible_server.addtocloud "/subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-addtocloud-prod"

Write-Host "Continuing Azure deployment..." -ForegroundColor Yellow
terraform apply -auto-approve

Write-Host ""

# Fix GCP GKE  
Write-Host "2. FIXING GCP GKE" -ForegroundColor Green
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"

Write-Host "Importing GCP resources..." -ForegroundColor Yellow
terraform import google_compute_network.main "projects/static-operator-469115-h1/global/networks/addtocloud-vpc"
terraform import google_service_account.gke_nodes "projects/static-operator-469115-h1/serviceAccounts/addtocloud-gke-nodes@static-operator-469115-h1.iam.gserviceaccount.com"

Write-Host "Continuing GCP deployment..." -ForegroundColor Yellow
terraform apply -var="gcp_project_id=static-operator-469115-h1" -auto-approve

Write-Host ""

# Start AWS EKS
Write-Host "3. STARTING AWS EKS" -ForegroundColor Yellow
Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"

Write-Host "Starting AWS deployment..." -ForegroundColor Yellow
terraform apply -var="project_name=addtocloud" -var="environment=production" -auto-approve

Write-Host ""
Write-Host "DEPLOYMENT FIX COMPLETED!" -ForegroundColor Green
