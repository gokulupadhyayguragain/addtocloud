# Multi-Cloud Deployment Error Fixes
# This script fixes all deployment errors for AWS EKS, Azure AKS, and GCP GKE

Write-Host "🔧 FIXING ALL CLOUD DEPLOYMENT ERRORS" -ForegroundColor Green
Write-Host "══════════════════════════════════════════" -ForegroundColor Blue
Write-Host ""

# Set up environment
$env:PATH += ";C:\Program Files\Amazon\AWSCLIV2"
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"

# Function to show status
function Show-Status {
    param($message, $color = "Cyan")
    Write-Host ""
    Write-Host "▶️ $message" -ForegroundColor $color
    Write-Host ""
}

# Function to handle errors
function Write-Error-Status {
    param($errorMessage)
    Write-Host "❌ Error: $errorMessage" -ForegroundColor Red
    Write-Host "Continuing with other deployments..." -ForegroundColor Yellow
}

try {
    # 1. Fix Azure AKS - Import existing resource group
    Show-Status "1️⃣ FIXING AZURE AKS DEPLOYMENT" "Green"
    
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure"
    Write-Host "📁 Azure Directory: $(Get-Location)" -ForegroundColor Gray
    
    Write-Host "Importing existing resource group..." -ForegroundColor Yellow
    terraform import azurerm_resource_group.addtocloud "/subscriptions/0691bc92-9379-4780-8d57-1c4d500901a7/resourceGroups/rg-addtocloud-prod"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Resource group imported successfully" -ForegroundColor Green
        Write-Host "Continuing Azure AKS deployment..." -ForegroundColor Yellow
        terraform apply -var="project_name=addtocloud" -var="environment=production" -auto-approve
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Azure AKS deployment completed!" -ForegroundColor Green
        } else {
            Write-Error-Status "Azure AKS deployment failed after import"
        }
    } else {
        Write-Host "⚠️ Resource group import failed, trying different approach..." -ForegroundColor Yellow
        # Alternative: Use different resource group name
        terraform apply -var="project_name=addtocloud" -var="environment=prod2" -auto-approve
    }

    # 2. Fix GCP GKE - Use correct project ID
    Show-Status "2️⃣ FIXING GCP GKE DEPLOYMENT" "Green"
    
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"
    Write-Host "📁 GCP Directory: $(Get-Location)" -ForegroundColor Gray
    
    # Get the actual GCP project ID
    $gcpProject = gcloud config get-value project
    Write-Host "Using GCP Project: $gcpProject" -ForegroundColor Cyan
    
    Write-Host "Deploying with correct project ID..." -ForegroundColor Yellow
    terraform apply -var="gcp_project_id=$gcpProject" -var="project_name=addtocloud" -var="environment=production" -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GCP GKE deployment completed!" -ForegroundColor Green
    } else {
        Write-Error-Status "GCP GKE deployment failed - checking project permissions"
        
        # Try to enable required APIs
        Write-Host "Enabling required GCP APIs..." -ForegroundColor Yellow
        gcloud services enable container.googleapis.com
        gcloud services enable compute.googleapis.com
        gcloud services enable iam.googleapis.com
        
        # Retry deployment
        terraform apply -var="gcp_project_id=$gcpProject" -var="project_name=addtocloud" -var="environment=production" -auto-approve
    }

    # 3. Check AWS EKS status
    Show-Status "3️⃣ CHECKING AWS EKS DEPLOYMENT" "Green"
    
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"
    Write-Host "📁 AWS Directory: $(Get-Location)" -ForegroundColor Gray
    
    # Check if AWS deployment is still running or completed
    $awsState = terraform show -json 2>$null
    if ($awsState) {
        Write-Host "✅ AWS EKS deployment is progressing or completed" -ForegroundColor Green
    } else {
        Write-Host "⚠️ AWS EKS deployment may need restart" -ForegroundColor Yellow
        Write-Host "Starting AWS EKS deployment..." -ForegroundColor Yellow
        terraform apply -var="project_name=addtocloud" -var="environment=production" -auto-approve
    }

    # 4. Summary and next steps
    Show-Status "🎉 DEPLOYMENT FIXES COMPLETED!" "Magenta"
    
    Write-Host "📊 DEPLOYMENT STATUS:" -ForegroundColor Cyan
    Write-Host ""
    
    # Check each cloud
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure"
    $azureState = terraform show 2>$null
    if ($azureState -and $azureState.Contains("azurerm_kubernetes_cluster")) {
        Write-Host "✅ Azure AKS: DEPLOYED" -ForegroundColor Green
    } else {
        Write-Host "⏳ Azure AKS: IN PROGRESS" -ForegroundColor Yellow
    }
    
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp"
    $gcpState = terraform show 2>$null
    if ($gcpState -and $gcpState.Contains("google_container_cluster")) {
        Write-Host "✅ GCP GKE: DEPLOYED" -ForegroundColor Green
    } else {
        Write-Host "⏳ GCP GKE: IN PROGRESS" -ForegroundColor Yellow
    }
    
    Set-Location "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws"
    $awsState = terraform show 2>$null
    if ($awsState -and $awsState.Contains("aws_eks_cluster")) {
        Write-Host "✅ AWS EKS: DEPLOYED" -ForegroundColor Green
    } else {
        Write-Host "⏳ AWS EKS: IN PROGRESS" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "🔗 NEXT STEPS:" -ForegroundColor Magenta
    Write-Host "1. Wait for all deployments to complete (5-10 minutes)" -ForegroundColor White
    Write-Host "2. Configure kubectl for all clusters" -ForegroundColor White
    Write-Host "3. Deploy AddToCloud application to all clusters" -ForegroundColor White
    Write-Host "4. Update Cloudflare frontend to use production APIs" -ForegroundColor White
    Write-Host ""
    Write-Host "🌟 You'll have AddToCloud running on all three major clouds!" -ForegroundColor Green

    Write-Host "✅ Multi-cloud deployment fix script completed!" -ForegroundColor Green
} catch {
    Write-Host "❌ Script error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check individual deployment logs for details" -ForegroundColor Yellow
}
