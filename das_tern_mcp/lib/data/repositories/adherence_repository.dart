import '../services/adherence_service.dart';

abstract class AdherenceRepository {
  Future<Map<String, dynamic>> fetchTodayAdherence();
  Future<Map<String, dynamic>> fetchWeeklyAdherence();
  Future<Map<String, dynamic>> fetchMonthlyAdherence();
  Future<Map<String, dynamic>> fetchAdherenceTrends({int days = 30});
  Future<({
    Map<String, dynamic> today,
    Map<String, dynamic> weekly,
    Map<String, dynamic> monthly,
  })>
  fetchAllAdherence();
}

class AdherenceRepositoryImpl implements AdherenceRepository {
  AdherenceRepositoryImpl({required AdherenceService adherenceService})
    : _adherenceService = adherenceService;

  final AdherenceService _adherenceService;

  @override
  Future<Map<String, dynamic>> fetchTodayAdherence() {
    return _adherenceService.getTodayAdherence();
  }

  @override
  Future<Map<String, dynamic>> fetchWeeklyAdherence() {
    return _adherenceService.getWeeklyAdherence();
  }

  @override
  Future<Map<String, dynamic>> fetchMonthlyAdherence() {
    return _adherenceService.getMonthlyAdherence();
  }

  @override
  Future<Map<String, dynamic>> fetchAdherenceTrends({int days = 30}) {
    return _adherenceService.getAdherenceTrends(days: days);
  }

  @override
  Future<({
    Map<String, dynamic> today,
    Map<String, dynamic> weekly,
    Map<String, dynamic> monthly,
  })>
  fetchAllAdherence() async {
    final futures = await Future.wait<Map<String, dynamic>>([
      fetchTodayAdherence(),
      fetchWeeklyAdherence(),
      fetchMonthlyAdherence(),
    ]);

    return (
      today: futures[0],
      weekly: futures[1],
      monthly: futures[2],
    );
  }
}
