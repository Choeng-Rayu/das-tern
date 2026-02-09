enum ConnectionStatus { pending, accepted, rejected, revoked }

enum PermissionLevel { notAllowed, request, selected, allowed }

class ConnectionRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final ConnectionStatus status;
  final PermissionLevel? permissionLevel;
  final DateTime createdAt;
  final DateTime? respondedAt;

  ConnectionRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    this.permissionLevel,
    required this.createdAt,
    this.respondedAt,
  });

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) => ConnectionRequest(
        id: json['id'],
        fromUserId: json['fromUserId'],
        toUserId: json['toUserId'],
        status: ConnectionStatus.values.firstWhere((e) => e.name == json['status']),
        permissionLevel: json['permissionLevel'] != null
            ? PermissionLevel.values.firstWhere((e) => e.name == json['permissionLevel'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': status.name,
        'permissionLevel': permissionLevel?.name,
        'createdAt': createdAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
      };
}
