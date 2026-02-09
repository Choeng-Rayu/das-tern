import '../enums_model/enums.dart';

/// Doctor model – extends the User with doctor-specific fields.
class Doctor {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String hospitalClinic;
  final String specialty;
  final String licenseNumber;
  final String? licensePhotoUrl;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationships
  final int patientCount;

  Doctor({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.hospitalClinic,
    required this.specialty,
    required this.licenseNumber,
    this.licensePhotoUrl,
    this.accountStatus = AccountStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.patientCount = 0,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      hospitalClinic: json['hospitalClinic'] ?? '',
      specialty: json['specialty'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      licensePhotoUrl: json['licensePhotoUrl'],
      accountStatus: json['accountStatus'] != null
          ? _fromString(json['accountStatus'])
          : AccountStatus.active,
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String()),
      patientCount: json['patientCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'hospitalClinic': hospitalClinic,
        'specialty': specialty,
        'licenseNumber': licenseNumber,
      };

  static AccountStatus _fromString(String v) {
    switch (v) {
      case 'ACTIVE':
        return AccountStatus.active;
      case 'PENDING_VERIFICATION':
        return AccountStatus.pendingVerification;
      case 'VERIFIED':
        return AccountStatus.verified;
      case 'REJECTED':
        return AccountStatus.rejected;
      case 'LOCKED':
        return AccountStatus.locked;
      default:
        return AccountStatus.active;
    }
  }
}
