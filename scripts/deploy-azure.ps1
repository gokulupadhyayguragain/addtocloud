# Simplified Multi-Cloud Deployment for AddToCloud
# Starting with Azure since Azure CLI is available

Write-Host "Starting AddToCloud Deployment Process" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Step 1: Verify Azure Authentication
Write-Host "1. Checking Azure Authentication..." -ForegroundColor Blue
try {
    $azAccount = az account show --query "name" -o tsv 2>$null
    if ($azAccount) {
        Write-Host "OK: Azure authenticated as: $azAccount" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Not authenticated with Azure" -ForegroundColor Red
        Write-Host "Run: az login" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "ERROR: Azure CLI issue" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Build Frontend
Write-Host "2. Building Frontend..." -ForegroundColor Blue
Set-Location "apps\frontend"

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: npm install failed" -ForegroundColor Red
    exit 1
}

# Build for production
Write-Host "Building for production..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: npm build failed" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Frontend built successfully" -ForegroundColor Green
Set-Location "..\..\"

Write-Host ""

# Step 3: Deploy Azure Infrastructure
Write-Host "3. Deploying Azure Infrastructure..." -ForegroundColor Blue
Set-Location "infrastructure\terraform\azure"

# Check if main.tf exists
if (-not (Test-Path "main.tf")) {
    Write-Host "ERROR: Azure Terraform configuration not found" -ForegroundColor Red
    Set-Location "..\..\..\"
    exit 1
}

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform init failed" -ForegroundColor Red
    Set-Location "..\..\..\"
    exit 1
}

# Validate configuration
Write-Host "Validating Terraform configuration..." -ForegroundColor Yellow
terraform validate

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform validation failed" -ForegroundColor Red
    Set-Location "..\..\..\"
    exit 1
}

# Plan deployment
Write-Host "Planning infrastructure deployment..." -ForegroundColor Yellow
terraform plan -out=azure.tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform plan failed" -ForegroundColor Red
    Set-Location "..\..\..\"
    exit 1
}

Write-Host "Terraform plan completed. Review the plan above." -ForegroundColor Yellow
Write-Host "Do you want to apply the infrastructure? (y/N): " -ForegroundColor Cyan -NoNewline
$response = Read-Host

if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "Applying infrastructure..." -ForegroundColor Yellow
    terraform apply azure.tfplan
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: Azure infrastructure deployed!" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Terraform apply failed" -ForegroundColor Red
        Set-Location "..\..\..\"
        exit 1
    }
} else {
    Write-Host "Deployment cancelled. Infrastructure plan saved as azure.tfplan" -ForegroundColor Yellow
    Set-Location "..\..\..\"
    exit 0
}

Set-Location "..\..\..\"

Write-Host ""

# Step 4: Configure kubectl for AKS
Write-Host "4. Configuring kubectl for AKS..." -ForegroundColor Blue

# Get AKS credentials (assuming resource group and cluster names from Terraform)
Write-Host "Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials --resource-group addtocloud-rg --name addtocloud-aks --overwrite-existing

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: AKS credentials configured" -ForegroundColor Green
} else {
    Write-Host "ERROR: Failed to get AKS credentials" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 5: Deploy Kubernetes Resources
Write-Host "5. Deploying Kubernetes Resources..." -ForegroundColor Blue

# Deploy storage
if (Test-Path "infrastructure\kubernetes\storage\persistent-storage.yaml") {
    Write-Host "Deploying persistent storage..." -ForegroundColor Yellow
    kubectl apply -f infrastructure\kubernetes\storage\persistent-storage.yaml
}

# Deploy databases
if (Test-Path "infrastructure\kubernetes\database\database-deployments.yaml") {
    Write-Host "Deploying databases..." -ForegroundColor Yellow
    kubectl apply -f infrastructure\kubernetes\database\database-deployments.yaml
}

# Deploy application
if (Test-Path "infrastructure\kubernetes\deployments\app.yaml") {
    Write-Host "Deploying application..." -ForegroundColor Yellow
    kubectl apply -f infrastructure\kubernetes\deployments\app.yaml
}

Write-Host ""

# Step 6: Verify Deployment
Write-Host "6. Verifying Deployment..." -ForegroundColor Blue

Write-Host "Checking pods..." -ForegroundColor Yellow
kubectl get pods

Write-Host ""
Write-Host "Checking services..." -ForegroundColor Yellow
kubectl get services

Write-Host ""
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Install AWS CLI and Google Cloud CLI for multi-cloud deployment" -ForegroundColor Yellow
Write-Host "2. Configure Cloudflare DNS" -ForegroundColor Yellow
Write-Host "3. Set up monitoring and alerting" -ForegroundColor Yellow
Write-Host ""
Write-Host "Your AddToCloud platform is now running on Azure!" -ForegroundColor Green
