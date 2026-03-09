# Run Backend Locally (Without Docker)
# This script starts the NestJS backend with the LATEST code

cd d:\DasTern-Project\das-tern\backend_nestjs

Write-Host "🔧 Installing dependencies..." -ForegroundColor Cyan
npm install

Write-Host "📊 Running database migration..." -ForegroundColor Cyan
npx prisma migrate deploy

Write-Host "🔧 Generating Prisma client..." -ForegroundColor Cyan
npx prisma generate

Write-Host "🚀 Starting backend server..." -ForegroundColor Green
Write-Host ""
Write-Host "✅ Backend will start on http://localhost:3001/api/v1" -ForegroundColor Green
Write-Host "✅ This includes the NEW claim-trial endpoint!" -ForegroundColor Green
Write-Host ""
Write-Host "🔴 Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start in development mode (with hot reload)
npm run start:dev
