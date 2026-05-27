# Tasks: Supabase Data Layer (Postgres + RLS + Storage)

> Implement the data foundation. Must be done immediately after Phase 1 of `00-overview/tasks.md`.

## Phase 1 — Migrations (3 days)

- [x] **1.1** `supabase/migrations/20260601000000_enums.sql`
- [x] **1.2** `supabase/migrations/20260601000001_profiles.sql`
- [x] **1.3** `supabase/migrations/20260601000002_connections.sql`
- [x] **1.4** `supabase/migrations/20260601000003_connection_tokens.sql`
- [x] **1.5** `supabase/migrations/20260601000004_prescriptions.sql`
- [x] **1.6** `supabase/migrations/20260601000005_medications.sql`
- [x] **1.7** `supabase/migrations/20260601000006_dose_events.sql`
- [x] **1.8** `supabase/migrations/20260601000007_notifications.sql`
- [x] **1.9** `supabase/migrations/20260601000008_audit_logs.sql`
- [x] **1.10** `supabase/migrations/20260601000009_subscriptions.sql`
- [x] **1.11** `supabase/migrations/20260601000010_other.sql`
- [x] **1.12** `supabase/migrations/20260601000100_policy_helpers.sql`
- [x] **1.13** `supabase/migrations/20260601000200_functions.sql`
- [x] **1.14** `supabase/migrations/20260601000300_realtime.sql`
- [x] **1.15** `supabase/migrations/20260601000400_storage.sql`
- [x] **1.16** `supabase/migrations/20260601000500_pg_cron.sql`

## Phase 2 — Seed data (0.5 day)

- [x] **2.1** `supabase/seed.sql` — 1 doctor, 2 patients, connections, prescription, medications, 7 dose events, subscriptions, meal_time_preferences.
  - 1 doctor profile (with hospital, license).
  - 1 patient profile (Khmer language, Asia/Phnom_Penh).
  - 1 second patient profile (the "family/peer" — also role = 'PATIENT' per ADDENDUM-001).
  - 1 ACCEPTED Doctor↔Patient connection (`permission_level = 'ALLOWED'`).
  - 1 ACCEPTED Patient↔Patient peer connection (`permission_level = 'ALLOWED'`).
  - 1 active prescription with 2 medications (one ORAL/TABLET twice daily, one ORAL/CAPSULE PRN).
  - 7 days of dose events (mix of TAKEN_ON_TIME, TAKEN_LATE, MISSED).
  - 1 FREEMIUM subscription per patient.
  - 1 meal_time_preferences row per patient.

## Phase 3 — pgtap RLS test suite (2 days)

- [ ] **3.1** Set up `supabase/tests/` with test runner config.
- [ ] **3.2** `supabase/tests/rls/profiles.test.sql` — own select/update; cross-user blocked.
- [ ] **3.3** `supabase/tests/rls/connections.test.sql` — initiator/recipient access; non-party blocked.
- [ ] **3.4** `supabase/tests/rls/prescriptions.test.sql` — patient owns; connected doctor read; non-connected doctor blocked; peer-Patient read (mutual, ADDENDUM-001); doctor write requires ALLOWED.
- [ ] **3.5** `supabase/tests/rls/dose_events.test.sql` — patient writes; doctor/family read; deletion only by patient.
- [ ] **3.6** `supabase/tests/rls/notifications.test.sql` — recipient read/update; no client insert.
- [ ] **3.7** `supabase/tests/rls/audit_logs.test.sql` — actor select; resource owner select; no update/delete; no direct insert.
- [ ] **3.8** `supabase/tests/rls/subscriptions.test.sql` — self select; no client write; service_role can write.
- [ ] **3.9** `supabase/tests/rls/storage.test.sql` — bucket folder isolation by user_id; doctor read on prescription-images.
- [ ] **3.10** `supabase/tests/functions/consume_token.test.sql` — happy path, expired, used, self-connection blocked.
- [ ] **3.11** `supabase/tests/functions/mark_dose.test.sql` — valid transitions, invalid transitions raise.
- [ ] **3.12** `supabase/tests/functions/get_adherence.test.sql` — known data set returns expected percent.
- [ ] **3.13** Wire pgtap into CI: `supabase test db` runs on every PR.

## Phase 4 — Drift schema mirror (2 days)

- [x] **4.1** `lib/core/storage/drift/tables/profiles_table.dart`.
- [x] **4.2** `lib/core/storage/drift/tables/connections_table.dart` + `connection_tokens_table.dart`.
- [x] **4.3** `lib/core/storage/drift/tables/prescriptions_table.dart` + `prescription_versions_table.dart`.
- [x] **4.4** `lib/core/storage/drift/tables/medications_table.dart`.
- [x] **4.5** `lib/core/storage/drift/tables/dose_events_table.dart`.
- [x] **4.6** `lib/core/storage/drift/tables/notifications_table.dart`.
- [x] **4.7** `lib/core/storage/drift/tables/audit_logs_table.dart` (read-only mirror).
- [x] **4.8** `lib/core/storage/drift/tables/subscriptions_table.dart` + `family_members_table.dart`.
- [x] **4.9** `lib/core/storage/drift/tables/meal_time_preferences_table.dart` + `doctor_notes_table.dart` + `medication_batches_table.dart`.
- [x] **4.10** `lib/core/storage/drift/tables/outbox_entries_table.dart` (already in 00-overview).
- [x] **4.11** Generate Drift code: `dart run build_runner build --delete-conflicting-outputs`.
- [x] **4.12** DAO classes for each table with `watch*()` reactive queries and CRUD.
- [x] **4.13** Drift schema test: create empty DB → run migrations → verify schema.

## Phase 5 — Repository layer wiring (1 day)

- [x] **5.1** `lib/core/data/repository.dart` — base `Repository` with `localStream`, `enqueueOp`, `bootstrapFromRemote`.
- [x] **5.2** Riverpod providers for each repository (will be filled in by feature specs).
- [x] **5.3** `BootstrapService` — on first sign-in, fetch user's full visible dataset (profile, connections, prescriptions, medications, future dose_events) and seed Drift.

## Phase 6 — Realtime wiring (1 day)

- [x] **6.1** `lib/core/sync/realtime_subscriber.dart` — subscribe to `dose_events`, `notifications`, `prescriptions`, `connections` channels with RLS filter applied server-side.
- [x] **6.2** Merge incoming changes into Drift; emit Riverpod invalidations.
- [x] **6.3** Lifecycle: subscribe on sign-in, unsubscribe on sign-out / app close.
- [x] **6.4** Reconnect logic: on socket disconnect, reconnect with exponential backoff up to 60s.

## Phase 7 — Storage upload helpers (0.5 day)

- [x] **7.1** `lib/core/storage/supabase_storage.dart` — typed wrapper for upload/get-signed-url.
- [x] **7.2** Path builders that enforce `{user_id}/...` prefix automatically.
- [x] **7.3** 50 MB size cap enforced client-side; server-side enforced by Storage policy file size limit.

## Phase 8 — Cron and maintenance (0.5 day)

- [ ] **8.1** Confirm `pg_cron` extension enabled on the Supabase project.
- [ ] **8.2** Verify `expire_missed_doses` runs every 5 minutes in production.
- [ ] **8.3** Verify token cleanup runs daily.
- [ ] **8.4** Add Sentry breadcrumb / log hook for cron failures.

## Phase 9 — Hardening (1 day)

- [ ] **9.1** Verify every `public.*` table has `enable row level security` AND `force row level security` set; add a CI test that fails if any table lacks both.
- [ ] **9.2** Verify no policy uses `using (true)` except in clearly intentional cases (storage public bucket only).
- [ ] **9.3** Verify all `security definer` functions list the explicit `set search_path = public`.
- [ ] **9.4** Run a "leakage test" with Supabase JS client and a forged JWT for user A trying to read user B's rows; expect zero results.
- [ ] **9.5** Document RLS policies in `docs/SECURITY.md` for compliance review.

## Phase 10 — Sign-off

- [ ] **10.1** Demo: clean checkout → `supabase db reset` → seed loads → pgtap suite green → Flutter app reads/writes prescription via repository → outbox flushes to Supabase.
- [ ] **10.2** Demo: log in as patient A, attempt to read patient B's prescriptions → empty list (verified via PostgREST raw call).
- [ ] **10.3** Demo: doctor connected with `permission_level = 'NOT_ALLOWED'` cannot see prescriptions; toggling to `ALLOWED` reveals them in real-time.
- [ ] **10.4** Stakeholder + security reviewer sign-off on RLS policies.

## Definitions of done

- Every domain table has `enable + force` RLS, explicit policies, and pgtap coverage.
- Drift schema in sync with Supabase schema (verified by a generated checksum).
- Bootstrap can populate a fresh Flutter install from Supabase in < 5 seconds for the seed dataset.
- Realtime updates land in Drift within 2 seconds of a remote change in 95% of test runs.
