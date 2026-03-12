import 'package:das_tern/data/models/enums.dart';

class Connection {
  const Connection({
    required this.id,
    required this.initiatorId,
    required this.recipientId,
    this.status = ConnectionStatus.pending,
    this.permissionLevel = PermissionLevel.notAllowed,
    this.metadata,
    this.acceptedAt,
    this.revokedAt,
    this.createdAt,
    this.initiatorName,
    this.initiatorRole,
    this.recipientName,
    this.recipientRole,
  });

  final String id;
  final String initiatorId;
  final String recipientId;
  final ConnectionStatus status;
  final PermissionLevel permissionLevel;
  final Map<String, dynamic>? metadata;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final DateTime? createdAt;
  final String? initiatorName;
  final String? initiatorRole;
  final String? recipientName;
  final String? recipientRole;

  bool get isAccepted => status == ConnectionStatus.accepted;
  bool get isPending => status == ConnectionStatus.pending;
  bool get isRevoked => status == ConnectionStatus.revoked;

  String getOtherUserName(String currentUserId) {
    if (currentUserId == initiatorId) return recipientName ?? '';
    return initiatorName ?? '';
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    final initiator = json['initiator'] as Map<String, dynamic>?;
    final recipient = json['recipient'] as Map<String, dynamic>?;

    return Connection(
      id: (json['id'] ?? '').toString(),
      initiatorId: json['initiatorId'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? '',
      status: ConnectionStatus.fromString(
        json['status'] as String? ?? 'PENDING',
      ),
      permissionLevel: PermissionLevel.fromString(
        json['permissionLevel'] as String? ?? 'NOT_ALLOWED',
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      revokedAt: json['revokedAt'] != null
          ? DateTime.tryParse(json['revokedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      initiatorName:
          initiator?['firstName'] as String? ??
          initiator?['fullName'] as String?,
      initiatorRole: initiator?['role'] as String?,
      recipientName:
          recipient?['firstName'] as String? ??
          recipient?['fullName'] as String?,
      recipientRole: recipient?['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'initiatorId': initiatorId,
    'recipientId': recipientId,
    'status': status.toApiString(),
    'permissionLevel': permissionLevel.toApiString(),
    if (metadata != null) 'metadata': metadata,
  };
}

class ConnectionToken {
  const ConnectionToken({
    required this.id,
    required this.patientId,
    required this.token,
    required this.permissionLevel,
    required this.expiresAt,
    this.usedAt,
    this.usedById,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final String token;
  final PermissionLevel permissionLevel;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedById;
  final DateTime? createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedAt != null;
  bool get isValid => !isExpired && !isUsed;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  factory ConnectionToken.fromJson(Map<String, dynamic> json) {
    return ConnectionToken(
      id: (json['id'] ?? '').toString(),
      patientId: json['patientId'] as String? ?? '',
      token: json['token'] as String? ?? '',
      permissionLevel: PermissionLevel.fromString(
        json['permissionLevel'] as String? ?? 'NOT_ALLOWED',
      ),
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now(),
      usedAt: json['usedAt'] != null
          ? DateTime.tryParse(json['usedAt'] as String)
          : null,
      usedById: json['usedById'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'token': token,
    'permissionLevel': permissionLevel.toApiString(),
    'expiresAt': expiresAt.toIso8601String(),
  };
}
