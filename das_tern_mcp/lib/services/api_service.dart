import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Custom exception for API errors with structured info.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, [this.body]);

  @override
  String toString() => message;
}

/// Singleton HTTP client for all backend API calls.
/// Matches the NestJS backend at /api/v1.
/// Includes automatic 401 token-refresh retry.
class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String get baseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? 'https://localhost:3001/api/v1';
    // In release mode, enforce HTTPS
    assert(
      url.startsWith('https://') || kDebugMode,
      'API_BASE_URL must use HTTPS in production',
    );
    return url;
  }

  // ────────────────────────────────────────────
  // Token helpers (encrypted storage)
  // ────────────────────────────────────────────

  Future<String?> _getAccessToken() async {
    return _secureStorage.read(key: 'accessToken');
  }

  Future<String?> _getRefreshToken() async {
    return _secureStorage.read(key: 'refreshToken');
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _secureStorage.write(key: 'accessToken', value: access);
    await _secureStorage.write(key: 'refreshToken', value: refresh);
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getAccessToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ────────────────────────────────────────────
  // Response handling
  // ────────────────────────────────────────────

  dynamic _handleResponse(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    String msg = 'Request failed';
    if (body is Map) {
      final m = body['message'];
      msg = m is List ? m.join(', ') : (m?.toString() ?? msg);
    }
    throw ApiException(res.statusCode, msg, body);
  }

  /// Try refreshing the access token. Returns true on success.
  Future<bool> _tryRefreshToken() async {
    final rt = await _getRefreshToken();
    if (rt == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rt}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        await _saveTokens(data['accessToken'], data['refreshToken']);
        return true;
      }
    } catch (_) {}
    await _clearTokens();
    return false;
  }

  /// Wrapper that auto-retries once on 401 after token refresh.
  Future<dynamic> _authenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _headers();
    var res = await request(headers);
    if (res.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        headers = await _headers();
        res = await request(headers);
      }
    }
    return _handleResponse(res);
  }

  // ────────────────────────────────────────────
  // Auth endpoints
  // ────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'phoneNumber': phoneNumber, 'password': password}),
    );
    return Map<String, dynamic>.from(_handleResponse(res));
  }

  Future<Map<String, dynamic>> registerPatient({
    required String firstName,
    required String lastName,
    required String gender,
    required String dateOfBirth,
    required String idCardNumber,
    required String phoneNumber,
    required String password,
    required String pinCode,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register/patient'),
      headers: await _headers(auth: false),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'idCardNumber': idCardNumber,
        'phoneNumber': phoneNumber,
        'password': password,
        'pinCode': pinCode,
      }),
    );
    return Map<String, dynamic>.from(_handleResponse(res));
  }

  Future<Map<String, dynamic>> registerDoctor({
    required String fullName,
    required String phoneNumber,
    required String hospitalClinic,
    required String specialty,
    required String licenseNumber,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register/doctor'),
      headers: await _headers(auth: false),
      body: jsonEncode({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'hospitalClinic': hospitalClinic,
        'specialty': specialty,
        'licenseNumber': licenseNumber,
        'password': password,
      }),
    );
    return Map<String, dynamic>.from(_handleResponse(res));
  }

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/otp/send'),
      headers: await _headers(auth: false),
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );
    return Map<String, dynamic>.from(_handleResponse(res));
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/otp/verify'),
      headers: await _headers(auth: false),
      body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
    );
    return Map<String, dynamic>.from(_handleResponse(res));
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: await _headers(auth: false),
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    return Map<String, dynamic>.from(_handleResponse(res));
  }

  /// GET /auth/me – fetch current user from token.
  Future<Map<String, dynamic>> getProfile(String accessToken) async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    return Map<String, dynamic>.from(_handleResponse(res));
  }

  Future<void> logout() async {
    await _clearTokens();
  }

  // ────────────────────────────────────────────
  // User endpoints
  // ────────────────────────────────────────────

  /// GET /users/me
  Future<Map<String, dynamic>> getMyProfile() async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/users/me'), headers: h),
      ),
    );
  }

  /// PATCH /users/me
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/users/me'),
            headers: h, body: jsonEncode(data)),
      ),
    );
  }

  /// GET /users/storage
  Future<Map<String, dynamic>> getStorageInfo() async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/users/storage'), headers: h),
      ),
    );
  }

  /// GET /users/:id
  Future<Map<String, dynamic>> getUserById(String id) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/users/$id'), headers: h),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Prescription endpoints
  // ────────────────────────────────────────────

  /// GET /prescriptions
  Future<List<dynamic>> getPrescriptions({String? status, String? patientId}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (patientId != null) params['patientId'] = patientId;
    final uri = Uri.parse('$baseUrl/prescriptions')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    return List<dynamic>.from(
      await _authenticatedRequest((h) => http.get(uri, headers: h)),
    );
  }

  /// GET /prescriptions/:id
  Future<Map<String, dynamic>> getPrescription(String id) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/prescriptions/$id'), headers: h),
      ),
    );
  }

  /// POST /prescriptions
  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.post(Uri.parse('$baseUrl/prescriptions'),
            headers: h, body: jsonEncode(data)),
      ),
    );
  }

  /// PATCH /prescriptions/:id
  Future<Map<String, dynamic>> updatePrescription(
      String id, Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/prescriptions/$id'),
            headers: h, body: jsonEncode(data)),
      ),
    );
  }

  /// POST /prescriptions/:id/urgent-update
  Future<Map<String, dynamic>> urgentUpdatePrescription(
      String id, Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.post(Uri.parse('$baseUrl/prescriptions/$id/urgent-update'),
            headers: h, body: jsonEncode(data)),
      ),
    );
  }

  /// POST /prescriptions/:id/confirm
  Future<Map<String, dynamic>> confirmPrescription(String id) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.post(Uri.parse('$baseUrl/prescriptions/$id/confirm'),
            headers: h, body: jsonEncode({})),
      ),
    );
  }

  /// POST /prescriptions/:id/retake
  Future<Map<String, dynamic>> retakePrescription(String id) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.post(Uri.parse('$baseUrl/prescriptions/$id/retake'),
            headers: h, body: jsonEncode({})),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Dose endpoints
  // ────────────────────────────────────────────

  /// GET /doses/schedule
  Future<Map<String, dynamic>> getDoseSchedule({String? date, String? groupBy}) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (groupBy != null) params['groupBy'] = groupBy;
    final uri = Uri.parse('$baseUrl/doses/schedule')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    return Map<String, dynamic>.from(
      await _authenticatedRequest((h) => http.get(uri, headers: h)),
    );
  }

  /// GET /doses/history?page=&take=
  Future<List<dynamic>> getDoseHistory({
    int? page,
    int? take,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = page.toString();
    if (take != null) params['take'] = take.toString();
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    final uri = Uri.parse('$baseUrl/doses/history')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    return List<dynamic>.from(
      await _authenticatedRequest((h) => http.get(uri, headers: h)),
    );
  }

  /// PATCH /doses/:id/taken
  Future<Map<String, dynamic>> markDoseTaken(String id,
      {DateTime? takenAt, bool offline = false}) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/doses/$id/taken'),
            headers: h,
            body: jsonEncode({
              if (takenAt != null) 'takenAt': takenAt.toIso8601String(),
              'offline': offline,
            })),
      ),
    );
  }

  /// PATCH /doses/:id/skipped
  Future<Map<String, dynamic>> skipDose(String id, String reason) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/doses/$id/skipped'),
            headers: h, body: jsonEncode({'reason': reason})),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Connection endpoints
  // ────────────────────────────────────────────

  /// GET /connections
  Future<List<dynamic>> getConnections({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$baseUrl/connections')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    return List<dynamic>.from(
      await _authenticatedRequest((h) => http.get(uri, headers: h)),
    );
  }

  /// POST /connections
  Future<Map<String, dynamic>> createConnection(Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.post(Uri.parse('$baseUrl/connections'),
            headers: h, body: jsonEncode(data)),
      ),
    );
  }

  /// PATCH /connections/:id/accept
  Future<Map<String, dynamic>> acceptConnection(
      String id, Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/connections/$id/accept'),
            headers: h, body: jsonEncode(data)),
      ),
    );
  }

  /// PATCH /connections/:id/revoke
  Future<Map<String, dynamic>> revokeConnection(String id) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/connections/$id/revoke'),
            headers: h, body: jsonEncode({})),
      ),
    );
  }

  /// PATCH /connections/:id/permission
  Future<Map<String, dynamic>> updateConnectionPermission(
      String id, Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/connections/$id/permission'),
            headers: h, body: jsonEncode(data)),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Notification endpoints
  // ────────────────────────────────────────────

  /// GET /notifications?unreadOnly=true
  Future<Map<String, dynamic>> getNotifications({bool unreadOnly = false}) async {
    final params = <String, String>{};
    if (unreadOnly) params['unreadOnly'] = 'true';
    final uri = Uri.parse('$baseUrl/notifications')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    return Map<String, dynamic>.from(
      await _authenticatedRequest((h) => http.get(uri, headers: h)),
    );
  }

  /// PATCH /notifications/:id/read
  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/notifications/$id/read'),
            headers: h, body: jsonEncode({})),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Subscription endpoints
  // ────────────────────────────────────────────

  /// GET /subscriptions/me
  Future<Map<String, dynamic>> getSubscription() async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/subscriptions/me'), headers: h),
      ),
    );
  }

  /// PATCH /subscriptions/tier
  Future<Map<String, dynamic>> updateSubscriptionTier(String tier) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.patch(Uri.parse('$baseUrl/subscriptions/tier'),
            headers: h, body: jsonEncode({'tier': tier})),
      ),
    );
  }

  /// POST /subscriptions/family/add
  Future<Map<String, dynamic>> addFamilyMember(Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.post(Uri.parse('$baseUrl/subscriptions/family/add'),
            headers: h, body: jsonEncode(data)),
      ),
    );
  }

  /// DELETE /subscriptions/family/:memberId
  Future<Map<String, dynamic>> removeFamilyMember(String memberId) async {
    return Map<String, dynamic>.from(
      await _authenticatedRequest(
        (h) => http.delete(
            Uri.parse('$baseUrl/subscriptions/family/$memberId'),
            headers: h),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Audit endpoints
  // ────────────────────────────────────────────

  /// GET /audit
  Future<List<dynamic>> getAuditLogs({int? page, int? take}) async {
    final params = <String, String>{};
    if (page != null) params['page'] = page.toString();
    if (take != null) params['take'] = take.toString();
    final uri = Uri.parse('$baseUrl/audit')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    return List<dynamic>.from(
      await _authenticatedRequest((h) => http.get(uri, headers: h)),
    );
  }
}
