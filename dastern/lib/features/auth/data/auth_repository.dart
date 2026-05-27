import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_failure.dart';
import '../domain/chosen_role.dart';
import 'auth_session_storage.dart';
import 'credential_kind_detector.dart';
import 'google_auth_client.dart';
import 'pending_role_storage.dart';
import 'telegram_auth_client.dart';

/// Result of a sign-up attempt — tells the UI what to show next.
class SignUpResult {
  const SignUpResult({
    required this.kind,
    required this.pendingPhoneOtp,
    required this.pendingEmailConfirm,
    this.session,
  });
  final CredentialKind kind;
  final bool pendingPhoneOtp;
  final bool pendingEmailConfirm;
  final Session? session;
}

/// Single entry point for all auth operations.
/// UI never calls SupabaseClient directly.
class AuthRepository {
  AuthRepository({
    required this._supabase,
    required this._sessionStorage,
    required this._google,
    required this._telegram,
    required this._pendingRole,
  });

  final SupabaseClient _supabase;
  final AuthSessionStorage _sessionStorage;
  final GoogleAuthClient _google;
  final TelegramAuthClient _telegram;
  final PendingRoleStorage _pendingRole;

  // ── email / phone + password ──────────────────────────────────────────

  Future<SignUpResult> signUpWithPassword({
    required String credential,
    required String password,
    required ChosenRole role,
  }) async {
    final kind = CredentialKindDetector.detect(credential);
    if (kind == CredentialKind.unknown) {
      throw const AuthFailure.invalidCredential();
    }
    try {
      final response = kind == CredentialKind.email
          ? await _supabase.auth.signUp(
              email: credential.trim(),
              password: password,
              data: <String, dynamic>{'role': role.code},
            )
          : await _supabase.auth.signUp(
              phone: CredentialKindDetector.normalizePhone(credential),
              password: password,
              data: <String, dynamic>{'role': role.code},
            );
      if (response.session != null) {
        await _sessionStorage.persist(response.session!);
      }
      return SignUpResult(
        kind: kind,
        pendingPhoneOtp:
            kind == CredentialKind.phone && response.session == null,
        pendingEmailConfirm:
            kind == CredentialKind.email && response.session == null,
        session: response.session,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String credential,
    required String password,
  }) async {
    final kind = CredentialKindDetector.detect(credential);
    if (kind == CredentialKind.unknown) {
      throw const AuthFailure.invalidCredential();
    }
    try {
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
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
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

  // ── Google ────────────────────────────────────────────────────────────

  Future<AuthResponse> signInOrSignUpWithGoogle() async {
    final response = await _google.authenticate(_supabase);
    if (response.session != null) {
      await _sessionStorage.persist(response.session!);
      await _applyPendingRoleIfFirstTime();
    }
    return response;
  }

  // ── Telegram ──────────────────────────────────────────────────────────

  Future<void> signInOrSignUpWithTelegram() async {
    final pendingRole = await _pendingRole.read();
    await _telegram.startAndCompleteSignIn(role: pendingRole);
    await _applyPendingRoleIfFirstTime();
  }

  // ── Password reset ────────────────────────────────────────────────────

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
    }
  }

  Future<void> updatePassword(String newPassword) =>
      _supabase.auth.updateUser(UserAttributes(password: newPassword));

  // ── Sign out ──────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _supabase.auth.signOut(scope: SignOutScope.global);
    await _sessionStorage.clear();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<void> _applyPendingRoleIfFirstTime() async {
    final pending = await _pendingRole.read();
    final user = _supabase.auth.currentUser;
    if (pending == null || user == null) return;
    final updated = await _supabase
        .from('profiles')
        .update(<String, dynamic>{'role': pending.code})
        .eq('id', user.id)
        .filter('first_name', 'is', null)
        .select();
    if ((updated as List).isNotEmpty) {
      await _pendingRole.clear();
    }
  }

  AuthFailure _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login')) return const AuthFailure.wrongPassword();
    if (msg.contains('user not found')) return const AuthFailure.userNotFound();
    if (msg.contains('already registered')) {
      return const AuthFailure.emailAlreadyInUse();
    }
    if (msg.contains('weak password')) return const AuthFailure.weakPassword();
    return AuthFailure.serverError(e.message);
  }
}
