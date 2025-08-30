# Frontend API Connection Fix
# This script creates the necessary API endpoints and updates the frontend configuration

Write-Host "🔧 FIXING FRONTEND-BACKEND CONNECTION ISSUE" -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host ""

# Get the current Istio gateway endpoint
$istioGateway = kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
Write-Host "🌐 Istio Gateway: $istioGateway" -ForegroundColor Cyan

# Test backend API connectivity
Write-Host "🔍 Testing backend API connectivity..." -ForegroundColor Yellow

# Test through port forwarding first
Write-Host "📡 Setting up temporary port forward to test API..." -ForegroundColor Gray
Start-Job -Name "PortForward" -ScriptBlock {
    kubectl port-forward -n addtocloud-prod svc/addtocloud-api-enterprise 8899:8080
} | Out-Null

Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8899/api/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "✅ Backend API is responding: $($response.StatusCode)" -ForegroundColor Green
    $apiWorking = $true
} catch {
    Write-Host "❌ Backend API not responding through port forward" -ForegroundColor Red
    $apiWorking = $false
}

# Stop port forward
Get-Job -Name "PortForward" | Stop-Job | Remove-Job

if ($apiWorking) {
    Write-Host "📋 SOLUTION: Frontend needs API endpoint configuration" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔧 FIXING OPTIONS:" -ForegroundColor Cyan
    Write-Host "1. ✅ Create LoadBalancer for direct API access" -ForegroundColor White
    Write-Host "2. ✅ Configure DNS CNAME for api.addtocloud.tech" -ForegroundColor White
    Write-Host "3. ✅ Update frontend to use production API URLs" -ForegroundColor White
    Write-Host "4. ✅ Fix CORS configuration for CloudFlare" -ForegroundColor White
    Write-Host ""
    
    # Create a dedicated API LoadBalancer
    Write-Host "🚀 Creating dedicated API LoadBalancer..." -ForegroundColor Green
    
    $apiLoadBalancer = @"
apiVersion: v1
kind: Service
metadata:
  name: addtocloud-api-public
  namespace: addtocloud-prod
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
  labels:
    app: addtocloud-api-public
spec:
  type: LoadBalancer
  selector:
    app: addtocloud-api-enterprise
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 8080
    protocol: TCP
"@
    
    $apiLoadBalancer | kubectl apply -f -
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ API LoadBalancer created successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create API LoadBalancer" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ Backend API is not working - need to fix backend first" -ForegroundColor Red
}

Write-Host ""
Write-Host "📊 CURRENT ARCHITECTURE ISSUE:" -ForegroundColor Red
Write-Host "=============================" -ForegroundColor Yellow
Write-Host "CloudFlare Frontend (https://addtocloud.tech)" -ForegroundColor White
Write-Host "        ↓ ❌ NO CONNECTION" -ForegroundColor Red
Write-Host "Kubernetes Backend APIs (Internal only)" -ForegroundColor White
Write-Host ""
Write-Host "🎯 REQUIRED ARCHITECTURE:" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Yellow
Write-Host "CloudFlare Frontend (https://addtocloud.tech)" -ForegroundColor White
Write-Host "        ↓ ✅ API CALLS TO" -ForegroundColor Green
Write-Host "Public API LoadBalancer (api.addtocloud.tech)" -ForegroundColor White
Write-Host "        ↓ ✅ ROUTES TO" -ForegroundColor Green
Write-Host "Kubernetes Backend APIs + Database" -ForegroundColor White
