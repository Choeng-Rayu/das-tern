/// Thin wrapper around [ApiService] for authentication endpoints.
/// All methods return raw JSON maps so that repositories can map them to
/// domain models without coupling the service layer to domain types.
library;

import '../../services/api_service.dart';

/// Service for authentication-related HTTP calls.
///
/// Uses the singleton [ApiService.instance] under the hood.
class AuthService {
  AuthService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  /// Authenticates a user with [phone] and [password].
  ///
  /// Returns the raw API response containing `accessToken`, `refreshToken`,
  /// and `user` fields.
  Future<Map<String, dynamic>> login(String phone, String password) {
    return _api.login(phone, password);
  }

  /// Registers a new user with the provided [data] map.
  ///
  /// Delegates to the appropriate registration endpoint based on the `role`
  /// key in [data] (`PATIENT` or `DOCTOR`).
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final role = (data['role'] as String? ?? '').toUpperCase();
    if (role == 'DOCTOR') {
      final firstName = data['firstName'] as String? ?? '';
      final lastName = data['lastName'] as String? ?? '';
      return _api.registerDoctor(
        fullName: '$firstName $lastName'.trim(),
        email: data['email'] as String? ?? '',
        password: data['password'] as String? ?? '',
        phoneNumber: data['phoneNumber'] as String? ?? data['phone'] as String?,
        licenseNumber: data['licenseNumber'] as String?,
        specialty: data['specialization'] as String? ?? data['specialty'] as String?,
        hospitalClinic: data['hospitalName'] as String? ?? data['hospitalClinic'] as String?,
      );
    }
    return _api.registerPatient(
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      gender: data['gender'] as String? ?? 'OTHER',
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? data['phone'] as String?,
    );
  }

  /// Logs out the currently authenticated user and clears local tokens.
  Future<void> logout() => _api.logout();

  /// Exchanges an expiring access token for a fresh one.
  ///
  /// [refreshToken] is the previously issued refresh token string.
  Future<Map<String, dynamic>> refreshToken(String refreshToken) {
    return _api.refreshToken(refreshToken);
  }

  /// Initiates the forgot-password flow for the given [phone] number.
  ///
  /// The backend sends an OTP to the supplied number.
  Future<Map<String, dynamic>> forgotPassword(String phone) {
    return _api.forgotPassword(phone);
  }

  /// Fetches the currently authenticated user's profile.
  Future<Map<String, dynamic>> getMyProfile() {
    return _api.getMyProfile();
  }
}
