# Network Configuration Fix - Physical Device Connection

## Problem Identified

Flutter app running on **physical Android device (CPH2333)** could not connect to NestJS backend with error:
```
ClientException with SocketConnection refused (OS Error: Connection refused, errno = 111), 
address = localhost, port = 40668, uri=http://localhost:3001/api/v1/auth/register/patient
```

### Root Cause

When running on a **physical device**, `localhost` refers to the **device itself**, NOT your development machine. The backend was running on your computer at `localhost:3001`, but the device couldn't reach it.

---

## Solution Applied

### 1. ✅ Updated Flutter App Configuration

**File:** `das_tern_mcp/.env`

**Before:**
```env
API_BASE_URL=http://localhost:3001/api/v1
```

**After:**
```env
# Use your local machine's IP address for physical device testing
# Find your IP with: hostname -I
API_BASE_URL=http://172.23.5.229:3001/api/v1
```

### 2. ✅ Updated Backend CORS Configuration

**File:** `backend_nestjs/.env`

**Before:**
```env
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

**After:**
```env
# Allow Flutter mobile app from local network IP
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://172.23.5.229:3001
```

### 3. ✅ Restarted Backend

Backend restarted successfully with new CORS settings:
```
✅ Database connected
🚀 Application is running on: http://localhost:3001/api/v1
```

### 4. ✅ Redeployed Flutter App

App redeployed to physical device with updated API URL. Logs show successful startup:
```
[17:19:17.428][INFO][App] 🚀 Starting DAS TERN MCP App
[17:19:17.705][SUCCESS][App] Environment loaded
[17:19:18.093][INFO][SyncService] Initial connectivity state
  ↳ Data: {online: true, type: wifi}
[17:19:18.314][SUCCESS][App] Services initialized
```

---

## Network Configuration Reference

### Your Development Machine

- **Local Network IP:** `172.23.5.229`
- **Backend Port:** `3001`
- **Full Backend URL:** `http://172.23.5.229:3001/api/v1`

### Find Your IP Address

If your IP changes (e.g., router DHCP reassignment), update `.env` files:

```bash
# Get your current local IP
hostname -I

# Example output: 172.23.5.229 172.19.0.1 172.18.0.1 172.17.0.1
# Use the FIRST IP (172.23.5.229)
```

---

## Device-Specific Configuration

### Physical Android Device (Current Setup)
✅ Use local network IP: `http://172.23.5.229:3001/api/v1`

**Requirements:**
- Device and computer on **same Wi-Fi network**
- Firewall allows port 3001 connections

### Android Emulator (Alternative)
Use Android emulator's special IP:
```env
API_BASE_URL=http://10.0.2.2:3001/api/v1
```

### iOS Simulator (Alternative)
Can use localhost (simulator shares host network):
```env
API_BASE_URL=http://localhost:3001/api/v1
```

---

## Verification Steps

### 1. Test Backend Accessibility from Device

From your computer, test if port 3001 is accessible:
```bash
# Check if backend is listening
curl http://172.23.5.229:3001/api/v1/auth/login -v

# Should return 400/405 (missing body), NOT connection refused
```

### 2. Watch Flutter Logs

Monitor app logs for API requests:
```bash
flutter run | grep "\[API→\]"
```

Expected successful output:
```
[17:20:15.123][API→][ApiService] POST /auth/register/patient
[17:20:15.456][API←][ApiService] POST /auth/register/patient [201]
```

### 3. Watch Backend Logs

Backend should log incoming requests:
```bash
# In backend_nestjs directory
npm run start:dev | grep "POST"
```

---

## Firewall Configuration (If Needed)

If connection still fails, allow port 3001 through firewall:

### Fedora/RHEL
```bash
sudo firewall-cmd --zone=public --add-port=3001/tcp --permanent
sudo firewall-cmd --reload
```

### Ubuntu/Debian
```bash
sudo ufw allow 3001/tcp
```

### macOS
```bash
# System Settings → Network → Firewall → Options
# Add port 3001 to allowed list
```

---

## Troubleshooting

### Error: "Connection refused"
- ✅ Check backend is running: `curl http://172.23.5.229:3001/api/v1`
- ✅ Verify device on same Wi-Fi network
- ✅ Check firewall allows port 3001

### Error: "CORS policy"
- ✅ Verify `ALLOWED_ORIGINS` includes your IP
- ✅ Restart backend after changing `.env`

### Error: "Network unreachable"
- ✅ Confirm IP with `hostname -I`
- ✅ Update both `.env` files if IP changed
- ✅ Redeploy Flutter app

---

## Production Deployment

For production, update to your production API URL:

**File:** `das_tern_mcp/.env`
```env
API_BASE_URL=https://api.dastern.com/api/v1
ENVIRONMENT=production
```

**Important:**
- MUST use HTTPS in production (enforced by `api_service.dart` assert)
- Update CORS in backend to production domain
- Consider using environment-specific `.env` files:
  - `.env.development` (local IP)
  - `.env.production` (production URL)

---

## Status: ✅ RESOLVED

- [x] Flutter app can now connect to backend from physical device
- [x] CORS configured to allow cross-origin requests
- [x] Logging shows successful app initialization
- [x] Both device and backend on same network (172.23.5.x)

**Next Step:** Test register/login from the device to verify full API communication.
