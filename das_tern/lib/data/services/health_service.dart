import 'dart:async';

import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/models/health_vital.dart';

abstract class HealthService {
  Future<List<HealthVital>> fetchLatestVitals();
  Future<List<HealthVital>> fetchVitals({VitalType? type});
  Future<HealthVital> recordVital(HealthVital vital);
  Future<void> deleteVital(String id);
  Future<List<HealthAlert>> fetchAlerts();
  Future<void> resolveAlert(String id);
  Future<List<VitalThreshold>> fetchThresholds();
}

class MockHealthService implements HealthService {
  final List<HealthVital> _vitals = [
    HealthVital(
      id: 'v-1',
      patientId: 'user-1',
      vitalType: VitalType.bloodPressure,
      value: 120,
      valueSecondary: 80,
      unit: 'mmHg',
      measuredAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    HealthVital(
      id: 'v-2',
      patientId: 'user-1',
      vitalType: VitalType.heartRate,
      value: 72,
      unit: 'bpm',
      measuredAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    HealthVital(
      id: 'v-3',
      patientId: 'user-1',
      vitalType: VitalType.glucose,
      value: 95,
      unit: 'mg/dL',
      measuredAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  @override
  Future<List<HealthVital>> fetchLatestVitals() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<HealthVital>.unmodifiable(_vitals);
  }

  @override
  Future<List<HealthVital>> fetchVitals({VitalType? type}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (type != null) {
      return _vitals.where((v) => v.vitalType == type).toList();
    }
    return List<HealthVital>.unmodifiable(_vitals);
  }

  @override
  Future<HealthVital> recordVital(HealthVital vital) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _vitals.insert(0, vital);
    return vital;
  }

  @override
  Future<void> deleteVital(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _vitals.removeWhere((v) => v.id == id);
  }

  @override
  Future<List<HealthAlert>> fetchAlerts() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const <HealthAlert>[];
  }

  @override
  Future<void> resolveAlert(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<VitalThreshold>> fetchThresholds() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const <VitalThreshold>[];
  }
}
