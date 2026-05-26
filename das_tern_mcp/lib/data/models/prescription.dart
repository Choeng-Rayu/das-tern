/// Clean MVVM-compliant Prescription domain model.
/// No Flutter dependencies — pure Dart only.
library;

import 'medication.dart';

// ── Status enum ───────────────────────────────────────────────────────────────

/// Lifecycle status of a prescription.
enum PrescriptionStatus { draft, active, paused, inactive }

PrescriptionStatus _statusFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'ACTIVE':
      return PrescriptionStatus.active;
    case 'PAUSED':
      return PrescriptionStatus.paused;
    case 'INACTIVE':
      return PrescriptionStatus.inactive;
    default:
      return PrescriptionStatus.draft;
  }
}

String _statusToString(PrescriptionStatus status) {
  switch (status) {
    case PrescriptionStatus.draft:
      return 'DRAFT';
    case PrescriptionStatus.active:
      return 'ACTIVE';
    case PrescriptionStatus.paused:
      return 'PAUSED';
    case PrescriptionStatus.inactive:
      return 'INACTIVE';
  }
}

// ── Domain model ─────────────────────────────────────────────────────────────

/// Immutable domain model for a prescription record.
class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.title,
    this.startDate,
    this.endDate,
    required this.status,
    required this.medications,
  });

  final String id;
  final String patientId;
  final String? doctorId;

  /// Human-readable title or chief complaint / diagnosis label.
  final String title;

  final DateTime? startDate;
  final DateTime? endDate;
  final PrescriptionStatus status;

  /// Medications included in this prescription.
  final List<Medication> medications;

  // ── Factory / serialisation ───────────────────────────────────────────────

  factory Prescription.fromJson(Map<String, dynamic> json) {
    // Parse medication list — may arrive as nested objects.
    List<Medication> meds = [];
    final rawMeds = json['medications'];
    if (rawMeds is List) {
      meds = rawMeds
          .whereType<Map<String, dynamic>>()
          .map(Medication.fromJson)
          .toList();
    }

    // Title falls back to symptoms or a generic label.
    final title = (json['title'] ??
            json['diagnosis'] ??
            json['symptoms'] ??
            'Prescription') as String;

    return Prescription(
      id: (json['id'] ?? '').toString(),
      patientId: (json['patientId'] ?? json['patient_id'] ?? '') as String,
      doctorId: (json['doctorId'] ?? json['doctor_id']) as String?,
      title: title,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      status: _statusFromString(json['status'] as String?),
      medications: meds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    if (doctorId != null) 'doctorId': doctorId,
    'title': title,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    'status': _statusToString(status),
    'medications': medications.map((m) => m.toJson()).toList(),
  };

  Prescription copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    PrescriptionStatus? status,
    List<Medication>? medications,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      medications: medications ?? this.medications,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Prescription && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Prescription(id: $id, status: $status, meds: ${medications.length})';
}
