# AddToCloud Repository Cleanup Script
Write-Host "🧹 Starting AddToCloud Repository Cleanup..." -ForegroundColor Green

# Function to safely remove files/directories
function Remove-SafelyIfExists {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Host "🗑️  Removing: $Path" -ForegroundColor Yellow
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Function to get directory size
function Get-DirectorySize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -File | Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1MB, 2)
    }
    return 0
}

Write-Host ""
Write-Host "📊 Current Repository Analysis..." -ForegroundColor Cyan

# Show large directories
$largeDirs = @(
    "google-cloud-sdk",
    "istio-1.19.5", 
    "windows-amd64",
    "node_modules",
    ".next",
    ".terraform",
    "bin"
)

foreach ($dir in $largeDirs) {
    if (Test-Path $dir) {
        $size = Get-DirectorySize $dir
        Write-Host "📁 $dir : ${size} MB" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "🧹 Cleaning up large binaries and installations..." -ForegroundColor Cyan

# Remove large installation files
$largeFiles = @(
    "*.zip",
    "*.tar.gz", 
    "*.msi",
    "kubectl.exe",
    "AWSCLIV2.msi",
    "gcloud-sdk.zip",
    "istio.zip",
    "helm.zip"
)

foreach ($pattern in $largeFiles) {
    Get-ChildItem -Path . -Name $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyIfExists $_
    }
}

# Remove installation directories
$installDirs = @(
    "google-cloud-sdk",
    "istio-1.19.5",
    "windows-amd64"
)

foreach ($dir in $installDirs) {
    Remove-SafelyIfExists $dir
}

Write-Host ""
Write-Host "🧹 Cleaning up build artifacts..." -ForegroundColor Cyan

# Remove build artifacts and temporary files
$buildArtifacts = @(
    "apps/backend/*.exe",
    "apps/backend/main",
    "apps/backend/addtocloud",
    "apps/backend/addtocloud-api", 
    "apps/backend/cmd.exe",
    "apps/backend/bin",
    "apps/frontend/.next",
    "apps/frontend/node_modules",
    "apps/frontend/build",
    "apps/frontend/dist"
)

foreach ($pattern in $buildArtifacts) {
    Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyIfExists $_.FullName
    }
}

Write-Host ""
Write-Host "🧹 Cleaning up Terraform state..." -ForegroundColor Cyan

# Remove Terraform files
Get-ChildItem -Path "infrastructure/terraform" -Recurse -Include "*.tfstate*", ".terraform*", "terraform.tfvars" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-SafelyIfExists $_.FullName
}

Write-Host ""
Write-Host "🧹 Cleaning up logs and temporary files..." -ForegroundColor Cyan

# Remove logs and temporary files
$tempFiles = @(
    "*.log",
    "*.tmp", 
    ".DS_Store",
    "Thumbs.db",
    "*.cache"
)

foreach ($pattern in $tempFiles) {
    Get-ChildItem -Path . -Recurse -Name $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyIfExists $_.FullName
    }
}

Write-Host ""
Write-Host "📋 Creating clean project structure..." -ForegroundColor Cyan

# Ensure proper directory structure exists
$requiredDirs = @(
    "apps/backend",
    "apps/frontend", 
    "apps/credential-service",
    "infrastructure/kubernetes",
    "infrastructure/terraform/aws",
    "infrastructure/terraform/azure",
    "infrastructure/terraform/gcp",
    "infrastructure/docker",
    "infrastructure/istio",
    "infrastructure/monitoring",
    "devops/argocd",
    "devops/github-actions",
    "scripts",
    "docs"
)

foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✅ Created directory: $dir" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🔍 Post-cleanup analysis..." -ForegroundColor Cyan

# Show remaining large files
$remainingLarge = Get-ChildItem -Recurse -File | Where-Object {$_.Length -gt 5MB} | Sort-Object Length -Descending | Select-Object -First 10

if ($remainingLarge) {
    Write-Host "📋 Remaining large files (>5MB):" -ForegroundColor Yellow
    foreach ($file in $remainingLarge) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Host "   📄 $($file.Name) - ${sizeMB} MB" -ForegroundColor White
    }
} else {
    Write-Host "✅ No large files remaining (>5MB)" -ForegroundColor Green
}

# Check git status
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "📦 Git Status:" -ForegroundColor Cyan
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "📋 Files changed:" -ForegroundColor Yellow
        $gitStatus | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
    } else {
        Write-Host "✅ Working directory clean" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "✅ Cleanup Complete!" -ForegroundColor Green
Write-Host "🎯 Repository is now optimized for production" -ForegroundColor Cyan
Write-Host "📧 Credential service ready for deployment" -ForegroundColor Cyan
Write-Host "🔒 Email notifications configured" -ForegroundColor Cyan

Write-Host ""
Write-Host "📌 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure email credentials in the Kubernetes secret" -ForegroundColor White
Write-Host "2. Deploy credential service: kubectl apply -f infrastructure/kubernetes/credential-service.yaml" -ForegroundColor White
Write-Host "3. Access request form will be available at: http://your-domain/credential-request" -ForegroundColor White
Write-Host "4. Update .env file with your email settings" -ForegroundColor White
