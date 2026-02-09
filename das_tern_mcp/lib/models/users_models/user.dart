import '../enums_model/enums.dart';

/// User model matching the backend Prisma User schema.
class User {
  final String id;
  final UserRole role;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String phoneNumber;
  final String? email;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? idCardNumber;
  final AppLanguage language;
  final AppTheme theme;
  final String? hospitalClinic;
  final String? specialty;
  final String? licenseNumber;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed fields from backend
  final int? dailyProgress;
  final String? greeting;
  final String? subscriptionTier;

  User({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.fullName,
    required this.phoneNumber,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.idCardNumber,
    this.language = AppLanguage.khmer,
    this.theme = AppTheme.light,
    this.hospitalClinic,
    this.specialty,
    this.licenseNumber,
    this.accountStatus = AccountStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.dailyProgress,
    this.greeting,
    this.subscriptionTier,
  });

  String get displayName =>
      fullName ?? [firstName, lastName].where((s) => s != null).join(' ');

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      role: userRoleFromString(json['role'] ?? 'PATIENT'),
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      gender: json['gender'] != null ? genderFromString(json['gender']) : null,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      idCardNumber: json['idCardNumber'],
      accountStatus: _accountStatusFromString(json['accountStatus'] ?? 'ACTIVE'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      dailyProgress: json['dailyProgress'],
      greeting: json['greeting'],
      subscriptionTier: json['subscriptionTier'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': userRoleToString(role),
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'gender': gender != null ? genderToString(gender!) : null,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'idCardNumber': idCardNumber,
      };

  static AccountStatus _accountStatusFromString(String v) {
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
