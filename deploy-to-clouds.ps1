# Quick Multi-Cloud Deployment to EKS, AKS, and GKE
# AddToCloud Enterprise Platform

Write-Host "🚀 AddToCloud: Deploy to ALL THREE CLOUDS" -ForegroundColor Green
Write-Host "Target Clouds: AWS EKS + Azure AKS + GCP GKE" -ForegroundColor Cyan
Write-Host ""

# Prerequisites Check
Write-Host "📋 Checking Cloud CLI Tools..." -ForegroundColor Blue
$required = @("aws", "az", "gcloud", "terraform", "kubectl")
$missing = @()

foreach ($tool in $required) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "✅ $tool" -ForegroundColor Green
    } else {
        Write-Host "❌ $tool (MISSING)" -ForegroundColor Red
        $missing += $tool
    }
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing tools: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "Install missing tools first" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🎯 DEPLOYMENT PLAN:" -ForegroundColor Magenta
Write-Host "1. AWS EKS Cluster in us-east-1" -ForegroundColor White
Write-Host "2. Azure AKS Cluster in East US" -ForegroundColor White  
Write-Host "3. GCP GKE Cluster in us-central1" -ForegroundColor White
Write-Host "4. Deploy AddToCloud app to all clusters" -ForegroundColor White
Write-Host "5. Configure load balancing" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Deploy to all clouds? (y/n)"
if ($choice -ne 'y' -and $choice -ne 'Y') {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Function to show deployment status
function Show-Status {
    param($message, $color = "Cyan")
    Write-Host ""
    Write-Host "▶️ $message" -ForegroundColor $color
    Write-Host ""
}

try {
    # 1. Deploy to AWS EKS
    Show-Status "1️⃣ Deploying AWS EKS Infrastructure..." "Cyan"
    
    Set-Location "infrastructure\terraform\aws"
    
    Write-Host "Initializing AWS Terraform..." -ForegroundColor Yellow
    terraform init
    
    Write-Host "Planning AWS deployment..." -ForegroundColor Yellow
    terraform plan -var="project_name=addtocloud" -var="environment=production" -out=aws-plan.tfplan
    
    Write-Host "Deploying AWS EKS cluster..." -ForegroundColor Yellow
    terraform apply -auto-approve aws-plan.tfplan
    
    # Configure kubectl for EKS
    $eksCluster = terraform output -raw cluster_name
    $awsRegion = terraform output -raw region
    aws eks update-kubeconfig --region $awsRegion --name $eksCluster
    
    Write-Host "✅ AWS EKS deployed: $eksCluster" -ForegroundColor Green
    Set-Location "..\..\..\"

    # 2. Deploy to Azure AKS
    Show-Status "2️⃣ Deploying Azure AKS Infrastructure..." "Cyan"
    
    Set-Location "infrastructure\terraform\azure"
    
    Write-Host "Initializing Azure Terraform..." -ForegroundColor Yellow
    terraform init
    
    Write-Host "Planning Azure deployment..." -ForegroundColor Yellow
    terraform plan -var="project_name=addtocloud" -var="environment=production" -out=azure-plan.tfplan
    
    Write-Host "Deploying Azure AKS cluster..." -ForegroundColor Yellow
    terraform apply -auto-approve azure-plan.tfplan
    
    # Configure kubectl for AKS
    $aksResourceGroup = terraform output -raw resource_group_name
    $aksCluster = terraform output -raw cluster_name
    az aks get-credentials --resource-group $aksResourceGroup --name $aksCluster --overwrite-existing
    
    Write-Host "✅ Azure AKS deployed: $aksCluster" -ForegroundColor Green
    Set-Location "..\..\..\"

    # 3. Deploy to GCP GKE
    Show-Status "3️⃣ Deploying GCP GKE Infrastructure..." "Cyan"
    
    Set-Location "infrastructure\terraform\gcp"
    
    Write-Host "Initializing GCP Terraform..." -ForegroundColor Yellow
    terraform init
    
    Write-Host "Planning GCP deployment..." -ForegroundColor Yellow
    terraform plan -var="project_name=addtocloud" -var="environment=production" -out=gcp-plan.tfplan
    
    Write-Host "Deploying GCP GKE cluster..." -ForegroundColor Yellow
    terraform apply -auto-approve gcp-plan.tfplan
    
    # Configure kubectl for GKE
    $gkeCluster = terraform output -raw cluster_name
    $gkeZone = terraform output -raw zone
    $gcpProject = terraform output -raw project_id
    gcloud container clusters get-credentials $gkeCluster --zone $gkeZone --project $gcpProject
    
    Write-Host "✅ GCP GKE deployed: $gkeCluster" -ForegroundColor Green
    Set-Location "..\..\..\"

    # 4. Deploy Application to All Clusters
    Show-Status "4️⃣ Deploying AddToCloud App to All Clusters..." "Cyan"
    
    $clusters = @(
        @{name="AWS EKS"; context=$eksCluster},
        @{name="Azure AKS"; context=$aksCluster},
        @{name="GCP GKE"; context=$gkeCluster}
    )
    
    foreach ($cluster in $clusters) {
        Write-Host "Deploying to $($cluster.name)..." -ForegroundColor Yellow
        
        # Switch to cluster context
        kubectl config use-context $cluster.context
        
        # Create namespace
        kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
        
        # Deploy application
        kubectl apply -f infrastructure\kubernetes\deployments\ -n addtocloud
        kubectl apply -f infrastructure\kubernetes\services\ -n addtocloud
        
        # Wait for deployment
        kubectl wait --for=condition=available --timeout=300s deployment/addtocloud-backend -n addtocloud
        
        Write-Host "✅ Deployed to $($cluster.name)" -ForegroundColor Green
    }

    # 5. Show Results
    Show-Status "🎉 MULTI-CLOUD DEPLOYMENT COMPLETE!" "Green"
    
    Write-Host "📊 DEPLOYMENT SUMMARY:" -ForegroundColor Magenta
    Write-Host ""
    
    foreach ($cluster in $clusters) {
        kubectl config use-context $cluster.context
        $nodeCount = (kubectl get nodes --no-headers | Measure-Object).Count
        $podCount = (kubectl get pods -n addtocloud --no-headers | Measure-Object).Count
        
        Write-Host "🌐 $($cluster.name):" -ForegroundColor Cyan
        Write-Host "   Context: $($cluster.context)" -ForegroundColor White
        Write-Host "   Nodes: $nodeCount" -ForegroundColor White
        Write-Host "   Pods: $podCount" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "🔗 ACCESS URLS:" -ForegroundColor Magenta
    Write-Host "Frontend: https://addtocloud.pages.dev" -ForegroundColor Green
    Write-Host "API: https://api.addtocloud.tech" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📱 NEXT STEPS:" -ForegroundColor Magenta
    Write-Host "1. Configure DNS routing to all clusters" -ForegroundColor White
    Write-Host "2. Set up monitoring across all clouds" -ForegroundColor White
    Write-Host "3. Test multi-cloud functionality" -ForegroundColor White
    Write-Host ""
    
    Write-Host "✅ All three clouds are now running AddToCloud!" -ForegroundColor Green

} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check logs above for details" -ForegroundColor Yellow
    exit 1
}
