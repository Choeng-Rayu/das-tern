# Google Sign-In Error Fix - Complete Summary

## Problem
You were getting this error when trying to sign in with Google:
```
ApiException: 10: com.google.android.gms.common.api.ApiException: 10
```

This error means: **"Developer console is not configured correctly"**

## Root Cause
The Android app needs to be registered in Google Cloud Console with:
1. The correct package name (`com.example.das_tern_mcp`)
2. The SHA-1 certificate fingerprint from your debug keystore

Without this registration, Google's Android SDK refuses to provide the ID token.

## Solution Applied

### 1. ✅ Removed Firebase Dependency
- Firebase was added but not configured (no `google-services.json`)
- We removed the Firebase plugin since you don't need it
- Your app uses `backend_nestjs` for all authentication logic

**Files Modified:**
- `android/app/build.gradle.kts` - Removed `google-services` plugin
- `android/build.gradle.kts` - Removed Firebase classpath

### 2. ✅ Created Helper Scripts

**`get_sha1.sh`** - Extracts your SHA-1 certificate
```bash
./get_sha1.sh
```
Output: `DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF`

**`setup_google_signin.sh`** - Automated setup and verification
```bash
./setup_google_signin.sh
```
- Verifies prerequisites
- Checks configuration
- Cleans build
- Gets dependencies
- Shows setup instructions

**`backend_nestjs/verify_google_oauth.sh`** - Verifies backend configuration
```bash
cd /home/rayu/das-tern/backend_nestjs
./verify_google_oauth.sh
```

### 3. ✅ Created Documentation

**`GOOGLE_SIGNIN_FIX.md`** - Complete fix guide  
**`GOOGLE_CLOUD_SETUP.md`** - Detailed Google Cloud Console setup with your specific values

## What You MUST Do Now

### CRITICAL: Configure Google Cloud Console

You **MUST** register your Android app in Google Cloud Console. The scripts can't do this for you.

#### Step-by-Step:

1. **Go to Google Cloud Console**
   - URL: https://console.cloud.google.com/
   - Login with your Google account

2. **Select/Create Project**
   - If you have an existing project for this app, select it
   - Otherwise: Click "New Project", name it "Das Tern" or similar

3. **Enable Required APIs**
   - Go to: **APIs & Services > Library**
   - Search for: "Google+ API" or "People API"
   - Click **Enable**

4. **Configure OAuth Consent Screen**
   - Go to: **APIs & Services > OAuth consent screen**
   - User Type: **External** (or Internal if using Google Workspace)
   - App name: `Das Tern`
   - User support email: Your email
   - Developer contact: Your email
   - Scopes: Add `email` and `profile`
   - Save

5. **Create Android OAuth Client**
   - Go to: **APIs & Services > Credentials**
   - Click: **+ CREATE CREDENTIALS > OAuth client ID**
   - Configure:
     ```
     Application type: Android
     Name: Das Tern MCP Android
     Package name: com.example.das_tern_mcp
     SHA-1: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF
     ```
   - Click **Create**

6. **Verify Client ID**
   - The generated client ID should be:
     ```
     843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
     ```
   - This is already configured in your `.env` files
   - If different, update both:
     - `das_tern_mcp/.env`
     - `backend_nestjs/.env`

7. **Create Web OAuth Client (for backend)**
   - Still in Credentials, click: **+ CREATE CREDENTIALS > OAuth client ID**
   - Configure:
     ```
     Application type: Web application
     Name: Das Tern Backend
     Authorized redirect URIs:
       - http://localhost:3001/api/v1/auth/google/callback
       - http://10.138.213.210:3001/api/v1/auth/google/callback
     ```
   - **IMPORTANT**: Use the SAME client ID as Android app

8. **Wait 5-10 Minutes**
   - Google OAuth configuration takes time to propagate globally
   - Don't test immediately after configuring

## Testing After Configuration

### 1. Make sure backend is running:
```bash
cd /home/rayu/das-tern/backend_nestjs
npm run start:dev
```

### 2. Clear app data (optional but recommended):
```bash
adb shell pm clear com.example.das_tern_mcp
```

### 3. Run Flutter app:
```bash
cd /home/rayu/das-tern/das_tern_mcp
flutter run
```

### 4. Test Google Sign-In:
- Click "Sign in with Google" button
- Select your Google account
- Grant permissions
- Should authenticate successfully!

## Architecture (How It Works)

```
┌─────────────────┐
│   Flutter App   │  1. User clicks "Sign in with Google"
│    (Android)    │  2. Google Sign-In SDK checks:
└────────┬────────┘     - Package name matches? ✓
         │              - SHA-1 registered? ✓
         │              - OAuth client exists? ✓
         ∨
┌─────────────────┐
│  Google OAuth   │  3. Shows account picker
│    Servers      │  4. User selects account & grants permission
└────────┬────────┘  5. Returns ID Token (JWT) to app
         │
         ∨
┌─────────────────┐
│   Flutter App   │  6. App gets ID Token
│                 │  7. Sends to: POST /api/v1/auth/google
└────────┬────────┘     Body: { "idToken": "...", "userRole": "PATIENT" }
         │
         ∨
┌─────────────────┐
│ backend_nestjs  │  8. Verifies ID Token with Google
│  Auth Service   │  9. Extracts user info (email, name, picture)
└────────┬────────┘  10. Creates/updates user in PostgreSQL
         │          11. Generates JWT access + refresh tokens
         ∨          12. Returns tokens to app
┌─────────────────┐
│   Flutter App   │  13. Stores tokens in secure storage
│ (Authenticated) │  14. Loads user profile
└─────────────────┘  15. Navigates to home screen
```

## Key Configuration Files

### Flutter App
**File**: `das_tern_mcp/.env`
```env
GOOGLE_CLIENT_ID=843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
API_BASE_URL=http://10.138.213.210:3001/api/v1
```

**File**: `das_tern_mcp/lib/providers/auth_provider.dart`
- Function: `signInWithGoogle()`
- Uses: `google_sign_in` package
- Gets: Google ID token
- Sends to: `_api.googleLogin()`

**File**: `das_tern_mcp/lib/services/api_service.dart`
- Function: `googleLogin(String idToken, {String? userRole})`
- Endpoint: `POST /auth/google`
- Payload: `{ "idToken": "...", "userRole": "..." }`

### Backend
**File**: `backend_nestjs/.env`
```env
GOOGLE_CLIENT_ID=843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
```

**File**: `backend_nestjs/src/modules/auth/auth.controller.ts`
- Endpoint: `POST /auth/google`
- Handler: `googleLoginMobile(dto: GoogleLoginDto)`
- Calls: `authService.googleLoginMobile()`

**File**: `backend_nestjs/src/modules/auth/auth.service.ts`
- Function: `googleLoginMobile(idToken: string, userRole?: UserRole)`
- Uses: `google-auth-library` npm package
- Verifies ID token with Google
- Creates/updates user in database
- Returns JWT tokens

## Troubleshooting

### Issue: Still getting ApiException: 10

**Solution 1**: Double-check SHA-1 is registered
```bash
cd /home/rayu/das-tern/das_tern_mcp
./get_sha1.sh
```
Verify this SHA-1 is in Google Cloud Console: `DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF`

**Solution 2**: Wait longer (OAuth changes take time)

**Solution 3**: Check package name
```bash
grep applicationId android/app/build.gradle.kts
```
Must output: `com.example.das_tern_mcp`

**Solution 4**: Rebuild keystore (nuclear option)
```bash
rm ~/.android/debug.keystore
cd android && ./gradlew assembleDebug && cd ..
./get_sha1.sh  # Get new SHA-1
# Update Google Cloud Console with new SHA-1
```

### Issue: Backend returns "Invalid Google token"

**Check 1**: Backend logs
```bash
cd /home/rayu/das-tern/backend_nestjs
npm run start:dev
# Watch logs when testing
```

**Check 2**: Client ID matches
```bash
grep GOOGLE_CLIENT_ID das_tern_mcp/.env
grep GOOGLE_CLIENT_ID backend_nestjs/.env
```
Both should be identical.

**Check 3**: Backend can reach Google
```bash
curl https://www.googleapis.com/oauth2/v3/tokeninfo
```

### Issue: OAuth Consent Screen Error

If you see "This app isn't verified":
- Click "Advanced"
- Click "Go to Das Tern (unsafe)" 
- This is normal for apps in development
- To remove this: Submit app for verification (production only)

## Why No Firebase?

You mentioned you don't want Firebase, and **you don't need it**!

- **Firebase** = Full app platform (database, auth, hosting, functions, etc.)
- **Google Sign-In** = Just identity verification
- We're only using Google's OAuth 2.0 for identity
- Your backend handles ALL logic and data storage
- Flutter just gets the ID token from Google
- Backend verifies it and manages sessions

The Android Google Sign-In SDK requires OAuth client configuration in Google Cloud Console, but does NOT require Firebase services.

## Summary of Changes

### Files Modified:
- ✅ `android/app/build.gradle.kts` - Removed Firebase plugin
- ✅ `android/build.gradle.kts` - Removed Firebase classpath

### Files Created:
- ✅ `get_sha1.sh` - SHA-1 extraction tool
- ✅ `setup_google_signin.sh` - Automated setup
- ✅ `GOOGLE_SIGNIN_FIX.md` - Fix guide
- ✅ `GOOGLE_CLOUD_SETUP.md` - Google Console setup
- ✅ `FIX_SUMMARY.md` - This document
- ✅ `backend_nestjs/verify_google_oauth.sh` - Backend verification

### No Code Changes Needed:
- Backend Google OAuth implementation is already correct ✓
- Flutter Google Sign-In implementation is already correct ✓
- `.env` files are already configured ✓

### What YOU Need To Do:
- ⚠️ **Register Android app in Google Cloud Console** (see above)
- ⚠️ **Add SHA-1 certificate fingerprint**
- ⚠️ **Wait 5-10 minutes after configuration**

## Quick Start Commands

```bash
# 1. Get your SHA-1 (you already have this)
cd /home/rayu/das-tern/das_tern_mcp
./get_sha1.sh

# 2. Run setup script (already done)
./setup_google_signin.sh

# 3. Verify backend
cd /home/rayu/das-tern/backend_nestjs
./verify_google_oauth.sh

# 4. Start backend
npm run start:dev

# 5. In another terminal, run Flutter app
cd /home/rayu/das-tern/das_tern_mcp
flutter run

# 6. Test Google Sign-In in the app
```

## Success Criteria

You'll know it's working when:
1. ✅ Click "Sign in with Google"
2. ✅ Account picker appears
3. ✅ Select account and grant permissions
4. ✅ App navigates to home screen
5. ✅ User profile loads correctly
6. ✅ No errors in logs

## Need Help?

1. **Check SHA-1**: `./get_sha1.sh`
2. **Check config**: `./setup_google_signin.sh`
3. **Check backend**: `cd ../backend_nestjs && ./verify_google_oauth.sh`
4. **Check logs**: `adb logcat | grep -E "flutter|google|auth"`
5. **Check backend logs**: Watch terminal running `npm run start:dev`

---

**Generated**: February 16, 2026  
**Your SHA-1**: `DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF`  
**Package**: `com.example.das_tern_mcp`  
**Client ID**: `843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com`
