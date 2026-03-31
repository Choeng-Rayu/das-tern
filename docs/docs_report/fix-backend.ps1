# Quick Fix: Rebuild Backend & Apply Migration
# Run this script whenever you update backend code

cd d:\DasTern-Project\das-tern

Write-Host "🔄 Stopping backend..." -ForegroundColor Yellow
docker-compose stop backend

Write-Host "🏗️  Rebuilding backend with new code..." -ForegroundColor Cyan
docker-compose build backend

Write-Host "🚀 Starting backend..." -ForegroundColor Green
docker-compose up -d backend

Write-Host "⏳ Waiting 10 seconds for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "📊 Applying database migration..." -ForegroundColor Cyan
docker exec dastern-backend npx prisma migrate deploy

Write-Host "🔧 Generating Prisma client..." -ForegroundColor Cyan
docker exec dastern-backend npx prisma generate

Write-Host ""
Write-Host "✅ DONE! Backend is ready with claim-trial endpoint" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open app and LOGIN (or LOGOUT and LOGIN again)" -ForegroundColor White
Write-Host "  2. Go to Settings → Upgrade Plan" -ForegroundColor White
Write-Host "  3. Tap green 'Claim 1-Month Free Trial' button" -ForegroundColor White
Write-Host "  4. Tap 'Confirm' in dialog" -ForegroundColor White
Write-Host "  5. Header should change to 'Premium' with trial info" -ForegroundColor White
Write-Host ""
Write-Host "🐛 View backend logs:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f backend --tail=100" -ForegroundColor Gray
