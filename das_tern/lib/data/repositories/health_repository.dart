import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/models/health_vital.dart';
import 'package:das_tern/data/services/health_service.dart';

abstract class HealthRepository {
  Future<List<HealthVital>> getLatestVitals();
  Future<List<HealthVital>> getVitals({VitalType? type});
  Future<HealthVital> recordVital(HealthVital vital);
  Future<void> deleteVital(String id);
  Future<List<HealthAlert>> getAlerts();
  Future<void> resolveAlert(String id);
  Future<List<VitalThreshold>> getThresholds();
}

class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl({required HealthService service}) : _service = service;

  final HealthService _service;

  @override
  Future<List<HealthVital>> getLatestVitals() => _service.fetchLatestVitals();

  @override
  Future<List<HealthVital>> getVitals({VitalType? type}) =>
      _service.fetchVitals(type: type);

  @override
  Future<HealthVital> recordVital(HealthVital vital) =>
      _service.recordVital(vital);

  @override
  Future<void> deleteVital(String id) => _service.deleteVital(id);

  @override
  Future<List<HealthAlert>> getAlerts() => _service.fetchAlerts();

  @override
  Future<void> resolveAlert(String id) => _service.resolveAlert(id);

  @override
  Future<List<VitalThreshold>> getThresholds() => _service.fetchThresholds();
}
