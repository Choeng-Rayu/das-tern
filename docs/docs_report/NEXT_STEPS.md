# NEXT STEPS: Start Backend and Test Free Trial

## Current Status

✅ **Code Complete**: The claim-trial feature is fully implemented in:
   - Backend: `/backend_nestjs/src/modules/subscriptions/subscriptions.controller.ts`
   - Database: Migration applied with `hasUsedTrial` field
   - Frontend: UI with green button, confirmation dialog, and trial display

❌ **Backend Not Running**: The backend server needs to be started manually

## Step 1: Start the Backend Server

**Option A: Manual Start (Recommended)**

1. Open a NEW PowerShell window
2. Run these commands:
```powershell
cd d:\DasTern-Project\das-tern\backend_nestjs
npm run start:dev
```

3. Wait for the message: **"Nest application successfully started"**
4. Keep this window open while testing

**Option B: Use the Automation Script**

```powershell
.\start-backend-local.ps1
```

## Step 2: Verify Backend is Running

In a NEW PowerShell window, test the endpoint:

```powershell
# Test claim-trial endpoint (should get 401 Unauthorized, NOT 404)
curl http://localhost:3001/api/v1/subscriptions/claim-trial `
  -Method POST `
  -Headers @{"Authorization"="Bearer test"} `
  -ContentType "application/json" `
  -Body "{}"
```

**Expected Result:**
- ❌ 404 = Backend has old code (endpoint doesn't exist)
- ✅ 401 Unauthorized = Backend has NEW code with claim-trial endpoint!

## Step 3: Test in Flutter App

1. **Open the app** on your device/emulator
2. **Login** (or register new account)
   - If you see 401 errors, LOGOUT and LOGIN again to get fresh token
3. **Navigate to**: Settings → Upgrade Plan
4. **You should see**:
   - Blue card showing "Freemium" plan
   - Green button: "Claim 1-Month Free Trial"

5. **Tap the green button**
6. **Confirmation dialog appears** with:
   - "Premium Trial" title
   - Feature list
   - "Confirm" button

7. **Tap "Confirm"**
8. **Expected result**:
   - ✅ Header changes from "Freemium" to "Premium"
   - ✅ Shows trial countdown (e.g., "28 days remaining")
   - ✅ Shows trial expiration date
   - ✅ Shows "Premium features unlocked" message
   - ✅ "Choose a Plan" section is hidden
   - ✅ Button changes to disabled "Trial Already Claimed"

## Troubleshooting

### If backend won't start:

```powershell
# Check for errors
cd d:\DasTern-Project\das-tern\backend_nestjs
npm run build
```

### If you get "port 3001 already in use":

```powershell
# Find and kill the process
netstat -ano | Select-String ":3001"
# Note the PID (last number), then:
Stop-Process -Id <PID> -Force
```

### If Flutter app shows 404 error:

- Backend is not running or has old code
- Restart backend with `npm run start:dev`

### If Flutter app shows 401 Unauthorized:

- Logout and login again to get fresh JWT token
- Or restart the app

### If claim button doesn't appear:

- You already claimed the trial (check database)
- You're already on Premium tier  

## Database Check (Optional)

To verify trial was claimed:

```powershell
cd d:\DasTern-Project\das-tern
docker exec -it dastern-postgres psql -U dastern_user -d dastern -c "SELECT id, tier, \"hasUsedTrial\", \"expiresAt\" FROM subscriptions WHERE \"hasUsedTrial\" = true;"
```

## Success Indicators

✅ Backend shows:  
   ```
   [RoutesResolver] SubscriptionsController {/api/v1/subscriptions}: +1ms
   [RouterExplorer] Mapped {/api/v1/subscriptions/claim-trial, POST} route +0ms
   ```

✅ Curl test returns 401 (not 404)

✅ App shows "Premium" with trial countdown after claiming

✅ Database shows `hasUsedTrial = true` and `expiresAt` 30 days from now

## What's Next?

After successfully testing:
1. Commit your changes to Git
2. Consider building and testing the Docker image
3. Test on multiple devices/accounts
4. Verify trial expiration behavior after 30 days

---

**Need Help?** 
- Check backend terminal for error messages
- Check Flutter app logs for API call details
- Verify PostgreSQL container is running: `docker-compose ps postgres`
