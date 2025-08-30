# Quick Status Monitor

Write-Host "QUICK STATUS MONITOR" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Blue
Write-Host "Time: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Check if Terraform processes are running
$terraformProcesses = Get-Process -Name "terraform" -ErrorAction SilentlyContinue
if ($terraformProcesses) {
    Write-Host "Terraform is RUNNING ($($terraformProcesses.Count) process(es))" -ForegroundColor Yellow
} else {
    Write-Host "Terraform is NOT RUNNING" -ForegroundColor Red
}

# Check deployment status files
$statusFiles = @(
    "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\azure\azure.tfplan",
    "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\gcp\gcp.tfplan", 
    "C:\Users\gokul\instant_upload\addtocloud\infrastructure\terraform\aws\aws.tfplan"
)

Write-Host ""
Write-Host "Plan Files Status:" -ForegroundColor Cyan
foreach ($file in $statusFiles) {
    $cloud = Split-Path (Split-Path $file -Parent) -Leaf
    if (Test-Path $file) {
        Write-Host "  $cloud`: PLAN EXISTS" -ForegroundColor Green
    } else {
        Write-Host "  $cloud`: NO PLAN" -ForegroundColor Red  
    }
}

Write-Host ""
Write-Host "Current Working Directory: $(Get-Location)" -ForegroundColor Gray
