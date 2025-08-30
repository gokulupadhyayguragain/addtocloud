# Install Cloud CLIs for Multi-Cloud Deployment

Write-Host "🔧 Installing Cloud CLI Tools for Multi-Cloud Support..." -ForegroundColor Cyan
Write-Host ""

# Check what's already installed
Write-Host "📋 Current Status:" -ForegroundColor Blue
if (Get-Command az -ErrorAction SilentlyContinue) { Write-Host "✅ Azure CLI (already installed)" -ForegroundColor Green } else { Write-Host "❌ Azure CLI" -ForegroundColor Red }
if (Get-Command aws -ErrorAction SilentlyContinue) { Write-Host "✅ AWS CLI (already installed)" -ForegroundColor Green } else { Write-Host "❌ AWS CLI (need to install)" -ForegroundColor Red }
if (Get-Command gcloud -ErrorAction SilentlyContinue) { Write-Host "✅ Google Cloud CLI (already installed)" -ForegroundColor Green } else { Write-Host "❌ Google Cloud CLI (need to install)" -ForegroundColor Red }
Write-Host ""

# Install AWS CLI
Write-Host "1️⃣ Installing AWS CLI..." -ForegroundColor Yellow
try {
    # Download AWS CLI v2 installer
    $awsInstaller = "$env:TEMP\AWSCLIV2.msi"
    Write-Host "Downloading AWS CLI installer..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $awsInstaller
    
    Write-Host "Installing AWS CLI (may require admin permissions)..." -ForegroundColor Gray
    Start-Process msiexec.exe -Wait -ArgumentList "/i $awsInstaller /quiet"
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    Write-Host "✅ AWS CLI installed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ AWS CLI installation failed. Install manually from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
}

Write-Host ""

# Install Google Cloud CLI
Write-Host "2️⃣ Installing Google Cloud CLI..." -ForegroundColor Yellow
try {
    # Download Google Cloud CLI installer
    $gcloudInstaller = "$env:TEMP\GoogleCloudSDKInstaller.exe"
    Write-Host "Downloading Google Cloud CLI installer..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -OutFile $gcloudInstaller
    
    Write-Host "Installing Google Cloud CLI (may require admin permissions)..." -ForegroundColor Gray
    Start-Process $gcloudInstaller -Wait -ArgumentList "/S"
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    Write-Host "✅ Google Cloud CLI installed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Google Cloud CLI installation failed. Install manually from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔄 Verifying installations..." -ForegroundColor Blue

# Verify installations
if (Get-Command aws -ErrorAction SilentlyContinue) { 
    Write-Host "✅ AWS CLI: $(aws --version)" -ForegroundColor Green 
} else { 
    Write-Host "❌ AWS CLI not found" -ForegroundColor Red 
}

if (Get-Command gcloud -ErrorAction SilentlyContinue) { 
    Write-Host "✅ Google Cloud CLI: $(gcloud --version | Select-Object -First 1)" -ForegroundColor Green 
} else { 
    Write-Host "❌ Google Cloud CLI not found" -ForegroundColor Red 
}

Write-Host ""
Write-Host "📝 NEXT STEPS:" -ForegroundColor Magenta
Write-Host "1. Restart PowerShell/VS Code to refresh PATH" -ForegroundColor White
Write-Host "2. Configure AWS: aws configure" -ForegroundColor White
Write-Host "3. Configure GCP: gcloud auth login" -ForegroundColor White
Write-Host "4. Run multi-cloud deployment: .\deploy-to-clouds.ps1" -ForegroundColor White
Write-Host ""
Write-Host "💡 OR deploy to Azure AKS right now (already configured):" -ForegroundColor Yellow
Write-Host "cd infrastructure\terraform\azure" -ForegroundColor White
Write-Host "terraform apply" -ForegroundColor White
