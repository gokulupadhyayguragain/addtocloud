# Simple deployment test - checks if kubectl is available and basic setup
Write-Host "🔍 Testing basic deployment prerequisites..." -ForegroundColor Blue

# Check if kubectl is available
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    if ($kubectlVersion) {
        Write-Host "✅ kubectl is available: $kubectlVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ kubectl not found or not working" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ kubectl error: $_" -ForegroundColor Red
    exit 1
}

# Check current context
try {
    $currentContext = kubectl config current-context 2>$null
    if ($currentContext) {
        Write-Host "ℹ️ Current context: $currentContext" -ForegroundColor Blue
    } else {
        Write-Host "⚠️ No current context set" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ No kubectl context configured" -ForegroundColor Yellow
}

# List available contexts
try {
    Write-Host "📋 Available contexts:" -ForegroundColor Blue
    $contexts = kubectl config get-contexts --no-headers 2>$null
    if ($contexts) {
        $contexts | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
    } else {
        Write-Host "  No contexts found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Error listing contexts" -ForegroundColor Red
}

# Check if Docker is running
try {
    $dockerVersion = docker version --format "{{.Client.Version}}" 2>$null
    if ($dockerVersion) {
        Write-Host "✅ Docker is available: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Docker not available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Docker not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Prerequisites check completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. If you have cloud clusters, configure kubectl contexts" -ForegroundColor White
Write-Host "2. Run .\setup-azure-aks.ps1 to create Azure cluster" -ForegroundColor White
Write-Host "3. Run .\setup-aws-eks.ps1 to create AWS cluster" -ForegroundColor White
Write-Host "4. Run .\setup-gcp-gke.ps1 to create GCP cluster" -ForegroundColor White
Write-Host "5. Run .\deploy-multicloud.ps1 to deploy applications" -ForegroundColor White
