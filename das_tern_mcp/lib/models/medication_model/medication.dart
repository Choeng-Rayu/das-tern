import '../enums_model/medication_status.dart';
import '../enums_model/medication_type.dart';

class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String form;
  final String? instructions;
  final MedicationType type;
  final MedicationStatus status;
  final int frequency;
  final List<String> reminderTimes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.form,
    this.instructions,
    required this.type,
    required this.status,
    required this.frequency,
    required this.reminderTimes,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'form': form,
      'instructions': instructions,
      'type': type.toJson(),
      'status': status.toJson(),
      'frequency': frequency,
      'reminder_times': reminderTimes.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      form: map['form'] as String,
      instructions: map['instructions'] as String?,
      type: MedicationTypeExtension.fromJson(map['type'] as String),
      status: MedicationStatusExtension.fromJson(map['status'] as String),
      frequency: map['frequency'] as int,
      reminderTimes: (map['reminder_times'] as String).split(','),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      synced: map['synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'form': form,
      'instructions': instructions,
      'type': type.toJson(),
      'status': status.toJson(),
      'frequency': frequency,
      'reminderTimes': reminderTimes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int?,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      form: json['form'] as String,
      instructions: json['instructions'] as String?,
      type: MedicationTypeExtension.fromJson(json['type'] as String),
      status: MedicationStatusExtension.fromJson(json['status'] as String),
      frequency: json['frequency'] as int,
      reminderTimes: List<String>.from(json['reminderTimes'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? form,
    String? instructions,
    MedicationType? type,
    MedicationStatus? status,
    int? frequency,
    List<String>? reminderTimes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      instructions: instructions ?? this.instructions,
      type: type ?? this.type,
      status: status ?? this.status,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
