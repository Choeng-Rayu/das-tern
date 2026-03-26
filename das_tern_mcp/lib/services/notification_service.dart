import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'notification_strings.dart';

/// Key used to store queued notification actions in SharedPreferences.
/// When the user taps "Mark as Taken" or "Skip" from a background notification,
/// the action is queued here and processed the next time the app opens.
const _kPendingActionsKey = 'pending_notification_actions';

/// SharedPreferences key used by LocaleProvider to persist the user's language.
const _kLangKey = 'languageCode';

/// Top-level callback for notification actions triggered in the background.
/// This runs in an isolate — only lightweight work (SharedPreferences) is safe.
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) {
  debugPrint(
    '[NotificationService] Background action: ${response.actionId} '
    'payload=${response.payload}',
  );

  final payload = response.payload;
  final actionId = response.actionId;
  if (payload == null || actionId == null) return;

  // Queue the action for processing when the app next opens.
  // We cannot use DoseProvider / ApiService here because this callback
  // runs in a bare isolate without Flutter engine access.
  SharedPreferences.getInstance().then((prefs) {
    final pending = prefs.getStringList(_kPendingActionsKey) ?? [];
    pending.add(
      jsonEncode({
        'action': actionId,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    prefs.setStringList(_kPendingActionsKey, pending);
    debugPrint('[NotificationService] Queued background action: $actionId');
  });
}

/// Manages local dose-reminder notifications via flutter_local_notifications.
///
/// All user-facing strings follow the language the user has selected in the
/// app (stored under SharedPreferences key `'languageCode'`). Supported
/// languages: English (`'en'`) and Khmer (`'km'`).
///
/// Supports:
/// - Dose reminders with action buttons (Mark as Taken, Snooze, Skip)
/// - Retry notifications (initial + 10 min + 20 min)
/// - Batch reminders (medication groups)
/// - Snooze rescheduling
/// - Background action queueing for when the app is closed
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Retry offsets in minutes for dose reminders.
  static const List<int> retryOffsets = [0, 10, 20];

  /// Callback invoked when a notification is tapped while the app is in the
  /// foreground. Set by the app (e.g. in main.dart) to handle navigation.
  void Function(String payload)? onNotificationTapped;

  // ────────────────────────────────────────────
  // Locale helper
  // ────────────────────────────────────────────

  /// Reads the user's selected language from SharedPreferences and returns
  /// the corresponding [NotificationStrings] instance.
  Future<NotificationStrings> _strings() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey);
    return NotificationStrings.fromCode(code);
  }

  // ────────────────────────────────────────────
  // Initialization
  // ────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Timezone setup
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Phnom_Penh'));

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
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
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationAction,
    );

    // Request permissions on Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        await android.requestNotificationsPermission();
        final exactAlarmGranted =
            await android.canScheduleExactNotifications() ?? false;
        if (!exactAlarmGranted) {
          await android.requestExactAlarmsPermission();
        }
      }
    }

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  /// Handle notification tap / action when the app is in the foreground.
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      '[NotificationService] Foreground response: '
      'actionId=${response.actionId} payload=${response.payload}',
    );

    final payload = response.payload;
    if (payload == null) return;

    final actionId = response.actionId;

    if (actionId == null || actionId.isEmpty) {
      // Plain tap on the notification body — navigate into the app
      onNotificationTapped?.call(payload);
      return;
    }

    // Action button tapped while app is in foreground — queue it the same
    // way as background so the processing path is uniform.
    SharedPreferences.getInstance().then((prefs) {
      final pending = prefs.getStringList(_kPendingActionsKey) ?? [];
      pending.add(
        jsonEncode({
          'action': actionId,
          'payload': payload,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      prefs.setStringList(_kPendingActionsKey, pending);
    });

    // If the action is "snooze", schedule a new notification immediately
    if (actionId == 'snooze') {
      _handleSnoozeAction(payload);
    }
  }

  // ────────────────────────────────────────────
  // Pending Action Processing
  // ────────────────────────────────────────────

  /// Retrieve and clear all queued notification actions.
  /// Call this from the app (e.g. on startup or when returning to foreground)
  /// to process mark-taken / skip actions that were triggered from
  /// notification buttons.
  Future<List<Map<String, dynamic>>> consumePendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_kPendingActionsKey) ?? [];
    if (pending.isEmpty) return [];

    final actions = pending
        .map((s) {
          try {
            return Map<String, dynamic>.from(jsonDecode(s) as Map);
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    // Clear the queue
    await prefs.remove(_kPendingActionsKey);
    debugPrint(
      '[NotificationService] Consumed ${actions.length} pending actions',
    );
    return actions;
  }

  // ────────────────────────────────────────────
  // Dose Reminder with Retries
  // ────────────────────────────────────────────

  /// Schedule a dose reminder with automatic retry notifications.
  ///
  /// Schedules notifications at:
  /// - [reminderTime] (initial)
  /// - [reminderTime] + 10 minutes (retry 1)
  /// - [reminderTime] + 20 minutes (retry 2)
  ///
  /// Each notification includes action buttons:
  /// Mark as Taken, Snooze 10min, Skip.
  ///
  /// All user-facing strings use the language stored in SharedPreferences.
  Future<void> scheduleDoseWithRetries({
    required String doseId,
    required String medicationName,
    required String dosage,
    required DateTime reminderTime,
    required String timePeriod,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    final s = await _strings();
    final period = s.periodLabel(timePeriod);

    for (final offsetMinutes in retryOffsets) {
      final time = reminderTime.add(Duration(minutes: offsetMinutes));
      if (time.isBefore(DateTime.now())) continue;

      final isRetry = offsetMinutes > 0;
      final title = s.reminderTitle + (isRetry ? s.reminderRetryTag : '');
      final uniqueId = '${doseId}_retry_$offsetMinutes';
      final id = uniqueId.hashCode.abs() % 2147483647;

      await _plugin.zonedSchedule(
        id,
        title,
        s.singleBody(medicationName, dosage, period),
        tz.TZDateTime.from(time, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'dose_reminders',
            s.channelDoseRemindersName,
            channelDescription: s.channelDoseRemindersDesc,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@drawable/ic_notification',
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_taken',
                s.actionMarkTaken,
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'snooze',
                s.actionSnooze,
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'skip',
                s.actionSkip,
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: doseId,
      );
    }
  }

  /// Cancel all retry notifications for a specific dose.
  Future<void> cancelDoseReminders(String doseId) async {
    if (kIsWeb) return;
    for (final offset in retryOffsets) {
      final uniqueId = '${doseId}_retry_$offset';
      final id = uniqueId.hashCode.abs() % 2147483647;
      await _plugin.cancel(id);
    }
    // Also cancel the legacy single notification (for backward compat)
    final legacyId = doseId.hashCode.abs() % 2147483647;
    await _plugin.cancel(legacyId);
  }

  // ────────────────────────────────────────────
  // Batch Dose Reminder (multiple meds at same time)
  // ────────────────────────────────────────────

  /// Schedule reminders for a group of doses at the same time.
  /// Shows a single notification listing all medicines.
  Future<void> scheduleBatchDoseWithRetries({
    required List<String> doseIds,
    required List<String> medicationNames,
    required DateTime reminderTime,
    required String timePeriod,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (doseIds.isEmpty || medicationNames.isEmpty) return;

    final s = await _strings();
    final period = s.periodLabel(timePeriod);

    // Use first doseId as the batch key
    final batchKey = 'dose_batch_${doseIds.first}';

    for (final offsetMinutes in retryOffsets) {
      final time = reminderTime.add(Duration(minutes: offsetMinutes));
      if (time.isBefore(DateTime.now())) continue;

      final isRetry = offsetMinutes > 0;
      final title = s.reminderTitle + (isRetry ? s.reminderRetryTag : '');
      final uniqueId = '${batchKey}_retry_$offsetMinutes';
      final id = uniqueId.hashCode.abs() % 2147483647;

      final batchBodyHeader = s.batchBodyHeader(period);
      final medicineLines = medicationNames.map((n) => '  - $n').join('\n');
      final body = '$batchBodyHeader\n$medicineLines';

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(time, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'dose_reminders',
            s.channelDoseRemindersName,
            channelDescription: s.channelDoseRemindersDesc,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@drawable/ic_notification',
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
            ),
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_taken',
                s.actionMarkTaken,
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'snooze',
                s.actionSnooze,
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'skip',
                s.actionSkip,
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Payload contains comma-separated dose IDs for batch action
        payload: doseIds.join(','),
      );
    }
  }

  /// Cancel batch dose reminders for a group of doses.
  Future<void> cancelBatchDoseReminders(List<String> doseIds) async {
    if (kIsWeb) return;
    if (doseIds.isEmpty) return;
    final batchKey = 'dose_batch_${doseIds.first}';
    for (final offset in retryOffsets) {
      final uniqueId = '${batchKey}_retry_$offset';
      final id = uniqueId.hashCode.abs() % 2147483647;
      await _plugin.cancel(id);
    }
    // Also cancel individual dose reminders
    for (final doseId in doseIds) {
      await cancelDoseReminders(doseId);
    }
  }

  // ────────────────────────────────────────────
  // Schedule All Reminders (called by DoseProvider)
  // ────────────────────────────────────────────

  /// Schedule reminders for a list of dose events from the backend.
  /// Groups doses by reminderTime for batch notifications.
  Future<void> scheduleAllReminders(
    List<Map<String, dynamic>> doseEvents,
  ) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    // Cancel all existing dose reminders first
    await cancelAllReminders();

    // Group DUE doses by reminderTime for batch notifications
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final dose in doseEvents) {
      final status = dose['status'] as String? ?? 'DUE';
      if (status != 'DUE') continue;

      final reminderTimeStr = dose['reminderTime'] as String?;
      if (reminderTimeStr == null) continue;

      final reminderTime = DateTime.tryParse(reminderTimeStr);
      if (reminderTime == null || reminderTime.isBefore(DateTime.now())) {
        continue;
      }

      // Group key: reminderTime + timePeriod
      final key = '${reminderTimeStr}_${dose['timePeriod'] ?? 'MORNING'}';
      groups.putIfAbsent(key, () => []).add(dose);
    }

    // Schedule each group
    for (final entry in groups.entries) {
      final doses = entry.value;
      if (doses.isEmpty) continue;

      final firstDose = doses.first;
      final reminderTime = DateTime.parse(firstDose['reminderTime'] as String);
      final timePeriod = firstDose['timePeriod'] as String? ?? 'MORNING';

      if (doses.length == 1) {
        // Single dose — individual notification with retries
        await scheduleDoseWithRetries(
          doseId: firstDose['id'] as String,
          medicationName:
              firstDose['medicationName'] as String? ?? 'Medication',
          dosage: _formatDosage(firstDose['dosage']),
          reminderTime: reminderTime,
          timePeriod: timePeriod,
        );
      } else {
        // Multiple doses at same time — batch notification
        final doseIds = doses.map((d) => d['id'] as String).toList();
        final medNames = doses
            .map((d) => d['medicationName'] as String? ?? 'Medication')
            .toList();

        await scheduleBatchDoseWithRetries(
          doseIds: doseIds,
          medicationNames: medNames,
          reminderTime: reminderTime,
          timePeriod: timePeriod,
        );
      }
    }
  }

  // ────────────────────────────────────────────
  // Cancel
  // ────────────────────────────────────────────

  /// Cancel a specific reminder by dose ID (legacy single-notification).
  Future<void> cancelReminder(String doseId) async {
    if (kIsWeb) return;
    await cancelDoseReminders(doseId);
  }

  /// Cancel all scheduled reminders.
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // ────────────────────────────────────────────
  // Medication Batch Reminders (daily repeating)
  // ────────────────────────────────────────────

  /// Schedule a daily repeating reminder for a medication batch.
  Future<void> scheduleBatchReminder({
    required String batchId,
    required String batchName,
    required List<String> medicineNames,
    required DateTime reminderTime,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    if (reminderTime.isBefore(DateTime.now())) return;

    final s = await _strings();
    final id = 'batch_$batchId'.hashCode.abs() % 2147483647;
    final medicineList = medicineNames.join(', ');

    await _plugin.zonedSchedule(
      id,
      batchName,
      '${s.channelDoseRemindersName}: $medicineList',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'batch_reminders',
          s.channelBatchRemindersName,
          channelDescription: s.channelBatchRemindersDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@drawable/ic_notification',
          styleInformation: BigTextStyleInformation(
            '${s.channelDoseRemindersName}:\n'
            '${medicineNames.map((n) => '  - $n').join('\n')}',
            contentTitle: batchName,
          ),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'mark_taken',
              s.actionMarkTaken,
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'snooze',
              s.actionSnooze,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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

    final s = await _strings();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          s.channelGeneralName,
          channelDescription: s.channelGeneralDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ────────────────────────────────────────────
  // Test / Mock notification
  // ────────────────────────────────────────────

  /// Fire an immediate test notification with all three action buttons.
  /// Uses the user's current language from SharedPreferences.
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    final s = await _strings();
    final id = 'test_notif'.hashCode.abs() % 2147483647;

    await _plugin.show(
      id,
      s.testTitle,
      s.testBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'dose_reminders',
          s.channelDoseRemindersName,
          channelDescription: s.channelDoseRemindersDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@drawable/ic_notification',
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'mark_taken',
              s.actionMarkTaken,
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'snooze',
              s.actionSnooze,
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'skip',
              s.actionSkip,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_dose',
    );

    debugPrint(
      '[NotificationService] Test notification shown (lang: ${s.reminderTitle})',
    );
  }

  // ────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────

  /// Handle snooze action by scheduling a new notification 10 minutes from now.
  void _handleSnoozeAction(String payload) {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    final snoozeId =
        'snooze_${payload}_${DateTime.now().millisecondsSinceEpoch}';
    final id = snoozeId.hashCode.abs() % 2147483647;

    // Determine if this is a batch (comma-separated IDs) or single dose
    final doseIds = payload.split(',');
    final isBatch = doseIds.length > 1;

    // Load locale strings async — fire and forget (snooze is best-effort)
    _strings().then((s) {
      _plugin.zonedSchedule(
        id,
        s.snoozedTitle,
        isBatch ? s.snoozedBodyBatch : s.snoozedBodySingle,
        tz.TZDateTime.from(snoozeTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'dose_reminders',
            s.channelDoseRemindersName,
            channelDescription: s.channelDoseRemindersDesc,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@drawable/ic_notification',
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_taken',
                s.actionMarkTaken,
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'snooze',
                s.actionSnooze,
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'skip',
                s.actionSkip,
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    });

    debugPrint('[NotificationService] Snoozed reminder for 10 minutes');
  }

  /// Format dosage for display. Handles both String and Map dosage values.
  String _formatDosage(dynamic dosage) {
    if (dosage == null) return '';
    if (dosage is String) return dosage;
    if (dosage is Map) {
      final amount = dosage['amount'] ?? dosage['quantity'] ?? '';
      final unit = dosage['unit'] ?? '';
      return '$amount $unit'.trim();
    }
    return dosage.toString();
  }
}
