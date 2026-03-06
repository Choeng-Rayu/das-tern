import 'dart:async';
import 'api_service.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'logger_service.dart';

/// Syncs server-side reminders to local cache and schedules notifications.
class ReminderSyncService {
  static final ReminderSyncService instance = ReminderSyncService._();
  ReminderSyncService._();

  final ApiService _api = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notifications = NotificationService.instance;
  final LoggerService _log = LoggerService.instance;
  Timer? _periodicTimer;

  /// Fetch upcoming reminders from API, cache locally, schedule notifications.
  Future<void> syncReminders() async {
    try {
      _log.info('ReminderSyncService', 'Syncing reminders from server');
      final reminders = await _api.getUpcomingReminders(days: 7, limit: 100);
      final reminderMaps = List<Map<String, dynamic>>.from(reminders);

      // Cache in SQLite
      await _db.cacheReminders(reminderMaps);

      // Schedule local notifications for PENDING/SNOOZED reminders
      int scheduled = 0;
      for (final r in reminderMaps) {
        final status = r['status'] as String? ?? 'PENDING';
        if (status != 'PENDING' && status != 'SNOOZED') continue;

        final timeStr = (status == 'SNOOZED'
            ? r['snoozedUntil']
            : r['scheduledTime']) as String?;
        if (timeStr == null) continue;

        final time = DateTime.tryParse(timeStr);
        if (time == null || time.isBefore(DateTime.now())) continue;

        final medName = r['medicationName'] as String? ??
            (r['medication'] is Map
                ? r['medication']['medicineName'] as String? ?? ''
                : '');
        final dosage = r['dosage'] as String? ??
            (r['medication'] is Map
                ? '${r['medication']['dosageAmount'] ?? ''}'
                : '');

        await _notifications.scheduleReminderNotification(
          reminderId: r['id'] as String,
          medicationName: medName,
          dosage: dosage,
          scheduledTime: time,
          timePeriod: r['timePeriod'] as String? ?? 'DAYTIME',
          repeatCount: r['repeatCount'] as int? ?? 0,
        );
        scheduled++;
        if (scheduled >= 100) break;
      }
      _log.success('ReminderSyncService',
          'Synced ${reminderMaps.length} reminders, scheduled $scheduled notifications');
    } catch (e) {
      _log.error('ReminderSyncService', 'Failed to sync reminders', e);
    }
  }

  /// Start periodic sync (hourly).
  void startPeriodicSync() {
    _periodicTimer?.cancel();
    syncReminders();
    _periodicTimer =
        Timer.periodic(const Duration(hours: 1), (_) => syncReminders());
    _log.info('ReminderSyncService', 'Periodic reminder sync started (hourly)');
  }

  /// Stop periodic sync.
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
