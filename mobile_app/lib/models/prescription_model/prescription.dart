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
  final double morningDosage;
  final double daytimeDosage;
  final double nightDosage;
  final String frequency;
  final String timing;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrescriptionMedication({
    this.id,
    this.prescriptionId,
    required this.rowNumber,
    required this.medicineName,
    required this.medicineNameKhmer,
    this.imageUrl,
    required this.morningDosage,
    required this.daytimeDosage,
    required this.nightDosage,
    required this.frequency,
    required this.timing,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrescriptionMedication.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedication(
      id: json['id'] as String?,
      prescriptionId: json['prescriptionId'] as String?,
      rowNumber: json['rowNumber'] as int,
      medicineName: json['medicineName'] as String,
      medicineNameKhmer: json['medicineNameKhmer'] as String,
      imageUrl: json['imageUrl'] as String?,
      morningDosage: (json['morningDosage'] as num).toDouble(),
      daytimeDosage: (json['daytimeDosage'] as num).toDouble(),
      nightDosage: (json['nightDosage'] as num).toDouble(),
      frequency: json['frequency'] as String,
      timing: json['timing'] as String,
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
      'morningDosage': morningDosage,
      'daytimeDosage': daytimeDosage,
      'nightDosage': nightDosage,
      'frequency': frequency,
      'timing': timing,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
