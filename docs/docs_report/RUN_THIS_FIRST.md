# 🚀 START SERVICES BEFORE TESTING

## ⚠️ IMPORTANT: Run these commands BEFORE testing the app!

### Step 1: Start Docker Desktop
- Open Docker Desktop application
- Wait until it says "Docker Desktop is running"

### Step 2: Start Database Services
```bash
cd D:\DasTern-Project\das-tern
docker-compose up -d postgres redis
```

Wait 10-15 seconds for PostgreSQL to fully start.

### Step 3: Run Database Migration (CRITICAL!)
```bash
cd backend_nestjs
npx prisma migrate deploy
npx prisma generate
```

This applies the new `hasUsedTrial` field to the database.

### Step 4: Start Backend Server
```bash
cd backend_nestjs
npm run start:dev
```

Keep this terminal running. You should see:
```
Nest application successfully started
```

### Step 5: Test Flutter App
```bash
cd das_tern_mcp
flutter run
```

---

## ✅ Verification

After completing all steps, the "Claim Free Trial" button should work without errors.

If you still see errors:
1. Check backend terminal for error messages
2. Verify PostgreSQL is running: `docker-compose ps`
3. Verify migration ran: `cd backend_nestjs && npx prisma migrate status`

---

## 🛑 Common Errors and Fixes

### "Failed to claim free trial"
- **Cause**: Database not running or migration not applied
- **Fix**: Follow steps 1-3 above

### "Connection refused" or "ECONNREFUSED"
- **Cause**: Backend server not running
- **Fix**: Run step 4 above

### "P1001: Can't reach database server"
- **Cause**: PostgreSQL container not running
- **Fix**: Run `docker-compose up -d postgres` and wait 15 seconds
