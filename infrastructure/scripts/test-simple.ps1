# Simple deployment test - checks if kubectl is available and basic setup
Write-Host "🔍 Testing basic deployment prerequisites..." -ForegroundColor Blue

# Check if kubectl is available
Write-Host "Checking kubectl..." -ForegroundColor Yellow
kubectl version --client --short
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ kubectl is available" -ForegroundColor Green
} else {
    Write-Host "❌ kubectl not found" -ForegroundColor Red
}

# Check current context
Write-Host "Checking current context..." -ForegroundColor Yellow
$currentContext = kubectl config current-context
if ($currentContext) {
    Write-Host "ℹ️ Current context: $currentContext" -ForegroundColor Blue
} else {
    Write-Host "⚠️ No current context set" -ForegroundColor Yellow
}

# List available contexts
Write-Host "📋 Available contexts:" -ForegroundColor Blue
kubectl config get-contexts

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
docker version --format "{{.Client.Version}}"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker is available" -ForegroundColor Green
} else {
    Write-Host "⚠️ Docker not available" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Prerequisites check completed!" -ForegroundColor Green
