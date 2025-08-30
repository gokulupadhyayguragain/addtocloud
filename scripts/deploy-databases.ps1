#!/usr/bin/env pwsh

# AddToCloud Database Deployment Script
# This script deploys PostgreSQL, MongoDB, and Redis using Docker Compose

param(
    [Parameter(HelpMessage="Deployment mode: docker or kubernetes")]
    [ValidateSet("docker", "kubernetes", "k8s")]
    [string]$Mode = "docker",
    
    [Parameter(HelpMessage="Action to perform")]
    [ValidateSet("start", "stop", "restart", "status", "logs", "clean")]
    [string]$Action = "start",
    
    [Parameter(HelpMessage="Specific service to target")]
    [ValidateSet("all", "postgres", "mongodb", "redis")]
    [string]$Service = "all"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 AddToCloud Database Deployment Script" -ForegroundColor Cyan
Write-Host "Mode: $Mode | Action: $Action | Service: $Service" -ForegroundColor Yellow

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

function Start-DockerDatabases {
    Write-Host "🐳 Starting databases with Docker Compose..." -ForegroundColor Green
    
    Push-Location $ProjectRoot
    try {
        # Check if Docker is running
        docker info > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Docker is not running. Please start Docker Desktop and try again."
        }
        
        # Start databases
        if ($Service -eq "all") {
            docker-compose -f docker-compose.databases.yml up -d
        } else {
            docker-compose -f docker-compose.databases.yml up -d $Service
        }
        
        Write-Host "✅ Databases started successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Database Connection Information:" -ForegroundColor Cyan
        Write-Host "PostgreSQL: localhost:5432" -ForegroundColor White
        Write-Host "  Database: addtocloud_prod" -ForegroundColor Gray
        Write-Host "  Username: addtocloud" -ForegroundColor Gray
        Write-Host "  Password: addtocloud_secure_2024" -ForegroundColor Gray
        Write-Host ""
        Write-Host "MongoDB: localhost:27017" -ForegroundColor White
        Write-Host "  Database: addtocloud_logs" -ForegroundColor Gray
        Write-Host "  Username: addtocloud" -ForegroundColor Gray
        Write-Host "  Password: addtocloud_mongo_2024" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Redis: localhost:6379" -ForegroundColor White
        Write-Host "  Password: addtocloud_redis_2024" -ForegroundColor Gray
        Write-Host ""
        Write-Host "🔧 Admin Interfaces:" -ForegroundColor Cyan
        Write-Host "pgAdmin: http://localhost:5050" -ForegroundColor White
        Write-Host "  Email: admin@addtocloud.tech" -ForegroundColor Gray
        Write-Host "  Password: addtocloud_admin_2024" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Mongo Express: http://localhost:8081" -ForegroundColor White
        Write-Host "  Username: admin" -ForegroundColor Gray
        Write-Host "  Password: addtocloud_admin_2024" -ForegroundColor Gray
        Write-Host ""
        Write-Host "RedisInsight: http://localhost:8001" -ForegroundColor White
        
    } catch {
        Write-Error "Failed to start databases: $($_.Exception.Message)"
        exit 1
    } finally {
        Pop-Location
    }
}

function Stop-DockerDatabases {
    Write-Host "🛑 Stopping databases..." -ForegroundColor Yellow
    
    Push-Location $ProjectRoot
    try {
        if ($Service -eq "all") {
            docker-compose -f docker-compose.databases.yml down
        } else {
            docker-compose -f docker-compose.databases.yml stop $Service
        }
        Write-Host "✅ Databases stopped successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to stop databases: $($_.Exception.Message)"
        exit 1
    } finally {
        Pop-Location
    }
}

function Get-DockerStatus {
    Write-Host "📊 Database Status:" -ForegroundColor Cyan
    
    Push-Location $ProjectRoot
    try {
        docker-compose -f docker-compose.databases.yml ps
    } catch {
        Write-Error "Failed to get status: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

function Get-DockerLogs {
    Write-Host "📋 Database Logs:" -ForegroundColor Cyan
    
    Push-Location $ProjectRoot
    try {
        if ($Service -eq "all") {
            docker-compose -f docker-compose.databases.yml logs -f --tail=50
        } else {
            docker-compose -f docker-compose.databases.yml logs -f --tail=50 $Service
        }
    } catch {
        Write-Error "Failed to get logs: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

function Remove-DockerDatabases {
    Write-Host "🧹 Cleaning up databases and volumes..." -ForegroundColor Red
    
    $confirmation = Read-Host "This will delete all database data. Type 'YES' to confirm"
    if ($confirmation -ne "YES") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }
    
    Push-Location $ProjectRoot
    try {
        docker-compose -f docker-compose.databases.yml down -v --remove-orphans
        Write-Host "✅ Databases and volumes removed successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to clean databases: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

function Deploy-KubernetesDatabases {
    Write-Host "☸️ Deploying databases to Kubernetes..." -ForegroundColor Green
    
    try {
        # Check if kubectl is available
        kubectl version --client > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "kubectl is not available. Please install kubectl and configure your cluster connection."
        }
        
        # Apply Kubernetes manifests
        kubectl apply -f "$ProjectRoot/infrastructure/kubernetes/databases/"
        
        Write-Host "✅ Kubernetes deployment initiated!" -ForegroundColor Green
        Write-Host "🔄 Waiting for pods to be ready..." -ForegroundColor Yellow
        
        # Wait for deployments to be ready
        kubectl wait --for=condition=ready pod -l app=postgres -n addtocloud-databases --timeout=300s
        kubectl wait --for=condition=ready pod -l app=mongodb -n addtocloud-databases --timeout=300s
        kubectl wait --for=condition=ready pod -l app=redis -n addtocloud-databases --timeout=300s
        
        Write-Host "✅ All database pods are ready!" -ForegroundColor Green
        
        # Show connection information
        Write-Host ""
        Write-Host "📋 Kubernetes Service Information:" -ForegroundColor Cyan
        kubectl get services -n addtocloud-databases
        
    } catch {
        Write-Error "Failed to deploy to Kubernetes: $($_.Exception.Message)"
        exit 1
    }
}

function Remove-KubernetesDatabases {
    Write-Host "🧹 Removing Kubernetes databases..." -ForegroundColor Red
    
    $confirmation = Read-Host "This will delete all Kubernetes database resources. Type 'YES' to confirm"
    if ($confirmation -ne "YES") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }
    
    try {
        kubectl delete namespace addtocloud-databases --ignore-not-found=true
        Write-Host "✅ Kubernetes databases removed successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to remove Kubernetes databases: $($_.Exception.Message)"
    }
}

# Main execution
switch ($Mode) {
    "docker" {
        switch ($Action) {
            "start" { Start-DockerDatabases }
            "stop" { Stop-DockerDatabases }
            "restart" { 
                Stop-DockerDatabases
                Start-Sleep -Seconds 5
                Start-DockerDatabases
            }
            "status" { Get-DockerStatus }
            "logs" { Get-DockerLogs }
            "clean" { Remove-DockerDatabases }
        }
    }
    { $_ -in @("kubernetes", "k8s") } {
        switch ($Action) {
            "start" { Deploy-KubernetesDatabases }
            "stop" { Remove-KubernetesDatabases }
            "status" { 
                kubectl get all -n addtocloud-databases 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "No Kubernetes databases found or kubectl not configured." -ForegroundColor Yellow
                }
            }
            "logs" { 
                if ($Service -eq "all") {
                    kubectl logs -n addtocloud-databases -l component=database --tail=50
                } else {
                    kubectl logs -n addtocloud-databases -l app=$Service --tail=50
                }
            }
            "clean" { Remove-KubernetesDatabases }
        }
    }
}

Write-Host ""
Write-Host "🎉 Database deployment script completed!" -ForegroundColor Green
