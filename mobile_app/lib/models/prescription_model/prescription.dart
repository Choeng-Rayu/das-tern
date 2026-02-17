class Prescription {
  final String? id;
  final String patientId;
  final String? doctorId;
  final String patientName;
  final String patientGender;
  final int patientAge;
  final String symptoms;
  final String? diagnosis;
  final String? clinicalNote;
  final String? followUpDate;
  final String status;
  final List<PrescriptionMedication> medications;
  final int currentVersion;
  final bool isUrgent;
  final String? urgentReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Prescription({
    this.id,
    required this.patientId,
    this.doctorId,
    required this.patientName,
    required this.patientGender,
    required this.patientAge,
    required this.symptoms,
    this.diagnosis,
    this.clinicalNote,
    this.followUpDate,
    required this.status,
    required this.medications,
    this.currentVersion = 1,
    this.isUrgent = false,
    this.urgentReason,
    this.createdAt,
    this.updatedAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String?,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String?,
      patientName: json['patientName'] as String? ?? '',
      patientGender: json['patientGender'] as String? ?? 'OTHER',
      patientAge: json['patientAge'] as int? ?? 0,
      symptoms: json['symptoms'] as String? ?? '',
      diagnosis: json['diagnosis'] as String?,
      clinicalNote: json['clinicalNote'] as String?,
      followUpDate: json['followUpDate'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      medications: json['medications'] != null
          ? (json['medications'] as List)
              .map((m) => PrescriptionMedication.fromJson(m))
              .toList()
          : [],
      currentVersion: json['currentVersion'] as int? ?? 1,
      isUrgent: json['isUrgent'] as bool? ?? false,
      urgentReason: json['urgentReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converts to JSON for reading/display purposes.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      if (doctorId != null) 'doctorId': doctorId,
      'patientName': patientName,
      'patientGender': patientGender,
      'patientAge': patientAge,
      'symptoms': symptoms,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (clinicalNote != null) 'clinicalNote': clinicalNote,
      if (followUpDate != null) 'followUpDate': followUpDate,
      'medications': medications.map((m) => m.toJson()).toList(),
      'isUrgent': isUrgent,
      if (urgentReason != null) 'urgentReason': urgentReason,
    };
  }
}

class PrescriptionMedication {
  final String? id;
  final String? prescriptionId;
  final int rowNumber;
  final String medicineName;
  final String? medicineNameKhmer;
  final String? medicineType;
  final String? unit;
  final double? dosageAmount;
  final String? description;
  final String? additionalNote;
  final String? imageUrl;
  final String? frequency;
  final int? duration;
  final String? timing;
  final bool isPRN;
  final bool beforeMeal;
  final Map<String, dynamic>? morningDosage;
  final Map<String, dynamic>? daytimeDosage;
  final Map<String, dynamic>? nightDosage;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PrescriptionMedication({
    this.id,
    this.prescriptionId,
    required this.rowNumber,
    required this.medicineName,
    this.medicineNameKhmer,
    this.medicineType,
    this.unit,
    this.dosageAmount,
    this.description,
    this.additionalNote,
    this.imageUrl,
    this.frequency,
    this.duration,
    this.timing,
    this.isPRN = false,
    this.beforeMeal = false,
    this.morningDosage,
    this.daytimeDosage,
    this.nightDosage,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory PrescriptionMedication.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedication(
      id: json['id'] as String?,
      prescriptionId: json['prescriptionId'] as String?,
      rowNumber: json['rowNumber'] as int? ?? 0,
      medicineName: json['medicineName'] as String? ?? '',
      medicineNameKhmer: json['medicineNameKhmer'] as String?,
      medicineType: json['medicineType'] as String?,
      unit: json['unit'] as String?,
      dosageAmount: json['dosageAmount'] != null
          ? (json['dosageAmount'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      additionalNote: json['additionalNote'] as String?,
      imageUrl: json['imageUrl'] as String?,
      frequency: json['frequency'] as String?,
      duration: json['duration'] as int?,
      timing: json['timing'] as String?,
      isPRN: json['isPRN'] as bool? ?? false,
      beforeMeal: json['beforeMeal'] as bool? ?? false,
      morningDosage: json['morningDosage'] != null
          ? Map<String, dynamic>.from(json['morningDosage'] as Map)
          : null,
      daytimeDosage: json['daytimeDosage'] != null
          ? Map<String, dynamic>.from(json['daytimeDosage'] as Map)
          : null,
      nightDosage: json['nightDosage'] != null
          ? Map<String, dynamic>.from(json['nightDosage'] as Map)
          : null,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
      'rowNumber': rowNumber,
      'medicineName': medicineName,
      if (medicineNameKhmer != null) 'medicineNameKhmer': medicineNameKhmer,
      if (medicineType != null) 'medicineType': medicineType,
      if (unit != null) 'unit': unit,
      if (dosageAmount != null) 'dosageAmount': dosageAmount,
      if (description != null) 'description': description,
      if (additionalNote != null) 'additionalNote': additionalNote,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (frequency != null) 'frequency': frequency,
      if (duration != null) 'durationDays': duration,
      'isPRN': isPRN,
      'beforeMeal': beforeMeal,
      if (morningDosage != null) 'morningDosage': morningDosage,
      if (daytimeDosage != null) 'daytimeDosage': daytimeDosage,
      if (nightDosage != null) 'nightDosage': nightDosage,
    };
  }
}
