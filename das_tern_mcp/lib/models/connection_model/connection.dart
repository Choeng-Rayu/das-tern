import '../enums_model/enums.dart';

/// Connection model matching backend Connection entity.
class Connection {
  final String id;
  final String initiatorId;
  final String recipientId;
  final ConnectionStatus status;
  final PermissionLevel permissionLevel;
  final Map<String, dynamic>? metadata;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;

  // Populated relationships
  final Map<String, dynamic>? initiator;
  final Map<String, dynamic>? recipient;

  // Legacy aliases
  String get doctorId => initiatorId;
  String get patientId => recipientId;
  Map<String, dynamic>? get doctor => initiator;
  Map<String, dynamic>? get patient => recipient;

  bool get alertsEnabled {
    if (metadata == null) return true;
    return metadata!['alertsEnabled'] ?? true;
  }

  Connection({
    required this.id,
    required this.initiatorId,
    required this.recipientId,
    required this.status,
    this.permissionLevel = PermissionLevel.notAllowed,
    this.metadata,
    this.acceptedAt,
    this.revokedAt,
    required this.createdAt,
    this.initiator,
    this.recipient,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'],
      initiatorId: json['initiatorId'] ?? json['doctorId'] ?? '',
      recipientId: json['recipientId'] ?? json['patientId'] ?? '',
      status: connectionStatusFromString(json['status'] ?? 'PENDING'),
      permissionLevel:
          _permissionFromString(json['permissionLevel'] ?? 'NOT_ALLOWED'),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'])
          : null,
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      initiator: json['initiator'] ?? json['doctor'],
      recipient: json['recipient'] ?? json['patient'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'initiatorId': initiatorId,
        'recipientId': recipientId,
        'status': status.name.toUpperCase(),
        'permissionLevel': permissionLevel.name.toUpperCase(),
      };

  /// Get the other user's name from the connection (relative to userId).
  String getOtherUserName(String userId) {
    final other = initiatorId == userId ? recipient : initiator;
    if (other == null) return 'Unknown';
    return other['fullName'] ?? 
           '${other['firstName'] ?? ''} ${other['lastName'] ?? ''}'.trim();
  }

  /// Get the other user's role from the connection.
  String? getOtherUserRole(String userId) {
    final other = initiatorId == userId ? recipient : initiator;
    return other?['role'];
  }

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

  static String permissionLevelToDisplay(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.notAllowed:
        return 'Not Allowed';
      case PermissionLevel.request:
        return 'View Only';
      case PermissionLevel.selected:
        return 'View + Remind';
      case PermissionLevel.allowed:
        return 'View + Manage';
    }
  }
}
