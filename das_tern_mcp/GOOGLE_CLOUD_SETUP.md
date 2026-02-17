# Google Sign-In Configuration for Google Cloud Console

## Your Configuration Details

### SHA-1 Certificate (Debug)
```
DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF
```

### Package Name
```
com.example.das_tern_mcp
```

### Google Client ID (Current Project: das-tern)
```
265372630808-uebdmc8rr9kr8vffs0brluuelkh3ofkp.apps.googleusercontent.com
```

**IMPORTANT**: You need to create an **Android** OAuth client in Google Cloud Console  
for the `das-tern` project (project number: 265372630808) with:
- Package name: `com.example.das_tern_mcp`
- SHA-1: Your debug keystore fingerprint

## Google Cloud Console Setup

### 1. Access Google Cloud Console
Go to: https://console.cloud.google.com/

### 2. Create/Select Project
- If you don't have a project, create one: "Das Tern" or similar
- Otherwise, select your existing project

### 3. Enable Google+ API (if not enabled)
- Go to: **APIs & Services > Library**
- Search for "Google+ API" or "Google Identity"
- Click **Enable**

### 4. Configure OAuth Consent Screen
- Go to: **APIs & Services > OAuth consent screen**
- Select **External** user type (or Internal if using Google Workspace)
- Fill in required fields:
  - App name: `Das Tern`
  - User support email: Your email
  - Developer contact: Your email
- Add scopes:
  - `email`
  - `profile`
- Save and continue

### 5. Create Android OAuth Client

Go to: **APIs & Services > Credentials**

Click: **+ CREATE CREDENTIALS > OAuth client ID**

Configure:
```
Application type: Android
Name: Das Tern MCP Android
Package name: com.example.das_tern_mcp
SHA-1 certificate fingerprint: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF
```

**IMPORTANT**: The generated client ID should be:
```
843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
```

### 6. Create Web OAuth Client (for backend)

Still in **Credentials**, click: **+ CREATE CREDENTIALS > OAuth client ID**

Configure:
```
Application type: Web application
Name: Das Tern Backend
Authorized redirect URIs:
  - http://localhost:3001/api/v1/auth/google/callback
  - http://10.138.213.210:3001/api/v1/auth/google/callback
```

**IMPORTANT**: This should use the SAME client ID as the Android app. If Google generates a new one, you'll need to update:
- `/home/rayu/das-tern/das_tern_mcp/.env`
- `/home/rayu/das-tern/backend_nestjs/.env`

### 7. Download OAuth Client Configuration (Optional)

If you want to verify:
- Click on your Android OAuth client
- Download JSON configuration
- Check that the client ID matches your `.env` files

## Testing After Configuration

### 1. Wait for Propagation
Google OAuth changes can take 5-10 minutes to propagate globally.

### 2. Clean and Rebuild
```bash
cd /home/rayu/das-tern/das_tern_mcp
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
```

### 3. Clear App Data
```bash
adb shell pm clear com.example.das_tern_mcp
```

### 4. Run App
```bash
flutter run
```

### 5. Test Sign-In
- Open the app
- Navigate to Login or Register screen
- Click "Sign in with Google" button
- Select your Google account
- Should authenticate successfully

## Troubleshooting

### Still Getting ApiException: 10?

**1. Verify SHA-1 is Registered**
- Go to Google Cloud Console > Credentials
- Click on your Android OAuth client
- Verify SHA-1 matches: `DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF`

**2. Check Package Name**
```bash
grep applicationId /home/rayu/das-tern/das_tern_mcp/android/app/build.gradle.kts
```
Should output: `com.example.das_tern_mcp`

**3. Verify Google Client ID**
```bash
grep GOOGLE_CLIENT_ID /home/rayu/das-tern/das_tern_mcp/.env
grep GOOGLE_CLIENT_ID /home/rayu/das-tern/backend_nestjs/.env
```
Both should be: `843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com`

**4. Check Logs**
```bash
adb logcat | grep -i "google\|auth\|oauth"
```

**5. Try Different Google Account**
Some Google accounts have restrictions. Try with a personal Gmail account.

**6. Rebuild Keystore (Nuclear Option)**
```bash
rm ~/.android/debug.keystore
cd /home/rayu/das-tern/das_tern_mcp/android
./gradlew assembleDebug
```
Then get new SHA-1 and update Google Cloud Console.

### ApiException: 12 (Sign-in cancelled)
This is normal if user cancels. Not an error.

### ApiException: 7 (Network error)
- Check internet connection
- Check if Google services are accessible
- Try using VPN if in restricted region

### Backend Verification Fails
If app gets ID token but backend rejects it:
- Check backend logs: `cd /home/rayu/das-tern/backend_nestjs && npm run start:dev`
- Verify `GOOGLE_CLIENT_ID` in backend `.env` matches
- Check backend can reach Google servers

## Quick Reference

| Item | Value |
|------|-------|
| Package Name | `com.example.das_tern_mcp` |
| Debug SHA-1 | `DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF` |
| Google Client ID | `843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu...` |
| Backend API | `http://10.138.213.210:3001/api/v1` |
| Auth Endpoint | `POST /auth/google` |

## Architecture Flow

```
┌──────────────┐
│ Flutter App  │
│ (Android)    │
└──────┬───────┘
       │ 1. User clicks "Sign in with Google"
       │ 2. Google Sign-In SDK validates app
       │    (checks SHA-1 + package name)
       ▼
┌──────────────┐
│   Google     │
│  OAuth 2.0   │
└──────┬───────┘
       │ 3. User selects account & grants permission
       │ 4. Returns ID Token to app
       ▼
┌──────────────┐
│ Flutter App  │
└──────┬───────┘
       │ 5. Sends ID Token to backend
       │    POST /api/v1/auth/google
       ▼
┌──────────────┐
│  Backend     │
│  NestJS      │
└──────┬───────┘
       │ 6. Verifies ID Token with Google
       │ 7. Creates/updates user in PostgreSQL
       │ 8. Returns JWT access + refresh tokens
       ▼
┌──────────────┐
│ Flutter App  │
│ (Logged in)  │
└──────────────┘
```

## Support

If you need help:
1. Check logs: `adb logcat | grep -E "flutter|google|auth"`
2. Verify backend is running: `curl http://10.138.213.210:3001/api/v1/health`
3. Test backend Google endpoint: 
   ```bash
   curl -X POST http://10.138.213.210:3001/api/v1/auth/google \
     -H "Content-Type: application/json" \
     -d '{"idToken": "test"}'
   ```
4. Check Google Cloud Console for OAuth client configuration

---

**Last Updated**: February 16, 2026  
**Generated SHA-1**: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF
