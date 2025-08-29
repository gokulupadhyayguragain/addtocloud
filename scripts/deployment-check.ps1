# AddToCloud Production Deployment Readiness Check
# Verifies all prerequisites for multi-cloud production deployment

Write-Host "Production Deployment Readiness Check" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: Verify NO localhost in production files
Write-Host "1. Checking for localhost in production configuration..." -ForegroundColor Yellow

$productionFiles = @(
    "apps/frontend/next.config.js",
    "apps/frontend/wrangler.toml", 
    ".env.production",
    "infrastructure/kubernetes/deployments/app.yaml",
    "infrastructure/istio/gateways/addtocloud-gateway.yaml"
)

$localhostFound = $false
foreach ($file in $productionFiles) {
    $fullPath = Join-Path $PWD $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        
        # Special handling for next.config.js - check if localhost is properly conditional
        if ($file -eq "apps/frontend/next.config.js") {
            # Check if production mode uses proper domains
            if ($content -match "NODE_ENV === 'production'.*https://api\.addtocloud\.tech" -and 
                $content -match "NODE_ENV === 'production'.*https://addtocloud\.tech") {
                Write-Host "OK: $file uses conditional localhost (development only)" -ForegroundColor Green
            } else {
                Write-Host "ERROR: $file production configuration incorrect" -ForegroundColor Red
                $localhostFound = $true
            }
        } else {
            # For other files, check for any localhost
            if ($content -match "localhost|127\.0\.0\.1") {
                # Ignore comments
                $lines = $content -split "`n"
                $hasRealLocalhost = $false
                foreach ($line in $lines) {
                    if ($line.Trim() -notmatch '^#' -and $line.Trim() -notmatch '^//' -and $line -match "localhost|127\.0\.0\.1") {
                        $hasRealLocalhost = $true
                        break
                    }
                }
                
                if ($hasRealLocalhost) {
                    Write-Host "ERROR: $file contains localhost/127.0.0.1" -ForegroundColor Red
                    $localhostFound = $true
                } else {
                    Write-Host "OK: $file is clean (localhost only in comments)" -ForegroundColor Green
                }
            } else {
                Write-Host "OK: $file is clean (no localhost)" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "WARNING: $file not found" -ForegroundColor Yellow
    }
}

if ($localhostFound) {
    Write-Host ""
    Write-Host "CRITICAL: Localhost addresses found in production files!" -ForegroundColor Red
    Write-Host "Production deployment will fail with localhost URLs." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "SUCCESS: No localhost addresses found in production configuration" -ForegroundColor Green
}

Write-Host ""

# Check 2: Environment files
Write-Host "2. Checking environment configuration..." -ForegroundColor Yellow

if (Test-Path ".env.production") {
    $prodEnv = Get-Content ".env.production" -Raw
    if ($prodEnv -match "addtocloud\.tech") {
        Write-Host "OK: .env.production contains proper domain" -ForegroundColor Green
    } else {
        Write-Host "WARNING: .env.production may not have proper domain" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: .env.production not found" -ForegroundColor Yellow
}

if (Test-Path ".env.development") {
    Write-Host "OK: .env.development found" -ForegroundColor Green
} else {
    Write-Host "WARNING: .env.development not found" -ForegroundColor Yellow
}

Write-Host ""

# Check 3: Git configuration
Write-Host "3. Checking Git configuration..." -ForegroundColor Yellow

$gitUser = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null

if ($gitUser -and $gitEmail) {
    Write-Host "OK: Git configured - User: $gitUser, Email: $gitEmail" -ForegroundColor Green
} else {
    Write-Host "ERROR: Git not properly configured" -ForegroundColor Red
    Write-Host "Run: git config --global user.name 'YourName'" -ForegroundColor Yellow
    Write-Host "Run: git config --global user.email 'your.email@example.com'" -ForegroundColor Yellow
}

Write-Host ""

# Check 4: Required tools
Write-Host "4. Checking required tools..." -ForegroundColor Yellow

# Check Docker
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        $dockerVersion = docker --version
        Write-Host "OK: Docker found - $dockerVersion" -ForegroundColor Green
    } catch {
        Write-Host "WARNING: Docker found but not running" -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR: Docker not found" -ForegroundColor Red
}

# Check kubectl
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "OK: kubectl found - $kubectlVersion" -ForegroundColor Green
} else {
    Write-Host "WARNING: kubectl not found (needed for K8s deployment)" -ForegroundColor Yellow
}

# Check GitHub CLI
if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        $authStatus = gh auth status 2>&1
        if ($authStatus -match "Logged in") {
            Write-Host "OK: GitHub CLI authenticated" -ForegroundColor Green
        } else {
            Write-Host "WARNING: GitHub CLI not authenticated - run 'gh auth login'" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARNING: GitHub CLI auth check failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: GitHub CLI not found" -ForegroundColor Yellow
    Write-Host "Install from: https://cli.github.com/" -ForegroundColor Cyan
}

Write-Host ""

# Check 5: Cloud CLI tools
Write-Host "5. Checking cloud CLI tools..." -ForegroundColor Yellow

# AWS CLI
if (Get-Command aws -ErrorAction SilentlyContinue) {
    $awsVersion = aws --version 2>$null
    Write-Host "OK: AWS CLI found - $awsVersion" -ForegroundColor Green
} else {
    Write-Host "WARNING: AWS CLI not found (needed for AWS EKS)" -ForegroundColor Yellow
}

# Azure CLI
if (Get-Command az -ErrorAction SilentlyContinue) {
    $azVersion = az --version 2>$null | Select-Object -First 1
    Write-Host "OK: Azure CLI found - $azVersion" -ForegroundColor Green
} else {
    Write-Host "WARNING: Azure CLI not found (needed for Azure AKS)" -ForegroundColor Yellow
}

# Google Cloud CLI
if (Get-Command gcloud -ErrorAction SilentlyContinue) {
    $gcloudVersion = gcloud --version 2>$null | Select-Object -First 1
    Write-Host "OK: Google Cloud CLI found - $gcloudVersion" -ForegroundColor Green
} else {
    Write-Host "WARNING: Google Cloud CLI not found (needed for GCP GKE)" -ForegroundColor Yellow
}

Write-Host ""

# Final summary
Write-Host "DEPLOYMENT READINESS SUMMARY" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

if (-not $localhostFound) {
    Write-Host "READY: No localhost in production configuration" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps for deployment:" -ForegroundColor White
    Write-Host "1. Ensure cloud CLI tools are authenticated" -ForegroundColor Yellow
    Write-Host "2. Run: terraform init && terraform apply (for each cloud)" -ForegroundColor Yellow
    Write-Host "3. Deploy to Kubernetes clusters" -ForegroundColor Yellow
    Write-Host "4. Configure Cloudflare DNS and CDN" -ForegroundColor Yellow
} else {
    Write-Host "BLOCKED: Fix localhost issues before deployment" -ForegroundColor Red
}
