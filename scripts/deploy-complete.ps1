# =============================================================================
# AddToCloud - Complete Production Deployment Script
# =============================================================================

param(
    [string]$Environment = "production",
    [switch]$StopExisting = $false,
    [switch]$CleanStart = $false,
    [switch]$SkipBuild = $false,
    [switch]$DeployDatabases = $true,
    [switch]$DeployServices = $true,
    [switch]$DeployMonitoring = $true
)

# Color functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "⚠️ $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "ℹ️ $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "🚀 $Message" -ForegroundColor Magenta }

# Check prerequisites
function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    $prerequisites = @{
        "Docker" = "docker --version"
        "Docker Compose" = "docker-compose --version"
        "Node.js" = "node --version"
        "NPM" = "npm --version"
        "Go" = "go version"
    }
    
    $missing = @()
    foreach ($tool in $prerequisites.Keys) {
        try {
            Invoke-Expression $prerequisites[$tool] | Out-Null
            Write-Success "$tool is installed"
        } catch {
            Write-Error "$tool is not installed or not in PATH"
            $missing += $tool
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "Missing prerequisites: $($missing -join ', ')"
        Write-Info "Please install missing tools and try again"
        exit 1
    }
}

# Stop existing containers
function Stop-ExistingContainers {
    if ($StopExisting) {
        Write-Step "Stopping existing containers..."
        
        # Stop main application stack
        if (Test-Path "docker-compose.full.yml") {
            docker-compose -f docker-compose.full.yml down
        }
        
        # Stop database stack
        if (Test-Path "docker-compose.databases.yml") {
            docker-compose -f docker-compose.databases.yml down
        }
        
        # Remove orphaned containers
        docker container prune -f
        
        if ($CleanStart) {
            Write-Warning "Cleaning up volumes and networks..."
            docker volume prune -f
            docker network prune -f
        }
        
        Write-Success "Existing containers stopped"
    }
}

# Build applications
function Build-Applications {
    if (-not $SkipBuild) {
        Write-Step "Building applications..."
        
        # Build frontend
        Write-Info "Building frontend..."
        Push-Location "apps/frontend"
        try {
            npm ci
            npm run build
            Write-Success "Frontend built successfully"
        } catch {
            Write-Error "Frontend build failed: $($_.Exception.Message)"
            Pop-Location
            exit 1
        }
        Pop-Location
        
        # Build backend
        Write-Info "Building backend..."
        Push-Location "apps/backend"
        try {
            go mod download
            go mod tidy
            go build -o bin/server ./cmd/main.go
            Write-Success "Backend built successfully"
        } catch {
            Write-Error "Backend build failed: $($_.Exception.Message)"
            Pop-Location
            exit 1
        }
        Pop-Location
        
        # Build credential service
        Write-Info "Building credential service..."
        Push-Location "apps/credential-service"
        try {
            go mod download
            go mod tidy
            go build -o bin/credential-service ./main.go
            Write-Success "Credential service built successfully"
        } catch {
            Write-Error "Credential service build failed: $($_.Exception.Message)"
            Pop-Location
            exit 1
        }
        Pop-Location
    }
}

# Deploy databases
function Deploy-Databases {
    if ($DeployDatabases) {
        Write-Step "Deploying database infrastructure..."
        
        # Start databases first
        docker-compose -f docker-compose.databases.yml up -d
        
        # Wait for databases to be ready
        Write-Info "Waiting for databases to be ready..."
        Start-Sleep -Seconds 30
        
        # Check database health
        $dbServices = @("postgres", "mongodb", "redis")
        foreach ($service in $dbServices) {
            $retries = 0
            $maxRetries = 10
            do {
                $health = docker-compose -f docker-compose.databases.yml ps --services --filter "status=running" | Where-Object { $_ -eq $service }
                if ($health) {
                    Write-Success "$service is healthy"
                    break
                }
                $retries++
                Write-Warning "Waiting for $service to be ready... (attempt $retries/$maxRetries)"
                Start-Sleep -Seconds 10
            } while ($retries -lt $maxRetries)
            
            if ($retries -eq $maxRetries) {
                Write-Error "$service failed to start properly"
                exit 1
            }
        }
        
        Write-Success "All databases are running and healthy"
    }
}

# Deploy services
function Deploy-Services {
    if ($DeployServices) {
        Write-Step "Deploying application services..."
        
        # Deploy the full stack
        docker-compose -f docker-compose.full.yml up -d --build
        
        # Wait for services to be ready
        Write-Info "Waiting for services to be ready..."
        Start-Sleep -Seconds 45
        
        # Health check all services
        $services = @{
            "Backend API" = "http://localhost:8080/health"
            "Frontend" = "http://localhost:3000"
            "Credential Service" = "http://localhost:8888/health"
            "NGINX" = "http://localhost:80/health"
        }
        
        foreach ($serviceName in $services.Keys) {
            $url = $services[$serviceName]
            $retries = 0
            $maxRetries = 10
            do {
                try {
                    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
                    if ($response.StatusCode -eq 200) {
                        Write-Success "$serviceName is healthy"
                        break
                    }
                } catch {
                    # Service not ready yet
                }
                $retries++
                Write-Warning "Waiting for $serviceName to be ready... (attempt $retries/$maxRetries)"
                Start-Sleep -Seconds 10
            } while ($retries -lt $maxRetries)
            
            if ($retries -eq $maxRetries) {
                Write-Warning "$serviceName may not be fully ready (check logs: docker-compose -f docker-compose.full.yml logs $serviceName)"
            }
        }
    }
}

# Deploy monitoring
function Deploy-Monitoring {
    if ($DeployMonitoring) {
        Write-Step "Setting up monitoring and observability..."
        
        # Monitoring services are included in the full stack
        Write-Info "Monitoring services included in main deployment"
        
        # Verify monitoring endpoints
        $monitoringServices = @{
            "Prometheus" = "http://localhost:9090"
            "Grafana" = "http://localhost:3001"
        }
        
        foreach ($serviceName in $monitoringServices.Keys) {
            $url = $monitoringServices[$serviceName]
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    Write-Success "$serviceName is accessible at $url"
                }
            } catch {
                Write-Warning "$serviceName may not be ready yet at $url"
            }
        }
    }
}

# Display deployment information
function Show-DeploymentInfo {
    Write-Step "Deployment Information"
    Write-Host ""
    Write-Host "🌐 Application URLs:" -ForegroundColor Cyan
    Write-Host "   Frontend:           http://localhost:3000" -ForegroundColor White
    Write-Host "   Backend API:        http://localhost:8080" -ForegroundColor White
    Write-Host "   Credential Service: http://localhost:8888" -ForegroundColor White
    Write-Host "   Load Balancer:      http://localhost:80" -ForegroundColor White
    Write-Host ""
    Write-Host "🗄️ Database URLs:" -ForegroundColor Cyan
    Write-Host "   PostgreSQL:    localhost:5433 (user: addtocloud)" -ForegroundColor White
    Write-Host "   MongoDB:       localhost:27018 (user: addtocloud)" -ForegroundColor White
    Write-Host "   Redis:         localhost:6380" -ForegroundColor White
    Write-Host ""
    Write-Host "🛠️ Admin Interfaces:" -ForegroundColor Cyan
    Write-Host "   pgAdmin:       http://localhost:5050 (admin@addtocloud.tech)" -ForegroundColor White
    Write-Host "   Mongo Express: http://localhost:8081" -ForegroundColor White
    Write-Host "   RedisInsight:  http://localhost:8001" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Monitoring:" -ForegroundColor Cyan
    Write-Host "   Prometheus:    http://localhost:9090" -ForegroundColor White
    Write-Host "   Grafana:       http://localhost:3001 (admin/addtocloud_admin_2024)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Useful Commands:" -ForegroundColor Cyan
    Write-Host "   View logs:     docker-compose -f docker-compose.full.yml logs -f [service]" -ForegroundColor Gray
    Write-Host "   Check status:  docker-compose -f docker-compose.full.yml ps" -ForegroundColor Gray
    Write-Host "   Restart:       docker-compose -f docker-compose.full.yml restart [service]" -ForegroundColor Gray
    Write-Host "   Stop all:      docker-compose -f docker-compose.full.yml down" -ForegroundColor Gray
    Write-Host ""
}

# Test deployment
function Test-Deployment {
    Write-Step "Running deployment tests..."
    
    # Test API endpoints
    $tests = @{
        "Backend Health" = "http://localhost:8080/health"
        "Frontend" = "http://localhost:3000"
        "Credential Health" = "http://localhost:8888/health"
        "Load Balancer" = "http://localhost:80/health"
        "Database Admin" = "http://localhost:5050"
    }
    
    $passed = 0
    $total = $tests.Count
    
    foreach ($testName in $tests.Keys) {
        try {
            $response = Invoke-WebRequest -Uri $tests[$testName] -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
                Write-Success "$testName test passed"
                $passed++
            } else {
                Write-Warning "$testName test returned status $($response.StatusCode)"
            }
        } catch {
            Write-Error "$testName test failed: $($_.Exception.Message)"
        }
    }
    
    Write-Host ""
    Write-Host "🧪 Test Results: $passed/$total tests passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
    
    if ($passed -eq $total) {
        Write-Success "All tests passed! Deployment is ready for use."
    } else {
        Write-Warning "Some tests failed. Check logs for more details."
    }
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "🚀 AddToCloud Production Deployment" -ForegroundColor Magenta
    Write-Host "====================================" -ForegroundColor Magenta
    Write-Host "Environment: $Environment" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Test-Prerequisites
        Stop-ExistingContainers
        Build-Applications
        Deploy-Databases
        Deploy-Services
        Deploy-Monitoring
        
        Write-Host ""
        Write-Success "🎉 Deployment completed successfully!"
        
        Show-DeploymentInfo
        Test-Deployment
        
    } catch {
        Write-Error "Deployment failed: $($_.Exception.Message)"
        Write-Info "Check logs for more details: docker-compose -f docker-compose.full.yml logs"
        exit 1
    }
}

# Run main function
Main
