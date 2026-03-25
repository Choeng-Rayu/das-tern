# Medication Reminder Notification System - Implementation Plan

## Problem Summary

| Issue | Root Cause |
|-------|-----------|
| Notifications don't fire when app closed | No boot receiver registered in AndroidManifest.xml — after reboot all scheduled alarms lost |
| Family members not notified in real-time | Backend NotificationsService.send() only writes to DB. No push. Family must open app. |
| No retry/escalation logic | Only one notification fires per dose. No retry if patient ignores. |
| No notification action buttons | _onNotificationTapped is a stub — no "Mark as Taken" or "Snooze" actions |
| No premium gating on family alerts | Family alert code doesn't check subscription tier |

---

## Phase 1: Fix Android Boot Receiver (Bug Fix)

**File:** `das_tern_mcp/android/app/src/main/AndroidManifest.xml`

Add before the `flutterEmbedding` meta-data tag:

```xml
<!-- Reschedule notifications after device reboot -->
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
<!-- Handle scheduled notification triggers -->
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<!-- Handle notification action buttons -->
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
```

---

## Phase 2: Add Notification Action Buttons

**Files:**
- `das_tern_mcp/lib/services/notification_service.dart` (major rewrite)
- `das_tern_mcp/lib/main.dart` (add background callback)

### Changes to notification_service.dart:

1. Add Android notification actions ("Mark as Taken", "Snooze 10min", "Skip")
2. Handle action callbacks including background actions
3. Wire up a global navigator key for navigation from notifications
4. Add snooze functionality (reschedule notification +10 min)

### Key code additions:

```dart
// Top-level callback for background notification actions
@pragma('vm:entry-point')
void notificationActionCallback(NotificationResponse response) {
  // Handle background actions
  final payload = response.payload;
  final actionId = response.actionId;
  
  if (payload == null) return;
  
  switch (actionId) {
    case 'mark_taken':
      // Queue action for when app opens
      _queueDoseAction(payload, 'taken');
      break;
    case 'snooze':
      // Schedule a new notification 10 minutes from now
      _scheduleSnooze(payload);
      break;
    case 'skip':
      _queueDoseAction(payload, 'skipped');
      break;
  }
}
```

Add to `scheduleDoseReminder()`:
```dart
AndroidNotificationDetails(
  'dose_reminders',
  'Dose Reminders',
  // ... existing config ...
  actions: <AndroidNotificationAction>[
    const AndroidNotificationAction(
      'mark_taken', '✅ Mark as Taken',
      showsUserInterface: false,
    ),
    const AndroidNotificationAction(
      'snooze', '⏰ Snooze 10min',
      showsUserInterface: false,
    ),
    const AndroidNotificationAction(
      'skip', '❌ Skip',
      showsUserInterface: false,
    ),
  ],
),
```

### Changes to main.dart:
- Add the `@pragma('vm:entry-point')` background callback registration
- Pass `onDidReceiveBackgroundNotificationResponse` to plugin.initialize()

---

## Phase 3: Implement Reminder Retry Logic

**New file:** `das_tern_mcp/lib/services/reminder_scheduler_service.dart`
**Modified:** `das_tern_mcp/lib/services/notification_service.dart`

### ReminderSchedulerService:

Wraps NotificationService to schedule multiple notifications per dose:
- Initial reminder at `scheduledTime`
- Retry 1 at `scheduledTime + 10 min`
- Retry 2 at `scheduledTime + 20 min`

When "Mark as Taken" or "Skip" is tapped, cancel all retry notifications for that dose.

Notification IDs for retries use: `doseId.hashCode + offset` to allow individual cancellation.

### Key code:

```dart
class ReminderSchedulerService {
  static final instance = ReminderSchedulerService._();
  ReminderSchedulerService._();
  
  final _notif = NotificationService.instance;
  
  static const _retryOffsets = [0, 10, 20]; // minutes
  
  Future<void> scheduleDoseWithRetries({
    required String doseId,
    required String medicationName,
    required String dosage,
    required DateTime reminderTime,
    required String timePeriod,
  }) async {
    for (final offsetMinutes in _retryOffsets) {
      final time = reminderTime.add(Duration(minutes: offsetMinutes));
      if (time.isBefore(DateTime.now())) continue;
      
      final isRetry = offsetMinutes > 0;
      await _notif.scheduleDoseReminder(
        doseId: '${doseId}_retry_$offsetMinutes',
        medicationName: medicationName,
        dosage: dosage,
        reminderTime: time,
        timePeriod: timePeriod,
        isRetry: isRetry,
      );
    }
  }
  
  Future<void> cancelAllRetriesForDose(String doseId) async {
    for (final offset in _retryOffsets) {
      await _notif.cancelReminder('${doseId}_retry_$offset');
    }
    // Also cancel the original
    await _notif.cancelReminder(doseId);
  }
  
  Future<void> scheduleSnooze({
    required String doseId,
    required String medicationName,
    required String dosage,
    required String timePeriod,
  }) async {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    await _notif.scheduleDoseReminder(
      doseId: '${doseId}_snooze_${DateTime.now().millisecondsSinceEpoch}',
      medicationName: medicationName,
      dosage: dosage,
      reminderTime: snoozeTime,
      timePeriod: timePeriod,
      isRetry: true,
    );
  }
}
```

### Update DoseProvider to use ReminderSchedulerService:
- Replace `_notif.cancelReminder(doseId)` with `ReminderSchedulerService.instance.cancelAllRetriesForDose(doseId)`
- Replace `_notif.scheduleAllReminders()` with batch retry scheduling

---

## Phase 4: Backend - Enhance Missed Dose Job + Premium Check

### Prisma Schema Changes (`prisma/schema.prisma`):

Add to `NotificationType` enum:
```prisma
enum NotificationType {
  CONNECTION_REQUEST
  PRESCRIPTION_UPDATE
  MISSED_DOSE_ALERT
  URGENT_PRESCRIPTION_CHANGE
  FAMILY_ALERT
  VITAL_ANOMALY
  EMERGENCY_ALERT
  REMINDER_ESCALATION    // NEW
  DOSE_CONFIRMED         // NEW
}
```

### Changes to `missed-dose.job.ts`:

1. Add premium check before family alerts:
```typescript
private async triggerCaregiverAlerts(dose: any) {
  // Check if patient has premium subscription
  const subscription = await this.prisma.subscription.findUnique({
    where: { userId: dose.patientId },
  });
  
  if (!subscription || subscription.tier === 'FREEMIUM') {
    this.logger.debug('Skipping caregiver alerts - patient is FREEMIUM');
    return;
  }
  
  // ... existing alert logic ...
}
```

2. Improve notification message with batch grouping:
```typescript
// Group missed doses by time period for batch notification
private async notifyPatientBatch(doses: any[]) {
  // Group by scheduledTime
  const groups = new Map<string, any[]>();
  for (const dose of doses) {
    const key = dose.scheduledTime.toISOString();
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key)!.push(dose);
  }
  
  for (const [time, groupDoses] of groups) {
    const medNames = groupDoses.map(d => d.medication.medicineName).join(', ');
    const timeStr = new Date(time).toLocaleTimeString('en-US', { 
      hour: '2-digit', minute: '2-digit' 
    });
    
    await this.notificationsService.send(
      groupDoses[0].patientId,
      'MISSED_DOSE_ALERT',
      'Medication Reminder',
      `You missed your ${timeStr} medicines: ${medNames}. Please take them now.`,
      { doseIds: groupDoses.map(d => d.id), scheduledTime: time },
    );
  }
}
```

### Changes to `notifications.service.ts`:

Add method for sending dose confirmation to family:
```typescript
async sendDoseConfirmation(patientId: string, doseId: string, takenAt: Date) {
  // Premium check
  const subscription = await this.prisma.subscription.findUnique({
    where: { userId: patientId },
  });
  if (!subscription || subscription.tier === 'FREEMIUM') return;
  
  // Get connected caregivers with alerts enabled
  const connections = await this.prisma.connection.findMany({
    where: {
      OR: [
        { initiatorId: patientId },
        { recipientId: patientId },
      ],
      status: 'ACCEPTED',
    },
    include: {
      initiator: { select: { id: true, firstName: true, fullName: true } },
      recipient: { select: { id: true, firstName: true, fullName: true } },
    },
  });
  
  const dose = await this.prisma.doseEvent.findUnique({
    where: { id: doseId },
    include: { medication: true, patient: true },
  });
  if (!dose) return;
  
  const patientName = dose.patient.fullName || dose.patient.firstName || 'Patient';
  const timeStr = takenAt.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  
  for (const conn of connections) {
    const caregiverId = conn.initiatorId === patientId ? conn.recipientId : conn.initiatorId;
    const metadata = conn.metadata as any;
    if (metadata?.alertsEnabled === false) continue;
    
    await this.send(
      caregiverId,
      'DOSE_CONFIRMED',
      'Medication Taken',
      `${patientName} has taken ${dose.medication.medicineName} at ${timeStr}.`,
      { doseId, patientId, takenAt: takenAt.toISOString() },
    );
  }
}
```

---

## Phase 5: Backend - Add Dose Confirmation to markTaken()

**File:** `backend_nestjs/src/modules/doses/doses.service.ts`

In `markTaken()`, after recording the dose, inject and call:
```typescript
constructor(
  private prisma: PrismaService,
  private notificationsService: NotificationsService, // ADD
) {}

async markTaken(id: string, patientId: string, takenAt?: string, offline = false) {
  // ... existing logic ...
  
  // Notify connected caregivers (premium only, handled inside)
  await this.notificationsService.sendDoseConfirmation(patientId, id, takenTime);
  
  return { dose: ..., dailyProgress };
}
```

**File:** `backend_nestjs/src/modules/doses/doses.module.ts`

Add `NotificationsModule` import (already there) and inject into `DosesService`.

---

## Phase 6: Batch Notification Grouping & UI Improvements

### Flutter notification_service.dart:

Enhance `scheduleAllReminders()` to group doses by time period and create batch notifications:

```dart
Future<void> scheduleAllReminders(List<Map<String, dynamic>> doseEvents) async {
  await cancelAllReminders();
  
  // Group by reminderTime for batch notifications
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final dose in doseEvents) {
    if ((dose['status'] as String?) != 'DUE') continue;
    final time = dose['reminderTime'] as String?;
    if (time == null) continue;
    groups.putIfAbsent(time, () => []).add(dose);
  }
  
  for (final entry in groups.entries) {
    final doses = entry.value;
    if (doses.length == 1) {
      // Single dose — schedule individual reminder with retries
      await _scheduleSingleDoseWithRetries(doses.first);
    } else {
      // Multiple doses at same time — schedule batch reminder with retries
      await _scheduleBatchDoseWithRetries(doses);
    }
  }
}
```

### Patient Notifications Screen UI:

- Add distinct icons/colors for `MISSED_DOSE_ALERT` vs `DOSE_CONFIRMED` vs `REMINDER_ESCALATION`
- Show medicine list in notification card for batch reminders
- Improve card design with action buttons (Mark as Read, View Details)

### Standard Notification Card:

- Add medicine list display for notifications with `doseIds` metadata
- Add colored left border based on notification type
- Add relative time display improvements

---

## Phase 7: Premium Gate for Family Alerts

### Flutter - caregiver_dashboard_screen.dart:
- Check `SubscriptionProvider.isPremium` before showing family alert features
- Show upgrade banner for FREEMIUM users

### Flutter - patient_home_tab.dart:
- Family connection quick action shows premium badge if not premium
- Tapping it navigates to upgrade screen for FREEMIUM

### Backend - already handled:
- `getTierLimits('FREEMIUM')` returns `familyConnections: 0`
- Phase 4 adds premium check to missed dose job caregiver alerts

---

## Phase 8: Flutter Analyze & Fixes

Run `flutter analyze` in das_tern_mcp and fix all issues:
- Unused imports
- Missing const constructors
- Deprecated API usage
- Type warnings
- Any other lint issues

---

## Files to Create (1 new file):
- `das_tern_mcp/lib/services/reminder_scheduler_service.dart`

## Files to Modify:
### Flutter (das_tern_mcp):
1. `android/app/src/main/AndroidManifest.xml` — boot receiver
2. `lib/services/notification_service.dart` — action buttons, retry, batch grouping
3. `lib/main.dart` — background callback registration
4. `lib/providers/dose_provider.dart` — use ReminderSchedulerService
5. `lib/ui/screens/patient/notification/patient_notifications_screen.dart` — UI improvements
6. `lib/ui/screens/patient/notification/standard_notification_card.dart` — notification type styling
7. `lib/ui/screens/family_ui/caregiver_dashboard_screen.dart` — premium gate
8. `lib/ui/screens/patient/tab/patient_home_tab.dart` — premium badge on family actions
9. `lib/models/notification_model/notification.dart` — add new notification types

### Backend (backend_nestjs):
1. `prisma/schema.prisma` — add REMINDER_ESCALATION, DOSE_CONFIRMED to NotificationType
2. `src/modules/notifications/notifications.service.ts` — add sendDoseConfirmation()
3. `src/modules/doses/missed-dose.job.ts` — premium check, batch grouping
4. `src/modules/doses/doses.service.ts` — call sendDoseConfirmation on markTaken
5. `src/modules/doses/doses.module.ts` — inject NotificationsService into DosesService
