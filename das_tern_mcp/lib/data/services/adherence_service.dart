import '../../services/api_service.dart';

/// Thin service wrapper for adherence API calls.
class AdherenceService {
  AdherenceService({required ApiService apiService}) : _apiService = apiService;

  final ApiService _apiService;

  Future<Map<String, dynamic>> getTodayAdherence() {
    return _apiService.getTodayAdherence();
  }

  Future<Map<String, dynamic>> getWeeklyAdherence() {
    return _apiService.getWeeklyAdherence();
  }

  Future<Map<String, dynamic>> getMonthlyAdherence() {
    return _apiService.getMonthlyAdherence();
  }

  Future<Map<String, dynamic>> getAdherenceTrends({int days = 30}) {
    return _apiService.getAdherenceTrends(days: days);
  }
}
