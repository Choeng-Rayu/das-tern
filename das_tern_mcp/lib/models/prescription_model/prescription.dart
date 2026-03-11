class Prescription {
  final String? id;
  final String patientId;
  final String? doctorId;
  final String patientName;
  final String patientGender;
  final int patientAge;
  final String symptoms;
  final String status;
  final List<PrescriptionMedication> medications;
  final int currentVersion;
  final bool isUrgent;
  final String? urgentReason;
  final String? notes;
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? doctor;
  final String? diagnosis;
  final String? clinicalNote;
  final String? doctorLicenseNumber;
  final DateTime? followUpDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? ocrMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Prescription({
    this.id,
    required this.patientId,
    this.doctorId,
    required this.patientName,
    required this.patientGender,
    required this.patientAge,
    required this.symptoms,
    required this.status,
    required this.medications,
    this.currentVersion = 1,
    this.isUrgent = false,
    this.urgentReason,
    this.notes,
    this.patient,
    this.doctor,
    this.diagnosis,
    this.clinicalNote,
    this.doctorLicenseNumber,
    this.followUpDate,
    this.startDate,
    this.endDate,
    this.ocrMetadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String?,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String?,
      patientName: json['patientName'] as String,
      patientGender: json['patientGender'] as String,
      patientAge: json['patientAge'] as int,
      symptoms: json['symptoms'] as String,
      status: json['status'] as String,
      medications: (json['medications'] as List)
          .map((m) => PrescriptionMedication.fromJson(m))
          .toList(),
      currentVersion: json['currentVersion'] as int? ?? 1,
      isUrgent: json['isUrgent'] as bool? ?? false,
      urgentReason: json['urgentReason'] as String?,
      notes: json['notes'] as String?,
      patient: json['patient'] is Map
          ? Map<String, dynamic>.from(json['patient'])
          : null,
      doctor: json['doctor'] is Map
          ? Map<String, dynamic>.from(json['doctor'])
          : null,
      diagnosis: json['diagnosis'] as String?,
      clinicalNote: json['clinicalNote'] as String?,
      doctorLicenseNumber: json['doctorLicenseNumber'] as String?,
      followUpDate: json['followUpDate'] != null
          ? DateTime.parse(json['followUpDate'] as String)
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      ocrMetadata: json['ocrMetadata'] is Map
          ? Map<String, dynamic>.from(json['ocrMetadata'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      if (doctorId != null) 'doctorId': doctorId,
      'patientName': patientName,
      'patientGender': patientGender,
      'patientAge': patientAge,
      'symptoms': symptoms,
      'status': status,
      'medications': medications.map((m) => m.toJson()).toList(),
      'currentVersion': currentVersion,
      'isUrgent': isUrgent,
      if (urgentReason != null) 'urgentReason': urgentReason,
      if (notes != null) 'notes': notes,
      if (patient != null) 'patient': patient,
      if (doctor != null) 'doctor': doctor,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (clinicalNote != null) 'clinicalNote': clinicalNote,
      if (doctorLicenseNumber != null)
        'doctorLicenseNumber': doctorLicenseNumber,
      if (followUpDate != null) 'followUpDate': followUpDate!.toIso8601String(),
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (ocrMetadata != null) 'ocrMetadata': ocrMetadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PrescriptionMedication {
  final String? id;
  final String? prescriptionId;
  final int rowNumber;
  final String medicineName;
  final String medicineNameKhmer;
  final String? imageUrl;
  final Map<String, dynamic>? morningDosage;
  final Map<String, dynamic>? afternoonDosage;
  final Map<String, dynamic>? eveningDosage;
  final Map<String, dynamic>? nightDosage;
  final String frequency;
  final String timing;
  final Map<String, dynamic>? medicationData;
  final String? medicineType;
  final String? unit;
  final double? dosageAmount;
  final int? duration;
  final String? description;
  final String? additionalNote;
  final bool isPRN;
  final bool beforeMeal;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrescriptionMedication({
    this.id,
    this.prescriptionId,
    required this.rowNumber,
    required this.medicineName,
    required this.medicineNameKhmer,
    this.imageUrl,
    this.morningDosage,
    this.afternoonDosage,
    this.eveningDosage,
    this.nightDosage,
    required this.frequency,
    required this.timing,
    this.medicationData,
    this.medicineType,
    this.unit,
    this.dosageAmount,
    this.duration,
    this.description,
    this.additionalNote,
    this.isPRN = false,
    this.beforeMeal = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrescriptionMedication.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedication(
      id: json['id'] as String?,
      prescriptionId: json['prescriptionId'] as String?,
      rowNumber: json['rowNumber'] as int,
      medicineName: json['medicineName'] as String,
      medicineNameKhmer: (json['medicineNameKhmer'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      morningDosage: json['morningDosage'] is Map
          ? Map<String, dynamic>.from(json['morningDosage'])
          : (json['morningDosage'] is num
                ? {'amount': (json['morningDosage'] as num).toDouble()}
                : null),
      afternoonDosage: json['afternoonDosage'] is Map
          ? Map<String, dynamic>.from(json['afternoonDosage'])
          : (json['afternoonDosage'] is num
                ? {'amount': (json['afternoonDosage'] as num).toDouble()}
                : null),
      eveningDosage: json['eveningDosage'] is Map
          ? Map<String, dynamic>.from(json['eveningDosage'])
          : (json['eveningDosage'] is num
                ? {'amount': (json['eveningDosage'] as num).toDouble()}
                : null),
      nightDosage: json['nightDosage'] is Map
          ? Map<String, dynamic>.from(json['nightDosage'])
          : (json['nightDosage'] is num
              ? {'amount': (json['nightDosage'] as num).toDouble()}
              : null),
      frequency: (json['frequency'] as String?) ?? '',
      timing: (json['timing'] as String?) ?? '',
      medicationData: json['medication'] is Map
          ? Map<String, dynamic>.from(json['medication'])
          : null,
      medicineType: json['medicineType'] as String?,
      unit: json['unit'] as String?,
      dosageAmount: json['dosageAmount'] != null
          ? (json['dosageAmount'] as num).toDouble()
          : null,
      duration: json['duration'] as int?,
      description: json['description'] as String?,
      additionalNote: json['additionalNote'] as String?,
      isPRN: json['isPRN'] as bool? ?? false,
      beforeMeal: json['beforeMeal'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
      'rowNumber': rowNumber,
      'medicineName': medicineName,
      'medicineNameKhmer': medicineNameKhmer,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (morningDosage != null) 'morningDosage': morningDosage,
      if (afternoonDosage != null) 'afternoonDosage': afternoonDosage,
      if (eveningDosage != null) 'eveningDosage': eveningDosage,
      if (nightDosage != null) 'nightDosage': nightDosage,
      'frequency': frequency,
      'timing': timing,
      if (medicineType != null) 'medicineType': medicineType,
      if (unit != null) 'unit': unit,
      if (dosageAmount != null) 'dosageAmount': dosageAmount,
      if (duration != null) 'duration': duration,
      if (description != null) 'description': description,
      if (additionalNote != null) 'additionalNote': additionalNote,
      'isPRN': isPRN,
      'beforeMeal': beforeMeal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
