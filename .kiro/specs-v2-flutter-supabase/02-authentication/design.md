# Design: Authentication & Profile Bootstrap

> **Updated by ADDENDUM-001 (2026-05-25):** Email/phone + password is the only MVP path. OAuth providers deferred.

## 1. High-level flow

```
                 ┌────────────────────────────────────┐
                 │       Welcome / role chooser        │
                 │  [Sign up as Patient] [as Doctor]   │
                 │  [I already have an account →]      │
                 └─────┬──────────────────┬────────────┘
                       │                  │
       sign-up         │                  │  sign-in
                       ▼                  ▼
       ┌──────────────────────────┐ ┌──────────────────────────┐
       │ Email-or-phone + password│ │ Email-or-phone + password│
       │ password confirm         │ │                          │
       └─────────┬────────────────┘ └─────────┬────────────────┘
                 │                            │
        email?   │ phone?                     │
        ┌────────┴────────┐                   │
        ▼                 ▼                   │
  email confirm     SMS OTP verify            │
  (or skip)              │                    │
        │                ▼                    │
        └────────┬───────┘                    │
                 ▼                            ▼
       ┌──────────────────────────┐ ┌──────────────────────────┐
       │ on_auth_user_created     │ │ signInWithPassword       │
       │ trigger inserts profile  │ │ → fetch profiles.role    │
       │ with role from metadata  │ │                          │
       └─────────┬────────────────┘ └─────────┬────────────────┘
                 │                            │
                 ▼                            ▼
       ┌──────────────────────────┐ ┌──────────────────────────┐
       │ Profile bootstrap form   │ │ Auto route by role:      │
       │ (patient or doctor track)│ │ Patient → patient home   │
       └─────────┬────────────────┘ │ Doctor  → doctor  home   │
                 ▼                  └──────────────────────────┘
                Home
```

## 2. Module structure

```
lib/features/auth/
├── data/
│   ├── auth_repository.dart           # signUp/signIn/signOut/resetPassword
│   ├── credential_kind.dart           # heuristic: email vs phone
│   └── auth_session_storage.dart
├── domain/
│   ├── auth_user.dart                 # freezed (uid, role)
│   ├── auth_failure.dart
│   ├── chosen_role.dart               # PATIENT | DOCTOR
│   └── usecases/
│       ├── sign_up_with_password.dart
│       ├── verify_phone_otp.dart      # phone-only
│       ├── sign_in_with_password.dart
│       ├── reset_password.dart
│       └── sign_out.dart
├── presentation/
│   ├── pages/
│   │   ├── welcome_page.dart           # role chooser + "I have an account"
│   │   ├── sign_up_page.dart           # credentials + password
│   │   ├── phone_otp_page.dart
│   │   ├── sign_in_page.dart
│   │   ├── forgot_password_page.dart
│   │   ├── reset_password_page.dart
│   │   ├── profile_bootstrap_page.dart # minimal: full name only
│   │   ├── verify_practice_page.dart   # optional doctor flow (see § 11.2)
│   │   └── auth_error_page.dart
│   ├── widgets/
│   │   ├── role_chooser_card.dart
│   │   ├── credential_field.dart       # smart email/phone input
│   │   ├── password_field.dart         # with show/hide toggle
│   │   └── strength_meter.dart
│   └── providers/
│       ├── auth_state_provider.dart
│       ├── current_user_provider.dart  # exposes role to the rest of the app
│       └── role_router_provider.dart   # decides patient vs doctor home
└── routing/auth_routes.dart
```

## 3. Credential detection helper

```dart
// lib/features/auth/data/credential_kind.dart
enum CredentialKind { email, phone, unknown }

class CredentialKindDetector {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  // E.164: optional +, then 8-15 digits
  static final _phoneRe = RegExp(r'^\+?[0-9]{8,15}$');

  static CredentialKind detect(String input) {
    final s = input.trim();
    if (_emailRe.hasMatch(s)) return CredentialKind.email;
    if (_phoneRe.hasMatch(s.replaceAll(RegExp(r'[\s\-()]'), ''))) {
      return CredentialKind.phone;
    }
    return CredentialKind.unknown;
  }

  static String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    return digits.startsWith('+') ? digits : '+$digits';
  }
}
```

## 4. AuthRepository

```dart
class AuthRepository {
  AuthRepository(this._supabase, this._sessionStorage);
  final SupabaseClient _supabase;
  final AuthSessionStorage _sessionStorage;

  /// Sign up with email or phone and a chosen role.
  /// For phone, an SMS OTP must be verified separately via [verifyPhoneOtp].
  Future<SignUpResult> signUp({
    required String credential,
    required String password,
    required ChosenRole role,
  }) async {
    final kind = CredentialKindDetector.detect(credential);
    if (kind == CredentialKind.unknown) {
      throw const AuthFailure.invalidCredential();
    }

    final response = kind == CredentialKind.email
        ? await _supabase.auth.signUp(
            email: credential.trim(),
            password: password,
            data: {'role': role.code},
          )
        : await _supabase.auth.signUp(
            phone: CredentialKindDetector.normalizePhone(credential),
            password: password,
            data: {'role': role.code},
          );

    if (response.session != null) {
      await _sessionStorage.persist(response.session!);
    }
    return SignUpResult(
      kind: kind,
      pendingPhoneOtp: kind == CredentialKind.phone && response.session == null,
      pendingEmailConfirm: kind == CredentialKind.email && response.session == null,
      session: response.session,
    );
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String code,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.sms,
      token: code,
      phone: CredentialKindDetector.normalizePhone(phone),
    );
    if (response.session != null) {
      await _sessionStorage.persist(response.session!);
    }
    return response;
  }

  /// Sign in detects email vs phone automatically.
  Future<AuthResponse> signIn({
    required String credential,
    required String password,
  }) async {
    final kind = CredentialKindDetector.detect(credential);
    if (kind == CredentialKind.unknown) {
      throw const AuthFailure.invalidCredential();
    }
    final response = kind == CredentialKind.email
        ? await _supabase.auth.signInWithPassword(
            email: credential.trim(),
            password: password,
          )
        : await _supabase.auth.signInWithPassword(
            phone: CredentialKindDetector.normalizePhone(credential),
            password: password,
          );
    if (response.session != null) {
      await _sessionStorage.persist(response.session!);
    }
    return response;
  }

  Future<void> requestPasswordReset(String credential) async {
    final kind = CredentialKindDetector.detect(credential);
    if (kind == CredentialKind.email) {
      await _supabase.auth.resetPasswordForEmail(
        credential.trim(),
        redirectTo: 'dastern://auth/reset',
      );
    } else if (kind == CredentialKind.phone) {
      await _supabase.auth.signInWithOtp(
        phone: CredentialKindDetector.normalizePhone(credential),
      );
    } else {
      throw const AuthFailure.invalidCredential();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    // Revoke other sessions for safety
    await _supabase.auth.signOut(scope: SignOutScope.others);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut(scope: SignOutScope.global);
    await _sessionStorage.clear();
  }
}
```

## 5. Profile bootstrap trigger (server-side)

The `on_auth_user_created` Postgres trigger reads the role from auth metadata supplied at sign-up. **Per ADDENDUM-001 § 2.4.1**, `account_status` is `ACTIVE` for both Patient and Doctor — registration does not require professional info.

```sql
-- supabase/migrations/20260601000001_profiles.sql (excerpt — updated)
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer as $$
declare
  v_role user_role := coalesce(
    (new.raw_user_meta_data->>'role')::user_role,
    'PATIENT'
  );
begin
  insert into public.profiles (id, email, phone_number, role, account_status)
  values (new.id, new.email, new.phone, v_role, 'ACTIVE')
  on conflict (id) do nothing;
  return new;
end;
$$;
```

A doctor's `account_status` only transitions to `PENDING_VERIFICATION` when they actively submit professional info via the "Verify your practice" flow (see § 11.2). It transitions to `VERIFIED` after admin review.

## 6. Auto role detection on sign-in

```dart
@riverpod
class AuthSession extends _$AuthSession {
  @override
  Stream<AuthState> build() => Supabase.instance.client.auth.onAuthStateChange;
}

@riverpod
Future<UserProfile?> currentUserProfile(Ref ref) async {
  final state = ref.watch(authSessionProvider).valueOrNull;
  final session = state?.session;
  if (session == null) return null;
  final row = await Supabase.instance.client
    .from('profiles').select('*').eq('id', session.user.id).maybeSingle();
  if (row == null) return null;
  return UserProfile.fromJson(row);
}

@riverpod
String roleAwareInitialRoute(Ref ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) return '/sign-in';
  if (profile.firstName == null || profile.firstName!.isEmpty) {
    // Both Patient and Doctor go to the same minimal bootstrap screen.
    return '/profile-bootstrap';
  }
  return profile.role == UserRole.doctor ? '/doctor/home' : '/patient/home';
}
```

`GoRouter` uses a redirect that calls `roleAwareInitialRoute`:

```dart
GoRouter(
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  redirect: (ctx, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final goingToAuth = state.uri.path.startsWith('/sign-')
                     || state.uri.path == '/welcome'
                     || state.uri.path.startsWith('/forgot-')
                     || state.uri.path.startsWith('/reset-');
    if (session == null && !goingToAuth) return '/welcome';
    if (session != null && goingToAuth) {
      return ProviderScope.containerOf(ctx).read(roleAwareInitialRouteProvider);
    }
    return null;
  },
  routes: [...],
);
```

## 7. Welcome / role chooser

```dart
class WelcomePage extends StatelessWidget {
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n.welcomeTitle, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: AppSpacing.lg),
          RoleChooserCard(
            role: ChosenRole.patient,
            title: l10n.signUpAsPatient,
            subtitle: l10n.signUpAsPatientSubtitle,
            icon: Icons.person_outline,
            onTap: () => context.push('/sign-up?role=PATIENT'),
          ),
          const SizedBox(height: AppSpacing.md),
          RoleChooserCard(
            role: ChosenRole.doctor,
            title: l10n.signUpAsDoctor,
            subtitle: l10n.signUpAsDoctorSubtitle,
            icon: Icons.medical_services_outlined,
            onTap: () => context.push('/sign-up?role=DOCTOR'),
          ),
          const Spacer(),
          AppButton(
            label: l10n.alreadyHaveAccount,
            variant: AppButtonVariant.outlined,
            onPressed: () => context.push('/sign-in'),
          ),
        ]),
      )),
    );
  }
}
```

## 8. Sign-up page

```dart
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key, required this.role});
  final ChosenRole role;
  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _credCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'passwords_dont_match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ref.read(authRepositoryProvider).signUp(
        credential: _credCtrl.text,
        password: _passCtrl.text,
        role: widget.role,
      );
      if (result.pendingPhoneOtp) {
        if (mounted) context.push('/sign-up/phone-otp', extra: _credCtrl.text);
      } else if (result.pendingEmailConfirm) {
        if (mounted) context.push('/sign-up/email-sent');
      } else {
        // session active → redirect handles routing to bootstrap
      }
    } on AuthFailure catch (e) {
      setState(() => _error = e.code);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(children: [
          Text(widget.role == ChosenRole.doctor
                ? l10n.signUpAsDoctor : l10n.signUpAsPatient,
               style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.md),
          CredentialField(controller: _credCtrl,
                          hintText: l10n.emailOrPhoneHint),
          const SizedBox(height: AppSpacing.md),
          PasswordField(controller: _passCtrl, label: l10n.password),
          const SizedBox(height: AppSpacing.sm),
          PasswordField(controller: _confirmCtrl, label: l10n.confirmPassword),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(l10n.byErrorCode(_error!), style: TextStyle(color: AppColors.danger))),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: l10n.continue_, loading: _loading, onPressed: _submit),
        ]),
      ),
    );
  }
}
```

## 9. Sign-in page

```dart
class SignInPage extends ConsumerStatefulWidget {...}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _credCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signIn(
        credential: _credCtrl.text,
        password: _passCtrl.text,
      );
      // GoRouter redirect will route based on role
    } on AuthException catch (e) {
      // Generic message — never reveal account existence
      setState(() => _error = 'invalid_credentials');
      _passCtrl.clear();
    } on AuthFailure catch (e) {
      setState(() => _error = e.code);
    } finally {
      setState(() => _loading = false);
    }
  }
  ...
}
```

## 10. Phone OTP verification page

```dart
class PhoneOtpPage extends ConsumerStatefulWidget {
  const PhoneOtpPage({super.key, required this.phone});
  final String phone;
  ...
}
```

`_submit()` calls `verifyPhoneOtp(phone: phone, code: code)`. On success, `onAuthStateChange` fires `signedIn` and the redirect routes the user to profile bootstrap.

## 11. Profile bootstrap and optional doctor verification

### 11.1 Minimal bootstrap (both roles)

Per ADDENDUM-001 § 2.4.1, the bootstrap is intentionally tiny — a single screen asking only for the user's full name. Everything else is optional and configurable later from Settings.

```dart
// lib/features/auth/presentation/pages/profile_bootstrap_page.dart
class ProfileBootstrapPage extends ConsumerStatefulWidget {
  const ProfileBootstrapPage({super.key});
  @override
  ConsumerState<ProfileBootstrapPage> createState() => _State();
}

class _State extends ConsumerState<ProfileBootstrapPage> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final raw = _nameCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() => _saving = true);
    final parts = raw.split(RegExp(r'\s+'));
    final first = parts.first;
    final last  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    await Supabase.instance.client.from('profiles').update({
      'first_name': first,
      'last_name': last,
      'full_name': raw,
    }).eq('id', Supabase.instance.client.auth.currentUser!.id);
    if (mounted) context.go(_homeRouteForRole());
  }

  String _homeRouteForRole() {
    final role = ref.read(currentUserProfileProvider).value?.role;
    return role == UserRole.doctor ? '/doctor/home' : '/patient/home';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n.bootstrapTellUsYourName,
               style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.bootstrapNameHint,
               style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(controller: _nameCtrl, hint: l10n.fullName),
          const Spacer(),
          AppButton(label: l10n.continue_, loading: _saving, onPressed: _save),
        ]),
      )),
    );
  }
}
```

That is the entire mandatory bootstrap. Date of birth, gender, language, timezone, and (for doctors) all professional fields are skipped. The user is taken straight to the home screen for their role.

### 11.2 Optional Doctor "Verify your practice" flow

Once a doctor is on their home screen, a non-blocking CTA banner offers verification:

```dart
class VerifyPracticeBanner extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null || profile.role != UserRole.doctor) return const SizedBox();
    if (profile.accountStatus == AccountStatus.verified) return const SizedBox();

    final l10n = AppLocalizations.of(context)!;
    final dismissed = ref.watch(verifyBannerDismissedProvider);
    if (dismissed) return const SizedBox();

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.verified_user_outlined),
        title: Text(l10n.verifyPracticeTitle),
        subtitle: Text(l10n.verifyPracticeSubtitle),
        trailing: Wrap(spacing: 4, children: [
          TextButton(
            child: Text(l10n.dismiss),
            onPressed: () => ref.read(verifyBannerDismissedProvider.notifier).state = true,
          ),
          FilledButton(
            child: Text(l10n.start),
            onPressed: () => context.push('/doctor/verify-practice'),
          ),
        ]),
      ),
    );
  }
}
```

The verify-practice page collects the optional professional fields:

```dart
class VerifyPracticePage extends ConsumerStatefulWidget {
  ...
}

class _State extends ConsumerState<VerifyPracticePage> {
  final _hospital = TextEditingController();
  final _specialty = TextEditingController();
  final _license = TextEditingController();
  String? _photoStoragePath;

  Future<void> _submit() async {
    final user = Supabase.instance.client.auth.currentUser!;
    if (_photoStoragePath == null) {
      _showError('please_upload_license_photo');
      return;
    }
    await Supabase.instance.client.from('profiles').update({
      'hospital_clinic': _hospital.text.trim(),
      'specialty': _specialty.text.trim(),
      'license_number': _license.text.trim(),
      'license_photo_url': _photoStoragePath,
      'account_status': 'PENDING_VERIFICATION',
    }).eq('id', user.id);
    if (mounted) context.pop();
  }
  ...
}
```

The license photo is uploaded via `Supabase.instance.client.storage.from('doctor-licenses').upload('$userId/license.jpg', file)` (RLS scopes the prefix to the doctor's id).

### 11.3 Verified badge

A simple Riverpod provider exposes the badge state:

```dart
@riverpod
bool isDoctorVerified(Ref ref, String doctorId) {
  final profileAsync = ref.watch(profileByIdProvider(doctorId));
  final p = profileAsync.valueOrNull;
  return p?.role == UserRole.doctor && p?.accountStatus == AccountStatus.verified;
}
```

Used wherever a doctor's identity is shown — connection cards, prescription cards, prescription detail, etc. The badge is informational; nothing in the system is gated on verification status in MVP.

### 11.4 No hard gate on prescription authoring

Per ADDENDUM-001 § 2.4.1, an unverified doctor can author prescriptions. The patient-side UI shows an "Unverified" indicator on the prescription card and on the doctor's profile, so the patient can make an informed decision before approving. Nothing else changes — the existing approval flow in `03-prescription-medication` is the gate.

## 12. Account deletion + export Edge Functions

Unchanged from the previous draft — see `02-authentication/design.md` history. They both run after auth via the user's JWT and use the service-role admin client only when necessary.

## 13. Configuration matrix

| Env var | Where | Purpose |
|---|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Flutter `--dart-define` | Client init |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge secret only | Admin-side ops in account-delete |
| (Twilio or other SMS provider configured in Supabase Dashboard) | Supabase Auth | SMS OTP delivery |

The Telegram-, Google-, and Apple-related secrets from the previous draft are no longer required for MVP. Their entries can be left blank in environment configuration.

## 14. Threat model

| Threat | Mitigation |
|---|---|
| Credential stuffing | Supabase rate limits (5 failed attempts → 15-min lockout); generic error messages. |
| SMS pumping (phone OTP abuse) | Supabase + SMS provider rate limits, OTP cool-down, phone-format validation. |
| Stolen access token | 1h JWT lifetime, refresh-token rotation. |
| Stolen refresh token | Rotation; revoke other sessions on password change. |
| Account enumeration | Generic "invalid email/phone or password" — never indicate which field is wrong. |
| Lateral data access via leaked anon key | RLS on every table; anon key alone cannot read other users' data. |

## 15. Testing

- **Unit:** `CredentialKindDetector` boundaries (`x@y.z` → email, `+855123…` → phone, `nonsense` → unknown).
- **Unit:** `AuthRepository` behaviour for email-only, phone-only, role metadata wiring.
- **Widget:** Sign-up role chooser routing; sign-in form rendering; password strength meter.
- **Integration:** Supabase local stack — sign up as Patient → bootstrap → home; sign up as Doctor → bootstrap → home with PENDING banner.
- **Security:** Failed sign-in 5x triggers lockout; password reset revokes other sessions; metadata `role` cannot be tampered to elevate to DOCTOR (the trigger trusts metadata at create time, so make sure the Flutter UI is the only path that sets it; the server can also reject unknown `role` values). Belt-and-braces: add a check constraint or trigger that rejects roles outside the enum.
