/// Clean MVVM-compliant User domain model.
/// No Flutter dependencies — pure Dart only.
library;

/// Represents the role a user holds in the system.
enum UserRole { patient, doctor, familyMember }

/// Represents the user's biological or self-identified gender.
enum Gender { male, female, other }

/// Language preference for the app UI.
enum AppLanguage { khmer, english }

/// Visual theme preference.
enum AppTheme { light, dark }

/// Lifecycle status of a user account.
enum AccountStatus {
  active,
  pendingVerification,
  verified,
  rejected,
  locked,
}

// ── String helpers ────────────────────────────────────────────────────────────

UserRole _userRoleFromString(String value) {
  switch (value.toUpperCase()) {
    case 'DOCTOR':
      return UserRole.doctor;
    case 'FAMILY_MEMBER':
      return UserRole.familyMember;
    default:
      return UserRole.patient;
  }
}

String _userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.patient:
      return 'PATIENT';
    case UserRole.doctor:
      return 'DOCTOR';
    case UserRole.familyMember:
      return 'FAMILY_MEMBER';
  }
}

Gender _genderFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'MALE':
      return Gender.male;
    case 'FEMALE':
      return Gender.female;
    default:
      return Gender.other;
  }
}

String _genderToString(Gender gender) {
  switch (gender) {
    case Gender.male:
      return 'MALE';
    case Gender.female:
      return 'FEMALE';
    case Gender.other:
      return 'OTHER';
  }
}

AppLanguage _languageFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'khmer':
    case 'km':
      return AppLanguage.khmer;
    default:
      return AppLanguage.english;
  }
}

AppTheme _themeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'dark':
      return AppTheme.dark;
    default:
      return AppTheme.light;
  }
}

AccountStatus _accountStatusFromString(String? value) {
  switch (value?.toUpperCase()) {
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

// ── Domain model ─────────────────────────────────────────────────────────────

/// Immutable domain model representing an authenticated user.
class User {
  const User({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.language = AppLanguage.english,
    this.theme = AppTheme.light,
    this.accountStatus = AccountStatus.active,
  });

  final String id;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final AppLanguage language;
  final AppTheme theme;
  final AccountStatus accountStatus;

  // ── Computed helpers ──────────────────────────────────────────────────────

  String get fullName => '$firstName $lastName'.trim();

  // ── Factory / serialisation ───────────────────────────────────────────────

  factory User.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case key styles from the backend.
    final first =
        (json['firstName'] ?? json['first_name'] ?? '') as String;
    final last =
        (json['lastName'] ?? json['last_name'] ?? '') as String;
    final phone =
        (json['phoneNumber'] ?? json['phone_number'] ?? json['phone'] ?? '')
            as String;

    return User(
      id: (json['id'] ?? '') as String,
      role: _userRoleFromString((json['role'] ?? 'PATIENT') as String),
      firstName: first,
      lastName: last,
      phoneNumber: phone,
      email: json['email'] as String?,
      gender: json['gender'] != null
          ? _genderFromString(json['gender'] as String)
          : null,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      language: _languageFromString(json['language'] as String?),
      theme: _themeFromString(json['theme'] as String?),
      accountStatus: _accountStatusFromString(
        json['accountStatus'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': _userRoleToString(role),
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    if (email != null) 'email': email,
    if (gender != null) 'gender': _genderToString(gender!),
    if (dateOfBirth != null)
      'dateOfBirth': dateOfBirth!.toIso8601String(),
    'language': language.name,
    'theme': theme.name,
    'accountStatus': accountStatus.name,
  };

  User copyWith({
    String? id,
    UserRole? role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    Gender? gender,
    DateTime? dateOfBirth,
    AppLanguage? language,
    AppTheme? theme,
    AccountStatus? accountStatus,
  }) {
    return User(
      id: id ?? this.id,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, role: $role, name: $fullName)';
}
