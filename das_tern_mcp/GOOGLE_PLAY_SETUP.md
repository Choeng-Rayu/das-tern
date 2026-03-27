# Das Tern — Google Play Console Complete Deployment Guide

> **Your App Details (already configured)**
> - Package name: `com.dastern.app`
> - Production SHA-1: `F8:98:7F:E8:97:0B:76:1F:00:F5:B7:CB:52:92:2D:A4:76:37:6D:53`
> - Keystore: `android/app/release.keystore` | Alias: `dastern` | Password: `DasTern2024SecureKey!`

---

## ⚠️ BEFORE ANYTHING ELSE — Backup Your Keystore

Your keystore is the **only way** to publish updates to your app. If you lose it, you must create a brand new app with a different package name and lose all your users.

**Run this NOW:**
```bash
# Create a backup folder
mkdir -p ~/dastern-keystore-backup

# Copy keystore and credentials
cp /home/rayu/das-tern/das_tern_mcp/android/app/release.keystore ~/dastern-keystore-backup/
cp /home/rayu/das-tern/das_tern_mcp/android/keystore.properties ~/dastern-keystore-backup/

# Verify backup
ls -la ~/dastern-keystore-backup/
```

Then copy `~/dastern-keystore-backup/` to a USB drive or encrypted cloud storage.

---

## PHASE 1 — Build the Release APK

### Step 1.1 — Run the Build

```bash
cd /home/rayu/das-tern/das_tern_mcp
./build_release.sh
```

Or manually:
```bash
cd /home/rayu/das-tern/das_tern_mcp
flutter clean
flutter pub get
flutter build apk --release
```

**Output file:** `build/app/outputs/flutter-apk/app-release.apk`

### Step 1.2 — Verify the APK is Signed Correctly

```bash
/usr/lib/jvm/java-21-openjdk/bin/keytool -printcert -jarfile \
  build/app/outputs/flutter-apk/app-release.apk | grep "SHA1"
```

Expected output:
```
SHA1: F8:98:7F:E8:97:0B:76:1F:00:F5:B7:CB:52:92:2D:A4:76:37:6D:53
```

If the SHA-1 matches → proceed. If not → do NOT upload to Play Store.

---

## PHASE 2 — Google Cloud Console (OAuth Setup)

**Why this comes first:** Google Sign-In will NOT work in production unless you register the production package name and SHA-1 in Google Cloud Console BEFORE uploading to Play Store.

### Step 2.1 — Open Google Cloud Console

1. Open browser → go to: https://console.cloud.google.com/
2. In the top bar, click the **project selector dropdown** (shows current project name)
3. Select your existing project **"das-tern"** (project number: 265372630808)
   - If you don't see it, click **"All"** tab and search for "das-tern"

### Step 2.2 — Navigate to Credentials

1. In the left sidebar, click **"APIs & Services"**
2. Click **"Credentials"** in the submenu
3. You will see a list of existing OAuth 2.0 Client IDs

### Step 2.3 — Create Production Android OAuth Client

1. Click the blue **"+ CREATE CREDENTIALS"** button at the top
2. Select **"OAuth client ID"** from the dropdown

3. On the "Create OAuth client ID" page:
   - **Application type:** Select **"Android"** from the dropdown
   - **Name:** Type `Das Tern Production (Play Store)`
   - **Package name:** Type exactly `com.dastern.app`
   - **SHA-1 certificate fingerprint:** Paste exactly:
     ```
     F8:98:7F:E8:97:0B:76:1F:00:F5:B7:CB:52:92:2D:A4:76:37:6D:53
     ```

4. Click **"CREATE"**

5. A popup appears showing your new Client ID. **Copy and save it** — it looks like:
   ```
   265372630808-XXXXXXXXXXXXXXXXXX.apps.googleusercontent.com
   ```
   (You don't need to put this in your `.env` — Android clients work automatically)

### Step 2.4 — Verify Your Web OAuth Client Exists

The Web client is what your backend uses to verify Google tokens.

1. Still on the Credentials page, look at the list under **"OAuth 2.0 Client IDs"**
2. Find the entry with type **"Web application"**
3. Click on it to open it
4. Verify **"Authorized redirect URIs"** contains:
   ```
   https://api.dastern.site/api/v1/auth/google/callback
   ```
5. If it's missing, click **"+ ADD URI"** and add it, then click **"SAVE"**
6. **Copy the Client ID** (starts with `265372630808-`) — this is your `GOOGLE_CLIENT_ID` in `.env`

### Step 2.5 — Verify Your .env Has the Web Client ID

Open `das_tern_mcp/.env` and confirm:
```
GOOGLE_CLIENT_ID=265372630808-fdi2v66tkfi85ful7gvh88r6rdi80h4u.apps.googleusercontent.com
```

This must be the **Web application** client ID, NOT the Android client ID.

---

## PHASE 3 — Google Play Console Setup

### Step 3.1 — Access Google Play Console

1. Open browser → go to: https://play.google.com/console
2. Sign in with your Google developer account
3. You will land on the **"All apps"** dashboard

### Step 3.2 — Create a New App

1. Click the blue **"Create app"** button (top right)

2. Fill in the form:

   **App details:**
   - **App name:** `Das Tern`
   - **Default language:** `English (United States)` — you can add Khmer later
   - **App or game:** Select **"App"**
   - **Free or paid:** Select **"Free"**

3. **Declarations section** (scroll down):
   - Check **"I accept the Developer Program Policies"**
   - Check **"I acknowledge that my app may be subject to US export laws"**

4. Click **"Create app"** button

5. You are now inside your app's dashboard. The left sidebar shows all sections you need to complete.

---

### Step 3.3 — Complete the Dashboard Setup

The Play Console shows a **"Dashboard"** with a checklist. You must complete all items before publishing. Here is each one:

---

#### 3.3.1 — App Access

**Location:** Left sidebar → **"App content"** → **"App access"**

1. Click **"App access"**
2. Select **"All functionality is available without special access"**
   - (Because Das Tern requires login, select **"All or some functionality is restricted"**)
   - If restricted: Click **"Add new instructions"**
   - Instruction name: `Test Account`
   - Username: `testuser@dastern.site` (create a test account on your backend first)
   - Password: `TestPassword123!`
   - Any other instructions: `Select "Patient" role on registration`
3. Click **"Save"**

---

#### 3.3.2 — Ads Declaration

**Location:** Left sidebar → **"App content"** → **"Ads"**

1. Click **"Ads"**
2. Select **"No, my app does not contain ads"**
3. Click **"Save"**

---

#### 3.3.3 — Content Rating

**Location:** Left sidebar → **"App content"** → **"Content rating"**

1. Click **"Content rating"**
2. Click **"Start questionnaire"**
3. **Email address:** Enter your email
4. **Category:** Select **"Utility, Productivity, Communication, or Other"**
   - (Do NOT select "Medical" — it triggers extra review requirements)
   - Actually for a medication app, select **"Health & Fitness"** if available, otherwise **"Other"**
5. Answer all questions:
   - Violence: **No**
   - Sexual content: **No**
   - Language: **No**
   - Controlled substances: **No** (it's a reminder app, not a pharmacy)
   - User-generated content: **No**
   - Location sharing: **No**
6. Click **"Save questionnaire"**
7. Click **"Calculate rating"**
8. Review the rating (should be **"Everyone"** or **"PEGI 3"**)
9. Click **"Apply rating"**

---

#### 3.3.4 — Target Audience

**Location:** Left sidebar → **"App content"** → **"Target audience and content"**

1. Click **"Target audience and content"**
2. **Target age groups:** Select **"18 and over"**
   - (Medication management is for adults)
3. Click **"Next"**
4. **"Does your app appeal to children?"** → Select **"No"**
5. Click **"Save"**

---

#### 3.3.5 — News App Declaration

**Location:** Left sidebar → **"App content"** → **"News apps"**

1. Click **"News apps"**
2. Select **"This app is not a news app"**
3. Click **"Save"**

---

#### 3.3.6 — COVID-19 Contact Tracing (if shown)

If this section appears:
1. Select **"This app is not a COVID-19 contact tracing or status app"**
2. Click **"Save"**

---

#### 3.3.7 — Data Safety

**Location:** Left sidebar → **"App content"** → **"Data safety"**

This is the most important section. Be accurate — Google verifies this.

1. Click **"Data safety"**
2. Click **"Start"**

**Section 1: Data collection and security**

| Question | Answer |
|----------|--------|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** |
| Do you provide a way for users to request that their data is deleted? | **Yes** (via account deletion in settings) |

**Section 2: Data types**

Click **"Next"** and select the data types your app collects:

- **Personal info:**
  - Name: ✅ Collected (user profile)
  - Email address: ✅ Collected (login)
  - Phone number: ✅ Collected (login/OTP)
  - User IDs: ✅ Collected (account ID)

- **Health and fitness:**
  - Health info: ✅ Collected (vitals, medications)

- **App activity:**
  - App interactions: ✅ Collected (dose tracking)

- **Device or other IDs:**
  - Device or other IDs: ✅ Collected (push notifications)

**Section 3: Data usage and handling**

For each data type, specify:
- **Purpose:** App functionality
- **Is it required or optional?** Required
- **Is it shared with third parties?** No (unless you use analytics)
- **Is it processed ephemerally?** No

3. Click **"Save"** after completing all sections
4. Click **"Submit"**

---

#### 3.3.8 — Government Apps Declaration (if shown)

1. Select **"This app is not a government app"**
2. Click **"Save"**

---

### Step 3.4 — Store Listing

**Location:** Left sidebar → **"Store presence"** → **"Main store listing"**

#### App Details

1. Click **"Main store listing"**

2. **App name:** `Das Tern`

3. **Short description** (max 80 characters):
   ```
   Medication reminder & health tracker for Cambodia
   ```

4. **Full description** (max 4000 characters):
   ```
   Das Tern (ដាស ទឺន) — Your Personal Medication Companion

   Never miss a dose again! Das Tern helps patients and families in Cambodia manage medications easily and safely.

   ✓ SMART MEDICATION REMINDERS
   Set reminders for each medication with custom times. Get notified before each dose so you never forget.

   ✓ PRESCRIPTION MANAGEMENT
   Store and track all your prescriptions in one place. Scan prescriptions with your camera using AI-powered OCR.

   ✓ FAMILY SHARING & CAREGIVER ACCESS
   Share medication schedules with family members or caregivers. Doctors can monitor patient adherence remotely.

   ✓ HEALTH MONITORING
   Track blood pressure, blood glucose, weight, temperature, and blood oxygen levels. View trends over time.

   ✓ ENGLISH & KHMER LANGUAGE
   Full support for both English and Khmer (ភាសាខ្មែរ) — designed for Cambodia.

   ✓ WORKS OFFLINE
   All core features work without internet. Data syncs automatically when you reconnect.

   ✓ SECURE & PRIVATE
   Your health data is encrypted and stored securely. We never sell your data.

   PERFECT FOR:
   • Patients managing multiple medications
   • Elderly patients who need reminders
   • Caregivers and family members
   • Doctors monitoring patient adherence
   • Anyone in Cambodia managing their health

   DISCLAIMER: Das Tern is a medication reminder tool only. It does not provide medical advice, diagnose conditions, or replace professional medical care. Always consult your doctor.

   Download Das Tern today and take control of your health!
   ```

#### Graphics

**Required assets you must prepare:**

| Asset | Size | Format | Notes |
|-------|------|--------|-------|
| App icon | 512×512 px | PNG (no alpha) | Use `assets/logo.png` resized |
| Feature graphic | 1024×500 px | PNG or JPG | Banner shown at top of listing |
| Phone screenshots | Min 2, max 8 | PNG or JPG | 16:9 ratio, min 1080×1920 |

**How to take screenshots:**
1. Run the app on a device: `flutter run --release`
2. Take screenshots of:
   - Home screen (today's medications)
   - Medication list screen
   - Dose reminder notification
   - Khmer language screen
   - Family sharing screen

**Upload screenshots:**
1. Scroll down to **"Phone screenshots"**
2. Click **"Add phone screenshots"**
3. Upload at least 2 screenshots

#### Contact Details

1. **Email:** `support@dastern.site`
2. **Phone:** (optional)
3. **Website:** `https://dastern.site`
4. **Privacy policy:** `https://dastern.site/privacy`

> ⚠️ **You MUST create a privacy policy page** at `https://dastern.site/privacy` before submitting. Google requires this for all apps that collect user data.

5. Click **"Save"**

---

### Step 3.5 — App Releases

**Location:** Left sidebar → **"Release"** → **"Production"**

#### First: Set Up Internal Testing (Recommended)

Before going to production, test with internal testers:

1. Left sidebar → **"Testing"** → **"Internal testing"**
2. Click **"Create new release"**
3. Click **"Upload"** → select `build/app/outputs/flutter-apk/app-release.apk`
4. Wait for upload to complete (may take 2-5 minutes)
5. **Release name:** `1.0.0 - Internal Test`
6. **Release notes:**
   ```
   Initial internal test release.
   - Test all medication reminder features
   - Test Google Sign-In
   - Test offline functionality
   ```
7. Click **"Save"**
8. Click **"Review release"**
9. Click **"Start rollout to Internal testing"**

**Add internal testers:**
1. Click **"Testers"** tab
2. Click **"Create email list"**
3. Add your email and team emails
4. Click **"Save changes"**

#### Then: Production Release

After internal testing passes:

1. Left sidebar → **"Release"** → **"Production"**
2. Click **"Create new release"**
3. Click **"Upload"** → select the same APK
4. **Release name:** `1.0.0`
5. **Release notes (English):**
   ```
   Initial release of Das Tern — Medication Management Platform.

   Features:
   - Medication reminders with custom schedules
   - Prescription scanning with AI
   - Family sharing and caregiver access
   - Health monitoring (vitals tracking)
   - English and Khmer language support
   - Offline support
   ```
6. Click **"Save"**
7. Click **"Review release"**

**Review checklist** — Play Console will show warnings. Common ones:
- ⚠️ "App targets API level below recommended" → Update `targetSdk` in build.gradle.kts if needed
- ⚠️ "Missing privacy policy" → Add URL in store listing
- ⚠️ "Content rating not complete" → Complete Step 3.3.3

8. If no blocking errors, click **"Start rollout to Production"**
9. Select rollout percentage: **10%** (recommended for first release)
10. Click **"Rollout"**

---

### Step 3.6 — App Signing in Play Console

**Location:** Left sidebar → **"Release"** → **"Setup"** → **"App signing"**

When you upload your first APK, Play Console will ask about app signing:

**Option A: Google-managed signing (Recommended)**
1. Select **"Use Google-managed key"**
2. Google will re-sign your APK with their key
3. You get a **Play App Signing certificate** — this is a DIFFERENT SHA-1 than your upload key
4. **IMPORTANT:** After enabling this, go to **"App signing"** page and copy the **"App signing key certificate"** SHA-1
5. You must add THIS new SHA-1 to Google Cloud Console as another Android OAuth client

**Option B: Self-managed signing**
1. Select **"Use a locally managed key"**
2. Your upload key IS the signing key
3. The SHA-1 you already registered (`F8:98:7F:E8:97:0B:76:1F:00:F5:B7:CB:52:92:2D:A4:76:37:6D:53`) is correct

> **Recommendation:** Use **Option A (Google-managed)** for better security. But after enabling it, you MUST update Google Cloud Console with the new Play App Signing SHA-1.

**If you chose Option A — Get the Play App Signing SHA-1:**
1. Left sidebar → **"Release"** → **"Setup"** → **"App signing"**
2. Under **"App signing key certificate"**, copy the **SHA-1 certificate fingerprint**
3. Go back to Google Cloud Console → Credentials
4. Create ANOTHER Android OAuth client with:
   - Package: `com.dastern.app`
   - SHA-1: (the new Play App Signing SHA-1)

---

## PHASE 4 — Post-Upload Verification

### Step 4.1 — Check for Policy Violations

After uploading, Play Console may flag issues:

**Location:** Left sidebar → **"Policy"** → **"Policy status"**

Common issues for medical apps:
- **"Sensitive content"** → Add disclaimer in description
- **"Health claims"** → Remove any medical claims from description
- **"Permissions"** → Justify each permission in the declaration

### Step 4.2 — Monitor Review Status

**Location:** Left sidebar → **"Dashboard"**

- **"In review"** → Google is reviewing (takes 1-7 days for new apps)
- **"Published"** → Live on Play Store
- **"Rejected"** → See rejection reason and fix

### Step 4.3 — Test Google Sign-In After Publishing

After the app is live:
1. Install from Play Store (not sideloaded APK)
2. Try Google Sign-In
3. If it fails with error 10:
   - Check that the Android OAuth client in Google Cloud has the correct SHA-1
   - If you used Google-managed signing, use the Play App Signing SHA-1 (not your upload key SHA-1)
   - Wait 15-30 minutes after creating the OAuth client

---

## PHASE 5 — Privacy Policy (Required)

You MUST have a privacy policy page. Here is a template:

**Create this page at `https://dastern.site/privacy`:**

```
Privacy Policy for Das Tern

Last updated: March 24, 2026

Das Tern ("we", "our", "us") operates the Das Tern mobile application.

INFORMATION WE COLLECT
- Account information: name, email, phone number
- Health data: medications, prescriptions, vital signs
- Usage data: dose tracking, app interactions

HOW WE USE YOUR INFORMATION
- To provide medication reminder services
- To enable family sharing features
- To sync data across devices

DATA STORAGE
- Your data is stored securely on servers in [your server location]
- All data is encrypted in transit using HTTPS
- We do not sell your data to third parties

YOUR RIGHTS
- You can delete your account and all data at any time
- Contact us at: support@dastern.site

CONTACT
Email: support@dastern.site
Website: https://dastern.site
```

---

## PHASE 6 — Common Errors and Fixes

### Error: "Your APK or Android App Bundle needs to be signed"

**Fix:**
```bash
# Verify keystore.properties has correct values
cat /home/rayu/das-tern/das_tern_mcp/android/keystore.properties

# Rebuild
cd /home/rayu/das-tern/das_tern_mcp
flutter clean && flutter build apk --release
```

### Error: "You uploaded an APK with an invalid signature"

**Fix:** The keystore file may be corrupted. Verify:
```bash
/usr/lib/jvm/java-21-openjdk/bin/keytool -list -v \
  -keystore /home/rayu/das-tern/das_tern_mcp/android/app/release.keystore \
  -alias dastern -storepass DasTern2024SecureKey!
```

### Error: "Package name already exists"

**Fix:** `com.dastern.app` may already be taken. Check by searching on Play Store. If taken, change to `site.dastern.app` and update `build.gradle.kts`.

### Error: "Google Sign-In fails in production (Error 10)"

**Fix:**
1. Go to Google Cloud Console → Credentials
2. Verify Android OAuth client exists with:
   - Package: `com.dastern.app`
   - SHA-1: matches your signing key
3. If using Play App Signing, use the Play App Signing SHA-1 (not upload key SHA-1)
4. Wait 30 minutes after creating/updating OAuth client

### Error: "App rejected — Sensitive permissions"

Das Tern uses these permissions that may require justification:
- `CAMERA` → For prescription scanning (OCR feature)
- `POST_NOTIFICATIONS` → For medication reminders
- `SCHEDULE_EXACT_ALARM` → For precise dose reminder timing
- `RECEIVE_BOOT_COMPLETED` → To restore reminders after device restart

**Fix:** In Play Console → App content → Permissions, add justification for each.

---

## Quick Reference

| Item | Value |
|------|-------|
| Package Name | `com.dastern.app` |
| Upload Key SHA-1 | `F8:98:7F:E8:97:0B:76:1F:00:F5:B7:CB:52:92:2D:A4:76:37:6D:53` |
| Keystore file | `android/app/release.keystore` |
| Key alias | `dastern` |
| Keystore password | `DasTern2024SecureKey!` |
| Backend API | `https://api.dastern.site/api/v1` |
| Google Cloud Project | `das-tern` (265372630808) |
| Web OAuth Client ID | `265372630808-fdi2v66tkfi85ful7gvh88r6rdi80h4u.apps.googleusercontent.com` |

---

## Deployment Checklist

### Before Building
- [ ] Keystore backed up to secure location
- [ ] `android/keystore.properties` has correct passwords
- [ ] `android/app/build.gradle.kts` has `applicationId = "com.dastern.app"`
- [ ] `pubspec.yaml` version is correct (e.g., `1.0.0+1`)

### Before Uploading to Play Store
- [ ] APK built with `flutter build apk --release`
- [ ] APK SHA-1 verified matches keystore
- [ ] Android OAuth client created in Google Cloud Console
- [ ] Privacy policy page is live at `https://dastern.site/privacy`
- [ ] Test account created for Play Console review

### In Play Console
- [ ] App created with correct package name
- [ ] Store listing complete (description, screenshots, icon)
- [ ] Content rating completed
- [ ] Data safety form completed
- [ ] App access instructions added
- [ ] Internal testing done first
- [ ] Production release submitted

### After Publishing
- [ ] Install from Play Store and test Google Sign-In
- [ ] Verify all features work in production
- [ ] Monitor crash reports in Play Console → Android vitals

---

**Last Updated:** March 24, 2026
