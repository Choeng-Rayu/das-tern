import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Unified API Service aligned 1:1 with NestJS backend controllers.
/// Base URL: configured via .env API_BASE_URL or defaults to http://localhost:3001/api/v1
class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3001/api/v1';

  // ─── Token Management ────────────────────────────────────────

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Generic request wrapper with automatic token refresh on 401
  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _getHeaders();
    var response = await request(headers);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await request(headers);
      }
    }
    return response;
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final rt = await _getRefreshToken();
      if (rt == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rt}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTH – /api/v1/auth
  // ═══════════════════════════════════════════════════════════════

  /// POST /auth/login
  Future<Map<String, dynamic>> login(
      String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['accessToken'] != null && data['refreshToken'] != null) {
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
      }
      return data;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/register/patient
  Future<Map<String, dynamic>> registerPatient({
    required String firstName,
    required String lastName,
    required String gender,
    required String dateOfBirth,
    required String email,
    required String password,
    String? idCardNumber,
    String? phoneNumber,
  }) async {
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'email': email,
      'password': password,
      if (idCardNumber != null && idCardNumber.isNotEmpty) 'idCardNumber': idCardNumber,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/patient'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['accessToken'] != null && data['refreshToken'] != null) {
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
      }
      return data;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/register/doctor
  Future<Map<String, dynamic>> registerDoctor({
    required String fullName,
    required String email,
    required String password,
    String? licenseNumber,
    String? hospitalClinic,
    String? specialty,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'password': password,
      if (licenseNumber != null && licenseNumber.isNotEmpty) 'licenseNumber': licenseNumber,
      if (hospitalClinic != null && hospitalClinic.isNotEmpty) 'hospitalClinic': hospitalClinic,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/doctor'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['accessToken'] != null && data['refreshToken'] != null) {
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
      }
      return data;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/otp/send
  Future<Map<String, dynamic>> sendOtp(String identifier) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/otp/verify
  Future<Map<String, dynamic>> verifyOtp(
      String identifier, String otpCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'otp': otpCode,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/refresh
  Future<Map<String, dynamic>> refreshTokenExplicit() async {
    final rt = await _getRefreshToken();
    if (rt == null) throw ApiException(401, 'No refresh token');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': rt}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      return data;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// GET /auth/me
  Future<Map<String, dynamic>> getMe() async {
    final response = await _authenticatedRequest(
      (headers) => http.get(Uri.parse('$baseUrl/auth/me'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/google
  Future<Map<String, dynamic>> googleLogin(
      String idToken, {String? userRole}) async {
    final body = <String, dynamic>{
      'idToken': idToken,
      if (userRole != null) 'userRole': userRole,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['accessToken'] != null && data['refreshToken'] != null) {
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
      }
      return data;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// Local logout (clear tokens)
  Future<void> logout() async {
    await _clearTokens();
  }

  // ═══════════════════════════════════════════════════════════════
  // PASSWORD RESET – /api/v1/auth
  // ═══════════════════════════════════════════════════════════════

  /// POST /auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/reset-password
  Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/reset-password-otp
  Future<Map<String, dynamic>> resetPasswordWithOtp(
      String identifier, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ═══════════════════════════════════════════════════════════════
  // USERS – /api/v1/users
  // ═══════════════════════════════════════════════════════════════

  /// GET /users/me
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _authenticatedRequest(
      (headers) => http.get(Uri.parse('$baseUrl/users/me'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PATCH /users/me
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// GET /users/storage
  Future<Map<String, dynamic>> getStorage() async {
    final response = await _authenticatedRequest(
      (headers) =>
          http.get(Uri.parse('$baseUrl/users/storage'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// GET /users/:id
  Future<Map<String, dynamic>> getUserById(String id) async {
    final response = await _authenticatedRequest(
      (headers) =>
          http.get(Uri.parse('$baseUrl/users/$id'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ═══════════════════════════════════════════════════════════════
  // PRESCRIPTIONS – /api/v1/prescriptions
  // ═══════════════════════════════════════════════════════════════

  /// GET /prescriptions?status=&patientId=
  Future<List<dynamic>> getPrescriptions({
    String? status,
    String? patientId,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (patientId != null) queryParams['patientId'] = patientId;
    final uri = Uri.parse('$baseUrl/prescriptions')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await _authenticatedRequest(
      (headers) => http.get(uri, headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// GET /prescriptions/:id
  Future<Map<String, dynamic>> getPrescription(String id) async {
    final response = await _authenticatedRequest(
      (headers) =>
          http.get(Uri.parse('$baseUrl/prescriptions/$id'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /prescriptions
  Future<Map<String, dynamic>> createPrescription(
      Map<String, dynamic> data) async {
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/prescriptions'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PATCH /prescriptions/:id
  Future<Map<String, dynamic>> updatePrescription(
      String id, Map<String, dynamic> data) async {
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/prescriptions/$id'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /prescriptions/:id/urgent-update
  Future<Map<String, dynamic>> urgentUpdatePrescription(
      String id, Map<String, dynamic> data) async {
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/prescriptions/$id/urgent-update'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /prescriptions/:id/confirm
  Future<Map<String, dynamic>> confirmPrescription(String id) async {
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/prescriptions/$id/confirm'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /prescriptions/:id/retake
  Future<Map<String, dynamic>> retakePrescription(
      String id, String reason) async {
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/prescriptions/$id/retake'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ═══════════════════════════════════════════════════════════════
  // DOSES – /api/v1/doses
  // ═══════════════════════════════════════════════════════════════

  /// GET /doses/schedule?date=&groupBy=
  Future<Map<String, dynamic>> getDoseSchedule({
    String? date,
    String? groupBy,
  }) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    if (groupBy != null) queryParams['groupBy'] = groupBy;
    final uri = Uri.parse('$baseUrl/doses/schedule')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await _authenticatedRequest(
      (headers) => http.get(uri, headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// GET /doses/history?page=&take=
  Future<dynamic> getDoseHistory({int? page, int? take}) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (take != null) queryParams['take'] = take.toString();
    final uri = Uri.parse('$baseUrl/doses/history')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await _authenticatedRequest(
      (headers) => http.get(uri, headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PATCH /doses/:id/taken
  Future<Map<String, dynamic>> markDoseTaken(
    String id, {
    DateTime? takenAt,
    bool? wasOffline,
  }) async {
    final body = <String, dynamic>{};
    if (takenAt != null) body['takenAt'] = takenAt.toIso8601String();
    if (wasOffline != null) body['wasOffline'] = wasOffline;
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/doses/$id/taken'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PATCH /doses/:id/skipped
  Future<Map<String, dynamic>> skipDose(String id, String reason) async {
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/doses/$id/skipped'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ═══════════════════════════════════════════════════════════════
  // CONNECTIONS – /api/v1/connections
  // ═══════════════════════════════════════════════════════════════

  /// GET /connections?status=
  Future<List<dynamic>> getConnections({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    final uri = Uri.parse('$baseUrl/connections')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await _authenticatedRequest(
      (headers) => http.get(uri, headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /connections
  Future<Map<String, dynamic>> createConnection({
    required String recipientId,
    required String connectionType,
  }) async {
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/connections'),
        headers: headers,
        body: jsonEncode({
          'recipientId': recipientId,
          'connectionType': connectionType,
        }),
      ),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PATCH /connections/:id/accept
  Future<Map<String, dynamic>> acceptConnection(
      String id, String permissionLevel) async {
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/connections/$id/accept'),
        headers: headers,
        body: jsonEncode({'permissionLevel': permissionLevel}),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PATCH /connections/:id/revoke
  Future<void> revokeConnection(String id) async {
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/connections/$id/revoke'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// PATCH /connections/:id/permission
  Future<Map<String, dynamic>> updateConnectionPermission(
      String id, String permissionLevel) async {
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/connections/$id/permission'),
        headers: headers,
        body: jsonEncode({'permissionLevel': permissionLevel}),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATIONS – /api/v1/notifications
  // ═══════════════════════════════════════════════════════════════

  /// GET /notifications?unreadOnly=
  Future<Map<String, dynamic>> getNotifications({bool? unreadOnly}) async {
    final queryParams = <String, String>{};
    if (unreadOnly != null) queryParams['unreadOnly'] = unreadOnly.toString();
    final uri = Uri.parse('$baseUrl/notifications')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await _authenticatedRequest(
      (headers) => http.get(uri, headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PATCH /notifications/:id/read
  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: headers,
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ═══════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS – /api/v1/subscriptions
  // ═══════════════════════════════════════════════════════════════

  /// GET /subscriptions/me
  Future<Map<String, dynamic>> getSubscription() async {
    final response = await _authenticatedRequest(
      (headers) =>
          http.get(Uri.parse('$baseUrl/subscriptions/me'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PATCH /subscriptions/tier
  Future<Map<String, dynamic>> updateSubscriptionTier(String tier) async {
    final response = await _authenticatedRequest(
      (headers) => http.patch(
        Uri.parse('$baseUrl/subscriptions/tier'),
        headers: headers,
        body: jsonEncode({'tier': tier}),
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /subscriptions/family/add
  Future<Map<String, dynamic>> addFamilyMember(String memberId) async {
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/subscriptions/family/add'),
        headers: headers,
        body: jsonEncode({'memberId': memberId}),
      ),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// DELETE /subscriptions/family/:memberId
  Future<void> removeFamilyMember(String memberId) async {
    final response = await _authenticatedRequest(
      (headers) => http.delete(
        Uri.parse('$baseUrl/subscriptions/family/$memberId'),
        headers: headers,
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AUDIT – /api/v1/audit
  // ═══════════════════════════════════════════════════════════════

  /// GET /audit?page=&take=
  Future<dynamic> getAuditLogs({int? page, int? take}) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (take != null) queryParams['take'] = take.toString();
    final uri = Uri.parse('$baseUrl/audit')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await _authenticatedRequest(
      (headers) => http.get(uri, headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ─── MIME Detection Helper ────────────────────────────────────

  /// Detect MIME type from file extension and magic bytes fallback
  Future<String> _detectMimeType(File file) async {
    // Try extension first
    final ext = file.path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'webp':
        return 'image/webp';
    }

    // Fallback: read magic bytes
    try {
      final bytes = await file.openRead(0, 12).first;
      if (bytes.length >= 3 &&
          bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      if (bytes.length >= 4 &&
          bytes[0] == 0x89 && bytes[1] == 0x50 &&
          bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes.length >= 4 &&
          bytes[0] == 0x25 && bytes[1] == 0x50 &&
          bytes[2] == 0x44 && bytes[3] == 0x46) {
        return 'application/pdf';
      }
      if (bytes.length >= 12 &&
          bytes[8] == 0x57 && bytes[9] == 0x45 &&
          bytes[10] == 0x42 && bytes[11] == 0x50) {
        return 'image/webp';
      }
    } catch (_) {}

    return 'image/jpeg'; // Default to JPEG for camera images
  }

  // ═══════════════════════════════════════════════════════════════
  // OCR – /api/v1/ocr
  // ═══════════════════════════════════════════════════════════════

  /// POST /ocr/extract – Extract prescription data from image (no save)
  Future<Map<String, dynamic>> extractPrescription(File imageFile) async {
    final token = await _getAccessToken();
    final uri = Uri.parse('$baseUrl/ocr/extract');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final mimeType = await _detectMimeType(imageFile);

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: MediaType.parse(mimeType),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    // Handle 401 with token refresh
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newToken = await _getAccessToken();
        final retryRequest = http.MultipartRequest('POST', uri);
        if (newToken != null) {
          retryRequest.headers['Authorization'] = 'Bearer $newToken';
        }
        retryRequest.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ));
        final retryStreamedResponse = await retryRequest.send();
        final retryResponse = await http.Response.fromStream(retryStreamedResponse);
        if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
          return jsonDecode(retryResponse.body);
        }
        throw ApiException(retryResponse.statusCode, retryResponse.body);
      }
    }

    throw ApiException(response.statusCode, response.body);
  }

  /// POST /ocr/scan – Scan prescription image and create prescription
  Future<Map<String, dynamic>> scanPrescription(File imageFile) async {
    final token = await _getAccessToken();
    final uri = Uri.parse('$baseUrl/ocr/scan');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final mimeType = await _detectMimeType(imageFile);

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: MediaType.parse(mimeType),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newToken = await _getAccessToken();
        final retryRequest = http.MultipartRequest('POST', uri);
        if (newToken != null) {
          retryRequest.headers['Authorization'] = 'Bearer $newToken';
        }
        retryRequest.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ));
        final retryStreamedResponse = await retryRequest.send();
        final retryResponse = await http.Response.fromStream(retryStreamedResponse);
        if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
          return jsonDecode(retryResponse.body);
        }
        throw ApiException(retryResponse.statusCode, retryResponse.body);
      }
    }

    throw ApiException(response.statusCode, response.body);
  }

  /// POST /prescriptions/patient – Create patient prescription with reviewed OCR data
  Future<Map<String, dynamic>> createPatientPrescription(
      Map<String, dynamic> data) async {
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/prescriptions/patient'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }
}

/// Custom API exception with status code and response body.
class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  Map<String, dynamic>? get parsed {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String get message {
    final p = parsed;
    if (p != null && p['message'] != null) {
      return p['message'] is List
          ? (p['message'] as List).join(', ')
          : p['message'].toString();
    }
    return body;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
