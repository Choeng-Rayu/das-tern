/// Use case: group a flat list of medications into time-of-day [ScheduleSlot]s.
///
/// Pure business logic — no Flutter, no HTTP, no I/O.
library;

import '../../data/models/medication.dart';
import '../../data/models/schedule_slot.dart';

/// Groups medications by their scheduled time period and returns an ordered
/// list of [ScheduleSlot]s (morning → afternoon → night).
///
/// Usage:
/// ```dart
/// final slots = GenerateScheduleUseCase()(medications);
/// ```
class GenerateScheduleUseCase {
  const GenerateScheduleUseCase();

  /// Builds schedule slots from [medications].
  ///
  /// Each medication's [ScheduleTime.period] string is mapped to a
  /// [TimePeriod]. Medications without any schedule times are placed into
  /// the morning slot by default.
  List<ScheduleSlot> call(List<Medication> medications) {
    // Accumulate medications per period.
    final Map<TimePeriod, List<Medication>> byPeriod = {
      TimePeriod.morning: [],
      TimePeriod.afternoon: [],
      TimePeriod.night: [],
    };

    for (final med in medications) {
      if (!med.isActive) continue;

      if (med.scheduleTimes.isEmpty) {
        // Default to morning if no schedule is set.
        byPeriod[TimePeriod.morning]!.add(med);
      } else {
        for (final st in med.scheduleTimes) {
          final period = _mapPeriod(st.period);
          byPeriod[period]!.add(med);
        }
      }
    }

    // Build slots, skipping empty periods.
    final slots = <ScheduleSlot>[];
    for (final period in TimePeriod.values) {
      final meds = byPeriod[period]!;
      if (meds.isEmpty) continue;
      slots.add(
        ScheduleSlot(
          period: period,
          time: _defaultTimeForPeriod(period),
          medications: List.unmodifiable(meds),
        ),
      );
    }

    // Sort by period display order (already in enum declaration order).
    slots.sort((a, b) => a.period.sortOrder.compareTo(b.period.sortOrder));
    return slots;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Maps a raw period string (from the backend or OCR) to a [TimePeriod].
  TimePeriod _mapPeriod(String raw) {
    switch (raw.toUpperCase()) {
      case 'MORNING':
      case 'AM':
        return TimePeriod.morning;
      case 'AFTERNOON':
      case 'DAYTIME':
      case 'PM':
      case 'NOON':
        return TimePeriod.afternoon;
      case 'NIGHT':
      case 'EVENING':
      case 'BEDTIME':
        return TimePeriod.night;
      default:
        return TimePeriod.morning;
    }
  }

  /// Returns a sensible default display time string for a given [period].
  String _defaultTimeForPeriod(TimePeriod period) {
    switch (period) {
      case TimePeriod.morning:
        return '08:00 AM';
      case TimePeriod.afternoon:
        return '12:00 PM';
      case TimePeriod.night:
        return '08:00 PM';
    }
  }
}
