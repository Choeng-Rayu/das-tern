# Requirements: Reminder System & Adherence Tracking (Offline-First)

## Introduction

This spec defines how Das Tern v2 fires medication reminders on the device (online and offline), records dose events, calculates adherence, and synchronizes everything with Supabase. The v1 server-side reminder queue is removed; reminders are entirely local. Server-side jobs only handle missed-dose detection (so connected peer-Patients — see ADDENDUM-001 — get alerts even when the patient's device is permanently offline).

## Glossary

- **Local_Notification** — A `flutter_local_notifications` scheduled notification that fires on the device.
- **Dose_Event** — A `dose_events` row with status `DUE/TAKEN_ON_TIME/TAKEN_LATE/MISSED/SKIPPED`.
- **Grace_Period** — Per-user `grace_period_minutes` (default 30) within which a dose taken counts as on-time.
- **Repeat_Reminder** — A follow-up notification fired up to 3 times every 5 minutes after the original if no action.
- **Adherence_Percentage** — `taken / scheduled × 100` over a window, excluding PRN.
- **Sync_Engine** — Existing `lib/core/sync/` infrastructure that drains the outbox.

## Requirements

### Requirement 1: Local notification scheduling

**User Story:** As a patient, I want notifications to fire at the scheduled times, so that I never miss a dose due to network issues.

#### Acceptance Criteria

1. WHEN a `dose_events` row is inserted with `status = 'DUE'`, THE Flutter_App SHALL schedule a local notification at `scheduled_time` with title `"<medicine_name> · <dosage>"` and body localized in the user's language.
2. THE Flutter_App SHALL include action buttons "Take", "Snooze", "Skip" on the notification (Android: action buttons; iOS: `UNNotificationCategory`).
3. WHEN the user taps a notification action, THE Flutter_App SHALL call the corresponding repository method which (a) updates Drift, (b) cancels future repeats, (c) enqueues an outbox op.
4. WHEN the prescription is paused or stopped, THE Flutter_App SHALL cancel all pending notifications for its dose events.
5. WHEN the user changes their grace period, THE Flutter_App SHALL recompute the cancel/missed window for already-scheduled notifications.

### Requirement 2: Repeat reminders

**User Story:** As a patient, I want a follow-up reminder if I miss the first one, so that I have a higher chance of remembering.

#### Acceptance Criteria

1. THE Flutter_App SHALL schedule up to 3 repeat notifications at +5, +10, +15 minutes after the original if the user has repeats enabled (default on).
2. THE Flutter_App SHALL cancel pending repeats as soon as the patient takes/snoozes/skips/dismisses the dose.
3. THE Flutter_App SHALL NOT fire repeats past the grace_period boundary (i.e., once the dose would be marked missed).
4. THE Flutter_App SHALL allow the user to disable repeats per medication or globally.

### Requirement 3: Snooze

**User Story:** As a patient, I want to snooze a reminder, so that I'm reminded again shortly when I'm ready.

#### Acceptance Criteria

1. WHEN the user taps "Snooze", THE Flutter_App SHALL offer +5, +10, +15 minute options.
2. THE Flutter_App SHALL reschedule the notification at `now + selected_duration` and set the dose row's `metadata.snoozed_count`.
3. THE Flutter_App SHALL allow up to 3 snoozes per dose; subsequent attempts hide the snooze option.
4. WHEN the snooze duration would exceed `scheduled_time + grace_period_minutes`, THE Flutter_App SHALL show a warning that the dose will be marked late if not taken before the grace cutoff.

### Requirement 4: Mark as taken

**User Story:** As a patient, I want one tap to mark my dose taken, so that adherence tracking is friction-free.

#### Acceptance Criteria

1. WHEN the user taps "Take" within the grace period, THE Flutter_App SHALL set `status = 'TAKEN_ON_TIME'`, `taken_at = now()`.
2. WHEN tapped after the grace period but within 24 hours, THE Flutter_App SHALL set `status = 'TAKEN_LATE'`.
3. WHEN tapped more than 24 hours after `scheduled_time`, THE Flutter_App SHALL show an error and not record the action.
4. THE Flutter_App SHALL call the SQL function `mark_dose(dose_id, status, taken_at, NULL, was_offline)` which atomically updates the row and writes the audit log.
5. WHEN the action is performed offline, THE Flutter_App SHALL set `was_offline = true` and queue the call.

### Requirement 5: Skip

**User Story:** As a patient, I want to skip a dose with an optional reason, so that my history reflects intentional decisions.

#### Acceptance Criteria

1. WHEN the user taps "Skip", THE Flutter_App SHALL show a reason dialog with presets (Feeling better, Side effects, Forgot to refill, Doctor advised, Other) and a free-text field for "Other".
2. THE Flutter_App SHALL allow skipping without selecting a reason.
3. THE Flutter_App SHALL call `mark_dose(dose_id, 'SKIPPED', NULL, reason, was_offline)`.
4. THE Flutter_App SHALL exclude SKIPPED doses from the "missed" alert pipeline.

### Requirement 6: Automatic missed detection (server-driven, late-binding)

**User Story:** As a connected peer-Patient (the person v1 called a "family member"), I want missed-dose alerts even when the patient's device is offline, so that I can intervene.

#### Acceptance Criteria

1. THE Postgres `expire_missed_doses()` cron job SHALL run every 5 minutes.
2. THE function SHALL update any `dose_events` where `status = 'DUE'` AND `scheduled_time + grace_period_minutes < now()` to `status = 'MISSED'`.
3. THE function SHALL emit a notification of type `MISSED_DOSE_ALERT` to the patient and to all connected peer-Patients (other PATIENT accounts) with `permission_level <> 'NOT_ALLOWED'`.
4. THE Flutter_App SHALL receive the notification via Supabase Realtime and (optionally) FCM push.
5. WHEN the patient's device is offline AND the cron later fires the missed notification, THE Flutter_App SHALL show a "Late notification" badge indicating the alert was sent post-sync.

### Requirement 7: Mark missed → taken (late recovery)

**User Story:** As a patient, I want to mark a missed dose as taken later, so that my adherence is accurate.

#### Acceptance Criteria

1. THE Flutter_App SHALL allow marking a `MISSED` dose as `TAKEN_LATE` for up to 24 hours after `scheduled_time`.
2. WHEN done, THE Flutter_App SHALL call `mark_dose(dose_id, 'TAKEN_LATE', now(), NULL, was_offline)`.
3. THE Flutter_App SHALL re-emit a notification to family of type `DOSE_CONFIRMED` so they know the patient recovered the dose.

### Requirement 8: Adherence calculation

**User Story:** As a patient, I want to see my adherence over time, so that I can track and improve.

#### Acceptance Criteria

1. THE Flutter_App SHALL display today's adherence, weekly (7d), monthly (30d), and 90-day adherence on the home screen.
2. THE Flutter_App SHALL call `get_adherence(patient_id, period)` for each period and cache results in Drift for 5 minutes.
3. THE Flutter_App SHALL color-code: ≥90% green, 70-89% yellow, <70% red.
4. THE Flutter_App SHALL show a 7-day adherence sparkline graph computed locally from Drift dose_events.
5. THE Flutter_App SHALL exclude PRN medications from all adherence math (already enforced server-side).

### Requirement 9: Today view

**User Story:** As a patient, I want to see today's schedule at a glance, so that I know what to take and when.

#### Acceptance Criteria

1. THE Flutter_App SHALL show today's doses grouped by `time_period` with each row showing: medication name, dosage, scheduled time, status badge.
2. THE Flutter_App SHALL show a "Next dose" card prominently with a countdown.
3. THE Flutter_App SHALL allow inline "Take" / "Skip" actions from the today view.
4. THE Flutter_App SHALL refresh the today view via Drift stream when realtime ingest updates rows.

### Requirement 10: Offline queueing

**User Story:** As a patient with intermittent connectivity, I want every action to land eventually, so that I don't lose data.

#### Acceptance Criteria

1. THE Flutter_App SHALL queue every `mark_dose` call as an outbox `RPC` op.
2. THE Flutter_App SHALL serialize ops in order; replay on connectivity restore in submitted order.
3. WHEN a queued op fails transiently (network), THE Flutter_App SHALL retry with exponential backoff.
4. WHEN a queued op fails permanently (server rejects with 4xx), THE Flutter_App SHALL surface a banner explaining the failure and suggest manual recovery.
5. THE outbox depth SHALL be observable on the diagnostics screen.

### Requirement 11: Reboot persistence

**User Story:** As an Android user who reboots the phone, I want reminders to keep working without re-launching the app.

#### Acceptance Criteria

1. THE Flutter_App SHALL register `flutter_local_notifications`'s boot receiver in `AndroidManifest.xml`.
2. WHEN the device boots, THE Flutter_App SHALL re-schedule the next 24 hours of pending notifications from Drift.
3. THE Flutter_App SHALL request `SCHEDULE_EXACT_ALARM` permission on Android 12+ for time-critical reminders.
4. THE Flutter_App SHALL handle the case where exact alarms are denied by falling back to inexact (and warning the user).

### Requirement 12: iOS notification budget

**User Story:** As an iOS user, I want reminders for the next several days to be queued, even though iOS limits pending notifications.

#### Acceptance Criteria

1. THE Flutter_App SHALL keep at most 60 pending notifications on iOS (under the 64 hard cap).
2. THE Flutter_App SHALL roll the notification window forward whenever the app is opened: cancel notifications older than now, schedule the next window.
3. THE Flutter_App SHALL use repeating calendar triggers when possible (e.g., daily at 08:00) to maximize budget efficiency.

### Requirement 13: Push notifications for family

**User Story:** As a peer-Patient, I want a push notification when my connected friend/family Patient misses a dose, so that I'm alerted even if my app is closed.

#### Acceptance Criteria

1. THE Flutter_App SHALL register an FCM token on sign-in and store it in `profiles.fcm_token` via UPDATE.
2. THE Postgres function emitting MISSED_DOSE_ALERT SHALL also enqueue an Edge Function call (`pg_net.http_post`) to a function that sends the FCM push.
3. THE Edge Function `send-fcm` SHALL call FCM with the recipient's token + localized payload.
4. THE Flutter_App SHALL handle the FCM message (foreground & background) and route to the relevant screen on tap.

### Requirement 14: Configurable grace period

**User Story:** As a patient, I want to adjust how strict "on time" is, so that the system matches my routine.

#### Acceptance Criteria

1. THE Flutter_App SHALL allow choosing 10, 20, 30, or 60 minutes for grace period.
2. WHEN changed, THE Flutter_App SHALL `UPDATE profiles SET grace_period_minutes = ?` and apply to future scheduling and missed detection.
3. THE Flutter_App SHALL NOT retroactively change the status of doses that were already marked using the old grace.
