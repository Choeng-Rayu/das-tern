import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/logger_service.dart';
import '../core/config/dev_config.dart';

/// Manages authentication state: login, register, logout, token storage.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final LoggerService _log = LoggerService.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
  );

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String? get userRole => _user?['role'];
  bool get isDoctor => userRole == 'DOCTOR';
  bool get isPatient => userRole == 'PATIENT';

  /// Load stored auth state on app start.
  Future<void> loadAuthState() async {
    _log.info('AuthProvider', 'Loading auth state from storage');

    // ── DEV BYPASS ──────────────────────────────────────────────────────────
    // Skips login/register screen during development. Flip DevConfig.skipAuth
    // to false before building for production.
    if (DevConfig.skipAuth) {
      _log.warning(
        'AuthProvider',
        '⚠️  DEV MODE: Skipping auth — using dev user',
      );
      _accessToken = DevConfig.devAccessToken;
      _refreshToken = DevConfig.devRefreshToken;
      _user = Map<String, dynamic>.from(DevConfig.devUser);
      _isAuthenticated = true;
      await _secureStorage.write(key: 'accessToken', value: _accessToken);
      await _secureStorage.write(key: 'refreshToken', value: _refreshToken);
      notifyListeners();
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

    _accessToken = await _secureStorage.read(key: 'accessToken');
    _refreshToken = await _secureStorage.read(key: 'refreshToken');

    if (_accessToken != null) {
      _log.debug('AuthProvider', 'Access token found, verifying with server');
      try {
        _user = await _api.getProfile(_accessToken!);
        _isAuthenticated = true;
        _log.success('AuthProvider', 'User authenticated', {
          'userId': _user?['id'],
          'role': _user?['role'],
        });
      } catch (e) {
        _log.warning('AuthProvider', 'Access token invalid, trying refresh', e);
        // Token expired – try refresh
        if (_refreshToken != null) {
          try {
            final result = await _api.refreshToken(_refreshToken!);
            await _saveTokens(result);
            _user = result['user'];
            _isAuthenticated = true;
            _log.success('AuthProvider', 'Token refreshed, user authenticated');
          } catch (e2) {
            _log.error(
              'AuthProvider',
              'Token refresh failed, clearing tokens',
              e2,
            );
            await _clearTokens();
          }
        }
      }
    } else {
      _log.info('AuthProvider', 'No stored tokens found');
    }
    notifyListeners();
  }

  /// Login with phone number or email and password.
  Future<bool> login(String identifier, String password) async {
    _log.info('AuthProvider', 'Login attempt', {'identifier': identifier});
    _setLoading(true);
    _error = null;
    try {
      final result = await _api.login(identifier, password);
      await _saveTokens(result);
      _user = result['user'];
      _isAuthenticated = true;
      _log.success('AuthProvider', 'Login successful', {
        'userId': _user?['id'],
        'role': _user?['role'],
      });
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('AuthProvider', 'Login failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google OAuth.
  /// Optional userRole parameter for doctor registration flow.
  Future<bool> signInWithGoogle({String? userRole}) async {
    _log.info('AuthProvider', 'Google Sign-In attempt', {'userRole': userRole});
    _setLoading(true);
    _error = null;
    try {
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _log.warning('AuthProvider', 'Google Sign-In cancelled by user');
        _error = 'Sign in cancelled';
        notifyListeners();
        return false;
      }

      _log.debug('AuthProvider', 'Google account selected', {
        'email': googleUser.email,
      });

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        _log.error('AuthProvider', 'Failed to get Google ID token', {});
        _error = 'Failed to authenticate with Google';
        notifyListeners();
        return false;
      }

      _log.debug('AuthProvider', 'Got Google ID token, sending to backend');

      // Send to backend
      final result = await _api.googleLogin(
        googleAuth.idToken!,
        userRole: userRole,
      );
      await _saveTokens(result);
      _user = result['user'];
      _isAuthenticated = true;

      _log.success('AuthProvider', 'Google Sign-In successful', {
        'userId': _user?['id'],
        'role': _user?['role'],
        'email': _user?['email'],
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiException: ', '');
      _log.error('AuthProvider', 'Google Sign-In failed', e);

      // Sign out Google account on failure
      await _googleSignIn.signOut();

      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register a new patient.
  Future<Map<String, dynamic>?> registerPatient({
    required String firstName,
    required String lastName,
    required String gender,
    required String dateOfBirth,
    String? idCardNumber,
    required String email,
    String? phoneNumber,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _api.registerPatient(
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        idCardNumber: idCardNumber,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Register a new doctor.
  Future<Map<String, dynamic>?> registerDoctor({
    required String fullName,
    required String email,
    String? phoneNumber,
    String? hospitalClinic,
    String? specialty,
    String? licenseNumber,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _api.registerDoctor(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        hospitalClinic: hospitalClinic,
        specialty: specialty,
        licenseNumber: licenseNumber,
        password: password,
      );
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP after registration.
  Future<bool> verifyOtp(String identifier, String otp) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _api.verifyOtp(identifier, otp);
      await _saveTokens(result);
      _user = result['user'];
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send OTP to email or phone number.
  Future<bool> sendOtp(String identifier) async {
    _setLoading(true);
    _error = null;
    try {
      await _api.sendOtp(identifier);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Forgot password – sends reset code to email or phone.
  Future<bool> forgotPassword(String identifier) async {
    _setLoading(true);
    _error = null;
    try {
      await _api.forgotPassword(identifier);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password with OTP code.
  Future<bool> resetPasswordWithOtp(
    String identifier,
    String otp,
    String newPassword,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      await _api.resetPasswordWithOtp(identifier, otp, newPassword);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout – clear tokens, local DB, and notifications.
  Future<void> logout() async {
    _log.info('AuthProvider', 'Logout initiated');
    await _clearTokens();
    await DatabaseService.instance.clearAll();
    await NotificationService.instance.cancelAllReminders();
    _user = null;
    _isAuthenticated = false;
    _log.success('AuthProvider', 'Logout complete');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Private helpers ──

  void _setLoading(bool v) {
    _isLoading = v;
    _log.stateChange(
      'AuthProvider',
      _isLoading ? 'idle' : 'loading',
      v ? 'loading' : 'idle',
    );
    notifyListeners();
  }

  Future<void> _saveTokens(Map<String, dynamic> result) async {
    _accessToken = result['accessToken'];
    _refreshToken = result['refreshToken'];
    if (_accessToken != null) {
      await _secureStorage.write(key: 'accessToken', value: _accessToken!);
    }
    if (_refreshToken != null) {
      await _secureStorage.write(key: 'refreshToken', value: _refreshToken!);
    }
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
  }
}
