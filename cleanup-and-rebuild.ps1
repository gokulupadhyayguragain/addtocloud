#!/usr/bin/env pwsh
# AddToCloud Complete System Cleanup and Rebuild Script

Write-Host "=== AddToCloud System Cleanup and Rebuild ===" -ForegroundColor Blue
Write-Host ""

# Set error handling
$ErrorActionPreference = "Continue"

Write-Host "1. Cleaning up duplicate and problematic deployments..." -ForegroundColor Yellow

# Delete problematic deployments in default namespace
$defaultDeployments = @(
    "addtocloud-api",
    "addtocloud-backend-full", 
    "addtocloud-email-micro",
    "addtocloud-email-service",
    "addtocloud-email-simple",
    "addtocloud-final-api",
    "addtocloud-website",
    "postgres"
)

foreach ($deployment in $defaultDeployments) {
    try {
        kubectl delete deployment $deployment -n default --ignore-not-found=true
        Write-Host "   Deleted deployment: $deployment" -ForegroundColor Green
    } catch {
        Write-Host "   Failed to delete $deployment : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Delete problematic deployments in addtocloud namespace
$addtocloudDeployments = @(
    "addtocloud-backend",
    "addtocloud-frontend"
)

foreach ($deployment in $addtocloudDeployments) {
    try {
        kubectl delete deployment $deployment -n addtocloud --ignore-not-found=true
        Write-Host "   Deleted deployment: $deployment in addtocloud namespace" -ForegroundColor Green
    } catch {
        Write-Host "   Failed to delete $deployment : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "2. Cleaning up services..." -ForegroundColor Yellow

# Delete problematic services
$services = @(
    "addtocloud-backend-full",
    "addtocloud-email-micro-service", 
    "addtocloud-email-service",
    "addtocloud-email-simple-service",
    "addtocloud-final-api-service"
)

foreach ($service in $services) {
    try {
        kubectl delete service $service -n default --ignore-not-found=true
        Write-Host "   Deleted service: $service" -ForegroundColor Green
    } catch {
        Write-Host "   Failed to delete service $service : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "3. Cleaning up configmaps and secrets..." -ForegroundColor Yellow

try {
    kubectl delete configmap email-nginx-config email-html-config -n default --ignore-not-found=true
    Write-Host "   Deleted email configmaps" -ForegroundColor Green
} catch {
    Write-Host "   Failed to delete configmaps: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "4. Checking remaining resources..." -ForegroundColor Yellow

Write-Host "   Active deployments:" -ForegroundColor Cyan
kubectl get deployments -A | Where-Object { $_ -match "addtocloud|postgres" }

Write-Host "   Active services:" -ForegroundColor Cyan  
kubectl get services -A | Where-Object { $_ -match "addtocloud|postgres" }

Write-Host "   Active pods:" -ForegroundColor Cyan
kubectl get pods -A | Where-Object { $_ -match "addtocloud|postgres" }

Write-Host ""
Write-Host "5. Cleanup completed!" -ForegroundColor Green
Write-Host "   Ready to deploy clean infrastructure..." -ForegroundColor Cyan
