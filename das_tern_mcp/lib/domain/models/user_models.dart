/// Typed domain models for the user/auth slice.
///
/// These replace raw `Map<String, dynamic>` access with compile-time safe
/// immutable data classes. The existing `AuthProvider.user` map is preserved
/// as legacy compatibility — new code should use `AuthProvider.currentUser`.
library;

import 'package:flutter/foundation.dart';

// ─── Auth Status ────────────────────────────────────────────────────────────

/// Represents the authentication lifecycle state.
enum AuthStatus {
  /// Initial state — haven't checked storage yet.
  unknown,

  /// Actively loading/checking auth state.
  loading,

  /// Authenticated with valid tokens and user data.
  authenticated,

  /// Not authenticated — no valid tokens.
  unauthenticated,
}

// ─── Current User ───────────────────────────────────────────────────────────

/// Immutable domain model for the currently authenticated user.
///
/// Constructed from the API response (`/auth/me` or `/users/me`).
@immutable
class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.firstName,
    required this.role,
    this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.profileImage,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final UserRole role;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? profileImage;

  /// Full display name.
  String get displayName {
    if (lastName == null || lastName!.isEmpty) return firstName;
    return '$firstName $lastName';
  }

  /// Initials for avatar fallback.
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = (lastName != null && lastName!.isNotEmpty) ? lastName![0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Construct from API JSON map.
  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'] as String,
      firstName: (json['firstName'] ?? json['name'] ?? '') as String,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      // API may send either 'phone' or 'phoneNumber'
      phone: (json['phone'] ?? json['phoneNumber']) as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'PATIENT'),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] != null
          ? Gender.fromString(json['gender'] as String)
          : null,
      // API may send either 'profileImage' or 'profilePictureUrl'
      profileImage:
          (json['profileImage'] ?? json['profilePictureUrl']) as String?,
    );
  }

  /// Convert back to JSON map (for legacy compatibility layer).
  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'phoneNumber': phone, // legacy alias
    'role': role.value,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender?.value,
    'profileImage': profileImage,
    'profilePictureUrl': profileImage, // legacy alias
  };

  CurrentUser copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    Gender? gender,
    String? profileImage,
  }) {
    return CurrentUser(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentUser &&
          other.id == id &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.email == email &&
          other.phone == phone &&
          other.profileImage == profileImage;

  @override
  int get hashCode => Object.hash(id, firstName, lastName, email, phone);
}

// ─── User Profile Update ────────────────────────────────────────────────────

/// Payload for PATCH /users/me — only non-null fields are sent.
@immutable
class UserProfileUpdate {
  const UserProfileUpdate({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.profileImage,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final Gender? gender;

  /// Base64-encoded image string (or URL) for profile picture.
  final String? profileImage;

  /// Convert to JSON map, omitting null fields.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (firstName != null) map['firstName'] = firstName;
    if (lastName != null) map['lastName'] = lastName;
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (dateOfBirth != null) {
      map['dateOfBirth'] = dateOfBirth!.toIso8601String();
    }
    if (gender != null) map['gender'] = gender!.value;
    if (profileImage != null) map['profileImage'] = profileImage;
    return map;
  }

  bool get isEmpty =>
      firstName == null &&
      lastName == null &&
      email == null &&
      phone == null &&
      dateOfBirth == null &&
      gender == null &&
      profileImage == null;
}

// ─── Auth View State ────────────────────────────────────────────────────────

/// Composite UI state exposed by AuthProvider to views.
@immutable
class AuthViewState {
  const AuthViewState({
    this.status = AuthStatus.unknown,
    this.currentUser,
    this.error,
    this.isLoading = false,
  });

  final AuthStatus status;
  final CurrentUser? currentUser;
  final String? error;
  final bool isLoading;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthViewState copyWith({
    AuthStatus? status,
    CurrentUser? currentUser,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthViewState(
      status: status ?? this.status,
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Enums ──────────────────────────────────────────────────────────────────

enum UserRole {
  patient('PATIENT'),
  doctor('DOCTOR'),
  family('FAMILY');

  const UserRole(this.value);
  final String value;

  factory UserRole.fromString(String s) {
    return UserRole.values.firstWhere(
      (e) => e.value == s.toUpperCase(),
      orElse: () => UserRole.patient,
    );
  }
}

enum Gender {
  male('MALE'),
  female('FEMALE'),
  other('OTHER');

  const Gender(this.value);
  final String value;

  factory Gender.fromString(String s) {
    return Gender.values.firstWhere(
      (e) => e.value == s.toUpperCase(),
      orElse: () => Gender.other,
    );
  }
}
