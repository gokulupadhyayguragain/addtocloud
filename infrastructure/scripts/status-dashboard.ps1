# AddToCloud Deployment Status Dashboard
# Real-time monitoring of multi-cloud deployment status

param(
    [string]$CloudProvider = "all",
    [switch]$Continuous = $false,
    [int]$RefreshInterval = 30
)

# Color functions
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ️ $Message" -ForegroundColor Blue }
function Write-Warning { param([string]$Message) Write-Host "⚠️ $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }

function Get-ClusterStatus {
    param([string]$Context)
    
    try {
        kubectl config use-context $Context | Out-Null
        $nodes = kubectl get nodes --no-headers 2>$null
        if ($nodes) {
            return @{
                Status = "Healthy"
                NodeCount = ($nodes | Measure-Object).Count
                Details = "Cluster accessible"
            }
        } else {
            return @{
                Status = "Error"
                NodeCount = 0
                Details = "No nodes found"
            }
        }
    } catch {
        return @{
            Status = "Error"
            NodeCount = 0
            Details = "Cannot connect to cluster"
        }
    }
}

function Get-DeploymentStatus {
    param([string]$Namespace, [string]$DeploymentName)
    
    try {
        $deployment = kubectl get deployment $DeploymentName -n $Namespace -o json 2>$null | ConvertFrom-Json
        if ($deployment) {
            $ready = if ($deployment.status.readyReplicas) { $deployment.status.readyReplicas } else { 0 }
            $desired = if ($deployment.status.replicas) { $deployment.status.replicas } else { 0 }
            
            return @{
                Status = if ($ready -eq $desired -and $desired -gt 0) { "Healthy" } else { "Warning" }
                Ready = $ready
                Desired = $desired
                Details = "$ready/$desired pods ready"
            }
        } else {
            return @{
                Status = "Error"
                Ready = 0
                Desired = 0
                Details = "Deployment not found"
            }
        }
    } catch {
        return @{
            Status = "Error"
            Ready = 0
            Desired = 0
            Details = "Cannot get deployment status"
        }
    }
}

function Get-ServiceStatus {
    param([string]$Namespace, [string]$ServiceName)
    
    try {
        $service = kubectl get service $ServiceName -n $Namespace -o json 2>$null | ConvertFrom-Json
        $endpoints = kubectl get endpoints $ServiceName -n $Namespace -o json 2>$null | ConvertFrom-Json
        
        if ($service -and $endpoints -and $endpoints.subsets -and $endpoints.subsets[0].addresses) {
            return @{
                Status = "Healthy"
                Type = $service.spec.type
                Endpoints = $endpoints.subsets[0].addresses.Count
                Details = "$($endpoints.subsets[0].addresses.Count) endpoints available"
            }
        } else {
            return @{
                Status = "Warning"
                Type = if ($service) { $service.spec.type } else { "Unknown" }
                Endpoints = 0
                Details = "No endpoints available"
            }
        }
    } catch {
        return @{
            Status = "Error"
            Type = "Unknown"
            Endpoints = 0
            Details = "Cannot get service status"
        }
    }
}

function Get-IngressStatus {
    param([string]$Namespace, [string]$IngressName)
    
    try {
        $ingress = kubectl get ingress $IngressName -n $Namespace -o json 2>$null | ConvertFrom-Json
        
        if ($ingress -and $ingress.status.loadBalancer.ingress) {
            $ip = $ingress.status.loadBalancer.ingress[0].ip
            $hostname = $ingress.status.loadBalancer.ingress[0].hostname
            
            return @{
                Status = "Healthy"
                IP = if ($ip) { $ip } else { $hostname }
                Details = "External access configured"
            }
        } else {
            return @{
                Status = "Warning"
                IP = "Pending"
                Details = "Waiting for external IP"
            }
        }
    } catch {
        return @{
            Status = "Error"
            IP = "Unknown"
            Details = "Cannot get ingress status"
        }
    }
}

function Get-PVCStatus {
    param([string]$Namespace)
    
    try {
        $pvcs = kubectl get pvc -n $Namespace -o json 2>$null | ConvertFrom-Json
        
        if ($pvcs -and $pvcs.items) {
            $bound = ($pvcs.items | Where-Object { $_.status.phase -eq "Bound" }).Count
            $total = $pvcs.items.Count
            
            return @{
                Status = if ($bound -eq $total) { "Healthy" } else { "Warning" }
                Bound = $bound
                Total = $total
                Details = "$bound/$total PVCs bound"
            }
        } else {
            return @{
                Status = "Info"
                Bound = 0
                Total = 0
                Details = "No PVCs found"
            }
        }
    } catch {
        return @{
            Status = "Error"
            Bound = 0
            Total = 0
            Details = "Cannot get PVC status"
        }
    }
}

function Get-ResourceUsage {
    param([string]$Namespace)
    
    try {
        $pods = kubectl get pods -n $Namespace -o json 2>$null | ConvertFrom-Json
        
        if ($pods -and $pods.items) {
            $running = ($pods.items | Where-Object { $_.status.phase -eq "Running" }).Count
            $total = $pods.items.Count
            $restarts = ($pods.items | ForEach-Object { $_.status.containerStatuses | ForEach-Object { $_.restartCount } } | Measure-Object -Sum).Sum
            
            return @{
                Status = if ($running -eq $total -and $restarts -eq 0) { "Healthy" } elseif ($running -eq $total) { "Warning" } else { "Error" }
                RunningPods = $running
                TotalPods = $total
                Restarts = $restarts
                Details = "$running/$total pods running, $restarts restarts"
            }
        } else {
            return @{
                Status = "Info"
                RunningPods = 0
                TotalPods = 0
                Restarts = 0
                Details = "No pods found"
            }
        }
    } catch {
        return @{
            Status = "Error"
            RunningPods = 0
            TotalPods = 0
            Restarts = 0
            Details = "Cannot get resource usage"
        }
    }
}

function Show-ProviderStatus {
    param([string]$Provider, [string]$Context)
    
    Write-Host ""
    Write-Host "🌐 $Provider" -ForegroundColor Yellow
    Write-Host "=" * ($Provider.Length + 3) -ForegroundColor Yellow
    
    # Get all status information
    $cluster = Get-ClusterStatus -Context $Context
    $frontend = Get-DeploymentStatus -Namespace "addtocloud" -DeploymentName "addtocloud-frontend"
    $backend = Get-DeploymentStatus -Namespace "addtocloud" -DeploymentName "addtocloud-backend"
    $frontendSvc = Get-ServiceStatus -Namespace "addtocloud" -ServiceName "addtocloud-frontend"
    $backendSvc = Get-ServiceStatus -Namespace "addtocloud" -ServiceName "addtocloud-backend"
    $ingress = Get-IngressStatus -Namespace "addtocloud" -IngressName "addtocloud-ingress"
    $pvcs = Get-PVCStatus -Namespace "addtocloud"
    $resources = Get-ResourceUsage -Namespace "addtocloud"
    
    # Display cluster info
    $clusterIcon = switch ($cluster.Status) { 
        "Healthy" { "✅" } 
        "Warning" { "⚠️" } 
        default { "❌" } 
    }
    Write-Host "  $clusterIcon Cluster: $($cluster.Details) ($($cluster.NodeCount) nodes)" -ForegroundColor $(if ($cluster.Status -eq "Healthy") { "Green" } elseif ($cluster.Status -eq "Warning") { "Yellow" } else { "Red" })
    
    # Display application status
    $frontendIcon = switch ($frontend.Status) { 
        "Healthy" { "✅" } 
        "Warning" { "⚠️" } 
        default { "❌" } 
    }
    Write-Host "  $frontendIcon Frontend: $($frontend.Details)" -ForegroundColor $(if ($frontend.Status -eq "Healthy") { "Green" } elseif ($frontend.Status -eq "Warning") { "Yellow" } else { "Red" })
    
    $backendIcon = switch ($backend.Status) { 
        "Healthy" { "✅" } 
        "Warning" { "⚠️" } 
        default { "❌" } 
    }
    Write-Host "  $backendIcon Backend: $($backend.Details)" -ForegroundColor $(if ($backend.Status -eq "Healthy") { "Green" } elseif ($backend.Status -eq "Warning") { "Yellow" } else { "Red" })
    
    # Display service status
    $frontendSvcIcon = switch ($frontendSvc.Status) { 
        "Healthy" { "✅" } 
        "Warning" { "⚠️" } 
        default { "❌" } 
    }
    Write-Host "  $frontendSvcIcon Frontend Service: $($frontendSvc.Details)" -ForegroundColor $(if ($frontendSvc.Status -eq "Healthy") { "Green" } elseif ($frontendSvc.Status -eq "Warning") { "Yellow" } else { "Red" })
    
    $backendSvcIcon = switch ($backendSvc.Status) { 
        "Healthy" { "✅" } 
        "Warning" { "⚠️" } 
        default { "❌" } 
    }
    Write-Host "  $backendSvcIcon Backend Service: $($backendSvc.Details)" -ForegroundColor $(if ($backendSvc.Status -eq "Healthy") { "Green" } elseif ($backendSvc.Status -eq "Warning") { "Yellow" } else { "Red" })
    
    # Display ingress status
    $ingressIcon = switch ($ingress.Status) { 
        "Healthy" { "✅" } 
        "Warning" { "⚠️" } 
        default { "❌" } 
    }
    Write-Host "  $ingressIcon Ingress: $($ingress.Details) (IP: $($ingress.IP))" -ForegroundColor $(if ($ingress.Status -eq "Healthy") { "Green" } elseif ($ingress.Status -eq "Warning") { "Yellow" } else { "Red" })
    
    # Display storage status
    $pvcIcon = switch ($pvcs.Status) { 
        "Healthy" { "✅" } 
        "Warning" { "⚠️" } 
        "Info" { "ℹ️" } 
        default { "❌" } 
    }
    Write-Host "  $pvcIcon Storage: $($pvcs.Details)" -ForegroundColor $(if ($pvcs.Status -eq "Healthy") { "Green" } elseif ($pvcs.Status -eq "Warning") { "Yellow" } elseif ($pvcs.Status -eq "Info") { "Cyan" } else { "Red" })
    
    # Display resource usage
    $resourceIcon = switch ($resources.Status) { 
        "Healthy" { "✅" } 
        "Warning" { "⚠️" } 
        "Info" { "ℹ️" } 
        default { "❌" } 
    }
    Write-Host "  $resourceIcon Resources: $($resources.Details)" -ForegroundColor $(if ($resources.Status -eq "Healthy") { "Green" } elseif ($resources.Status -eq "Warning") { "Yellow" } elseif ($resources.Status -eq "Info") { "Cyan" } else { "Red" })
    
    # Calculate overall health score
    $statuses = @($cluster.Status, $frontend.Status, $backend.Status, $frontendSvc.Status, $backendSvc.Status, $ingress.Status, $pvcs.Status, $resources.Status)
    $healthyCount = ($statuses | Where-Object { $_ -eq "Healthy" }).Count
    $totalCount = $statuses.Count
    $score = [math]::Round(($healthyCount / $totalCount) * 100, 1)
    
    $scoreColor = if ($score -ge 80) { "Green" } elseif ($score -ge 60) { "Yellow" } else { "Red" }
    Write-Host "  📊 Health Score: $healthyCount/$totalCount ($score%)" -ForegroundColor $scoreColor
    
    return @{
        Provider = $Provider
        Score = $score
        Status = $statuses
    }
}

function Show-Header {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                        AddToCloud Deployment Status                         ║" -ForegroundColor Cyan
    Write-Host "║                           Multi-Cloud Dashboard                             ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🕐 Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
}

function Show-Summary {
    param([array]$Results)
    
    Write-Host ""
    Write-Host "📊 Multi-Cloud Summary" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    
    $totalScore = 0
    foreach ($result in $Results) {
        $scoreColor = if ($result.Score -ge 80) { "Green" } elseif ($result.Score -ge 60) { "Yellow" } else { "Red" }
        Write-Host "  $($result.Provider): $($result.Score)%" -ForegroundColor $scoreColor
        $totalScore += $result.Score
    }
    
    $averageScore = [math]::Round($totalScore / $Results.Count, 1)
    $avgColor = if ($averageScore -ge 80) { "Green" } elseif ($averageScore -ge 60) { "Yellow" } else { "Red" }
    Write-Host ""
    Write-Host "🎯 Overall Health: $averageScore%" -ForegroundColor $avgColor
    
    # Show quick actions
    Write-Host ""
    Write-Host "🔧 Quick Actions:" -ForegroundColor Cyan
    Write-Host "  - Press Ctrl+C to exit continuous mode" -ForegroundColor Gray
    Write-Host "  - Run validation script: .\validate-deployment.ps1" -ForegroundColor Gray
    Write-Host "  - Check logs: kubectl logs -n addtocloud -l app=addtocloud-backend" -ForegroundColor Gray
    Write-Host "  - Access monitoring: http://localhost:3000" -ForegroundColor Gray
}

# Main execution
$results = @()

do {
    Show-Header
    
    switch ($CloudProvider.ToLower()) {
        "azure" {
            $results = @(Show-ProviderStatus -Provider "Azure AKS" -Context "azure-aks")
        }
        "aws" {
            $results = @(Show-ProviderStatus -Provider "AWS EKS" -Context "aws-eks")
        }
        "gcp" {
            $results = @(Show-ProviderStatus -Provider "GCP GKE" -Context "gcp-gke")
        }
        "all" {
            $results = @(
                Show-ProviderStatus -Provider "Azure AKS" -Context "azure-aks"
                Show-ProviderStatus -Provider "AWS EKS" -Context "aws-eks"
                Show-ProviderStatus -Provider "GCP GKE" -Context "gcp-gke"
            )
        }
        default {
            Write-Error "Invalid cloud provider. Use: azure, aws, gcp, or all"
            exit 1
        }
    }
    
    Show-Summary -Results $results
    
    if ($Continuous) {
        Write-Host ""
        Write-Host "⏳ Refreshing in $RefreshInterval seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $RefreshInterval
    }
    
} while ($Continuous)

Write-Host ""
Write-Host "✨ Status check completed!" -ForegroundColor Green
