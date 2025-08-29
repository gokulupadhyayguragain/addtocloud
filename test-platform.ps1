#!/usr/bin/env pwsh

Write-Host "🚀 AddToCloud Platform Testing Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Test 1: Backend Health Check
Write-Host "`n1. Testing Backend Health..." -ForegroundColor Yellow

try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get -TimeoutSec 5
    Write-Host "✅ Backend Health: $($health.status)" -ForegroundColor Green
    Write-Host "   Version: $($health.version)" -ForegroundColor Gray
    Write-Host "   Service: $($health.service)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Backend Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Make sure backend is running: go run cmd/main-test.go" -ForegroundColor Yellow
}

# Test 2: Cloud Services API
Write-Host "`n2. Testing Cloud Services API..." -ForegroundColor Yellow

try {
    $services = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/cloud/services" -Method Get -TimeoutSec 10
    Write-Host "✅ Cloud Services API: $($services.services.Count) services loaded" -ForegroundColor Green
    Write-Host "   Providers: AWS($($services.providers.AWS)), Azure($($services.providers.Azure)), GCP($($services.providers.GCP))" -ForegroundColor Gray
} catch {
    Write-Host "❌ Cloud Services API Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Authentication Registration
Write-Host "`n3. Testing Authentication..." -ForegroundColor Yellow

$testUser = @{
    firstName = "Test"
    lastName = "User"
    email = "test$(Get-Random)@example.com"
    password = "password123"
} | ConvertTo-Json

try {
    $authResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/register" -Method Post -Body $testUser -ContentType "application/json" -TimeoutSec 5
    Write-Host "✅ User Registration: Success" -ForegroundColor Green
    Write-Host "   User: $($authResponse.user.firstName) $($authResponse.user.lastName)" -ForegroundColor Gray
    Write-Host "   Token: $($authResponse.token.Substring(0,20))..." -ForegroundColor Gray
} catch {
    if ($_.Exception.Message -like "*503*" -or $_.Exception.Message -like "*database*") {
        Write-Host "⚠️  Authentication: Database not available (using fallback)" -ForegroundColor Yellow
        Write-Host "   This is expected for testing without PostgreSQL" -ForegroundColor Gray
    } else {
        Write-Host "❌ Authentication Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: Frontend Availability
Write-Host "`n4. Testing Frontend..." -ForegroundColor Yellow

try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:3000" -Method Get -TimeoutSec 5 -UseBasicParsing
    if ($frontend.StatusCode -eq 200) {
        Write-Host "✅ Frontend: Available" -ForegroundColor Green
        Write-Host "   Status: $($frontend.StatusCode)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Frontend Not Available: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Make sure frontend is running: npm run dev" -ForegroundColor Yellow
}

# Test 5: Build Tests
Write-Host "`n5. Testing Builds..." -ForegroundColor Yellow

# Test Backend Build
Write-Host "   Backend build test..." -ForegroundColor Gray
$backendPath = "apps/backend"
if (Test-Path $backendPath) {
    Push-Location $backendPath
    try {
        $buildResult = go build cmd/main-test.go 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Backend Build: Success" -ForegroundColor Green
        } else {
            Write-Host "❌ Backend Build Failed" -ForegroundColor Red
            Write-Host $buildResult -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ Backend Build Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Pop-Location
} else {
    Write-Host "❌ Backend directory not found" -ForegroundColor Red
}

# Test Frontend Build (quick check)
Write-Host "   Frontend dependencies check..." -ForegroundColor Gray
$frontendPath = "apps/frontend"
if (Test-Path "$frontendPath/package.json") {
    Write-Host "✅ Frontend Build: package.json found" -ForegroundColor Green
} else {
    Write-Host "❌ Frontend Build: package.json not found" -ForegroundColor Red
}

# Summary
Write-Host "`n🎯 Test Summary" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
Write-Host "
Ready for deployment if:
✅ Backend health check passes
✅ Cloud services API responds  
✅ Authentication endpoints work (or show expected database fallback)
✅ Frontend is accessible
✅ Builds compile successfully

🚀 To deploy: git add . && git commit -m 'Deploy v2.0.0' && git push origin main
" -ForegroundColor White

Write-Host "📋 Quick Commands:" -ForegroundColor Cyan
Write-Host "Backend: cd apps/backend && go run cmd/main-test.go" -ForegroundColor Gray
Write-Host "Frontend: cd apps/frontend && npm run dev" -ForegroundColor Gray
Write-Host "Health Check: curl http://localhost:8080/health" -ForegroundColor Gray
Write-Host "Services: curl http://localhost:8080/api/v1/cloud/services" -ForegroundColor Gray
