import 'adherence_result.dart';
import 'doctor_note.dart';

/// Full patient details returned by GET /doctor/patients/:id/details.
class PatientDetails {
  final PatientInfo patient;
  final AdherenceResult adherence;
  final List<AdherenceTimelinePoint> adherenceTimeline;
  final List<PatientPrescription> prescriptions;
  final List<DoctorNote> notes;
  final String connectionId;

  PatientDetails({
    required this.patient,
    required this.adherence,
    required this.adherenceTimeline,
    required this.prescriptions,
    required this.notes,
    required this.connectionId,
  });

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    return PatientDetails(
      patient: PatientInfo.fromJson(
          Map<String, dynamic>.from(json['patient'] ?? {})),
      adherence: AdherenceResult.fromJson(
          Map<String, dynamic>.from(json['adherence'] ?? {})),
      adherenceTimeline: (json['adherenceTimeline'] as List<dynamic>?)
              ?.map((e) => AdherenceTimelinePoint.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      prescriptions: (json['prescriptions'] as List<dynamic>?)
              ?.map((e) => PatientPrescription.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      notes: (json['notes'] as List<dynamic>?)
              ?.map(
                  (e) => DoctorNote.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      connectionId: json['connectionId'] ?? '',
    );
  }
}

/// Basic patient info within patient details.
class PatientInfo {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String? gender;
  final int? age;
  final String? dateOfBirth;

  PatientInfo({
    required this.id,
    this.firstName,
    this.lastName,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.gender,
    this.age,
    this.dateOfBirth,
  });

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final parts = [firstName ?? '', lastName ?? ''];
    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['id'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      gender: json['gender'],
      age: json['age'],
      dateOfBirth: json['dateOfBirth'],
    );
  }
}

/// Prescription data embedded in patient details.
class PatientPrescription {
  final String id;
  final String patientId;
  final String? doctorId;
  final String? symptoms;
  final String status;
  final int currentVersion;
  final List<PrescriptionMedication> medications;
  final String? createdAt;

  PatientPrescription({
    required this.id,
    required this.patientId,
    this.doctorId,
    this.symptoms,
    required this.status,
    this.currentVersion = 1,
    this.medications = const [],
    this.createdAt,
  });

  bool get isActive => status == 'ACTIVE';

  factory PatientPrescription.fromJson(Map<String, dynamic> json) {
    return PatientPrescription(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'],
      symptoms: json['symptoms'],
      status: json['status'] ?? 'DRAFT',
      currentVersion: json['currentVersion'] ?? 1,
      medications: (json['medications'] as List<dynamic>?)
              ?.map((e) => PrescriptionMedication.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      createdAt: json['createdAt'],
    );
  }
}

/// Medication within a prescription.
class PrescriptionMedication {
  final String id;
  final String medicineName;
  final String? medicineNameKhmer;
  final String? imageUrl;
  final Map<String, dynamic>? morningDosage;
  final Map<String, dynamic>? daytimeDosage;
  final Map<String, dynamic>? nightDosage;
  final String? frequency;
  final String? timing;

  PrescriptionMedication({
    required this.id,
    required this.medicineName,
    this.medicineNameKhmer,
    this.imageUrl,
    this.morningDosage,
    this.daytimeDosage,
    this.nightDosage,
    this.frequency,
    this.timing,
  });

  factory PrescriptionMedication.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedication(
      id: json['id'] ?? '',
      medicineName: json['medicineName'] ?? '',
      medicineNameKhmer: json['medicineNameKhmer'],
      imageUrl: json['imageUrl'],
      morningDosage: json['morningDosage'] != null
          ? Map<String, dynamic>.from(json['morningDosage'])
          : null,
      daytimeDosage: json['daytimeDosage'] != null
          ? Map<String, dynamic>.from(json['daytimeDosage'])
          : null,
      nightDosage: json['nightDosage'] != null
          ? Map<String, dynamic>.from(json['nightDosage'])
          : null,
      frequency: json['frequency'],
      timing: json['timing'],
    );
  }
}
