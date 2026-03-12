import 'package:das_tern/data/models/dose_event.dart';
import 'package:das_tern/data/services/dose_service.dart';

abstract class DoseRepository {
  Future<List<DoseEvent>> getTodaySchedule();
  Future<List<DoseEvent>> getDoseHistory({int page = 1, int limit = 20});
  Future<DoseEvent> markDoseTaken(String doseId);
  Future<DoseEvent> skipDose(String doseId, {String? reason});
}

class DoseRepositoryImpl implements DoseRepository {
  DoseRepositoryImpl({required DoseService service}) : _service = service;

  final DoseService _service;

  @override
  Future<List<DoseEvent>> getTodaySchedule() => _service.fetchTodaySchedule();

  @override
  Future<List<DoseEvent>> getDoseHistory({int page = 1, int limit = 20}) =>
      _service.fetchDoseHistory(page: page, limit: limit);

  @override
  Future<DoseEvent> markDoseTaken(String doseId) =>
      _service.markDoseTaken(doseId);

  @override
  Future<DoseEvent> skipDose(String doseId, {String? reason}) =>
      _service.skipDose(doseId, reason: reason);
}
