import '../enums_model/enums.dart';

/// Connection model matching backend Connection entity.
class Connection {
  final String id;
  final String doctorId;
  final String patientId;
  final ConnectionStatus status;
  final PermissionLevel prescriptionPermission;
  final PermissionLevel healthDataPermission;
  final PermissionLevel personalInfoPermission;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;

  // Populated relationships
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? patient;

  Connection({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.status,
    this.prescriptionPermission = PermissionLevel.notAllowed,
    this.healthDataPermission = PermissionLevel.notAllowed,
    this.personalInfoPermission = PermissionLevel.notAllowed,
    this.acceptedAt,
    this.revokedAt,
    required this.createdAt,
    this.doctor,
    this.patient,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'],
      doctorId: json['doctorId'],
      patientId: json['patientId'],
      status: connectionStatusFromString(json['status'] ?? 'PENDING'),
      prescriptionPermission:
          _permissionFromString(json['prescriptionPermission'] ?? 'NOT_ALLOWED'),
      healthDataPermission:
          _permissionFromString(json['healthDataPermission'] ?? 'NOT_ALLOWED'),
      personalInfoPermission:
          _permissionFromString(json['personalInfoPermission'] ?? 'NOT_ALLOWED'),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'])
          : null,
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      doctor: json['doctor'],
      patient: json['patient'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorId': doctorId,
        'patientId': patientId,
        'status': status.name.toUpperCase(),
      };

  static PermissionLevel _permissionFromString(String v) {
    switch (v) {
      case 'NOT_ALLOWED':
        return PermissionLevel.notAllowed;
      case 'REQUEST':
        return PermissionLevel.request;
      case 'SELECTED':
        return PermissionLevel.selected;
      case 'ALLOWED':
        return PermissionLevel.allowed;
      default:
        return PermissionLevel.notAllowed;
    }
  }
}
