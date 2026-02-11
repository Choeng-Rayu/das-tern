/// Model for a connection token used for QR-based family onboarding.
class ConnectionToken {
  final String id;
  final String patientId;
  final String token;
  final String permissionLevel;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedById;
  final DateTime createdAt;

  ConnectionToken({
    required this.id,
    required this.patientId,
    required this.token,
    required this.permissionLevel,
    required this.expiresAt,
    this.usedAt,
    this.usedById,
    required this.createdAt,
  });

  factory ConnectionToken.fromJson(Map<String, dynamic> json) {
    return ConnectionToken(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      token: json['token'] ?? '',
      permissionLevel: json['permissionLevel'] ?? 'ALLOWED',
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().add(const Duration(hours: 24)).toIso8601String()),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
      usedById: json['usedById'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedAt != null;
  bool get isValid => !isExpired && !isUsed;

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
