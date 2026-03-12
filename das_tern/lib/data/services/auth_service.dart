import 'dart:async';

import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/models/user.dart';

abstract class AuthService {
  Future<User?> getCurrentUser();
  Future<User> signIn({required String email, required String password});
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    Gender? gender,
    DateTime? dateOfBirth,
  });
  Future<void> verifyOtp({required String email, required String otp});
  Future<void> forgotPassword({required String email});
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
  Future<void> signOut();
}

class MockAuthService implements AuthService {
  User? _currentUser = const User(
    id: 'user-1',
    name: 'Sok Dara',
    email: 'dara@example.com',
    phoneNumber: '+85512345678',
  );

  @override
  Future<User?> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = User(
      id: 'user-1',
      name: 'Sok Dara',
      email: email,
      phoneNumber: '+85512345678',
    );
    return _currentUser!;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    Gender? gender,
    DateTime? dateOfBirth,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
      gender: gender,
      dateOfBirth: dateOfBirth,
      accountStatus: AccountStatus.pendingVerification,
    );
    return _currentUser!;
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        accountStatus: AccountStatus.verified,
      );
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
  }
}
