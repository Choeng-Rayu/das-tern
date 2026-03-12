import 'package:das_tern/data/models/medication.dart';

class MedicationBatch {
  const MedicationBatch({
    required this.id,
    required this.name,
    required this.scheduledTime,
    this.patientId,
    this.isActive = true,
    this.medications = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? patientId;
  final String name;
  final String scheduledTime;
  final bool isActive;
  final List<Medication> medications;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MedicationBatch.fromJson(Map<String, dynamic> json) {
    final List<dynamic> meds =
        (json['medications'] as List<dynamic>?) ?? <dynamic>[];

    return MedicationBatch(
      id: (json['id'] ?? '').toString(),
      patientId: json['patientId'] as String?,
      name: json['name'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String? ?? '08:00',
      isActive: json['isActive'] as bool? ?? true,
      medications: meds
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (patientId != null) 'patientId': patientId,
    'name': name,
    'scheduledTime': scheduledTime,
    'isActive': isActive,
    'medications': medications.map((m) => m.toJson()).toList(),
  };

  MedicationBatch copyWith({
    String? id,
    String? patientId,
    String? name,
    String? scheduledTime,
    bool? isActive,
    List<Medication>? medications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationBatch(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
      medications: medications ?? this.medications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
