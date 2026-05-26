import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for the keys the app uses.
///
/// All auth tokens and encryption keys go through here — never into
/// [SharedPreferences].
///
/// Spec ref: 00-overview §Requirement 7.
class SecureStorage {
  const SecureStorage([FlutterSecureStorage? impl])
    : _impl = impl ?? const FlutterSecureStorage();

  final FlutterSecureStorage _impl;

  static const String _accessToken = 'supabase_access_token';
  static const String _refreshToken = 'supabase_refresh_token';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _impl.write(key: _accessToken, value: accessToken);
    await _impl.write(key: _refreshToken, value: refreshToken);
  }

  Future<String?> readAccessToken() => _impl.read(key: _accessToken);
  Future<String?> readRefreshToken() => _impl.read(key: _refreshToken);

  Future<void> clearSession() async {
    await _impl.delete(key: _accessToken);
    await _impl.delete(key: _refreshToken);
  }
}
