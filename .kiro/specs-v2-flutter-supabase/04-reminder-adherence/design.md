# Design: Reminder System & Adherence Tracking (Offline-First)

## 1. Component diagram

```
┌────────────────────────────────────────────────────────────┐
│                     Flutter App                             │
│                                                             │
│   ┌──────────────┐    ┌─────────────────────┐               │
│   │ Drift        │◄──►│ DoseEventRepository │               │
│   │ (dose_events)│    └────────┬────────────┘               │
│   └──────┬───────┘             │                            │
│          │                     │                            │
│          ▼                     ▼                            │
│   ┌──────────────┐    ┌─────────────────────┐               │
│   │ Local Notif. │◄───│ ReminderScheduler   │               │
│   │ Plugin       │    └─────────────────────┘               │
│   └──────────────┘                                          │
│          │                                                  │
│          │ user taps action                                 │
│          ▼                                                  │
│   ┌──────────────┐    ┌─────────────────────┐               │
│   │ NotifAction  │───►│ MarkDoseUseCase     │──► outbox/RPC │
│   │ Handler      │    └─────────────────────┘               │
│   └──────────────┘                                          │
└─────────────────────────┬──────────────────────────────────┘
                          │
                          ▼ (online)
┌────────────────────────────────────────────────────────────┐
│ Supabase                                                    │
│   public.dose_events (RLS)                                  │
│   mark_dose() SQL function (atomic + audit)                 │
│   expire_missed_doses() pg_cron every 5min                  │
│   tg_dose_event_status_change → notifications               │
│   Edge Function `send-fcm` ◄── pg_net.http_post             │
└────────────────────────────────────────────────────────────┘
```

## 2. Module structure

```
lib/features/reminders/
├── data/
│   ├── dose_event_repository.dart
│   ├── reminder_scheduler.dart          # local notification orchestration
│   ├── notification_action_handler.dart # foreground+background tap
│   ├── adherence_repository.dart        # caches get_adherence
│   └── fcm_token_registrar.dart
├── domain/
│   ├── dose_event.dart                  # freezed
│   ├── adherence.dart                   # freezed
│   └── usecases/
│       ├── mark_dose_taken.dart
│       ├── mark_dose_skipped.dart
│       ├── mark_dose_missed_to_taken_late.dart
│       └── snooze_dose.dart
└── presentation/
    ├── pages/
    │   ├── today_page.dart
    │   ├── adherence_page.dart
    │   └── reminder_settings_page.dart
    └── widgets/
        ├── dose_card.dart
        ├── adherence_ring.dart
        └── adherence_sparkline.dart
```

## 3. ReminderScheduler

```dart
class ReminderScheduler {
  ReminderScheduler(this._plugin, this._db, this._tz);
  final FlutterLocalNotificationsPlugin _plugin;
  final AppDatabase _db;
  final TimezoneService _tz;

  Future<void> scheduleForDoseEvent(DoseEvent ev, Medication med) async {
    if (ev.status != DoseEventStatus.due) return;
    final tzScheduled = tz.TZDateTime.from(ev.scheduledTime, _tz.location);

    final detail = NotificationDetails(
      android: AndroidNotificationDetails(
        'dose_reminders', 'Dose reminders',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        actions: const [
          AndroidNotificationAction('TAKE',   'Take'),
          AndroidNotificationAction('SNOOZE', 'Snooze'),
          AndroidNotificationAction('SKIP',   'Skip'),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'DOSE_REMINDER',
      ),
    );

    await _plugin.zonedSchedule(
      ev.id.hashCode & 0x7fffffff,
      _formatTitle(med),
      _formatBody(med, ev),
      tzScheduled,
      detail,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({'doseId': ev.id, 'kind': 'reminder'}),
    );

    // Repeat reminders at +5, +10, +15
    for (final m in const [5, 10, 15]) {
      await _plugin.zonedSchedule(
        ('${ev.id}_$m').hashCode & 0x7fffffff,
        _formatTitle(med, isRepeat: true),
        _formatBody(med, ev, isRepeat: true),
        tzScheduled.add(Duration(minutes: m)),
        detail,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({'doseId': ev.id, 'kind': 'repeat', 'offset': m}),
      );
    }
  }

  Future<void> cancelForDoseEvent(String doseId) async {
    await _plugin.cancel(doseId.hashCode & 0x7fffffff);
    for (final m in const [5, 10, 15]) {
      await _plugin.cancel(('${doseId}_$m').hashCode & 0x7fffffff);
    }
  }
}
```

## 4. Notification action handler

```dart
class NotificationActionHandler {
  NotificationActionHandler(this._markTaken, this._markSkipped, this._snooze);

  Future<void> onActionReceived(NotificationResponse response) async {
    final payload = jsonDecode(response.payload ?? '{}') as Map<String, dynamic>;
    final doseId = payload['doseId'] as String?;
    if (doseId == null) return;

    switch (response.actionId) {
      case 'TAKE':
        await _markTaken(doseId);
        break;
      case 'SKIP':
        await _markSkipped(doseId, reason: null);
        break;
      case 'SNOOZE':
        await _snooze(doseId, const Duration(minutes: 5));
        break;
      default:
        // tap (no action button) → open app deep link
        break;
    }
  }
}
```

Hooked up in `main.dart` via `FlutterLocalNotificationsPlugin.initialize` `onDidReceiveNotificationResponse` and `onDidReceiveBackgroundNotificationResponse`.

## 5. MarkDose use case

```dart
class MarkDoseTaken {
  MarkDoseTaken(this._supabase, this._db, this._sync, this._scheduler);

  Future<void> call(String doseId, {DateTime? takenAt}) async {
    final dose = await _db.doseEventDao.findById(doseId);
    if (dose == null) throw const AppFailure.notFound();

    final now = takenAt ?? DateTime.now().toUtc();
    final grace = await _db.profileDao.gracePeriodMinutes();
    final wasOnTime = now.isBefore(
      dose.scheduledTime.add(Duration(minutes: grace)));
    final newStatus = wasOnTime
        ? DoseEventStatus.takenOnTime
        : DoseEventStatus.takenLate;

    final wasOffline = !await _connectivity.isOnline;

    // Optimistic local update
    await _db.doseEventDao.markTaken(doseId, newStatus, now, wasOffline);
    // Cancel future repeats locally
    await _scheduler.cancelForDoseEvent(doseId);

    // Enqueue server RPC
    await _sync.enqueueRpc('mark_dose', {
      'p_dose_id': doseId,
      'p_status': newStatus.name.toUpperCase(),
      'p_taken_at': now.toIso8601String(),
      'p_skip_reason': null,
      'p_was_offline': wasOffline,
    });
  }
}
```

## 6. Server-side missed expiration

```sql
-- supabase/migrations/20260601000500_pg_cron.sql
select cron.schedule(
  'expire_missed_doses_every_5min',
  '*/5 * * * *',
  $$ select public.expire_missed_doses(); $$
);

-- Trigger on dose_events status change emits notifications.
-- Per ADDENDUM-001: peer-Patients (not FAMILY_MEMBER role) receive missed-dose alerts.
-- See 05-family-doctor-connections/design.md § 6 for the canonical body. Repeated here
-- for completeness:
create or replace function public.tg_dose_status_change()
returns trigger language plpgsql security definer as $$
begin
  if (new.status = 'MISSED' and old.status = 'DUE') then
    -- 1. Patient self-notification
    insert into public.notifications (recipient_id, type, title, message, data)
    values (new.patient_id, 'MISSED_DOSE_ALERT',
            'Dose missed', 'You missed a scheduled dose. Tap to mark as taken or skip.',
            jsonb_build_object('dose_event_id', new.id, 'medication_id', new.medication_id));

    -- 2. Mutual peer-Patient alerts (both endpoints must be PATIENT)
    insert into public.notifications (recipient_id, type, title, message, data)
    select case
             when c.initiator_id = new.patient_id then c.recipient_id
             else c.initiator_id end,
           'FAMILY_ALERT',
           'A connected person missed a dose',
           coalesce((select first_name from public.profiles where id = new.patient_id), 'Someone')
             || ' missed a dose',
           jsonb_build_object('dose_event_id', new.id, 'patient_id', new.patient_id)
      from public.connections c
     where c.status = 'ACCEPTED'
       and (c.initiator_id = new.patient_id or c.recipient_id = new.patient_id)
       and c.permission_level <> 'NOT_ALLOWED'
       and exists (select 1 from public.profiles p
                    where p.id = case
                            when c.initiator_id = new.patient_id then c.recipient_id
                            else c.initiator_id end
                      and p.role = 'PATIENT')
       and exists (select 1 from public.profiles p
                    where p.id = new.patient_id and p.role = 'PATIENT');
  end if;

  if (new.status in ('TAKEN_ON_TIME','TAKEN_LATE') and old.status = 'MISSED') then
    -- Notify peer-Patients that the patient recovered the dose
    insert into public.notifications (recipient_id, type, title, message, data)
    select case
             when c.initiator_id = new.patient_id then c.recipient_id
             else c.initiator_id end,
           'DOSE_CONFIRMED',
           'Connected patient took the missed dose',
           'A connected friend/family marked the missed dose as taken.',
           jsonb_build_object('dose_event_id', new.id)
      from public.connections c
     where c.status = 'ACCEPTED'
       and (c.initiator_id = new.patient_id or c.recipient_id = new.patient_id)
       and c.permission_level <> 'NOT_ALLOWED'
       and exists (select 1 from public.profiles p
                    where p.id = case
                            when c.initiator_id = new.patient_id then c.recipient_id
                            else c.initiator_id end
                      and p.role = 'PATIENT');
  end if;
  return new;
end;
$$;

create trigger dose_events_status_change
after update of status on public.dose_events
for each row execute function public.tg_dose_status_change();
```

## 7. FCM dispatch

The `notifications` insert trigger calls `pg_net.http_post` (Supabase HTTP extension) to invoke the `send-fcm` Edge Function:

```sql
create or replace function public.tg_notification_to_fcm()
returns trigger language plpgsql security definer as $$
declare v_token text;
begin
  select fcm_token into v_token from public.profiles where id = new.recipient_id;
  if v_token is null then return new; end if;
  perform net.http_post(
    url := current_setting('app.fcm_function_url'),
    headers := jsonb_build_object('Authorization', current_setting('app.fcm_function_secret')),
    body := jsonb_build_object(
      'token', v_token,
      'title', new.title,
      'body', new.message,
      'data', new.data
    )::text
  );
  return new;
end;
$$;

create trigger notifications_fcm_dispatch
after insert on public.notifications
for each row execute function public.tg_notification_to_fcm();
```

The Edge Function `send-fcm` validates the auth header against a shared secret and sends to FCM HTTP v1 API using the service account.

> Note: `profiles.fcm_token` column needs to be added in a migration.

## 8. Adherence flow

```dart
@riverpod
Future<Adherence> adherence(AdherenceRef ref, AdherencePeriod period) async {
  final supabase = ref.watch(supabaseClientProvider);
  final cached = ref.watch(adherenceCacheProvider(period));
  if (cached != null && cached.cachedAt.isAfter(DateTime.now().subtract(const Duration(minutes: 5)))) {
    return cached.value;
  }
  final pct = await supabase.rpc('get_adherence', params: {
    'p_patient_id': supabase.auth.currentUser!.id,
    'p_period': period.code,
  });
  final adh = Adherence(period: period, percent: (pct as num).toDouble(), cachedAt: DateTime.now());
  ref.read(adherenceCacheProvider(period).notifier).set(adh);
  return adh;
}
```

The sparkline graph is computed locally from Drift `dose_events`:

```dart
List<double> dailyAdherenceLast7Days(List<DoseEvent> events) {
  final byDay = groupBy(events, (e) => DateUtils.dateOnly(e.scheduledTime.toLocal()));
  return List.generate(7, (i) {
    final day = DateUtils.dateOnly(DateTime.now().subtract(Duration(days: 6 - i)));
    final ds = byDay[day] ?? const <DoseEvent>[];
    if (ds.isEmpty) return double.nan;
    final taken = ds.where((d) => d.status == DoseEventStatus.takenOnTime || d.status == DoseEventStatus.takenLate).length;
    return taken / ds.length;
  });
}
```

## 9. Settings UI

`ReminderSettingsPage` exposes:
- Grace period choice (10/20/30/60 min) — updates `profiles.grace_period_minutes`.
- Repeat reminders toggle (global).
- Per-medication reminder enable/disable.
- Meal time preferences (links into 03-prescription-medication's meal time form).

## 10. Background reboot

`flutter_local_notifications` ships an Android `BootReceiver` that re-registers all pending notifications by re-reading them from the plugin's local SQLite. We additionally re-validate against Drift on app start because schedules may have changed while the device was off:

```dart
Future<void> rescheduleAllPending() async {
  final pending = await _plugin.pendingNotificationRequests();
  final pendingIds = pending.map((n) => n.id).toSet();
  final upcoming = await _db.doseEventDao.findDueWithinNext(const Duration(days: 7));
  for (final e in upcoming) {
    if (!pendingIds.contains(e.id.hashCode & 0x7fffffff)) {
      final med = await _db.medicationDao.findById(e.medicationId);
      await _scheduler.scheduleForDoseEvent(e, med!);
    }
  }
}
```

Called on cold start and on connectivity-restore.

## 11. Testing

- Unit: ReminderScheduler with mock plugin (verify zonedSchedule called with expected times).
- Unit: MarkDoseTaken returns TAKEN_ON_TIME/LATE based on grace.
- Widget: TodayPage shows today's grouped doses, action buttons enabled/disabled by status.
- Integration: schedule notification → simulate fire → action handler updates Drift + outbox.
- pgtap: `expire_missed_doses` updates only DUE rows whose grace has passed, no others.
