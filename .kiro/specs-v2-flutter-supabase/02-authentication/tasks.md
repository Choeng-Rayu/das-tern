# Tasks: Authentication & Profile Bootstrap

> **Updated by ADDENDUM-001 § 2.4 (2026-05-25):** Three MVP methods — Google OAuth, Telegram OIDC, email/phone + password. Apple deferred to iOS phase.

## Phase 1 — Supabase Auth provider configuration (1 day)

- [ ] **1.1** In Supabase dashboard, enable **Email** provider with email confirmation off (MVP) or on (post-MVP). Customise the confirmation template (Khmer + English).
- [ ] **1.2** Enable **Phone** provider; configure SMS provider (Twilio or Supabase managed). OTP length 6, expiry 60s.
- [ ] **1.3** Enable **Google** provider in Supabase Auth: paste Web Client ID + Client Secret. Set redirect URL `https://<project>.supabase.co/auth/v1/callback`.
- [ ] **1.4** Configure custom Telegram OIDC integration via Edge Function (no provider toggle in Supabase Dashboard for Telegram).
- [ ] **1.5** Apple provider: leave disabled in v2 MVP. Add to backlog for the iOS phase.
- [ ] **1.6** Set JWT settings: `JWT_EXP=3600`, `REFRESH_TOKEN_EXP=2592000`, refresh rotation on.
- [ ] **1.7** Configure rate limits: 60 OTP/hour per IP, 30 sign-up attempts/hour per IP, 10 password resets/hour per identifier.
- [ ] **1.8** Add deep-link redirect URLs: `dastern://auth/confirm`, `dastern://auth/reset`, `dastern://auth/telegram/callback`.

## Phase 2 — Flutter dependencies and config (0.5 day)

- [ ] **2.1** Add deps: `supabase_flutter`, `google_sign_in`, `flutter_web_auth_2`, `flutter_secure_storage`, `crypto`, `uni_links`, `url_launcher`.
- [ ] **2.2** Android: declare deep-link `<intent-filter>` for `dastern://auth/telegram/callback`, `dastern://auth/confirm`, `dastern://auth/reset` in `AndroidManifest.xml`.
- [ ] **2.3** Android: add Google services configuration; register debug + release SHA-1 in Firebase + Google Cloud.
- [ ] **2.4** iOS: configure URL schemes in `Info.plist`: `dastern` and Google reverse-client-id.
- [ ] **2.5** Wire `Supabase.initialize` with `--dart-define` URL and anon key, plus `--dart-define=GOOGLE_WEB_CLIENT_ID` and `--dart-define=TELEGRAM_BOT_CLIENT_ID`.

## Phase 3 — Shared infrastructure (1 day)

- [ ] **3.1** `CredentialKindDetector` per design § 4 with unit tests (valid emails, valid E.164 phones, invalid inputs, edge cases).
- [ ] **3.2** `PendingRoleStorage` + `pendingRoleControllerProvider` per design § 3.
- [ ] **3.3** `AuthSessionStorage` wrapping `flutter_secure_storage`.
- [ ] **3.4** `AuthRepository` skeleton wiring all three methods (per design § 5).

## Phase 4 — Welcome + Method chooser (0.5 day)

- [ ] **4.1** `WelcomePage` with two role chooser cards.
- [ ] **4.2** `RoleChooserCard` widget.
- [ ] **4.3** "I already have an account" → routes to `/sign-in`.
- [ ] **4.4** `MethodChooserPage` with three options.
- [ ] **4.5** Persist chosen role via `PendingRoleStorage` before launching any auth method.

## Phase 5 — Email/phone + password flow (1.5 days)

- [ ] **5.1** `signUpWithPassword` and `signInWithPassword` in `AuthRepository` per design § 5.
- [ ] **5.2** `SignUpCredentialsPage` reachable from method chooser; reads role from `pendingRoleControllerProvider`.
- [ ] **5.3** `CredentialField` widget with smart email/phone hint and validation.
- [ ] **5.4** `PasswordField` with show/hide and strength meter.
- [ ] **5.5** `PhoneOtpPage` for SMS verification.
- [ ] **5.6** `EmailSentPage` for email-confirmation path (skipped if confirmation disabled).
- [ ] **5.7** `SignInPage` integrates all three methods; handles password sign-in.
- [ ] **5.8** Generic error messaging on sign-in (no account enumeration).
- [ ] **5.9** Tests: happy paths for email and phone sign-up; password mismatch; weak password; lockout after 5 failed sign-ins.

## Phase 6 — Google native flow (1 day)

- [ ] **6.1** `GoogleAuthClient` per design § 6.
- [ ] **6.2** `GoogleButton` widget with brand-compliant styling.
- [ ] **6.3** Wire `signInOrSignUpWithGoogle` in `AuthRepository` to apply pending role on first-time profiles via `_applyPendingRoleIfFirstTime`.
- [ ] **6.4** Test on physical Android device (debug + release SHA-1).
- [ ] **6.5** Test sign-in path (returning user) — pending role is ignored, existing role used.
- [ ] **6.6** Test sign-up path (new user) — pending role applied; subsequent sign-in does not change role.

## Phase 7 — Telegram OIDC flow (1.5 days)

- [ ] **7.1** `TelegramAuthClient` per design § 7.1 with PKCE generation and state storage.
- [ ] **7.2** `TelegramButton` widget.
- [ ] **7.3** Edge Function `supabase/functions/auth-telegram/index.ts` per design § 7.2.
- [ ] **7.4** Edge Function secrets: `TELEGRAM_BOT_CLIENT_ID`, `TELEGRAM_BOT_CLIENT_SECRET`, `SUPABASE_SERVICE_ROLE_KEY`.
- [ ] **7.5** Deploy: `supabase functions deploy auth-telegram --no-verify-jwt`.
- [ ] **7.6** Wire end-to-end: Flutter → external browser → Telegram → callback → Edge Function → Supabase magiclink session.
- [ ] **7.7** Edge Function tests: valid token, invalid signature, expired, wrong audience, missing claims, role-on-fresh-only invariant.
- [ ] **7.8** Flutter integration test: tap Telegram button → assert callback handler accepts a known state and rejects a tampered one.

## Phase 8 — Profile bootstrap (minimal) + optional doctor verification (1 day)

- [ ] **8.1** Update `on_auth_user_created` trigger per design § 8: insert profile with `account_status = 'ACTIVE'` for both PATIENT and DOCTOR; role from `raw_user_meta_data`.
- [ ] **8.2** Add `tg_profiles_role_immutable` trigger per design § 8.1 enforcing role lock after `first_name` is set.
- [ ] **8.3** `ProfileBootstrapPage` — single screen, only `full_name` required, applies to both roles.
- [ ] **8.4** GoRouter redirect logic: if `firstName == null` route to `/profile-bootstrap`; otherwise route to role-appropriate home.
- [ ] **8.5** `VerifyPracticeBanner` widget — non-blocking CTA on doctor home; dismissible per session; hidden once `account_status = 'VERIFIED'`.
- [ ] **8.6** `VerifyPracticePage` reachable from Settings → Profile and from the banner. Collects optional `hospital_clinic`, `specialty`, `license_number`, `license_photo_url`. Sets `account_status = 'PENDING_VERIFICATION'` on submit.
- [ ] **8.7** `isDoctorVerified(doctorId)` Riverpod provider; render a "Verified" badge wherever a doctor's identity appears.
- [ ] **8.8** Confirm prescription authoring is **not** gated on `account_status` (an "Unverified" indicator appears on the patient's view of the prescription card).
- [ ] **8.9** Tests: empty/whitespace name rejected; happy path routes to correct home; verify-practice flow toggles `account_status`; banner disappears on VERIFIED.

## Phase 9 — Forgot / reset password (0.5 day)

- [ ] **9.1** `ForgotPasswordPage` with credential field.
- [ ] **9.2** Email path: `resetPasswordForEmail` → `dastern://auth/reset` → `ResetPasswordPage`.
- [ ] **9.3** Phone path: `signInWithOtp(phone)` → enter OTP → `updateUser(password)`.
- [ ] **9.4** Show provider hint ("Use Google/Telegram instead") for users without a password.
- [ ] **9.5** Revoke other sessions after password change.

## Phase 10 — Session lifecycle (0.5 day)

- [ ] **10.1** Subscribe to `auth.onAuthStateChange` in app shell.
- [ ] **10.2** On `signedOut`, clear secure storage + Drift (preserve outbox unless different user).
- [ ] **10.3** On `tokenRefreshed`, persist new tokens.
- [ ] **10.4** On `userUpdated`, refetch profile.
- [ ] **10.5** Background → foreground re-validation: refresh token if online and >30 minutes since last validation.

## Phase 11 — Account deletion + export (0.5 day)

- [ ] **11.1** Edge Function `account-delete` with admin SDK call.
- [ ] **11.2** Edge Function `account-export` returning a signed JSON archive URL.
- [ ] **11.3** Settings UI buttons + confirmation dialogs.

## Phase 12 — Hardening (0.5 day)

- [ ] **12.1** Verify no passwords, OTPs, ID tokens, PKCE verifiers in Sentry/logs.
- [ ] **12.2** Verify `Pending_Role_Provider` only ever holds whitelisted values; ignored otherwise.
- [ ] **12.3** Verify role cannot be elevated post-bootstrap (trigger rejects; Edge Function ignores `role` for returning users).
- [ ] **12.4** Confirm Telegram OAuth uses external browser only (`flutter_web_auth_2`), not WebView.
- [ ] **12.5** Confirm rate limits on Supabase Auth and on `auth-telegram` Edge Function (10 req/min/IP).
- [ ] **12.6** Pen-test: account enumeration via timing or messaging; tampered Telegram state aborts; replayed Telegram code fails.

## Phase 13 — Sign-off

- [ ] **13.1** Demo: open app → Welcome → "Sign up as Patient" → Method chooser → Google → bootstrap (name only) → patient home.
- [ ] **13.2** Demo: Welcome → "Sign up as Doctor" → Method chooser → Telegram → SMS-OTP-free Telegram flow → doctor home with "Verify your practice" CTA visible.
- [ ] **13.3** Demo: Welcome → "Sign up as Patient" → Method chooser → email/phone + password → SMS OTP if phone → bootstrap → patient home.
- [ ] **13.4** Demo: Sign-in via Google as returning user → goes straight to correct home without role prompt.
- [ ] **13.5** Demo: Sign-in via Telegram as returning user → role preserved (Patient stays Patient even if request body had `role: 'DOCTOR'`).
- [ ] **13.6** Demo: Sign-in via email/password → auto-routed to correct home.
- [ ] **13.7** Demo: Doctor opens Verify Practice → uploads license photo + fills professional fields → admin sets VERIFIED → badge appears.
- [ ] **13.8** Demo: Forgot password (email) → reset → previous sessions invalidated.
- [ ] **13.9** Demo: Forgot password attempted on a Google-only account → helpful message directing to Google.
- [ ] **13.10** Demo: Account deletion → all owned rows cascade-removed.
- [ ] **13.11** Demo: Unverified doctor connects to a patient via QR and authors a prescription → patient sees "Unverified" indicator and can still approve.

## Definitions of done

- All three sign-up paths green in CI integration tests for both Patient and Doctor roles.
- Sign-in via each method routes to the correct home based on existing `profiles.role`.
- No auth secrets shipped to clients.
- Profile bootstrap forced before access to feature screens.
- Role-elevation attempts on returning users blocked at three layers (client guard, Edge Function check, Postgres trigger).
