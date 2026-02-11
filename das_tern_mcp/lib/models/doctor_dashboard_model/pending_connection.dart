/// Pending connection request shown on the doctor dashboard.
class PendingConnection {
  final String id;
  final String initiatorId;
  final String recipientId;
  final String status;
  final DateTime requestedAt;
  final PendingConnectionPatient? initiator;

  PendingConnection({
    required this.id,
    required this.initiatorId,
    required this.recipientId,
    required this.status,
    required this.requestedAt,
    this.initiator,
  });

  String get patientName {
    if (initiator == null) return 'Unknown';
    return initiator!.displayName;
  }

  factory PendingConnection.fromJson(Map<String, dynamic> json) {
    return PendingConnection(
      id: json['id'] ?? '',
      initiatorId: json['initiatorId'] ?? '',
      recipientId: json['recipientId'] ?? '',
      status: json['status'] ?? 'PENDING',
      requestedAt: DateTime.parse(
          json['requestedAt'] ?? DateTime.now().toIso8601String()),
      initiator: json['initiator'] != null
          ? PendingConnectionPatient.fromJson(
              Map<String, dynamic>.from(json['initiator']))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'initiatorId': initiatorId,
        'recipientId': recipientId,
        'status': status,
        'requestedAt': requestedAt.toIso8601String(),
        'initiator': initiator?.toJson(),
      };
}

/// Patient info within a pending connection.
class PendingConnectionPatient {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phoneNumber;
  final String? gender;
  final String? dateOfBirth;

  PendingConnectionPatient({
    required this.id,
    this.firstName,
    this.lastName,
    this.fullName,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
  });

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final parts = [firstName ?? '', lastName ?? ''];
    final joined = parts.where((p) => p.isNotEmpty).join(' ');
    return joined.isNotEmpty ? joined : 'Unknown';
  }

  factory PendingConnectionPatient.fromJson(Map<String, dynamic> json) {
    return PendingConnectionPatient(
      id: json['id'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
      };
}
