# Fix Google OAuth Error 10 (DEVELOPER_ERROR)

## Problem
Getting `ApiException: 10` when signing in with Google. This means Android OAuth client is not configured.

## Your App Details
- **Package Name**: `com.example.das_tern_mcp`
- **SHA-1 Fingerprint**: `DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF`
- **Project**: das-tern (265372630808)

## Solution: Create Android OAuth Client

### Step 1: Go to Google Cloud Console
1. Open: https://console.cloud.google.com/apis/credentials?project=das-tern
2. Make sure you're in the **das-tern** project (top dropdown)

### Step 2: Create Android OAuth Client
1. Click **"+ CREATE CREDENTIALS"** → **OAuth client ID**
2. Application type: **Android**
3. Name: `Das Tern Android Client`
4. Package name: **`com.example.das_tern_mcp`** (copy exactly)
5. SHA-1 certificate fingerprint: **`DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF`** (copy exactly)
6. Click **CREATE**

### Step 3: No Download Needed!
**IMPORTANT**: For Android OAuth, you don't download any JSON file. The configuration is automatic based on package name + SHA-1.

### Step 4: Update Your .env (Already Done)
Your `.env` already has the correct Web Client ID:
```
GOOGLE_CLIENT_ID=265372630808-uebdmc8rr9kr8vffs0brluuelkh3ofkp.apps.googleusercontent.com
```

### Step 5: Test
1. Wait 5-10 minutes for Google's servers to sync
2. Run: `cd /home/rayu/das-tern/das_tern_mcp && flutter clean && flutter pub get && flutter run`
3. Try Google Sign-In again

## Why This Happens
- Android Google Sign-In requires **TWO** OAuth clients:
  1. **Web client** (for serverClientId - already have this: `265372630808-uebdmc8rr9kr8vffs0brluuelkh3ofkp`)
  2. **Android client** (for app authentication - this is what was missing!)

The Android client validates your app by checking:
- Package name matches `com.example.das_tern_mcp`
- App signature matches SHA-1 fingerprint

## Verification
After creating the Android client, you should see in Google Cloud Console:
- Web client: 265372630808-uebdmc8rr9kr8vffs0brluuelkh3ofkp
- Android client: (new client ID will be auto-generated)

## If Still Not Working
1. Check OAuth consent screen is configured: https://console.cloud.google.com/apis/credentials/consent?project=das-tern
2. Make sure test users are added if app is in "Testing" status
3. Try `flutter clean && flutter run` to rebuild with fresh config
4. Clear app data on device: Settings → Apps → das_tern_mcp → Clear data

## Quick Copy-Paste Values
```
Package Name: com.example.das_tern_mcp
SHA-1: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF
```
