/// Clean MVVM-compliant Reminder domain model.
/// Represents a single scheduled medication dose for today's view.
/// No Flutter dependencies — pure Dart only.
library;

// ── Domain model ─────────────────────────────────────────────────────────────

/// Immutable domain model for a single medication reminder / dose event.
class Reminder {
  const Reminder({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.isPast,
    required this.isTaken,
    required this.dosage,
    required this.unit,
  });

  /// Unique dose-event identifier from the backend.
  final String id;

  /// Parent medication identifier.
  final String medicationId;

  /// Human-readable medication name.
  final String medicationName;

  /// Wall-clock time this dose is scheduled for.
  final DateTime scheduledTime;

  /// Whether the scheduled time has already passed.
  final bool isPast;

  /// Whether the user has marked this dose as taken.
  final bool isTaken;

  /// Dose quantity, e.g. "1" or "500".
  final String dosage;

  /// Unit of measurement, e.g. "tablet", "mg", "ml".
  final String unit;

  // ── Factory / serialisation ───────────────────────────────────────────────

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final scheduledRaw =
        json['scheduledTime'] ?? json['scheduled_time'] ?? '';
    final scheduledTime = scheduledRaw is String
        ? DateTime.tryParse(scheduledRaw) ?? DateTime.now()
        : DateTime.now();

    return Reminder(
      id: (json['id'] ?? '').toString(),
      medicationId:
          (json['medicationId'] ?? json['medication_id'] ?? '').toString(),
      medicationName:
          (json['medicationName'] ?? json['name'] ?? '') as String,
      scheduledTime: scheduledTime,
      isPast: json['isPast'] as bool? ?? scheduledTime.isBefore(DateTime.now()),
      isTaken: json['isTaken'] as bool? ??
          (json['status'] == 'TAKEN_ON_TIME' ||
              json['status'] == 'TAKEN_LATE'),
      dosage: (json['dosage'] ?? '').toString(),
      unit: (json['unit'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicationId': medicationId,
    'medicationName': medicationName,
    'scheduledTime': scheduledTime.toIso8601String(),
    'isPast': isPast,
    'isTaken': isTaken,
    'dosage': dosage,
    'unit': unit,
  };

  Reminder copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    bool? isPast,
    bool? isTaken,
    String? dosage,
    String? unit,
  }) {
    return Reminder(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isPast: isPast ?? this.isPast,
      isTaken: isTaken ?? this.isTaken,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Reminder && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Reminder(id: $id, med: $medicationName, '
      'time: $scheduledTime, taken: $isTaken)';
}
