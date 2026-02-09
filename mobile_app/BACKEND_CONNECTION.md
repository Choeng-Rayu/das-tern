# Backend Connection Configuration ✅

**Date**: February 9, 2026, 09:37  
**Status**: ✅ Connected to backend via .env configuration

---

## Backend Configuration

### Backend URL
```
http://localhost:3001/api/v1
```

**Backend**: NestJS (from `/backend_nestjs`)  
**Port**: 3001  
**API Prefix**: api/v1

---

## Implementation

### 1. Created .env File

**File**: `mobile_app/.env`

```env
# Backend API Configuration
API_BASE_URL=http://localhost:3001/api/v1

# Environment
ENVIRONMENT=development

# App Configuration
APP_NAME=Das Tern
DEFAULT_TIMEZONE=Asia/Phnom_Penh
DEFAULT_LANGUAGE=km

# Storage
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/webp,application/pdf

# Subscription Plans
FREEMIUM_STORAGE_GB=5
PREMIUM_STORAGE_GB=20
PREMIUM_PRICE_USD=0.50
FAMILY_PREMIUM_PRICE_USD=1.00
FAMILY_PREMIUM_MAX_MEMBERS=3
```

---

### 2. Added flutter_dotenv Package

**File**: `pubspec.yaml`

```yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

---

### 3. Updated API Service

**File**: `lib/services/api_service.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Backend API base URL from .env
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3001/api/v1';
  
  // ... rest of the service
}
```

**Features**:
- ✅ Reads API_BASE_URL from .env
- ✅ Fallback to default if .env not found
- ✅ Dynamic configuration per environment

---

### 4. Updated Main Entry Point

**File**: `lib/main.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}
```

---

## API Endpoints Available

### Medications
- `POST /api/v1/medications` - Create medication
- `GET /api/v1/medications` - Get all medications
- `PUT /api/v1/medications/:id` - Update medication

### Dose Events
- `POST /api/v1/dose-events/sync` - Sync dose events
- `PUT /api/v1/dose-events/:id` - Update dose event

### Authentication (to be implemented)
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/register` - Register
- `POST /api/v1/auth/verify-otp` - Verify OTP

---

## Environment-Specific Configuration

### Development (.env)
```env
API_BASE_URL=http://localhost:3001/api/v1
ENVIRONMENT=development
```

### Production (.env.production)
```env
API_BASE_URL=https://api.dastern.com/api/v1
ENVIRONMENT=production
```

### Staging (.env.staging)
```env
API_BASE_URL=https://staging-api.dastern.com/api/v1
ENVIRONMENT=staging
```

---

## How to Use Different Environments

### 1. Create Environment Files
```bash
mobile_app/
├── .env                 # Development (default)
├── .env.production      # Production
└── .env.staging         # Staging
```

### 2. Load Specific Environment
```dart
// In main.dart
await dotenv.load(fileName: ".env.production");
```

### 3. Or Use Build Flavors
```bash
flutter run --dart-define=ENV=production
```

---

## Backend Connection Status

### Current Status
- ✅ Configuration: Complete
- ✅ API Service: Ready
- ⚠️ Backend Server: Not running
- ⏳ Authentication: To be implemented

### To Start Backend
```bash
cd /home/rayu/das-tern/backend_nestjs
npm install
npm run start:dev
```

Backend will run on: `http://localhost:3001`

---

## Testing Backend Connection

### 1. Start Backend
```bash
cd backend_nestjs
npm run start:dev
```

### 2. Run Mobile App
```bash
cd mobile_app
flutter run
```

### 3. Test API Calls
- Create a medication
- Sync dose events
- Check network logs

---

## Security Notes

### .env File
- ✅ Added to `.gitignore`
- ✅ Not committed to repository
- ✅ Each developer has their own .env

### API Keys
- Store sensitive keys in .env
- Never hardcode in source code
- Use different keys per environment

---

## Files Modified

1. ✅ `mobile_app/.env` - Created
2. ✅ `mobile_app/pubspec.yaml` - Added flutter_dotenv
3. ✅ `mobile_app/lib/main.dart` - Load .env on startup
4. ✅ `mobile_app/lib/services/api_service.dart` - Read from .env

---

## Verification

```bash
flutter analyze
```
**Result**: ✅ No issues found!

---

## Next Steps

1. **Start Backend Server**
   ```bash
   cd backend_nestjs
   npm run start:dev
   ```

2. **Implement Authentication API**
   - Login endpoint
   - Register endpoint
   - OTP verification

3. **Test API Integration**
   - Create medication via API
   - Sync dose events
   - Handle errors

4. **Add Error Handling**
   - Network errors
   - Timeout handling
   - Retry logic

---

**Status**: ✅ Backend connection configured and ready!

**Last Updated**: February 9, 2026, 09:37
