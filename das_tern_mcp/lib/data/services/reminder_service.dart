/// Thin wrapper around [ApiService] for dose/reminder endpoints.
library;

import '../../services/api_service.dart';

/// Service for reminder (dose schedule) HTTP calls.
///
/// The backend models reminders as *dose events* under `/doses`.
class ReminderService {
  ReminderService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  /// Fetches today's dose schedule for the current patient.
  ///
  /// Returns a map with `schedule` keyed by period, plus metadata.
  Future<Map<String, dynamic>> getTodayReminders() {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return _api.getDoseSchedule(date: dateStr);
  }

  /// Marks the dose identified by [id] as taken at the current time.
  Future<Map<String, dynamic>> markReminderTaken(String id) {
    return _api.markDoseTaken(id, takenAt: DateTime.now());
  }

  /// Fetches upcoming (future) dose events.
  ///
  /// Uses the dose history endpoint filtered to the next 7 days as a proxy
  /// for upcoming reminders; falls back to today's schedule if the filter
  /// is unavailable.
  Future<List<dynamic>> getUpcomingReminders() {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 7));
    return _api.getDoseHistory(
      startDate: now.toIso8601String(),
      endDate: end.toIso8601String(),
    );
  }
}
