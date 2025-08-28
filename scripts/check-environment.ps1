# =============================================================================
# AddToCloud Environment Quick Check
# =============================================================================

# Check for critical development tools
Write-Host "🔍 Checking development environment..." -ForegroundColor Cyan

$tools = @(
    @{Name="Node.js"; Command="node"; Version="node --version"},
    @{Name="NPM"; Command="npm"; Version="npm --version"},
    @{Name="Docker"; Command="docker"; Version="docker --version"},
    @{Name="Go"; Command="go"; Version="go version"},
    @{Name="Wrangler"; Command="wrangler"; Version="wrangler --version"},
    @{Name="kubectl"; Command="kubectl"; Version="kubectl version --client"},
    @{Name="Terraform"; Command="terraform"; Version="terraform version"},
    @{Name="Azure CLI"; Command="az"; Version="az --version"},
    @{Name="AWS CLI"; Command="aws"; Version="aws --version"},
    @{Name="Google Cloud"; Command="gcloud"; Version="gcloud version"}
)

$installed = @()
$missing = @()

foreach ($tool in $tools) {
    try {
        $null = Get-Command $tool.Command -ErrorAction Stop
        $installed += $tool.Name
        Write-Host "✅ $($tool.Name)" -ForegroundColor Green
    } catch {
        $missing += $tool.Name
        Write-Host "❌ $($tool.Name)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "  Installed: $($installed.Count)/$($tools.Count)" -ForegroundColor Green
Write-Host "  Missing: $($missing.Count)" -ForegroundColor Red

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "🚨 Missing tools:" -ForegroundColor Yellow
    foreach ($tool in $missing) {
        Write-Host "  - $tool" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "💡 Run setup-dev-windows.ps1 to install missing tools" -ForegroundColor Blue
}

Write-Host ""
Write-Host "🚀 Quick start commands:" -ForegroundColor Cyan
Write-Host "  npm run dev        # Start development"
Write-Host "  npm run build      # Build for production" 
Write-Host "  npm run deploy     # Deploy everything"
