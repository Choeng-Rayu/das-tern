import 'package:flutter/material.dart';
import '../models/dose_event_model/dose_event.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

/// Manages dose schedule and history state with offline support.
/// When offline, reads from SQLite and queues actions for sync.
class DoseProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notif = NotificationService.instance;
  final SyncService _sync = SyncService.instance;

  bool _isLoading = false;
  String? _error;
  List<DoseEvent> _todaysDoses = [];
  Map<String, List<DoseEvent>> _groupedDoses = {};
  List<DoseEvent> _history = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DoseEvent> get todaysDoses => _todaysDoses;
  Map<String, List<DoseEvent>> get groupedDoses => _groupedDoses;
  List<DoseEvent> get history => _history;

  int get totalDoses => _todaysDoses.length;
  int get takenDoses => _todaysDoses
      .where((d) =>
          d.status == 'TAKEN_ON_TIME' ||
          d.status == 'TAKEN_LATE')
      .length;
  double get progress => totalDoses > 0 ? takenDoses / totalDoses : 0;

  /// Fetch today's dose schedule.
  /// Online → API + cache to SQLite + schedule notifications.
  /// Offline → load from SQLite cache.
  Future<void> fetchTodaySchedule() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      if (_sync.isOnline) {
        // Online: fetch from API
        final result =
            await _api.getDoseSchedule(date: today, groupBy: 'timePeriod');
        if (result['doses'] != null) {
          final doseList = List<Map<String, dynamic>>.from(result['doses']);
          // Cache in SQLite
          await _db.cacheDoseEvents(doseList);
          // Schedule local notifications
          await _notif.scheduleAllReminders(doseList);
          _todaysDoses =
              doseList.map((d) => DoseEvent.fromJson(d)).toList();
        }
        if (result['grouped'] != null) {
          _groupedDoses =
              (result['grouped'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key,
              (value as List).map((d) => DoseEvent.fromJson(d)).toList(),
            ),
          );
        }
      } else {
        // Offline: load from SQLite
        final cached = await _db.getCachedDosesByDate(today);
        _todaysDoses =
            cached.map((d) => DoseEvent.fromJson(d)).toList();
        // Group by timePeriod
        _groupedDoses = {};
        for (final dose in _todaysDoses) {
          _groupedDoses
              .putIfAbsent(dose.timePeriod, () => [])
              .add(dose);
        }
        // Schedule notifications from cache
        await _notif.scheduleAllReminders(cached);
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      // Fallback to cache on API error
      try {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final cached = await _db.getCachedDosesByDate(today);
        if (cached.isNotEmpty) {
          _todaysDoses =
              cached.map((d) => DoseEvent.fromJson(d)).toList();
          _error = null; // cleared – we have cached data
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch dose history for a date range.
  Future<void> fetchHistory({String? startDate, String? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getDoseHistory(
        startDate: startDate,
        endDate: endDate,
      );
      _history = result.map((d) => DoseEvent.fromJson(d)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a dose as taken (works offline).
  Future<bool> markTaken(String doseId) async {
    try {
      final now = DateTime.now();

      if (_sync.isOnline) {
        await _api.markDoseTaken(doseId, takenAt: now);
      } else {
        // Save locally and queue for sync
        await _db.markDoseTakenLocally(doseId, now);
        await _db.addToSyncQueue(
          action: 'mark_taken',
          endpoint: '/doses/$doseId/taken',
          method: 'PATCH',
          body: {'takenAt': now.toIso8601String(), 'offline': true},
        );
      }

      // Cancel the reminder for this dose
      await _notif.cancelReminder(doseId);

      // Re-fetch schedule
      await fetchTodaySchedule();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Skip a dose with a reason (works offline).
  Future<bool> skipDose(String doseId, String reason) async {
    try {
      if (_sync.isOnline) {
        await _api.skipDose(doseId, reason);
      } else {
        await _db.skipDoseLocally(doseId, reason);
        await _db.addToSyncQueue(
          action: 'skip_dose',
          endpoint: '/doses/$doseId/skipped',
          method: 'PATCH',
          body: {'reason': reason},
        );
      }

      await _notif.cancelReminder(doseId);
      await fetchTodaySchedule();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
