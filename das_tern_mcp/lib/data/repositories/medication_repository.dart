/// Repository for medication (medicine) data.
///
/// Translates raw JSON from [MedicationService] into clean
/// [Medication] domain models.
library;

import '../models/medication.dart';
import '../services/medication_service.dart';

/// Abstract contract enabling easy test doubles.
abstract class MedicationRepository {
  /// Returns all medications belonging to [prescriptionId].
  Future<List<Medication>> getMedications(String prescriptionId);

  /// Adds a new medication to [prescriptionId] and returns the created model.
  Future<Medication> addMedication(
    String prescriptionId,
    Map<String, dynamic> data,
  );

  /// Updates the medication identified by [id] and returns the updated model.
  Future<Medication> updateMedication(String id, Map<String, dynamic> data);

  /// Permanently removes the medication identified by [id].
  Future<void> deleteMedication(String id);
}

// ── Implementation ────────────────────────────────────────────────────────────

/// Concrete implementation backed by [MedicationService].
class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl({MedicationService? service})
      : _service = service ?? MedicationService();

  final MedicationService _service;

  @override
  Future<List<Medication>> getMedications(String prescriptionId) async {
    try {
      final json = await _service.getMedications(prescriptionId);
      // The API returns the prescription wrapper; medications are nested.
      final rawMeds = json['medications'];
      if (rawMeds is List) {
        return rawMeds
            .whereType<Map<String, dynamic>>()
            .map(Medication.fromJson)
            .toList();
      }
      return [];
    } catch (e) {
      throw MedicationException(
        'Failed to fetch medications for prescription $prescriptionId: $e',
      );
    }
  }

  @override
  Future<Medication> addMedication(
    String prescriptionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final json = await _service.addMedication(prescriptionId, data);
      return Medication.fromJson(json);
    } catch (e) {
      throw MedicationException('Failed to add medication: $e');
    }
  }

  @override
  Future<Medication> updateMedication(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final json = await _service.updateMedication(id, data);
      return Medication.fromJson(json);
    } catch (e) {
      throw MedicationException('Failed to update medication $id: $e');
    }
  }

  @override
  Future<void> deleteMedication(String id) async {
    try {
      await _service.deleteMedication(id);
    } catch (e) {
      throw MedicationException('Failed to delete medication $id: $e');
    }
  }
}

// ── Exception ─────────────────────────────────────────────────────────────────

/// Thrown by [MedicationRepositoryImpl] when an operation fails.
class MedicationException implements Exception {
  const MedicationException(this.message);
  final String message;

  @override
  String toString() => 'MedicationException: $message';
}
