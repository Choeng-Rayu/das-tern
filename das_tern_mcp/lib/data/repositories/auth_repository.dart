/// Repository for authentication operations.
///
/// Wraps [ApiService] auth endpoints and returns typed results.
/// Exceptions are caught and returned as [AuthResult.failure].
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/user_models.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';

// ─── Result type ────────────────────────────────────────────────────────────

/// Sealed result for auth operations — either success or failure.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
  final CurrentUser user;
  final String accessToken;
  final String refreshToken;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}

/// Sealed result for void auth operations (OTP send, password reset, etc.)
sealed class VoidResult {
  const VoidResult();
}

class VoidSuccess extends VoidResult {
  const VoidSuccess();
}

class VoidFailure extends VoidResult {
  const VoidFailure(this.message);
  final String message;
}

// ─── Repository ─────────────────────────────────────────────────────────────

class AuthRepository {
  AuthRepository({ApiService? api, FlutterSecureStorage? storage})
    : _api = api ?? ApiService.instance,
      _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final ApiService _api;
  final FlutterSecureStorage _storage;
  final LoggerService _log = LoggerService.instance;

  // ── Token persistence ───────────────────────────────────────────────────

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'accessToken', value: access);
    await _storage.write(key: 'refreshToken', value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: 'accessToken');
  Future<String?> get refreshToken => _storage.read(key: 'refreshToken');

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // ── Auth operations ─────────────────────────────────────────────���───────

  /// Login with email/phone + password.
  Future<AuthResult> login(String identifier, String password) async {
    try {
      final result = await _api.login(identifier, password);
      return _parseAuthResponse(result);
    } catch (e) {
      _log.error('AuthRepository', 'login failed', e);
      return AuthFailure(_errorMessage(e));
    }
  }

  /// Google OAuth login.
  Future<AuthResult> googleLogin(String idToken, {String? userRole}) async {
    try {
      final result = await _api.googleLogin(idToken, userRole: userRole);
      return _parseAuthResponse(result);
    } catch (e) {
      _log.error('AuthRepository', 'googleLogin failed', e);
      return AuthFailure(_errorMessage(e));
    }
  }

  /// Telegram OAuth login.
  Future<AuthResult> telegramLogin(
    String code,
    String codeVerifier,
    String redirectUri, {
    String? userRole,
  }) async {
    try {
      final result = await _api.telegramLogin(
        code,
        codeVerifier,
        redirectUri,
        userRole: userRole,
      );
      return _parseAuthResponse(result);
    } catch (e) {
      _log.error('AuthRepository', 'telegramLogin failed', e);
      return AuthFailure(_errorMessage(e));
    }
  }

  /// Refresh tokens using stored refresh token.
  Future<AuthResult> refresh(String refreshToken) async {
    try {
      final result = await _api.refreshToken(refreshToken);
      return _parseAuthResponse(result);
    } catch (e) {
      _log.error('AuthRepository', 'refresh failed', e);
      return AuthFailure(_errorMessage(e));
    }
  }

  /// Fetch current user profile using access token.
  Future<CurrentUser?> fetchProfile(String accessToken) async {
    try {
      final json = await _api.getProfile(accessToken);
      return CurrentUser.fromJson(json);
    } catch (e) {
      _log.error('AuthRepository', 'fetchProfile failed', e);
      return null;
    }
  }

  /// Send OTP to identifier.
  Future<VoidResult> sendOtp(String identifier) async {
    try {
      await _api.sendOtp(identifier);
      return const VoidSuccess();
    } catch (e) {
      return VoidFailure(_errorMessage(e));
    }
  }

  /// Verify OTP.
  Future<AuthResult> verifyOtp(String identifier, String otp) async {
    try {
      final result = await _api.verifyOtp(identifier, otp);
      return _parseAuthResponse(result);
    } catch (e) {
      return AuthFailure(_errorMessage(e));
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  AuthResult _parseAuthResponse(Map<String, dynamic> result) {
    final userJson = result['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      return const AuthFailure('Invalid server response');
    }
    final access = result['accessToken'] as String? ?? '';
    final refresh = result['refreshToken'] as String? ?? '';
    return AuthSuccess(
      user: CurrentUser.fromJson(userJson),
      accessToken: access,
      refreshToken: refresh,
    );
  }

  String _errorMessage(Object e) {
    return e
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '');
  }
}
