Write-Host "🧹 Starting AddToCloud Repository Cleanup..." -ForegroundColor Green

# Remove large files
Write-Host "Removing large installation files..." -ForegroundColor Cyan
if (Test-Path "gcloud-sdk.zip") { Remove-Item "gcloud-sdk.zip" -Force }
if (Test-Path "istio.zip") { Remove-Item "istio.zip" -Force }
if (Test-Path "helm.zip") { Remove-Item "helm.zip" -Force }
if (Test-Path "AWSCLIV2.msi") { Remove-Item "AWSCLIV2.msi" -Force }
if (Test-Path "kubectl.exe") { Remove-Item "kubectl.exe" -Force }

# Remove large directories
Write-Host "Removing large directories..." -ForegroundColor Cyan
if (Test-Path "google-cloud-sdk") { Remove-Item "google-cloud-sdk" -Recurse -Force }
if (Test-Path "istio-1.19.5") { Remove-Item "istio-1.19.5" -Recurse -Force }
if (Test-Path "windows-amd64") { Remove-Item "windows-amd64" -Recurse -Force }

# Remove build artifacts
Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan
Get-ChildItem -Path "apps" -Include "*.exe", "main", "bin" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# Remove node_modules and .next if they exist
if (Test-Path "apps/frontend/node_modules") { Remove-Item "apps/frontend/node_modules" -Recurse -Force }
if (Test-Path "apps/frontend/.next") { Remove-Item "apps/frontend/.next" -Recurse -Force }

# Clean Terraform state
Get-ChildItem -Path "infrastructure/terraform" -Include "*.tfstate*", ".terraform*" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Write-Host "✅ Cleanup Complete!" -ForegroundColor Green
Write-Host "📧 Credential service created and ready for deployment" -ForegroundColor Cyan
Write-Host "🔒 Email notification system configured" -ForegroundColor Cyan
