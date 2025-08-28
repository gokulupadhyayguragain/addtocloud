# =============================================================================
# AddToCloud - Quick Fix Script
# =============================================================================

# Check workspace
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Run this script from the project root directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Fixing development environment..." -ForegroundColor Cyan

# Clean dependencies
Write-Host "⚡ Cleaning dependencies..." -ForegroundColor Yellow
Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue

if (Test-Path "frontend") {
    Push-Location "frontend"
    Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
    Pop-Location
}

# Install dependencies
Write-Host "⚡ Installing root dependencies..." -ForegroundColor Yellow
npm install

if (Test-Path "frontend") {
    Write-Host "⚡ Installing frontend dependencies..." -ForegroundColor Yellow
    Push-Location "frontend"
    npm install
    Pop-Location
}

# Go modules
if (Test-Path "backend") {
    Write-Host "⚡ Cleaning Go modules..." -ForegroundColor Yellow
    Push-Location "backend"
    go mod tidy
    go mod download
    Pop-Location
}

# Verify
Write-Host ""
Write-Host "🔍 Verification:" -ForegroundColor Cyan
if (Test-Path "node_modules") { Write-Host "✅ Root packages" -ForegroundColor Green } else { Write-Host "❌ Root packages" -ForegroundColor Red }
if (Test-Path "frontend/node_modules") { Write-Host "✅ Frontend packages" -ForegroundColor Green } else { Write-Host "❌ Frontend packages" -ForegroundColor Red }
if (Test-Path "backend/go.sum") { Write-Host "✅ Go modules" -ForegroundColor Green } else { Write-Host "❌ Go modules" -ForegroundColor Red }

Write-Host ""
Write-Host "🎉 Quick fix completed!" -ForegroundColor Green
