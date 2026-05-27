import 'chosen_role.dart';

/// Minimal auth user exposed to the presentation layer.
class AuthUser {
  const AuthUser({required this.id, required this.role, this.email});

  final String id;
  final ChosenRole role;
  final String? email;
}
