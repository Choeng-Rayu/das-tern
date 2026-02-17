# Google OAuth Setup for Production (App Store & Google Play)

## Summary: You Need 3 OAuth Clients

| Client Type | Purpose | When Needed |
|-------------|---------|-------------|
| **Web** | Backend authentication (serverClientId) | ✅ NOW (for both Android & iOS) |
| **Android** | Android app validation | ✅ Before Google Play release |
| **iOS** | iOS app validation | ✅ Before App Store release |

---

## 1. Web OAuth Client (CREATE NOW!)

### Why Needed?
Your mobile app sends `idToken` to backend. Backend calls:
```typescript
await this.googleClient.verifyIdToken({
  idToken,
  audience: GOOGLE_CLIENT_ID  // ← Must be WEB client!
});
```

### Setup Steps
1. Go to: https://console.cloud.google.com/apis/credentials?project=das-tern
2. **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Application type: **Web application**
4. Name: `Das Tern Backend (Production)`
5. Authorized redirect URIs:
   ```
   https://your-production-domain.com/api/v1/auth/google/callback
   http://localhost:3001/api/v1/auth/google/callback
   http://192.168.0.189:3001/api/v1/auth/google/callback
   ```
6. Click **CREATE**
7. **Copy the Client ID** (e.g., `265372630808-XXXXX.apps.googleusercontent.com`)
8. Update `.env` files:
   ```bash
   GOOGLE_CLIENT_ID=265372630808-YOUR-WEB-CLIENT-ID.apps.googleusercontent.com
   ```

**This is used by BOTH Android and iOS apps!**

---

## 2. Android OAuth Client (for Google Play)

### Current Status
✅ You have DEBUG version:
- Package: `com.example.das_tern_mcp`
- SHA-1: `DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF` (debug keystore)

### For Production Release
You need a SECOND Android OAuth client with your **production keystore SHA-1**!

#### Step 1: Get Production SHA-1
```bash
# If you have a production keystore
keytool -list -v -keystore /path/to/production.keystore -alias your-alias

# If using Play App Signing, get SHA-1 from:
# Google Play Console → Your App → Setup → App Integrity → App signing
```

#### Step 2: Create Production Android Client
1. Go to: https://console.cloud.google.com/apis/credentials?project=das-tern
2. **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Application type: **Android**
4. Name: `Das Tern Android (Production)`
5. Package name: `com.example.das_tern_mcp`
6. SHA-1: `YOUR-PRODUCTION-SHA1-FINGERPRINT`
7. Click **CREATE**

**Note**: Keep both DEBUG and PRODUCTION Android clients! You need both.

---

## 3. iOS OAuth Client (for App Store)

### When Needed
Before submitting to App Store.

### Setup Steps
1. Get your iOS Bundle ID from: `/das_tern_mcp/ios/Runner.xcodeproj/project.pbxproj`
   - Look for: `PRODUCT_BUNDLE_IDENTIFIER`
   - Example: `com.example.dasTernMcp`

2. Go to: https://console.cloud.google.com/apis/credentials?project=das-tern
3. **+ CREATE CREDENTIALS** → **OAuth client ID**
4. Application type: **iOS**
5. Name: `Das Tern iOS (Production)`
6. Bundle ID: `com.example.dasTernMcp` (your actual bundle ID)
7. Click **CREATE**

**No configuration needed in .env!** iOS client validates automatically.

---

## Final OAuth Clients List (Production)

After completing all steps, you should have:

```
Google Cloud Console → Credentials:
├── Web client (for backend auth)
│   └── Used by: serverClientId in Flutter + backend verifyIdToken
├── Android (Debug)
│   └── Package: com.example.das_tern_mcp
│   └── SHA-1: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF
├── Android (Production)
│   └── Package: com.example.das_tern_mcp
│   └── SHA-1: YOUR-PLAY-STORE-SHA1
└── iOS (Production)
    └── Bundle ID: com.example.dasTernMcp
```

---

## Common Misconception

❌ "Web client is for web browsers"
✅ "Web client is for backend authentication"

**All mobile apps that authenticate with a backend need a Web OAuth client!**

---

## Deployment Checklist

### Before Google Play Release
- [ ] Create Web OAuth client
- [ ] Update GOOGLE_CLIENT_ID in .env with Web client ID
- [ ] Create Android Production OAuth client with release keystore SHA-1
- [ ] Test Google Sign-In on production build

### Before App Store Release
- [ ] Web OAuth client already created ✓
- [ ] Create iOS OAuth client with production bundle ID
- [ ] Update iOS Info.plist with URL scheme (if needed)
- [ ] Test Google Sign-In on TestFlight

---

## Testing Strategy

### Development (Now)
- Use Web client + Android Debug client
- Test on emulators and physical devices

### Staging/Beta
- Use Web client + Android Production client (beta SHA-1)
- Test via Google Play Internal Testing or TestFlight

### Production
- Web client + Android Production + iOS Production
- All clients must be from same Google Cloud project

---

## Why 3 Clients?

1. **Web client**: Proves idToken is valid (backend security)
2. **Android client**: Proves app is yours (prevents impersonation)
3. **iOS client**: Proves app is yours (prevents impersonation)

Google Sign-In checks ALL of them in the flow:
```
User clicks "Sign in with Google"
  ↓
Android/iOS client validates your app (package/bundle + SHA-1)
  ↓
App gets idToken
  ↓
App sends idToken to backend
  ↓
Backend validates idToken using Web client (serverClientId)
  ↓
Success! User authenticated
```

---

## Next Steps

1. **NOW**: Create Web OAuth client (blocks both Android & iOS)
2. **Before Google Play**: Get production SHA-1, create Android production client
3. **Before App Store**: Get bundle ID, create iOS client

**Start with Web client - it's required for everything!**
