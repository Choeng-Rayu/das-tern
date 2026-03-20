# Telegram Authentication Testing Guide

## Quick Start Testing

### Prerequisites
1. Backend server running on `http://10.212.42.210:3001`
2. Flutter app installed on device
3. Telegram app installed on device
4. Internet connection

---

## Test Scenarios

### ✅ Scenario 1: New User Registration via Telegram (Login Screen)

**Steps:**
1. Open DasTern app
2. On login screen, tap **"Continue with Telegram"** button
3. Browser opens with Telegram OAuth page
4. Tap **"Accept"** to authorize
5. App automatically opens and navigates to dashboard

**Expected Result:**
- ✅ User account created with Telegram profile data
- ✅ JWT token stored securely
- ✅ User navigated to Patient dashboard
- ✅ User receives 1-month Premium trial

**Verify in Database:**
```sql
SELECT id, "telegramId", "telegramUsername", "telegramFirstName", 
       "accountStatus", role 
FROM users 
WHERE "telegramId" IS NOT NULL 
ORDER BY "createdAt" DESC LIMIT 1;
```

---

### ✅ Scenario 2: New User Registration via Telegram (Registration Screen)

**Steps:**
1. Open DasTern app
2. Tap **"Create Account"**
3. Select **"Patient"** or **"Doctor"**
4. On registration form (Step 1 or Step 2), tap **"Continue with Telegram"**
5. Complete OAuth flow
6. App navigates to appropriate dashboard

**Expected Result:**
- ✅ Same as Scenario 1
- ✅ Registration form bypassed
- ✅ User role determined by registration flow

---

### ✅ Scenario 3: Existing User Login via Telegram

**Steps:**
1. Use account from Scenario 1 or 2
2. Logout from app
3. On login screen, tap **"Continue with Telegram"**
4. Complete OAuth flow

**Expected Result:**
- ✅ User logged in with existing account
- ✅ No duplicate account created
- ✅ User navigated to correct dashboard

---

### ✅ Scenario 4: Account Linking (Telegram + Email)

**Steps:**
1. Create account via email/password registration
2. Verify email with OTP
3. Logout
4. Login with Telegram using **same email address**
5. Complete OAuth flow

**Expected Result:**
- ✅ Telegram ID linked to existing account
- ✅ User logged in with existing account
- ✅ No duplicate account created

**Verify in Database:**
```sql
SELECT id, email, "telegramId", "telegramUsername" 
FROM users 
WHERE email = 'your-test-email@example.com';
```

---

### ⚠️ Scenario 5: Error Handling - Network Failure

**Steps:**
1. Turn off WiFi/mobile data
2. Tap **"Continue with Telegram"**

**Expected Result:**
- ✅ Error dialog: "Unable to connect right now. Check your internet connection and try again."
- ✅ "Try Again" button available

---

### ⚠️ Scenario 6: Error Handling - User Cancels OAuth

**Steps:**
1. Tap **"Continue with Telegram"**
2. On Telegram OAuth page, tap **"Cancel"** or close browser

**Expected Result:**
- ✅ App remains on login/registration screen
- ✅ No error dialog shown
- ✅ User can retry

---

### ⚠️ Scenario 7: Error Handling - Invalid Token

**Steps:**
1. Manually trigger deep link with invalid token:
   ```bash
   adb shell am start -W -a android.intent.action.VIEW \
     -d "myapp://login-success?token=invalid-token-here"
   ```

**Expected Result:**
- ✅ Error dialog: "Your Telegram login session is invalid or expired. Please try again."
- ✅ User remains on login screen

---

### ✅ Scenario 8: Backward Compatibility - Google OAuth

**Steps:**
1. Tap **"Continue with Google"**
2. Complete Google OAuth flow

**Expected Result:**
- ✅ Google OAuth still works
- ✅ No interference with Telegram auth

---

### ✅ Scenario 9: Backward Compatibility - Email/Password

**Steps:**
1. Register with email/password
2. Verify OTP
3. Login with email/password

**Expected Result:**
- ✅ Email/password auth still works
- ✅ No interference with Telegram auth

---

## API Testing with cURL

### Test Backend Callback Endpoint

```bash
# Test callback with mock Telegram data
curl -X GET "http://10.212.42.210:3001/api/v1/auth/telegram/callback?id=123456789&first_name=Test&last_name=User&username=testuser&photo_url=https://example.com/photo.jpg&auth_date=1710864000&hash=mock-hash-here"
```

**Expected Response:**
- Redirect to `myapp://login-success?token=JWT_TOKEN_HERE`

---

## Database Verification Queries

### Check Telegram Users
```sql
SELECT 
  id, 
  email, 
  "telegramId", 
  "telegramUsername", 
  "telegramFirstName", 
  "telegramLastName",
  "accountStatus",
  role,
  "createdAt"
FROM users 
WHERE "telegramId" IS NOT NULL 
ORDER BY "createdAt" DESC;
```

### Check Premium Trial
```sql
SELECT 
  u.id,
  u."telegramId",
  s.tier,
  s."storageQuota",
  s."expiresAt",
  s."hasUsedTrial"
FROM users u
JOIN subscriptions s ON s."userId" = u.id
WHERE u."telegramId" IS NOT NULL
ORDER BY u."createdAt" DESC;
```

---

## Troubleshooting

### Issue: Browser doesn't open
**Check:**
- `url_launcher` package installed
- Device has default browser
- Internet connection active

**Fix:**
```bash
cd /home/rayu/das-tern/das_tern_mcp
flutter pub get
flutter run
```

---

### Issue: Deep link doesn't work
**Check Android:**
```bash
adb shell dumpsys package | grep -A 5 "myapp"
```

**Check iOS:**
- Verify Info.plist has `myapp` URL scheme
- Rebuild app after changes

---

### Issue: "Invalid authentication data"
**Check:**
- `TELEGRAM_BOT_TOKEN` in backend .env matches BotFather token
- Hash verification is working correctly

**Debug:**
```bash
# Check backend logs
cd /home/rayu/das-tern/backend_nestjs
npm run start:dev
# Watch for "Telegram auth rejected: hash mismatch" messages
```

---

### Issue: "Authentication data has expired"
**Cause:** Auth date is older than 24 hours

**Fix:** User needs to retry authentication (this is expected behavior)

---

## Performance Testing

### Load Test Telegram Endpoints

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Test POST /auth/telegram (should hit rate limit at 5 req/min)
ab -n 10 -c 2 -p telegram-auth-data.json -T application/json \
  http://10.212.42.210:3001/api/v1/auth/telegram

# Test GET /auth/telegram/callback (should hit rate limit at 10 req/min)
ab -n 20 -c 2 \
  "http://10.212.42.210:3001/api/v1/auth/telegram/callback?id=123&first_name=Test&auth_date=1710864000&hash=test"
```

---

## Security Testing

### Test Hash Verification

```bash
# Test with tampered data (should fail)
curl -X GET "http://10.212.42.210:3001/api/v1/auth/telegram/callback?id=123456789&first_name=Hacker&auth_date=1710864000&hash=invalid-hash"
```

**Expected:** 401 Unauthorized - "Invalid authentication data"

### Test Expired Auth Date

```bash
# Test with old timestamp (should fail)
curl -X GET "http://10.212.42.210:3001/api/v1/auth/telegram/callback?id=123456789&first_name=Test&auth_date=1609459200&hash=test"
```

**Expected:** 401 Unauthorized - "Authentication data has expired"

---

## Test Checklist

- [ ] ✅ New user registration via Telegram (login screen)
- [ ] ✅ New user registration via Telegram (patient registration)
- [ ] ✅ New user registration via Telegram (doctor registration)
- [ ] ✅ Existing user login via Telegram
- [ ] ✅ Account linking with matching email
- [ ] ⚠️ Error handling - network failure
- [ ] ⚠️ Error handling - user cancels OAuth
- [ ] ⚠️ Error handling - invalid token
- [ ] ✅ Backward compatibility - Google OAuth
- [ ] ✅ Backward compatibility - email/password
- [ ] 🔒 Security - hash verification
- [ ] 🔒 Security - auth date validation
- [ ] 🔒 Security - rate limiting
- [ ] 📱 Android deep link
- [ ] 📱 iOS deep link
- [ ] 💾 Database - user creation
- [ ] 💾 Database - premium trial
- [ ] 🌐 Localization - English
- [ ] 🌐 Localization - Khmer

---

## Sign-Off

**Tester Name:** ___________________  
**Date:** ___________________  
**All Tests Passed:** [ ] YES [ ] NO  
**Issues Found:** ___________________  
**Ready for Production:** [ ] YES [ ] NO

---

*Last Updated: March 19, 2026*
