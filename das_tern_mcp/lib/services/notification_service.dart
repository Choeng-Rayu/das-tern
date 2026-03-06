import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Manages local dose-reminder notifications via flutter_local_notifications.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ────────────────────────────────────────────
  // Initialization
  // ────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    // flutter_local_notifications does not support web
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Timezone setup
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Phnom_Penh'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped: ${response.payload}');
    // Navigation can be handled via a global navigator key
  }

  // ────────────────────────────────────────────
  // Schedule a dose reminder
  // ────────────────────────────────────────────

  /// Schedule a notification at [reminderTime] for a dose.
  Future<void> scheduleDoseReminder({
    required String doseId,
    required String medicationName,
    required String dosage,
    required DateTime reminderTime,
    required String timePeriod,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    // Don't schedule past notifications
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = doseId.hashCode.abs() % 2147483647; // safe 32-bit int

    final periodLabel = timePeriod == 'DAYTIME' ? '🌅 Daytime' : '🌙 Night';

    await _plugin.zonedSchedule(
      id,
      '$periodLabel Dose Reminder',
      'Time to take $medicationName ($dosage)',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'dose_reminders',
          'Dose Reminders',
          channelDescription: 'Reminders to take your medication',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: doseId,
    );
  }

  // ────────────────────────────────────────────
  // Schedule reminders for all today's doses
  // ────────────────────────────────────────────

  /// Schedule reminders for a batch of dose events.
  Future<void> scheduleAllReminders(
    List<Map<String, dynamic>> doseEvents,
  ) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    // Cancel all existing reminders first
    await cancelAllReminders();

    for (final dose in doseEvents) {
      final status = dose['status'] as String? ?? 'DUE';
      // Only schedule for DUE doses
      if (status != 'DUE') continue;

      final reminderTimeStr = dose['reminderTime'] as String?;
      if (reminderTimeStr == null) continue;

      final reminderTime = DateTime.tryParse(reminderTimeStr);
      if (reminderTime == null || reminderTime.isBefore(DateTime.now())) {
        continue;
      }

      await scheduleDoseReminder(
        doseId: dose['id'] as String,
        medicationName: dose['medicationName'] as String? ?? 'Medication',
        dosage: dose['dosage'] as String? ?? '',
        reminderTime: reminderTime,
        timePeriod: dose['timePeriod'] as String? ?? 'DAYTIME',
      );
    }
  }

  // ────────────────────────────────────────────
  // Cancel
  // ────────────────────────────────────────────

  /// Cancel a specific reminder by dose ID.
  Future<void> cancelReminder(String doseId) async {
    if (kIsWeb) return;
    final id = doseId.hashCode.abs() % 2147483647;
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled reminders.
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // ────────────────────────────────────────────
  // Batch reminders
  // ────────────────────────────────────────────

  /// Schedule a single reminder for a medication batch at its scheduledTime.
  /// Lists all medicine names in the notification body.
  Future<void> scheduleBatchReminder({
    required String batchId,
    required String batchName,
    required List<String> medicineNames,
    required DateTime reminderTime,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    if (reminderTime.isBefore(DateTime.now())) return;

    final id = 'batch_$batchId'.hashCode.abs() % 2147483647;
    final medicineList = medicineNames.join(', ');

    await _plugin.zonedSchedule(
      id,
      batchName,
      'Time to take: $medicineList',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'batch_reminders',
          'Batch Reminders',
          channelDescription: 'Reminders for medication batch groups',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'batch:$batchId',
    );
  }

  /// Cancel a batch reminder by batch ID.
  Future<void> cancelBatchReminder(String batchId) async {
    if (kIsWeb) return;
    final id = 'batch_$batchId'.hashCode.abs() % 2147483647;
    await _plugin.cancel(id);
  }

  // ────────────────────────────────────────────
  // Instant notification
  // ────────────────────────────────────────────

  /// Show an immediate notification (e.g. sync complete, missed dose alert).
  Future<void> showInstant({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General',
          channelDescription: 'General app notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ────────────────────────────────────────────
  // Reminder notifications
  // ────────────────────────────────────────────

  /// Schedule a local notification for a server-side reminder.
  Future<void> scheduleReminderNotification({
    required String reminderId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    required String timePeriod,
    int repeatCount = 0,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    if (scheduledTime.isBefore(DateTime.now())) return;

    final id = 'reminder_$reminderId'.hashCode.abs() % 2147483647;

    final periodLabel = timePeriod == 'MORNING'
        ? 'Morning'
        : timePeriod == 'DAYTIME'
            ? 'Daytime'
            : 'Night';
    final prefix = repeatCount > 0 ? '[Repeat] ' : '';

    await _plugin.zonedSchedule(
      id,
      '$prefix$periodLabel Dose Reminder',
      'Time to take $medicationName ($dosage)',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'dose_reminders',
          'Dose Reminders',
          channelDescription: 'Reminders to take your medication',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder:$reminderId',
    );
  }

  /// Show an immediate missed dose alert notification.
  Future<void> showMissedDoseAlert({
    required String medicationName,
    required String scheduledTime,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      'Missed Dose',
      'You missed $medicationName scheduled at $scheduledTime',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'missed_dose_alerts',
          'Missed Dose Alerts',
          channelDescription: 'Alerts for missed medication doses',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'missed_dose',
    );
  }

  /// Cancel a reminder notification.
  Future<void> cancelReminderNotification(String reminderId) async {
    if (kIsWeb) return;
    final id = 'reminder_$reminderId'.hashCode.abs() % 2147483647;
    await _plugin.cancel(id);
  }
}
