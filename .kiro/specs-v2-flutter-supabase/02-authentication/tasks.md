# Tasks: Authentication & Profile Bootstrap

> **Updated by ADDENDUM-001 (2026-05-25):** OAuth provider tasks removed; email/phone+password is the only MVP path.

## Phase 1 — Supabase Auth provider configuration (0.5 day)

- [ ] **1.1** In Supabase dashboard, enable **Email** provider with email confirmation OFF (MVP) or ON (post-MVP). Customize the confirmation template (Khmer + English).
- [ ] **1.2** Enable **Phone** provider; configure SMS provider (Twilio or Supabase managed). Set OTP length 6, expiry 60s.
- [ ] **1.3** Set JWT settings: `JWT_EXP=3600`, `REFRESH_TOKEN_EXP=2592000`, refresh rotation on.
- [ ] **1.4** Configure rate limits: 60 OTP/hour per IP, 30 sign-up attempts/hour per IP, 10 password resets/hour per identifier.
- [ ] **1.5** Add deep-link redirect URLs: `dastern://auth/confirm`, `dastern://auth/reset`.
- [ ] **1.6** Disable Google, Apple, Telegram providers in Supabase dashboard for v2 MVP (re-enable in v2.1+).

## Phase 2 — Flutter dependencies and config (0.5 day)

- [ ] **2.1** Add deps: `supabase_flutter`, `flutter_secure_storage`, `uni_links`.
- [ ] **2.2** Configure Android deep-links: `dastern://auth/confirm`, `dastern://auth/reset` in `AndroidManifest.xml`.
- [ ] **2.3** Configure iOS URL schemes in `Info.plist`: `dastern`.
- [ ] **2.4** Wire `Supabase.initialize` with `--dart-define` URL and anon key.

## Phase 3 — Credential helper + repository (0.5 day)

- [ ] **3.1** `CredentialKindDetector` per design § 3.
- [ ] **3.2** Unit tests covering valid emails, valid E.164 phones, invalid inputs, edge cases (`+855 12 345 678` with spaces).
- [ ] **3.3** `AuthRepository` per design § 4 (signUp, verifyPhoneOtp, signIn, requestPasswordReset, updatePassword, signOut).

## Phase 4 — Welcome / role chooser (0.5 day)

- [ ] **4.1** `WelcomePage` with two role chooser cards.
- [ ] **4.2** "I already have an account" → routes to sign-in.

## Phase 5 — Sign-up flow (1 day)

- [ ] **5.1** `SignUpPage` accepting role from query param (`?role=PATIENT|DOCTOR`).
- [ ] **5.2** `CredentialField` widget with smart email/phone hint and validation.
- [ ] **5.3** `PasswordField` with show/hide and strength meter.
- [ ] **5.4** Submit handler calling `signUp(...)`.
- [ ] **5.5** `PhoneOtpPage` for SMS verification.
- [ ] **5.6** `EmailSentPage` for email-confirmation path (skipped if confirmation disabled).
- [ ] **5.7** Tests: happy paths for email and phone; password mismatch; weak password.

## Phase 6 — Sign-in flow (0.5 day)

- [ ] **6.1** `SignInPage` with credential field + password.
- [ ] **6.2** Submit handler calling `signIn(...)`.
- [ ] **6.3** Generic error handling that never reveals account existence.
- [ ] **6.4** Lockout indicator after 5 failed attempts.

## Phase 7 — Profile bootstrap (minimal) + optional doctor verification (1 day)

- [ ] **7.1** Update `on_auth_user_created` trigger per design § 5: insert profile with `account_status = 'ACTIVE'` for **both** PATIENT and DOCTOR; role from `raw_user_meta_data`.
- [ ] **7.2** `ProfileBootstrapPage` — single screen, only `full_name` required, applies to both roles.
- [ ] **7.3** GoRouter redirect logic: if `firstName == null` route to `/profile-bootstrap`; otherwise route to role-appropriate home (no separate doctor bootstrap page).
- [ ] **7.4** `VerifyPracticeBanner` widget — non-blocking CTA on doctor home; dismissible per session; hidden once `account_status = 'VERIFIED'`.
- [ ] **7.5** `VerifyPracticePage` reachable from Settings → Profile and from the banner. Collects optional `hospital_clinic`, `specialty`, `license_number`, and `license_photo_url` upload to `doctor-licenses/<doctor_id>/...`. Sets `account_status = 'PENDING_VERIFICATION'` on submit.
- [ ] **7.6** `isDoctorVerified(doctorId)` Riverpod provider; render a "Verified" badge wherever a doctor's identity appears (connection cards, prescription cards, doctor profile view).
- [ ] **7.7** Verify that prescription authoring is **not** gated on `account_status` (the patient approval flow is the gate; an "Unverified" indicator appears on the patient's view of the prescription card).
- [ ] **7.8** Tests: bootstrap with empty / whitespace name rejected; happy path routes to correct home; verify-practice flow toggles `account_status` correctly; admin sets to VERIFIED; banner disappears.

## Phase 8 — Forgot / reset password (0.5 day)

- [ ] **8.1** `ForgotPasswordPage` with credential field.
- [ ] **8.2** Email path: `resetPasswordForEmail` → `dastern://auth/reset` deep link → `ResetPasswordPage`.
- [ ] **8.3** Phone path: `signInWithOtp(phone)` → enter OTP → `updateUser(password)`.
- [ ] **8.4** Revoke other sessions after password change.

## Phase 9 — Session lifecycle (0.5 day)

- [ ] **9.1** Subscribe to `auth.onAuthStateChange` in app shell.
- [ ] **9.2** On `signedOut`, clear secure storage + Drift (preserve outbox unless different user).
- [ ] **9.3** On `tokenRefreshed`, persist new tokens.
- [ ] **9.4** On `userUpdated`, refetch profile.
- [ ] **9.5** Background → foreground re-validation: refresh token if online and >30 minutes since last validation.

## Phase 10 — Account deletion + export (0.5 day)

- [ ] **10.1** Edge Function `account-delete` with admin SDK call (unchanged from previous draft).
- [ ] **10.2** Edge Function `account-export` returning a signed JSON archive URL.
- [ ] **10.3** Settings UI buttons + confirmation dialogs.

## Phase 11 — Hardening (0.5 day)

- [ ] **11.1** Verify no passwords or OTPs in Sentry/logs.
- [ ] **11.2** Verify role metadata cannot be elevated post-creation by client (server-side trigger reads metadata only at create time; profile updates do not allow `role` change by RLS — add explicit policy `profiles_role_immutable`).
- [ ] **11.3** Confirm rate limits on Supabase Auth.
- [ ] **11.4** Penetration test: account enumeration via timing or messaging.

## Phase 12 — Sign-off

- [ ] **12.1** Demo: sign up as Patient with email → confirm (or skip) → minimal bootstrap (name only) → patient home.
- [ ] **12.2** Demo: sign up as Doctor with phone → SMS OTP → minimal bootstrap (name only) → doctor home **without** any professional info; "Verify your practice" CTA visible.
- [ ] **12.3** Demo: doctor opens "Verify your practice" → uploads license photo + fills hospital/specialty/license number → `account_status = 'PENDING_VERIFICATION'` → admin sets `VERIFIED` via dashboard → banner disappears, "Verified" badge appears on doctor's profile and prescriptions.
- [ ] **12.4** Demo: sign in with email/password → auto-routed to correct home.
- [ ] **12.5** Demo: sign in with phone/password → auto-routed.
- [ ] **12.6** Demo: forgot password → reset → previous sessions invalidated.
- [ ] **12.7** Demo: account deletion → all owned rows cascade-removed.
- [ ] **12.8** Demo: unverified doctor connects to a patient via QR and authors a prescription → patient sees an "Unverified" indicator on the prescription card; the patient can still approve.

## Definitions of done

- Sign-up + sign-in green in CI integration tests for both email and phone.
- No passwords/OTPs in any log surface.
- Role-based home routing verified for both Patient and Doctor.
- Profile bootstrap forced before access to feature screens.
- v2 MVP ships without OAuth; v2.1+ can re-enable additional providers without schema changes.
