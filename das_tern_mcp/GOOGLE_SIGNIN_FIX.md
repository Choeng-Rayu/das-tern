# Google Sign-In Fix - No Firebase Required

## Issue
Getting `ApiException: 10` error when trying to sign in with Google on Android. This error means the Android app isn't properly registered with Google OAuth.

## Solution
The issue is that Google Sign-In on Android requires your app to be registered in Google Cloud Console with your app's SHA-1 certificate fingerprint. **You don't need Firebase** - we're using the backend_nestjs for authentication verification.

## Quick Fix Steps

### Step 1: Get Your SHA-1 Certificate

Run this command:
```bash
cd /home/rayu/das-tern/das_tern_mcp
./get_sha1.sh
```

This will display your debug SHA-1 fingerprint. Copy it.

Or manually get it:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line starting with `SHA1:` and copy that fingerprint.

### Step 2: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)

2. Select your project (or create a new one)

3. Navigate to: **APIs & Services** > **Credentials**

4. Click **"+ CREATE CREDENTIALS"** > **"OAuth client ID"**

5. Configure the Android OAuth client:
   - **Application type**: Android
   - **Name**: Das Tern MCP Android
   - **Package name**: `com.example.das_tern_mcp`
   - **SHA-1 certificate fingerprint**: Paste the SHA-1 from Step 1

6. Click **Create**

### Step 3: Verify OAuth Client ID

The generated OAuth client ID should be:
```
843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
```

This is already configured in:
- `/home/rayu/das-tern/das_tern_mcp/.env` (Flutter)
- `/home/rayu/das-tern/backend_nestjs/.env` (Backend)

If it's different, update both .env files.

### Step 4: Also Create Web OAuth Client (if not exists)

For the backend to verify ID tokens, you also need a Web OAuth client:

1. In Google Cloud Console > Credentials
2. Click **"+ CREATE CREDENTIALS"** > **"OAuth client ID"**
3. Configure:
   - **Application type**: Web application
   - **Name**: Das Tern Backend
   - **Authorized redirect URIs**: 
     - `http://localhost:3001/api/v1/auth/google/callback`
     - Add production URL when deploying

4. **Important**: Use the SAME client ID as the Android app:
   ```
   843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
   ```

### Step 5: Rebuild the App

```bash
cd /home/rayu/das-tern/das_tern_mcp
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## How It Works (No Firebase Needed!)

1. **Flutter App**: Uses `google_sign_in` package to get Google ID token
2. **Android Native**: Google Sign-In SDK validates the app using SHA-1
3. **Backend**: Receives ID token, verifies it with Google, creates/logs in user
4. **Response**: Backend returns JWT access/refresh tokens

The flow:
```
Flutter (Google Sign-In) 
   → Gets ID Token
   → Sends to backend_nestjs (/api/v1/auth/google)
   → Backend verifies with Google OAuth
   → Backend creates/updates user in PostgreSQL 
   → Backend returns JWT tokens
   → Flutter stores tokens and navigates to home
```

## Troubleshooting

### Still getting ApiException: 10?

1. **Double-check package name**: Must be exactly `com.example.das_tern_mcp`
   ```bash
   grep applicationId /home/rayu/das-tern/das_tern_mcp/android/app/build.gradle.kts
   ```

2. **Verify SHA-1 is added**: In Google Cloud Console, check that your OAuth client has the SHA-1

3. **Wait a few minutes**: Google OAuth configuration can take 5-10 minutes to propagate

4. **Clear app data**:
   ```bash
   adb shell pm clear com.example.das_tern_mcp
   ```

5. **Check client ID matches**: In both .env files

### GOOGLE_CLIENT_ID mismatch?

If you created a new OAuth client with a different ID:

1. Update `/home/rayu/das-tern/das_tern_mcp/.env`:
   ```
   GOOGLE_CLIENT_ID=YOUR_NEW_CLIENT_ID
   ```

2. Update `/home/rayu/das-tern/backend_nestjs/.env`:
   ```
   GOOGLE_CLIENT_ID=YOUR_NEW_CLIENT_ID
   ```

3. Restart backend:
   ```bash
   cd /home/rayu/das-tern/backend_nestjs
   npm run start:dev
   ```

## Why No Firebase?

- **Firebase** is Google's app development platform with database, auth, etc.
- We're only using **Google Sign-In** for authentication
- Our backend (backend_nestjs) handles all auth logic and database
- We just need Google OAuth to verify user identity
- Android's Google Sign-In SDK requires OAuth client configuration, but NOT Firebase

## Current Configuration

### Flutter (das_tern_mcp/.env)
```
GOOGLE_CLIENT_ID=843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
```

### Backend (backend_nestjs/.env)
```
GOOGLE_CLIENT_ID=843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
```

### Backend Code
- **Verification**: `backend_nestjs/src/modules/auth/auth.service.ts` → `googleLoginMobile()`
- **Uses**: `google-auth-library` npm package to verify ID tokens
- **Endpoint**: `POST /api/v1/auth/google`

## Testing

After configuration:

1. Run the app:
   ```bash
   cd /home/rayu/das-tern/das_tern_mcp
   flutter run
   ```

2. Click "Sign in with Google"

3. Select Google account

4. Should see success and navigate to home screen

5. Check logs:
   ```bash
   adb logcat | grep -i "google\|auth"
   ```

## Need Help?

If still not working:
1. Run `./get_sha1.sh` and verify SHA-1 is registered
2. Check Google Cloud Console > APIs & Services > Credentials
3. Ensure OAuth consent screen is configured
4. Try incognito mode or different Google account
5. Check backend logs for verification errors
