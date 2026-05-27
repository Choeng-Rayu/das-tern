import 'dart:convert';

import 'prescription_enums.dart';

/// A single time-slot dosage amount.
class DosageSlot {
  const DosageSlot({required this.amount, required this.unit, this.note});

  final double amount;
  final MedicineUnit unit;
  final String? note;

  factory DosageSlot.fromJson(Map<String, dynamic> j) => DosageSlot(
        amount: (j['amount'] as num).toDouble(),
        unit: MedicineUnitX.fromCode(j['unit'] as String?),
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'amount': amount,
        'unit': unit.code,
        if (note != null) 'note': note,
      };

  static DosageSlot? fromJsonString(String? s) {
    if (s == null) return null;
    return DosageSlot.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Immutable medication domain entity.
class Medication {
  const Medication({
    required this.id,
    required this.prescriptionId,
    required this.rowNumber,
    this.batchId,
    required this.medicineName,
    this.medicineNameKhmer,
    this.imageUrl,
    required this.medicineType,
    required this.unit,
    required this.dosageAmount,
    this.description,
    this.additionalNote,
    this.createdBy,
    this.morningDosage,
    this.afternoonDosage,
    this.eveningDosage,
    this.nightDosage,
    this.frequency,
    this.duration,
    this.timing,
    required this.isPrn,
    required this.beforeMeal,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String prescriptionId;
  final int rowNumber;
  final String? batchId;
  final String medicineName;
  final String? medicineNameKhmer;
  final String? imageUrl;
  final MedicineType medicineType;
  final MedicineUnit unit;
  final double dosageAmount;
  final String? description;
  final String? additionalNote;
  final String? createdBy;
  final DosageSlot? morningDosage;
  final DosageSlot? afternoonDosage;
  final DosageSlot? eveningDosage;
  final DosageSlot? nightDosage;
  final String? frequency;
  final int? duration;
  final String? timing;
  final bool isPrn;
  final bool beforeMeal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication copyWith({
    String? medicineName,
    String? medicineNameKhmer,
    MedicineType? medicineType,
    MedicineUnit? unit,
    double? dosageAmount,
    DosageSlot? morningDosage,
    DosageSlot? afternoonDosage,
    DosageSlot? eveningDosage,
    DosageSlot? nightDosage,
    String? frequency,
    int? duration,
    bool? isPrn,
    bool? beforeMeal,
    DateTime? updatedAt,
  }) =>
      Medication(
        id: id,
        prescriptionId: prescriptionId,
        rowNumber: rowNumber,
        batchId: batchId,
        medicineName: medicineName ?? this.medicineName,
        medicineNameKhmer: medicineNameKhmer ?? this.medicineNameKhmer,
        imageUrl: imageUrl,
        medicineType: medicineType ?? this.medicineType,
        unit: unit ?? this.unit,
        dosageAmount: dosageAmount ?? this.dosageAmount,
        description: description,
        additionalNote: additionalNote,
        createdBy: createdBy,
        morningDosage: morningDosage ?? this.morningDosage,
        afternoonDosage: afternoonDosage ?? this.afternoonDosage,
        eveningDosage: eveningDosage ?? this.eveningDosage,
        nightDosage: nightDosage ?? this.nightDosage,
        frequency: frequency ?? this.frequency,
        duration: duration ?? this.duration,
        timing: timing,
        isPrn: isPrn ?? this.isPrn,
        beforeMeal: beforeMeal ?? this.beforeMeal,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Medication.fromMap(Map<String, dynamic> m) => Medication(
        id: m['id'] as String,
        prescriptionId: m['prescription_id'] as String,
        rowNumber: m['row_number'] as int,
        batchId: m['batch_id'] as String?,
        medicineName: m['medicine_name'] as String,
        medicineNameKhmer: m['medicine_name_khmer'] as String?,
        imageUrl: m['image_url'] as String?,
        medicineType: MedicineTypeX.fromCode(m['medicine_type'] as String?),
        unit: MedicineUnitX.fromCode(m['unit'] as String?),
        dosageAmount: (m['dosage_amount'] as num?)?.toDouble() ?? 1.0,
        description: m['description'] as String?,
        additionalNote: m['additional_note'] as String?,
        createdBy: m['created_by'] as String?,
        morningDosage: DosageSlot.fromJsonString(m['morning_dosage'] as String?),
        afternoonDosage: DosageSlot.fromJsonString(m['afternoon_dosage'] as String?),
        eveningDosage: DosageSlot.fromJsonString(m['evening_dosage'] as String?),
        nightDosage: DosageSlot.fromJsonString(m['night_dosage'] as String?),
        frequency: m['frequency'] as String?,
        duration: m['duration'] as int?,
        timing: m['timing'] as String?,
        isPrn: m['is_prn'] as bool? ?? false,
        beforeMeal: m['before_meal'] as bool? ?? false,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'prescription_id': prescriptionId,
        'row_number': rowNumber,
        'medicine_name': medicineName,
        if (medicineNameKhmer != null) 'medicine_name_khmer': medicineNameKhmer,
        'medicine_type': medicineType.code,
        'unit': unit.code,
        'dosage_amount': dosageAmount,
        if (description != null) 'description': description,
        if (morningDosage != null) 'morning_dosage': morningDosage!.toJsonString(),
        if (afternoonDosage != null) 'afternoon_dosage': afternoonDosage!.toJsonString(),
        if (eveningDosage != null) 'evening_dosage': eveningDosage!.toJsonString(),
        if (nightDosage != null) 'night_dosage': nightDosage!.toJsonString(),
        if (frequency != null) 'frequency': frequency,
        if (duration != null) 'duration': duration,
        'is_prn': isPrn,
        'before_meal': beforeMeal,
      };
}
