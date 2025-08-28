# =============================================================================
# AddToCloud Complete Infrastructure Deployment Script (PowerShell)
# =============================================================================
# This script automates the complete deployment of AddToCloud platform
# across Azure AKS, AWS EKS, and GCP GKE clusters

param(
    [switch]$SkipAzure,
    [switch]$SkipAWS,
    [switch]$SkipGCP,
    [switch]$OnlyK8s,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Configuration
$ProjectName = "addtocloud"
$Environment = "production"
$Namespace = "addtocloud"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir

# Cloud providers to deploy
$DeployAzure = -not $SkipAzure -and -not $OnlyK8s
$DeployAWS = -not $SkipAWS -and -not $OnlyK8s
$DeployGCP = -not $SkipGCP -and -not $OnlyK8s

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
}

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor $Colors.Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red
    exit 1
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Blue
}

function Show-Help {
    Write-Host "AddToCloud Infrastructure Deployment Script" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "Usage: .\deploy-all.ps1 [OPTIONS]" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "Options:" -ForegroundColor $Colors.Blue
    Write-Host "  -SkipAzure    Skip Azure AKS deployment"
    Write-Host "  -SkipAWS      Skip AWS EKS deployment"
    Write-Host "  -SkipGCP      Skip GCP GKE deployment"
    Write-Host "  -OnlyK8s      Only deploy Kubernetes resources (skip cloud infrastructure)"
    Write-Host "  -Help         Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor $Colors.Blue
    Write-Host "  .\deploy-all.ps1                    # Deploy to all clouds"
    Write-Host "  .\deploy-all.ps1 -SkipAzure         # Skip Azure deployment"
    Write-Host "  .\deploy-all.ps1 -OnlyK8s           # Only deploy Kubernetes resources"
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
    $tools = @("kubectl", "helm", "terraform", "docker")
    
    # Cloud CLI tools
    if ($DeployAzure) { $tools += "az" }
    if ($DeployAWS) { $tools += "aws" }
    if ($DeployGCP) { $tools += "gcloud" }
    
    foreach ($tool in $tools) {
        if (Test-CommandExists $tool) {
            Write-Info "✓ $tool is installed"
        }
        else {
            Write-Error "$tool is not installed. Please install it first."
        }
    }
    
    # Check Terraform version
    try {
        $tfVersion = (terraform version -json | ConvertFrom-Json).terraform_version
        Write-Info "✓ Terraform version: $tfVersion"
    }
    catch {
        Write-Warning "Could not determine Terraform version"
    }
    
    # Check kubectl
    try {
        kubectl version --client | Out-Null
        Write-Info "✓ kubectl is working"
    }
    catch {
        Write-Warning "kubectl might not be properly configured"
    }
}

function Initialize-Environment {
    Write-Log "Setting up environment..."
    
    # Create necessary directories
    $dirs = @(
        "$RootDir\infrastructure\terraform\states",
        "$RootDir\secrets",
        "$RootDir\logs"
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # Check if .env file exists
    $envFile = "$RootDir\.env"
    if (-not (Test-Path $envFile)) {
        Write-Warning ".env file not found. Creating from template..."
        $envExample = "$RootDir\.env.example"
        if (Test-Path $envExample) {
            Copy-Item $envExample $envFile
            Write-Warning "Please update .env file with your actual values"
        }
        else {
            Write-Error ".env.example file not found. Cannot create .env file."
        }
    }
    
    # Load environment variables
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
            }
        }
        Write-Info "✓ Environment variables loaded"
    }
}

function New-Secrets {
    Write-Log "Generating application secrets..."
    
    $secretsFile = "$RootDir\secrets\generated-secrets.env"
    
    # Function to generate random string
    function Get-RandomString {
        param([int]$Length = 32)
        $bytes = New-Object byte[] $Length
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        return [Convert]::ToBase64String($bytes).Replace('+', '-').Replace('/', '_').Substring(0, $Length)
    }
    
    # Generate secrets
    $jwtSecret = Get-RandomString 64
    $jwtRefreshSecret = Get-RandomString 64
    $sessionSecret = Get-RandomString 64
    $encryptionKey = Get-RandomString 64
    $apiSecret = Get-RandomString 64
    $dbPassword = Get-RandomString 20
    $redisPassword = Get-RandomString 16
    $webhookSecret = Get-RandomString 32
    $githubWebhookSecret = Get-RandomString 32
    $appSecretKey = Get-RandomString 64
    $csrfSecretKey = Get-RandomString 32
    
    # Create secrets file
    $secretsContent = @"
# Generated secrets for AddToCloud platform
# Generated on: $(Get-Date)

# JWT and Session Secrets
JWT_SECRET=$jwtSecret
JWT_REFRESH_SECRET=$jwtRefreshSecret
SESSION_SECRET=$sessionSecret

# Encryption Keys
ENCRYPTION_KEY=$encryptionKey
API_SECRET_KEY=$apiSecret

# Database Passwords
POSTGRES_PASSWORD=$dbPassword
REDIS_PASSWORD=$redisPassword

# Webhook Secrets
WEBHOOK_SECRET=$webhookSecret
GITHUB_WEBHOOK_SECRET=$githubWebhookSecret

# Application Keys
APP_SECRET_KEY=$appSecretKey
CSRF_SECRET_KEY=$csrfSecretKey
"@
    
    Set-Content -Path $secretsFile -Value $secretsContent
    
    # Set file permissions (Windows equivalent)
    $acl = Get-Acl $secretsFile
    $acl.SetAccessRuleProtection($true, $false)
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
        "FullControl",
        "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $secretsFile -AclObject $acl
    
    Write-Info "✓ Secrets generated and saved to $secretsFile"
    
    # Load the generated secrets
    Get-Content $secretsFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
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
        # Check if terraform.tfvars exists
        if (-not (Test-Path "terraform.tfvars")) {
            Write-Warning "terraform.tfvars not found in Azure directory"
            if (Test-Path "..\terraform.tfvars.example") {
                Copy-Item "..\terraform.tfvars.example" "terraform.tfvars"
                Write-Warning "Please update terraform.tfvars with your Azure credentials"
                return
            }
        }
        
        # Initialize Terraform
        terraform init -backend-config="key=azure-$Environment.tfstate"
        
        # Plan deployment
        terraform plan -out=tfplan
        
        # Apply deployment
        terraform apply tfplan
        
        # Get AKS credentials
        $resourceGroup = terraform output -raw resource_group_name
        $clusterName = terraform output -raw cluster_name
        
        az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing
        
        Write-Info "✓ Azure AKS cluster deployed and configured"
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
        # Check if terraform.tfvars exists
        if (-not (Test-Path "terraform.tfvars")) {
            Write-Warning "terraform.tfvars not found in AWS directory"
            if (Test-Path "..\terraform.tfvars.example") {
                Copy-Item "..\terraform.tfvars.example" "terraform.tfvars"
                Write-Warning "Please update terraform.tfvars with your AWS credentials"
                return
            }
        }
        
        # Initialize Terraform
        terraform init -backend-config="key=aws-$Environment.tfstate"
        
        # Plan deployment
        terraform plan -out=tfplan
        
        # Apply deployment
        terraform apply tfplan
        
        # Get EKS credentials
        $clusterName = terraform output -raw cluster_name
        $region = terraform output -raw region
        
        aws eks update-kubeconfig --region $region --name $clusterName
        
        Write-Info "✓ AWS EKS cluster deployed and configured"
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
        # Check if terraform.tfvars exists
        if (-not (Test-Path "terraform.tfvars")) {
            Write-Warning "terraform.tfvars not found in GCP directory"
            if (Test-Path "..\terraform.tfvars.example") {
                Copy-Item "..\terraform.tfvars.example" "terraform.tfvars"
                Write-Warning "Please update terraform.tfvars with your GCP credentials"
                return
            }
        }
        
        # Initialize Terraform
        terraform init -backend-config="prefix=gcp-$Environment"
        
        # Plan deployment
        terraform plan -out=tfplan
        
        # Apply deployment
        terraform apply tfplan
        
        # Get GKE credentials
        $clusterName = terraform output -raw cluster_name
        $zone = terraform output -raw zone
        $projectId = terraform output -raw project_id
        
        gcloud container clusters get-credentials $clusterName --zone $zone --project $projectId
        
        Write-Info "✓ GCP GKE cluster deployed and configured"
    }
    finally {
        Pop-Location
    }
}

function Install-Istio {
    Write-Log "Installing Istio service mesh..."
    
    # Check if Istio is already installed
    try {
        kubectl get namespace istio-system | Out-Null
        $pods = kubectl get pods -n istio-system --no-headers 2>$null
        if ($pods -match "istiod") {
            Write-Info "✓ Istio is already installed"
            return
        }
    }
    catch {
        # Namespace doesn't exist, continue with installation
    }
    
    # Download and install Istio
    $istioVersion = $env:ISTIO_VERSION
    if (-not $istioVersion) { $istioVersion = "1.20.0" }
    
    # Download Istio for Windows
    $istioUrl = "https://github.com/istio/istio/releases/download/$istioVersion/istio-$istioVersion-win.zip"
    $istioZip = "$env:TEMP\istio-$istioVersion-win.zip"
    $istioDir = "$RootDir\istio-$istioVersion"
    
    Write-Info "Downloading Istio $istioVersion..."
    Invoke-WebRequest -Uri $istioUrl -OutFile $istioZip
    
    Write-Info "Extracting Istio..."
    Expand-Archive -Path $istioZip -DestinationPath $RootDir -Force
    
    # Add istioctl to PATH temporarily
    $env:PATH = "$istioDir\bin;$env:PATH"
    
    # Install Istio
    & "$istioDir\bin\istioctl.exe" install --set values.defaultRevision=default -y
    
    # Enable sidecar injection for addtocloud namespace
    kubectl label namespace $Namespace istio-injection=enabled --overwrite
    
    Write-Info "✓ Istio service mesh installed"
}

function Deploy-Kubernetes {
    Write-Log "Deploying Kubernetes resources..."
    
    Push-Location $RootDir
    
    try {
        # Create namespace
        kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
        
        # Create secrets from generated secrets file
        $secretsFile = "$RootDir\secrets\generated-secrets.env"
        if (Test-Path $secretsFile) {
            kubectl create secret generic app-secrets --from-env-file="$secretsFile" --namespace="$Namespace" --dry-run=client -o yaml | kubectl apply -f -
            Write-Info "✓ Application secrets created in Kubernetes"
        }
        
        # Deploy database services
        if (Test-Path "infrastructure\kubernetes\deployments\postgres.yaml") {
            kubectl apply -f infrastructure\kubernetes\deployments\postgres.yaml -n $Namespace
            Write-Info "✓ PostgreSQL deployed"
        }
        
        if (Test-Path "infrastructure\kubernetes\deployments\redis.yaml") {
            kubectl apply -f infrastructure\kubernetes\deployments\redis.yaml -n $Namespace
            Write-Info "✓ Redis deployed"
        }
        
        # Deploy monitoring stack
        if (Test-Path "infrastructure\kubernetes\deployments\monitoring.yaml") {
            kubectl apply -f infrastructure\kubernetes\deployments\monitoring.yaml -n $Namespace
            Write-Info "✓ Monitoring stack deployed"
        }
        
        # Deploy application
        if (Test-Path "infrastructure\kubernetes\deployments\app.yaml") {
            kubectl apply -f infrastructure\kubernetes\deployments\app.yaml -n $Namespace
            Write-Info "✓ Application deployed"
        }
        
        # Deploy Istio configurations
        if (Test-Path "infrastructure\istio") {
            kubectl apply -f infrastructure\istio\ -n $Namespace
            Write-Info "✓ Istio configurations applied"
        }
    }
    finally {
        Pop-Location
    }
}

function Build-AndPushImages {
    Write-Log "Building and pushing Docker images..."
    
    Push-Location $RootDir
    
    try {
        # Get registry information from Terraform outputs
        $registryUrl = ""
        $imageTag = "latest"
        
        # Determine which registry to use based on deployed cloud
        if ($DeployAWS) {
            try {
                Push-Location "infrastructure\terraform\aws"
                $registryUrl = terraform output -raw ecr_registry_url 2>$null
                Pop-Location
            }
            catch { Pop-Location }
        }
        elseif ($DeployAzure) {
            try {
                Push-Location "infrastructure\terraform\azure"
                $registryUrl = terraform output -raw acr_login_server 2>$null
                Pop-Location
            }
            catch { Pop-Location }
        }
        elseif ($DeployGCP) {
            try {
                Push-Location "infrastructure\terraform\gcp"
                $registryUrl = terraform output -raw artifact_registry_url 2>$null
                Pop-Location
            }
            catch { Pop-Location }
        }
        
        if ($registryUrl) {
            # Build and push backend image
            docker build -t "$registryUrl/${ProjectName}-backend:$imageTag" -f infrastructure\docker\Dockerfile.backend .
            docker push "$registryUrl/${ProjectName}-backend:$imageTag"
            
            # Build and push frontend image
            docker build -t "$registryUrl/${ProjectName}-frontend:$imageTag" -f infrastructure\docker\Dockerfile.frontend .
            docker push "$registryUrl/${ProjectName}-frontend:$imageTag"
            
            Write-Info "✓ Docker images built and pushed to $registryUrl"
        }
        else {
            Write-Warning "No container registry found. Skipping image push."
        }
    }
    finally {
        Pop-Location
    }
}

function Test-Deployment {
    Write-Log "Verifying deployment..."
    
    # Check if pods are running
    $retries = 30
    $count = 0
    
    while ($count -lt $retries) {
        try {
            $pods = kubectl get pods -n $Namespace --no-headers 2>$null
            $runningPods = ($pods | Where-Object { $_ -match "Running" }).Count
            $totalPods = $pods.Count
            
            if ($runningPods -eq $totalPods -and $totalPods -gt 0) {
                Write-Info "✓ All pods are running ($runningPods/$totalPods)"
                break
            }
            else {
                Write-Info "Waiting for pods to be ready ($runningPods/$totalPods)..."
                Start-Sleep 10
                $count++
            }
        }
        catch {
            Write-Info "Waiting for namespace to be ready..."
            Start-Sleep 10
            $count++
        }
    }
    
    if ($count -eq $retries) {
        Write-Warning "Some pods might not be ready. Please check manually."
    }
    
    # Show deployment status
    kubectl get all -n $Namespace
    
    # Get service URLs
    try {
        kubectl get service -n $Namespace 2>$null | Out-Null
        Write-Info "Service endpoints:"
        kubectl get service -n $Namespace -o wide
    }
    catch {
        Write-Info "No services found yet"
    }
    
    # Get Istio gateway information
    try {
        kubectl get gateway -n $Namespace 2>$null | Out-Null
        Write-Info "Istio gateway configuration:"
        kubectl get gateway -n $Namespace -o wide
    }
    catch {
        Write-Info "No Istio gateways found yet"
    }
}

function Invoke-Cleanup {
    Write-Log "Cleaning up temporary files..."
    
    # Remove Terraform plan files
    Get-ChildItem -Path "$RootDir\infrastructure\terraform" -Filter "tfplan" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
    
    # Remove temporary Istio installation
    if (Test-Path "$RootDir\istio-*") {
        Remove-Item -Path "$RootDir\istio-*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Main {
    if ($Help) {
        Show-Help
    }
    
    Write-Log "Starting AddToCloud infrastructure deployment..."
    
    # Set up cleanup trap
    try {
        # Execute deployment steps
        Test-Prerequisites
        Initialize-Environment
        New-Secrets
        
        # Deploy cloud infrastructure
        Deploy-Azure
        Deploy-AWS
        Deploy-GCP
        
        # Install service mesh and deploy applications
        Install-Istio
        Build-AndPushImages
        Deploy-Kubernetes
        Test-Deployment
        
        Write-Log "🎉 AddToCloud deployment completed successfully!"
        
        Write-Info "Next steps:"
        Write-Info "1. Update your DNS settings to point to the load balancer"
        Write-Info "2. Configure SSL certificates"
        Write-Info "3. Set up monitoring alerts"
        Write-Info "4. Test all application endpoints"
        
        Write-Info "Useful commands:"
        Write-Info "  kubectl get all -n $Namespace"
        Write-Info "  kubectl logs -f deployment/addtocloud-backend -n $Namespace"
        Write-Info "  kubectl logs -f deployment/addtocloud-frontend -n $Namespace"
        Write-Info "  istioctl proxy-status"
    }
    finally {
        Invoke-Cleanup
    }
}

# Run main function
Main
