# Design: Authentication & Profile Bootstrap

> **Updated by ADDENDUM-001 § 2.4 (2026-05-25):** Three MVP methods — Google OAuth, Telegram OIDC, email/phone + password. Apple deferred. Role chosen at Welcome, propagated through whichever method the user picks.

## 1. High-level flow

```
                    ┌────────────────────────────────────────┐
                    │             Welcome page                │
                    │  [Sign up as Patient] [as Doctor]       │
                    │  [I already have an account →]          │
                    └─────┬──────────────────┬─────────────────┘
                          │                  │
              sign-up     │                  │  sign-in
                          ▼                  ▼
            ┌────────────────────────────┐  ┌─────────────────────────────────┐
            │ Method chooser (sign-up)   │  │ Sign-in page (3 methods)        │
            │  [Continue with Google]    │  │  [Continue with Google]         │
            │  [Continue with Telegram]  │  │  [Continue with Telegram]       │
            │  [Continue with email/phone│  │  email/phone + password input   │
            └─────┬─────┬─────┬──────────┘  └─────┬─────┬─────┬───────────────┘
                  │     │     │                   │     │     │
                  ▼     ▼     ▼                   ▼     ▼     ▼
        Google   Telegram   email/phone     Google   Telegram   email/phone
        signInWith  PKCE +    signUp        signInWith  PKCE +    signInWithPassword
        IdToken    Edge Fn   (+ OTP if     IdToken    Edge Fn
                              phone)
                  │     │     │                   │     │     │
                  ▼     ▼     ▼                   ▼     ▼     ▼
        ┌────────────────────────────────────────────────────────────┐
        │   on_auth_user_created Postgres trigger inserts profile     │
        │   (role from raw_user_meta_data, default PATIENT)           │
        └─────┬──────────────────────────────────────────────────────┘
              │ first-time only
              ▼
        ┌────────────────────────────────────────────────────────────┐
        │ Role reconciliation (sign-up only):                         │
        │  • email/phone path: trigger already used the metadata.    │
        │  • Google path: Flutter UPDATE profiles SET role = ...     │
        │  • Telegram path: Edge Function set role on creation.      │
        │ All are idempotent and only run when first_name IS NULL.   │
        └─────┬──────────────────────────────────────────────────────┘
              ▼
        ┌────────────────────────────────────────────────────────────┐
        │ ProfileBootstrapPage (single screen, name only)             │
        └─────┬──────────────────────────────────────────────────────┘
              ▼
        ┌────────────────────────────────────────────────────────────┐
        │ roleAwareInitialRoute → patient home or doctor home          │
        └────────────────────────────────────────────────────────────┘
```

## 2. Module structure

```
lib/features/auth/
├── data/
│   ├── auth_repository.dart            # signUp/signIn/signOut/resetPassword
│   ├── credential_kind.dart            # heuristic: email vs phone
│   ├── google_auth_client.dart         # google_sign_in + signInWithIdToken
│   ├── telegram_auth_client.dart       # PKCE + browser launcher + Edge Fn
│   ├── pending_role_storage.dart       # secure-storage backed transient store
│   └── auth_session_storage.dart
├── domain/
│   ├── auth_user.dart                  # freezed (uid, role)
│   ├── auth_failure.dart
│   ├── chosen_role.dart                # PATIENT | DOCTOR
│   └── usecases/
│       ├── sign_up_with_google.dart
│       ├── sign_up_with_telegram.dart
│       ├── sign_up_with_password.dart
│       ├── sign_in_with_google.dart
│       ├── sign_in_with_telegram.dart
│       ├── sign_in_with_password.dart
│       ├── verify_phone_otp.dart
│       ├── reset_password.dart
│       └── sign_out.dart
├── presentation/
│   ├── pages/
│   │   ├── welcome_page.dart           # role chooser + "I have an account"
│   │   ├── method_chooser_page.dart    # Google / Telegram / email-phone
│   │   ├── sign_up_credentials_page.dart  # email/phone + password
│   │   ├── phone_otp_page.dart
│   │   ├── sign_in_page.dart           # all 3 methods on one screen
│   │   ├── forgot_password_page.dart
│   │   ├── reset_password_page.dart
│   │   ├── profile_bootstrap_page.dart # minimal: full name only
│   │   ├── verify_practice_page.dart   # optional doctor flow
│   │   └── auth_error_page.dart
│   ├── widgets/
│   │   ├── role_chooser_card.dart
│   │   ├── google_button.dart
│   │   ├── telegram_button.dart
│   │   ├── credential_field.dart
│   │   ├── password_field.dart
│   │   └── strength_meter.dart
│   └── providers/
│       ├── auth_state_provider.dart
│       ├── current_user_provider.dart
│       ├── pending_role_provider.dart
│       └── role_router_provider.dart
└── routing/auth_routes.dart
```

## 3. PendingRoleStorage

The role chosen at Welcome must survive an OAuth round-trip through the system browser, so it is stored in `flutter_secure_storage` (cleared after first-bootstrap consumption).

```dart
// lib/features/auth/data/pending_role_storage.dart
class PendingRoleStorage {
  PendingRoleStorage(this._secure);
  final FlutterSecureStorage _secure;
  static const _key = 'pending_role_v1';

  Future<void> set(ChosenRole role) async {
    await _secure.write(key: _key, value: role.code);
  }
  Future<ChosenRole?> read() async {
    final v = await _secure.read(key: _key);
    return ChosenRole.fromCode(v);
  }
  Future<void> clear() async => _secure.delete(key: _key);
}

@riverpod
class PendingRoleController extends _$PendingRoleController {
  @override
  Future<ChosenRole?> build() => ref.watch(pendingRoleStorageProvider).read();

  Future<void> set(ChosenRole role) async {
    await ref.read(pendingRoleStorageProvider).set(role);
    ref.invalidateSelf();
  }
  Future<void> clear() async {
    await ref.read(pendingRoleStorageProvider).clear();
    ref.invalidateSelf();
  }
}
```

## 4. Credential helper

```dart
// lib/features/auth/data/credential_kind.dart
enum CredentialKind { email, phone, unknown }

class CredentialKindDetector {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
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

## 5. AuthRepository (entry points for each method)

```dart
class AuthRepository {
  AuthRepository(this._supabase, this._sessionStorage,
                 this._google, this._telegram, this._pendingRole);
  final SupabaseClient _supabase;
  final AuthSessionStorage _sessionStorage;
  final GoogleAuthClient _google;
  final TelegramAuthClient _telegram;
  final PendingRoleStorage _pendingRole;

  // ------- email/phone + password -------

  Future<SignUpResult> signUpWithPassword({
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

  Future<AuthResponse> signInWithPassword({
    required String credential,
    required String password,
  }) async {
    final kind = CredentialKindDetector.detect(credential);
    if (kind == CredentialKind.unknown) {
      throw const AuthFailure.invalidCredential();
    }
    final response = kind == CredentialKind.email
        ? await _supabase.auth.signInWithPassword(
            email: credential.trim(), password: password)
        : await _supabase.auth.signInWithPassword(
            phone: CredentialKindDetector.normalizePhone(credential),
            password: password);
    if (response.session != null) {
      await _sessionStorage.persist(response.session!);
    }
    return response;
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

  // ------- Google native -------

  /// Used both by sign-up and sign-in. The role (if any) comes from
  /// PendingRoleStorage and is applied AFTER the session lands, only when
  /// the profile is freshly created.
  Future<AuthResponse> signInOrSignUpWithGoogle() async {
    final response = await _google.authenticate(_supabase);
    if (response.session != null) {
      await _sessionStorage.persist(response.session!);
      await _applyPendingRoleIfFirstTime();
    }
    return response;
  }

  // ------- Telegram OIDC -------

  Future<void> signInOrSignUpWithTelegram() async {
    final pendingRole = await _pendingRole.read();
    await _telegram.startAndCompleteSignIn(role: pendingRole);
    // Edge Function returns either a session or a magiclink hashed_token.
    // _telegram.startAndCompleteSignIn() finalises by calling
    // supabase.auth.setSession() / verifyOTP() on the Flutter side.
    await _applyPendingRoleIfFirstTime();
  }

  // ------- shared helpers -------

  Future<void> _applyPendingRoleIfFirstTime() async {
    final pending = await _pendingRole.read();
    final user = _supabase.auth.currentUser;
    if (pending == null || user == null) return;
    // Only update when the profile is fresh (first_name IS NULL).
    final updated = await _supabase
      .from('profiles')
      .update({'role': pending.code})
      .eq('id', user.id)
      .filter('first_name', 'is', null)
      .select();
    if ((updated as List).isNotEmpty) {
      await _pendingRole.clear();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut(scope: SignOutScope.global);
    await _sessionStorage.clear();
  }

  Future<void> requestPasswordReset(String credential) async { /* unchanged */ }
  Future<void> updatePassword(String newPassword) async { /* unchanged */ }
}
```

## 6. Google native flow

```dart
// lib/features/auth/data/google_auth_client.dart
class GoogleAuthClient {
  Future<AuthResponse> authenticate(SupabaseClient supabase) async {
    final google = GoogleSignIn(
      serverClientId: AppConfig.googleWebClientId,
      scopes: const ['email', 'profile', 'openid'],
    );
    final user = await google.signIn();
    if (user == null) throw const AuthFailure.cancelled();

    final auth = await user.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if (idToken == null) throw const AuthFailure.invalidProviderResponse();

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}
```

## 7. Telegram OIDC flow

### 7.1 Flutter side

```dart
// lib/features/auth/data/telegram_auth_client.dart
class TelegramAuthClient {
  TelegramAuthClient(this._supabase, this._secureStorage);
  final SupabaseClient _supabase;
  final FlutterSecureStorage _secureStorage;

  Future<void> startAndCompleteSignIn({ChosenRole? role}) async {
    final state = _randomBase64Url(32);
    final codeVerifier = _randomBase64Url(64);
    final codeChallenge = _sha256B64Url(codeVerifier);
    await _secureStorage.write(
      key: 'tg_state_v1',
      value: jsonEncode({'state': state, 'verifier': codeVerifier}),
    );

    final authUrl = Uri.https('oauth.telegram.org', '/auth', {
      'bot_id': AppConfig.telegramBotClientId,
      'scope': 'openid',
      'response_type': 'code',
      'redirect_uri': 'dastern://auth/telegram/callback',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'dastern',
    );
    final cb = Uri.parse(result);
    final code = cb.queryParameters['code'];
    final returnedState = cb.queryParameters['state'];
    final stored = jsonDecode(
      (await _secureStorage.read(key: 'tg_state_v1')) ?? '{}',
    ) as Map<String, dynamic>;
    if (returnedState != stored['state']) throw const AuthFailure.cancelled();
    if (code == null) throw const AuthFailure.invalidProviderResponse();

    final res = await _supabase.functions.invoke('auth-telegram', body: {
      'code': code,
      'codeVerifier': stored['verifier'],
      'redirectUri': 'dastern://auth/telegram/callback',
      if (role != null) 'role': role.code,  // PATIENT | DOCTOR
    });
    if (res.status != 200) {
      throw AuthFailure.serverError(res.data?['error']?.toString());
    }

    // Exchange the magiclink hashed_token for an actual session.
    final body = res.data as Map<String, dynamic>;
    if (body['hashed_token'] != null && body['email'] != null) {
      await _supabase.auth.verifyOTP(
        type: OtpType.magiclink,
        token: body['hashed_token'] as String,
        email: body['email'] as String,
      );
    } else if (body['access_token'] != null && body['refresh_token'] != null) {
      await _supabase.auth.setSession(body['refresh_token'] as String);
    } else {
      throw const AuthFailure.invalidProviderResponse();
    }
    await _secureStorage.delete(key: 'tg_state_v1');
  }
}
```

### 7.2 Edge Function (`supabase/functions/auth-telegram/index.ts`)

```ts
import { serve } from "https://deno.land/std@0.217.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { jwtVerify, importJWK } from "https://esm.sh/jose@5.9.6";

const TELEGRAM_OIDC_ISSUER = "https://oauth.telegram.org";
const TELEGRAM_TOKEN_URL = "https://oauth.telegram.org/token";
const TELEGRAM_JWKS_URL  = "https://oauth.telegram.org/.well-known/jwks.json";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const TELEGRAM_BOT_CLIENT_ID     = Deno.env.get("TELEGRAM_BOT_CLIENT_ID")!;
const TELEGRAM_BOT_CLIENT_SECRET = Deno.env.get("TELEGRAM_BOT_CLIENT_SECRET")!;

interface ReqBody {
  code: string;
  codeVerifier: string;
  redirectUri: string;
  role?: "PATIENT" | "DOCTOR";
}

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const body = await req.json() as ReqBody;
  if (!body.code || !body.codeVerifier || !body.redirectUri) {
    return json({ error: "missing_params" }, 400);
  }
  // Defensive: only accept whitelisted role values.
  const role = body.role === "PATIENT" || body.role === "DOCTOR"
    ? body.role : null;

  // 1. Token exchange
  const tokenResp = await fetch(TELEGRAM_TOKEN_URL, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      code: body.code,
      redirect_uri: body.redirectUri,
      code_verifier: body.codeVerifier,
      client_id: TELEGRAM_BOT_CLIENT_ID,
      client_secret: TELEGRAM_BOT_CLIENT_SECRET,
    }),
  });
  if (!tokenResp.ok) return json({ error: "token_exchange_failed" }, 401);
  const { id_token } = await tokenResp.json();

  // 2. Verify ID token
  const jwks = await (await fetch(TELEGRAM_JWKS_URL)).json();
  const { payload } = await jwtVerify(id_token, async (header) => {
    const jwk = jwks.keys.find((k: any) => k.kid === header.kid);
    if (!jwk) throw new Error("kid_not_found");
    return importJWK(jwk, header.alg!);
  }, {
    issuer: TELEGRAM_OIDC_ISSUER,
    audience: TELEGRAM_BOT_CLIENT_ID,
  });

  const tgUserId = String(payload.sub);
  const claims = payload as Record<string, any>;

  // 3. Find or create user keyed on telegram_id
  const { data: existing } = await supabaseAdmin
    .from("profiles")
    .select("id, first_name")
    .eq("telegram_id", tgUserId)
    .maybeSingle();

  let userId: string;
  let isFreshProfile = false;

  if (existing) {
    userId = existing.id;
    isFreshProfile = existing.first_name == null;
  } else {
    const placeholderEmail = `tg_${tgUserId}@telegram.dastern.local`;
    const { data: created, error } = await supabaseAdmin.auth.admin.createUser({
      email: placeholderEmail,
      email_confirm: true,
      user_metadata: { telegram_id: tgUserId, role: role ?? "PATIENT" },
    });
    if (error) {
      return json({ error: "user_create_failed", detail: error.message }, 500);
    }
    userId = created.user.id;
    isFreshProfile = true;
  }

  // 4. Update profile with latest Telegram fields. Only set role on
  //    fresh profiles AND only when role was provided in the request.
  const profileUpdate: Record<string, unknown> = {
    telegram_id: tgUserId,
    telegram_username: claims.username ?? null,
    telegram_first_name: claims.first_name ?? null,
    telegram_last_name: claims.last_name ?? null,
    telegram_photo_url: claims.photo_url ?? null,
  };
  if (role && isFreshProfile) profileUpdate.role = role;
  await supabaseAdmin.from("profiles").update(profileUpdate).eq("id", userId);

  // 5. Generate a magiclink token for Flutter to consume
  const { data: link, error: linkErr } = await supabaseAdmin.auth.admin
    .generateLink({
      type: "magiclink",
      email: claims.email ?? `tg_${tgUserId}@telegram.dastern.local`,
    });
  if (linkErr) {
    return json({ error: "session_generate_failed", detail: linkErr.message }, 500);
  }

  return json({
    user_id: userId,
    hashed_token: link.properties?.hashed_token,
    email: claims.email ?? `tg_${tgUserId}@telegram.dastern.local`,
  }, 200);
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status, headers: { "content-type": "application/json" },
  });
}
```

## 8. Profile bootstrap trigger (server-side)

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

### 8.1 Role immutability after bootstrap

```sql
create or replace function public.tg_profiles_role_immutable()
returns trigger language plpgsql as $$
begin
  -- Allow role change only while the profile is still fresh (first_name IS NULL).
  -- After bootstrap, role is locked unless service_role makes the change.
  if new.role is distinct from old.role
     and old.first_name is not null
     and current_setting('request.jwt.claims', true)::json->>'role' <> 'service_role' then
    raise exception 'role_immutable_after_bootstrap';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_role_immutable on public.profiles;
create trigger profiles_role_immutable
before update of role on public.profiles
for each row execute function public.tg_profiles_role_immutable();
```

## 9. Auto role detection on sign-in

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
  if (profile == null) return '/welcome';
  if (profile.firstName == null || profile.firstName!.isEmpty) {
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
    final goingToAuth = state.uri.path == '/welcome'
                     || state.uri.path.startsWith('/sign-')
                     || state.uri.path.startsWith('/method-')
                     || state.uri.path.startsWith('/forgot-')
                     || state.uri.path.startsWith('/reset-')
                     || state.uri.path.startsWith('/auth/');
    if (session == null && !goingToAuth) return '/welcome';
    if (session != null && goingToAuth) {
      return ProviderScope.containerOf(ctx)
        .read(roleAwareInitialRouteProvider);
    }
    return null;
  },
  routes: [...],
);
```

## 10. Welcome and Method chooser pages

```dart
class WelcomePage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    Future<void> chooseRole(ChosenRole role) async {
      await ref.read(pendingRoleControllerProvider.notifier).set(role);
      if (context.mounted) context.push('/method-chooser');
    }
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
            onTap: () => chooseRole(ChosenRole.patient),
          ),
          const SizedBox(height: AppSpacing.md),
          RoleChooserCard(
            role: ChosenRole.doctor,
            title: l10n.signUpAsDoctor,
            subtitle: l10n.signUpAsDoctorSubtitle,
            icon: Icons.medical_services_outlined,
            onTap: () => chooseRole(ChosenRole.doctor),
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

class MethodChooserPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<MethodChooserPage> createState() => _State();
}

class _State extends ConsumerState<MethodChooserPage> {
  bool _busyGoogle = false;
  bool _busyTelegram = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _busyGoogle = true);
    try {
      await ref.read(authRepositoryProvider).signInOrSignUpWithGoogle();
    } on AuthFailure catch (e) {
      if (mounted) _showError(e.code);
    } finally {
      if (mounted) setState(() => _busyGoogle = false);
    }
  }

  Future<void> _continueWithTelegram() async {
    setState(() => _busyTelegram = true);
    try {
      await ref.read(authRepositoryProvider).signInOrSignUpWithTelegram();
    } on AuthFailure catch (e) {
      if (mounted) _showError(e.code);
    } finally {
      if (mounted) setState(() => _busyTelegram = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.chooseHowToContinue,
               style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.lg),
          GoogleButton(loading: _busyGoogle, onPressed: _continueWithGoogle),
          const SizedBox(height: AppSpacing.sm),
          TelegramButton(loading: _busyTelegram, onPressed: _continueWithTelegram),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.continueWithEmailOrPhone,
            variant: AppButtonVariant.outlined,
            onPressed: () => context.push('/sign-up/credentials'),
          ),
        ]),
      ),
    );
  }
}
```

## 11. Profile bootstrap and optional doctor verification

### 11.1 Minimal bootstrap (both roles)

Per ADDENDUM-001 § 2.4.1, the bootstrap is a single screen asking only for the user's full name.

```dart
class ProfileBootstrapPage extends ConsumerStatefulWidget {
  ...
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
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    await Supabase.instance.client.from('profiles').update({
      'first_name': first,
      'last_name': last,
      'full_name': raw,
    }).eq('id', Supabase.instance.client.auth.currentUser!.id);
    // Pending role would have been consumed already by AuthRepository,
    // but be defensive: clear it if anything is still hanging around.
    await ref.read(pendingRoleControllerProvider.notifier).clear();
    if (mounted) context.go(_homeRouteForRole());
  }

  String _homeRouteForRole() {
    final role = ref.read(currentUserProfileProvider).value?.role;
    return role == UserRole.doctor ? '/doctor/home' : '/patient/home';
  }
  ...
}
```

### 11.2 Optional Doctor "Verify your practice" flow

```dart
class VerifyPracticeBanner extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null || profile.role != UserRole.doctor) return const SizedBox();
    if (profile.accountStatus == AccountStatus.verified) return const SizedBox();
    final dismissed = ref.watch(verifyBannerDismissedProvider);
    if (dismissed) return const SizedBox();
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.verified_user_outlined),
        title: Text(l10n.verifyPracticeTitle),
        subtitle: Text(l10n.verifyPracticeSubtitle),
        trailing: Wrap(spacing: 4, children: [
          TextButton(
            child: Text(l10n.dismiss),
            onPressed: () =>
              ref.read(verifyBannerDismissedProvider.notifier).state = true,
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

`VerifyPracticePage` collects optional professional fields and uploads `license_photo_url` to `doctor-licenses/<doctor_id>/...`. On submit it sets `account_status = 'PENDING_VERIFICATION'`. Authoring is **not** gated on verification status.

### 11.3 Verified badge

```dart
@riverpod
bool isDoctorVerified(Ref ref, String doctorId) {
  final profile = ref.watch(profileByIdProvider(doctorId)).valueOrNull;
  return profile?.role == UserRole.doctor
      && profile?.accountStatus == AccountStatus.verified;
}
```

Used wherever a doctor's identity appears.

## 12. Account deletion + export Edge Functions

Unchanged from the previous draft — `account-delete` and `account-export` run with the user's JWT and use the service-role admin client only when necessary.

## 13. Configuration matrix

| Env var | Where | Purpose |
|---|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Flutter `--dart-define` | Client init |
| `GOOGLE_WEB_CLIENT_ID` | Flutter `--dart-define` | google_sign_in serverClientId |
| `TELEGRAM_BOT_CLIENT_ID` | Flutter `--dart-define` + Edge secret | OIDC client id |
| `TELEGRAM_BOT_CLIENT_SECRET` | Edge secret only | Telegram token exchange |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge secret only | Admin SDK |
| (Twilio or other SMS provider in Supabase Dashboard) | Supabase Auth | SMS OTP delivery |
| (Apple Service ID, Team Key ID, Apple private key) | Supabase Auth | iOS phase only |

## 14. Threat model

| Threat | Mitigation |
|---|---|
| Stolen access token | 1h JWT lifetime; refresh-token rotation. |
| Stolen refresh token | Rotation; revoke other sessions on password change. |
| OAuth callback hijack | PKCE + state verification; deep link only for Telegram. |
| Forged Telegram ID token | JWKS signature + iss/aud/exp checks in Edge Function. |
| Mass OTP enumeration | Supabase OTP rate limits + 30s resend cool-down. |
| Account enumeration on sign-in failure | Generic "Invalid email/phone or password". |
| Lateral data access via leaked anon key | RLS on every table. |
| Role elevation via tampered metadata | `tg_profiles_role_immutable` trigger; Edge Function ignores `role` if `first_name IS NOT NULL`; Postgres trigger uses metadata only at insert time. |
| WebView OAuth phishing | OAuth uses external system browser only. |

## 15. Testing

- **Unit:** `CredentialKindDetector` boundaries; `AuthRepository.signInOrSignUpWithGoogle` applies pending role only on first-time profiles; Telegram OIDC verifier rejects invalid signature/expired/wrong-aud.
- **Widget:** Welcome → Method chooser flow; sign-in page displays all three options; password show/hide; provider buttons brand-coloured.
- **Integration:** Supabase local stack — sign up via each method as Patient and Doctor; first-time bootstrap; sign in returning user via each method; pending role cleared after consumption.
- **Security:** Tamper with `state` in Telegram callback → app aborts; replay old `code` → fails; force `role = 'DOCTOR'` on a returning Patient → trigger rejects.
