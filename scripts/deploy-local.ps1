# Local Kubernetes Deployment for AddToCloud
# Using Docker and k3d for local testing before cloud deployment

Write-Host "Starting AddToCloud Local Deployment" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Step 1: Check Docker
Write-Host "1. Checking Docker..." -ForegroundColor Blue
try {
    $dockerVersion = docker --version
    Write-Host "OK: $dockerVersion" -ForegroundColor Green
    
    # Check if Docker is running
    docker ps > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: Docker daemon is running" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Docker daemon not running. Please start Docker Desktop." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Docker not found" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Install k3d if not present
Write-Host "2. Setting up k3d (lightweight Kubernetes)..." -ForegroundColor Blue
if (-not (Get-Command k3d -ErrorAction SilentlyContinue)) {
    Write-Host "Installing k3d..." -ForegroundColor Yellow
    
    # Download and install k3d
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh" -UseBasicParsing | Invoke-Expression
        Write-Host "OK: k3d installed" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to install k3d" -ForegroundColor Red
        Write-Host "Please install manually from: https://k3d.io/" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "OK: k3d already installed" -ForegroundColor Green
}

Write-Host ""

# Step 3: Create k3d cluster
Write-Host "3. Creating local Kubernetes cluster..." -ForegroundColor Blue

# Check if cluster already exists
$clusterExists = k3d cluster list | Select-String "addtocloud"
if ($clusterExists) {
    Write-Host "Cluster 'addtocloud' already exists. Deleting and recreating..." -ForegroundColor Yellow
    k3d cluster delete addtocloud
}

# Create new cluster with port mappings
Write-Host "Creating k3d cluster 'addtocloud'..." -ForegroundColor Yellow
k3d cluster create addtocloud --port "80:80@loadbalancer" --port "443:443@loadbalancer" --port "8080:8080@loadbalancer"

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: k3d cluster created successfully" -ForegroundColor Green
} else {
    Write-Host "ERROR: Failed to create k3d cluster" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Build backend Docker image
Write-Host "4. Building backend Docker image..." -ForegroundColor Blue
Set-Location "backend"

if (Test-Path "Dockerfile") {
    Write-Host "Building backend image..." -ForegroundColor Yellow
    docker build -t addtocloud-backend:latest .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: Backend image built" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Backend build failed" -ForegroundColor Red
        Set-Location ".."
        exit 1
    }
} else {
    Write-Host "WARNING: Backend Dockerfile not found, skipping build" -ForegroundColor Yellow
}

Set-Location ".."

Write-Host ""

# Step 5: Build frontend
Write-Host "5. Building frontend..." -ForegroundColor Blue
Set-Location "apps\frontend"

# Install dependencies
Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: npm install failed" -ForegroundColor Red
    Set-Location "..\..\"
    exit 1
}

# Build frontend
Write-Host "Building frontend..." -ForegroundColor Yellow
$env:NODE_ENV = "development"
npm run build

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Frontend built successfully" -ForegroundColor Green
} else {
    Write-Host "ERROR: Frontend build failed" -ForegroundColor Red
    Set-Location "..\..\"
    exit 1
}

Set-Location "..\..\"

Write-Host ""

# Step 6: Deploy to k3d cluster
Write-Host "6. Deploying to local Kubernetes cluster..." -ForegroundColor Blue

# Load backend image into k3d
if (Test-Path "backend\Dockerfile") {
    Write-Host "Loading backend image into k3d..." -ForegroundColor Yellow
    k3d image import addtocloud-backend:latest -c addtocloud
}

# Create namespace
Write-Host "Creating namespace..." -ForegroundColor Yellow
kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -

# Deploy databases
if (Test-Path "infrastructure\kubernetes\database\database-deployments.yaml") {
    Write-Host "Deploying databases..." -ForegroundColor Yellow
    kubectl apply -f infrastructure\kubernetes\database\database-deployments.yaml -n addtocloud
}

# Deploy application
if (Test-Path "infrastructure\kubernetes\deployments\app.yaml") {
    Write-Host "Deploying application..." -ForegroundColor Yellow
    kubectl apply -f infrastructure\kubernetes\deployments\app.yaml -n addtocloud
}

Write-Host ""

# Step 7: Verify deployment
Write-Host "7. Verifying deployment..." -ForegroundColor Blue

Write-Host "Waiting for pods to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "Pod status:" -ForegroundColor Yellow
kubectl get pods -n addtocloud

Write-Host ""
Write-Host "Service status:" -ForegroundColor Yellow
kubectl get services -n addtocloud

Write-Host ""

# Step 8: Start frontend development server
Write-Host "8. Starting frontend development server..." -ForegroundColor Blue
Set-Location "apps\frontend"

Write-Host "Starting Next.js development server..." -ForegroundColor Yellow
Write-Host "Frontend will be available at http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API will be proxied through the frontend" -ForegroundColor Cyan
Write-Host ""

# Start the development server
Start-Process -FilePath "npm" -ArgumentList "run", "dev" -NoNewWindow

Set-Location "..\..\"

Write-Host ""
Write-Host "LOCAL DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""
Write-Host "Your AddToCloud platform is now running locally:" -ForegroundColor White
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Cyan
Write-Host "  Backend API: http://localhost:3000/api" -ForegroundColor Cyan
Write-Host "  Kubernetes Dashboard: kubectl port-forward svc/kubernetes-dashboard 8080:80 -n kube-system" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps for Cloud Deployment:" -ForegroundColor Yellow
Write-Host "1. Set up cloud provider accounts and authentication" -ForegroundColor White
Write-Host "2. Configure Terraform variables for each cloud" -ForegroundColor White
Write-Host "3. Run cloud-specific deployment scripts" -ForegroundColor White
Write-Host "4. Configure Cloudflare DNS and CDN" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the development server" -ForegroundColor Yellow
