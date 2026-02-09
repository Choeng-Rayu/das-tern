class User {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        role: UserRole.values.firstWhere((e) => e.name == json['role']),
        profileImage: json['profileImage'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'profileImage': profileImage,
      };
}

enum UserRole { patient, doctor, family }
