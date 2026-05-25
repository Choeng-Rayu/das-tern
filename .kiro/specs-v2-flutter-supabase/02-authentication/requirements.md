# Requirements: Authentication & Profile Bootstrap

> **Updated by ADDENDUM-001 § 2.4 (2026-05-25):** Three MVP auth methods — Google OAuth, Telegram OAuth, and email/phone + password. Two role-specific sign-up paths (Patient vs Doctor). Sign-in auto-detects role. Apple Sign-In is deferred to the iOS phase.

## Introduction

This spec defines how users sign up and sign in to Das Tern v2 using Supabase Auth. v2 MVP supports three methods:

1. **Google native sign-in** via `google_sign_in` + `supabase.auth.signInWithIdToken`.
2. **Telegram Login 2.0 OIDC PKCE** via the `auth-telegram` Supabase Edge Function.
3. **email/phone + password** (manual sign-up + sign-in).

Sign-up is split into two role-specific paths — Patient or Doctor — and each results in a `profiles` row with the appropriate role regardless of which method the user picks. Sign-in is unified: the user picks any method, authenticates, and the system routes to the correct home screen based on the stored role.

The legacy NestJS auth module is retired. Apple Sign-In stays out of MVP and will be added in v2.1+.

## Glossary

- **Supabase_Auth** — Supabase's GoTrue-based authentication service.
- **Auth_Method** — One of: Google OAuth, Telegram OIDC, email/phone + password.
- **Credential** — Either an email address or a phone number (E.164), paired with a password (only used by the manual method).
- **Role_Sign_Up_Path** — One of two sign-up flows: "Sign up as Patient" or "Sign up as Doctor". Each flow ends with the same authenticated session but produces a different `profiles.role`.
- **Profile_Bootstrap** — The post-sign-up step that fills in role-specific fields (full name minimum; doctor verification deferred).
- **Auto_Role_Detection** — The sign-in step that reads `profiles.role` after authentication to choose the patient home or doctor home.
- **Pending_Role_Provider** — A transient client-side store (Riverpod + flutter_secure_storage) that holds the role chosen at the welcome screen for the duration of the auth flow.

## Requirements

### Requirement 1: Welcome screen — role chooser then method chooser

**User Story:** As a new user, I want to choose whether I'm a Patient or a Doctor, then pick how to sign up, so that the app can route me correctly.

#### Acceptance Criteria

1. THE Flutter_App SHALL show a Welcome screen with: language toggle (Khmer/English), app logo, two role chooser buttons ("Sign up as Patient", "Sign up as Doctor"), and a "I already have an account" link to sign-in.
2. WHEN a role is tapped, THE Flutter_App SHALL store the chosen role in `Pending_Role_Provider` and navigate to the **method chooser** screen.
3. THE method chooser SHALL show three options in this order: "Continue with Google", "Continue with Telegram", "Continue with email/phone".
4. THE method chooser SHALL allow the user to back-navigate and pick a different role without losing the role choice (it persists until consumed by a successful first-time bootstrap or until the user explicitly cancels).
5. THE Flutter_App SHALL persist the chosen role using `flutter_secure_storage` so it survives a brief OAuth round-trip through an external browser.

### Requirement 2: Sign-in — same three methods, no role prompt

**User Story:** As a returning user, I want to sign in with whichever method I used originally, so that I'm taken to my home screen.

#### Acceptance Criteria

1. THE Flutter_App SHALL show a Sign-in screen with: "Continue with Google", "Continue with Telegram", and a credential field + password section for email/phone sign-in.
2. THE Sign-in screen SHALL NOT prompt for role; the role is read from the existing `profiles.role` after authentication.
3. THE Sign-in screen SHALL provide "Forgot password?" only on the email/phone path; OAuth methods do not have password recovery (they use the upstream provider's flow).
4. WHEN authentication succeeds, THE Flutter_App SHALL redirect via the role-aware router (patient home or doctor home).

### Requirement 3: Google native sign-in

**User Story:** As a user with a Google account, I want one-tap sign-in/sign-up using my Google identity.

#### Acceptance Criteria

1. THE Flutter_App SHALL display a "Continue with Google" button on both sign-up and sign-in screens.
2. WHEN tapped on sign-up, THE Flutter_App SHALL ensure `Pending_Role_Provider` holds the chosen role.
3. WHEN tapped, THE Flutter_App SHALL invoke `google_sign_in` and obtain an ID token + access token.
4. THE Flutter_App SHALL call `supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken, accessToken: accessToken, nonce: nonce)`.
5. WHEN the call succeeds AND the resulting user is new (Supabase `Identity` was just linked OR `profiles.first_name IS NULL`), THE Flutter_App SHALL `UPDATE profiles SET role = <pending_role> WHERE id = auth.uid() AND first_name IS NULL` (idempotent and safe for re-runs).
6. THE Flutter_App SHALL clear `Pending_Role_Provider` after successful first-time bootstrap.
7. THE Supabase_Auth SHALL be configured with the Google OAuth client ID and (Android) the SHA-1 fingerprint(s) for debug/release.
8. IF the Google flow is cancelled, THEN THE Flutter_App SHALL return silently to the previous screen with the role choice preserved.

### Requirement 4: Telegram OIDC sign-in

**User Story:** As a user with Telegram, I want to sign in or sign up with Telegram.

#### Acceptance Criteria

1. THE Flutter_App SHALL display a "Continue with Telegram" button on both sign-up and sign-in screens.
2. WHEN tapped, THE Flutter_App SHALL generate `state` (32-byte CSPRNG, base64url) and PKCE `code_verifier`/`code_challenge` (S256), then open `https://oauth.telegram.org/auth?bot_id=...&scope=openid&response_type=code&redirect_uri=dastern://auth/telegram/callback&code_challenge=...&code_challenge_method=S256&state=...` in the system browser.
3. THE Flutter_App SHALL handle the deep-link callback `dastern://auth/telegram/callback?code=...&state=...`.
4. THE Flutter_App SHALL verify the `state` matches the value generated in step 2; if not, abort.
5. THE Flutter_App SHALL POST `{code, codeVerifier, redirectUri, role: <pending_role | null>}` to the `auth-telegram` Edge Function.
6. THE `auth-telegram` Edge Function SHALL:
   - Exchange `code` at Telegram's token endpoint using the bot's client_id/client_secret;
   - Fetch JWKS from `https://oauth.telegram.org/.well-known/jwks.json` and verify the `id_token` signature; verify `iss = https://oauth.telegram.org`, `aud = TELEGRAM_BOT_CLIENT_ID`, `exp > now()`;
   - Find or create a Supabase user keyed on `telegram_id` (from `sub`); for first-time users use placeholder email `tg_<telegram_id>@telegram.dastern.local`;
   - **If the request body included `role` AND the profile is being created for the first time**, set `profiles.role = role`; otherwise keep the existing role;
   - Return tokens (or a magiclink hashed token) to Flutter for session establishment.
7. THE Flutter_App SHALL `setSession()` (or `verifyOTP(magiclink)`) with the returned token and store the session in `flutter_secure_storage`.
8. THE Flutter_App SHALL clear `Pending_Role_Provider` after successful first-time bootstrap.
9. THE Edge Function SHALL log all rejection reasons (invalid signature, expired token, wrong audience) for security monitoring; never log secrets, code verifiers, or full ID tokens.

### Requirement 5: Email/phone + password sign-up

**User Story:** As a new user without a Google or Telegram account I want to use, I want to register with email-or-phone plus a password.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a single input that accepts either an email or a phone number, plus a password input and a confirm-password input.
2. THE Flutter_App SHALL detect the credential kind heuristically: contains `@` ⇒ email; otherwise digits/`+` ⇒ phone (E.164).
3. THE Flutter_App SHALL validate password strength: minimum 8 characters, must include letters and digits.
4. WHEN the credential is an email, THE Flutter_App SHALL call `supabase.auth.signUp(email: email, password: password, data: {role: chosenRole})`.
5. WHEN the credential is a phone, THE Flutter_App SHALL call `supabase.auth.signUp(phone: phone, password: password, data: {role: chosenRole})` and route to a phone-OTP verification screen for the SMS code.
6. THE Flutter_App SHALL surface localized errors for: invalid email, invalid phone, password too weak, account already exists.
7. WHEN sign-up succeeds, THE `on_auth_user_created` trigger SHALL insert the `profiles` row with `role = (raw_user_meta_data->>'role')::user_role`. No further client-side role update is needed for this method.

### Requirement 6: Email confirmation (optional)

**User Story:** As a security engineer, I want email accounts to be confirmed.

#### Acceptance Criteria

1. WHEN the Supabase project has email confirmation enabled, THE Flutter_App SHALL display a "Check your email to verify" screen after sign-up.
2. THE Supabase_Auth SHALL be configured with a custom confirmation email template branded for Das Tern (Khmer + English).
3. WHEN the user taps the confirmation link, THE Flutter_App SHALL handle the deep link `dastern://auth/confirm` and complete the session.
4. WHEN email confirmation is disabled (MVP default), THE Flutter_App SHALL proceed directly to profile bootstrap after sign-up returns a session.

### Requirement 7: Phone OTP confirmation (mandatory for phone sign-ups)

**User Story:** As a phone-sign-up user, I want to verify my number with an SMS code.

#### Acceptance Criteria

1. WHEN sign-up is via phone, THE Supabase_Auth SHALL send an SMS OTP to that phone number.
2. THE Flutter_App SHALL show a 6-digit code entry screen.
3. WHEN the user submits the code, THE Flutter_App SHALL call `supabase.auth.verifyOTP(type: OtpType.sms, token: code, phone: phone)`.
4. THE Flutter_App SHALL allow resending the SMS after a 30-second cool-down.
5. THE Flutter_App SHALL fail gracefully with a localized error if SMS rate limits are hit.

### Requirement 8: Email/phone + password sign-in

**User Story:** As a returning user, I want to sign in with my email/phone and password.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a credential field (email or phone, autodetected) and a password field on the sign-in screen.
2. WHEN the user submits, THE Flutter_App SHALL call `supabase.auth.signInWithPassword(email: ?, phone: ?, password: password)` based on the detected kind.
3. WHEN sign-in fails, THE Flutter_App SHALL show a generic localized error ("Invalid email/phone or password") that does not reveal whether the account exists.
4. THE Supabase_Auth SHALL lock an account after 5 failed attempts in 15 minutes; the UI shows "Too many attempts. Try again in N minutes."

### Requirement 9: Forgot password (email/phone path only)

**User Story:** As a user who forgot their password, I want to reset it.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Forgot password" link on the email/phone sign-in section.
2. WHEN the credential is an email, THE Flutter_App SHALL call `supabase.auth.resetPasswordForEmail(email, redirectTo: 'dastern://auth/reset')`.
3. WHEN the credential is a phone, THE Flutter_App SHALL call `supabase.auth.signInWithOtp(phone: phone)` and ask the user to enter the OTP, then update the password via `auth.updateUser(UserAttributes(password: newPassword))`.
4. THE Flutter_App SHALL handle the deep-link callback `dastern://auth/reset` for email reset and show a "Set new password" screen.
5. THE Flutter_App SHALL revoke other existing sessions on password change.
6. WHEN the user originally signed up via Google or Telegram and has no password, "Forgot password" SHALL display a help text directing them to use the corresponding provider button instead.

### Requirement 10: Profile bootstrap — minimal, with optional fields

**User Story:** As a new user, I want to start using the app immediately after sign-up by providing only the minimum necessary info.

#### Acceptance Criteria

1. WHEN sign-up succeeds via any method, THE `on_auth_user_created` Postgres trigger SHALL insert a `profiles` row with `role = coalesce((raw_user_meta_data->>'role')::user_role, 'PATIENT')`, `language = 'KHMER'`, `theme = 'LIGHT'`, `timezone = 'Asia/Phnom_Penh'`, `account_status = 'ACTIVE'` for **both** Patient and Doctor.
2. WHEN sign-up is via Google, THE Flutter_App SHALL `UPDATE profiles SET role = <pending_role> WHERE id = auth.uid() AND first_name IS NULL` immediately after the session is established (idempotent for repeat sign-ins).
3. WHEN sign-up is via Telegram, THE `auth-telegram` Edge Function SHALL set `role` on the new profile if `role` is provided in the request body and the profile is freshly created.
4. THE Flutter_App SHALL navigate to a single-step "Tell us your name" bootstrap screen with the only required field being `full_name`.
5. THE Flutter_App SHALL NOT require date of birth, gender, language, or timezone at bootstrap.
6. THE Flutter_App SHALL NOT require any professional information from Doctors at bootstrap. Specifically, `hospital_clinic`, `specialty`, `license_number`, and `license_photo_url` SHALL remain `NULL` until the doctor chooses to complete the optional "Verify your practice" flow (see Requirement 11).
7. WHEN the user submits the name form, THE Flutter_App SHALL `UPDATE profiles SET first_name, last_name, full_name`. RLS guarantees only the user's own row is mutable.
8. THE GoRouter redirect SHALL route to the role-appropriate home: Patient → patient home, Doctor → doctor home.

### Requirement 11: Doctor "Verify your practice" flow (optional, deferrable)

**User Story:** As a Doctor, I want to add my professional credentials when I'm ready, so that patients see I'm a verified provider — but I'm not blocked from using the app while I do so.

#### Acceptance Criteria

1. THE Flutter_App SHALL show a non-blocking "Verify your practice" CTA on the Doctor home screen until the doctor's `account_status` reaches `VERIFIED`. The CTA SHALL be dismissible per session.
2. THE Flutter_App SHALL provide a "Verify your practice" screen reachable from Settings → Profile that collects: `hospital_clinic`, `specialty`, `license_number`, and a `license_photo_url` upload to the `doctor-licenses/<doctor_id>/...` bucket.
3. WHEN the doctor submits the form, THE Flutter_App SHALL `UPDATE profiles SET hospital_clinic, specialty, license_number, license_photo_url, account_status = 'PENDING_VERIFICATION' WHERE id = auth.uid()`.
4. THE admin SHALL review the license photo via the Supabase dashboard (or a future admin Edge Function) and set `account_status = 'VERIFIED'` (or `REJECTED` with a notification).
5. WHEN `account_status = 'VERIFIED'`, THE Flutter_App SHALL display a "Verified" badge on the doctor's profile and on every prescription card the doctor authors (visible to the patient).
6. THE doctor SHALL be able to edit their professional fields after verification; doing so SHALL revert `account_status` to `PENDING_VERIFICATION` until re-approved.
7. v2 MVP SHALL NOT gate prescription authoring on `account_status`. An unverified doctor can author prescriptions; the patient sees an "Unverified" indicator and chooses whether to approve. The patient remains the sole authority on what enters their record.

### Requirement 12: Session lifecycle

**User Story:** As a returning user, I want to stay signed in across launches.

#### Acceptance Criteria

1. THE Flutter_App SHALL initialize Supabase with `persistSession: true` and `autoRefreshToken: true`.
2. THE Flutter_App SHALL refresh the access token proactively when within 5 minutes of expiry.
3. WHEN the refresh token is rejected, THE Flutter_App SHALL clear `flutter_secure_storage`, clear Drift, and route to sign-in.
4. THE Flutter_App SHALL listen to `auth.onAuthStateChange` and react to `signedIn`, `signedOut`, `tokenRefreshed`, `userUpdated`, `passwordRecovery`.

### Requirement 13: Sign out

**User Story:** As a user, I want to sign out.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Sign out" action in settings.
2. WHEN tapped, THE Flutter_App SHALL call `auth.signOut(scope: SignOutScope.global)` and clear secure storage.
3. THE Flutter_App SHALL preserve the outbox for the same Supabase user id; if a different user signs in next, THE Flutter_App SHALL warn and clear the outbox.

### Requirement 14: Account deletion and data export

**User Story:** As a privacy-conscious user, I want to delete my account or export my data.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide settings actions "Delete my account" and "Export my data".
2. THE Edge Function `account-delete` SHALL call Supabase Admin API `auth.admin.deleteUser(user.id)`; cascades remove all owned rows.
3. THE Edge Function `account-export` SHALL produce a JSON archive of the user's profile, prescriptions, medications, dose events, connections, notifications, and audit logs, then upload to Storage and email a signed URL (1h TTL).

### Requirement 15: Sign-in / sign-up screen UX

**User Story:** As a user on these screens, I want a clear, accessible interface.

#### Acceptance Criteria

1. THE Welcome screen SHALL show, in this order: language toggle, app logo, "Sign up as Patient", "Sign up as Doctor", "I already have an account".
2. THE Method chooser SHALL show, in this order: provider buttons "Continue with Google", "Continue with Telegram", divider, link to "Continue with email/phone".
3. THE OAuth buttons SHALL respect each provider's brand-color guidelines while fitting the Material 3 button style.
4. THE Flutter_App SHALL meet WCAG AA contrast in light and dark mode.
5. THE Flutter_App SHALL have minimum 44x44 px tap targets.
6. THE Flutter_App SHALL show inline validation as the user types (email format, phone digits) on the email/phone path.
7. THE Flutter_App SHALL show a loading indicator on the active button only, never blocking the entire screen.

### Requirement 16: Security

**User Story:** As a security engineer, I want auth to follow best practices.

#### Acceptance Criteria

1. THE Flutter_App SHALL use HTTPS for all Supabase and Edge Function calls.
2. THE Flutter_App SHALL never log passwords, OTP codes, access tokens, refresh tokens, ID tokens, or PKCE verifiers.
3. THE Flutter_App SHALL clear the password field after each failed sign-in attempt.
4. THE Flutter_App SHALL deny WebView-based OAuth flows; OAuth uses the external system browser only (`flutter_web_auth_2` or `url_launcher` external mode).
5. THE Edge Function `auth-telegram` SHALL rate-limit to 10 requests/minute per IP and use constant-time comparison for sensitive equality checks.
6. THE Supabase_Auth SHALL apply rate limits: 60 OTP per hour per IP, 30 sign-up attempts per hour per IP, 10 password resets per hour per identifier.
7. THE Supabase_Auth SHALL configure `JWT_EXP = 3600` (1h access), `REFRESH_TOKEN_EXP = 2592000` (30d), refresh-token rotation on use.
8. THE `Pending_Role_Provider` SHALL only ever hold values `'PATIENT'` or `'DOCTOR'`; any other value is treated as null.
9. THE `auth-telegram` Edge Function SHALL ignore an incoming `role` from the request body if the matched profile already has `first_name IS NOT NULL` (it never elevates a returning user's role).
10. THE Postgres `profiles` table SHALL forbid client-side role updates after the first bootstrap (RLS policy `profiles_role_immutable`): `UPDATE profiles SET role = ?` is allowed only when the previous value was the default and `first_name IS NULL`.

### Requirement 17: Apple Sign-In (deferred to iOS phase)

**User Story:** As an iOS user, I may want Apple Sign-In in a later release.

#### Acceptance Criteria

1. v2 MVP SHALL NOT ship Apple Sign-In on Android.
2. The data model and routing SHALL not preclude Apple Sign-In in the iOS phase — `profiles` already has the columns to support multiple identities.
3. WHEN Apple is added, the same role-propagation pattern SHALL apply: capture role at welcome, persist in `Pending_Role_Provider`, apply via `UPDATE profiles SET role` after first sign-in, idempotent for returning users.
