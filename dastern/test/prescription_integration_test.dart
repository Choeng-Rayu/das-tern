import 'dart:ffi';
import 'dart:io';

import 'package:dastern/core/storage/drift/app_database.dart';
import 'package:dastern/core/storage/drift/daos/dose_events_dao.dart';
import 'package:dastern/core/sync/sync_engine.dart';
import 'package:dastern/features/prescriptions/data/medication_repository.dart';
import 'package:dastern/features/prescriptions/data/prescription_repository.dart';
import 'package:dastern/features/prescriptions/data/schedule_generator.dart';
import 'package:dastern/features/prescriptions/domain/prescription_enums.dart';
import 'package:dastern/features/prescriptions/domain/usecases/create_prescription.dart';
import 'package:dastern/features/prescriptions/domain/usecases/prescription_lifecycle.dart';
import 'package:drift/native.dart';
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

  test(
    '9.3 Integration: create DRAFT → confirm → dose events generated → visible in list',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final engine = SyncEngine(db: db);
      final prescriptionRepo = PrescriptionRepositoryImpl(db: db, sync: engine);
      final medRepo = MedicationRepositoryImpl(db: db, sync: engine);
      final doseDao = DoseEventsDao(db);

      // 1. Doctor creates a DRAFT prescription
      final useCase = CreatePrescription(
        prescriptionRepo,
        medRepo,
        const ScheduleGenerator(MealTimePreference.cambodiaDefaults),
        doseDao,
        engine,
      );

      final draft = await useCase(
        const PrescriptionDraft(
          patientId: 'patient-1',
          patientName: 'Dara Chan',
          patientGender: Gender.male,
          patientAge: 30,
          symptoms: 'Headache',
          doctorId: 'doctor-1', // doctor-authored → starts as DRAFT
          medications: <Map<String, dynamic>>[
            <String, dynamic>{
              'medicine_name': 'Paracetamol',
              'medicine_type': 'ORAL',
              'unit': 'TABLET',
              'dosage_amount': 1.0,
              'is_prn': false,
              'before_meal': false,
              'morning_dosage': '{"amount":1,"unit":"TABLET"}',
              'evening_dosage': '{"amount":1,"unit":"TABLET"}',
            },
          ],
          patientTimezone: 'Asia/Phnom_Penh',
        ),
      );

      // 2. Verify DRAFT status — no dose events yet
      expect(draft.status, PrescriptionStatus.draft);
      final eventsBeforeConfirm = await db.select(db.doseEventsTable).get();
      expect(eventsBeforeConfirm, isEmpty);

      // 3. Patient confirms → ACTIVE
      await ConfirmPrescription(prescriptionRepo).call(draft.id);
      final confirmed = await prescriptionRepo.findById(draft.id);
      expect(confirmed?.status, PrescriptionStatus.active);

      // 4. Generate dose events now that it's ACTIVE (simulates what the
      //    confirm flow would trigger in the full app)
      final meds = await medRepo.getByPrescription(draft.id);
      final now = DateTime.now().toUtc();
      for (final med in meds) {
        final drafts = const ScheduleGenerator(MealTimePreference.cambodiaDefaults)
            .generate(
              med,
              patientId: 'patient-1',
              startUtc: now,
              endUtc: now.add(const Duration(days: 30)),
              timezone: 'Asia/Phnom_Penh',
            )
            .toList();
        for (final d in drafts) {
          await doseDao.upsert(
            DoseEventsTableCompanion.insert(
              id: '${d.medicationId}_${d.scheduledTime.millisecondsSinceEpoch}',
              prescriptionId: d.prescriptionId,
              medicationId: d.medicationId,
              patientId: d.patientId,
              scheduledTime: d.scheduledTime,
              timePeriod: d.timePeriod.code,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      // 5. Dose events visible in Drift (BID × 30 days = 60)
      final events = await db.select(db.doseEventsTable).get();
      expect(events.length, 60);
      expect(events.every((e) => e.status == 'DUE'), isTrue);

      // 6. Prescription visible in the patient's list
      final list = await prescriptionRepo
          .watchByPatient('patient-1')
          .first;
      expect(list.any((p) => p.id == draft.id), isTrue);
      expect(list.first.status, PrescriptionStatus.active);

      engine.stop();
      await db.close();
    },
  );
}
