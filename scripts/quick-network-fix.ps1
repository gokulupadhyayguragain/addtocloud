# =============================================================================
# AddToCloud - Quick Network Fix and Startup
# =============================================================================

Write-Host "AddToCloud Network Fix" -ForegroundColor Magenta
Write-Host "======================" -ForegroundColor Magenta

# Stop any existing containers that might conflict
Write-Host "Stopping conflicting containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.databases.yml down 2>$null
docker-compose -f docker-compose.full.yml down 2>$null

# Clean up any hanging processes on ports
Write-Host "Cleaning up ports..." -ForegroundColor Yellow
$ports = @(3000, 8080, 8888, 5433, 27018, 6380, 80, 443, 9090, 3001)
foreach ($port in $ports) {
    try {
        $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($process) {
            $pid = $process.OwningProcess
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            Write-Host "   Freed port $port" -ForegroundColor Green
        }
    } catch {
        # Port not in use, continue
    }
}

# Create network if it doesn't exist
Write-Host "Setting up Docker network..." -ForegroundColor Yellow
docker network create addtocloud-network 2>$null

# Start databases first
Write-Host "Starting databases..." -ForegroundColor Yellow
docker-compose -f docker-compose.databases.yml up -d

# Wait for databases
Write-Host "Waiting for databases (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check database health
Write-Host "Checking database health..." -ForegroundColor Yellow
$dbHealthy = $true
try {
    # Test PostgreSQL
    $pgResult = docker exec addtocloud-postgres pg_isready -U addtocloud -d addtocloud_prod 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   PostgreSQL is ready" -ForegroundColor Green
    } else {
        Write-Host "   PostgreSQL not ready" -ForegroundColor Red
        $dbHealthy = $false
    }
    
    # Test MongoDB
    $mongoResult = docker exec addtocloud-mongodb mongosh --eval "db.adminCommand('ping')" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   MongoDB is ready" -ForegroundColor Green
    } else {
        Write-Host "   MongoDB not ready" -ForegroundColor Red
        $dbHealthy = $false
    }
    
    # Test Redis
    $redisResult = docker exec addtocloud-redis redis-cli --raw incr ping 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Redis is ready" -ForegroundColor Green
    } else {
        Write-Host "   Redis not ready" -ForegroundColor Red
        $dbHealthy = $false
    }
} catch {
    Write-Host "   Database health check failed" -ForegroundColor Yellow
}

# Fix credential service environment
Write-Host "Updating credential service configuration..." -ForegroundColor Yellow
$envContent = @"
# Database Configuration
DATABASE_URL=postgres://addtocloud:addtocloud_secure_2024@localhost:5433/addtocloud_prod?sslmode=disable
MONGODB_URL=mongodb://addtocloud:addtocloud_mongo_2024@localhost:27018/addtocloud_logs
REDIS_URL=redis://:addtocloud_redis_2024@localhost:6380/0

# Server Configuration
PORT=8080
GIN_MODE=release

# Email Configuration (update with real credentials)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_FROM=info@addtocloud.tech
SMTP_TO=admin@addtocloud.tech
SMTP_USER=info@addtocloud.tech
SMTP_PASSWORD=your_app_password_here

# Feature Flags
ENABLE_EMAIL_NOTIFICATIONS=true
ENABLE_MANUAL_APPROVAL=true
ENABLE_AUTO_PROVISIONING=false

# Security
JWT_SECRET=addtocloud_jwt_secret_key_2024_very_secure
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:80

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
"@

$envPath = "apps/credential-service/.env"
$envContent | Out-File -FilePath $envPath -Encoding UTF8
Write-Host "   Environment updated" -ForegroundColor Green

# Start credential service with proper networking
Write-Host "Starting credential service..." -ForegroundColor Yellow
Push-Location "apps/credential-service"
try {
    # Build the service
    go mod tidy
    go build -o bin/credential-service main.go
    
    # Start in background
    Start-Process -FilePath ".\bin\credential-service.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 10
    
    # Test the service
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "   Credential service is running" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Credential service may need manual start" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Failed to build credential service" -ForegroundColor Red
}
Pop-Location

# Test network connectivity
Write-Host "Testing network connectivity..." -ForegroundColor Yellow
$endpoints = @{
    "PostgreSQL Admin" = "http://localhost:5050"
    "MongoDB Admin" = "http://localhost:8081"
    "Redis Admin" = "http://localhost:8001"
    "Credential Service" = "http://localhost:8080/health"
}

foreach ($name in $endpoints.Keys) {
    try {
        $response = Invoke-WebRequest -Uri $endpoints[$name] -UseBasicParsing -TimeoutSec 5
        Write-Host "   $name accessible" -ForegroundColor Green
    } catch {
        Write-Host "   $name not accessible" -ForegroundColor Red
    }
}

# Final status
Write-Host ""
Write-Host "Quick Fix Summary" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service Status:" -ForegroundColor White
Write-Host "   PostgreSQL:       localhost:5433" -ForegroundColor Gray
Write-Host "   MongoDB:          localhost:27018" -ForegroundColor Gray
Write-Host "   Redis:            localhost:6380" -ForegroundColor Gray
Write-Host "   Credential API:   localhost:8080" -ForegroundColor Gray
Write-Host ""
Write-Host "Admin Interfaces:" -ForegroundColor White
Write-Host "   pgAdmin:          http://localhost:5050" -ForegroundColor Gray
Write-Host "   Mongo Express:    http://localhost:8081" -ForegroundColor Gray
Write-Host "   RedisInsight:     http://localhost:8001" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "   1. Test credential form at: http://localhost:8080" -ForegroundColor Gray
Write-Host "   2. View logs: docker-compose -f docker-compose.databases.yml logs -f" -ForegroundColor Gray
Write-Host "   3. Check database: http://localhost:5050" -ForegroundColor Gray
Write-Host ""

# Open browser to credential service
Write-Host "Opening credential service in browser..." -ForegroundColor Yellow
Start-Process "http://localhost:8080"

Write-Host "Quick fix completed! Test the credential form now." -ForegroundColor Green
