abstract class User {
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

class Patient extends User {
  Patient({
    required String id, // p-uuid
    required String name,
    String? email,
    String? phone,
    String? profileImage,
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          role: UserRole.patient,
          profileImage: profileImage,
        );
}

interface class Lan {
  String kongLan(){
    return "must have kong 4";
  } // e.g., "father", "mother", "sibling"
} 

class toyota implements Lan{
//   @override
//   String kongLan() {
//     return "must have kong 4";
//   }
  @override
  String kongLan() {
    return "";
  }
}
class Doctor extends User {
  Doctor({
    required String id, // d-uuid
    required String name,
    String? email,
    String? phone,
    String? profileImage, 
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          role: UserRole.doctor,
          profileImage: profileImage,
        );
}

enum UserRole { patient, doctor, family }
