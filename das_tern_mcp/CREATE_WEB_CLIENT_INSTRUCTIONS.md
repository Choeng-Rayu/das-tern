# ⚠️ WRONG CONFIGURATION DETECTED!

## The Problem

You created an **Android OAuth client** ✅ (correct!)
But you're using its Client ID in your `.env` file ❌ (WRONG!)

**Your current .env has:**
```
GOOGLE_CLIENT_ID=265372630808-uebdmc8rr9kr8vffs0brluuelkh3ofkp.apps.googleusercontent.com
```

**This is the ANDROID client ID!** But the `serverClientId` parameter needs a **WEB client ID**!

## What You Need

For Android Google Sign-In, you need **BOTH**:

1. ✅ **Android OAuth client** (you already have this)
   - Client ID: 265372630808-uebdmc8rr9kr8vffs0brluuelkh3ofkp
   - Package: com.example.das_tern_mcp
   - SHA-1: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF
   - **Used by**: Google Sign-In plugin automatically (no config needed)

2. ❌ **Web OAuth client** (YOU NEED TO CREATE THIS!)
   - **Used by**: `serverClientId` parameter in your code
   - **Purpose**: Gets idToken for backend authentication

## Create Web OAuth Client NOW

### Step 1: Open Google Cloud Console
https://console.cloud.google.com/apis/credentials?project=das-tern

### Step 2: Create Web Client
1. Click **"+ CREATE CREDENTIALS"** → **OAuth client ID**
2. Select **"Web application"** (NOT Android, you already have that!)
3. Name: `Das Tern Web Client`
4. **Authorized redirect URIs** - Add BOTH:
   ```
   http://localhost:3001/api/v1/auth/google/callback
   http://192.168.0.189:3001/api/v1/auth/google/callback
   ```
5. Click **CREATE**

### Step 3: Copy the NEW Web Client ID
After creating, Google shows you a popup with:
- **Client ID**: 265372630808-XXXXXXXXXX.apps.googleusercontent.com (DIFFERENT from Android!)
- **Client Secret**: GOCSPX-XXXXXXXXXX

**Copy the Web Client ID!** It will look like:
```
265372630808-abc123xyz456randomchars.apps.googleusercontent.com
```

### Step 4: Update BOTH .env Files

**Update Flutter .env:**
```bash
# /home/rayu/das-tern/das_tern_mcp/.env
GOOGLE_CLIENT_ID=265372630808-YOUR-NEW-WEB-CLIENT-ID.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-YOUR-CLIENT-SECRET
```

**Update Backend .env:**
```bash
# /home/rayu/das-tern/backend_nestjs/.env
GOOGLE_CLIENT_ID=265372630808-YOUR-NEW-WEB-CLIENT-ID.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-YOUR-CLIENT-SECRET
```

### Step 5: Test
```bash
cd /home/rayu/das-tern/das_tern_mcp
flutter clean && flutter pub get && flutter run
```

## Why This Fixes It

### Current (WRONG):
```dart
GoogleSignIn(
  serverClientId: 'ANDROID-CLIENT-ID',  // ❌ WRONG!
)
```

### After Fix (CORRECT):
```dart
GoogleSignIn(
  serverClientId: 'WEB-CLIENT-ID',      // ✅ CORRECT!
)
```

The Android client validates your app automatically.
The Web client gets the idToken for your backend.

## Summary

| Client Type | Purpose | In .env? | 
|-------------|---------|----------|
| Android | App validation (package + SHA-1) | ❌ No (automatic) |
| Web | Backend authentication (idToken) | ✅ Yes (GOOGLE_CLIENT_ID) |

You have the Android client ✅
You need to create the Web client and use its ID in .env ❌

## After You Create the Web Client

Send me the new Web Client ID and I'll update your .env files for you!
