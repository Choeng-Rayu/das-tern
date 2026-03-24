# Quick Start - Flutter App with Production Backend

## 🚀 Setup Complete!

Your Flutter app is now configured to connect to the production backend at **`https://api.dastern.site/api/v1`**

## 📋 What Was Changed

### 1. `.env` File
```
API_BASE_URL=https://api.dastern.site/api/v1
GOOGLE_REDIRECT_URI=https://api.dastern.site/api/v1/auth/google/callback
TELEGRAM_OAUTH_REDIRECT_URI=https://api.dastern.site/api/v1/auth/telegram/callback
```

### 2. `lib/utils/api_constants.dart`
- Added production URL constant
- Kept local development options commented

### 3. `lib/services/api_service.dart`
- Already reads from `.env` file
- Falls back to `ApiConstants.apiBaseUrl`
- Enforces HTTPS in production

## 🏃 Running the App

### Step 1: Install Dependencies
```bash
cd das_tern_mcp
flutter pub get
```

### Step 2: Run the App
```bash
# For Android emulator
flutter run

# For physical device
flutter run -d <device_id>

# With verbose logging
flutter run -v
```

### Step 3: Test Login
1. Open the app
2. Go to Login screen
3. Enter test credentials
4. Check logs for any errors

## 🔍 Verify Connection

### Test Health Endpoint
```bash
curl -v https://api.dastern.site/api/v1/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "dastern-backend",
  "timestamp": "2026-03-23T...",
  "uptime": 11316.43
}
```

### Test Login Endpoint
```bash
curl -X POST https://api.dastern.site/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"test@example.com","password":"password123"}'
```

## ⚠️ Common Issues

### "Failed to fetch" Error
- Check internet connection
- Verify DNS: `ping api.dastern.site`
- Check SSL: `curl -v https://api.dastern.site/api/v1/health`

### Android Emulator Can't Reach API
- Use physical device instead
- Or configure emulator network settings

### CORS Error
- Backend CORS is configured for production domains
- Check `ALLOWED_ORIGINS` on VPS

## 📱 Device Testing

### Physical Device
1. Connect device via USB
2. Run: `flutter run -d <device_id>`
3. App will use production backend

### Android Emulator
1. May have network restrictions
2. Use physical device for testing
3. Or configure emulator network

## 🔐 Security Notes

- ✅ HTTPS enforced in production
- ✅ Tokens stored in secure storage
- ✅ Auto-refresh on 401 Unauthorized
- ✅ CORS configured for allowed origins

## 📚 Documentation

- See `FLUTTER_BACKEND_SETUP.md` for detailed configuration
- See `lib/services/api_service.dart` for API methods
- See `lib/utils/api_constants.dart` for constants

## ✅ Checklist

- [x] `.env` file updated with production URL
- [x] `api_constants.dart` updated
- [x] Dependencies installed (`http`, `flutter_secure_storage`, `flutter_dotenv`)
- [x] Backend is running and healthy
- [x] SSL certificates are valid
- [x] CORS is configured

**Ready to run!** 🎉

