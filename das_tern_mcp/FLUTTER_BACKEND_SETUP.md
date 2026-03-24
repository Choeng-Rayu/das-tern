# Flutter App - Backend Configuration Setup

## ✅ Configuration Complete

Your Flutter app has been configured to connect to the production backend hosted on DigitalOcean VPS.

### Updated Files

#### 1. **`.env` File** (das_tern_mcp/.env)
```
API_BASE_URL=https://api.dastern.site/api/v1
```

**Changes Made:**
- ✅ Updated `API_BASE_URL` to production backend URL
- ✅ Updated `GOOGLE_REDIRECT_URI` to use HTTPS
- ✅ Updated `TELEGRAM_OAUTH_REDIRECT_URI` to use HTTPS

#### 2. **`api_constants.dart`** (das_tern_mcp/lib/utils/api_constants.dart)
- ✅ Added `productionApiBaseUrl` constant for fallback
- ✅ Added comments for production vs local development

#### 3. **`api_service.dart`** (das_tern_mcp/lib/services/api_service.dart)
- ✅ Already configured to read from `.env` file first
- ✅ Falls back to `ApiConstants.apiBaseUrl` if `.env` not loaded
- ✅ Enforces HTTPS in production mode

### How It Works

1. **Environment Variable Priority:**
   - First: Reads `API_BASE_URL` from `.env` file
   - Fallback: Uses `ApiConstants.apiBaseUrl` if `.env` not available

2. **HTTPS Enforcement:**
   - Production mode requires HTTPS
   - Debug mode allows HTTP for local testing

3. **Token Management:**
   - Access tokens stored in secure storage
   - Auto-refresh on 401 Unauthorized
   - Tokens cleared on logout

### Testing the Connection

#### Option 1: Run Flutter App
```bash
cd das_tern_mcp
flutter pub get
flutter run
```

#### Option 2: Test API Directly
```bash
# Test health endpoint
curl -v https://api.dastern.site/api/v1/health

# Test login endpoint
curl -X POST https://api.dastern.site/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"test","password":"test"}'
```

### Backend Status

✅ **Backend is running and healthy**
- Container: `dastern-backend` (Up 3+ hours)
- Port: 3001 (internal) → 127.0.0.1:3001
- Nginx: Reverse proxy on port 443 (HTTPS)
- SSL: Let's Encrypt certificates active
- CORS: Configured for production domains

### Troubleshooting

**If you get "Failed to fetch" error:**

1. **Check network connectivity:**
   ```bash
   ping api.dastern.site
   ```

2. **Verify SSL certificate:**
   ```bash
   curl -v https://api.dastern.site/api/v1/health
   ```

3. **Check Flutter logs:**
   - Run with: `flutter run -v`
   - Look for network errors in console

4. **For Android Emulator:**
   - Emulator may not reach external URLs by default
   - Use physical device or configure emulator network

### Environment Variables Summary

| Variable | Value | Purpose |
|----------|-------|---------|
| `API_BASE_URL` | `https://api.dastern.site/api/v1` | Backend API endpoint |
| `GOOGLE_REDIRECT_URI` | `https://api.dastern.site/api/v1/auth/google/callback` | Google OAuth callback |
| `TELEGRAM_OAUTH_REDIRECT_URI` | `https://api.dastern.site/api/v1/auth/telegram/callback` | Telegram OAuth callback |

### Next Steps

1. ✅ Run `flutter pub get` to ensure dependencies are installed
2. ✅ Run the app: `flutter run`
3. ✅ Test login with valid credentials
4. ✅ Check logs for any connection errors

**All set! Your Flutter app is now configured to use the production backend.** 🚀

