# Simple Production Website Fix

Write-Host "DEPLOYING SIMPLE WORKING WEBSITE" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Blue

# Create a simple deployment that works
kubectl create deployment simple-web --image=nginx:alpine -n addtocloud
kubectl expose deployment simple-web --port=80 --type=ClusterIP -n addtocloud

# Create virtual service YAML file
$virtualServiceYaml = @"
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: simple-routes
  namespace: addtocloud
spec:
  hosts:
  - "*"
  gateways:
  - addtocloud-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: simple-web.addtocloud.svc.cluster.local
        port:
          number: 80
"@

$virtualServiceYaml | Out-File -FilePath "simple-vs.yaml" -Encoding UTF8
kubectl apply -f simple-vs.yaml
Remove-Item "simple-vs.yaml" -Force

Write-Host ""
Write-Host "✅ SIMPLE WEBSITE DEPLOYED!" -ForegroundColor Green
Write-Host "🌐 Test: http://52.224.84.148" -ForegroundColor Cyan
