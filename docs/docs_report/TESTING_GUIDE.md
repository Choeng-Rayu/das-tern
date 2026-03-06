# Testing Guide: Das Tern OCR Services + Backend

This guide walks you through testing the new Kiri-OCR service with the NestJS backend.

## Prerequisites

- Docker & Docker Compose installed
- Test prescription image at: `/home/rayu/das-tern/ocr_service/test_space/images_for_test/image.png`
- `.env` file configured in `/home/rayu/das-tern/.env`

## Architecture Overview

```
Flutter Mobile App (you run locally)
        ↓ HTTPS
NestJS Backend (http://localhost:3001)
        ↓ HTTP
Kiri-OCR Service (http://kiri-ocr:8003) [in Docker]
        ↓ (optional)
AI API Service (http://ai-api:8001) [external]
```

---

## Part 1: Build Services

### 1.1 Build Kiri-OCR Docker Image

```bash
cd /home/rayu/das-tern
docker build -t dastern-kiri-ocr:latest ./kiri_ocr
```

Expected output:
```
...
Successfully built <image-id>
Successfully tagged dastern-kiri-ocr:latest
```

### 1.2 Build/Update NestJS Backend (if needed)

The Dockerfile for backend already exists:

```bash
cd /home/rayu/das-tern
docker build -t dastern-backend:latest ./backend_nestjs
```

Or docker-compose will build automatically.

---

## Part 2: Start Services via Docker Compose

### 2.1 Start Full Stack (All Services)

```bash
cd /home/rayu/das-tern
docker compose up -d
```

This will start:
- **postgres** (port 5432) — Database
- **redis** (port 6379) — Cache
- **rabbitmq** (port 5672, 15672) — Message queue
- **kiri-ocr** (port 8003) — OCR service
- **minio** (port 9000, 9001) — File storage
- **backend** (port 3001) — NestJS API

Expected output:
```
[+] Running 7/7
 ✔ Container dastern-postgres  Started
 ✔ Container dastern-redis  Started
 ✔ Container dastern-rabbitmq  Started
 ✔ Container dastern-kiri-ocr  Started
 ✔ Container dastern-minio  Started
 ✔ Container dastern-backend  Started
```

**Wait 30-60 seconds for services to fully initialize** (especially backend and kiri-ocr).

Check logs:
```bash
docker compose logs -f backend
docker compose logs -f kiri-ocr
```

---

## Part 3: Test Services

### 3.1 Health Checks

Test that all services are running:

```bash
# Kiri-OCR health
curl http://localhost:8003/api/v1/health

# Backend health (should return 200 on port 3001)
curl http://localhost:3001/api/v1/health 2>/dev/null || echo "Backend loading..."
```

Expected kiri-ocr response:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "ocr_engine": "kiri-ocr",
  "model_name": "mrrtmob/kiri-ocr",
  "models_loaded": true
}
```

### 3.2 Test Kiri-OCR Service Directly

Extract text from test prescription image:

```bash
curl -X POST \
  -F "file=@/home/rayu/das-tern/ocr_service/test_space/images_for_test/image.png" \
  http://localhost:8003/api/v1/extract \
  | jq '.extraction_summary'
```

Expected output:
```json
{
  "total_medications": 4,
  "confidence_score": 0.44,
  "needs_review": true,
  "processing_time_ms": 12000,
  "engines_used": ["kiri-ocr"]
}
```

Check the full response:
```bash
curl -s -X POST \
  -F "file=@/home/rayu/das-tern/ocr_service/test_space/images_for_test/image.png" \
  http://localhost:8003/api/v1/extract \
  | jq '.data.prescription.patient'
```

Expected:
```json
{
  "personal_info": {
    "name": {
      "full_name": "ង៉ា ដានី"
    },
    "age": {
      "value": 19
    },
    "gender": {
      "value": "F"
    }
  },
  "identification": {
    "patient_id": {
      "value": "HAKF13541664"
    }
  }
}
```

### 3.3 Test Backend OCR Endpoints

The backend has two OCR endpoints:

#### A. `/api/v1/ocr/extract` — Extract + AI Enhancement (Preview)

```bash
curl -X POST \
  -F "file=@/home/rayu/das-tern/ocr_service/test_space/images_for_test/image.png" \
  http://localhost:3001/api/v1/ocr/extract \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

Returns: OCR result + AI corrections (if available) + `ai_status` field.

#### B. `/api/v1/ocr/scan` — Extract + Create Prescription in DB

```bash
curl -X POST \
  -F "file=@/home/rayu/das-tern/ocr_service/test_space/images_for_test/image.png" \
  http://localhost:3001/api/v1/ocr/scan \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

Returns: Created prescription object in database.

**Note:** Requires valid JWT token from login. See Flutter app testing below.

### 3.4 Test Graceful Degradation (AI Service Down)

The backend should still return OCR results even if AI service (`ai-api`) is down:

```bash
# Stop AI service (if running)
docker stop dastern-ai-api 2>/dev/null || echo "AI service not running"

# Test OCR endpoint
curl -X POST \
  -F "file=@/home/rayu/das-tern/ocr_service/test_space/images_for_test/image.png" \
  http://localhost:3001/api/v1/ocr/extract

# Check response has ai_status: 'not_responded'
```

Expected: Response includes `"ai_status": "not_responded"` but OCR data is still present.

---

## Part 4: Mobile App Testing (Flutter)

### 4.1 Configure Flutter App to Use Your Backend

Edit the API configuration in your Flutter app:

**File:** `das_tern_mcp/lib/config/api_config.dart` (or similar)

Set the backend URL:
```dart
const String API_BASE_URL = 'http://localhost:3001/api/v1';
// For Android emulator:
// const String API_BASE_URL = 'http://10.0.2.2:3001/api/v1';
```

### 4.2 Login Flow (Required for OCR Endpoints)

The OCR endpoints require JWT authentication. Your app must:

1. **Register** a new user (or use existing):
   ```
   POST /api/v1/auth/register
   Body: {
     "email": "test@example.com",
     "password": "TestPassword123!",
     "role": "patient"
   }
   ```

2. **Login**:
   ```
   POST /api/v1/auth/login
   Body: {
     "email": "test@example.com",
     "password": "TestPassword123!"
   }
   ```
   Response includes `access_token` and `refresh_token`.

3. **Store token** and use in OCR requests:
   ```
   Authorization: Bearer <access_token>
   ```

### 4.3 Test OCR in Flutter App

Navigate to the **Scan Tab** in your app:

1. **Pick an image** from gallery or camera
2. **Tap "Extract"** — sends to backend
3. **Review OCR results** — should show:
   - Patient name, age, gender
   - 4 medications with dosages
   - Diagnosis, prescriber, dates
4. **Edit if needed** — correct any OCR errors
5. **Submit** — creates prescription in database

### 4.4 Troubleshooting Mobile Connection

**If Flutter app can't reach backend:**

For **Android Emulator**:
- Use `http://10.0.2.2:3001` (maps to host `localhost:3001`)

For **Android Device**:
- Replace `localhost` with your computer's IP address
- Find IP: `ipconfig getifaddr en0` (macOS) or `ipconfig` (Windows)
- Example: `http://192.168.1.100:3001/api/v1`

For **iOS Simulator**:
- Use `http://localhost:3001`

For **iOS Device**:
- Use your computer's IP address (same as Android)

---

## Part 5: View Logs

Monitor service logs in real-time:

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f kiri-ocr
docker compose logs -f backend

# Filter by service
docker compose logs -f backend | grep "OCR\|Error\|warn"
```

---

## Part 6: Cleanup

### Stop all services:
```bash
docker compose down
```

### Stop and remove volumes (reset database):
```bash
docker compose down -v
```

### View running containers:
```bash
docker compose ps
```

---

## Expected Test Flow

1. ✅ Start docker-compose
2. ✅ Health checks pass
3. ✅ Kiri-OCR extracts text from image → 4 medications found
4. ✅ Backend receives OCR requests → forwards to kiri-ocr
5. ✅ Backend returns Dynamic Universal v2.0 format
6. ✅ AI enhancement works (if ai-api running)
7. ✅ Graceful degradation works (OCR works without AI)
8. ✅ Flutter app can login and submit OCR scan
9. ✅ Prescription created in database with OCR-extracted data

---

## Troubleshooting

### Kiri-OCR service not starting
- **Check logs**: `docker compose logs kiri-ocr`
- **Issue**: Model download timeout → increase `start_period` in docker-compose.yml to 180s
- **Fix**:
  ```yaml
  healthcheck:
    start_period: 180s  # increased from 120s
  ```

### Backend can't connect to kiri-ocr
- **Issue**: Wrong container name or port
- **Fix**: Verify in backend logs: `docker compose logs backend | grep OCR_SERVICE_URL`
- **Should show**: `OCR_SERVICE_URL=http://kiri-ocr:8003` ✅

### Flutter app login fails
- **Check**: Backend health `/health` endpoint
- **Check**: Database is running: `docker compose ps postgres`
- **Check**: Redis is running: `docker compose ps redis`

### OCR extraction timeout
- **Check**: Kiri-OCR logs for model loading issues
- **Check**: System memory availability
- **Increase timeout** in backend: `timeout: 30000` → `60000` in `ocr.service.ts` line 70

---

## Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service definitions |
| `kiri_ocr/Dockerfile` | Kiri-OCR container |
| `backend_nestjs/Dockerfile` | NestJS container |
| `backend_nestjs/src/modules/ocr/ocr.controller.ts` | OCR endpoints |
| `backend_nestjs/src/modules/ocr/ocr.service.ts` | OCR logic + AI enhancement |
| `das_tern_mcp/lib/ui/screens/patient/tab/patient_scan_tab.dart` | Flutter scan UI |

---

## Quick Commands

```bash
# Check container status
docker compose ps

# View real-time logs
docker compose logs -f

# Execute command in container
docker compose exec backend npm run typeorm migration:run

# Restart a service
docker compose restart backend

# View network
docker network ls
docker network inspect das-tern_dastern-network
```

---

Done! Your services are ready to test. Report any issues with specific error messages.
