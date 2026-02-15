import '../enums_model/medication_type.dart';

class HealthVital {
  final String id;
  final String patientId;
  final VitalType vitalType;
  final double value;
  final double? valueSecondary;
  final String unit;
  final DateTime measuredAt;
  final String? notes;
  final bool isAbnormal;
  final String? source;
  final DateTime createdAt;

  HealthVital({
    required this.id,
    required this.patientId,
    required this.vitalType,
    required this.value,
    this.valueSecondary,
    required this.unit,
    required this.measuredAt,
    this.notes,
    this.isAbnormal = false,
    this.source,
    required this.createdAt,
  });

  factory HealthVital.fromJson(Map<String, dynamic> json) {
    return HealthVital(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      vitalType: VitalType.fromJson(json['vitalType'] as String),
      value: (json['value'] as num).toDouble(),
      valueSecondary: json['valueSecondary'] != null
          ? (json['valueSecondary'] as num).toDouble()
          : null,
      unit: json['unit'] as String,
      measuredAt: DateTime.parse(json['measuredAt'] as String),
      notes: json['notes'] as String?,
      isAbnormal: json['isAbnormal'] as bool? ?? false,
      source: json['source'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'vitalType': vitalType.toJson(),
      'value': value,
      if (valueSecondary != null) 'valueSecondary': valueSecondary,
      'unit': unit,
      'measuredAt': measuredAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      'isAbnormal': isAbnormal,
      if (source != null) 'source': source,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayValue {
    if (vitalType == VitalType.bloodPressure && valueSecondary != null) {
      return '${value.toInt()}/${valueSecondary!.toInt()}';
    }
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
