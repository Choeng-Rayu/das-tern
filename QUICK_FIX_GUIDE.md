# Quick Fix Guide - Endpoint Mismatch & Compilation Errors

## ✅ What I Fixed

### 1. Compilation Errors  
- Fixed `QRCode` import in `bakong_payment/src/bakong/khqr.ts`
- Fixed type imports in `bakong_payment/src/controllers/payment.controller.ts`
- Added Prisma postinstall script to `bakong_payment/package.json`

### 2. Endpoint Analysis
- ✅ **Flutter App** → **backend_nestjs**: Endpoints are CORRECTLY aligned
- ✅ **backend_nestjs** → **bakong_payment**: Communication is properly configured
- Created comprehensive endpoint documentation

## 📋 What You Need to Do

### Step 1: Fix Prisma Generation (bakong_payment)

```bash
cd /home/rayu/das-tern/bakong_payment

# Generate Prisma Client
npx prisma generate --schema=./prisma/schema.prisma

# Wait 10-15 seconds, then verify:
ls -la node_modules/.prisma/client/

# Build the service
npm run build

# Start development mode
npm run start:dev
```

**Expected output**: `🚀 Bakong Payment Service started on port 3002`

### Step 2: Start Backend NestJS

```bash
cd /home/rayu/das-tern/backend_nestjs

# Start development mode
npm run start:dev
```

**Expected output**: `🚀 Application is running on: http://localhost:3001/api/v1`

### Step 3: Fix Flutter Network Configuration

**File**: `das_tern_mcp/lib/utils/api_constants.dart`

Update the IP address to your computer's IP:

```dart
static const String hostIpAddress = '172.23.5.229'; // Update this!
```

**Find your IP**:
```bash
ip a | grep "inet " | grep -v 127.0.0.1
```

### Step 4: Configure Firewall (Fedora)

```bash
# Allow Flutter app to reach backend on port 3001
sudo firewall-cmd --add-port=3001/tcp --permanent
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

### Step 5: Test Connection

**From your phone's browser, navigate to**:
```
http://YOUR_IP:3001/api/v1/auth/health
```

Replace `YOUR_IP` with your computer's IP (e.g., `172.23.5.229`)

**Expected response**:
```json
{"status":"ok"}
```

## 🔍 Verifying Endpoints Are Aligned

### Flutter App Endpoints
```dart
// File: das_tern_mcp/lib/services/api_service.dart
POST   $baseUrl/bakong-payment/create
GET    $baseUrl/bakong-payment/status/:md5Hash  
GET    $baseUrl/bakong-payment/plans
GET    $baseUrl/bakong-payment/subscription

// Where baseUrl = http://172.23.5.229:3001/api/v1
```

### Backend NestJS Routes
```typescript
// File: backend_nestjs/src/modules/bakong-payment/bakong-payment.controller.ts
@Controller('bakong-payment')  // With global prefix 'api/v1'

POST   /api/v1/bakong-payment/create           ✅ Matches
GET    /api/v1/bakong-payment/status/:md5Hash  ✅ Matches
GET    /api/v1/bakong-payment/plans            ✅ Matches  
GET    /api/v1/bakong-payment/subscription     ✅ Matches
```

## ✅ Endpoints Are Correctly Aligned!

The mismatch you're experiencing is likely due to:
1. ❌ **Wrong IP address** in Flutter's `api_constants.dart`
2. ❌ **Firewall blocking** port 3001
3. ❌ **Phone and computer not on same WiFi network**

## 📊 Architecture Diagram

```
┌─────────────────────┐
│   Flutter App       │
│  (Physical Device)  │
│   172.23.5.229      │
└──────────┬──────────┘
           │ HTTP Request
           │ POST http://172.23.5.229:3001/api/v1/bakong-payment/create
           ↓
┌─────────────────────┐
│  Backend NestJS     │
│   Port: 3001        │
│   Prefix: api/v1    │
└──────────┬──────────┘
           │ Internal HTTP
           │ POST http://localhost:3002/api/payments/create
           ↓
┌─────────────────────┐
│ Bakong Payment      │
│ Service             │
│   Port: 3002        │
└─────────────────────┘
```

## 🎯 Common Issues & Solutions

### Issue 1: "Connection refused" on physical device

**Solution**:
```bash
# Check computer's IP
ip a | grep "inet "

# Update Flutter app
# Edit: das_tern_mcp/lib/utils/api_constants.dart
static const String hostIpAddress = 'YOUR_COMPUTER_IP';

# Open firewall
sudo firewall-cmd --add-port=3001/tcp --permanent
sudo firewall-cmd --reload
```

### Issue 2: "Endpoint not found" or "404"

**Solution**: Check backend is running with correct prefix
```bash
cd backend_nestjs
cat .env | grep -E "PORT|API_PREFIX"
# Should show:
# PORT=3001
# API_PREFIX=api/v1

npm run start:dev
```

### Issue 3: Backend can't reach Bakong service

**Solution**: Verify bakong_payment is running
```bash
cd bakong_payment
npm run start:dev

# Test from another terminal:
curl http://localhost:3002/api/health
```

## 📁 Key Files Modified

| File | Change | Purpose |
|------|--------|---------|
| `bakong_payment/src/bakong/khqr.ts` | Fixed QRCode import | Resolve TS2349 error |
| `bakong_payment/src/controllers/payment.controller.ts` | Fixed type import | Resolve TS1272 error |
| `bakong_payment/package.json` | Added postinstall script | Auto-generate Prisma client |
| **/ENDPOINT_ALIGNMENT.md** | New documentation | Complete endpoint reference |
| **bakong_payment/COMPILATION_FIXES.md** | New guide | Fix instructions |

## 🚀 Final Checklist

- [ ] Prisma client generated in bakong_payment
- [ ] bakong_payment service running on port 3002
- [ ] backend_nestjs running on port 3001  
- [ ] Flutter `api_constants.dart` has correct IP
- [ ] Firewall allows port 3001
- [ ] Can access `http://YOUR_IP:3001/api/v1/auth/health` from phone browser
- [ ] Phone and computer on same WiFi

## 📚 Documentation Created

1. **ENDPOINT_ALIGNMENT.md** - Complete endpoint documentation for all services
2. **bakong_payment/COMPILATION_FIXES.md** - Detailed compilation fix steps
3. **THIS FILE** - Quick reference guide

## Need Help?

Check the detailed documentation:
- Full endpoint reference: `/home/rayu/das-tern/ENDPOINT_ALIGNMENT.md`
- Compilation fixes: `/home/rayu/das-tern/bakong_payment/COMPILATION_FIXES.md`
