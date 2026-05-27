import 'package:timezone/timezone.dart' as tz;

import '../domain/medication.dart';
import '../domain/prescription_enums.dart';

/// Draft for a dose event before it is persisted.
class DoseEventDraft {
  const DoseEventDraft({
    required this.medicationId,
    required this.prescriptionId,
    required this.patientId,
    required this.scheduledTime,
    required this.timePeriod,
  });

  final String medicationId;
  final String prescriptionId;
  final String patientId;
  final DateTime scheduledTime; // UTC
  final TimePeriod timePeriod;
}

/// Meal-time preferences used by the generator.
class MealTimePreference {
  const MealTimePreference({
    this.morningMeal,
    this.afternoonMeal,
    this.eveningMeal,
    this.nightMeal,
  });

  final String? morningMeal;
  final String? afternoonMeal;
  final String? eveningMeal;
  final String? nightMeal;

  static const MealTimePreference cambodiaDefaults = MealTimePreference(
    morningMeal: '07:00',
    afternoonMeal: '12:00',
    eveningMeal: '18:00',
    nightMeal: '21:00',
  );
}

/// Pure-Dart deterministic dose-event generator.
///
/// Generates one [DoseEventDraft] per active [DosageSlot] per day between
/// [startUtc] (inclusive) and [endUtc] (exclusive). PRN medications are
/// skipped entirely.
///
/// Spec ref: 03-prescription-medication design §3.
class ScheduleGenerator {
  const ScheduleGenerator(this._mealTime);

  final MealTimePreference _mealTime;

  Iterable<DoseEventDraft> generate(
    Medication med, {
    required String patientId,
    required DateTime startUtc,
    required DateTime endUtc,
    required String timezone,
  }) sync* {
    if (med.isPrn) return;

    final loc = tz.getLocation(timezone);
    final startLocal = tz.TZDateTime.from(startUtc, loc);
    final endLocal = tz.TZDateTime.from(endUtc, loc);

    var day = DateTime(startLocal.year, startLocal.month, startLocal.day);
    final endDay = DateTime(endLocal.year, endLocal.month, endLocal.day);

    while (day.isBefore(endDay)) {
      final slots = <(TimePeriod, DosageSlot?, String)>[
        (TimePeriod.morning, med.morningDosage, _mealTime.morningMeal ?? '07:00'),
        (TimePeriod.afternoon, med.afternoonDosage, _mealTime.afternoonMeal ?? '12:00'),
        (TimePeriod.evening, med.eveningDosage, _mealTime.eveningMeal ?? '18:00'),
        (TimePeriod.night, med.nightDosage, _mealTime.nightMeal ?? '21:00'),
      ];

      for (final (period, slot, mealTime) in slots) {
        if (slot == null) continue;
        final hm = mealTime.split(':');
        var local = tz.TZDateTime(
          loc,
          day.year,
          day.month,
          day.day,
          int.parse(hm[0]),
          int.parse(hm[1]),
        );
        if (med.beforeMeal) {
          local = local.subtract(const Duration(minutes: 30));
        }
        yield DoseEventDraft(
          medicationId: med.id,
          prescriptionId: med.prescriptionId,
          patientId: patientId,
          scheduledTime: local.toUtc(),
          timePeriod: period,
        );
      }

      day = day.add(const Duration(days: 1));
    }
  }
}
