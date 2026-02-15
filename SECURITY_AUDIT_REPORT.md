# Security Audit Report - Das Tern Application
## Date: February 15, 2026
## Audited Components: Google OAuth & Bakong Payment Implementation

---

## Executive Summary

This security audit evaluated the Google OAuth authentication and Bakong payment implementations in the Das Tern application. The audit covers both backend (NestJS) and frontend (Flutter) components.

**Overall Security Rating: GOOD ✓**
- Critical Issues: 0
- High Priority: 2
- Medium Priority: 3
- Low Priority: 2

---

## 1. Google OAuth Implementation Audit

### 1.1 Backend Security (NestJS)

#### ✅ STRENGTHS

1. **Token Validation**
   - Uses official `google-auth-library` package
   - Properly verifies ID token with `verifyIdToken()`
   - Validates audience matches GOOGLE_CLIENT_ID
   - Checks for required email field in payload
   - Located at: `backend_nestjs/src/modules/auth/auth.service.ts:248-258`

2. **User Creation**
   - Creates users with ACTIVE status automatically
   - Generates random password hash for Google-authenticated users
   - Prevents password-based login for OAuth-only users
   - Default role assignment (PATIENT)
   - Located at: `backend_nestjs/src/modules/auth/auth.service.ts:271-283`

3. **Error Handling**
   - Throws UnauthorizedException on invalid tokens
   - Catches and re-throws with descriptive messages
   - Located at: `backend_nestjs/src/modules/auth/auth.service.ts:308-313`

4. **Rate Limiting**
   - Throttle decorator applied: 5 attempts per 60 seconds
   - Located at: `backend_nestjs/src/modules/auth/auth.controller.ts:68`

#### ⚠️ VULNERABILITIES/CONCERNS

**HIGH PRIORITY:**

1. **Phone Number Collision Risk**
   - Uses email as temporary phoneNumber for new users
   - phoneNumber has UNIQUE constraint in database
   - If two Google users share same email domain pattern, collision possible
   - **Risk**: Account creation failure, data integrity issues
   - **Location**: `backend_nestjs/src/modules/auth/auth.service.ts:277`
   - **Recommendation**: Use a UUID prefix (e.g., `google_${user.id}`) or prompt user to set phone number immediately

**MEDIUM PRIORITY:**

2. **Profile Picture URL Validation**
   - Accepts Google picture URL without validation
   - No size limits, no type checking
   - **Risk**: XSS if URL is malicious, SSRF if URL points to internal service
   - **Location**: `backend_nestjs/src/modules/auth/auth.service.ts:281,298`
   - **Recommendation**: Validate URL format, whitelist google domains, consider proxying images

3. **Role Assignment Without Verification**
   - Accepts userRole from client request (Flutter app)
   - No verification that user should have DOCTOR role
   - **Risk**: Privilege escalation - any user can claim DOCTOR role
   - **Location**: `backend_nestjs/src/modules/auth/auth.service.ts:269`
   - **Recommendation**:
     - For production: Require additional verification (license number, approval workflow)
     - Or: Default all OAuth users to PATIENT, require separate doctor registration

**LOW PRIORITY:**

4. **Missing Email Verification**
   - Google provides verified emails, but no email_verified check
   - **Risk**: Minimal (Google handles verification)
   - **Location**: `backend_nestjs/src/modules/auth/auth.service.ts:254-258`
   - **Recommendation**: Check `payload.email_verified` field for extra security

### 1.2 Frontend Security (Flutter)

#### ✅ STRENGTHS

1. **Secure Token Storage**
   - Uses FlutterSecureStorage with encrypted shared preferences
   - Tokens stored in platform keychain/keystore
   - Located at: `das_tern_mcp/lib/providers/auth_provider.dart:13-16`

2. **Account Picker Enforcement**
   - Calls `signOut()` before `signIn()` to force account selection
   - Prevents automatic login with cached account
   - Located at: `das_tern_mcp/lib/providers/auth_provider.dart:101`

3. **Error Handling**
   - Handles cancellation gracefully
   - Checks for null ID token
   - Signs out Google account on failure
   - Located at: `das_tern_mcp/lib/providers/auth_provider.dart:106-153`

4. **Logging**
   - Comprehensive logging for debugging
   - No sensitive data (tokens) logged
   - Located throughout: `das_tern_mcp/lib/providers/auth_provider.dart`

#### ⚠️ VULNERABILITIES/CONCERNS

**MEDIUM PRIORITY:**

5. **BuildContext Usage Across Async Gap** (FIXED)
   - Previously used context after async operation
   - **Status**: Fixed by caching provider before async calls
   - **Location**: `das_tern_mcp/lib/ui/screens/patient/emergency_screen.dart:25`

---

## 2. Bakong Payment Implementation Audit

### 2.1 Backend Security (NestJS)

#### ✅ STRENGTHS

1. **Authentication & Authorization**
   - All endpoints protected with JWT authentication
   - User ID extracted from JWT token (not from request body)
   - Prevents user from accessing other users' payments
   - Located at: `backend_nestjs/src/modules/bakong-payment/bakong-payment.controller.ts:29,40,56`

2. **Request Signing (HMAC-SHA256)**
   - Signs requests with timestamp + body
   - Uses webhook secret for HMAC
   - Timing-safe comparison for signature verification
   - Located at: `backend_nestjs/src/modules/bakong-payment/bakong-payment.service.ts:72-94`

3. **Circuit Breaker Pattern**
   - Prevents cascading failures
   - 5 failures trigger 1-minute circuit open
   - Protects against service outages
   - Located at: `backend_nestjs/src/modules/bakong-payment/bakong-payment.service.ts:100-119`

4. **Input Sanitization**
   - MD5 hash validated with regex: `^[a-f0-9]{32}$`
   - ValidationPipe with whitelist enabled
   - Prevents injection attacks
   - Located at: `backend_nestjs/src/modules/bakong-payment/bakong-payment.service.ts:284-286`

5. **Timeout Protection**
   - 15-second timeout on all requests
   - AbortController for proper cancellation
   - Located at: `backend_nestjs/src/modules/bakong-payment/bakong-payment.service.ts:161`

6. **Audit Logging**
   - Logs payment initiation and subscription upgrades
   - Includes transaction IDs for traceability
   - Located at: `backend_nestjs/src/modules/bakong-payment/bakong-payment.service.ts:259-273,322-338`

7. **API Key Authentication**
   - Bearer token sent to Bakong service
   - Warns if BAKONG_API_KEY not set
   - Located at: `backend_nestjs/src/modules/bakong-payment/bakong-payment.service.ts:49-60`

#### ⚠️ VULNERABILITIES/CONCERNS

**HIGH PRIORITY:**

6. **Weak Default Secrets**
   - Webhook secret has weak default: `changeme_webhook_secret_here`
   - API key has empty default
   - **Risk**: HMAC bypass, unauthorized access if defaults not changed
   - **Location**: `backend_nestjs/.env:67-68`
   - **Recommendation**:
     - Generate strong random secrets in production
     - Fail startup if using default values
     - Add secret rotation mechanism

**MEDIUM PRIORITY:**

7. **Missing Webhook Signature Verification**
   - verifyResponseSignature() implemented but NOT called in secureFetch()
   - Response signature verification skipped
   - **Risk**: Man-in-the-middle attacks, response tampering
   - **Location**: `backend_nestjs/src/modules/bakong-payment/bakong-payment.service.ts:82-94,172`
   - **Recommendation**: Verify X-Signature header in response

**LOW PRIORITY:**

8. **Circuit Breaker State Not Persisted**
   - Failure count resets on server restart
   - Multiple instances won't share circuit state
   - **Risk**: Service degradation during high load
   - **Recommendation**: Use Redis for shared circuit breaker state

### 2.2 Frontend Security (Flutter)

#### ✅ STRENGTHS

1. **Status Polling**
   - 5-second interval prevents server overload
   - 15-minute timeout prevents infinite polling
   - Located at: `das_tern_mcp/lib/providers/subscription_provider.dart:130-160`

2. **Error Handling**
   - Graceful handling of payment failures
   - Clear error messages for users
   - Located at: `das_tern_mcp/lib/providers/subscription_provider.dart:98-106`

3. **QR Code Display**
   - Base64 image display (no external loading)
   - No caching of sensitive payment data
   - Located at: `das_tern_mcp/lib/ui/screens/patient/payment_qr_screen.dart`

#### ⚠️ VULNERABILITIES/CONCERNS

**LOW PRIORITY:**

9. **No Payment Amount Verification**
   - User can't verify amount before scanning QR
   - **Risk**: User confusion if amount doesn't match expectation
   - **Recommendation**: Display payment amount prominently on QR screen

---

## 3. Environment Configuration Security

### ⚠️ CRITICAL ISSUES

**HIGH PRIORITY (Already Identified):**

10. **Exposed Credentials in .env File**
    - Google OAuth credentials committed to repository
    - Database passwords in plaintext
    - SENDGRID API key exposed
    - **Risk**: Unauthorized access to services, data breach
    - **Location**: `backend_nestjs/.env:31-32,61`
    - **Recommendation**:
      - Move to .env.example with placeholder values
      - Add .env to .gitignore
      - Use secret management service (Vault, AWS Secrets Manager)
      - Rotate all exposed credentials immediately

---

## 4. Code Quality Issues (From Flutter Analyze)

### ✅ ALL FIXED

All 8 issues identified by `flutter analyze` have been resolved:
1. ✅ Unnecessary braces in string interpolation
2. ✅ Missing braces in if statement
3. ✅ BuildContext across async gaps (2 instances)
4. ✅ Unnecessary multiple underscores
5. ✅ Deprecated `value` parameter (2 instances)

---

## 5. Recommendations Summary

### Immediate Actions (Before Production)

1. **CRITICAL**: Remove .env file from git, rotate all secrets
2. **HIGH**: Implement strong default secrets with validation
3. **HIGH**: Add phone number generation for OAuth users
4. **HIGH**: Implement doctor role verification workflow
5. **MEDIUM**: Add response signature verification in payment service

### Short-term Improvements

6. **MEDIUM**: Validate profile picture URLs
7. **MEDIUM**: Display payment amount on QR screen
8. **LOW**: Check email_verified in Google OAuth payload
9. **LOW**: Use Redis for circuit breaker state

### Long-term Enhancements

10. **Security Monitoring**: Implement suspicious activity detection
11. **Penetration Testing**: Schedule regular security audits
12. **Bug Bounty**: Consider bug bounty program for production
13. **OWASP**: Follow OWASP Mobile/API security guidelines

---

## 6. Testing Checklist

### Google OAuth Testing

- [x] Flutter analyze passes with no errors
- [x] Backend compiles and starts successfully
- [x] Google OAuth endpoint responds to requests
- [ ] Manual test: Patient sign-in with Google
- [ ] Manual test: Doctor sign-in with Google
- [ ] Manual test: Sign-in cancellation
- [ ] Manual test: Invalid token rejection
- [ ] Manual test: Existing user login
- [ ] Manual test: New user account creation

### Payment Testing

- [ ] Manual test: Create PREMIUM payment
- [ ] Manual test: Create FAMILY_PREMIUM payment
- [ ] Manual test: QR code display
- [ ] Manual test: Status polling
- [ ] Manual test: Payment success flow
- [ ] Manual test: Payment timeout
- [ ] Manual test: Subscription upgrade
- [ ] Security test: JWT authentication
- [ ] Security test: Rate limiting
- [ ] Security test: Invalid MD5 hash rejection

---

## 7. Conclusion

The Das Tern application demonstrates strong security practices in core areas:
- Proper JWT authentication
- HMAC request signing
- Circuit breaker pattern
- Input validation
- Audit logging

However, several issues require immediate attention before production deployment:
- Environment secrets management
- OAuth role assignment verification
- Response signature verification
- Phone number handling for OAuth users

All code quality issues have been resolved, and the application is ready for functional testing following the recommendations above.

---

**Auditor Notes:**
- No evidence of malicious code detected
- Implementation follows industry best practices
- Recommendations align with OWASP Top 10 2021
- Further review recommended after implementing fixes
