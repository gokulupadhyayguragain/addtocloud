# Setup Cloudflare Pages Project
# This script creates the Cloudflare Pages project for AddToCloud

Write-Host "🌟 Setting up Cloudflare Pages for AddToCloud..." -ForegroundColor Cyan

# Check if wrangler is installed
if (!(Get-Command "npx" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js/npm is required. Please install Node.js first." -ForegroundColor Red
    exit 1
}

Write-Host "📦 Installing/updating Wrangler CLI..." -ForegroundColor Yellow
npx wrangler@latest --version

Write-Host "🔐 Please ensure you have logged in to Cloudflare:" -ForegroundColor Yellow
Write-Host "   npx wrangler login" -ForegroundColor Gray

Write-Host "🚀 Creating Cloudflare Pages project..." -ForegroundColor Green

# Create the Pages project
Write-Host "Creating project 'addtocloud'..." -ForegroundColor Blue
npx wrangler pages project create addtocloud --compatibility-flags="nodejs_compat"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Cloudflare Pages project 'addtocloud' created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔧 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Build the frontend: cd frontend && npm run build" -ForegroundColor Gray
    Write-Host "2. Deploy manually: npx wrangler pages deploy frontend/out --project-name=addtocloud" -ForegroundColor Gray
    Write-Host "3. Or push to GitHub to trigger automatic deployment" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🌐 Your site will be available at: https://addtocloud.pages.dev" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create Cloudflare Pages project." -ForegroundColor Red
    Write-Host "Please check your Cloudflare authentication and try again." -ForegroundColor Yellow
    Write-Host "Run: npx wrangler login" -ForegroundColor Gray
}
