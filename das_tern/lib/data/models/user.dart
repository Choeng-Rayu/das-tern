class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'patient',
  });

  final String id;
  final String name;
  final String email;
  final String role;
}
