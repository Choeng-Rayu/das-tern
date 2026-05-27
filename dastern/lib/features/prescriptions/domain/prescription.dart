import 'prescription_enums.dart';

/// Immutable prescription domain entity.
/// Spec ref: 03-prescription-medication design §2.
class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.patientName,
    required this.patientGender,
    required this.patientAge,
    required this.symptoms,
    this.diagnosis,
    this.clinicalNote,
    this.followUpDate,
    this.startDate,
    this.endDate,
    required this.status,
    required this.currentVersion,
    required this.isUrgent,
    this.urgentReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final String? doctorId;
  final String patientName;
  final Gender patientGender;
  final int patientAge;
  final String symptoms;
  final String? diagnosis;
  final String? clinicalNote;
  final DateTime? followUpDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final PrescriptionStatus status;
  final int currentVersion;
  final bool isUrgent;
  final String? urgentReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Prescription copyWith({
    PrescriptionStatus? status,
    bool? isUrgent,
    String? urgentReason,
    int? currentVersion,
    DateTime? updatedAt,
  }) =>
      Prescription(
        id: id,
        patientId: patientId,
        doctorId: doctorId,
        patientName: patientName,
        patientGender: patientGender,
        patientAge: patientAge,
        symptoms: symptoms,
        diagnosis: diagnosis,
        clinicalNote: clinicalNote,
        followUpDate: followUpDate,
        startDate: startDate,
        endDate: endDate,
        status: status ?? this.status,
        currentVersion: currentVersion ?? this.currentVersion,
        isUrgent: isUrgent ?? this.isUrgent,
        urgentReason: urgentReason ?? this.urgentReason,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Prescription.fromMap(Map<String, dynamic> m) => Prescription(
        id: m['id'] as String,
        patientId: m['patient_id'] as String,
        doctorId: m['doctor_id'] as String?,
        patientName: m['patient_name'] as String,
        patientGender: GenderX.fromCode(m['patient_gender'] as String?),
        patientAge: m['patient_age'] as int,
        symptoms: m['symptoms'] as String? ?? '',
        diagnosis: m['diagnosis'] as String?,
        clinicalNote: m['clinical_note'] as String?,
        status: PrescriptionStatusX.fromCode(m['status'] as String?),
        currentVersion: m['current_version'] as int? ?? 1,
        isUrgent: m['is_urgent'] as bool? ?? false,
        urgentReason: m['urgent_reason'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'patient_id': patientId,
        if (doctorId != null) 'doctor_id': doctorId,
        'patient_name': patientName,
        'patient_gender': patientGender.code,
        'patient_age': patientAge,
        'symptoms': symptoms,
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (clinicalNote != null) 'clinical_note': clinicalNote,
        'status': status.code,
        'current_version': currentVersion,
        'is_urgent': isUrgent,
        if (urgentReason != null) 'urgent_reason': urgentReason,
      };
}
