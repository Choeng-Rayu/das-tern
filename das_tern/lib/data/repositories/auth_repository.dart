import 'package:das_tern/data/models/user.dart';
import 'package:das_tern/data/services/auth_service.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> signIn();
  Future<void> signOut();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthService service}) : _service = service;

  final AuthService _service;

  @override
  Future<User?> getCurrentUser() {
    return _service.getCurrentUser();
  }

  @override
  Future<User> signIn() {
    return _service.signIn();
  }

  @override
  Future<void> signOut() {
    return _service.signOut();
  }
}
