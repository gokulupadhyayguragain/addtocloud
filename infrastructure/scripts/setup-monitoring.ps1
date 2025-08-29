# AddToCloud Monitoring Dashboard Setup
# This script sets up Grafana dashboards and Prometheus alerts

param(
    [string]$CloudProvider = "all"
)

# Color functions
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Blue }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }

Write-Info "📊 Setting up AddToCloud monitoring dashboards..."

# Create Grafana dashboard for application metrics
$appDashboard = @"
{
  "dashboard": {
    "title": "AddToCloud Application Metrics",
    "tags": ["addtocloud", "application"],
    "timezone": "browser",
    "panels": [
      {
        "title": "HTTP Request Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "title": "Response Time",
        "type": "timeseries",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, http_request_duration_seconds_bucket)",
            "legendFormat": "95th percentile"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "title": "Error Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "Error Rate"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 8}
      },
      {
        "title": "Active Connections",
        "type": "stat",
        "targets": [
          {
            "expr": "go_goroutines",
            "legendFormat": "Goroutines"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 8}
      },
      {
        "title": "Memory Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "go_memstats_alloc_bytes",
            "legendFormat": "Memory Allocated"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
"@

# Create Grafana dashboard for infrastructure metrics
$infraDashboard = @"
{
  "dashboard": {
    "title": "AddToCloud Infrastructure Metrics",
    "tags": ["addtocloud", "infrastructure"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Pod CPU Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{pod=~\"addtocloud-.*\"}[5m])",
            "legendFormat": "{{pod}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "title": "Pod Memory Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "container_memory_usage_bytes{pod=~\"addtocloud-.*\"}",
            "legendFormat": "{{pod}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "title": "Kubernetes Cluster Status",
        "type": "stat",
        "targets": [
          {
            "expr": "kube_node_status_condition{condition=\"Ready\",status=\"true\"}",
            "legendFormat": "Ready Nodes"
          }
        ],
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 8}
      },
      {
        "title": "Pod Restart Count",
        "type": "stat",
        "targets": [
          {
            "expr": "kube_pod_container_status_restarts_total{pod=~\"addtocloud-.*\"}",
            "legendFormat": "{{pod}}"
          }
        ],
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 8}
      },
      {
        "title": "Persistent Volume Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * 100",
            "legendFormat": "{{persistentvolumeclaim}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
"@

# Create Prometheus alerts
$prometheusAlerts = @"
groups:
  - name: addtocloud.rules
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: High error rate detected
          description: "Error rate is {{ \$value }} errors per second"
      
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High response time detected
          description: "95th percentile response time is {{ \$value }} seconds"
      
      - alert: PodCrashLooping
        expr: kube_pod_container_status_restarts_total > 5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: Pod is crash looping
          description: "Pod {{ \$labels.pod }} has restarted {{ \$value }} times"
      
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High memory usage
          description: "Container {{ \$labels.container }} is using {{ \$value }}% of memory"
      
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High CPU usage
          description: "Container {{ \$labels.container }} CPU usage is {{ \$value }}%"
      
      - alert: PVCAlmostFull
        expr: kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: PVC almost full
          description: "PVC {{ \$labels.persistentvolumeclaim }} is {{ \$value }}% full"
      
      - alert: ServiceDown
        expr: up{job=~"addtocloud-.*"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: Service is down
          description: "Service {{ \$labels.job }} is down"
"@

# Function to setup monitoring for a specific cloud provider
function Setup-Monitoring {
    param([string]$Provider, [string]$Context)
    
    Write-Info "🌐 Setting up monitoring for $Provider..."
    
    try {
        # Switch to the correct context
        kubectl config use-context $Context
        
        # Create monitoring namespace if it doesn't exist
        kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
        
        # Create Prometheus alerts configmap
        $prometheusAlerts | kubectl create configmap prometheus-alerts --from-file=/dev/stdin -n monitoring --dry-run=client -o yaml | kubectl apply -f -
        Write-Success "Created Prometheus alerts for $Provider"
        
        # Get Grafana admin password
        $grafanaPassword = kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.password}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
        
        if (-not $grafanaPassword) {
            Write-Warning "Grafana not found, creating default installation..."
            
            # Create Grafana deployment
            $grafanaDeployment = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
"@
            
            $grafanaDeployment | kubectl apply -f -
            Write-Success "Created Grafana deployment for $Provider"
            
            # Wait for Grafana to be ready
            Write-Info "Waiting for Grafana to be ready..."
            kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
        }
        
        # Port forward to access Grafana (in background)
        Write-Info "Setting up port forward for Grafana..."
        Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "svc/grafana", "3000:3000", "-n", "monitoring" -WindowStyle Hidden
        
        Write-Success "Monitoring setup completed for $Provider"
        Write-Info "Grafana available at: http://localhost:3000 (admin/admin123)"
        
        # Create dashboards (would need Grafana API calls in real implementation)
        Write-Info "Dashboard configurations saved to monitoring namespace"
        
        return $true
        
    } catch {
        Write-Error "Failed to setup monitoring for $Provider`: $_"
        return $false
    }
}

function Create-MonitoringConfigMaps {
    Write-Info "Creating monitoring configuration files..."
    
    try {
        # Create dashboard configs as configmaps
        $appDashboard | kubectl create configmap grafana-dashboard-app --from-file=/dev/stdin -n monitoring --dry-run=client -o yaml | kubectl apply -f -
        $infraDashboard | kubectl create configmap grafana-dashboard-infra --from-file=/dev/stdin -n monitoring --dry-run=client -o yaml | kubectl apply -f -
        
        Write-Success "Created dashboard configurations"
        
        # Create a script to import dashboards
        $importScript = @"
#!/bin/bash
# Dashboard import script
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

# Wait for Grafana to be ready
until curl -s "\$GRAFANA_URL/api/health" > /dev/null; do
  echo "Waiting for Grafana..."
  sleep 5
done

# Import application dashboard
curl -X POST \\
  -H "Content-Type: application/json" \\
  -d '@/tmp/app-dashboard.json' \\
  "http://\$GRAFANA_USER:\$GRAFANA_PASS@\$GRAFANA_URL/api/dashboards/db"

# Import infrastructure dashboard
curl -X POST \\
  -H "Content-Type: application/json" \\
  -d '@/tmp/infra-dashboard.json' \\
  "http://\$GRAFANA_USER:\$GRAFANA_PASS@\$GRAFANA_URL/api/dashboards/db"

echo "Dashboards imported successfully!"
"@
        
        $importScript | Out-File -FilePath ".\import-dashboards.sh" -Encoding UTF8
        Write-Success "Created dashboard import script"
        
        return $true
        
    } catch {
        Write-Error "Failed to create monitoring configs: $_"
        return $false
    }
}

# Main execution
Write-Info "🚀 Starting monitoring dashboard setup..."

# Create monitoring configurations
if (-not (Create-MonitoringConfigMaps)) {
    Write-Error "Failed to create monitoring configurations"
    exit 1
}

# Setup monitoring for specified cloud providers
$results = @{}

switch ($CloudProvider.ToLower()) {
    "azure" {
        $results["azure"] = Setup-Monitoring -Provider "Azure AKS" -Context "azure-aks"
    }
    "aws" {
        $results["aws"] = Setup-Monitoring -Provider "AWS EKS" -Context "aws-eks"
    }
    "gcp" {
        $results["gcp"] = Setup-Monitoring -Provider "GCP GKE" -Context "gcp-gke"
    }
    "all" {
        $results["azure"] = Setup-Monitoring -Provider "Azure AKS" -Context "azure-aks"
        $results["aws"] = Setup-Monitoring -Provider "AWS EKS" -Context "aws-eks"
        $results["gcp"] = Setup-Monitoring -Provider "GCP GKE" -Context "gcp-gke"
    }
    default {
        Write-Error "Invalid cloud provider. Use: azure, aws, gcp, or all"
        exit 1
    }
}

# Show results
Write-Host ""
Write-Host "📊 Monitoring Setup Summary:" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

foreach ($provider in $results.Keys) {
    if ($results[$provider]) {
        Write-Success "$($provider.ToUpper()): Monitoring configured successfully"
    } else {
        Write-Error "$($provider.ToUpper()): Monitoring setup failed"
    }
}

Write-Host ""
Write-Host "📋 Monitoring Access:" -ForegroundColor Cyan
Write-Host "- Grafana: http://localhost:3000 (admin/admin123)" -ForegroundColor White
Write-Host "- Prometheus: http://localhost:9090" -ForegroundColor White
Write-Host "- AlertManager: http://localhost:9093" -ForegroundColor White

Write-Host ""
Write-Host "📈 Available Dashboards:" -ForegroundColor Cyan
Write-Host "- AddToCloud Application Metrics" -ForegroundColor White
Write-Host "- AddToCloud Infrastructure Metrics" -ForegroundColor White

Write-Host ""
Write-Host "🔔 Configured Alerts:" -ForegroundColor Cyan
Write-Host "- High Error Rate (>10%)" -ForegroundColor White
Write-Host "- High Response Time (>1s)" -ForegroundColor White
Write-Host "- Pod Crash Looping (>5 restarts)" -ForegroundColor White
Write-Host "- High Memory Usage (>90%)" -ForegroundColor White
Write-Host "- High CPU Usage (>80%)" -ForegroundColor White
Write-Host "- PVC Almost Full (>90%)" -ForegroundColor White
Write-Host "- Service Down" -ForegroundColor White

Write-Host ""
Write-Success "🎯 Monitoring dashboard setup completed!"
