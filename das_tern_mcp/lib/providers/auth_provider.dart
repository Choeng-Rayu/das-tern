import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/logger_service.dart';
import '../core/config/dev_config.dart';

/// Manages authentication state: login, register, logout, token storage.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    ApiService? apiService,
    DatabaseService? databaseService,
    NotificationService? notificationService,
    LoggerService? loggerService,
    AppLinks? appLinks,
    FlutterSecureStorage? secureStorage,
    bool enableTelegramDeepLinkListener = true,
  }) : _api = apiService ?? ApiService.instance,
       _databaseService = databaseService ?? DatabaseService.instance,
       _notificationService =
           notificationService ?? NotificationService.instance,
       _log = loggerService ?? LoggerService.instance,
       _appLinks = appLinks ?? AppLinks(),
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock,
             ),
           ) {
    if (enableTelegramDeepLinkListener) {
      _initTelegramAuthListener();
    }
  }

  final ApiService _api;
  final DatabaseService _databaseService;
  final NotificationService _notificationService;
  final LoggerService _log;
  final AppLinks _appLinks;
  final FlutterSecureStorage _secureStorage;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId: the web OAuth 2.0 client ID — used by backend to validate the idToken
    serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
    // clientId: iOS-only native client ID — setting this on Android causes immediate cancellation
    clientId: Platform.isIOS ? dotenv.env['GOOGLE_IOS_CLIENT_ID'] : null,
  );

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  String? _error;
  Future<void>? _loadAuthStateFuture;
  StreamSubscription<Uri>? _telegramLinkSubscription;
  Completer<Uri>? _telegramCallbackCompleter;
  String? _telegramExpectedState;
  bool _telegramLinkListenerStarted = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String? get userRole => _user?['role'];
  bool get isDoctor => userRole == 'DOCTOR';
  bool get isPatient => userRole == 'PATIENT';

  @override
  void dispose() {
    _telegramLinkSubscription?.cancel();
    super.dispose();
  }

  /// Load stored auth state on app start.
  Future<void> loadAuthState() async {
    final inFlight = _loadAuthStateFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _loadAuthStateInternal();
    _loadAuthStateFuture = future;

    try {
      await future;
    } finally {
      if (identical(_loadAuthStateFuture, future)) {
        _loadAuthStateFuture = null;
      }
    }
  }

  Future<void> _loadAuthStateInternal() async {
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
      try {
        await _secureStorage.deleteAll();
        await _secureStorage.write(key: 'accessToken', value: _accessToken);
        await _secureStorage.write(key: 'refreshToken', value: _refreshToken);
      } catch (_) {
        // Keychain errors in simulator are non-fatal in dev mode
      }
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
        if (_isAuthFailure(e)) {
          _log.warning(
            'AuthProvider',
            'Access token invalid, trying refresh',
            e,
          );
          if (_refreshToken != null) {
            try {
              final result = await _api.refreshToken(_refreshToken!);
              await _saveTokens(result);
              _user = result['user'];
              _isAuthenticated = true;
              _log.success(
                'AuthProvider',
                'Token refreshed, user authenticated',
              );
            } catch (e2) {
              if (_isAuthFailure(e2)) {
                _log.error(
                  'AuthProvider',
                  'Token refresh rejected, clearing tokens',
                  e2,
                );
                await _clearTokens();
              } else {
                _log.warning(
                  'AuthProvider',
                  'Token refresh failed due to network/server issue, keeping tokens',
                  e2,
                );
              }
            }
          } else {
            await _clearTokens();
          }
        } else {
          _log.warning(
            'AuthProvider',
            'Profile verification failed due to network/server issue, keeping tokens',
            e,
          );
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

  /// Sign in with Telegram OAuth 2.0 (OIDC + PKCE).
  Future<bool> signInWithTelegram({String? userRole}) async {
    _log.info('AuthProvider', 'Telegram Sign-In attempt', {
      'userRole': userRole,
    });
    _setLoading(true);
    _error = null;

    try {
      final clientId = dotenv.env['TELEGRAM_BOT_CLIENT_ID']?.trim();
      if (clientId == null || clientId.isEmpty) {
        _error = 'Telegram client ID is not configured';
        notifyListeners();
        return false;
      }

      final oauthRedirectUri = _telegramOAuthRedirectUri;
      final state = _generateRandomBase64Url(16);
      final codeVerifier = _generateRandomBase64Url(64);
      final codeChallenge = _base64UrlNoPadding(
        sha256.convert(utf8.encode(codeVerifier)).bytes,
      );

      _telegramExpectedState = state;
      _telegramCallbackCompleter = Completer<Uri>();

      final authUrl = Uri.https('oauth.telegram.org', '/auth', {
        'client_id': clientId,
        'redirect_uri': oauthRedirectUri,
        'response_type': 'code',
        'scope': 'openid profile phone',
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      });

      final didLaunch = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!didLaunch) {
        _error = 'Unable to open Telegram login';
        notifyListeners();
        return false;
      }

      final callbackUri = await _telegramCallbackCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw TimeoutException('Telegram login timed out'),
      );

      final callbackState = callbackUri.queryParameters['state'];
      if (callbackState == null || callbackState != _telegramExpectedState) {
        _error = 'Telegram login state validation failed';
        notifyListeners();
        return false;
      }

      final callbackError = callbackUri.queryParameters['error'];
      if (callbackError != null && callbackError.isNotEmpty) {
        _error = callbackError;
        notifyListeners();
        return false;
      }

      final code = callbackUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        _error = 'Telegram did not return an authorization code';
        notifyListeners();
        return false;
      }

      final result = await _api.telegramLogin(
        code,
        codeVerifier,
        oauthRedirectUri,
        userRole: userRole,
      );

      await _saveTokens(result);
      _user = result['user'];
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiException: ', '');
      _log.error('AuthProvider', 'Telegram Sign-In failed', e);
      notifyListeners();
      return false;
    } finally {
      _telegramExpectedState = null;
      _telegramCallbackCompleter = null;
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
    await _databaseService.clearAll();
    await _notificationService.cancelAllReminders();
    _user = null;
    _isAuthenticated = false;
    _log.success('AuthProvider', 'Logout complete');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Update user profile fields.
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _api.updateProfile(data);
      _user = result;
      _log.success('AuthProvider', 'Profile updated');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      _log.error('AuthProvider', 'Profile update failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change password for current user.
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      await _api.changePassword(currentPassword, newPassword);
      _log.success('AuthProvider', 'Password changed');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      _log.error('AuthProvider', 'Password change failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current user profile from server.
  Future<void> refreshProfile() async {
    try {
      if (_accessToken != null) {
        _user = await _api.getProfile(_accessToken!);
        notifyListeners();
      }
    } catch (e) {
      _log.error('AuthProvider', 'Failed to refresh profile', e);
    }
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
    _user = null;
    _isAuthenticated = false;
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
  }

  bool _isAuthFailure(Object error) {
    return error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403);
  }

  Future<void> _initTelegramAuthListener() async {
    if (_telegramLinkListenerStarted) {
      return;
    }
    _telegramLinkListenerStarted = true;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleTelegramCallbackUri(initialUri);
      }
    } catch (error) {
      _log.warning('AuthProvider', 'Failed reading initial deep link', error);
    }

    _telegramLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleTelegramCallbackUri(uri);
      },
      onError: (error) {
        _log.warning('AuthProvider', 'Telegram deep link stream error', error);
      },
    );
  }

  void _handleTelegramCallbackUri(Uri uri) {
    if (!_isTelegramCallbackUri(uri)) {
      return;
    }

    final completer = _telegramCallbackCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(uri);
    }
  }

  bool _isTelegramCallbackUri(Uri uri) {
    final expected = Uri.parse(_telegramRedirectUri);
    return uri.scheme == expected.scheme &&
        uri.host == expected.host &&
        uri.path == expected.path;
  }

  String get _telegramAppRedirectUri {
    final configured = dotenv.env['TELEGRAM_APP_REDIRECT_URI']?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return 'dastern://auth/telegram/callback';
  }

  String get _telegramOAuthRedirectUri {
    final configured = dotenv.env['TELEGRAM_OAUTH_REDIRECT_URI']?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return '${dotenv.env['API_BASE_URL']}/auth/telegram/callback';
  }

  String get _telegramRedirectUri => _telegramAppRedirectUri;

  String _generateRandomBase64Url(int bytesLength) {
    final random = Random.secure();
    final bytes = List<int>.generate(bytesLength, (_) => random.nextInt(256));
    return _base64UrlNoPadding(bytes);
  }

  String _base64UrlNoPadding(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
