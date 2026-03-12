import 'package:das_tern/data/models/enums.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.role = UserRole.patient,
    this.gender,
    this.dateOfBirth,
    this.accountStatus = AccountStatus.active,
    this.subscriptionTier = SubscriptionTier.freemium,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final UserRole role;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final AccountStatus accountStatus;
  final SubscriptionTier subscriptionTier;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;

  factory User.fromJson(Map<String, dynamic> json) {
    final String firstName = (json['firstName'] as String?) ?? '';
    final String lastName = (json['lastName'] as String?) ?? '';
    final String fullName =
        json['fullName'] as String? ?? '$firstName $lastName'.trim();

    return User(
      id: json['id'] as String? ?? '',
      name: fullName.isEmpty ? (json['name'] as String? ?? '') : fullName,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'PATIENT'),
      gender: json['gender'] != null
          ? Gender.fromString(json['gender'] as String)
          : null,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      accountStatus: AccountStatus.fromString(
        json['accountStatus'] as String? ?? 'ACTIVE',
      ),
      subscriptionTier: SubscriptionTier.fromString(
        json['subscriptionTier'] as String? ?? 'FREEMIUM',
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    'role': role.toApiString(),
    if (gender != null) 'gender': gender!.toApiString(),
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    'accountStatus': accountStatus.name,
    'subscriptionTier': subscriptionTier.toApiString(),
  };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    Gender? gender,
    DateTime? dateOfBirth,
    AccountStatus? accountStatus,
    SubscriptionTier? subscriptionTier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      accountStatus: accountStatus ?? this.accountStatus,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
