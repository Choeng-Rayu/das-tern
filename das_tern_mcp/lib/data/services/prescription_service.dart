/// Thin wrapper around [ApiService] for prescription endpoints.
library;

import '../../services/api_service.dart';

/// Service for prescription-related HTTP calls.
class PrescriptionService {
  PrescriptionService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  /// Fetches all prescriptions visible to the current user.
  ///
  /// Optional [status] filter maps to `PrescriptionStatus` string values
  /// (e.g. `"ACTIVE"`, `"DRAFT"`).
  Future<List<dynamic>> getPrescriptions({String? status}) {
    return _api.getPrescriptions(status: status);
  }

  /// Fetches a single prescription by its [id].
  Future<Map<String, dynamic>> getPrescription(String id) {
    return _api.getPrescription(id);
  }

  /// Creates a new prescription from [data].
  ///
  /// [data] must match the backend `CreatePrescriptionDto` shape.
  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> data) {
    return _api.createPrescription(data);
  }

  /// Partially updates the prescription identified by [id].
  ///
  /// [data] must match the backend `UpdatePrescriptionDto` shape.
  Future<Map<String, dynamic>> updatePrescription(
    String id,
    Map<String, dynamic> data,
  ) {
    return _api.updatePrescription(id, data);
  }

  /// Permanently deletes the prescription identified by [id].
  Future<Map<String, dynamic>> deletePrescription(String id) {
    return _api.deletePrescription(id);
  }
}
