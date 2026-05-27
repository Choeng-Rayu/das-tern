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

AppDatabase _db() => AppDatabase(NativeDatabase.memory());

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        return DynamicLibrary.open('libsqlite3.so.0');
      });
    }
  });

  group('CreatePrescription use case', () {
    late AppDatabase db;
    late PrescriptionRepositoryImpl prescriptionRepo;
    late MedicationRepositoryImpl medRepo;
    late SyncEngine engine;

    setUp(() {
      db = _db();
      engine = SyncEngine(db: db);
      prescriptionRepo = PrescriptionRepositoryImpl(db: db, sync: engine);
      medRepo = MedicationRepositoryImpl(db: db, sync: engine);
    });

    tearDown(() {
      engine.stop();
      db.close();
    });

    test('creates prescription and version in Drift', () async {
      final useCase = CreatePrescription(
        prescriptionRepo,
        medRepo,
        const ScheduleGenerator(MealTimePreference.cambodiaDefaults),
        DoseEventsDao(db),
        engine,
      );

      final p = await useCase(
        const PrescriptionDraft(
          patientId: 'p1',
          patientName: 'Test',
          patientGender: Gender.male,
          patientAge: 30,
          symptoms: 'Fever',
          medications: <Map<String, dynamic>>[],
          patientTimezone: 'Asia/Phnom_Penh',
        ),
      );

      expect(p.patientName, 'Test');
      expect(p.status, PrescriptionStatus.active);

      // Version 1 should exist
      final versions = await db.select(db.prescriptionVersionsTable).get();
      expect(versions.length, 1);
      expect(versions.first.versionNumber, 1);
    });

    test('creates dose events for active prescription with medications', () async {
      final useCase = CreatePrescription(
        prescriptionRepo,
        medRepo,
        const ScheduleGenerator(MealTimePreference.cambodiaDefaults),
        DoseEventsDao(db),
        engine,
      );

      await useCase(
        const PrescriptionDraft(
          patientId: 'p1',
          patientName: 'Test',
          patientGender: Gender.male,
          patientAge: 30,
          symptoms: 'Cough',
          medications: <Map<String, dynamic>>[
            <String, dynamic>{
              'medicine_name': 'Paracetamol',
              'medicine_type': 'ORAL',
              'unit': 'TABLET',
              'dosage_amount': 1.0,
              'is_prn': false,
              'before_meal': false,
              'morning_dosage': '{"amount":1,"unit":"TABLET"}',
            },
          ],
          patientTimezone: 'Asia/Phnom_Penh',
        ),
      );

      final events = await db.select(db.doseEventsTable).get();
      // 30 days × 1 slot = 30 events
      expect(events.length, 30);
    });

    test('doctor prescription starts as DRAFT', () async {
      final useCase = CreatePrescription(
        prescriptionRepo,
        medRepo,
        const ScheduleGenerator(MealTimePreference.cambodiaDefaults),
        DoseEventsDao(db),
        engine,
      );

      final p = await useCase(
        const PrescriptionDraft(
          patientId: 'p1',
          patientName: 'Test',
          patientGender: Gender.male,
          patientAge: 30,
          symptoms: 'Fever',
          doctorId: 'doc1',
          medications: <Map<String, dynamic>>[],
          patientTimezone: 'Asia/Phnom_Penh',
        ),
      );

      expect(p.status, PrescriptionStatus.draft);
    });
  });

  group('Lifecycle use cases', () {
    late AppDatabase db;
    late PrescriptionRepositoryImpl repo;
    late SyncEngine engine;

    setUp(() {
      db = _db();
      engine = SyncEngine(db: db);
      repo = PrescriptionRepositoryImpl(db: db, sync: engine);
    });

    tearDown(() {
      engine.stop();
      db.close();
    });

    Future<void> insertRx(String id, PrescriptionStatus status) =>
        repo.insert(<String, dynamic>{
          'id': id,
          'patient_id': 'p1',
          'patient_name': 'Test',
          'patient_gender': 'MALE',
          'patient_age': 30,
          'symptoms': 'Test',
          'status': status.code,
          'current_version': 1,
          'is_urgent': false,
        });

    test('PausePrescription sets status to PAUSED', () async {
      await insertRx('rx1', PrescriptionStatus.active);
      await PausePrescription(repo).call('rx1');
      final p = await repo.findById('rx1');
      expect(p?.status, PrescriptionStatus.paused);
    });

    test('ResumePrescription sets status to ACTIVE', () async {
      await insertRx('rx2', PrescriptionStatus.paused);
      await ResumePrescription(repo).call('rx2');
      final p = await repo.findById('rx2');
      expect(p?.status, PrescriptionStatus.active);
    });

    test('StopPrescription sets status to INACTIVE', () async {
      await insertRx('rx3', PrescriptionStatus.active);
      await StopPrescription(repo).call('rx3');
      final p = await repo.findById('rx3');
      expect(p?.status, PrescriptionStatus.inactive);
    });

    test('ConfirmPrescription sets DRAFT → ACTIVE', () async {
      await insertRx('rx4', PrescriptionStatus.draft);
      await ConfirmPrescription(repo).call('rx4');
      final p = await repo.findById('rx4');
      expect(p?.status, PrescriptionStatus.active);
    });

    test('RejectPrescription sets DRAFT → INACTIVE', () async {
      await insertRx('rx5', PrescriptionStatus.draft);
      await RejectPrescription(repo).call('rx5');
      final p = await repo.findById('rx5');
      expect(p?.status, PrescriptionStatus.inactive);
    });
  });
}
