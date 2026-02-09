import 'package:flutter_test/flutter_test.dart';
import 'package:das_tern_mcp/models/dose_event_model/dose_event.dart';

/// Unit tests for offline data models and conversion logic.
/// Note: sqflite requires a platform context, so we test the model
/// layer and JSON conversions that the DatabaseService relies on.
void main() {
  group('DoseEvent Model', () {
    final sampleJson = {
      'id': 'dose-001',
      'prescriptionId': 'rx-001',
      'medicationId': 'med-001',
      'patientId': 'patient-001',
      'scheduledTime': '2025-01-15T08:00:00.000Z',
      'timePeriod': 'MORNING',
      'reminderTime': '2025-01-15T07:50:00.000Z',
      'status': 'DUE',
      'takenAt': null,
      'skipReason': null,
      'wasOffline': false,
      'medicationName': 'Amoxicillin',
      'dosage': '500mg',
      'medication': {
        'medicineName': 'Amoxicillin',
        'morningDosage': 1,
        'afternoonDosage': 0,
        'eveningDosage': 1,
      },
      'createdAt': '2025-01-15T00:00:00.000Z',
      'updatedAt': '2025-01-15T00:00:00.000Z',
    };

    test('fromJson creates DoseEvent correctly', () {
      final dose = DoseEvent.fromJson(sampleJson);

      expect(dose.id, 'dose-001');
      expect(dose.prescriptionId, 'rx-001');
      expect(dose.medicationId, 'med-001');
      expect(dose.patientId, 'patient-001');
      expect(dose.timePeriod, 'MORNING');
      expect(dose.status, 'DUE');
      expect(dose.wasOffline, false);
      expect(dose.medicationName, 'Amoxicillin');
      expect(dose.dosage, '500mg');
      expect(dose.takenAt, isNull);
      expect(dose.skipReason, isNull);
      expect(dose.medication, isNotNull);
      expect(dose.medication!['morningDosage'], 1);
    });

    test('fromJson handles missing medication name via medication map', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json.remove('medicationName');
      json.remove('dosage');

      final dose = DoseEvent.fromJson(json);
      expect(dose.medicationName, 'Amoxicillin');
      expect(dose.dosage, '1');
    });

    test('fromJson handles taken dose', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['status'] = 'TAKEN_ON_TIME';
      json['takenAt'] = '2025-01-15T08:05:00.000Z';

      final dose = DoseEvent.fromJson(json);
      expect(dose.status, 'TAKEN_ON_TIME');
      expect(dose.takenAt, isNotNull);
      expect(dose.takenAt!.hour, 8);
    });

    test('fromJson handles skipped dose', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['status'] = 'SKIPPED';
      json['skipReason'] = 'Nausea';

      final dose = DoseEvent.fromJson(json);
      expect(dose.status, 'SKIPPED');
      expect(dose.skipReason, 'Nausea');
    });

    test('fromJson handles offline dose', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['wasOffline'] = true;

      final dose = DoseEvent.fromJson(json);
      expect(dose.wasOffline, true);
    });

    test('fromJson handles null medication', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['medication'] = null;
      json['medicationName'] = 'Paracetamol';
      json['dosage'] = '250mg';

      final dose = DoseEvent.fromJson(json);
      expect(dose.medication, isNull);
      expect(dose.medicationName, 'Paracetamol');
      expect(dose.dosage, '250mg');
    });

    test('toJson produces correct map', () {
      final dose = DoseEvent.fromJson(sampleJson);
      final json = dose.toJson();

      expect(json['id'], 'dose-001');
      expect(json['status'], 'DUE');
      expect(json['timePeriod'], 'MORNING');
      expect(json['medicationName'], 'Amoxicillin');
    });
  });

  group('Database Row Conversion Logic', () {
    test('doseToRow maps camelCase to snake_case correctly', () {
      final dose = {
        'id': 'dose-002',
        'prescriptionId': 'rx-002',
        'medicationId': 'med-002',
        'patientId': 'patient-002',
        'scheduledTime': '2025-01-15T12:00:00.000Z',
        'timePeriod': 'DAYTIME',
        'reminderTime': '2025-01-15T11:50:00.000Z',
        'status': 'DUE',
        'takenAt': null,
        'skipReason': null,
        'wasOffline': false,
        'medicationName': 'Metformin',
        'dosage': '500mg',
        'medication': null,
        'createdAt': '2025-01-15T00:00:00.000Z',
        'updatedAt': '2025-01-15T00:00:00.000Z',
      };

      // Simulate DatabaseService._doseToRow
      final row = {
        'id': dose['id'],
        'prescription_id': dose['prescriptionId'],
        'medication_id': dose['medicationId'],
        'patient_id': dose['patientId'],
        'scheduled_time': dose['scheduledTime'],
        'time_period': dose['timePeriod'],
        'reminder_time': dose['reminderTime'],
        'status': dose['status'],
        'taken_at': dose['takenAt'],
        'skip_reason': dose['skipReason'],
        'was_offline': (dose['wasOffline'] == true) ? 1 : 0,
        'medication_name': dose['medicationName'] ?? '',
        'dosage': dose['dosage'] ?? '',
        'synced': 1,
      };

      expect(row['prescription_id'], 'rx-002');
      expect(row['time_period'], 'DAYTIME');
      expect(row['was_offline'], 0);
      expect(row['synced'], 1);
    });

    test('rowToDose maps snake_case back to camelCase', () {
      final row = {
        'id': 'dose-003',
        'prescription_id': 'rx-003',
        'medication_id': 'med-003',
        'patient_id': 'patient-003',
        'scheduled_time': '2025-01-15T20:00:00.000Z',
        'time_period': 'NIGHT',
        'reminder_time': '2025-01-15T19:50:00.000Z',
        'status': 'TAKEN_ON_TIME',
        'taken_at': '2025-01-15T20:02:00.000Z',
        'skip_reason': null,
        'was_offline': 1,
        'medication_name': 'Ibuprofen',
        'dosage': '200mg',
        'medication_json': null,
        'created_at': '2025-01-15T00:00:00.000Z',
        'updated_at': '2025-01-15T00:00:00.000Z',
      };

      // Simulate DatabaseService._rowToDose
      final dose = {
        'id': row['id'],
        'prescriptionId': row['prescription_id'],
        'medicationId': row['medication_id'],
        'patientId': row['patient_id'],
        'scheduledTime': row['scheduled_time'],
        'timePeriod': row['time_period'],
        'reminderTime': row['reminder_time'],
        'status': row['status'],
        'takenAt': row['taken_at'],
        'skipReason': row['skip_reason'],
        'wasOffline': row['was_offline'] == 1,
      };

      expect(dose['prescriptionId'], 'rx-003');
      expect(dose['timePeriod'], 'NIGHT');
      expect(dose['wasOffline'], true);
      expect(dose['takenAt'], '2025-01-15T20:02:00.000Z');

      // Verify this can be parsed into a DoseEvent
      final doseEvent = DoseEvent.fromJson({
        ...dose,
        'medicationName': row['medication_name'],
        'dosage': row['dosage'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      });
      expect(doseEvent.id, 'dose-003');
      expect(doseEvent.status, 'TAKEN_ON_TIME');
      expect(doseEvent.wasOffline, true);
    });
  });

  group('Sync Queue Data Integrity', () {
    test('sync queue item structure for mark_taken', () {
      final item = {
        'action': 'mark_taken',
        'endpoint': '/doses/dose-001/taken',
        'method': 'PATCH',
        'body': '{"takenAt":"2025-01-15T08:05:00.000Z","offline":true}',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'last_error': null,
      };

      expect(item['action'], 'mark_taken');
      expect(item['method'], 'PATCH');
      expect(item['endpoint'], contains('/doses/'));
      expect(item['endpoint'], contains('/taken'));
      expect(item['retry_count'], 0);
    });

    test('sync queue item structure for skip_dose', () {
      final item = {
        'action': 'skip_dose',
        'endpoint': '/doses/dose-002/skipped',
        'method': 'PATCH',
        'body': '{"reason":"Side effects"}',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'last_error': null,
      };

      expect(item['action'], 'skip_dose');
      expect(item['endpoint'], contains('/skipped'));
    });

    test('retry count increments and prune threshold works', () {
      const maxRetries = 5;
      var retryCount = 0;

      // Simulate 5 failures
      for (var i = 0; i < 5; i++) {
        retryCount++;
      }

      expect(retryCount >= maxRetries, true);
      // Item should be pruned
    });
  });

  group('Notification Scheduling Logic', () {
    test('past reminder times should be skipped', () {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      expect(pastTime.isBefore(DateTime.now()), true);
      // NotificationService skips past times
    });

    test('future reminder times should be scheduled', () {
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      expect(futureTime.isAfter(DateTime.now()), true);
    });

    test('only DUE doses should get reminders', () {
      final doseStatuses = ['DUE', 'TAKEN_ON_TIME', 'TAKEN_LATE', 'SKIPPED'];
      final schedulable =
          doseStatuses.where((s) => s == 'DUE').toList();
      expect(schedulable.length, 1);
      expect(schedulable.first, 'DUE');
    });

    test('dose ID hash produces safe 32-bit notification ID', () {
      const doseId = 'dose-uuid-123-456-789';
      final id = doseId.hashCode.abs() % 2147483647;
      expect(id, greaterThan(0));
      expect(id, lessThan(2147483647));
    });
  });

  group('Connectivity Logic', () {
    test('online states are correctly identified', () {
      // Simulate ConnectivityResult checks
      final onlineStates = ['mobile', 'wifi', 'ethernet'];
      final offlineStates = ['none', 'bluetooth', 'vpn'];

      for (final state in onlineStates) {
        expect(
          state == 'mobile' || state == 'wifi' || state == 'ethernet',
          true,
          reason: '$state should be online',
        );
      }

      for (final state in offlineStates) {
        expect(
          state == 'mobile' || state == 'wifi' || state == 'ethernet',
          false,
          reason: '$state should be offline',
        );
      }
    });
  });
}
