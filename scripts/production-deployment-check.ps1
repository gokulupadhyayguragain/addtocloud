# Production Deployment Script - NO LOCALHOST!
# This script ensures production deployment uses proper domain names

Write-Host "🚀 Production Deployment for AddToCloud - Multi-Cloud" -ForegroundColor Green
Write-Host ""

# Verify we're not deploying localhost to production
Write-Host "🔍 Pre-deployment Verification..." -ForegroundColor Blue
Write-Host ""

# Check for localhost in config files
$localhostFound = $false
$configFiles = @(
    "apps\frontend\next.config.js",
    "apps\frontend\package.json", 
    ".env.production",
    "devops\argocd\applications.yaml",
    "infrastructure\kubernetes\base\deployment.yaml"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -match "localhost|127\.0\.0\.1") {
            Write-Host "❌ DANGER: localhost found in $file" -ForegroundColor Red
            $localhostFound = $true
        } else {
            Write-Host "✅ $file: Clean (no localhost)" -ForegroundColor Green
        }
    }
}

if ($localhostFound) {
    Write-Host ""
    Write-Host "🚨 DEPLOYMENT BLOCKED: localhost addresses found in production files!" -ForegroundColor Red
    Write-Host "   Fix these before deploying to production." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✅ Localhost verification passed!" -ForegroundColor Green
Write-Host ""

# Check GitHub authentication
Write-Host "🔐 Checking GitHub Authentication..." -ForegroundColor Blue

# Check if GitHub CLI is available
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "  GitHub CLI found" -ForegroundColor Cyan
    try {
        $authStatus = gh auth status 2>&1
        if ($authStatus -match "Logged in") {
            Write-Host "✅ GitHub CLI: Authenticated" -ForegroundColor Green
            $githubUser = (gh api user --jq .login 2>$null)
            Write-Host "  User: $githubUser" -ForegroundColor Cyan
        } else {
            Write-Host "❌ GitHub CLI: Not authenticated" -ForegroundColor Red
            Write-Host "  Run: gh auth login" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ GitHub CLI: Auth check failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "📥 GitHub CLI not found. Installing..." -ForegroundColor Yellow
    
    # Try to install GitHub CLI via winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            winget install --id GitHub.cli
            Write-Host "✅ GitHub CLI installed" -ForegroundColor Green
            Write-Host "  Please run: gh auth login" -ForegroundColor Cyan
        } catch {
            Write-Host "❌ Failed to install GitHub CLI via winget" -ForegroundColor Red
        }
    } else {
        Write-Host "📋 Manual GitHub CLI installation required:" -ForegroundColor Yellow
        Write-Host "  1. Download from: https://cli.github.com/" -ForegroundColor Cyan
        Write-Host "  2. Run: gh auth login" -ForegroundColor Cyan
    }
}

# Check Git configuration
Write-Host ""
Write-Host "📝 Git Configuration:" -ForegroundColor Blue
$gitUser = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null

if ($gitUser -and $gitEmail) {
    Write-Host "✅ Git configured: $gitUser <$gitEmail>" -ForegroundColor Green
    
    # Verify this matches expected GitHub user
    if ($gitUser -eq "gokulupadhyayguragain") {
        Write-Host "✅ Git user matches repository owner" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Git user different from repository owner (gokulupadhyayguragain)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Git not configured" -ForegroundColor Red
    Write-Host "  Run these commands:" -ForegroundColor Yellow
    Write-Host "  git config --global user.name 'gokulupadhyayguragain'" -ForegroundColor Cyan
    Write-Host "  git config --global user.email 'gokulupadhyayguragain@gmail.com'" -ForegroundColor Cyan
}

# Check repository remote
Write-Host ""
Write-Host "🔗 Repository Configuration:" -ForegroundColor Blue
try {
    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl) {
        Write-Host "✅ Remote URL: $remoteUrl" -ForegroundColor Green
        
        if ($remoteUrl -match "gokulupadhyayguragain/addtocloud") {
            Write-Host "✅ Correct repository" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Repository URL doesn't match expected repo" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ No Git remote configured" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Not a Git repository or no remote set" -ForegroundColor Red
}

# Check required environment variables for deployment
Write-Host ""
Write-Host "🌍 Environment Variables Check:" -ForegroundColor Blue

$requiredEnvVars = @(
    "GITHUB_TOKEN",
    "CLOUDFLARE_API_TOKEN", 
    "CLOUDFLARE_ACCOUNT_ID",
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY"
)

$missingVars = @()
foreach ($var in $requiredEnvVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
        $maskedValue = $value.Substring(0, [Math]::Min(8, $value.Length)) + "***"
        Write-Host "✅ $var`: $maskedValue" -ForegroundColor Green
    } else {
        Write-Host "❌ $var`: Not set" -ForegroundColor Red
        $missingVars += $var
    }
}

# Provide instructions for missing environment variables
if ($missingVars.Count -gt 0) {
    Write-Host ""
    Write-Host "🔧 Required Environment Variables Missing:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($var in $missingVars) {
        switch ($var) {
            "GITHUB_TOKEN" {
                Write-Host "  $var`: " -ForegroundColor Red -NoNewline
                Write-Host "Personal Access Token from GitHub" -ForegroundColor Cyan
                Write-Host "    1. Go to: https://github.com/settings/tokens" -ForegroundColor White
                Write-Host "    2. Generate new token with 'repo' and 'packages' permissions" -ForegroundColor White
                Write-Host "    3. Set: `$env:GITHUB_TOKEN='your_token_here'" -ForegroundColor White
            }
            "CLOUDFLARE_API_TOKEN" {
                Write-Host "  $var`: " -ForegroundColor Red -NoNewline
                Write-Host "API Token from Cloudflare" -ForegroundColor Cyan
                Write-Host "    1. Go to: https://dash.cloudflare.com/profile/api-tokens" -ForegroundColor White
                Write-Host "    2. Create token with 'Cloudflare Pages:Edit' permission" -ForegroundColor White
                Write-Host "    3. Set: `$env:CLOUDFLARE_API_TOKEN='your_token_here'" -ForegroundColor White
            }
            "CLOUDFLARE_ACCOUNT_ID" {
                Write-Host "  $var`: " -ForegroundColor Red -NoNewline
                Write-Host "Account ID from Cloudflare" -ForegroundColor Cyan
                Write-Host "    1. Go to: https://dash.cloudflare.com/" -ForegroundColor White
                Write-Host "    2. Copy Account ID from right sidebar" -ForegroundColor White
                Write-Host "    3. Set: `$env:CLOUDFLARE_ACCOUNT_ID='your_account_id'" -ForegroundColor White
            }
            "AWS_ACCESS_KEY_ID" {
                Write-Host "  $var`: " -ForegroundColor Red -NoNewline
                Write-Host "AWS Access Key" -ForegroundColor Cyan
                Write-Host "    1. Go to: https://console.aws.amazon.com/iam/home#/security_credentials" -ForegroundColor White
                Write-Host "    2. Create new access key" -ForegroundColor White
                Write-Host "    3. Set: `$env:AWS_ACCESS_KEY_ID='your_key_id'" -ForegroundColor White
            }
            "AWS_SECRET_ACCESS_KEY" {
                Write-Host "  $var`: " -ForegroundColor Red -NoNewline
                Write-Host "AWS Secret Key" -ForegroundColor Cyan
                Write-Host "    Set: `$env:AWS_SECRET_ACCESS_KEY='your_secret_key'" -ForegroundColor White
            }
        }
        Write-Host ""
    }
}

# Check cloud CLI tools
Write-Host "🛠️ Cloud CLI Tools Check:" -ForegroundColor Blue

$cliTools = @(
    @{name="kubectl"; description="Kubernetes CLI"},
    @{name="terraform"; description="Infrastructure as Code"},
    @{name="aws"; description="AWS CLI"},
    @{name="gcloud"; description="Google Cloud CLI"},
    @{name="az"; description="Azure CLI"},
    @{name="docker"; description="Container platform"},
    @{name="helm"; description="Kubernetes package manager"}
)

$missingTools = @()
foreach ($tool in $cliTools) {
    if (Get-Command $tool.name -ErrorAction SilentlyContinue) {
        $version = & $tool.name --version 2>$null | Select-Object -First 1
        Write-Host "✅ $($tool.name): Installed" -ForegroundColor Green
    } else {
        Write-Host "❌ $($tool.name): Not installed ($($tool.description))" -ForegroundColor Red
        $missingTools += $tool
    }
}

# Final deployment readiness check
Write-Host ""
Write-Host "🎯 Deployment Readiness Summary:" -ForegroundColor Blue
Write-Host ""

$readinessIssues = 0

if ($localhostFound) {
    Write-Host "❌ Localhost addresses in production files" -ForegroundColor Red
    $readinessIssues++
}

if ($missingVars.Count -gt 0) {
    Write-Host "❌ Missing environment variables: $($missingVars.Count)" -ForegroundColor Red
    $readinessIssues++
}

if ($missingTools.Count -gt 0) {
    Write-Host "❌ Missing CLI tools: $($missingTools.Count)" -ForegroundColor Red
    $readinessIssues++
}

if (!$gitUser -or !$gitEmail) {
    Write-Host "❌ Git not properly configured" -ForegroundColor Red
    $readinessIssues++
}

if ($readinessIssues -eq 0) {
    Write-Host "🎉 READY FOR PRODUCTION DEPLOYMENT!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor Blue
    Write-Host "  1. Run: .\scripts\deploy-complete-multicloud.ps1" -ForegroundColor Cyan
    Write-Host "  2. Monitor deployment progress" -ForegroundColor Cyan
    Write-Host "  3. Verify at: https://addtocloud.tech" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔗 Production URLs:" -ForegroundColor Blue
    Write-Host "  Frontend: https://addtocloud.tech" -ForegroundColor Cyan
    Write-Host "  API: https://api.addtocloud.tech" -ForegroundColor Cyan
    Write-Host "  Grafana: https://grafana.addtocloud.tech" -ForegroundColor Cyan
    Write-Host "  ArgoCD: https://argocd.addtocloud.tech" -ForegroundColor Cyan
} else {
    Write-Host "🚫 NOT READY FOR DEPLOYMENT" -ForegroundColor Red
    Write-Host "   Fix $readinessIssues issue(s) above before deploying" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💡 Remember: Production uses proper domain names, NOT localhost!" -ForegroundColor Green
