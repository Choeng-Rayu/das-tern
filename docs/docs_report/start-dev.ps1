# Quick Start Script for DasTern Development
# Run this script to start all services

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DasTern Development Quick Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "[1/5] Checking Docker Desktop..." -ForegroundColor Yellow
$dockerRunning = $false
try {
    docker info | Out-Null
    $dockerRunning = $true
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Desktop is NOT running!" -ForegroundColor Red
    Write-Host "   Please start Docker Desktop and run this script again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Start PostgreSQL and Redis
Write-Host ""
Write-Host "[2/5] Starting PostgreSQL and Redis..." -ForegroundColor Yellow
docker-compose up -d postgres redis

Write-Host "   Waiting 15 seconds for PostgreSQL to start..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# Check if containers are running
$postgresRunning = docker-compose ps --services --filter "status=running" | Select-String -Pattern "postgres"
if ($postgresRunning) {
    Write-Host "✓ PostgreSQL is running" -ForegroundColor Green
} else {
    Write-Host "✗ PostgreSQL failed to start" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Run database migration
Write-Host ""
Write-Host "[3/5] Running database migration..." -ForegroundColor Yellow
Set-Location backend_nestjs

$migrationResult = npx prisma migrate deploy 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Database migration completed" -ForegroundColor Green
} else {
    Write-Host "✗ Migration failed. This is OK if database is already up to date." -ForegroundColor Yellow
}

# Generate Prisma Client
Write-Host ""
Write-Host "[4/5] Generating Prisma Client..." -ForegroundColor Yellow
npx prisma generate | Out-Null
Write-Host "✓ Prisma Client generated" -ForegroundColor Green

# Start Backend Server
Write-Host ""
Write-Host "[5/5] Starting Backend Server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Backend server starting..." -ForegroundColor Cyan
Write-Host "   Keep this terminal open!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test the app:" -ForegroundColor Green
Write-Host "  1. Open a NEW terminal" -ForegroundColor White
Write-Host "  2. cd das_tern_mcp" -ForegroundColor White
Write-Host "  3. flutter run" -ForegroundColor White
Write-Host ""

npm run start:dev
