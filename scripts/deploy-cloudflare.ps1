# =============================================================================
# AddToCloud Multi-Cloud Deployment Script (Cloudflare Frontend) - PowerShell
# =============================================================================
# This script deploys frontend to Cloudflare and backend to multi-cloud

param(
    [switch]$FrontendOnly,
    [switch]$BackendOnly,
    [switch]$SkipAzure,
    [switch]$SkipAWS,
    [switch]$SkipGCP,
    [string]$Environment = "production",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Configuration
$ProjectName = "addtocloud"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir

# Deployment flags
$DeployFrontend = -not $BackendOnly
$DeployBackend = -not $FrontendOnly
$DeployAzure = $DeployBackend -and -not $SkipAzure
$DeployAWS = $DeployBackend -and -not $SkipAWS
$DeployGCP = $DeployBackend -and -not $SkipGCP

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
    Magenta = "Magenta"
}

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor $Colors.Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red
    exit 1
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Cyan
}

function Show-Help {
    Write-Host "AddToCloud Deployment Script (PowerShell)" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "Usage: .\deploy-cloudflare.ps1 [OPTIONS]" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "Options:" -ForegroundColor $Colors.Blue
    Write-Host "  -FrontendOnly       Deploy only frontend to Cloudflare"
    Write-Host "  -BackendOnly        Deploy only backend to clouds"
    Write-Host "  -SkipAzure         Skip Azure deployment"
    Write-Host "  -SkipAWS           Skip AWS deployment"
    Write-Host "  -SkipGCP           Skip GCP deployment"
    Write-Host "  -Environment ENV   Set environment (development|staging|production)"
    Write-Host "  -Help              Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor $Colors.Blue
    Write-Host "  .\deploy-cloudflare.ps1                           # Deploy everything"
    Write-Host "  .\deploy-cloudflare.ps1 -FrontendOnly             # Deploy only frontend"
    Write-Host "  .\deploy-cloudflare.ps1 -BackendOnly -SkipAzure   # Deploy backend to AWS and GCP only"
    Write-Host "  .\deploy-cloudflare.ps1 -Environment staging      # Deploy to staging environment"
    exit 0
}

function Test-CommandExists {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."
    
    # Required tools
    $tools = @("node", "npm", "docker", "kubectl", "terraform")
    
    # Add cloud CLI tools based on deployment flags
    if ($DeployFrontend) { $tools += "wrangler" }
    if ($DeployAzure) { $tools += "az" }
    if ($DeployAWS) { $tools += "aws" }
    if ($DeployGCP) { $tools += "gcloud" }
    
    foreach ($tool in $tools) {
        if (Test-CommandExists $tool) {
            Write-Info "✓ $tool is installed"
        }
        else {
            Write-ErrorMsg "$tool is not installed. Please install it first."
        }
    }
    
    Write-Success "All prerequisites checked"
}

function Initialize-Environment {
    Write-Log "Setting up environment for $Environment..."
    
    # Create necessary directories
    $dirs = @(
        "$RootDir\logs",
        "$RootDir\tmp"
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # Load environment variables
    $envFile = "$RootDir\.env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
            }
        }
        Write-Info "✓ Environment variables loaded"
    }
    
    # Load environment-specific variables
    $envSpecificFile = "$RootDir\.env.$Environment"
    if (Test-Path $envSpecificFile) {
        Get-Content $envSpecificFile | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
            }
        }
        Write-Info "✓ Environment-specific variables loaded"
    }
    
    Write-Success "Environment setup complete"
}

function Deploy-Frontend {
    if (-not $DeployFrontend) {
        Write-Info "Skipping frontend deployment"
        return
    }
    
    Write-Log "Deploying frontend to Cloudflare Pages..."
    
    Push-Location "$RootDir\frontend"
    
    try {
        # Install dependencies
        Write-Info "Installing frontend dependencies..."
        npm ci
        
        # Set environment variables for build
        $env:NEXT_PUBLIC_ENVIRONMENT = $Environment
        
        switch ($Environment) {
            "production" {
                $env:NEXT_PUBLIC_API_URL = "https://api.addtocloud.tech"
                $env:NEXT_PUBLIC_APP_URL = "https://addtocloud.tech"
            }
            "staging" {
                $env:NEXT_PUBLIC_API_URL = "https://staging-api.addtocloud.tech"
                $env:NEXT_PUBLIC_APP_URL = "https://staging.addtocloud.tech"
            }
            "development" {
                $env:NEXT_PUBLIC_API_URL = "http://localhost:8080"
                $env:NEXT_PUBLIC_APP_URL = "http://localhost:3000"
            }
        }
        
        # Build and export
        Write-Info "Building frontend for static export..."
        npm run build:export
        
        # Deploy to Cloudflare
        Write-Info "Deploying to Cloudflare Pages..."
        if ($Environment -eq "production") {
            wrangler pages deploy out --project-name addtocloud-frontend --env production
        }
        else {
            wrangler pages deploy out --project-name addtocloud-frontend --env $Environment
        }
        
        Write-Success "Frontend deployed to Cloudflare Pages"
    }
    finally {
        Pop-Location
    }
}

function Build-DockerImages {
    Write-Log "Building Docker images..."
    
    Push-Location $RootDir
    
    try {
        # Build backend image
        Write-Info "Building backend Docker image..."
        docker build -t "addtocloud-backend:latest" -f infrastructure\docker\Dockerfile.backend .
        
        # Build frontend image (for development/backup)
        Write-Info "Building frontend Docker image..."
        docker build -t "addtocloud-frontend:latest" -f infrastructure\docker\Dockerfile.frontend .
        
        Write-Success "Docker images built successfully"
    }
    finally {
        Pop-Location
    }
}

function Deploy-Azure {
    if (-not $DeployAzure) {
        Write-Info "Skipping Azure deployment"
        return
    }
    
    Write-Log "Deploying to Azure AKS..."
    
    Push-Location "$RootDir\infrastructure\terraform\azure"
    
    try {
        # Initialize Terraform
        Write-Info "Initializing Terraform for Azure..."
        terraform init -input=false
        
        # Plan deployment
        Write-Info "Planning Azure infrastructure..."
        terraform plan -out=tfplan -var="environment=$Environment" -var="project_name=$ProjectName"
        
        # Apply deployment
        Write-Info "Applying Azure infrastructure..."
        terraform apply tfplan
        
        # Get AKS credentials
        $resourceGroup = terraform output -raw resource_group_name
        $clusterName = terraform output -raw cluster_name
        
        Write-Info "Getting AKS credentials..."
        az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing
        
        # Deploy to Kubernetes
        Write-Info "Deploying to AKS..."
        kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -f "$RootDir\infrastructure\kubernetes\deployments\" -n addtocloud
        kubectl apply -f "$RootDir\infrastructure\istio\" -n addtocloud
        
        Write-Success "Azure deployment completed"
    }
    finally {
        Pop-Location
    }
}

function Deploy-AWS {
    if (-not $DeployAWS) {
        Write-Info "Skipping AWS deployment"
        return
    }
    
    Write-Log "Deploying to AWS EKS..."
    
    Push-Location "$RootDir\infrastructure\terraform\aws"
    
    try {
        # Initialize Terraform
        Write-Info "Initializing Terraform for AWS..."
        terraform init -input=false
        
        # Plan deployment
        Write-Info "Planning AWS infrastructure..."
        terraform plan -out=tfplan -var="environment=$Environment" -var="project_name=$ProjectName"
        
        # Apply deployment
        Write-Info "Applying AWS infrastructure..."
        terraform apply tfplan
        
        # Get EKS credentials
        $clusterName = terraform output -raw cluster_name
        $region = terraform output -raw region
        
        Write-Info "Getting EKS credentials..."
        aws eks update-kubeconfig --region $region --name $clusterName
        
        # Deploy to Kubernetes
        Write-Info "Deploying to EKS..."
        kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -f "$RootDir\infrastructure\kubernetes\deployments\" -n addtocloud
        kubectl apply -f "$RootDir\infrastructure\istio\" -n addtocloud
        
        Write-Success "AWS deployment completed"
    }
    finally {
        Pop-Location
    }
}

function Deploy-GCP {
    if (-not $DeployGCP) {
        Write-Info "Skipping GCP deployment"
        return
    }
    
    Write-Log "Deploying to GCP GKE..."
    
    Push-Location "$RootDir\infrastructure\terraform\gcp"
    
    try {
        # Initialize Terraform
        Write-Info "Initializing Terraform for GCP..."
        terraform init -input=false
        
        # Plan deployment
        Write-Info "Planning GCP infrastructure..."
        terraform plan -out=tfplan -var="environment=$Environment" -var="project_name=$ProjectName"
        
        # Apply deployment
        Write-Info "Applying GCP infrastructure..."
        terraform apply tfplan
        
        # Get GKE credentials
        $clusterName = terraform output -raw cluster_name
        $zone = terraform output -raw zone
        $projectId = terraform output -raw project_id
        
        Write-Info "Getting GKE credentials..."
        gcloud container clusters get-credentials $clusterName --zone $zone --project $projectId
        
        # Deploy to Kubernetes
        Write-Info "Deploying to GKE..."
        kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -f "$RootDir\infrastructure\kubernetes\deployments\" -n addtocloud
        kubectl apply -f "$RootDir\infrastructure\istio\" -n addtocloud
        
        Write-Success "GCP deployment completed"
    }
    finally {
        Pop-Location
    }
}

function Test-Deployments {
    Write-Log "Verifying deployments..."
    
    if ($DeployFrontend) {
        Write-Info "Frontend deployed to Cloudflare Pages"
        switch ($Environment) {
            "production" {
                Write-Info "Frontend URL: https://addtocloud.tech"
            }
            "staging" {
                Write-Info "Frontend URL: https://staging.addtocloud.tech"
            }
            "development" {
                Write-Info "Frontend URL: Check Cloudflare Pages dashboard"
            }
        }
    }
    
    if ($DeployBackend) {
        Write-Info "Backend services status:"
        
        if ($DeployAzure -or $DeployAWS -or $DeployGCP) {
            try {
                kubectl get pods -n addtocloud 2>$null
                kubectl get services -n addtocloud 2>$null
            }
            catch {
                Write-Warning "Could not retrieve Kubernetes status"
            }
        }
    }
    
    Write-Success "Deployment verification completed"
}

function Invoke-Cleanup {
    Write-Log "Cleaning up temporary files..."
    
    # Remove Terraform plan files
    Get-ChildItem -Path "$RootDir\infrastructure\terraform" -Filter "tfplan" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
    
    # Clean up Docker
    try {
        docker system prune -f | Out-Null
    }
    catch {
        # Ignore Docker cleanup errors
    }
    
    Write-Info "Cleanup completed"
}

function Main {
    if ($Help) {
        Show-Help
    }
    
    # Set up cleanup trap
    try {
        Write-Log "🚀 Starting AddToCloud deployment..."
        Write-Info "Environment: $Environment"
        Write-Info "Frontend: $DeployFrontend"
        Write-Info "Backend: $DeployBackend (Azure: $DeployAzure, AWS: $DeployAWS, GCP: $DeployGCP)"
        
        # Execute deployment steps
        Test-Prerequisites
        Initialize-Environment
        
        # Deploy frontend to Cloudflare
        Deploy-Frontend
        
        # Deploy backend to clouds
        if ($DeployBackend) {
            Build-DockerImages
            Deploy-Azure
            Deploy-AWS
            Deploy-GCP
        }
        
        # Verify deployments
        Test-Deployments
        
        Write-Success "🎉 AddToCloud deployment completed successfully!"
        
        # Show useful information
        Write-Host ""
        Write-Info "📋 Next steps:"
        Write-Info "1. Check your domain DNS settings"
        Write-Info "2. Verify SSL certificates"
        Write-Info "3. Test all application endpoints"
        Write-Info "4. Monitor deployment health"
        
        Write-Host ""
        Write-Info "🔧 Useful commands:"
        Write-Info "  kubectl get all -n addtocloud"
        Write-Info "  kubectl logs -f deployment/addtocloud-backend -n addtocloud"
        Write-Info "  wrangler pages deployment list --project-name addtocloud-frontend"
    }
    finally {
        Invoke-Cleanup
    }
}

# Run main function
Main
