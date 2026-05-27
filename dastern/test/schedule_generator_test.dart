import 'dart:ffi';
import 'dart:io';

import 'package:dastern/features/prescriptions/data/schedule_generator.dart';
import 'package:dastern/features/prescriptions/domain/medication.dart';
import 'package:dastern/features/prescriptions/domain/prescription_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        return DynamicLibrary.open('libsqlite3.so.0');
      });
    }
  });

  const tz = 'Asia/Phnom_Penh'; // UTC+7, no DST
  const prefs = MealTimePreference(
    morningMeal: '07:00',
    afternoonMeal: '12:00',
    eveningMeal: '18:00',
    nightMeal: '21:00',
  );
  const gen = ScheduleGenerator(prefs);

  Medication buildMed({
    bool isPrn = false,
    bool beforeMeal = false,
    DosageSlot? morning,
    DosageSlot? afternoon,
    DosageSlot? evening,
    DosageSlot? night,
  }) =>
      Medication(
        id: 'med-1',
        prescriptionId: 'rx-1',
        rowNumber: 1,
        medicineName: 'Paracetamol',
        medicineType: MedicineType.oral,
        unit: MedicineUnit.tablet,
        dosageAmount: 1,
        isPrn: isPrn,
        beforeMeal: beforeMeal,
        morningDosage: morning,
        afternoonDosage: afternoon,
        eveningDosage: evening,
        nightDosage: night,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  const slot = DosageSlot(amount: 1, unit: MedicineUnit.tablet);

  test('PRN medication generates no events', () {
    final events = gen
        .generate(
          buildMed(isPrn: true, morning: slot),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 2),
          timezone: tz,
        )
        .toList();
    expect(events, isEmpty);
  });

  test('BID (morning + evening) generates 2 events per day', () {
    final events = gen
        .generate(
          buildMed(morning: slot, evening: slot),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 2),
          timezone: tz,
        )
        .toList();
    expect(events.length, 2);
    expect(events.map((e) => e.timePeriod).toSet(),
        {TimePeriod.morning, TimePeriod.evening});
  });

  test('QID generates 4 events per day', () {
    final events = gen
        .generate(
          buildMed(morning: slot, afternoon: slot, evening: slot, night: slot),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 2),
          timezone: tz,
        )
        .toList();
    expect(events.length, 4);
  });

  test('before_meal shifts time 30 minutes earlier', () {
    final withoutBefore = gen
        .generate(
          buildMed(morning: slot),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 2),
          timezone: tz,
        )
        .first
        .scheduledTime;

    final withBefore = gen
        .generate(
          buildMed(morning: slot, beforeMeal: true),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 2),
          timezone: tz,
        )
        .first
        .scheduledTime;

    expect(withoutBefore.difference(withBefore).inMinutes, 30);
  });

  test('morning slot in Phnom Penh is 07:00 local = 00:00 UTC', () {
    final event = gen
        .generate(
          buildMed(morning: slot),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 2),
          timezone: tz,
        )
        .first;
    // 07:00 Asia/Phnom_Penh = 00:00 UTC
    expect(event.scheduledTime.toUtc().hour, 0);
    expect(event.scheduledTime.toUtc().minute, 0);
  });

  test('7-day range generates 7 events for once-daily', () {
    final events = gen
        .generate(
          buildMed(morning: slot),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 8),
          timezone: tz,
        )
        .toList();
    expect(events.length, 7);
  });

  test('idempotency: same inputs produce identical output', () {
    final a = gen
        .generate(
          buildMed(morning: slot, evening: slot),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 4),
          timezone: tz,
        )
        .map((e) => e.scheduledTime.toIso8601String())
        .toList();

    final b = gen
        .generate(
          buildMed(morning: slot, evening: slot),
          patientId: 'p1',
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 4),
          timezone: tz,
        )
        .map((e) => e.scheduledTime.toIso8601String())
        .toList();

    expect(a, b);
  });
}
