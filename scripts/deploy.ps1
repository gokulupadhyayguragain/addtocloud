#!/usr/bin/env pwsh
# AddToCloud Deployment Script
# Professional enterprise-grade deployment automation

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("aws", "azure", "gcp")]
    [string]$Cloud = "aws",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Validate = $false
)

$ErrorActionPreference = "Stop"

# Colors for output
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param($Color, $Message)
    Write-Host "${Color}${Message}${Reset}"
}

function Test-Prerequisites {
    Write-ColorOutput $Blue "🔍 Checking prerequisites..."
    
    $tools = @("kubectl", "docker", "make")
    $cloudTools = @{
        "aws" = "aws"
        "azure" = "az"
        "gcp" = "gcloud"
    }
    
    foreach ($tool in $tools) {
        if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-ColorOutput $Red "❌ $tool is not installed"
            exit 1
        }
        Write-ColorOutput $Green "✅ $tool is available"
    }
    
    $cloudTool = $cloudTools[$Cloud]
    if (!(Get-Command $cloudTool -ErrorAction SilentlyContinue)) {
        Write-ColorOutput $Red "❌ $cloudTool is not installed"
        exit 1
    }
    Write-ColorOutput $Green "✅ $cloudTool is available"
}

function Test-KustomizeConfig {
    Write-ColorOutput $Blue "🧪 Validating Kustomize configuration..."
    
    try {
        kubectl kustomize "infrastructure/kubernetes/overlays/$Environment" | Out-Null
        Write-ColorOutput $Green "✅ Kustomize configuration is valid"
    }
    catch {
        Write-ColorOutput $Red "❌ Kustomize configuration error: $_"
        exit 1
    }
}

function Build-Application {
    Write-ColorOutput $Blue "🔨 Building application..."
    
    if ($DryRun) {
        Write-ColorOutput $Yellow "🔍 DRY RUN: Would build backend and frontend images"
        return
    }
    
    try {
        make build-backend TAG="$Environment-latest"
        make build-frontend TAG="$Environment-latest"
        Write-ColorOutput $Green "✅ Application built successfully"
    }
    catch {
        Write-ColorOutput $Red "❌ Build failed: $_"
        exit 1
    }
}

function Deploy-ToCloud {
    Write-ColorOutput $Blue "🚀 Deploying to $Cloud ($Environment environment)..."
    
    if ($DryRun) {
        Write-ColorOutput $Yellow "🔍 DRY RUN: Would deploy to $Cloud"
        kubectl kustomize "infrastructure/kubernetes/overlays/$Environment"
        return
    }
    
    switch ($Cloud) {
        "aws" {
            Write-ColorOutput $Blue "🔧 Configuring AWS EKS context..."
            # AWS deployment would happen here
            kubectl apply -k "infrastructure/kubernetes/overlays/$Environment"
        }
        "azure" {
            Write-ColorOutput $Blue "🔧 Configuring Azure AKS context..."
            # Azure deployment would happen here
            kubectl apply -k "infrastructure/kubernetes/overlays/$Environment"
        }
        "gcp" {
            Write-ColorOutput $Blue "🔧 Configuring GCP GKE context..."
            # GCP deployment would happen here
            kubectl apply -k "infrastructure/kubernetes/overlays/$Environment"
        }
    }
    
    Write-ColorOutput $Green "✅ Deployment completed"
}

function Show-Status {
    Write-ColorOutput $Blue "📊 Checking deployment status..."
    
    kubectl get pods -n "addtocloud-$Environment" -l app.kubernetes.io/name=addtocloud
    kubectl get services -n "addtocloud-$Environment"
    kubectl get ingress -n "addtocloud-$Environment"
}

# Main execution
Write-ColorOutput $Blue "🎯 AddToCloud Enterprise Deployment"
Write-ColorOutput $Blue "Environment: $Environment | Cloud: $Cloud | DryRun: $DryRun"
Write-ColorOutput $Blue "================================================"

Test-Prerequisites
Test-KustomizeConfig

if ($Validate) {
    Write-ColorOutput $Green "✅ All validations passed"
    exit 0
}

Build-Application
Deploy-ToCloud
Show-Status

Write-ColorOutput $Green "🎉 Deployment completed successfully!"
Write-ColorOutput $Blue "Access your application at: https://$Environment.addtocloud.tech"
