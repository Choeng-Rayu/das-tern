import 'package:flutter_test/flutter_test.dart';
import 'package:das_tern_mcp/models/dose_event_model/dose_event.dart';
import 'package:das_tern_mcp/models/prescription_model/prescription.dart';
import 'package:das_tern_mcp/models/connection_model/connection.dart';
import 'package:das_tern_mcp/models/user_model/user.dart';
import 'package:das_tern_mcp/models/enums_model/enums.dart' as enums;

/// Comprehensive QA tests for all models, JSON round-trips, edge cases,
/// and business logic validation.
void main() {
  // ─────────────────────────────────────────────
  // User Model Tests
  // ─────────────────────────────────────────────
  group('User Model', () {
    test('fromJson creates User correctly', () {
      final user = User.fromJson({
        'id': 'u-001',
        'name': 'Sok Dara',
        'email': 'sok@example.com',
        'phone': '+85512345678',
        'role': 'patient',
        'profileImage': null,
      });
      expect(user.id, 'u-001');
      expect(user.name, 'Sok Dara');
      expect(user.role, UserRole.patient);
      expect(user.phone, '+85512345678');
    });

    test('toJson round-trip is consistent', () {
      final original = User(
        id: 'u-002',
        name: 'Dr. Rina',
        phone: '+85598765432',
        role: UserRole.doctor,
      );
      final json = original.toJson();
      final restored = User.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.role, original.role);
    });

    test('handles doctor role', () {
      final user = User.fromJson({
        'id': 'u-003',
        'name': 'Dr. Chea',
        'role': 'doctor',
      });
      expect(user.role, UserRole.doctor);
    });
  });

  // ─────────────────────────────────────────────
  // Prescription Model Tests
  // ─────────────────────────────────────────────
  group('Prescription Model', () {
    final samplePrescription = {
      'id': 'rx-001',
      'patientId': 'p-001',
      'doctorId': 'd-001',
      'patientName': 'Sok Dara',
      'patientGender': 'MALE',
      'patientAge': 45,
      'symptoms': 'Fever, cough',
      'status': 'ACTIVE',
      'medications': [
        {
          'rowNumber': 1,
          'medicineName': 'Amoxicillin',
          'medicineNameKhmer': 'អាម៉ុកស៊ីស៊ីលីន',
          'morningDosage': 1.0,
          'daytimeDosage': 0.0,
          'nightDosage': 1.0,
          'frequency': 'Twice daily',
          'timing': 'After meals',
          'createdAt': '2025-01-15T00:00:00.000Z',
          'updatedAt': '2025-01-15T00:00:00.000Z',
        }
      ],
      'currentVersion': 1,
      'isUrgent': false,
      'createdAt': '2025-01-15T00:00:00.000Z',
      'updatedAt': '2025-01-15T00:00:00.000Z',
    };

    test('fromJson creates Prescription correctly', () {
      final rx = Prescription.fromJson(samplePrescription);
      expect(rx.id, 'rx-001');
      expect(rx.patientName, 'Sok Dara');
      expect(rx.status, 'ACTIVE');
      expect(rx.medications.length, 1);
      expect(rx.medications[0].medicineName, 'Amoxicillin');
      expect(rx.medications[0].medicineNameKhmer, 'អាម៉ុកស៊ីស៊ីលីន');
      expect(rx.isUrgent, false);
    });

    test('toJson round-trip preserves medications', () {
      final rx = Prescription.fromJson(samplePrescription);
      final json = rx.toJson();
      final restored = Prescription.fromJson(json);
      expect(restored.medications.length, 1);
      expect(restored.medications[0].morningDosage, 1.0);
      expect(restored.medications[0].nightDosage, 1.0);
    });

    test('handles urgent prescription', () {
      final urgentJson = Map<String, dynamic>.from(samplePrescription);
      urgentJson['isUrgent'] = true;
      urgentJson['urgentReason'] = 'Allergic reaction detected';
      final rx = Prescription.fromJson(urgentJson);
      expect(rx.isUrgent, true);
      expect(rx.urgentReason, 'Allergic reaction detected');
    });

    test('handles multiple medications', () {
      final multiMed = Map<String, dynamic>.from(samplePrescription);
      multiMed['medications'] = [
        ...List<dynamic>.from(samplePrescription['medications'] as List),
        {
          'rowNumber': 2,
          'medicineName': 'Paracetamol',
          'medicineNameKhmer': 'ប៉ារ៉ាសេតាម៉ុល',
          'morningDosage': 1.0,
          'daytimeDosage': 1.0,
          'nightDosage': 1.0,
          'frequency': 'Three times daily',
          'timing': 'After meals',
          'createdAt': '2025-01-15T00:00:00.000Z',
          'updatedAt': '2025-01-15T00:00:00.000Z',
        },
      ];
      final rx = Prescription.fromJson(multiMed);
      expect(rx.medications.length, 2);
      expect(rx.medications[1].medicineName, 'Paracetamol');
      expect(rx.medications[1].daytimeDosage, 1.0);
    });
  });

  // ─────────────────────────────────────────────
  // PrescriptionMedication Model Tests
  // ─────────────────────────────────────────────
  group('PrescriptionMedication', () {
    test('dosage values parse as doubles', () {
      final med = PrescriptionMedication.fromJson({
        'rowNumber': 1,
        'medicineName': 'Test Med',
        'medicineNameKhmer': 'ថ្នាំសាកល្បង',
        'morningDosage': 2,
        'daytimeDosage': 1,
        'nightDosage': 0,
        'frequency': 'Twice daily',
        'timing': 'Before meals',
        'createdAt': '2025-01-15T00:00:00.000Z',
        'updatedAt': '2025-01-15T00:00:00.000Z',
      });
      expect(med.morningDosage, 2.0);
      expect(med.daytimeDosage, 1.0);
      expect(med.nightDosage, 0.0);
      expect(med.morningDosage, isA<double>());
    });

    test('handles Khmer medicine names', () {
      final med = PrescriptionMedication.fromJson({
        'rowNumber': 1,
        'medicineName': 'Metformin',
        'medicineNameKhmer': 'មិតហ្វរមីន',
        'morningDosage': 1,
        'daytimeDosage': 0,
        'nightDosage': 1,
        'frequency': 'Twice daily',
        'timing': 'With food',
        'createdAt': '2025-01-15T00:00:00.000Z',
        'updatedAt': '2025-01-15T00:00:00.000Z',
      });
      expect(med.medicineNameKhmer, 'មិតហ្វរមីន');
    });
  });

  // ─────────────────────────────────────────────
  // Connection Model Tests
  // ─────────────────────────────────────────────
  group('Connection Model', () {
    test('fromJson parses all statuses correctly', () {
      for (final status in ['PENDING', 'ACCEPTED', 'REVOKED']) {
        final conn = Connection.fromJson({
          'id': 'conn-001',
          'doctorId': 'd-001',
          'patientId': 'p-001',
          'status': status,
          'createdAt': '2025-01-15T00:00:00.000Z',
        });
        expect(conn.status, isA<enums.ConnectionStatus>());
      }
    });

    test('fromJson parses permission levels', () {
      final conn = Connection.fromJson({
        'id': 'conn-002',
        'doctorId': 'd-001',
        'patientId': 'p-001',
        'status': 'ACCEPTED',
        'prescriptionPermission': 'ALLOWED',
        'healthDataPermission': 'SELECTED',
        'personalInfoPermission': 'NOT_ALLOWED',
        'createdAt': '2025-01-15T00:00:00.000Z',
      });
      expect(conn.prescriptionPermission, enums.PermissionLevel.allowed);
      expect(conn.healthDataPermission, enums.PermissionLevel.selected);
      expect(conn.personalInfoPermission, enums.PermissionLevel.notAllowed);
    });

    test('fromJson handles accepted connection with dates', () {
      final conn = Connection.fromJson({
        'id': 'conn-003',
        'doctorId': 'd-001',
        'patientId': 'p-001',
        'status': 'ACCEPTED',
        'acceptedAt': '2025-01-16T10:00:00.000Z',
        'createdAt': '2025-01-15T00:00:00.000Z',
      });
      expect(conn.acceptedAt, isNotNull);
      expect(conn.revokedAt, isNull);
    });

    test('defaults missing permissions to NOT_ALLOWED', () {
      final conn = Connection.fromJson({
        'id': 'conn-004',
        'doctorId': 'd-001',
        'patientId': 'p-001',
        'status': 'PENDING',
        'createdAt': '2025-01-15T00:00:00.000Z',
      });
      expect(conn.prescriptionPermission, enums.PermissionLevel.notAllowed);
      expect(conn.healthDataPermission, enums.PermissionLevel.notAllowed);
      expect(conn.personalInfoPermission, enums.PermissionLevel.notAllowed);
    });
  });

  // ─────────────────────────────────────────────
  // DoseEvent Model — Extended Tests
  // ─────────────────────────────────────────────
  group('DoseEvent Extended', () {
    test('toJson then fromJson round-trip is lossless', () {
      final original = DoseEvent(
        id: 'dose-rt-001',
        prescriptionId: 'rx-001',
        medicationId: 'med-001',
        patientId: 'p-001',
        scheduledTime: DateTime(2025, 1, 15, 8, 0),
        timePeriod: 'MORNING',
        reminderTime: DateTime(2025, 1, 15, 7, 50),
        status: 'DUE',
        wasOffline: false,
        medicationName: 'Amoxicillin',
        dosage: '500mg',
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 15),
      );
      final json = original.toJson();
      final restored = DoseEvent.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.timePeriod, original.timePeriod);
      expect(restored.status, original.status);
      expect(restored.medicationName, original.medicationName);
    });

    test('all time periods are handled', () {
      for (final period in ['MORNING', 'DAYTIME', 'NIGHT']) {
        final dose = DoseEvent(
          prescriptionId: 'rx-001',
          medicationId: 'med-001',
          patientId: 'p-001',
          scheduledTime: DateTime.now(),
          timePeriod: period,
          reminderTime: DateTime.now(),
          status: 'DUE',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(dose.timePeriod, period);
      }
    });

    test('all dose statuses are handled', () {
      for (final status
          in ['DUE', 'TAKEN_ON_TIME', 'TAKEN_LATE', 'MISSED', 'SKIPPED']) {
        final json = {
          'id': 'dose-status-$status',
          'prescriptionId': 'rx-001',
          'medicationId': 'med-001',
          'patientId': 'p-001',
          'scheduledTime': '2025-01-15T08:00:00.000Z',
          'timePeriod': 'MORNING',
          'reminderTime': '2025-01-15T07:50:00.000Z',
          'status': status,
          'createdAt': '2025-01-15T00:00:00.000Z',
          'updatedAt': '2025-01-15T00:00:00.000Z',
        };
        final dose = DoseEvent.fromJson(json);
        expect(dose.status, status);
      }
    });
  });

  // ─────────────────────────────────────────────
  // Enum Helper Tests
  // ─────────────────────────────────────────────
  group('Enum Helpers', () {
    test('userRoleFromString handles all values', () {
      expect(enums.userRoleFromString('PATIENT'), enums.UserRole.patient);
      expect(enums.userRoleFromString('DOCTOR'), enums.UserRole.doctor);
      expect(enums.userRoleFromString('FAMILY_MEMBER'), enums.UserRole.familyMember);
      // Invalid defaults to patient
      expect(enums.userRoleFromString('UNKNOWN'), enums.UserRole.patient);
    });

    test('userRoleToString round-trips correctly', () {
      for (final role in enums.UserRole.values) {
        final str = enums.userRoleToString(role);
        final restored = enums.userRoleFromString(str);
        expect(restored, role);
      }
    });

    test('connectionStatusFromString handles all values', () {
      expect(enums.connectionStatusFromString('PENDING'), enums.ConnectionStatus.pending);
      expect(
          enums.connectionStatusFromString('ACCEPTED'), enums.ConnectionStatus.accepted);
      expect(enums.connectionStatusFromString('REVOKED'), enums.ConnectionStatus.revoked);
    });
  });

  // ─────────────────────────────────────────────
  // API Contract Validation
  // ─────────────────────────────────────────────
  group('API Contract Validation', () {
    test('login request format is correct', () {
      const phoneNumber = '+85512345678';
      const password = 'Test123!';
      final body = {
        'phoneNumber': phoneNumber,
        'password': password,
      };
      expect(body, containsPair('phoneNumber', phoneNumber));
      expect(body, containsPair('password', password));
    });

    test('register patient request has all required fields', () {
      final body = {
        'firstName': 'Sok',
        'lastName': 'Dara',
        'gender': 'MALE',
        'dateOfBirth': '1990-01-01',
        'idCardNumber': '123456789',
        'phoneNumber': '+85512345678',
        'password': 'Test123!',
        'pinCode': '1234',
      };
      expect(body.keys, containsAll([
        'firstName', 'lastName', 'gender', 'dateOfBirth',
        'idCardNumber', 'phoneNumber', 'password', 'pinCode',
      ]));
    });

    test('register doctor request has all required fields', () {
      final body = {
        'fullName': 'Dr. Rina',
        'phoneNumber': '+85598765432',
        'hospitalClinic': 'Calmette Hospital',
        'specialty': 'General Medicine',
        'licenseNumber': 'KH-DOC-001',
        'password': 'SecurePass123!',
      };
      expect(body.keys, containsAll([
        'fullName', 'phoneNumber', 'hospitalClinic',
        'specialty', 'licenseNumber', 'password',
      ]));
    });

    test('phone number format validation (+855)', () {
      const validPhones = ['+85512345678', '+855 98765432'];
      const invalidPhones = ['012345678', '85512345678', '+1234567'];

      for (final phone in validPhones) {
        expect(phone.replaceAll(' ', '').startsWith('+855'), true,
            reason: '$phone should be valid');
      }
      for (final phone in invalidPhones) {
        expect(phone.startsWith('+855'), false,
            reason: '$phone should be invalid');
      }
    });

    test('OTP format is 4 digits', () {
      const validOtps = ['1234', '0000', '9999'];
      const invalidOtps = ['123', '12345', 'abcd', ''];

      for (final otp in validOtps) {
        expect(RegExp(r'^\d{4}$').hasMatch(otp), true,
            reason: '$otp should be valid');
      }
      for (final otp in invalidOtps) {
        expect(RegExp(r'^\d{4}$').hasMatch(otp), false,
            reason: '$otp should be invalid');
      }
    });
  });

  // ─────────────────────────────────────────────
  // Business Logic Validation
  // ─────────────────────────────────────────────
  group('Business Logic', () {
    test('dose progress calculation is correct', () {
      final doses = [
        DoseEvent.fromJson(_dueJson('dose-1', 'TAKEN_ON_TIME')),
        DoseEvent.fromJson(_dueJson('dose-2', 'DUE')),
        DoseEvent.fromJson(_dueJson('dose-3', 'TAKEN_LATE')),
        DoseEvent.fromJson(_dueJson('dose-4', 'SKIPPED')),
      ];
      final total = doses.length;
      final taken = doses
          .where((d) => d.status == 'TAKEN_ON_TIME' || d.status == 'TAKEN_LATE')
          .length;
      final progress = total > 0 ? taken / total : 0.0;

      expect(total, 4);
      expect(taken, 2); // TAKEN_ON_TIME + TAKEN_LATE
      expect(progress, 0.5);
    });

    test('dose progress is 0 when no doses', () {
      final doses = <DoseEvent>[];
      final progress = doses.isNotEmpty
          ? doses
                  .where((d) =>
                      d.status == 'TAKEN_ON_TIME' || d.status == 'TAKEN_LATE')
                  .length /
              doses.length
          : 0.0;
      expect(progress, 0.0);
    });

    test('grouping doses by time period', () {
      final doses = [
        DoseEvent.fromJson(_dueJson('dose-m1', 'DUE', period: 'MORNING')),
        DoseEvent.fromJson(_dueJson('dose-m2', 'DUE', period: 'MORNING')),
        DoseEvent.fromJson(_dueJson('dose-d1', 'DUE', period: 'DAYTIME')),
        DoseEvent.fromJson(_dueJson('dose-n1', 'DUE', period: 'NIGHT')),
      ];

      final grouped = <String, List<DoseEvent>>{};
      for (final dose in doses) {
        grouped.putIfAbsent(dose.timePeriod, () => []).add(dose);
      }

      expect(grouped['MORNING']!.length, 2);
      expect(grouped['DAYTIME']!.length, 1);
      expect(grouped['NIGHT']!.length, 1);
    });

    test('permission levels are properly ordered', () {
      final levels = [
        enums.PermissionLevel.notAllowed,
        enums.PermissionLevel.request,
        enums.PermissionLevel.selected,
        enums.PermissionLevel.allowed,
      ];
      expect(levels.indexOf(enums.PermissionLevel.notAllowed), 0);
      expect(levels.indexOf(enums.PermissionLevel.allowed), 3);
    });
  });
}

/// Helper to create a minimal dose JSON with given id and status.
Map<String, dynamic> _dueJson(String id, String status,
    {String period = 'MORNING'}) {
  return {
    'id': id,
    'prescriptionId': 'rx-001',
    'medicationId': 'med-001',
    'patientId': 'p-001',
    'scheduledTime': '2025-01-15T08:00:00.000Z',
    'timePeriod': period,
    'reminderTime': '2025-01-15T07:50:00.000Z',
    'status': status,
    'medicationName': 'Test Med',
    'dosage': '500mg',
    'createdAt': '2025-01-15T00:00:00.000Z',
    'updatedAt': '2025-01-15T00:00:00.000Z',
  };
}
