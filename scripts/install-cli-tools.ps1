#!/usr/bin/env powershell
# Quick CLI Installation Script for AddToCloud Deployment

Write-Host "🔧 Checking and Installing Cloud CLI Tools..." -ForegroundColor Green

# Check Azure CLI
try {
    $azVersion = az --version 2>$null | Select-String "azure-cli"
    Write-Host "✅ Azure CLI: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI not found" -ForegroundColor Red
}

# Check AWS CLI
try {
    $awsVersion = aws --version 2>$null
    Write-Host "✅ AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found - Installing..." -ForegroundColor Yellow
    # Try to install AWS CLI
    try {
        Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "$env:TEMP\AWSCLIV2.msi"
        Start-Process msiexec.exe -Wait -ArgumentList '/I', "$env:TEMP\AWSCLIV2.msi", '/quiet'
        Write-Host "✅ AWS CLI installed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ AWS CLI installation failed - will use GitHub Actions" -ForegroundColor Yellow
    }
}

# Check Google Cloud CLI
try {
    $gcpVersion = gcloud --version 2>$null
    Write-Host "✅ Google Cloud CLI: $gcpVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Google Cloud CLI not found" -ForegroundColor Red
    Write-Host "💡 Install manually from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚀 Deployment Status:" -ForegroundColor Cyan
Write-Host "  Frontend: Building 406 pages on Cloudflare" -ForegroundColor White
Write-Host "  Backend: Deploying to cloud providers via GitHub Actions" -ForegroundColor White
Write-Host "  Monitor: Check GitHub Actions for deployment progress" -ForegroundColor White

Write-Host ""
Write-Host "🌐 Expected URLs:" -ForegroundColor Cyan
Write-Host "  Frontend: https://addtocloud-tech.pages.dev" -ForegroundColor White
Write-Host "  Backend: Will be deployed to AWS/Azure/GCP" -ForegroundColor White
