import 'dart:ffi';
import 'dart:io';

import 'package:dastern/core/storage/drift/app_database.dart';
import 'package:dastern/core/storage/drift/daos/outbox_dao.dart';
import 'package:dastern/core/sync/sync_engine.dart';
import 'package:dastern/features/prescriptions/data/prescription_repository.dart';
import 'package:dastern/features/prescriptions/domain/prescription_enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

AppDatabase _db() => AppDatabase(NativeDatabase.memory());

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        return DynamicLibrary.open('libsqlite3.so.0');
      });
    }
  });

  group('Outbox round-trip: prescription create offline', () {
    late AppDatabase db;
    late OutboxDao outboxDao;
    final flushed = <String>[];

    setUp(() {
      db = _db();
      outboxDao = OutboxDao(db);
      flushed.clear();
    });

    tearDown(() => db.close());

    test('create prescription enqueues outbox entry', () async {
      final engine = SyncEngine(
        db: db,
        onFlush: (entry) async => flushed.add(entry.id),
      );

      final repo = PrescriptionRepositoryImpl(db: db, sync: engine);

      await repo.insert(<String, dynamic>{
        'id': 'rx-test-1',
        'patient_id': 'patient-1',
        'patient_name': 'Test Patient',
        'patient_gender': 'MALE',
        'patient_age': 30,
        'symptoms': 'Headache',
        'status': 'ACTIVE',
        'current_version': 1,
        'is_urgent': false,
      });

      // Outbox should have 1 entry
      final depth = await outboxDao.depth();
      expect(depth, 1);

      // Drift should have the row
      final row = await repo.findById('rx-test-1');
      expect(row, isNotNull);
      expect(row!.patientName, 'Test Patient');
    });

    test('drain flushes outbox and clears it', () async {
      final engine = SyncEngine(
        db: db,
        onFlush: (entry) async => flushed.add(entry.id),
      );

      final repo = PrescriptionRepositoryImpl(db: db, sync: engine);

      await repo.insert(<String, dynamic>{
        'id': 'rx-test-2',
        'patient_id': 'patient-1',
        'patient_name': 'Test Patient',
        'patient_gender': 'MALE',
        'patient_age': 30,
        'symptoms': 'Fever',
        'status': 'DRAFT',
        'current_version': 1,
        'is_urgent': false,
      });

      expect(await outboxDao.depth(), 1);

      // Simulate network restore → drain
      await engine.drainNow();

      expect(flushed.length, 1);
      expect(await outboxDao.depth(), 0);
    });

    test('status update enqueues a second outbox entry', () async {
      final engine = SyncEngine(
        db: db,
        onFlush: (entry) async => flushed.add(entry.id),
      );
      final repo = PrescriptionRepositoryImpl(db: db, sync: engine);

      await repo.insert(<String, dynamic>{
        'id': 'rx-test-3',
        'patient_id': 'patient-1',
        'patient_name': 'Test Patient',
        'patient_gender': 'MALE',
        'patient_age': 30,
        'symptoms': 'Cough',
        'status': 'DRAFT',
        'current_version': 1,
        'is_urgent': false,
      });

      await repo.updateStatus('rx-test-3', PrescriptionStatus.active);

      expect(await outboxDao.depth(), 2);

      await engine.drainNow();
      expect(flushed.length, 2);
      expect(await outboxDao.depth(), 0);
    });
  });
}
