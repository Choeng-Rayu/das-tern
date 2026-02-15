/// Doctor note model for patient notes.
class DoctorNote {
  final String id;
  final String doctorId;
  final String patientId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DoctorNoteAuthor? doctor;

  DoctorNote({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.doctor,
  });

  factory DoctorNote.fromJson(Map<String, dynamic> json) {
    return DoctorNote(
      id: json['id'] ?? '',
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String()),
      doctor: json['doctor'] != null
          ? DoctorNoteAuthor.fromJson(Map<String, dynamic>.from(json['doctor']))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorId': doctorId,
        'patientId': patientId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'doctor': doctor?.toJson(),
      };

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }
}

/// Embedded doctor info within a note.
class DoctorNoteAuthor {
  final String id;
  final String? fullName;

  DoctorNoteAuthor({required this.id, this.fullName});

  factory DoctorNoteAuthor.fromJson(Map<String, dynamic> json) {
    return DoctorNoteAuthor(
      id: json['id'] ?? '',
      fullName: json['fullName'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
      };
}
