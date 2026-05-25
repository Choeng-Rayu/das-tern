# Tasks: Reminder System & Adherence Tracking

## Phase 1 — Plugin setup (0.5 day)

- [ ] **1.1** Add deps: `flutter_local_notifications`, `timezone`, `connectivity_plus`, `firebase_messaging`, `firebase_core`.
- [ ] **1.2** Android: declare permissions `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`. Configure `AndroidManifest` for boot receiver.
- [ ] **1.3** iOS: configure `UNUserNotificationCenter` action categories, capabilities for push notifications.
- [ ] **1.4** Initialize timezone db with `tz.initializeTimeZones()` in `main.dart`.

## Phase 2 — ReminderScheduler (1 day)

- [ ] **2.1** `lib/features/reminders/data/reminder_scheduler.dart` per design § 3.
- [ ] **2.2** Helper to compute notification id from dose-event id deterministically.
- [ ] **2.3** Action category definitions for Android + iOS.
- [ ] **2.4** Unit test: scheduling for a given dose event yields the expected `zonedSchedule` calls.

## Phase 3 — Notification action handler (0.5 day)

- [ ] **3.1** `NotificationActionHandler` wired to `onDidReceiveNotificationResponse` and `onDidReceiveBackgroundNotificationResponse`.
- [ ] **3.2** Background isolate-safe markDose entry point (write to Drift + enqueue outbox; sync on next foreground).
- [ ] **3.3** Deep-link payload routes to today page when user taps the notification body.

## Phase 4 — MarkDose use cases (1 day)

- [ ] **4.1** `MarkDoseTaken`, `MarkDoseSkipped`, `SnoozeDose`, `MarkMissedAsTaken` per design § 5.
- [ ] **4.2** All use cases call `mark_dose` RPC via outbox.
- [ ] **4.3** Snooze: cancel existing notification, reschedule at +duration, increment `metadata.snoozed_count` (max 3).
- [ ] **4.4** Tests for grace-period boundary cases (on-time vs late).

## Phase 5 — Today view + adherence UI (1 day)

- [ ] **5.1** `TodayPage` with grouped time periods, dose cards, action buttons.
- [ ] **5.2** "Next dose" countdown card.
- [ ] **5.3** `AdherenceRing` widget showing today's percentage in color-coded ring.
- [ ] **5.4** `AdherenceSparkline` for last 7 days, computed locally.
- [ ] **5.5** `AdherencePage` with weekly + monthly + 90-day charts.

## Phase 6 — Server triggers + cron (1 day)

- [ ] **6.1** Add SQL trigger `tg_dose_status_change` per design § 6.
- [ ] **6.2** Schedule `expire_missed_doses` via `pg_cron` every 5 minutes.
- [ ] **6.3** Add SQL trigger `tg_notification_to_fcm` calling `send-fcm` Edge Function.
- [ ] **6.4** pgtap test: insert DUE dose with scheduled_time in the past → run cron → status = MISSED + notifications inserted for patient + family.

## Phase 7 — Send-FCM Edge Function (1 day)

- [ ] **7.1** `supabase/functions/send-fcm/index.ts` — accepts `{token, title, body, data}`, validates auth header against shared secret, sends to FCM HTTP v1 API.
- [ ] **7.2** Service account JSON stored as Edge secret `FIREBASE_SERVICE_ACCOUNT_JSON`.
- [ ] **7.3** OAuth2 token caching (FCM HTTP v1 requires Bearer access token from service account JWT).
- [ ] **7.4** Unit test against fake FCM endpoint.
- [ ] **7.5** Add `profiles.fcm_token` column migration.
- [ ] **7.6** Flutter: register FCM token on sign-in, refresh on `onTokenRefresh`.

## Phase 8 — Settings (0.5 day)

- [ ] **8.1** `ReminderSettingsPage` with grace period choice, repeats toggle, per-med toggles.
- [ ] **8.2** Persist via `UPDATE profiles ...`.

## Phase 9 — Reboot & app-cycle (0.5 day)

- [ ] **9.1** On cold start, call `rescheduleAllPending()`.
- [ ] **9.2** On connectivity restore, refresh adherence cache.
- [ ] **9.3** iOS: roll notification window forward whenever app is opened (cap at 60 pending).

## Phase 10 — Tests (1 day)

- [ ] **10.1** Unit: scheduler, action handler, mark-dose use cases.
- [ ] **10.2** Widget: today page, adherence ring with green/yellow/red.
- [ ] **10.3** Integration: schedule → fire → action → row updated → server matches.
- [ ] **10.4** Manual QA matrix: airplane mode for 1 day → re-online → outbox drained, missed alerts arrive, family notifications sent.

## Phase 11 — Sign-off

- [ ] **11.1** Demo: notification fires offline → take → adherence updates → re-online → server sees TAKEN_LATE.
- [ ] **11.2** Demo: missed dose → cron fires → patient + family notifications appear.
- [ ] **11.3** Demo: device reboot → reminders still fire.
