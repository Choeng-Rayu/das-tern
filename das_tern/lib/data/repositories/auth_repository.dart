import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/models/user.dart';
import 'package:das_tern/data/services/auth_service.dart';

abstract class AuthRepository {
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

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthService service}) : _service = service;

  final AuthService _service;

  @override
  Future<User?> getCurrentUser() => _service.getCurrentUser();

  @override
  Future<User> signIn({required String email, required String password}) =>
      _service.signIn(email: email, password: password);

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    Gender? gender,
    DateTime? dateOfBirth,
  }) => _service.register(
    name: name,
    email: email,
    password: password,
    phoneNumber: phoneNumber,
    role: role,
    gender: gender,
    dateOfBirth: dateOfBirth,
  );

  @override
  Future<void> verifyOtp({required String email, required String otp}) =>
      _service.verifyOtp(email: email, otp: otp);

  @override
  Future<void> forgotPassword({required String email}) =>
      _service.forgotPassword(email: email);

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      _service.resetPassword(email: email, otp: otp, newPassword: newPassword);

  @override
  Future<void> signOut() => _service.signOut();
}
