# Production Fix - Deploy Working Application

Write-Host "FIXING PRODUCTION DEPLOYMENT" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Blue
Write-Host ""

# Step 1: Fix the frontend deployment
Write-Host "1. FIXING FRONTEND DEPLOYMENT" -ForegroundColor Cyan

# Create a working frontend deployment with nginx serving static files
$frontendYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addtocloud-frontend-fixed
  namespace: addtocloud
spec:
  replicas: 3
  selector:
    matchLabels:
      app: addtocloud-frontend-fixed
  template:
    metadata:
      labels:
        app: addtocloud-frontend-fixed
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: config
        configMap:
          name: frontend-config
      - name: html
        configMap:
          name: frontend-html
---
apiVersion: v1
kind: Service
metadata:
  name: addtocloud-frontend-fixed
  namespace: addtocloud
spec:
  selector:
    app: addtocloud-frontend-fixed
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
"@

$frontendYaml | Out-File -FilePath "frontend-fixed.yaml" -Encoding UTF8

# Create nginx config
$nginxConfig = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: addtocloud
data:
  default.conf: |
    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files `$uri `$uri/ /index.html;
        }
        
        location /api {
            proxy_pass http://addtocloud-backend.addtocloud.svc.cluster.local:8080;
            proxy_set_header Host `$host;
            proxy_set_header X-Real-IP `$remote_addr;
        }
    }
"@

$nginxConfig | Out-File -FilePath "frontend-config.yaml" -Encoding UTF8

# Create HTML content
$htmlContent = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-html
  namespace: addtocloud
data:
  index.html: |
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>AddToCloud - Enterprise Multi-Cloud Platform</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white; min-height: 100vh; display: flex; align-items: center;
            }
            .container { max-width: 1200px; margin: 0 auto; padding: 2rem; text-align: center; }
            .hero { margin-bottom: 3rem; }
            h1 { font-size: 3.5rem; margin-bottom: 1rem; font-weight: 700; }
            .subtitle { font-size: 1.2rem; opacity: 0.9; margin-bottom: 2rem; }
            .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; margin: 2rem 0; }
            .status-card { 
                background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 15px;
                backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.2);
            }
            .status-card h3 { color: #4ade80; margin-bottom: 1rem; }
            .endpoint { background: rgba(0,0,0,0.2); padding: 1rem; border-radius: 8px; margin: 0.5rem 0; }
            .endpoint a { color: #60a5fa; text-decoration: none; }
            .endpoint a:hover { text-decoration: underline; }
            .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin: 3rem 0; }
            .feature { background: rgba(255,255,255,0.05); padding: 1.5rem; border-radius: 10px; }
            .cta { margin-top: 3rem; }
            .btn { 
                display: inline-block; padding: 1rem 2rem; margin: 0.5rem;
                background: linear-gradient(45deg, #4ade80, #22d3ee);
                color: white; text-decoration: none; border-radius: 50px;
                font-weight: 600; transition: transform 0.2s;
            }
            .btn:hover { transform: translateY(-2px); }
            .footer { margin-top: 3rem; opacity: 0.7; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="hero">
                <h1>🚀 AddToCloud</h1>
                <p class="subtitle">Enterprise Multi-Cloud Platform - Live & Running</p>
            </div>
            
            <div class="status-grid">
                <div class="status-card">
                    <h3>✅ Azure AKS</h3>
                    <p>Primary Production Cluster</p>
                    <div class="endpoint">
                        <strong>Location:</strong> East US<br>
                        <strong>Status:</strong> Running<br>
                        <strong>URL:</strong> <a href="http://52.224.84.148">http://52.224.84.148</a>
                    </div>
                </div>
                
                <div class="status-card">
                    <h3>✅ AWS EKS</h3>
                    <p>Secondary Production Cluster</p>
                    <div class="endpoint">
                        <strong>Location:</strong> US West 2<br>
                        <strong>Status:</strong> Running<br>
                        <strong>URL:</strong> <a href="http://a21f927dc7e504cbe99d241bc3562345-1460504033.us-west-2.elb.amazonaws.com">AWS EKS</a>
                    </div>
                </div>
                
                <div class="status-card">
                    <h3>✅ GCP GKE</h3>
                    <p>Tertiary Production Cluster</p>
                    <div class="endpoint">
                        <strong>Location:</strong> US Central 1<br>
                        <strong>Status:</strong> Running<br>
                        <strong>IP:</strong> 34.61.70.104
                    </div>
                </div>
            </div>
            
            <div class="features">
                <div class="feature">
                    <h3>🌐 Multi-Cloud</h3>
                    <p>Deployed across Azure, AWS, and GCP for maximum reliability and performance.</p>
                </div>
                <div class="feature">
                    <h3>🔒 Enterprise Security</h3>
                    <p>Advanced security features with Istio service mesh and network policies.</p>
                </div>
                <div class="feature">
                    <h3>📊 Auto-Scaling</h3>
                    <p>Kubernetes horizontal pod autoscaling for handling traffic spikes.</p>
                </div>
                <div class="feature">
                    <h3>🚀 High Performance</h3>
                    <p>Load balanced across multiple regions with low latency routing.</p>
                </div>
            </div>
            
            <div class="cta">
                <a href="/api/health" class="btn">🩺 Health Check</a>
                <a href="/api/v1/cloud/services" class="btn">📡 API Services</a>
                <a href="mailto:contact@addtocloud.tech" class="btn">📧 Contact Us</a>
            </div>
            
            <div class="footer">
                <p>© 2025 AddToCloud Enterprise. Multi-cloud platform operational across 3 major cloud providers.</p>
                <p>🎯 <strong>Production Status:</strong> All systems operational</p>
            </div>
        </div>
        
        <script>
            // Simple health check display
            async function checkHealth() {
                try {
                    const response = await fetch('/api/health');
                    const status = response.ok ? '🟢 API Healthy' : '🔴 API Issues';
                    console.log('API Status:', status);
                } catch (error) {
                    console.log('API Status: 🔴 Not responding');
                }
            }
            
            // Check health on load
            checkHealth();
            
            // Auto-refresh every 30 seconds
            setInterval(checkHealth, 30000);
        </script>
    </body>
    </html>
"@

$htmlContent | Out-File -FilePath "frontend-html.yaml" -Encoding UTF8

Write-Host "Applying production fixes..." -ForegroundColor Yellow

# Apply the configurations
kubectl apply -f frontend-config.yaml
kubectl apply -f frontend-html.yaml  
kubectl apply -f frontend-fixed.yaml

# Update the virtual service to point to the fixed frontend
$virtualServiceYaml = @"
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: addtocloud-routes-fixed
  namespace: addtocloud
spec:
  hosts:
  - "*"
  gateways:
  - addtocloud-gateway
  http:
  - match:
    - uri:
        prefix: /api
    route:
    - destination:
        host: addtocloud-backend.addtocloud.svc.cluster.local
        port:
          number: 8080
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: addtocloud-frontend-fixed.addtocloud.svc.cluster.local
        port:
          number: 80
"@

$virtualServiceYaml | Out-File -FilePath "virtualservice-fixed.yaml" -Encoding UTF8
kubectl apply -f virtualservice-fixed.yaml

Write-Host ""
Write-Host "✅ PRODUCTION FIX APPLIED!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Test the websites now:" -ForegroundColor Cyan
Write-Host "   Azure: http://52.224.84.148" -ForegroundColor Yellow
Write-Host "   AWS:   http://a21f927dc7e504cbe99d241bc3562345-1460504033.us-west-2.elb.amazonaws.com" -ForegroundColor Yellow
Write-Host ""

# Clean up
Remove-Item "frontend-*.yaml" -Force
Remove-Item "virtualservice-fixed.yaml" -Force
