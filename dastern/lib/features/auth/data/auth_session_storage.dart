import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session tokens in secure storage.
class AuthSessionStorage {
  const AuthSessionStorage(this._secure);
  final FlutterSecureStorage _secure;

  static const _accessKey = 'auth_access_token_v1';
  static const _refreshKey = 'auth_refresh_token_v1';

  Future<void> persist(Session session) async {
    await _secure.write(key: _accessKey, value: session.accessToken);
    await _secure.write(key: _refreshKey, value: session.refreshToken);
  }

  Future<String?> readRefreshToken() => _secure.read(key: _refreshKey);

  Future<void> clear() async {
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
  }
}
