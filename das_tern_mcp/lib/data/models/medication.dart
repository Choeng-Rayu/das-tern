/// Clean MVVM-compliant Medication domain model.
/// No Flutter dependencies — pure Dart only.
library;

// ── Supporting value-object ───────────────────────────────────────────────────

/// A single scheduled administration time for a medication.
class ScheduleTime {
  const ScheduleTime({required this.time, required this.period});

  /// Time string in HH:mm 24-hour format, e.g. "08:00".
  final String time;

  /// Period label such as "MORNING", "AFTERNOON", "NIGHT".
  final String period;

  factory ScheduleTime.fromJson(Map<String, dynamic> json) => ScheduleTime(
    time: (json['time'] ?? '') as String,
    period: (json['period'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {'time': time, 'period': period};

  @override
  String toString() => 'ScheduleTime(time: $time, period: $period)';
}

// ── Domain model ─────────────────────────────────────────────────────────────

/// Immutable domain model for a single medication entry.
class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.frequency,
    required this.scheduleTimes,
    this.prescriptionId,
    this.isActive = true,
  });

  final String id;

  /// Generic or brand name of the medication.
  final String name;

  /// Numeric or descriptive dose amount, e.g. "500" or "1".
  final String dosage;

  /// Unit of measurement, e.g. "mg", "tablet", "ml".
  final String unit;

  /// Number of times per day this medication is taken.
  final int frequency;

  /// Ordered list of scheduled administration times.
  final List<ScheduleTime> scheduleTimes;

  /// ID of the parent prescription, if any.
  final String? prescriptionId;

  /// Whether this medication is currently active.
  final bool isActive;

  // ── Factory / serialisation ───────────────────────────────────────────────

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Parse scheduleTimes from various backend shapes.
    List<ScheduleTime> times = [];
    final raw = json['scheduleTimes'] ?? json['schedule_times'];
    if (raw is List) {
      times = raw
          .map((e) => ScheduleTime.fromJson(
                e is Map<String, dynamic> ? e : <String, dynamic>{},
              ))
          .toList();
    }

    return Medication(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['medicineName'] ?? '') as String,
      dosage: (json['dosage'] ?? json['dosageAmount']?.toString() ?? '')
          as String,
      unit: (json['unit'] ?? '') as String,
      frequency: (json['frequency'] is int)
          ? json['frequency'] as int
          : int.tryParse(json['frequency']?.toString() ?? '') ?? 1,
      scheduleTimes: times,
      prescriptionId: (json['prescriptionId'] ?? json['prescription_id'])
          as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'unit': unit,
    'frequency': frequency,
    'scheduleTimes': scheduleTimes.map((t) => t.toJson()).toList(),
    if (prescriptionId != null) 'prescriptionId': prescriptionId,
    'isActive': isActive,
  };

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? unit,
    int? frequency,
    List<ScheduleTime>? scheduleTimes,
    String? prescriptionId,
    bool? isActive,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Medication && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Medication(id: $id, name: $name, dosage: $dosage $unit)';
}
