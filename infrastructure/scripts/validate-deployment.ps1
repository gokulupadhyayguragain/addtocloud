# AddToCloud Deployment Validation Script
# This script validates the deployment across all cloud providers

param(
    [string]$CloudProvider = "all"
)

# Color functions
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Blue }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }

Write-Info "🔍 Starting AddToCloud deployment validation..."

# Test functions
function Test-KubernetesCluster {
    param([string]$Context)
    
    Write-Info "Testing Kubernetes cluster: $Context"
    
    try {
        kubectl config use-context $Context
        $nodes = kubectl get nodes --no-headers | Measure-Object
        if ($nodes.Count -gt 0) {
            Write-Success "Cluster $Context is accessible with $($nodes.Count) nodes"
            return $true
        } else {
            Write-Error "No nodes found in cluster $Context"
            return $false
        }
    } catch {
        Write-Error "Failed to connect to cluster $Context"
        return $false
    }
}

function Test-Deployment {
    param([string]$Namespace, [string]$DeploymentName)
    
    Write-Info "Testing deployment: $DeploymentName in namespace: $Namespace"
    
    try {
        $deployment = kubectl get deployment $DeploymentName -n $Namespace -o json | ConvertFrom-Json
        $readyReplicas = $deployment.status.readyReplicas
        $replicas = $deployment.status.replicas
        
        if ($readyReplicas -eq $replicas -and $replicas -gt 0) {
            Write-Success "Deployment $DeploymentName is healthy ($readyReplicas/$replicas ready)"
            return $true
        } else {
            Write-Warning "Deployment $DeploymentName is not fully ready ($readyReplicas/$replicas ready)"
            return $false
        }
    } catch {
        Write-Error "Failed to get deployment status for $DeploymentName"
        return $false
    }
}

function Test-Service {
    param([string]$Namespace, [string]$ServiceName)
    
    Write-Info "Testing service: $ServiceName in namespace: $Namespace"
    
    try {
        $service = kubectl get service $ServiceName -n $Namespace -o json | ConvertFrom-Json
        $endpoints = kubectl get endpoints $ServiceName -n $Namespace -o json | ConvertFrom-Json
        
        if ($endpoints.subsets -and $endpoints.subsets[0].addresses) {
            Write-Success "Service $ServiceName has endpoints"
            return $true
        } else {
            Write-Warning "Service $ServiceName has no endpoints"
            return $false
        }
    } catch {
        Write-Error "Failed to get service status for $ServiceName"
        return $false
    }
}

function Test-HealthEndpoint {
    param([string]$Url)
    
    Write-Info "Testing health endpoint: $Url"
    
    try {
        $response = Invoke-RestMethod -Uri $Url -TimeoutSec 10
        if ($response.status -eq "healthy") {
            Write-Success "Health endpoint $Url is healthy"
            return $true
        } else {
            Write-Warning "Health endpoint $Url returned status: $($response.status)"
            return $false
        }
    } catch {
        Write-Error "Failed to reach health endpoint $Url"
        return $false
    }
}

function Test-Database {
    param([string]$Namespace, [string]$DatabaseType)
    
    Write-Info "Testing database: $DatabaseType"
    
    try {
        $pods = kubectl get pods -n $Namespace -l app=$DatabaseType --no-headers
        if ($pods) {
            $podName = ($pods -split '\s+')[0]
            $status = kubectl get pod $podName -n $Namespace -o jsonpath='{.status.phase}'
            
            if ($status -eq "Running") {
                Write-Success "Database $DatabaseType is running"
                return $true
            } else {
                Write-Warning "Database $DatabaseType is in status: $status"
                return $false
            }
        } else {
            Write-Error "No pods found for database $DatabaseType"
            return $false
        }
    } catch {
        Write-Error "Failed to check database $DatabaseType"
        return $false
    }
}

function Test-Ingress {
    param([string]$Namespace, [string]$IngressName)
    
    Write-Info "Testing ingress: $IngressName"
    
    try {
        $ingress = kubectl get ingress $IngressName -n $Namespace -o json | ConvertFrom-Json
        if ($ingress.status.loadBalancer.ingress) {
            $ip = $ingress.status.loadBalancer.ingress[0].ip
            Write-Success "Ingress $IngressName has IP: $ip"
            return $true
        } else {
            Write-Warning "Ingress $IngressName has no external IP"
            return $false
        }
    } catch {
        Write-Error "Failed to get ingress status for $IngressName"
        return $false
    }
}

function Test-CloudProvider {
    param([string]$Provider, [string]$Context)
    
    Write-Info "🌐 Validating $Provider deployment..."
    
    $results = @{
        cluster = Test-KubernetesCluster -Context $Context
        frontend = $false
        backend = $false
        databases = @{}
        services = @{}
        ingress = $false
        health = $false
    }
    
    if ($results.cluster) {
        # Test deployments
        $results.frontend = Test-Deployment -Namespace "addtocloud" -DeploymentName "addtocloud-frontend"
        $results.backend = Test-Deployment -Namespace "addtocloud" -DeploymentName "addtocloud-backend"
        
        # Test databases
        $results.databases.postgres = Test-Database -Namespace "addtocloud" -DatabaseType "postgres"
        $results.databases.mongodb = Test-Database -Namespace "addtocloud" -DatabaseType "mongodb"
        $results.databases.redis = Test-Database -Namespace "addtocloud" -DatabaseType "redis"
        
        # Test services
        $results.services.frontend = Test-Service -Namespace "addtocloud" -ServiceName "addtocloud-frontend"
        $results.services.backend = Test-Service -Namespace "addtocloud" -ServiceName "addtocloud-backend"
        
        # Test ingress
        $results.ingress = Test-Ingress -Namespace "addtocloud" -IngressName "addtocloud-ingress"
        
        # Test health endpoints (if ingress is working)
        if ($results.ingress) {
            $results.health = Test-HealthEndpoint -Url "https://api.addtocloud.tech/health"
        }
    }
    
    return $results
}

function Show-ValidationSummary {
    param([hashtable]$Results)
    
    Write-Host ""
    Write-Host "📊 Validation Summary:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    foreach ($provider in $Results.Keys) {
        Write-Host ""
        Write-Host "🌐 $($provider.ToUpper()):" -ForegroundColor Yellow
        $result = $Results[$provider]
        
        # Overall status
        $healthyCount = 0
        $totalChecks = 0
        
        # Cluster
        $totalChecks++
        if ($result.cluster) { 
            Write-Host "  ✅ Cluster: Accessible" -ForegroundColor Green
            $healthyCount++
        } else { 
            Write-Host "  ❌ Cluster: Not accessible" -ForegroundColor Red
        }
        
        # Frontend
        $totalChecks++
        if ($result.frontend) { 
            Write-Host "  ✅ Frontend: Healthy" -ForegroundColor Green
            $healthyCount++
        } else { 
            Write-Host "  ❌ Frontend: Unhealthy" -ForegroundColor Red
        }
        
        # Backend
        $totalChecks++
        if ($result.backend) { 
            Write-Host "  ✅ Backend: Healthy" -ForegroundColor Green
            $healthyCount++
        } else { 
            Write-Host "  ❌ Backend: Unhealthy" -ForegroundColor Red
        }
        
        # Databases
        foreach ($db in $result.databases.Keys) {
            $totalChecks++
            if ($result.databases[$db]) { 
                Write-Host "  ✅ Database ($db): Running" -ForegroundColor Green
                $healthyCount++
            } else { 
                Write-Host "  ❌ Database ($db): Not running" -ForegroundColor Red
            }
        }
        
        # Services
        foreach ($svc in $result.services.Keys) {
            $totalChecks++
            if ($result.services[$svc]) { 
                Write-Host "  ✅ Service ($svc): Available" -ForegroundColor Green
                $healthyCount++
            } else { 
                Write-Host "  ❌ Service ($svc): Unavailable" -ForegroundColor Red
            }
        }
        
        # Ingress
        $totalChecks++
        if ($result.ingress) { 
            Write-Host "  ✅ Ingress: Configured" -ForegroundColor Green
            $healthyCount++
        } else { 
            Write-Host "  ❌ Ingress: Not configured" -ForegroundColor Red
        }
        
        # Health endpoint
        if ($result.ContainsKey('health')) {
            $totalChecks++
            if ($result.health) { 
                Write-Host "  ✅ Health Check: Passing" -ForegroundColor Green
                $healthyCount++
            } else { 
                Write-Host "  ❌ Health Check: Failing" -ForegroundColor Red
            }
        }
        
        # Score
        $percentage = [math]::Round(($healthyCount / $totalChecks) * 100, 1)
        Write-Host "  📈 Score: $healthyCount/$totalChecks ($percentage%)" -ForegroundColor Cyan
    }
}

# Main execution
$validationResults = @{}

switch ($CloudProvider.ToLower()) {
    "azure" {
        $validationResults["azure"] = Test-CloudProvider -Provider "Azure AKS" -Context "azure-aks"
    }
    "aws" {
        $validationResults["aws"] = Test-CloudProvider -Provider "AWS EKS" -Context "aws-eks"
    }
    "gcp" {
        $validationResults["gcp"] = Test-CloudProvider -Provider "GCP GKE" -Context "gcp-gke"
    }
    "all" {
        $validationResults["azure"] = Test-CloudProvider -Provider "Azure AKS" -Context "azure-aks"
        $validationResults["aws"] = Test-CloudProvider -Provider "AWS EKS" -Context "aws-eks"
        $validationResults["gcp"] = Test-CloudProvider -Provider "GCP GKE" -Context "gcp-gke"
    }
    default {
        Write-Error "Invalid cloud provider. Use: azure, aws, gcp, or all"
        exit 1
    }
}

Show-ValidationSummary -Results $validationResults

Write-Host ""
Write-Host "🎯 Validation completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Fix any failing components" -ForegroundColor White
Write-Host "2. Monitor application performance" -ForegroundColor White
Write-Host "3. Set up monitoring dashboards" -ForegroundColor White
Write-Host "4. Configure backup strategies" -ForegroundColor White
