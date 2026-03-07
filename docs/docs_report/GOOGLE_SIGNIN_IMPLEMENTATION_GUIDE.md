# Google Sign-In Implementation Guide

**Date:** March 2, 2026  
**Project:** Das Tern (das-tern)  
**Scope:** Login & Register via Google OAuth — Backend (NestJS) + Frontend (Flutter)

---

## Current State Analysis

| Component | Status |
|-----------|--------|
| Backend `POST /auth/google` endpoint | ✅ Done |
| Backend `googleLoginMobile()` service | ✅ Done |
| Flutter `google_sign_in` package | ✅ Done |
| Flutter `AuthProvider.signInWithGoogle()` | ✅ Done |
| Flutter `ApiService.googleLogin()` | ✅ Done |
| Login screen Google button wired | ✅ Done |
| Backend `.env` `GOOGLE_CLIENT_ID` | ✅ Done |
| `google-services.json` on Android | ❌ MISSING |
| Android Gradle Google Services plugin | ❌ MISSING |
| Android OAuth client (SHA-1 registered) | ⚠️ Must verify |
| Google button on Register screens | ❌ Not added |

---

## Step 1 — Google Cloud Console Setup

Go to https://console.cloud.google.com and open your project (das-tern).

### 1.1 Verify OAuth Consent Screen

Navigate to **APIs & Services → OAuth consent screen**.  
Ensure it is configured with your app name, support email, and authorized domains.

### 1.2 Create an Android OAuth Client

Navigate to **APIs & Services → Credentials → Create Credentials → OAuth Client ID**.

- Application type: **Android**
- Package name: `com.example.das_tern_mcp`  
  (from `das_tern_mcp/android/app/build.gradle.kts` line 8)
- SHA-1 certificate fingerprint — get it by running:

```bash
# In das_tern_mcp/android/
./gradlew signingReport

# OR for debug keystore directly:
keytool -keystore ~/.android/debug.keystore -list -v -storepass android
```

Copy the SHA-1 from the **debug** keystore output and paste it into the Google Cloud Console form, then click **Create**.

### 1.3 Download `google-services.json`

After creating the Android OAuth client, click **Download google-services.json** and place it at:

```
das_tern_mcp/android/app/google-services.json
```

> ⚠️ This file must NOT be committed to a public repository. Add it to `.gitignore`.

---

## Step 2 — Android Gradle Plugin Configuration

The `google-services` Gradle plugin is required to process `google-services.json`.  
Your current build files are missing it.

### 2.1 Root `android/build.gradle.kts`

Add the Google Services classpath inside `buildscript`:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")   // ADD THIS
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
// ... rest of file unchanged
```

### 2.2 App `android/app/build.gradle.kts`

Add the plugin at the top of the `plugins` block:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // ADD THIS
}
```

---

## Step 3 — Flutter `.env` Verification

Your `das_tern_mcp/.env` already has:

```dotenv
GOOGLE_CLIENT_ID=...
```

This is the **WEB** client ID. It is passed as `serverClientId` in `auth_provider.dart`:

```dart
late final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],  // ✅ Must be the WEB client ID
);
```

> **Important:** `serverClientId` must be the **WEB** OAuth 2.0 client ID (not the Android one).  
> This is how the backend can verify the `idToken` using `google-auth-library`.  
> Your current `.env` value is correct — do not change it.

---

## Step 4 — Backend `.env` Verification

Your `backend_nestjs/.env` already has:

```dotenv
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_CALLBACK_URL=http://localhost:3001/api/v1/auth/google/callback
```

These are used in:
- `google.strategy.ts` — web OAuth browser flow
- `AuthService.googleLoginMobile()` — mobile ID token verification

Both are already wired correctly. **No changes needed.**

---

## Step 5 — Add Google Sign-In to Register Screens

The login screen already has Google sign-in. The register screens do not.

### Recommended Registration Flow via Google

```
User opens app
  → Taps "Register"
  → RegisterRoleScreen: selects "Patient" or "Doctor"
  → Taps "Continue with Google" (new button to add)
  → AuthProvider.signInWithGoogle(userRole: 'PATIENT' | 'DOCTOR')
  → Backend creates user automatically if not exists
  → Navigate to /patient or /doctor shell
```

### 5.1 Add handler to `register_role_screen.dart`

The `RegisterRoleScreen` widget needs to become a `StatelessWidget` with `context.read<AuthProvider>()`:

```dart
// Add this helper method inside the widget or as a top-level function
Future<void> _handleGoogleRegister(BuildContext context, String role) async {
  final auth = context.read<AuthProvider>();
  final success = await auth.signInWithGoogle(userRole: role);
  if (!context.mounted) return;
  if (success) {
    final userRole = auth.userRole;
    Navigator.of(context).pushReplacementNamed(
      userRole == 'DOCTOR' ? '/doctor' : '/patient',
    );
  } else if (auth.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error!),
        backgroundColor: AppColors.alertRed,
      ),
    );
  }
}
```

### 5.2 Add Google buttons to role cards

Below the existing Patient and Doctor role selection cards, add a divider and Google sign-in options:

```dart
// After the role cards — add divider
const Padding(
  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
  child: Row(
    children: [
      Expanded(child: Divider(color: Colors.white30)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text('OR', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ),
      Expanded(child: Divider(color: Colors.white30)),
    ],
  ),
),

// Google sign-in as patient
AuthSocialButton(
  label: l10n.continueWithGoogleAsPatient,  // add to arb files
  onPressed: () => _handleGoogleRegister(context, 'PATIENT'),
),
const SizedBox(height: AppSpacing.sm),

// Google sign-in as doctor
AuthSocialButton(
  label: l10n.continueWithGoogleAsDoctor,   // add to arb files
  onPressed: () => _handleGoogleRegister(context, 'DOCTOR'),
),
```

### 5.3 Add localization strings

In `lib/l10n/app_en.arb`:
```json
"continueWithGoogleAsPatient": "Continue as Patient with Google",
"continueWithGoogleAsDoctor": "Continue as Doctor with Google"
```

In `lib/l10n/app_km.arb`:
```json
"continueWithGoogleAsPatient": "បន្តជាអ្នកជំងឺជាមួយ Google",
"continueWithGoogleAsDoctor": "បន្តជាវេជ្ជបណ្ឌិតជាមួយ Google"
```

---

## Step 6 — iOS Setup (If Targeting iOS)

### 6.1 Create iOS OAuth Client

In Google Cloud Console → Credentials → Create OAuth Client ID → **iOS**:
- Bundle ID: check `ios/Runner/Info.plist` for `CFBundleIdentifier`

### 6.2 Download `GoogleService-Info.plist`

Place it at:
```
das_tern_mcp/ios/Runner/GoogleService-Info.plist
```

### 6.3 Add URL scheme to `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Get REVERSED_CLIENT_ID from GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.265372630808-XXXXXXXXXX</string>
    </array>
  </dict>
</array>
```

---

## Step 7 — How the Backend Creates Users (Logic Reference)

When the Flutter app calls `POST /auth/google` with a valid `idToken`:

```
Backend receives { idToken, userRole? }
  → Verifies idToken with Google (google-auth-library)
  → Extracts { googleId, email, firstName, lastName, picture }
  → Checks DB: user exists by googleId OR email?
      YES → updates googleId/picture if missing → login()
      NO  → creates new user with role (default: PATIENT)
           → creates FREEMIUM subscription (if PATIENT)
           → login()
  → Returns { accessToken, refreshToken, user }
```

File references:
- Endpoint: `backend_nestjs/src/modules/auth/auth.controller.ts` — `POST /auth/google`
- Service logic: `backend_nestjs/src/modules/auth/auth.service.ts` — `googleLoginMobile()`
- DTO: `backend_nestjs/src/modules/auth/dto/google-login.dto.ts`

---

## Step 8 — Test the Full Flow

### 8.1 Backend unit test (manual curl)

```bash
# 1. Temporarily log the idToken in AuthProvider.signInWithGoogle() on Flutter
#    by adding: debugPrint('ID TOKEN: ${googleAuth.idToken}');
# 2. Run the app, trigger Google Sign-In, copy the token from logs
# 3. Call backend:

curl -X POST http://localhost:3001/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"idToken": "<paste_real_id_token_here>", "userRole": "PATIENT"}'
```

Expected response:
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "user": {
    "id": "...",
    "email": "user@gmail.com",
    "role": "PATIENT",
    "googleId": "...",
    ...
  }
}
```

### 8.2 Flutter analysis before testing

```bash
cd das_tern_mcp
flutter analyze
# Must show 0 issues before testing
```

### 8.3 Device test

> ⚠️ Google Sign-In does NOT work on most Android emulators. Use a **real physical device**.

```bash
flutter run --debug
```

---

## Summary Checklist

| # | Action | File / Location | Status |
|---|--------|-----------------|--------|
| 1 | Create Android OAuth client in Google Cloud Console | Google Cloud Console | ❌ TODO |
| 2 | Place `google-services.json` in Android app folder | `android/app/google-services.json` | ❌ TODO |
| 3 | Add Google Services classpath to root gradle | `android/build.gradle.kts` | ❌ TODO |
| 4 | Apply Google Services plugin in app gradle | `android/app/build.gradle.kts` | ❌ TODO |
| 5 | Add Google register buttons to register role screen | `lib/ui/screens/auth/register_role_screen.dart` | ❌ TODO |
| 6 | Add localization strings (EN + KM) | `lib/l10n/app_en.arb`, `lib/l10n/app_km.arb` | ❌ TODO |
| 7 | *(iOS only)* Create iOS OAuth client | Google Cloud Console | ❌ TODO |
| 8 | *(iOS only)* Place `GoogleService-Info.plist` | `ios/Runner/` | ❌ TODO |
| 9 | *(iOS only)* Add `REVERSED_CLIENT_ID` URL scheme | `ios/Runner/Info.plist` | ❌ TODO |
| 10 | Run `flutter analyze` — must show 0 issues | `das_tern_mcp/` | ❌ TODO |
| 11 | Test on real physical Android device | Device | ❌ TODO |

### Already Complete — No Changes Needed

- `backend_nestjs/src/modules/auth/auth.controller.ts` — `POST /auth/google`
- `backend_nestjs/src/modules/auth/auth.service.ts` — `googleLoginMobile()`
- `backend_nestjs/src/modules/auth/strategies/google.strategy.ts`
- `backend_nestjs/src/modules/auth/dto/google-login.dto.ts`
- `das_tern_mcp/lib/providers/auth_provider.dart` — `signInWithGoogle()`
- `das_tern_mcp/lib/services/api_service.dart` — `googleLogin()`
- `das_tern_mcp/lib/ui/screens/auth/login_screen.dart` — Google button
- `das_tern_mcp/pubspec.yaml` — `google_sign_in: ^6.2.1`
- Both `.env` files — `GOOGLE_CLIENT_ID` configured
