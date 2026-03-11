/// Repository for authentication and current-user state.
///
/// Acts as the single source of truth for the logged-in [User] object.
/// Maintains a simple in-memory cache so that the ViewModel does not need
/// to hit the network on every navigation.
library;

import '../models/user.dart';
import '../services/auth_service.dart';

/// Abstract contract — makes it easy to swap in a fake during tests.
abstract class AuthRepository {
  /// Signs in with [phone] and [password].
  ///
  /// On success, caches and returns the authenticated [User].
  Future<User> login(String phone, String password);

  /// Registers a new account described by [data].
  ///
  /// Returns the newly created [User].
  Future<User> register(Map<String, dynamic> data);

  /// Signs out the current user and clears the in-memory cache.
  Future<void> logout();

  /// Returns the currently cached [User], fetching from the network if needed.
  ///
  /// Returns `null` when no user is authenticated.
  Future<User?> getCurrentUser();
}

// ── Implementation ────────────────────────────────────────────────────────────

/// Concrete implementation backed by [AuthService].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthService? authService})
      : _service = authService ?? AuthService();

  final AuthService _service;

  /// In-memory cache — cleared on logout.
  User? _cachedUser;

  @override
  Future<User> login(String phone, String password) async {
    try {
      final json = await _service.login(phone, password);
      final userJson = _extractUser(json);
      final user = User.fromJson(userJson);
      _cachedUser = user;
      return user;
    } catch (e) {
      throw AuthException('Login failed: $e');
    }
  }

  @override
  Future<User> register(Map<String, dynamic> data) async {
    try {
      final json = await _service.register(data);
      final userJson = _extractUser(json);
      final user = User.fromJson(userJson);
      _cachedUser = user;
      return user;
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _service.logout();
    } finally {
      _cachedUser = null;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    try {
      final json = await _service.getMyProfile();
      final user = User.fromJson(json);
      _cachedUser = user;
      return user;
    } on AuthException {
      rethrow;
    } catch (_) {
      // Not authenticated or network error — return null gracefully.
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Extracts the `user` sub-object from a login/register response, or falls
  /// back to treating the entire response as the user object.
  Map<String, dynamic> _extractUser(Map<String, dynamic> json) {
    final nested = json['user'];
    if (nested is Map<String, dynamic>) return nested;
    return json;
  }
}

// ── Exception ─────────────────────────────────────────────────────────────────

/// Thrown by [AuthRepositoryImpl] when an authentication operation fails.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}
