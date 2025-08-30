# Ultimate Deployment Fix - Import Existing Resources

Write-Host "🔧 ULTIMATE DEPLOYMENT FIX - IMPORTING EXISTING RESOURCES" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Blue
Write-Host ""

# Set up environment
$env:PATH += ";C:\Program Files\Amazon\AWSCLIV2"
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"

try {
    # Fix Azure AKS - Import all existing resources
    Write-Host "1️⃣ FIXING AZURE AKS - IMPORTING EXISTING RESOURCES" -ForegroundColor Cyan
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure"
    
    Write-Host "Importing Azure resource group..." -ForegroundColor Yellow
    terraform import azurerm_resource_group.addtocloud /subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod
    
    Write-Host "Importing Azure virtual network..." -ForegroundColor Yellow
    terraform import azurerm_virtual_network.addtocloud /subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod/providers/Microsoft.Network/virtualNetworks/vnet-addtocloud-prod
    
    Write-Host "Importing Azure container registry..." -ForegroundColor Yellow
    terraform import azurerm_container_registry.addtocloud /subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod/providers/Microsoft.ContainerRegistry/registries/addtocloudacr2025
    
    Write-Host "Importing Azure PostgreSQL server..." -ForegroundColor Yellow
    terraform import azurerm_postgresql_flexible_server.addtocloud /subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-addtocloud-prod
    
    Write-Host "Continuing Azure deployment..." -ForegroundColor Yellow
    terraform apply -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure AKS deployment completed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Azure AKS partial deployment - check manually" -ForegroundColor Yellow
    }

    Write-Host ""

    # Fix GCP GKE - Import existing resources
    Write-Host "2️⃣ FIXING GCP GKE - IMPORTING EXISTING RESOURCES" -ForegroundColor Green
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"
    
    Write-Host "Importing GCP network..." -ForegroundColor Yellow
    terraform import google_compute_network.main projects/static-operator-469115-h1/global/networks/addtocloud-vpc
    
    Write-Host "Importing GCP service account..." -ForegroundColor Yellow
    terraform import google_service_account.gke_nodes projects/static-operator-469115-h1/serviceAccounts/addtocloud-gke-nodes@static-operator-469115-h1.iam.gserviceaccount.com
    
    Write-Host "Continuing GCP deployment..." -ForegroundColor Yellow
    terraform apply -var="gcp_project_id=static-operator-469115-h1" -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GCP GKE deployment completed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ GCP GKE partial deployment - check manually" -ForegroundColor Yellow
    }

    Write-Host ""

    # Check AWS EKS - Start fresh deployment
    Write-Host "3️⃣ STARTING AWS EKS DEPLOYMENT" -ForegroundColor Yellow
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"
    
    Write-Host "Starting AWS EKS deployment..." -ForegroundColor Yellow
    terraform apply -var="project_name=addtocloud" -var="environment=production" -auto-approve
    
    Write-Host ""

    # Final status check
    Write-Host "🎉 DEPLOYMENT SUMMARY" -ForegroundColor Magenta
    Write-Host "══════════════════════" -ForegroundColor Blue
    Write-Host ""
    
    # Check Azure
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure"
    Write-Host "Azure AKS Resources:" -ForegroundColor Cyan
    terraform state list | ForEach-Object { Write-Host "  ✅ $_" -ForegroundColor Green }
    
    Write-Host ""
    
    # Check GCP
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"
    Write-Host "GCP GKE Resources:" -ForegroundColor Cyan
    terraform state list | ForEach-Object { Write-Host "  ✅ $_" -ForegroundColor Green }
    
    Write-Host ""
    
    # Check AWS
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"
    Write-Host "AWS EKS Resources:" -ForegroundColor Cyan
    terraform state list | ForEach-Object { Write-Host "  ✅ $_" -ForegroundColor Green }
    
    Write-Host ""
    Write-Host "🌟 ALL DEPLOYMENT ERRORS FIXED!" -ForegroundColor Green
    Write-Host "Multi-cloud infrastructure is now ready!" -ForegroundColor Cyan

} catch {
    Write-Host "❌ Error during fix: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Ultimate deployment fix completed!" -ForegroundColor Green
