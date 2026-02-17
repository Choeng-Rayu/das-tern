# Google OAuth Setup WITHOUT Domain (Mobile Only)

## Good News! 

**You DON'T need a domain for mobile apps!** The redirect URIs are only for web-based OAuth flows. Your Flutter app uses native Google Sign-In, so redirects aren't used!

---

## Quick Setup (3 Steps)

### Step 1: Create Web OAuth Client (NO DOMAIN NEEDED!)

1. Go to: https://console.cloud.google.com/apis/credentials?project=das-tern
2. Click **"+ CREATE CREDENTIALS"** → **OAuth client ID**
3. Select **"Web application"**
4. Name: `Das Tern Backend`
5. **Authorized redirect URIs**: Leave EMPTY or use `http://localhost:3001/api/v1/auth/google/callback`
6. Click **CREATE**

**Google allows creating Web clients with NO redirect URIs!** You only need redirects if users login through a web browser, which you're NOT doing!

### Step 2: Copy the Web Client ID

After creating, you'll see:
```
Client ID: 265372630808-XXXXXXXXXXXXX.apps.googleusercontent.com
Client secret: GOCSPX-XXXXXXXXXXXXX
```

**Copy the Client ID!** (starts with `265372630808-`)

### Step 3: Update Your .env Files

Update BOTH:
- `/home/rayu/das-tern/das_tern_mcp/.env`
- `/home/rayu/das-tern/backend_nestjs/.env`

Replace `GOOGLE_CLIENT_ID` with your NEW Web client ID:

```bash
GOOGLE_CLIENT_ID=265372630808-YOUR-NEW-WEB-CLIENT-ID.apps.googleusercontent.com
```

---

## Why This Works

### Your Current OAuth Clients

**Android OAuth client** (you already have):
```
✅ Package: com.example.das_tern_mcp
✅ SHA-1: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF
✅ Purpose: Validates your mobile app
```

**Web OAuth client** (you need to create):
```
❌ Client ID: (NEW - you'll get this)
❌ Redirect URIs: NONE (not needed for mobile!)
❌ Purpose: Backend token verification only
```

### How It Works

```
1. User clicks "Sign in with Google" on phone
   ↓
2. Android OAuth client validates your app (package + SHA-1)
   ↓
3. Google Sign-In returns idToken
   ↓
4. Flutter sends idToken to your backend (192.168.0.189:3001)
   ↓
5. Backend verifies idToken using Web client ID
   ↓ (NO redirect happens here!)
6. User logged in! ✅
```

**The Web client NEVER redirects the user!** It just verifies the token is authentic!

---

## Test It

After creating Web client and updating .env:

```bash
cd /home/rayu/das-tern/das_tern_mcp
flutter clean && flutter pub get && flutter run
```

Try Google Sign-In on your phone - it should work!

---

## Why You Don't Need a Domain

| If you were... | You'd need... |
|----------------|---------------|
| Building a website with "Login with Google" button | Domain + Redirect URIs |
| Building mobile app with backend | Web client (no redirects!) + Android client |
| **← Your case** | **← What you need** |

Your backend just **verifies** tokens, it doesn't **redirect** users. No domain needed!

---

## Troubleshooting

### If it still shows error 10

1. Make sure you created **BOTH**:
   - ✅ Web OAuth client (for serverClientId)
   - ✅ Android OAuth client (you have this)

2. Wait 5-10 minutes for Google to sync

3. Double-check .env files have the **WEB** client ID, not Android client ID

### How to tell which is which?

Go to: https://console.cloud.google.com/apis/credentials?project=das-tern

You should see:
```
📱 Das Tern Android Client (Android)
   └── Package: com.example.das_tern_mcp
   
🌐 Das Tern Backend (Web application)
   └── Use THIS client ID in .env!
```

---

## What About Production?

When deploying to Play Store/App Store:

1. **Android Production**: Create another Android client with production SHA-1
2. **iOS**: Create iOS client with your bundle ID
3. **Web client**: Keep using the same one! No changes needed!

Even in production, mobile apps don't need domain redirects!

---

## Summary

✅ Create Web OAuth client with NO redirect URIs  
✅ Use Web client ID in .env files  
✅ Keep Android client (you already have)  
✅ No domain needed!  
✅ Mobile apps work perfectly without redirect URIs!

**After you create the Web client, send me the Client ID and I'll update your .env files!**
