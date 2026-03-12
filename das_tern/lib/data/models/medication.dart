import 'package:das_tern/data/models/enums.dart';

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.frequency,
    this.nameKhmer,
    this.imageUrl,
    this.medicineType = MedicineType.oral,
    this.medicineUnit = MedicineUnit.tablet,
    this.description,
    this.additionalNote,
    this.isPRN = false,
    this.beforeMeal = false,
    this.duration,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? nameKhmer;
  final double dosage;
  final String unit;
  final String frequency;
  final String? imageUrl;
  final MedicineType medicineType;
  final MedicineUnit medicineUnit;
  final String? description;
  final String? additionalNote;
  final bool isPRN;
  final bool beforeMeal;
  final int? duration;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: (json['id'] ?? '').toString(),
      name: json['medicineName'] as String? ?? json['name'] as String? ?? '',
      nameKhmer: json['medicineNameKhmer'] as String?,
      dosage: (json['dosageAmount'] ?? json['dosage'] ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'mg',
      frequency: json['frequency'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      medicineType: MedicineType.fromString(
        json['medicineType'] as String? ?? 'ORAL',
      ),
      medicineUnit: MedicineUnit.fromString(
        json['unit'] as String? ?? 'TABLET',
      ),
      description: json['description'] as String?,
      additionalNote: json['additionalNote'] as String?,
      isPRN: json['isPRN'] as bool? ?? false,
      beforeMeal: json['beforeMeal'] as bool? ?? false,
      duration: json['duration'] as int? ?? json['durationDays'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineName': name,
    if (nameKhmer != null) 'medicineNameKhmer': nameKhmer,
    'dosageAmount': dosage,
    'unit': unit,
    'frequency': frequency,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'medicineType': medicineType.toApiString(),
    if (description != null) 'description': description,
    if (additionalNote != null) 'additionalNote': additionalNote,
    'isPRN': isPRN,
    'beforeMeal': beforeMeal,
    if (duration != null) 'durationDays': duration,
    'isActive': isActive,
  };

  Medication copyWith({
    String? id,
    String? name,
    String? nameKhmer,
    double? dosage,
    String? unit,
    String? frequency,
    String? imageUrl,
    MedicineType? medicineType,
    MedicineUnit? medicineUnit,
    String? description,
    String? additionalNote,
    bool? isPRN,
    bool? beforeMeal,
    int? duration,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      imageUrl: imageUrl ?? this.imageUrl,
      medicineType: medicineType ?? this.medicineType,
      medicineUnit: medicineUnit ?? this.medicineUnit,
      description: description ?? this.description,
      additionalNote: additionalNote ?? this.additionalNote,
      isPRN: isPRN ?? this.isPRN,
      beforeMeal: beforeMeal ?? this.beforeMeal,
      duration: duration ?? this.duration,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
