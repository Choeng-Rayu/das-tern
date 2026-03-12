import 'dart:async';

import 'package:das_tern/data/models/dose_event.dart';
import 'package:das_tern/data/models/enums.dart';

abstract class DoseService {
  Future<List<DoseEvent>> fetchTodaySchedule();
  Future<List<DoseEvent>> fetchDoseHistory({int page = 1, int limit = 20});
  Future<DoseEvent> markDoseTaken(String doseId);
  Future<DoseEvent> skipDose(String doseId, {String? reason});
}

class MockDoseService implements DoseService {
  final List<DoseEvent> _todayDoses = [
    DoseEvent(
      id: 'dose-1',
      prescriptionId: 'rx-1',
      medicationId: 'med-1',
      patientId: 'user-1',
      scheduledTime: DateTime.now().copyWith(hour: 8, minute: 0),
      timePeriod: 'Morning',
      medicationName: 'Metformin',
      dosage: '500mg',
      status: DoseEventStatus.due,
    ),
    DoseEvent(
      id: 'dose-2',
      prescriptionId: 'rx-1',
      medicationId: 'med-2',
      patientId: 'user-1',
      scheduledTime: DateTime.now().copyWith(hour: 13, minute: 0),
      timePeriod: 'Afternoon',
      medicationName: 'Amlodipine',
      dosage: '5mg',
      status: DoseEventStatus.due,
    ),
    DoseEvent(
      id: 'dose-3',
      prescriptionId: 'rx-1',
      medicationId: 'med-1',
      patientId: 'user-1',
      scheduledTime: DateTime.now().copyWith(hour: 20, minute: 0),
      timePeriod: 'Night',
      medicationName: 'Metformin',
      dosage: '500mg',
      status: DoseEventStatus.due,
    ),
  ];

  @override
  Future<List<DoseEvent>> fetchTodaySchedule() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<DoseEvent>.unmodifiable(_todayDoses);
  }

  @override
  Future<List<DoseEvent>> fetchDoseHistory({
    int page = 1,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const <DoseEvent>[];
  }

  @override
  Future<DoseEvent> markDoseTaken(String doseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _todayDoses.indexWhere((d) => d.id == doseId);
    if (index >= 0) {
      _todayDoses[index] = _todayDoses[index].copyWith(
        status: DoseEventStatus.takenOnTime,
        takenAt: DateTime.now(),
      );
      return _todayDoses[index];
    }
    throw Exception('Dose not found');
  }

  @override
  Future<DoseEvent> skipDose(String doseId, {String? reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _todayDoses.indexWhere((d) => d.id == doseId);
    if (index >= 0) {
      _todayDoses[index] = _todayDoses[index].copyWith(
        status: DoseEventStatus.skipped,
        skipReason: reason,
      );
      return _todayDoses[index];
    }
    throw Exception('Dose not found');
  }
}
