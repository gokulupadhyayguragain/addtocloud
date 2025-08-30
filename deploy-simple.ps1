Write-Host "=== AddToCloud Production Deployment Started ===" -ForegroundColor Blue
Write-Host ""

Write-Host "1. Creating namespaces..." -ForegroundColor Yellow
kubectl create namespace addtocloud-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

Write-Host "2. Enabling Istio injection..." -ForegroundColor Yellow
kubectl label namespace addtocloud-prod istio-injection=enabled --overwrite

Write-Host "3. Deploying production infrastructure..." -ForegroundColor Yellow
kubectl apply -f production-infrastructure.yaml

Write-Host "4. Deploying Istio configuration..." -ForegroundColor Yellow
kubectl apply -f istio-configuration.yaml

Write-Host "5. Deploying monitoring stack..." -ForegroundColor Yellow
kubectl apply -f monitoring-complete.yaml

Write-Host "6. Waiting for deployments..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "7. Checking pod status..." -ForegroundColor Yellow
Write-Host "Production pods:" -ForegroundColor Cyan
kubectl get pods -n addtocloud-prod

Write-Host "Monitoring pods:" -ForegroundColor Cyan
kubectl get pods -n monitoring

Write-Host "8. Getting services..." -ForegroundColor Yellow
kubectl get services -n addtocloud-prod
kubectl get services -n monitoring

Write-Host "9. Creating LoadBalancer..." -ForegroundColor Yellow
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

$loadBalancerConfig | kubectl apply -f -

Write-Host "10. Deployment completed!" -ForegroundColor Green
Write-Host "Waiting for LoadBalancer to be ready..." -ForegroundColor Cyan

Start-Sleep -Seconds 45

Write-Host "11. Getting LoadBalancer URL..." -ForegroundColor Yellow
kubectl get service addtocloud-production-lb -n addtocloud-prod

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETED ===" -ForegroundColor Green
