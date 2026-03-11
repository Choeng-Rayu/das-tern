import 'dart:async';

import 'package:das_tern/data/models/user.dart';

abstract class AuthService {
  Future<User?> getCurrentUser();
  Future<User> signIn();
  Future<void> signOut();
}

class MockAuthService implements AuthService {
  User? _currentUser = const User(
    id: 'user-1',
    name: 'Sok Dara',
    email: 'dara@example.com',
  );

  @override
  Future<User?> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<User> signIn() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _currentUser ??= const User(
      id: 'user-1',
      name: 'Sok Dara',
      email: 'dara@example.com',
    );
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
  }
}
