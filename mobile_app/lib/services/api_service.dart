import 'dart:convert';
import 'package:http/http.dart' as http;
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
      String phoneNumber, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
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
    required String idCardNumber,
    required String phoneNumber,
    required String password,
    String? email,
  }) async {
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'idCardNumber': idCardNumber,
      'phoneNumber': phoneNumber,
      'password': password,
      if (email != null) 'email': email,
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
    required String licenseNumber,
    required String hospitalClinic,
    required String specialty,
    required String phoneNumber,
    required String password,
    String? email,
  }) async {
    final body = {
      'fullName': fullName,
      'licenseNumber': licenseNumber,
      'hospitalClinic': hospitalClinic,
      'specialty': specialty,
      'phoneNumber': phoneNumber,
      'password': password,
      if (email != null) 'email': email,
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
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /auth/otp/verify
  Future<Map<String, dynamic>> verifyOtp(
      String phoneNumber, String otpCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'otpCode': otpCode,
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

  /// Local logout (clear tokens)
  Future<void> logout() async {
    await _clearTokens();
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
