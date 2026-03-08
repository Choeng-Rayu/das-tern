# Fix "Cannot POST /api/v1/subscriptions/claim-trial" Error

## Problem Analysis

Based on the error logs:
```
[401] Unauthorized - No refresh token available
[404] Cannot POST /api/v1/subscriptions/claim-trial
```

**Root Causes:**
1. ❌ Backend Docker container has OLD code (doesn't include new `claim-trial` endpoint)
2. ❌ User is not logged in (401 Unauthorized error)

## Solution Steps

### Step 1: Rebuild Backend Docker Container

The backend is running in Docker with outdated code. Rebuild it to include the new endpoint:

```powershell
# Stop the backend container
cd d:\DasTern-Project\das-tern
docker-compose stop backend

# Rebuild backend image with new code
docker-compose build backend

# Start backend container
docker-compose up -d backend

# Verify it's running
docker-compose ps backend

# Check logs to confirm startup
docker-compose logs -f backend --tail=50
```

Wait for the log message: **"Nest application successfully started"**

Press `Ctrl+C` to exit logs.

### Step 2: Apply Database Migration

The new endpoint requires the `hasUsedTrial` field in the database:

```powershell
# Enter the backend container
docker exec -it dastern-backend sh

# Inside container: Run migration
npx prisma migrate deploy

# Generate Prisma client (if needed)
npx prisma generate

# Exit container
exit
```

### Step 3: Ensure User is Logged In

The app must have a valid authentication token:

1. **Open the app**
2. **Logout** (if logged in)
3. **Login again** or **Register new account**
4. **Navigate to Settings → Upgrade Plan**

### Step 4: Test Free Trial Claim

1. Verify you see **"Freemium"** plan at top
2. Tap green **"Claim 1-Month Free Trial"** button
3. Confirmation dialog appears
4. Tap **"Confirm"** button
5. ✅ Header should change to **"Premium"**
6. ✅ Trial countdown info should appear
7. ✅ Plan selection cards should be hidden

## Quick Fix Script

Run this PowerShell script to automate steps 1 & 2:

```powershell
# Save as: rebuild-backend.ps1
cd d:\DasTern-Project\das-tern

Write-Host "🔄 Stopping backend..." -ForegroundColor Yellow
docker-compose stop backend

Write-Host "🏗️  Rebuilding backend image..." -ForegroundColor Cyan
docker-compose build backend

Write-Host "🚀 Starting backend..." -ForegroundColor Green
docker-compose up -d backend

Write-Host "⏳ Waiting for backend to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "📊 Running migration..." -ForegroundColor Cyan
docker exec dastern-backend npx prisma migrate deploy

Write-Host "🔧 Generating Prisma client..." -ForegroundColor Cyan
docker exec dastern-backend npx prisma generate

Write-Host "✅ Backend ready!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Backend logs (Ctrl+C to exit):" -ForegroundColor Cyan
docker-compose logs -f backend --tail=50
```

## Expected Result

After successful claim:
- Header changes: **Freemium** → **Premium** (with ACTIVE badge)
- Shows trial countdown with large 72pt font
- Displays trial expiration date
- Shows list of Premium features unlocked
- Hides "Choose a Plan" section during trial
- Button changes to disabled "Trial Already Claimed"

## Troubleshooting

**If 404 error persists:**
```powershell
# Check if endpoint exists in running container
docker exec dastern-backend cat src/modules/subscriptions/subscriptions.controller.ts | grep "claim-trial"
```

**If 401 error persists:**
- Force logout and login again
- Clear app data: Settings → Clear Cache
- Uninstall and reinstall app

**If database error occurs:**
```powershell
# Verify migration applied
docker exec dastern-backend npx prisma migrate status
```
