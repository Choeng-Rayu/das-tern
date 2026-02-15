import '../enums_model/medication_type.dart';

class VitalThreshold {
  final String id;
  final String patientId;
  final VitalType vitalType;
  final double? minValue;
  final double? maxValue;
  final double? minSecondary;
  final double? maxSecondary;
  final bool isCustom;

  VitalThreshold({
    required this.id,
    required this.patientId,
    required this.vitalType,
    this.minValue,
    this.maxValue,
    this.minSecondary,
    this.maxSecondary,
    this.isCustom = false,
  });

  factory VitalThreshold.fromJson(Map<String, dynamic> json) {
    return VitalThreshold(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      vitalType: VitalType.fromJson(json['vitalType'] as String),
      minValue:
          json['minValue'] != null ? (json['minValue'] as num).toDouble() : null,
      maxValue:
          json['maxValue'] != null ? (json['maxValue'] as num).toDouble() : null,
      minSecondary: json['minSecondary'] != null
          ? (json['minSecondary'] as num).toDouble()
          : null,
      maxSecondary: json['maxSecondary'] != null
          ? (json['maxSecondary'] as num).toDouble()
          : null,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vitalType': vitalType.toJson(),
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (minSecondary != null) 'minSecondary': minSecondary,
      if (maxSecondary != null) 'maxSecondary': maxSecondary,
    };
  }
}
