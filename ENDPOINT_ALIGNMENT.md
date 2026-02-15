# Endpoint Alignment Documentation

## Architecture Overview

```
Flutter App (Physical Device) 
    ↓ HTTP
Backend NestJS (Port 3001)
    ↓ HTTP
Bakong Payment Service (Port 3002)
```

## 1. Flutter Mobile App Configuration

**File**: `das_tern_mcp/lib/utils/api_constants.dart`

```dart
hostIpAddress: '172.23.5.229'  // Your computer's IP
apiPort: '3001'
apiPrefix: 'api/v1'
baseUrl: 'http://172.23.5.229:3001/api/v1'
```

### Flutter Bakong Payment Endpoints

**File**: `das_tern_mcp/lib/services/api_service.dart`

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/bakong-payment/create` | Create payment & get QR code |
| GET | `/bakong-payment/status/:md5Hash` | Check payment status |
| GET | `/bakong-payment/plans` | Get available plans |
| GET | `/bakong-payment/subscription` | Get user's subscription |

**Full URLs**:
- `http://172.23.5.229:3001/api/v1/bakong-payment/create`
- `http://172.23.5.229:3001/api/v1/bakong-payment/status/:md5Hash`
- `http://172.23.5.229:3001/api/v1/bakong-payment/plans`
- `http://172.23.5.229:3001/api/v1/bakong-payment/subscription`

---

## 2. Backend NestJS (Main Backend)

**Port**: 3001  
**Global Prefix**: `api/v1`  
**File**: `backend_nestjs/src/modules/bakong-payment/bakong-payment.controller.ts`

### Bakong Payment Endpoints

| Method | Controller Route | Full Path | Auth | Purpose |
|--------|-----------------|-----------|------|---------|
| POST | `/bakong-payment/create` | `/api/v1/bakong-payment/create` | JWT | Create payment |
| GET | `/bakong-payment/status/:md5Hash` | `/api/v1/bakong-payment/status/:md5Hash` | JWT | Check status |
| GET | `/bakong-payment/plans` | `/api/v1/bakong-payment/plans` | JWT | Get plans |
| GET | `/bakong-payment/subscription` | `/api/v1/bakong-payment/subscription` | JWT | Get subscription |

### Configuration (.env)

```env
PORT=3001
API_PREFIX=api/v1
BAKONG_SERVICE_URL=http://localhost:3002
BAKONG_API_KEY=changeme_secure_api_key_here
BAKONG_WEBHOOK_SECRET=changeme_webhook_secret_here
```

---

## 3. Bakong Payment Service (Microservice)

**Port**: 3002  
**Files**: `bakong_payment/src/controllers/*.controller.ts`

### Payment Controller

| Method | Route | Full Path | Purpose |
|--------|-------|-----------|---------|
| POST | `/api/payments/create` | `http://localhost:3002/api/payments/create` | Create payment & generate QR |
| GET | `/api/payments/status/:md5` | `http://localhost:3002/api/payments/status/:md5` | Check payment status |
| POST | `/api/payments/monitor` | `http://localhost:3002/api/payments/monitor` | Monitor payment |
| POST | `/api/payments/bulk-check` | `http://localhost:3002/api/payments/bulk-check` | Bulk status check |
| GET | `/api/payments/history` | `http://localhost:3002/api/payments/history` | Get payment history |

### Subscription Controller

| Method | Route | Full Path | Purpose |
|--------|-------|-----------|---------|
| GET | `/api/subscriptions/status/:userId` | `http://localhost:3002/api/subscriptions/status/:userId` | Get subscription status |
| POST | `/api/subscriptions/upgrade` | `http://localhost:3002/api/subscriptions/upgrade` | Upgrade subscription |
| POST | `/api/subscriptions/downgrade` | `http://localhost:3002/api/subscriptions/downgrade` | Downgrade subscription |
| POST | `/api/subscriptions/cancel` | `http://localhost:3002/api/subscriptions/cancel` | Cancel subscription |
| POST | `/api/subscriptions/renew` | `http://localhost:3002/api/subscriptions/renew` | Renew subscription |

### Health Controller

| Method | Route | Full Path | Purpose |
|--------|-------|-----------|---------|
| GET | `/api/health` | `http://localhost:3002/api/health` | Health check |
| GET | `/api/health/ready` | `http://localhost:3002/api/health/ready` | Readiness probe |
| GET | `/api/health/live` | `http://localhost:3002/api/health/live` | Liveness probe |

### Configuration (.env)

```env
PORT=3002
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/bakong_payment?schema=public"
```

---

## Communication Flow

### Payment Creation Flow

1. **Flutter** → `POST http://172.23.5.229:3001/api/v1/bakong-payment/create`
   ```json
   {
     "planType": "PREMIUM",
     "appName": "Das Tern Mobile"
   }
   ```

2. **backend_nestjs** (receives request, extracts userId from JWT)
   - Validates user & plan
   - Prepares encrypted payload

3. **backend_nestjs** → **bakong_payment**: `POST http://localhost:3002/api/payments/create`
   ```json
   {
     "userId": "uuid",
     "amount": 5.00,
     "planType": "PREMIUM",
     "currency": "USD"
   }
   ```

4. **bakong_payment** → **Bakong API** (external)
   - Generates QR code
   - Returns QR data

5. **bakong_payment** → **backend_nestjs** (response)
   ```json
   {
     "success": true,
     "payment": {
       "id": "uuid",
       "billNumber": "INV-...",
       "md5Hash": "...",
       "qrCode": "...",
       "amount": 5.00
     }
   }
   ```

6. **backend_nestjs** → **Flutter** (response)
   ```json
   {
     "success": true,
     "payment": { ... },
     "qrCode": "...",
     "expiresAt": "..."
   }
   ```

---

## Network Configuration for Physical Device Testing

### Requirements

1. **Computer and Phone must be on same WiFi network**

2. **Find your computer's IP address**:
   ```bash
   # Linux
   ip a | grep "inet " | grep -v 127.0.0.1
   
   # Should show something like: 172.23.5.229
   ```

3. **Update Flutter configuration** (`das_tern_mcp/lib/utils/api_constants.dart`):
   ```dart
   static const String hostIpAddress = '172.23.5.229'; // Your IP
   ```

4. **Ensure backend is accessible**:
   ```bash
   # Test from your phone's browser:
   http://172.23.5.229:3001/api/v1/auth/health
   ```

5. **Firewall configuration**:
   ```bash
   # Allow port 3001 on Fedora
   sudo firewall-cmd --add-port=3001/tcp --permanent
   sudo firewall-cmd --reload
   ```

---

## Verification Checklist

### ✅ Backend NestJS (Port 3001)

- [ ] Running on port 3001
- [ ] Global prefix is `api/v1`
- [ ] Can access: `http://localhost:3001/api/v1/auth/health`
- [ ] Can access from phone: `http://172.23.5.229:3001/api/v1/auth/health`
- [ ] Environment variables set:
  - `PORT=3001`
  - `API_PREFIX=api/v1`
  - `BAKONG_SERVICE_URL=http://localhost:3002`

### ✅ Bakong Payment Service (Port 3002)

- [ ] Running on port 3002
- [ ] Can access: `http://localhost:3002/api/health`
- [ ] Database connection configured
- [ ] Environment variables set:
  - `PORT=3002`
  - `DATABASE_URL` configured

### ✅ Flutter App

- [ ] `api_constants.dart` has correct IP: `172.23.5.229`
- [ ] Port is `3001`
- [ ] API prefix is `api/v1`
- [ ] Device and computer on same network
- [ ] Can reach backend from device browser

---

## Common Issues & Solutions

### Issue: "Connection Refused" on Physical Device

**Solution**:
1. Check firewall: `sudo firewall-cmd --list-ports`
2. Add port: `sudo firewall-cmd --add-port=3001/tcp --permanent`
3. Reload: `sudo firewall-cmd --reload`

### Issue: "Endpoint Mismatch"

**Check**:
1. Flutter uses: `/api/v1/bakong-payment/*`
2. Backend controller: `@Controller('bakong-payment')`
3. Backend global prefix: `app.setGlobalPrefix('api/v1')`

### Issue: Backend Can't Reach Bakong Service

**Solution**:
1. Verify bakong service is running: `curl http://localhost:3002/api/health`
2. Check `BAKONG_SERVICE_URL` in backend `.env`
3. Ensure both services are running

---

## Testing Commands

### Test Backend NestJS
```bash
cd backend_nestjs
npm run start:dev
# Should see: 🚀 Application is running on: http://localhost:3001/api/v1
```

### Test Bakong Payment Service
```bash
cd bakong_payment
npm run start:dev
# Should see: 🚀 Bakong Payment Service started on port 3002
```

### Test from Flutter Device
```bash
# On your phone's browser, navigate to:
http://172.23.5.229:3001/api/v1/auth/health
# Should return: {"status":"ok"}
```

### Test Backend → Bakong Communication
```bash
# From backend terminal:
curl http://localhost:3002/api/health
# Should return health status
```

---

## Current Status: ✅ ALIGNED

All endpoints are properly configured and aligned:
- Flutter → backend_nestjs : ✅ Correct
- backend_nestjs → bakong_payment : ✅ Correct
- API paths match between client and server : ✅ Correct

**Update your IP address in Flutter's `api_constants.dart` to match your network and ensure firewall allows port 3001!**
