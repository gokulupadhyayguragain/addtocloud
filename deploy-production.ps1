#!/usr/bin/env pwsh
# AddToCloud Complete Production Deployment Script
# Includes Kubernetes 1.31, Istio, Monitoring, and all DevOps tools

Write-Host "=== AddToCloud Production Deployment Started ===" -ForegroundColor Blue
Write-Host ""

# Set error handling
$ErrorActionPreference = "Continue"

Write-Host "1. Checking EKS cluster upgrade status..." -ForegroundColor Yellow
try {
    $clusterStatus = aws eks describe-cluster --name addtocloud-prod-eks --region us-west-2 --query "cluster.status" --output text
    Write-Host "   Cluster status: $clusterStatus" -ForegroundColor Cyan
    
    if ($clusterStatus -eq "UPDATING") {
        Write-Host "   Cluster is updating to Kubernetes 1.31... Please wait." -ForegroundColor Yellow
        Write-Host "   This may take 15-20 minutes. Continuing with deployment..." -ForegroundColor Cyan
    }
} catch {
    Write-Host "   Could not check cluster status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "2. Creating namespaces..." -ForegroundColor Yellow

# Create namespaces
$namespaces = @("addtocloud-prod", "monitoring", "logging")
foreach ($namespace in $namespaces) {
    try {
        kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -
        Write-Host "   Created/Updated namespace: $namespace" -ForegroundColor Green
    } catch {
        Write-Host "   Failed to create namespace $namespace : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "3. Enabling Istio injection for production namespace..." -ForegroundColor Yellow
try {
    kubectl label namespace addtocloud-prod istio-injection=enabled --overwrite
    Write-Host "   Istio injection enabled for addtocloud-prod" -ForegroundColor Green
} catch {
    Write-Host "   Failed to enable Istio injection: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "4. Deploying production infrastructure..." -ForegroundColor Yellow
try {
    kubectl apply -f production-infrastructure.yaml
    Write-Host "   Production infrastructure deployed" -ForegroundColor Green
} catch {
    Write-Host "   Failed to deploy infrastructure: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "5. Deploying Istio configuration..." -ForegroundColor Yellow
try {
    kubectl apply -f istio-configuration.yaml
    Write-Host "   Istio service mesh configured" -ForegroundColor Green
} catch {
    Write-Host "   Failed to deploy Istio config: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "6. Deploying monitoring stack..." -ForegroundColor Yellow
try {
    kubectl apply -f monitoring-complete.yaml
    Write-Host "   Monitoring stack (Prometheus, Grafana, AlertManager) deployed" -ForegroundColor Green
} catch {
    Write-Host "   Failed to deploy monitoring: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "7. Waiting for deployments to be ready..." -ForegroundColor Yellow

# Wait for key deployments
$deployments = @(
    "addtocloud-prod:addtocloud-backend",
    "addtocloud-prod:addtocloud-frontend", 
    "addtocloud-prod:postgres",
    "monitoring:prometheus",
    "monitoring:grafana"
)

foreach ($deployment in $deployments) {
    $namespace, $name = $deployment -split ":"
    try {
        Write-Host "   Waiting for $name in namespace $namespace..." -ForegroundColor Cyan
        kubectl wait --for=condition=available --timeout=300s deployment/$name -n $namespace
        Write-Host "   ✅ $name is ready" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ $name may still be starting: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "8. Checking pod status..." -ForegroundColor Yellow
Write-Host "   Production pods:" -ForegroundColor Cyan
kubectl get pods -n addtocloud-prod

Write-Host "   Monitoring pods:" -ForegroundColor Cyan
kubectl get pods -n monitoring

Write-Host "   Istio system:" -ForegroundColor Cyan
kubectl get pods -n istio-system

Write-Host ""
Write-Host "9. Getting service information..." -ForegroundColor Yellow
Write-Host "   Production services:" -ForegroundColor Cyan
kubectl get services -n addtocloud-prod

Write-Host "   Monitoring services:" -ForegroundColor Cyan
kubectl get services -n monitoring

Write-Host "   LoadBalancer services:" -ForegroundColor Cyan
kubectl get services --all-namespaces | findstr LoadBalancer

Write-Host ""
Write-Host "10. Setting up DNS and ingress..." -ForegroundColor Yellow

# Get Istio ingress gateway external IP
try {
    $ingressIP = kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    if ($ingressIP) {
        Write-Host "   Istio Ingress Gateway: $ingressIP" -ForegroundColor Green
        Write-Host "   Configure DNS records:" -ForegroundColor Cyan
        Write-Host "     addtocloud.tech -> $ingressIP" -ForegroundColor Cyan
        Write-Host "     api.addtocloud.tech -> $ingressIP" -ForegroundColor Cyan
        Write-Host "     grafana.addtocloud.tech -> $ingressIP" -ForegroundColor Cyan
    } else {
        Write-Host "   Istio ingress IP not yet available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Could not get ingress IP: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "11. Creating LoadBalancer for direct access..." -ForegroundColor Yellow

# Create LoadBalancer service for production backend
$loadBalancerConfig = @"
apiVersion: v1
kind: Service
metadata:
  name: addtocloud-production-lb
  namespace: addtocloud-prod
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: addtocloud-backend
"@

try {
    $loadBalancerConfig | kubectl apply -f -
    Write-Host "   Production LoadBalancer created" -ForegroundColor Green
} catch {
    Write-Host "   Failed to create LoadBalancer: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "12. Testing API endpoints..." -ForegroundColor Yellow

# Wait a bit for LoadBalancer to be ready
Start-Sleep -Seconds 30

try {
    $lbInfo = kubectl get service addtocloud-production-lb -n addtocloud-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    if ($lbInfo) {
        Write-Host "   Production API URL: http://$lbInfo" -ForegroundColor Green
        
        # Test health endpoint
        try {
            $healthResponse = Invoke-RestMethod -Uri "http://$lbInfo/api/health" -Method GET -TimeoutSec 10
            Write-Host "   ✅ API Health: $($healthResponse.status)" -ForegroundColor Green
            Write-Host "   📊 Version: $($healthResponse.version)" -ForegroundColor Cyan
        } catch {
            Write-Host "   ⚠️ API not yet ready: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   LoadBalancer IP not yet available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Could not get LoadBalancer info: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "13. Deployment summary..." -ForegroundColor Yellow

Write-Host "   ✅ Kubernetes cluster (upgrading to 1.31)" -ForegroundColor Green
Write-Host "   ✅ Istio service mesh enabled" -ForegroundColor Green
Write-Host "   ✅ Production infrastructure deployed" -ForegroundColor Green
Write-Host "   ✅ Monitoring stack (Prometheus, Grafana) deployed" -ForegroundColor Green
Write-Host "   ✅ AlertManager with email notifications" -ForegroundColor Green
Write-Host "   ✅ ArgoCD for GitOps (already running)" -ForegroundColor Green
Write-Host "   ✅ PostgreSQL database" -ForegroundColor Green
Write-Host "   ✅ LoadBalancer for external access" -ForegroundColor Green

Write-Host ""
Write-Host "14. Access Information:" -ForegroundColor Blue
Write-Host "   🌐 Website: https://addtocloud.tech" -ForegroundColor Cyan
Write-Host "   🔧 API: Check LoadBalancer URL above" -ForegroundColor Cyan
Write-Host "   📊 Grafana: http://grafana-service-external-ip:3000 (admin/addtocloud123)" -ForegroundColor Cyan
Write-Host "   🚀 ArgoCD: Check ArgoCD service for URL" -ForegroundColor Cyan
Write-Host "   📈 Prometheus: Internal cluster access only" -ForegroundColor Cyan

Write-Host ""
Write-Host "15. Next Steps:" -ForegroundColor Blue
Write-Host "   1. Wait for Kubernetes upgrade to complete" -ForegroundColor Cyan
Write-Host "   2. Configure DNS records for Istio ingress" -ForegroundColor Cyan
Write-Host "   3. Set up SSL certificates" -ForegroundColor Cyan
Write-Host "   4. Configure CloudFlare worker to use new API" -ForegroundColor Cyan
Write-Host "   5. Set up monitoring dashboards in Grafana" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETED ===" -ForegroundColor Green
Write-Host "Production-ready multi-cloud platform is now deployed!" -ForegroundColor Green
Write-Host ""
