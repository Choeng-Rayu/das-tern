# Feature: reminders

> Spec: [`.kiro/specs-v2-flutter-supabase/04-reminder-adherence/`](../../../../.kiro/specs-v2-flutter-supabase/04-reminder-adherence/)

Local-first reminder scheduling, dose tracking, adherence calculation, and
sync queue. Owns:
- DoseEvent generation (next 30 days from active prescriptions)
- `flutter_local_notifications` scheduling, including reschedule on boot
- Mark Taken / Missed / Skipped / Snooze actions
- Adherence percentage calculation
