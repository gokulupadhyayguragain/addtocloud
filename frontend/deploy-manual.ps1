# Manual Cloudflare Pages Deployment Script (PowerShell)

Write-Host "🚀 Starting manual Cloudflare Pages deployment..." -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Error: package.json not found. Please run this from the frontend directory." -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm ci

# Set environment variables
Write-Host "🔧 Setting environment variables..." -ForegroundColor Yellow
$env:NEXT_PUBLIC_API_BASE_URL = "https://api.addtocloud.tech"
$env:NEXT_PUBLIC_EKS_API = "https://eks-api.addtocloud.tech"
$env:NEXT_PUBLIC_AKS_API = "https://aks-api.addtocloud.tech"
$env:NEXT_PUBLIC_GKE_API = "https://gke-api.addtocloud.tech"
$env:NEXT_PUBLIC_MONITORING_URL = "https://addtocloud.tech/monitoring"
$env:NEXT_PUBLIC_GRAFANA_URL = "https://addtocloud.tech/grafana"

# Build the project
Write-Host "🔨 Building the project..." -ForegroundColor Yellow
npm run build

# Check if build was successful
if (-not (Test-Path "out")) {
    Write-Host "❌ Build failed - out directory not created" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host "📁 Output directory: $PWD\out" -ForegroundColor Cyan
Write-Host "📋 Files in output:" -ForegroundColor Cyan
Get-ChildItem out | Format-Table

# Deploy using Wrangler
Write-Host "🌐 Deploying to Cloudflare Pages..." -ForegroundColor Cyan
npx wrangler pages deploy out --project-name addtocloud

Write-Host "🎉 Deployment completed!" -ForegroundColor Green
Write-Host "🔗 Site: https://addtocloud.tech" -ForegroundColor Cyan
