import '../enums_model/medication_type.dart';

class HealthAlert {
  final String id;
  final String patientId;
  final String? vitalId;
  final String alertType;
  final AlertSeverity severity;
  final String message;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime createdAt;

  HealthAlert({
    required this.id,
    required this.patientId,
    this.vitalId,
    required this.alertType,
    required this.severity,
    required this.message,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
  });

  factory HealthAlert.fromJson(Map<String, dynamic> json) {
    return HealthAlert(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      vitalId: json['vitalId'] as String?,
      alertType: json['alertType'] as String,
      severity: AlertSeverity.fromJson(json['severity'] as String),
      message: json['message'] as String,
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolvedBy: json['resolvedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      if (vitalId != null) 'vitalId': vitalId,
      'alertType': alertType,
      'severity': severity.toJson(),
      'message': message,
      'isResolved': isResolved,
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
