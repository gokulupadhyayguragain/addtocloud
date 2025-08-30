# AddToCloud Development Server
# Run both frontend and backend in development mode

Write-Host "🚀 Starting AddToCloud Development Environment..." -ForegroundColor Green

# Set environment variables
$env:NODE_ENV = "development"
$env:NEXT_PUBLIC_API_BASE_URL = "http://localhost:8080"

# Check if Go is installed
try {
    $goVersion = go version
    Write-Host "✅ Go found: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Go not found. Please install Go from https://golang.org/" -ForegroundColor Red
    exit 1
}

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Change to backend directory and start Go server in background
Write-Host "🔧 Starting Go backend server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\Users\gokul\instant_upload\addtocloud\backend'; Write-Host '🔥 Starting AddToCloud Admin API Server...' -ForegroundColor Cyan; go run cmd/main-admin-system.go"

# Wait a moment for backend to start
Start-Sleep -Seconds 3

# Change to frontend directory and install dependencies if needed
Write-Host "📦 Checking frontend dependencies..." -ForegroundColor Yellow
Set-Location "c:\Users\gokul\instant_upload\addtocloud\frontend"

if (!(Test-Path "node_modules")) {
    Write-Host "📥 Installing frontend dependencies..." -ForegroundColor Yellow
    npm install
}

# Start frontend development server
Write-Host "🌐 Starting Next.js frontend server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "🎯 Application URLs:" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   Backend API: http://localhost:8080" -ForegroundColor White
Write-Host "   Admin Panel: http://localhost:3000/admin-login" -ForegroundColor White
Write-Host ""
Write-Host "🔐 Default Admin Credentials:" -ForegroundColor Magenta
Write-Host "   Email: admin@addtocloud.tech" -ForegroundColor White
Write-Host "   Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "📝 Manual Approval Workflow:" -ForegroundColor Green
Write-Host "   1. Users request access at /request-access" -ForegroundColor White
Write-Host "   2. Admin reviews requests at /admin" -ForegroundColor White
Write-Host "   3. Approved users get dedicated EC2 instances" -ForegroundColor White
Write-Host ""

npm run dev
