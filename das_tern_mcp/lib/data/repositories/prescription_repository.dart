/// Repository for prescription data.
///
/// Translates raw JSON from [PrescriptionService] into clean
/// [Prescription] domain models.
library;

import '../models/prescription.dart';
import '../services/prescription_service.dart';

/// Abstract contract enabling easy test doubles.
abstract class PrescriptionRepository {
  /// Returns all prescriptions visible to the current user.
  Future<List<Prescription>> getPrescriptions({String? status});

  /// Returns a single prescription by its [id].
  Future<Prescription> getPrescription(String id);

  /// Creates a new prescription from [data] and returns the result.
  Future<Prescription> createPrescription(Map<String, dynamic> data);

  /// Updates the prescription identified by [id] and returns the result.
  Future<Prescription> updatePrescription(
    String id,
    Map<String, dynamic> data,
  );

  /// Permanently deletes the prescription identified by [id].
  Future<void> deletePrescription(String id);
}

// ── Implementation ────────────────────────────────────────────────────────────

/// Concrete implementation backed by [PrescriptionService].
class PrescriptionRepositoryImpl implements PrescriptionRepository {
  PrescriptionRepositoryImpl({PrescriptionService? service})
      : _service = service ?? PrescriptionService();

  final PrescriptionService _service;

  @override
  Future<List<Prescription>> getPrescriptions({String? status}) async {
    try {
      final list = await _service.getPrescriptions(status: status);
      return list
          .whereType<Map<String, dynamic>>()
          .map(Prescription.fromJson)
          .toList();
    } catch (e) {
      throw PrescriptionException('Failed to fetch prescriptions: $e');
    }
  }

  @override
  Future<Prescription> getPrescription(String id) async {
    try {
      final json = await _service.getPrescription(id);
      return Prescription.fromJson(json);
    } catch (e) {
      throw PrescriptionException('Failed to fetch prescription $id: $e');
    }
  }

  @override
  Future<Prescription> createPrescription(Map<String, dynamic> data) async {
    try {
      final json = await _service.createPrescription(data);
      return Prescription.fromJson(json);
    } catch (e) {
      throw PrescriptionException('Failed to create prescription: $e');
    }
  }

  @override
  Future<Prescription> updatePrescription(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final json = await _service.updatePrescription(id, data);
      return Prescription.fromJson(json);
    } catch (e) {
      throw PrescriptionException('Failed to update prescription $id: $e');
    }
  }

  @override
  Future<void> deletePrescription(String id) async {
    try {
      await _service.deletePrescription(id);
    } catch (e) {
      throw PrescriptionException('Failed to delete prescription $id: $e');
    }
  }
}

// ── Exception ─────────────────────────────────────────────────────────────────

/// Thrown by [PrescriptionRepositoryImpl] when an operation fails.
class PrescriptionException implements Exception {
  const PrescriptionException(this.message);
  final String message;

  @override
  String toString() => 'PrescriptionException: $message';
}
