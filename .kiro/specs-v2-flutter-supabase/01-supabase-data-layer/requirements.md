# Requirements: Supabase Data Layer (Postgres + RLS + Storage)

## Introduction

This spec defines the persistent data layer for Das Tern v2: the Postgres schema, Row-Level Security policies, Storage buckets, Realtime publications, and the migration strategy that ports the v1 Prisma schema (16+ models) into a fully RLS-protected Supabase project.

The schema is **functionally equivalent** to v1, but every cross-tenant guarantee that v1 enforced in NestJS service code is now enforced by Postgres RLS so the Flutter app can talk to the database directly without an application server.

## Glossary

- **profiles** — Per-user profile row keyed by Supabase `auth.uid()`. Replaces v1 `User` rows for Supabase-managed auth attributes.
- **RLS** — Row-Level Security policy enforced by Postgres on every `SELECT/INSERT/UPDATE/DELETE`.
- **policy_helper** — A SQL function (e.g., `is_connected_doctor(patient_id uuid)`) used inside multiple RLS policies to keep them DRY.
- **service_role** — Supabase admin key used only inside Edge Functions, never in the client.
- **realtime** — Supabase Realtime; per-table publication that streams changes via WebSocket.
- **storage_bucket** — A namespaced object container in Supabase Storage with its own RLS-style access policies.

## Requirements

### Requirement 1: Schema parity with v1

**User Story:** As a migration engineer, I want the v2 Postgres schema to express the same domain as v1, so that the existing Flutter UI logic and v1 business rules transfer without semantic loss.

#### Acceptance Criteria

1. THE Supabase_Project SHALL include every v1 entity that powers an MVP feature: `profiles` (replaces `users`), `connections`, `connection_tokens`, `prescriptions`, `prescription_versions`, `medications`, `dose_events`, `notifications`, `audit_logs`, `subscriptions`, `family_members`, `meal_time_preferences`, `doctor_notes`, `medication_batches`.
2. THE Supabase_Project SHALL keep the v1 enums verbatim *except* `user_role`, which is reduced to `('PATIENT', 'DOCTOR')` per ADDENDUM-001. The remaining enums are unchanged: `gender`, `language`, `theme`, `account_status`, `connection_status`, `permission_level`, `prescription_status`, `time_period`, `dose_event_status`, `subscription_tier`, `notification_type`, `audit_action_type`, `medicine_type`, `medicine_unit`.
3. THE Supabase_Project MAY defer (but not delete) `health_vitals`, `vital_thresholds`, `health_alerts` until those features ship; the tables SHALL exist with RLS enabled to avoid blocking future work.
4. THE Supabase_Project SHALL include all v1 Prisma indexes (e.g., `dose_events(patient_id, scheduled_time)`, `prescriptions(patient_id, status)`, `notifications(recipient_id, is_read)`).
5. THE Supabase_Project SHALL preserve column types (UUID for ids, `timestamptz` for timestamps, `jsonb` for dosage payloads).

### Requirement 2: profiles table bound to Supabase Auth

**User Story:** As a developer, I want each authenticated user to have a `profiles` row that mirrors my existing v1 user fields, so that I can reference user data by `auth.uid()`.

#### Acceptance Criteria

1. THE Supabase_Project SHALL define `public.profiles` with primary key `id uuid` referencing `auth.users(id) ON DELETE CASCADE`.
2. THE Supabase_Project SHALL include columns from v1 `User`: `role`, `first_name`, `last_name`, `full_name`, `phone_number`, `email`, `gender`, `date_of_birth`, `id_card_number`, `profile_picture_url`, `language`, `theme`, `hospital_clinic`, `specialty`, `license_number`, `license_photo_url`, `grace_period_minutes`, `account_status`, `created_at`, `updated_at`.
3. THE Supabase_Project SHALL NOT store `password_hash` (Supabase Auth owns credentials) or `failed_login_attempts` / `locked_until` / `reset_token` / `reset_token_expiry` (Supabase Auth owns these).
4. THE Supabase_Project SHALL maintain `telegram_id`, `telegram_username`, `telegram_first_name`, `telegram_last_name`, `telegram_photo_url` columns to support Telegram OIDC linking.
5. THE Supabase_Project SHALL provide a Postgres trigger `on_auth_user_created` that inserts a `profiles` row with `role = 'PATIENT'` (default), `language = 'KHMER'`, `theme = 'LIGHT'` whenever a new `auth.users` row is created.
6. THE Supabase_Project SHALL allow each user to read and update only their own `profiles` row (RLS).

### Requirement 3: RLS enabled by default on every domain table

**User Story:** As a security engineer, I want every domain table protected by RLS, so that a leaked anon key cannot expose another user's data.

#### Acceptance Criteria

1. THE Supabase_Project SHALL execute `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` on every table in the `public` schema except enum/lookup tables.
2. THE Supabase_Project SHALL execute `ALTER TABLE ... FORCE ROW LEVEL SECURITY` so that even the table owner is subject to RLS unless using service_role.
3. THE Supabase_Project SHALL define explicit `SELECT`, `INSERT`, `UPDATE`, `DELETE` policies on every table — no implicit deny relying solely on no-policy state.
4. THE Supabase_Project SHALL test every RLS policy with `pgtap` in CI before any migration merges to main.
5. THE Supabase_Project SHALL document each policy's intent in an SQL `COMMENT ON POLICY` statement so it's self-describing in `pg_policies`.

### Requirement 4: Patient-as-owner policies

**User Story:** As a patient, I want only myself, my connected doctors, and my approved family members to read my prescriptions/medications/dose events, so that my medical data stays private.

#### Acceptance Criteria

1. THE Supabase_Project SHALL allow a patient to `SELECT/INSERT/UPDATE/DELETE` rows in `prescriptions`, `medications`, `dose_events`, `prescription_versions`, `meal_time_preferences`, `medication_batches` where `patient_id = auth.uid()`.
2. THE Supabase_Project SHALL allow a doctor to `SELECT` patient rows where an accepted `connections` row exists with `recipient_id = auth.uid()` (or `initiator_id`) AND `status = 'ACCEPTED'` AND `permission_level <> 'NOT_ALLOWED'`.
3. THE Supabase_Project SHALL allow a doctor to `INSERT` rows in `prescriptions` and `medications` for a connected patient only when the connection's `permission_level = 'ALLOWED'`.
4. THE Supabase_Project SHALL allow a Patient to `SELECT` rows from another Patient's `prescriptions`, `medications`, and `dose_events` when an ACCEPTED Patient↔Patient connection exists with `permission_level <> 'NOT_ALLOWED'` (mutual visibility — see ADDENDUM-001). Both Patients are subject to the connection-limit trigger.
5. THE Supabase_Project SHALL prohibit any user (other than the patient or service_role) from `DELETE`-ing a `dose_events` row.

### Requirement 5: Connection token policies

**User Story:** As a patient, I want only valid, unused, unexpired tokens to be consumable, so that connection tokens cannot be replayed.

#### Acceptance Criteria

1. THE Supabase_Project SHALL allow the patient to `INSERT` a row in `connection_tokens` for themselves.
2. THE Supabase_Project SHALL allow the patient to `SELECT` their own connection tokens.
3. THE Supabase_Project SHALL allow any authenticated user to `SELECT` a single token row by exact `token` match if `expires_at > now()` AND `used_at IS NULL` (this is the validation step).
4. THE Supabase_Project SHALL allow any authenticated user to `UPDATE` a token row to set `used_at = now()` and `used_by_id = auth.uid()` ATOMICALLY, but only when `used_at IS NULL`.
5. THE Supabase_Project SHALL run a daily Postgres cron job that deletes tokens older than 30 days.

### Requirement 6: Subscription policies

**User Story:** As a billing engineer, I want subscription state to be writable only by Edge Functions, so that the client cannot fake premium status.

#### Acceptance Criteria

1. THE Supabase_Project SHALL allow each user to `SELECT` only their own `subscriptions` row.
2. THE Supabase_Project SHALL prohibit any non-`service_role` connection from `INSERT`/`UPDATE`/`DELETE` on `subscriptions`.
3. THE Supabase_Project SHALL allow `INSERT`/`UPDATE` on `subscriptions` only when `current_setting('request.jwt.claims', true)::json->>'role' = 'service_role'` (i.e., from Edge Functions using the service role).
4. THE Supabase_Project SHALL allow each user to `SELECT` `family_members` rows for subscriptions they own or where they are a member.
5. THE Supabase_Project SHALL prohibit non-service-role writes to `family_members`.

### Requirement 7: Audit log policies

**User Story:** As a compliance officer, I want audit logs to be append-only and readable only by their owning user, so that we have tamper-evident traceability.

#### Acceptance Criteria

1. THE Supabase_Project SHALL allow each user to `SELECT` `audit_logs` rows where `actor_id = auth.uid()`.
2. THE Supabase_Project SHALL allow patients to `SELECT` `audit_logs` rows that target their resources (e.g., prescriptions they own) regardless of actor.
3. THE Supabase_Project SHALL prohibit any client (anon or authenticated) from `UPDATE`/`DELETE` on `audit_logs`.
4. THE Supabase_Project SHALL allow `INSERT` on `audit_logs` from authenticated clients only via Postgres functions (never direct INSERT) to enforce field-shape and prevent forgery.

### Requirement 8: Notifications policies

**User Story:** As a user, I want only my own notifications visible, so that other people's alerts don't leak into my feed.

#### Acceptance Criteria

1. THE Supabase_Project SHALL allow each user to `SELECT/UPDATE` `notifications` rows where `recipient_id = auth.uid()`.
2. THE Supabase_Project SHALL prohibit `INSERT` on `notifications` from non-service-role connections (notifications are created by Postgres functions / Edge Functions).
3. THE Supabase_Project SHALL allow each user to mark their own notifications as read (`UPDATE is_read = true, read_at = now()`).

### Requirement 9: Storage buckets and policies

**User Story:** As a patient, I want my profile picture and prescription photos protected, so that nobody else can fetch my files.

#### Acceptance Criteria

1. THE Supabase_Project SHALL create a private `profile-pictures` bucket. Path convention: `{user_id}/{filename}`.
2. THE Supabase_Project SHALL create a private `prescription-images` bucket for OCR source images. Path convention: `{patient_id}/{prescription_id}/{filename}`.
3. THE Supabase_Project SHALL create a private `doctor-licenses` bucket for verification photos. Path convention: `{doctor_id}/{filename}`.
4. THE Supabase_Project SHALL create a public `app-assets` bucket for static UI assets (illustrations, default avatars).
5. EACH private bucket SHALL have policies: a user can read/write objects under their own `user_id` prefix; doctors can read prescription images of connected patients (same RLS-equivalent as `prescriptions` table).
6. THE Flutter_App SHALL never embed Supabase service role key; uploads go through user-scoped tokens, with a 50 MB per-object size cap and `image/*` MIME allowlist.

### Requirement 10: Realtime publications

**User Story:** As a connected family member, I want my dashboard to update live when the patient takes a dose, so that I have near-real-time visibility.

#### Acceptance Criteria

1. THE Supabase_Project SHALL include `dose_events`, `notifications`, `prescriptions`, `connections` in the `supabase_realtime` publication.
2. THE Supabase_Project SHALL ensure RLS applies on the realtime stream (so subscribers only receive changes they could SELECT).
3. THE Supabase_Project SHALL emit `INSERT`, `UPDATE`, `DELETE` events for the published tables.
4. THE Flutter_App SHALL subscribe to a single channel per active screen and unsubscribe on dispose to avoid socket leaks.

### Requirement 11: Postgres functions for cross-table integrity

**User Story:** As a developer, I want certain operations expressed as SQL functions, so that race conditions and audit-log writes are atomic.

#### Acceptance Criteria

1. THE Supabase_Project SHALL provide `accept_connection(connection_id uuid, permission permission_level)` — atomically updates the connection, writes audit log, and returns the updated row.
2. THE Supabase_Project SHALL provide `consume_connection_token(token text)` — atomically validates, marks used, creates a `PENDING` connection, returns the connection id (or raises).
3. THE Supabase_Project SHALL provide `mark_dose(dose_id uuid, status dose_event_status, taken_at timestamptz, skip_reason text)` — atomically updates the dose row and writes audit log; rejects if status transition is invalid.
4. THE Supabase_Project SHALL provide `create_audit_log(...)` as the only path for clients to write audit rows.
5. THE Supabase_Project SHALL provide `get_adherence(patient_id uuid, period text)` — returns adherence percentage for the requested period using the indexed `dose_events` table.
6. EVERY function SHALL be defined `SECURITY DEFINER` only when it must elevate; otherwise `SECURITY INVOKER`.

### Requirement 12: Migration strategy and seeds

**User Story:** As a team, we want versioned, replayable migrations, so that any environment can be brought up consistently.

#### Acceptance Criteria

1. THE Supabase_Project SHALL store SQL under `supabase/migrations/<timestamp>_<description>.sql`.
2. THE Supabase_Project SHALL include a seed script `supabase/seed.sql` for local development containing: 1 doctor, 1 patient, 1 family member, 1 prescription with 2 medications, 7 days of dose events.
3. THE Supabase_Project SHALL keep migrations forward-only; corrective migrations SHALL be additive.
4. THE Supabase_Project SHALL support local reset via `supabase db reset` and remote application via `supabase db push`.
5. THE Supabase_Project SHALL include a `pgtap`-based test suite for RLS policies and core functions, runnable via `supabase test db`.

### Requirement 13: Drift mirror schema

**User Story:** As an offline-first developer, I want a local SQLite mirror that matches the Supabase schema 1:1 for the tables a user can read, so that the sync engine can read-through and write-through without translation.

#### Acceptance Criteria

1. THE Flutter_App SHALL include Drift table definitions for `profiles`, `connections`, `prescriptions`, `medications`, `dose_events`, `notifications`, `meal_time_preferences`, `medication_batches`, `connection_tokens`, `subscriptions`, `family_members`, `prescription_versions`, `doctor_notes`.
2. THE Flutter_App SHALL store enum columns as `text` and validate values in Dart code mirroring the Postgres enum names exactly.
3. THE Flutter_App SHALL store JSONB columns as `text` (serialized) in Drift and parse on read.
4. THE Flutter_App SHALL include a Drift migration version number that bumps whenever the Supabase schema bumps.
5. THE Flutter_App SHALL implement an idempotent `bootstrapFromRemote()` that downloads the user's full visible dataset on first sign-in or after a destructive sign-out.

### Requirement 14: Time and timezone

**User Story:** As a Cambodian user, I want all reminders to fire in Asia/Phnom_Penh by default, so that "morning" means morning where I live.

#### Acceptance Criteria

1. THE Supabase_Project SHALL store all timestamps in UTC (`timestamptz`).
2. THE Supabase_Project SHALL store user-facing time-of-day fields (e.g., `meal_time_preferences.morning_meal`) as `time` or string `HH:MM` interpreted in the patient's preferred timezone.
3. THE Supabase_Project SHALL include a `timezone text` column on `profiles`, defaulting to `'Asia/Phnom_Penh'`.
4. THE Flutter_App SHALL display all timestamps in the user's timezone.
5. WHEN a patient travels to another timezone, THE Flutter_App SHALL prompt to either (a) keep reminders on Cambodia local time, or (b) follow device local time. The choice is stored in `profiles.timezone` and referenced when generating local notifications.
