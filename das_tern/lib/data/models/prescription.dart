import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/models/medication.dart';

class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.medications,
    required this.issuedAt,
    this.doctorId,
    this.doctorName = '',
    this.patientName = '',
    this.patientGender,
    this.patientAge,
    this.symptoms = '',
    this.status = PrescriptionStatus.active,
    this.isUrgent = false,
    this.urgentReason,
    this.notes,
    this.diagnosis,
    this.clinicalNote,
    this.startDate,
    this.endDate,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String? doctorId;
  final String doctorName;
  final String patientName;
  final Gender? patientGender;
  final int? patientAge;
  final String symptoms;
  final PrescriptionStatus status;
  final List<Medication> medications;
  final bool isUrgent;
  final String? urgentReason;
  final String? notes;
  final String? diagnosis;
  final String? clinicalNote;
  final DateTime issuedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? updatedAt;

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final List<dynamic> meds =
        (json['medications'] as List<dynamic>?) ?? <dynamic>[];

    return Prescription(
      id: (json['id'] ?? '').toString(),
      patientId: json['patientId'] as String? ?? '',
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      patientGender: json['patientGender'] != null
          ? Gender.fromString(json['patientGender'] as String)
          : null,
      patientAge: json['patientAge'] as int?,
      symptoms: json['symptoms'] as String? ?? '',
      status: PrescriptionStatus.fromString(
        json['status'] as String? ?? 'ACTIVE',
      ),
      medications: meds
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList(),
      isUrgent: json['isUrgent'] as bool? ?? false,
      urgentReason: json['urgentReason'] as String?,
      notes: json['notes'] as String?,
      diagnosis: json['diagnosis'] as String?,
      clinicalNote: json['clinicalNote'] as String?,
      issuedAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    if (doctorId != null) 'doctorId': doctorId,
    'doctorName': doctorName,
    'patientName': patientName,
    if (patientGender != null) 'patientGender': patientGender!.toApiString(),
    if (patientAge != null) 'patientAge': patientAge,
    'symptoms': symptoms,
    'status': status.toApiString(),
    'medications': medications.map((m) => m.toJson()).toList(),
    'isUrgent': isUrgent,
    if (urgentReason != null) 'urgentReason': urgentReason,
    if (notes != null) 'notes': notes,
    if (diagnosis != null) 'diagnosis': diagnosis,
    if (clinicalNote != null) 'clinicalNote': clinicalNote,
    'createdAt': issuedAt.toIso8601String(),
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
  };

  Prescription copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? doctorName,
    String? patientName,
    Gender? patientGender,
    int? patientAge,
    String? symptoms,
    PrescriptionStatus? status,
    List<Medication>? medications,
    bool? isUrgent,
    String? urgentReason,
    String? notes,
    String? diagnosis,
    String? clinicalNote,
    DateTime? issuedAt,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      patientGender: patientGender ?? this.patientGender,
      patientAge: patientAge ?? this.patientAge,
      symptoms: symptoms ?? this.symptoms,
      status: status ?? this.status,
      medications: medications ?? this.medications,
      isUrgent: isUrgent ?? this.isUrgent,
      urgentReason: urgentReason ?? this.urgentReason,
      notes: notes ?? this.notes,
      diagnosis: diagnosis ?? this.diagnosis,
      clinicalNote: clinicalNote ?? this.clinicalNote,
      issuedAt: issuedAt ?? this.issuedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
