/// Represents a patient in the doctor's patient list.
class PatientListItem {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final int? age;
  final String? gender;
  final String phoneNumber;
  final int activePrescriptions;
  final double adherencePercentage;
  final String adherenceLevel; // 'GREEN' | 'YELLOW' | 'RED'
  final DateTime? lastActivity;
  final String connectionId;

  PatientListItem({
    required this.id,
    this.firstName,
    this.lastName,
    this.fullName,
    this.age,
    this.gender,
    required this.phoneNumber,
    required this.activePrescriptions,
    required this.adherencePercentage,
    required this.adherenceLevel,
    this.lastActivity,
    required this.connectionId,
  });

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final parts = [firstName ?? '', lastName ?? ''];
    final joined = parts.where((p) => p.isNotEmpty).join(' ');
    return joined.isNotEmpty ? joined : 'Unknown Patient';
  }

  String get initials {
    final name = displayName;
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  factory PatientListItem.fromJson(Map<String, dynamic> json) {
    return PatientListItem(
      id: json['id'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      age: json['age'],
      gender: json['gender'],
      phoneNumber: json['phoneNumber'] ?? '',
      activePrescriptions: json['activePrescriptions'] ?? 0,
      adherencePercentage:
          (json['adherencePercentage'] ?? 0).toDouble(),
      adherenceLevel: json['adherenceLevel'] ?? 'GREEN',
      lastActivity: json['lastActivity'] != null
          ? DateTime.tryParse(json['lastActivity'].toString())
          : null,
      connectionId: json['connectionId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'age': age,
        'gender': gender,
        'phoneNumber': phoneNumber,
        'activePrescriptions': activePrescriptions,
        'adherencePercentage': adherencePercentage,
        'adherenceLevel': adherenceLevel,
        'lastActivity': lastActivity?.toIso8601String(),
        'connectionId': connectionId,
      };
}
