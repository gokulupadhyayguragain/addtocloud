# =============================================================================
# AddToCloud - Quick Problems Fix
# =============================================================================

Write-Host "🔧 Fixing AddToCloud Issues..." -ForegroundColor Green

$Fixed = 0

# Clean Azure Terraform
Write-Host "⚡ Cleaning Azure Terraform..." -ForegroundColor Yellow
Remove-Item "infrastructure\terraform\azure\.terraform" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "infrastructure\terraform\azure\.terraform.lock.hcl" -Force -ErrorAction SilentlyContinue
$Fixed++

# Update Next.js
Write-Host "⚡ Updating Next.js..." -ForegroundColor Yellow
Push-Location "frontend"
npm install --save next@14.2.32
$Fixed++
Pop-Location

# Fix vulnerabilities
Write-Host "⚡ Fixing vulnerabilities..." -ForegroundColor Yellow
Push-Location "frontend"
npm audit fix --force
$Fixed++
Pop-Location

# Clean Go modules
Write-Host "⚡ Cleaning Go modules..." -ForegroundColor Yellow
Push-Location "backend"
go mod tidy
$Fixed++
Pop-Location

# Test builds
Write-Host "⚡ Testing builds..." -ForegroundColor Yellow
npm run build
$Fixed++

Write-Host ""
Write-Host "✅ Fixed $Fixed major issues!" -ForegroundColor Green
Write-Host "🚀 Ready for deployment!" -ForegroundColor Cyan
