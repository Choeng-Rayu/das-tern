/// Thin wrapper around [ApiService] for medication (medicine) endpoints.
library;

import '../../services/api_service.dart';

/// Service for medication-related HTTP calls.
///
/// Maps to the `/prescriptions/:id/medicines` and `/medicines/:id` endpoints
/// exposed by the NestJS backend.
class MedicationService {
  MedicationService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  /// Fetches all medicines belonging to [prescriptionId].
  ///
  /// Returns the prescription object which includes a `medications` list.
  Future<Map<String, dynamic>> getMedications(String prescriptionId) {
    return _api.getPrescription(prescriptionId);
  }

  /// Adds a new medicine to [prescriptionId].
  ///
  /// [data] must match the backend `CreateMedicineDto` shape.
  Future<Map<String, dynamic>> addMedication(
    String prescriptionId,
    Map<String, dynamic> data,
  ) {
    return _api.addMedicine(prescriptionId, data);
  }

  /// Updates an existing medicine identified by [id].
  ///
  /// [data] must match the backend `UpdateMedicineDto` shape.
  Future<Map<String, dynamic>> updateMedication(
    String id,
    Map<String, dynamic> data,
  ) {
    return _api.updateMedicine(id, data);
  }

  /// Permanently removes a medicine identified by [id].
  Future<Map<String, dynamic>> deleteMedication(String id) {
    return _api.deleteMedicine(id);
  }
}
