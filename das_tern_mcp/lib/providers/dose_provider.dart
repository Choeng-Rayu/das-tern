import 'package:flutter/material.dart';
import '../models/dose_event_model/dose_event.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../services/logger_service.dart';

/// Manages dose schedule and history state with offline support.
/// When offline, reads from SQLite and queues actions for sync.
class DoseProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notif = NotificationService.instance;
  final SyncService _sync = SyncService.instance;
  final LoggerService _log = LoggerService.instance;

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
      .where((d) => d.status == 'TAKEN_ON_TIME' || d.status == 'TAKEN_LATE')
      .length;
  double get progress => totalDoses > 0 ? takenDoses / totalDoses : 0;

  /// Fetch today's dose schedule.
  /// Online → API + cache to SQLite + schedule notifications.
  /// Offline → load from SQLite cache.
  Future<void> fetchTodaySchedule() async {
    _log.info('DoseProvider', 'Fetching today\'s schedule');
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      if (_sync.isOnline) {
        _log.debug('DoseProvider', 'Fetching from API (online)');
        // Online: fetch from API
        final result = await _api.getDoseSchedule(
          date: today,
          groupBy: 'timePeriod',
        );
        // Backend returns { date, dailyProgress, groups: [{period, doses}] }
        // when groupBy=timePeriod is used
        if (result['groups'] != null) {
          final groups = result['groups'] as List;
          // Flatten all doses for caching and notifications
          final allDoses = <Map<String, dynamic>>[];
          final grouped = <String, List<DoseEvent>>{};
          for (final group in groups) {
            final period = group['period'] as String;
            final doseMaps = List<Map<String, dynamic>>.from(
              group['doses'] as List,
            );
            allDoses.addAll(doseMaps);
            grouped[period] = doseMaps
                .map((d) => DoseEvent.fromJson(d))
                .toList();
          }
          await _db.cacheDoseEvents(allDoses);
          await _notif.scheduleAllReminders(allDoses);
          _todaysDoses = allDoses.map((d) => DoseEvent.fromJson(d)).toList();
          _groupedDoses = grouped;
          _log.success('DoseProvider', 'Schedule fetched from API (grouped)', {
            'count': _todaysDoses.length,
          });
        } else if (result['doses'] != null) {
          final doseList = List<Map<String, dynamic>>.from(
            result['doses'] as List,
          );
          // Cache in SQLite
          await _db.cacheDoseEvents(doseList);
          // Schedule local notifications
          await _notif.scheduleAllReminders(doseList);
          _todaysDoses = doseList.map((d) => DoseEvent.fromJson(d)).toList();
          _log.success('DoseProvider', 'Schedule fetched from API', {
            'count': _todaysDoses.length,
          });
        }
      } else {
        _log.warning('DoseProvider', 'Device offline, loading from cache');
        // Offline: load from SQLite
        final cached = await _db.getCachedDosesByDate(today);
        _todaysDoses = cached.map((d) => DoseEvent.fromJson(d)).toList();
        // Group by timePeriod
        _groupedDoses = {};
        for (final dose in _todaysDoses) {
          _groupedDoses.putIfAbsent(dose.timePeriod, () => []).add(dose);
        }
        // Schedule notifications from cache
        await _notif.scheduleAllReminders(cached);
        _log.info('DoseProvider', 'Schedule loaded from cache', {
          'count': _todaysDoses.length,
        });
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoseProvider', 'Failed to fetch schedule', e);
      // Fallback to cache on API error
      try {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final cached = await _db.getCachedDosesByDate(today);
        if (cached.isNotEmpty) {
          _todaysDoses = cached.map((d) => DoseEvent.fromJson(d)).toList();
          _error = null; // cleared – we have cached data
          _log.info('DoseProvider', 'Fallback to cache successful');
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
    _log.info('DoseProvider', 'Marking dose taken', {
      'doseId': doseId,
      'online': _sync.isOnline,
    });
    try {
      final now = DateTime.now();

      if (_sync.isOnline) {
        await _api.markDoseTaken(doseId, takenAt: now);
        _log.success('DoseProvider', 'Dose marked taken (online)');
      } else {
        // Save locally and queue for sync
        await _db.markDoseTakenLocally(doseId, now);
        await _db.addToSyncQueue(
          action: 'mark_taken',
          endpoint: '/doses/$doseId/taken',
          method: 'PATCH',
          body: {'takenAt': now.toIso8601String(), 'offline': true},
        );
        _log.info(
          'DoseProvider',
          'Dose marked taken (offline, queued for sync)',
        );
      }

      // Cancel all retry reminders for this dose
      await _notif.cancelDoseReminders(doseId);

      // Re-fetch schedule
      await fetchTodaySchedule();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoseProvider', 'Failed to mark dose taken', e);
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

      await _notif.cancelDoseReminders(doseId);
      await fetchTodaySchedule();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Process queued notification actions (mark_taken / skip) that were
  /// triggered from notification action buttons while the app was closed
  /// or in the background. Called from main.dart on startup / resume.
  Future<void> processPendingNotificationActions() async {
    final actions = await _notif.consumePendingActions();
    if (actions.isEmpty) return;

    _log.info('DoseProvider', 'Processing pending notification actions', {
      'count': actions.length,
    });

    for (final action in actions) {
      final actionId = action['action'] as String?;
      final payload = action['payload'] as String?;
      if (actionId == null || payload == null) continue;

      // Payload may be a single dose ID or comma-separated (batch).
      final doseIds = payload.split(',').where((s) => s.isNotEmpty).toList();

      switch (actionId) {
        case 'mark_taken':
          for (final doseId in doseIds) {
            _log.info(
              'DoseProvider',
              'Pending action: mark_taken',
              {'doseId': doseId},
            );
            await markTaken(doseId);
          }
          break;
        case 'skip':
          for (final doseId in doseIds) {
            _log.info(
              'DoseProvider',
              'Pending action: skip',
              {'doseId': doseId},
            );
            await skipDose(doseId, 'Skipped via notification');
          }
          break;
        case 'snooze':
          // Snooze is already handled at notification-service level
          // (a new notification was scheduled immediately). No provider
          // action needed — just log it.
          _log.info('DoseProvider', 'Pending action: snooze (no-op)', {
            'payload': payload,
          });
          break;
        default:
          _log.warning(
            'DoseProvider',
            'Unknown pending action: $actionId',
          );
      }
    }
  }
}
