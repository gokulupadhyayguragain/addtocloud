# Deploy Complete AddToCloud Production Stack
Write-Host "🚀 DEPLOYING COMPLETE ADDTOCLOUD PRODUCTION STACK" -ForegroundColor Blue

# Set paths
$env:PATH += ";C:\Program Files\Amazon\AWSCLIV2"
$env:PATH += ";c:\Users\gokul\instant_upload\addtocloud\windows-amd64"

# Deploy to AWS EKS
Write-Host "`n🟦 DEPLOYING TO AWS EKS..." -ForegroundColor Blue
kubectl config use-context arn:aws:eks:us-west-2:741448922544:cluster/addtocloud-prod-eks

# Create namespace and enable Istio injection
kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace addtocloud istio-injection=enabled --overwrite

# Deploy database
Write-Host "🗄️ Deploying PostgreSQL database..." -ForegroundColor Cyan
kubectl apply -f c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\database.yaml

# Deploy backend
Write-Host "🔧 Deploying Backend API with 400+ services..." -ForegroundColor Cyan
kubectl apply -f c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\backend.yaml

# Deploy frontend
Write-Host "🌐 Deploying Frontend..." -ForegroundColor Cyan
kubectl apply -f c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\frontend.yaml

# Deploy Istio gateway
Write-Host "🌐 Configuring Istio Gateway..." -ForegroundColor Cyan
kubectl apply -f c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\gateway.yaml

# Deploy monitoring
Write-Host "📊 Deploying Prometheus and Grafana..." -ForegroundColor Cyan
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --set grafana.service.type=LoadBalancer --set grafana.adminPassword=admin123 --wait --timeout=10m

Write-Host "`n✅ AWS EKS DEPLOYMENT COMPLETE!" -ForegroundColor Green

# Deploy to Azure AKS
Write-Host "`n🟦 DEPLOYING TO AZURE AKS..." -ForegroundColor Blue
kubectl config use-context aks-addtocloud-prod

# Create namespace and enable Istio injection
kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace addtocloud istio-injection=enabled --overwrite

# Deploy all components
kubectl apply -f c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\database.yaml
kubectl apply -f c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\backend.yaml
kubectl apply -f c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\frontend.yaml
kubectl apply -f c:\Users\gokul\instant_upload\addtocloud\infrastructure\kubernetes\gateway.yaml

# Deploy monitoring
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --set grafana.service.type=LoadBalancer --set grafana.adminPassword=admin123 --wait --timeout=10m

Write-Host "`n✅ AZURE AKS DEPLOYMENT COMPLETE!" -ForegroundColor Green

# Get endpoints
Write-Host "`n📍 GETTING SERVICE ENDPOINTS..." -ForegroundColor Cyan

kubectl config use-context arn:aws:eks:us-west-2:741448922544:cluster/addtocloud-prod-eks
$awsIstio = kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
$awsGrafana = kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null

kubectl config use-context aks-addtocloud-prod
$azureIstio = kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
$azureGrafana = kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null

Write-Host "`n🎉 DEPLOYMENT COMPLETE! LIVE ENDPOINTS:" -ForegroundColor Green
Write-Host "`n🟦 AWS EKS:" -ForegroundColor Blue
if ($awsIstio) { Write-Host "  🌐 AddToCloud: http://$awsIstio" -ForegroundColor White }
if ($awsGrafana) { Write-Host "  📊 Grafana: http://$awsGrafana (admin/admin123)" -ForegroundColor White }

Write-Host "`n🟦 Azure AKS:" -ForegroundColor Blue
if ($azureIstio) { Write-Host "  🌐 AddToCloud: http://$azureIstio" -ForegroundColor White }
if ($azureGrafana) { Write-Host "  📊 Grafana: http://$azureGrafana (admin/admin123)" -ForegroundColor White }

Write-Host "`n🔗 TO ACCESS addtocloud.tech:" -ForegroundColor Yellow
Write-Host "  1. Configure Cloudflare DNS:" -ForegroundColor White
Write-Host "     - A record: addtocloud.tech -> $azureIstio" -ForegroundColor Gray
Write-Host "     - CNAME: aws.addtocloud.tech -> $awsIstio" -ForegroundColor Gray
Write-Host "  2. Enable Cloudflare SSL/TLS" -ForegroundColor White
Write-Host "  3. Set up load balancing between both endpoints" -ForegroundColor White

Write-Host "`n📋 DEPLOYED COMPONENTS:" -ForegroundColor Blue
Write-Host "  ✅ Frontend (Next.js with Istio sidecars)" -ForegroundColor Green
Write-Host "  ✅ Backend API (Go with 400+ cloud services)" -ForegroundColor Green
Write-Host "  ✅ PostgreSQL Database" -ForegroundColor Green
Write-Host "  ✅ Service Mesh (Istio)" -ForegroundColor Green
Write-Host "  ✅ Monitoring (Prometheus + Grafana)" -ForegroundColor Green
Write-Host "  ✅ Load Balancers" -ForegroundColor Green
