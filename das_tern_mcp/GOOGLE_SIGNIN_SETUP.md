# Google Sign-In Setup Guide for Das Tern MCP

## Overview
This guide will help you configure Google Sign-In for the Das Tern MCP Flutter app. The error `ApiException: 10` means the app isn't properly configured with Google's OAuth services.

## Prerequisites
- Firebase project (or Google Cloud Console project)
- Android Studio or access to terminal
- Your app's package name: `com.example.das_tern_mcp`

## Step 1: Create/Configure Firebase Project

### 1.1 Go to Firebase Console
1. Visit [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project: **das-tern** (or similar name)
3. Enable Google Analytics (optional but recommended)

### 1.2 Add Android App to Firebase
1. Click "Add app" → Select Android icon
2. Register app with package name: `com.example.das_tern_mcp`
3. App nickname (optional): "Das Tern MCP Android"
4. Don't download `google-services.json` yet

## Step 2: Get SHA-1 Fingerprint

### 2.1 Debug SHA-1 (for development)
Run this command in your terminal from the project root:

```bash
cd das_tern_mcp/android
./gradlew signingReport
```

Or use keytool directly:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the **SHA-1** fingerprint in the output. It looks like:
```
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

### 2.2 Release SHA-1 (for production)
If you have a release keystore:
```bash
keytool -list -v -keystore /path/to/your-release-key.keystore -alias your-key-alias
```

### 2.3 Add SHA-1 to Firebase
1. In Firebase Console → Project Settings → Your Apps → Android App
2. Scroll down to "SHA certificate fingerprints"
3. Click "Add fingerprint"
4. Paste your SHA-1 fingerprint
5. Click "Save"

## Step 3: Configure OAuth Consent Screen

### 3.1 Go to Google Cloud Console
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to "APIs & Services" → "OAuth consent screen"

### 3.2 Configure Consent Screen
1. Choose "External" user type (unless you have Google Workspace)
2. Click "Create"
3. Fill in:
   - App name: **Das Tern**
   - User support email: your email
   - Developer contact email: your email
4. Click "Save and Continue"
5. Skip "Scopes" → Click "Save and Continue"
6. Add test users (your email) → Click "Save and Continue"
7. Click "Back to Dashboard"

## Step 4: Download google-services.json

### 4.1 Download from Firebase
1. Firebase Console → Project Settings → Your Apps → Android App
2. Click "Download google-services.json"
3. Save the file

### 4.2 Place in Correct Location
Copy `google-services.json` to:
```bash
das_tern_mcp/android/app/google-services.json
```

**IMPORTANT**: The file must be in the `android/app/` directory, NOT in `android/` root!

### 4.3 Verify Structure
The `google-services.json` should contain:
- `project_info.project_id`
- `client[0].oauth_client.client_id` (ending with `.apps.googleusercontent.com`)
- `client[0].api_key[0].current_key`

## Step 5: Enable Google Sign-In Authentication

### 5.1 Enable in Firebase
1. Firebase Console → Authentication → Sign-in method
2. Click "Google" provider
3. Toggle "Enable"
4. Set project support email
5. Click "Save"

## Step 6: Backend Configuration

### 6.1 Get OAuth Client ID
1. Google Cloud Console → APIs & Services → Credentials
2. Find "Web client (auto created by Google Service)" under OAuth 2.0 Client IDs
3. Copy the Client ID (it ends with `.apps.googleusercontent.com`)

### 6.2 Update Backend .env
Add to your `backend_nestjs/.env`:
```env
GOOGLE_CLIENT_ID=your-web-client-id-here.apps.googleusercontent.com
```

## Step 7: Build and Test

### 7.1 Clean and Rebuild
```bash
cd das_tern_mcp
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk --debug
```

### 7.2 Test on Device
```bash
flutter run
```

### 7.3 Test Google Sign-In
1. Open the app
2. Go to Login screen
3. Click "Sign in with Google"
4. Select Google account
5. Should redirect to home screen

## Troubleshooting

### Error: ApiException: 10
**Cause**: Developer error - app not configured correctly

**Solutions**:
1. ✅ Verify `google-services.json` is in `android/app/` directory
2. ✅ Ensure SHA-1 fingerprint is added to Firebase
3. ✅ Check package name matches: `com.example.das_tern_mcp`
4. ✅ Clean and rebuild: `flutter clean && flutter pub get && flutter build apk`
5. ✅ Wait 5-10 minutes after adding SHA-1 (Google needs time to propagate)

### Error: ApiException: 12
**Cause**: Version update required

**Solution**: Update Google Play Services on your device

### Error: ApiException: 7
**Cause**: Network error

**Solution**: Check internet connection

### Error: Sign-in cancelled
**Cause**: User cancelled the Google account picker

**Solution**: This is normal user behavior, not an error

## Verification Checklist

- [ ] Firebase project created
- [ ] Android app registered with package name `com.example.das_tern_mcp`
- [ ] SHA-1 debug fingerprint added to Firebase
- [ ] OAuth consent screen configured
- [ ] Google Sign-In enabled in Firebase Authentication
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] Built and deployed to device
- [ ] Backend has `GOOGLE_CLIENT_ID` configured
- [ ] Internet permission added to AndroidManifest (already done)
- [ ] Google Services plugin added to Gradle (already done)

## Additional Resources

- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Google Sign-In for Android](https://developers.google.com/identity/sign-in/android/start)
- [Flutter Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)

## Notes

### Production Release
When releasing to production:
1. Generate release keystore
2. Get release SHA-1 fingerprint
3. Add release SHA-1 to Firebase
4. Update app in Google Play Console
5. Ensure release OAuth client ID is configured

### Multiple Environments
If you have dev/staging/production:
1. Create separate Firebase projects
2. Use different `google-services.json` for each
3. Use flavor-specific directories in Flutter

## Support

If you continue to have issues after following this guide:
1. Check Firebase Console logs
2. Check Android Logcat for detailed error messages
3. Verify all steps in the checklist above
4. Wait 10-15 minutes after making changes (propagation time)
