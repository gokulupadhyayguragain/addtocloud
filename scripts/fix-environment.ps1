# =============================================================================
# AddToCloud - Fix Development Issues Script
# =============================================================================

# Check workspace
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Run this script from the project root directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Fixing development environment issues..." -ForegroundColor Cyan

# Function to safely run commands
function Invoke-SafeCommand {
    param([string]$Command, [string]$Description)
    
    Write-Host "⚡ $Description..." -ForegroundColor Yellow
    try {
        if ($Command.StartsWith("Remove-Item")) {
            $parts = $Command.Split(" ")
            $path = $parts[1]
            $switches = $parts[2..($parts.Length-1)]
            Remove-Item $path @switches
        } else {
            Invoke-Expression $Command
        }
        Write-Host "✅ $Description completed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ $Description failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Clean and reinstall dependencies
try {
    Write-Host "⚡ Cleaning root node_modules..." -ForegroundColor Yellow
    Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Cleaned root node_modules" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Failed to clean root node_modules" -ForegroundColor Red
}

try {
    Write-Host "⚡ Removing root lock file..." -ForegroundColor Yellow
    Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Removed root lock file" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Failed to remove root lock file" -ForegroundColor Red
}

Push-Location "frontend"
try {
    Write-Host "⚡ Cleaning frontend node_modules..." -ForegroundColor Yellow
    Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Cleaned frontend node_modules" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Failed to clean frontend node_modules" -ForegroundColor Red
}

try {
    Write-Host "⚡ Removing frontend lock file..." -ForegroundColor Yellow
    Remove-Item "package-lock.json" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Removed frontend lock file" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Failed to remove frontend lock file" -ForegroundColor Red
}
Pop-Location

# Reinstall dependencies
Invoke-SafeCommand "npm install" "Installing root dependencies"

Push-Location "frontend"
Invoke-SafeCommand "npm install" "Installing frontend dependencies"
Pop-Location

# Go module cleanup
Push-Location "backend"
Invoke-SafeCommand "go mod tidy" "Cleaning Go modules"
Invoke-SafeCommand "go mod download" "Downloading Go dependencies"
Pop-Location

# Verify installations
Write-Host "🔍 Verifying installations..." -ForegroundColor Cyan

$checks = @(
    @{Name="Root packages"; Test={Test-Path "node_modules"}},
    @{Name="Frontend packages"; Test={Test-Path "frontend/node_modules"}},
    @{Name="Go modules"; Test={Test-Path "backend/go.sum"}}
)

foreach ($check in $checks) {
    if (& $check.Test) {
        Write-Host "✅ $($check.Name)" -ForegroundColor Green
    } else {
        Write-Host "❌ $($check.Name)" -ForegroundColor Red
    }
}

# Check for common issues
Write-Host ""
Write-Host "🔍 Checking for common issues..." -ForegroundColor Cyan

# Check Docker
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Docker not running - start Docker Desktop" -ForegroundColor Yellow
}

# Check Node version
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Environment fixes completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "  1. npm run dev        # Test development servers"
Write-Host "  2. npm run build      # Test production build"
Write-Host "  3. npm run deploy     # Deploy when ready"
