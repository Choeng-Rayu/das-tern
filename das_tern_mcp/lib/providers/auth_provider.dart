import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Manages authentication state: login, register, logout, token storage.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
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
    _accessToken = await _secureStorage.read(key: 'accessToken');
    _refreshToken = await _secureStorage.read(key: 'refreshToken');

    if (_accessToken != null) {
      try {
        _user = await _api.getProfile(_accessToken!);
        _isAuthenticated = true;
      } catch (_) {
        // Token expired – try refresh
        if (_refreshToken != null) {
          try {
            final result = await _api.refreshToken(_refreshToken!);
            await _saveTokens(result);
            _user = result['user'];
            _isAuthenticated = true;
          } catch (_) {
            await _clearTokens();
          }
        }
      }
    }
    notifyListeners();
  }

  /// Login with phone number and password.
  Future<bool> login(String phoneNumber, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _api.login(phoneNumber, password);
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

  /// Register a new patient.
  Future<Map<String, dynamic>?> registerPatient({
    required String firstName,
    required String lastName,
    required String gender,
    required String dateOfBirth,
    required String idCardNumber,
    required String phoneNumber,
    required String password,
    required String pinCode,
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
        phoneNumber: phoneNumber,
        password: password,
        pinCode: pinCode,
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
    required String phoneNumber,
    required String hospitalClinic,
    required String specialty,
    required String licenseNumber,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _api.registerDoctor(
        fullName: fullName,
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
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _api.verifyOtp(phoneNumber, otp);
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

  /// Send OTP to phone number.
  Future<bool> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _error = null;
    try {
      await _api.sendOtp(phoneNumber);
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
    await _clearTokens();
    await DatabaseService.instance.clearAll();
    await NotificationService.instance.cancelAllReminders();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Private helpers ──

  void _setLoading(bool v) {
    _isLoading = v;
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
