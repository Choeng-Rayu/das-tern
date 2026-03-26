import 'dose_event_model/dose_event.dart';
import 'prescription_model/prescription.dart';
import 'health_model/health_vital.dart';

/// Aggregates all data needed for the patient health report PDF.
/// This model serves as a single source of truth for PDF generation,
/// combining patient profile, doctor info, medications, dose history, and vitals.
class PatientReportData {
  /// Patient profile information
  final PatientProfile patient;

  /// Assigned doctor information (may be null if no doctor assigned)
  final DoctorInfo? doctor;

  /// Active prescriptions with medication details
  final List<Prescription> medications;

  /// Dose activity history (last 30 days)
  final List<DoseEvent> doseHistory;

  /// Health vitals (blood pressure, glucose, etc.)
  final List<HealthVital> vitals;

  /// Adherence metrics for summary cards
  final AdherenceMetrics? adherence;

  /// Timestamp when this report was generated
  final DateTime generatedAt;

  PatientReportData({
    required this.patient,
    this.doctor,
    required this.medications,
    required this.doseHistory,
    required this.vitals,
    this.adherence,
    required this.generatedAt,
  });

  /// Creates a PatientReportData from provider data
  factory PatientReportData.fromProviders({
    required Map<String, dynamic>? userMap,
    Map<String, dynamic>? doctorMap,
    required List<Prescription> prescriptions,
    required List<DoseEvent> doses,
    required List<HealthVital> healthVitals,
    Map<String, dynamic>? adherenceData,
  }) {
    return PatientReportData(
      patient: PatientProfile.fromUserMap(userMap),
      doctor: doctorMap != null ? DoctorInfo.fromMap(doctorMap) : null,
      medications: prescriptions,
      doseHistory: doses,
      vitals: healthVitals,
      adherence: adherenceData != null
          ? AdherenceMetrics.fromMap(adherenceData)
          : null,
      generatedAt: DateTime.now(),
    );
  }
}

/// Patient profile information for the report header
class PatientProfile {
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? userId;

  PatientProfile({
    this.firstName,
    this.lastName,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.userId,
  });

  String get fullName {
    final name = [firstName, lastName].where((s) => s != null).join(' ').trim();
    return name.isEmpty ? 'Patient' : name;
  }

  int? get age {
    if (dateOfBirth == null) return null;
    return DateTime.now().difference(dateOfBirth!).inDays ~/ 365;
  }

  factory PatientProfile.fromUserMap(Map<String, dynamic>? map) {
    if (map == null) {
      return PatientProfile();
    }

    return PatientProfile(
      firstName: map['firstName'] as String?,
      lastName: map['lastName'] as String?,
      email: map['email'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'] as String)
          : null,
      gender: map['gender'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      userId: map['id'] as String?,
    );
  }
}

/// Doctor information for the assigned physician section
class DoctorInfo {
  final String fullName;
  final String? specialty;
  final String? hospitalClinic;
  final String? email;
  final String? phoneNumber;
  final String? licenseNumber;

  DoctorInfo({
    required this.fullName,
    this.specialty,
    this.hospitalClinic,
    this.email,
    this.phoneNumber,
    this.licenseNumber,
  });

  factory DoctorInfo.fromMap(Map<String, dynamic> map) {
    return DoctorInfo(
      fullName: map['fullName'] as String? ?? 'Doctor',
      specialty: map['specialty'] as String?,
      hospitalClinic: map['hospitalClinic'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
    );
  }
}

/// Adherence metrics for summary section
class AdherenceMetrics {
  final double? weeklyPercentage;
  final double? monthlyPercentage;
  final int? todayTaken;
  final int? todayTotal;
  final List<dynamic>? weeklyDays;

  AdherenceMetrics({
    this.weeklyPercentage,
    this.monthlyPercentage,
    this.todayTaken,
    this.todayTotal,
    this.weeklyDays,
  });

  factory AdherenceMetrics.fromMap(Map<String, dynamic> map) {
    return AdherenceMetrics(
      weeklyPercentage: (map['weeklyPercentage'] as num?)?.toDouble(),
      monthlyPercentage: (map['monthlyPercentage'] as num?)?.toDouble(),
      todayTaken: map['todayTaken'] as int?,
      todayTotal: map['todayTotal'] as int?,
      weeklyDays: map['weeklyDays'] as List<dynamic>?,
    );
  }
}
