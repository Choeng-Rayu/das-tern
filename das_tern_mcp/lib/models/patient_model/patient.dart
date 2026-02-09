import '../enums_model/enums.dart';

/// Patient model – extends the User with patient-specific fields.
class Patient {
  final String id;
  final String? firstName;
  final String? lastName;
  final String phoneNumber;
  final String? email;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? idCardNumber;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed / relationship fields
  final int? dailyProgress;
  final int activePrescriptions;
  final String? subscriptionTier;

  Patient({
    required this.id,
    this.firstName,
    this.lastName,
    required this.phoneNumber,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.idCardNumber,
    this.accountStatus = AccountStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.dailyProgress,
    this.activePrescriptions = 0,
    this.subscriptionTier,
  });

  String get displayName =>
      [firstName, lastName].where((s) => s != null).join(' ');

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      gender: json['gender'] != null ? genderFromString(json['gender']) : null,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      idCardNumber: json['idCardNumber'],
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String()),
      dailyProgress: json['dailyProgress'],
      activePrescriptions: json['activePrescriptions'] ?? 0,
      subscriptionTier: json['subscriptionTier'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
        'gender': gender != null ? genderToString(gender!) : null,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'idCardNumber': idCardNumber,
      };
}
