# Tasks: Architecture Overview & Project Foundation

> Implementation roadmap for the foundational layer. These tasks must be done before any feature spec (03+) can be implemented end-to-end. They establish the project skeleton.

Each task is sized to a half-day to one day for an experienced Flutter developer. Boxes track completion.

## Phase 0 — Decisions and prerequisites (1 day)

- [ ] **0.1** Decide Supabase region (Singapore recommended for Cambodia latency). Update `00-overview/design.md` § "Open decisions".
- [ ] **0.2** Decide crash reporting tool (Sentry vs Crashlytics). Add to dependency list.
- [ ] **0.3** Confirm whether Telegram auth and iOS IAP are in MVP scope (default: Telegram in MVP, iOS IAP deferred).
- [ ] **0.4** Provision Supabase projects for `dev`, `staging`, `prod`.
- [ ] **0.5** Provision Firebase project (FCM only, no Firestore/Auth).
- [ ] **0.6** Create Google Play Console developer account, internal test track app.
- [ ] **0.7** Create Google Cloud Vision API project + service account, store JSON in 1Password (or similar).

## Phase 1 — Repo skeleton (1 day)

- [ ] **1.1** Create `.kiro/specs-v2-flutter-supabase/` (this folder, done by spec authoring).
- [ ] **1.2** Create `supabase/` directory with `migrations/`, `functions/`, `seed.sql`, `config.toml`.
- [ ] **1.3** Create `.agents/skills/` and run:
  ```bash
  npx skills add flutter/skills --skill '*' --agent universal
  npx skills add dart-lang/skills --skill '*' --agent universal
  ```
  Commit the results.
- [ ] **1.4** Author `.agents/skills/das-tern/add-feature/SKILL.md` with the feature-folder template.
- [ ] **1.5** Author `.agents/skills/das-tern/add-supabase-migration/SKILL.md`.
- [ ] **1.6** Author `.agents/skills/das-tern/add-riverpod-provider/SKILL.md`.
- [ ] **1.7** Author `.agents/skills/das-tern/add-edge-function/SKILL.md`.
- [ ] **1.8** Update root `README.md` to point to `.kiro/specs-v2-flutter-supabase/README.md` as the source of truth.

## Phase 2 — Flutter app skeleton (2 days)

- [ ] **2.1** In `das_tern_mcp/`, upgrade to Flutter 3.24+ stable, Dart 3.5+. Update `pubspec.yaml`.
- [ ] **2.2** Lock dependency versions:
  - `flutter_riverpod`, `freezed`, `json_serializable`, `build_runner`
  - `go_router`, `drift`, `drift_flutter`, `sqlite3_flutter_libs`
  - `supabase_flutter`, `flutter_secure_storage`, `connectivity_plus`
  - `flutter_local_notifications`, `firebase_messaging`, `firebase_core`
  - `google_sign_in`, `google_mlkit_text_recognition`, `flutter_tesseract_ocr`
  - `qr_flutter`, `mobile_scanner`, `camera`, `image_picker`
  - `in_app_purchase`, `intl`, `logger`, `sentry_flutter`
- [ ] **2.3** Create `lib/core/` subfolders: `config`, `error`, `i18n`, `logging`, `network`, `routing`, `storage/{drift,secure}`, `sync`, `theme`, `time`.
- [ ] **2.4** Create empty `lib/features/<name>/` folders for: `auth`, `prescriptions`, `reminders`, `connections`, `doctor_dashboard`, `ocr`, `billing`, `settings`.
- [ ] **2.5** Wire `Supabase.initialize()` in `main.dart` reading `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define`.
- [ ] **2.6** Wire Sentry/Crashlytics initialization with environment switch (skip in debug).
- [ ] **2.7** Create root `MaterialApp.router` with empty `GoRouter` config.
- [ ] **2.8** Create `lib/core/theme/` with light/dark `ThemeData` and shared `ColorScheme` tokens.
- [ ] **2.9** Create `lib/l10n/app_en.arb` and `lib/l10n/app_km.arb` with at least the app name and welcome strings; configure `flutter_localizations` in `MaterialApp`.
- [ ] **2.10** Add app icon + launch screen for Android and iOS.

## Phase 3 — Local storage + sync foundation (2 days)

- [ ] **3.1** Create `lib/core/storage/drift/app_database.dart` with empty `AppDatabase` class extending `_$AppDatabase`.
- [ ] **3.2** Create `OutboxEntries` table in Drift (id, table, op, payload JSONB, attempts, next_attempt_at, last_error, created_at).
- [ ] **3.3** Implement `OutboxDao` with `enqueue`, `dequeueBatch`, `markFailed`, `markSucceeded`.
- [ ] **3.4** Create `lib/core/sync/sync_engine.dart` with `start()`, `stop()`, `enqueue(op)`, internal `_drainOutbox()`, exponential-backoff helper.
- [ ] **3.5** Wire `connectivity_plus` listener to call `SyncEngine.drainNow()` when status flips to online.
- [ ] **3.6** Add `SecureStorage` wrapper class for session token, refresh token, and any encryption keys.
- [ ] **3.7** Riverpod providers: `appDatabaseProvider`, `supabaseClientProvider`, `syncEngineProvider`, `connectivityProvider`.
- [ ] **3.8** Unit tests: outbox enqueue/drain happy-path, exponential backoff math, Drift round-trip.

## Phase 4 — CI/CD baseline (1 day)

- [ ] **4.1** GitHub Action `flutter-ci.yml`:
  ```yaml
  on: [pull_request, push: [main]]
  jobs:
    analyze:
      - flutter pub get
      - dart format --output=none --set-exit-if-changed .
      - flutter analyze --fatal-warnings --fatal-infos
      - flutter test --coverage
      - upload coverage artifact
    android-debug:
      - flutter build apk --debug --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  ```
- [ ] **4.2** GitHub Action `supabase-staging-deploy.yml`:
  - On push to `main`, run `supabase db push --project-ref <staging-ref>` and `supabase functions deploy --project-ref <staging-ref>`.
  - Use `SUPABASE_ACCESS_TOKEN` from secrets.
- [ ] **4.3** GitHub Action `android-release.yml`:
  - Triggered on tag `v*`.
  - Build signed AAB with keystore from secrets.
  - Manual approval gate.
  - Upload to Play Console internal track via fastlane (or `r0adkll/upload-google-play`).
- [ ] **4.4** Branch protection rule on `main`: require PR, 1 reviewer, all checks green, no force push.
- [ ] **4.5** Add `CODEOWNERS` for `supabase/migrations/` and `.kiro/specs-v2-flutter-supabase/` (require review by senior engineer).

## Phase 5 — Observability + telemetry (0.5 day)

- [ ] **5.1** Configure Sentry DSN via `--dart-define=SENTRY_DSN=...`.
- [ ] **5.2** Add a `LogInterceptor` for Supabase calls that elides PII.
- [ ] **5.3** Add `kDebugMode` gate to Sentry init so debug builds don't pollute Sentry.
- [ ] **5.4** Add a "Diagnostics" screen in settings (build number, environment, Supabase project ref, last sync timestamp, outbox depth).

## Phase 6 — Documentation hand-off (0.5 day)

- [ ] **6.1** Write a "Getting Started" doc at `das_tern_mcp/README.md` covering: clone, `flutter pub get`, `supabase start`, `flutter run` with `--dart-define`s.
- [ ] **6.2** Document required secrets for each environment in `docs/SECRETS.md` (key names only, never values).
- [ ] **6.3** Document the Riverpod conventions and feature-folder pattern in `das_tern_mcp/AGENTS.md`.
- [ ] **6.4** Update root `README.md` to reflect the v2 architecture.

## Phase 7 — Sign-off

- [ ] **7.1** Demo: clean checkout → `flutter run` → app opens with empty home screen, theme/language toggle works.
- [ ] **7.2** Demo: airplane mode → click a stub "create prescription" button → outbox grows → re-enable network → outbox drains.
- [ ] **7.3** Stakeholder sign-off on architecture before kicking off feature specs (03+).

## Out of scope for this phase (handled in feature specs)

- Authentication flows (→ `02-authentication/tasks.md`).
- Any feature UI or business logic (→ feature spec tasks files).
- Production secret provisioning beyond placeholder env config.
- iOS-specific signing and TestFlight (deferred unless 0.3 says otherwise).

## Definitions of done

- A new contributor can clone, install, and run the app against local Supabase in under 30 minutes.
- CI green on a clean main.
- All four agent skills present and discoverable by `npx skills list`.
- Outbox drain demonstrated end-to-end against the local Supabase project.
