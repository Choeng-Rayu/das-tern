# Requirements: Architecture Overview & Project Foundation

## Introduction

This spec defines the foundational architecture, technology choices, and project structure for Das Tern v2 — a single Flutter codebase backed by Supabase. It is the umbrella spec that every other v2 spec builds on.

## Glossary

- **Flutter_App** — The single-codebase Flutter application targeting Android (primary), iOS (secondary), and optionally web for the doctor dashboard.
- **Supabase_Project** — The managed Supabase project hosting Postgres, Auth, Storage, Edge Functions, and Realtime.
- **Edge_Function** — A Deno-based HTTP function deployed to Supabase, used only for tasks that require server-side credentials or webhooks.
- **RLS** — Row-Level Security; Postgres feature used to enforce tenant isolation on every table.
- **Local_Store** — On-device persistent storage (Drift/SQLite for relational data, flutter_secure_storage for tokens, SharedPreferences for simple flags).
- **Sync_Engine** — The Flutter component that reconciles `Local_Store` with Supabase Postgres when connectivity returns.
- **Offline_First** — A design property where every patient-facing mutation is recorded locally first and synced opportunistically.
- **Agent_Skill** — A markdown blueprint installed under `.agents/skills/` that gives AI coding assistants domain-specific procedures.

## Requirements

### Requirement 1: Single Flutter codebase

**User Story:** As a developer, I want a single Flutter codebase that targets Android, iOS, and (optionally) web, so that I can ship features once and reach every platform without duplicating code.

#### Acceptance Criteria

1. THE Flutter_App SHALL use Flutter 3.24+ stable with Dart 3.5+.
2. THE Flutter_App SHALL be a single codebase under `das_tern_mcp/lib/` with platform-specific code isolated to `lib/platform/<platform_name>/`.
3. THE Flutter_App SHALL declare `android` and `ios` as primary targets in `pubspec.yaml` and successfully `flutter build apk` and `flutter build ios` on a clean checkout.
4. THE Flutter_App SHALL pin all major dependencies to exact versions in `pubspec.yaml` to prevent supply-chain drift.
5. THE Flutter_App SHALL run `dart format` and `flutter analyze` cleanly as a CI gate before any merge.

### Requirement 2: Supabase as the only managed backend

**User Story:** As an architect, I want a single managed backend, so that the operational surface is small and predictable.

#### Acceptance Criteria

1. THE Flutter_App SHALL connect to exactly one Supabase_Project per environment (dev, staging, production).
2. THE Flutter_App SHALL NOT depend on any custom-hosted HTTP API beyond Supabase. (NestJS, Bakong service, Python OCR service, AI/LLM service, and any nginx fronting them are explicitly out of scope.)
3. THE Supabase_Project SHALL host the Postgres database for all relational data.
4. THE Supabase_Project SHALL host all binary assets (prescription images, profile photos) in named Storage buckets.
5. THE Supabase_Project SHALL host all server-side logic that requires privileged credentials in Edge_Functions.
6. WHEN a feature appears to require a custom backend service, THE designer SHALL first attempt to express it as (a) RLS-protected SQL, (b) a Postgres function, or (c) an Edge_Function, in that order of preference.

### Requirement 3: Project structure

**User Story:** As a developer, I want a predictable project structure, so that I can find code quickly and onboard new contributors fast.

#### Acceptance Criteria

1. THE Flutter_App SHALL organize code under `das_tern_mcp/lib/` using feature-first folders: `lib/features/<feature_name>/{data,domain,presentation}/`.
2. THE Flutter_App SHALL place cross-cutting code under `lib/core/` (theme, networking, error handling, logging) and `lib/shared/widgets/` for reusable widgets. Localization assets (ARB sources, the generated `AppLocalizations`, and `locale_controller.dart`) live under `lib/l10n/`.
3. THE Flutter_App SHALL keep generated code (`*.g.dart`, `*.freezed.dart`) committed to the repo so CI builds do not need code generation by default.
4. THE Supabase_Project SQL SHALL live under `supabase/migrations/` with timestamped filenames (`YYYYMMDDHHMMSS_<description>.sql`).
5. THE Supabase_Project Edge Functions SHALL live under `supabase/functions/<function_name>/index.ts` with a `_shared/` folder for code reused across functions.
6. THE Supabase_Project SHALL include a `supabase/seed.sql` for local development data (no production secrets).
7. THE repository root SHALL contain `.agents/skills/` populated by the official Flutter and Dart skills repositories.

### Requirement 4: State management and data flow

**User Story:** As a developer, I want a consistent state-management pattern, so that every feature is read and reasoned about the same way.

#### Acceptance Criteria

1. THE Flutter_App SHALL use Riverpod 2.x (`flutter_riverpod`) as the single state-management solution.
2. THE Flutter_App SHALL expose Supabase queries through repository classes registered as Riverpod providers; UI widgets SHALL NOT call Supabase directly.
3. THE Flutter_App SHALL model domain entities as immutable classes generated by `freezed`.
4. THE Flutter_App SHALL use `AsyncValue<T>` from Riverpod for any UI state that originates from an asynchronous source.
5. WHEN a screen mutates data, THE Flutter_App SHALL invalidate the affected Riverpod providers so dependent views refresh.

### Requirement 5: Local storage and offline-first

**User Story:** As a patient, I want the app to work offline so that I can still log doses and create prescriptions when my network is down.

#### Acceptance Criteria

1. THE Flutter_App SHALL use Drift (SQLite) as the relational `Local_Store`.
2. THE Flutter_App SHALL use `flutter_secure_storage` for the Supabase session token, refresh token, and any encryption keys.
3. THE Flutter_App SHALL use a single `Sync_Engine` that owns the read-through, write-through, and conflict-resolution logic between Drift and Supabase.
4. THE Flutter_App SHALL queue every mutation while offline as an `OutboxEntry` row in Drift; the queue SHALL survive process restarts.
5. WHEN the device regains connectivity, THE Sync_Engine SHALL drain the outbox in submission order, retry transient failures with exponential backoff (max 5 attempts), and surface permanent failures to the user.
6. THE Flutter_App SHALL display an "Offline" indicator in the app shell when `Connectivity().status == none`.

### Requirement 6: Observability

**User Story:** As an engineer on call, I want logs and crash reports, so that I can debug production issues.

#### Acceptance Criteria

1. THE Flutter_App SHALL use `package:logger` (or equivalent) with a per-environment log level (verbose in debug, info in release).
2. THE Flutter_App SHALL ship Sentry (or Firebase Crashlytics) for uncaught exception reporting in release builds.
3. THE Flutter_App SHALL NOT log PII (patient names, phone numbers, prescription text) at any level.
4. THE Supabase_Project Edge_Functions SHALL emit structured JSON logs that Supabase's log explorer can index.

### Requirement 7: Security baseline

**User Story:** As a patient, I want my medical data secure, so that no unauthorized party can read or modify it.

#### Acceptance Criteria

1. THE Supabase_Project SHALL enable RLS on every table that contains user-owned data (no exceptions).
2. THE Supabase_Project SHALL store the Supabase `anon` key in the Flutter app and NEVER ship the `service_role` key to clients.
3. THE Supabase_Project Edge_Functions SHALL read secrets (Google service-account JSON, Vision API key, RTDN webhook authorization secret) from Supabase Edge Function secrets, never from request bodies or logged output.
4. THE Flutter_App SHALL pin Supabase TLS to the certificate authority bundle shipped with Flutter and reject any custom CA installation in release builds (best-effort cert pinning).
5. THE Flutter_App SHALL store the active Supabase session in `flutter_secure_storage` only.
6. THE Flutter_App SHALL request only the minimum Android permissions: camera (OCR), notifications (reminders), `POST_NOTIFICATIONS` (Android 13+), `SCHEDULE_EXACT_ALARM` (reminder accuracy on Android 12+).

### Requirement 8: Localization & theming foundation

**User Story:** As a patient in Cambodia, I want the app in Khmer with a dark mode, so that it matches my language and lighting.

#### Acceptance Criteria

1. THE Flutter_App SHALL use `flutter_localizations` + ARB files under `lib/l10n/` with two locales: `km` (Khmer, default) and `en` (English).
2. THE Flutter_App SHALL fall back to English when a Khmer string is missing and emit a debug warning (never a crash).
3. THE Flutter_App SHALL ship light and dark `ThemeData` with shared `ColorScheme` tokens defined in `lib/core/theme/`.
4. WHEN the user toggles language or theme, THE Flutter_App SHALL persist the choice in SharedPreferences and apply without restart.
5. THE Flutter_App SHALL respect the device locale and theme on first launch if the user has no saved preference.

### Requirement 9: CI/CD baseline

**User Story:** As a team, we want every PR to be checked automatically, so that broken code does not reach main.

#### Acceptance Criteria

1. THE repository SHALL include a GitHub Actions workflow that runs `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed`, and a debug Android build on every PR.
2. THE repository SHALL include a workflow that applies pending Supabase migrations to a staging project on merge to `main`.
3. THE repository SHALL include a release workflow gated by manual approval that builds a signed Android App Bundle (AAB).
4. THE repository SHALL prohibit direct pushes to `main` and require at least one reviewer.

### Requirement 10: Agent skills installed

**User Story:** As a developer using AI assistants, I want the project to ship with Flutter and Dart skills, so that the assistant follows the team's conventions.

#### Acceptance Criteria

1. THE repository SHALL contain `.agents/skills/flutter/` populated from `flutter/skills` GitHub repository.
2. THE repository SHALL contain `.agents/skills/dart-lang/` populated from `dart-lang/skills` GitHub repository.
3. THE repository SHALL contain `.agents/skills/das-tern/` with project-specific skills covering: (a) creating a new feature module, (b) adding a Supabase migration with RLS, (c) wiring a new Riverpod provider, (d) adding a new Edge Function with secrets.
4. THE repository SHALL document how to refresh skills (`npx skills add flutter/skills --skill '*' --agent universal`) in `00-overview/design.md`.
