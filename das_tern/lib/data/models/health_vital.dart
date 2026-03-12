import 'package:das_tern/data/models/enums.dart';

class HealthVital {
  const HealthVital({
    required this.id,
    required this.patientId,
    required this.vitalType,
    required this.value,
    required this.unit,
    required this.measuredAt,
    this.valueSecondary,
    this.notes,
    this.isAbnormal = false,
    this.source,
    this.createdAt,
  });

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
  final DateTime? createdAt;

  String get displayValue {
    if (vitalType == VitalType.bloodPressure && valueSecondary != null) {
      return '${value.toInt()}/${valueSecondary!.toInt()}';
    }
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }

  factory HealthVital.fromJson(Map<String, dynamic> json) {
    return HealthVital(
      id: (json['id'] ?? '').toString(),
      patientId: json['patientId'] as String? ?? '',
      vitalType: VitalType.fromString(
        json['vitalType'] as String? ?? 'HEART_RATE',
      ),
      value: (json['value'] ?? 0).toDouble(),
      valueSecondary: json['valueSecondary'] != null
          ? (json['valueSecondary'] as num).toDouble()
          : null,
      unit: json['unit'] as String? ?? '',
      measuredAt:
          DateTime.tryParse(json['measuredAt'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String?,
      isAbnormal: json['isAbnormal'] as bool? ?? false,
      source: json['source'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'vitalType': vitalType.toApiString(),
    'value': value,
    if (valueSecondary != null) 'valueSecondary': valueSecondary,
    'unit': unit,
    'measuredAt': measuredAt.toIso8601String(),
    if (notes != null) 'notes': notes,
    'isAbnormal': isAbnormal,
    if (source != null) 'source': source,
  };
}

class HealthAlert {
  const HealthAlert({
    required this.id,
    required this.patientId,
    required this.alertType,
    required this.severity,
    required this.message,
    this.vitalId,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final String? vitalId;
  final String alertType;
  final AlertSeverity severity;
  final String message;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime? createdAt;

  factory HealthAlert.fromJson(Map<String, dynamic> json) {
    return HealthAlert(
      id: (json['id'] ?? '').toString(),
      patientId: json['patientId'] as String? ?? '',
      vitalId: json['vitalId'] as String?,
      alertType: json['alertType'] as String? ?? '',
      severity: AlertSeverity.fromString(json['severity'] as String? ?? 'LOW'),
      message: json['message'] as String? ?? '',
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
      resolvedBy: json['resolvedBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    if (vitalId != null) 'vitalId': vitalId,
    'alertType': alertType,
    'severity': severity.toApiString(),
    'message': message,
    'isResolved': isResolved,
  };
}

class VitalThreshold {
  const VitalThreshold({
    required this.id,
    required this.patientId,
    required this.vitalType,
    this.minValue,
    this.maxValue,
    this.minSecondary,
    this.maxSecondary,
    this.isCustom = false,
  });

  final String id;
  final String patientId;
  final VitalType vitalType;
  final double? minValue;
  final double? maxValue;
  final double? minSecondary;
  final double? maxSecondary;
  final bool isCustom;

  factory VitalThreshold.fromJson(Map<String, dynamic> json) {
    return VitalThreshold(
      id: (json['id'] ?? '').toString(),
      patientId: json['patientId'] as String? ?? '',
      vitalType: VitalType.fromString(
        json['vitalType'] as String? ?? 'HEART_RATE',
      ),
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      minSecondary: (json['minSecondary'] as num?)?.toDouble(),
      maxSecondary: (json['maxSecondary'] as num?)?.toDouble(),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'vitalType': vitalType.toApiString(),
    if (minValue != null) 'minValue': minValue,
    if (maxValue != null) 'maxValue': maxValue,
    if (minSecondary != null) 'minSecondary': minSecondary,
    if (maxSecondary != null) 'maxSecondary': maxSecondary,
    'isCustom': isCustom,
  };
}
