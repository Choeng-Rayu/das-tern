/// ScheduleSlot and TimePeriod — used by GenerateScheduleUseCase and the
/// patient home screen to group medications by time-of-day.
library;

import 'medication.dart';

// ── Enum ─────────────────────────────────────────────────────────────────────

/// Time-of-day period for a medication dose.
enum TimePeriod { morning, afternoon, night }

extension TimePeriodX on TimePeriod {
  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case TimePeriod.morning:
        return 'Morning';
      case TimePeriod.afternoon:
        return 'Afternoon';
      case TimePeriod.night:
        return 'Night';
    }
  }

  /// Sort order (morning → afternoon → night).
  int get sortOrder {
    switch (this) {
      case TimePeriod.morning:
        return 0;
      case TimePeriod.afternoon:
        return 1;
      case TimePeriod.night:
        return 2;
    }
  }
}

// ── Domain model ─────────────────────────────────────────────────────────────

/// A single time slot grouping medications that share the same [period].
class ScheduleSlot {
  const ScheduleSlot({
    required this.period,
    required this.time,
    required this.medications,
  });

  /// Which part of the day this slot belongs to.
  final TimePeriod period;

  /// Display time string, e.g. "08:00 AM".
  final String time;

  /// Medications scheduled for this slot.
  final List<Medication> medications;

  ScheduleSlot copyWith({
    TimePeriod? period,
    String? time,
    List<Medication>? medications,
  }) {
    return ScheduleSlot(
      period: period ?? this.period,
      time: time ?? this.time,
      medications: medications ?? this.medications,
    );
  }

  @override
  String toString() =>
      'ScheduleSlot(period: $period, time: $time, '
      'medications: ${medications.length})';
}
