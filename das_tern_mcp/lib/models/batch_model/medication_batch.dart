class BatchMedication {
  final String? id;
  final String? prescriptionId;
  final String medicineName;
  final String? medicineNameKhmer;
  final String? medicineType;
  final String? unit;
  final double? dosageAmount;
  final String? frequency;
  final int? durationDays;
  final String? description;
  final String? additionalNote;
  final bool beforeMeal;
  final bool isPRN;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BatchMedication({
    this.id,
    this.prescriptionId,
    required this.medicineName,
    this.medicineNameKhmer,
    this.medicineType,
    this.unit,
    this.dosageAmount,
    this.frequency,
    this.durationDays,
    this.description,
    this.additionalNote,
    this.beforeMeal = false,
    this.isPRN = false,
    this.createdAt,
    this.updatedAt,
  });

  factory BatchMedication.fromJson(Map<String, dynamic> json) {
    return BatchMedication(
      id: json['id'] as String?,
      prescriptionId: json['prescriptionId'] as String?,
      medicineName: json['medicineName'] as String? ?? '',
      medicineNameKhmer: json['medicineNameKhmer'] as String?,
      medicineType: json['medicineType'] as String?,
      unit: json['unit'] as String?,
      dosageAmount: json['dosageAmount'] != null
          ? (json['dosageAmount'] as num).toDouble()
          : null,
      frequency: json['frequency'] as String?,
      durationDays: json['duration'] as int? ?? json['durationDays'] as int?,
      description: json['description'] as String?,
      additionalNote: json['additionalNote'] as String?,
      beforeMeal: json['beforeMeal'] as bool? ?? false,
      isPRN: json['isPRN'] as bool? ?? false,
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
      'medicineName': medicineName,
      if (medicineNameKhmer != null) 'medicineNameKhmer': medicineNameKhmer,
      if (medicineType != null) 'medicineType': medicineType,
      if (unit != null) 'unit': unit,
      if (dosageAmount != null) 'dosageAmount': dosageAmount,
      if (frequency != null) 'frequency': frequency,
      if (durationDays != null) 'durationDays': durationDays,
      if (description != null) 'description': description,
      if (additionalNote != null) 'additionalNote': additionalNote,
      'beforeMeal': beforeMeal,
      'isPRN': isPRN,
    };
  }
}

class MedicationBatch {
  final String? id;
  final String? patientId;
  final String name;
  final String scheduledTime;
  final bool isActive;
  final List<BatchMedication> medications;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicationBatch({
    this.id,
    this.patientId,
    required this.name,
    required this.scheduledTime,
    this.isActive = true,
    this.medications = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory MedicationBatch.fromJson(Map<String, dynamic> json) {
    return MedicationBatch(
      id: json['id'] as String?,
      patientId: json['patientId'] as String?,
      name: json['name'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      medications: json['medications'] != null
          ? (json['medications'] as List)
              .map((m) => BatchMedication.fromJson(
                  Map<String, dynamic>.from(m as Map)))
              .toList()
          : [],
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
      'name': name,
      'scheduledTime': scheduledTime,
      'isActive': isActive,
      'medicines': medications.map((m) => m.toJson()).toList(),
    };
  }
}
