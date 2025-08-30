#!/usr/bin/env powershell

# AddToCloud EC2 Deployment Script for Windows
# This script deploys EC2 instances for the AddToCloud platform

param(
    [string]$Action = "plan",
    [string]$Environment = "production",
    [switch]$AutoApprove,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
AddToCloud EC2 Deployment Script

Usage:
    .\deploy-ec2.ps1 -Action <plan|apply|destroy> [-Environment <env>] [-AutoApprove]

Parameters:
    -Action        : Terraform action (plan, apply, destroy)
    -Environment   : Environment name (default: production)
    -AutoApprove   : Skip confirmation prompts
    -Help          : Show this help message

Examples:
    .\deploy-ec2.ps1 -Action plan
    .\deploy-ec2.ps1 -Action apply -AutoApprove
    .\deploy-ec2.ps1 -Action destroy -Environment staging

Prerequisites:
    1. Install Terraform: https://www.terraform.io/downloads
    2. Install AWS CLI: https://aws.amazon.com/cli/
    3. Configure AWS credentials: aws configure
    4. Generate SSH key pair for EC2 access
"@
    exit 0
}

# Configuration
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TerraformDir = Join-Path $ProjectRoot "infrastructure\terraform\aws"
$TfVarsFile = Join-Path $TerraformDir "terraform.tfvars"
$ExampleVarsFile = Join-Path $TerraformDir "terraform.tfvars.example"

Write-Host "🚀 AddToCloud EC2 Deployment Script" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host ""

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Green

# Check Terraform
try {
    $terraformVersion = terraform version -json | ConvertFrom-Json
    Write-Host "✅ Terraform found: $($terraformVersion.terraform_version)" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform not found. Please install Terraform first." -ForegroundColor Red
    exit 1
}

# Check AWS CLI
try {
    $awsVersion = aws --version 2>&1
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Check AWS credentials
try {
    $awsIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✅ AWS credentials configured for account: $($awsIdentity.Account)" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Change to Terraform directory
Set-Location $TerraformDir

# Check if terraform.tfvars exists
if (-not (Test-Path $TfVarsFile)) {
    Write-Host "⚠️ terraform.tfvars not found. Creating from example..." -ForegroundColor Yellow
    
    if (Test-Path $ExampleVarsFile) {
        Copy-Item $ExampleVarsFile $TfVarsFile
        Write-Host "📝 Created terraform.tfvars from example." -ForegroundColor Green
        Write-Host "🔧 Please edit terraform.tfvars and add your SSH public key before proceeding." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To generate an SSH key pair:" -ForegroundColor Cyan
        Write-Host "ssh-keygen -t rsa -b 4096 -f ~/.ssh/addtocloud-production-key" -ForegroundColor White
        Write-Host ""
        notepad $TfVarsFile
        Read-Host "Press Enter after updating terraform.tfvars"
    } else {
        Write-Host "❌ terraform.tfvars.example not found." -ForegroundColor Red
        exit 1
    }
}

# Initialize Terraform
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Green
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform initialization failed." -ForegroundColor Red
    exit 1
}

# Format Terraform files
Write-Host "📋 Formatting Terraform files..." -ForegroundColor Green
terraform fmt

# Validate Terraform configuration
Write-Host "✅ Validating Terraform configuration..." -ForegroundColor Green
terraform validate

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform validation failed." -ForegroundColor Red
    exit 1
}

# Execute Terraform action
switch ($Action.ToLower()) {
    "plan" {
        Write-Host "📊 Creating Terraform plan..." -ForegroundColor Green
        terraform plan -var-file="terraform.tfvars"
    }
    
    "apply" {
        Write-Host "🚀 Applying Terraform configuration..." -ForegroundColor Green
        
        if ($AutoApprove) {
            terraform apply -var-file="terraform.tfvars" -auto-approve
        } else {
            terraform apply -var-file="terraform.tfvars"
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "🎉 EC2 deployment completed successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "📋 Deployment Information:" -ForegroundColor Cyan
            terraform output
            Write-Host ""
            Write-Host "🔑 SSH Key Management:" -ForegroundColor Yellow
            Write-Host "Make sure your SSH private key has correct permissions:" -ForegroundColor White
            Write-Host "icacls ~/.ssh/addtocloud-production-key /inheritance:r /grant:r `"$env:USERNAME`":(R)" -ForegroundColor Gray
            Write-Host ""
            Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
            Write-Host "1. SSH into your instances and run the deployment script" -ForegroundColor White
            Write-Host "2. Configure your domain DNS to point to the load balancer" -ForegroundColor White
            Write-Host "3. Set up SSL certificates for HTTPS" -ForegroundColor White
        }
    }
    
    "destroy" {
        Write-Host "⚠️ Destroying Terraform-managed infrastructure..." -ForegroundColor Red
        Write-Host "This will permanently delete all EC2 instances and associated resources!" -ForegroundColor Red
        
        if (-not $AutoApprove) {
            $confirmation = Read-Host "Are you sure you want to destroy all resources? (yes/no)"
            if ($confirmation -ne "yes") {
                Write-Host "❌ Destruction cancelled." -ForegroundColor Yellow
                exit 0
            }
        }
        
        if ($AutoApprove) {
            terraform destroy -var-file="terraform.tfvars" -auto-approve
        } else {
            terraform destroy -var-file="terraform.tfvars"
        }
    }
    
    default {
        Write-Host "❌ Invalid action: $Action" -ForegroundColor Red
        Write-Host "Valid actions: plan, apply, destroy" -ForegroundColor Yellow
        exit 1
    }
}

# Return to original directory
Set-Location $ProjectRoot

Write-Host ""
Write-Host "✅ Script completed." -ForegroundColor Green
