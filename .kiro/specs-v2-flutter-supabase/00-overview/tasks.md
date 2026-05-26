# Tasks: Architecture Overview & Project Foundation

> Implementation roadmap for the foundational layer. These tasks must be done before any feature spec (03+) can be implemented end-to-end. They establish the project skeleton.

Each task is sized to a half-day to one day for an experienced Flutter developer. Boxes track completion.

## Phase 0 — Decisions and prerequisites (1 day)

- [x] **0.1** Decide Supabase region (Singapore recommended for Cambodia latency). Update `00-overview/design.md` § "Open decisions".
- [x] **0.2** Decide crash reporting tool (Sentry vs Crashlytics). Add to dependency list. → **Sentry** chosen.
- [x] **0.3** Confirm whether Telegram auth and iOS IAP are in MVP scope. → **Telegram in MVP, iOS IAP deferred**.
- [x] **0.4** Provision Supabase projects. → Project `epextungmzestfnnccgu` (ap-southeast-1 / Singapore) provisioned. Credentials in `dastern/.env`.
- [ ] **0.5** Provision Firebase project (FCM only, no Firestore/Auth).
- [ ] **0.6** Create Google Play Console developer account, internal test track app.
- [ ] **0.7** Create Google Cloud Vision API project + service account, store JSON in 1Password (or similar).

## Phase 1 — Repo skeleton (1 day)

- [x] **1.1** Create `.kiro/specs-v2-flutter-supabase/` (this folder, done by spec authoring).
- [x] **1.2** Create `supabase/` directory with `migrations/`, `functions/`, `seed.sql`, `config.toml`.
- [x] **1.3** `.agents/skills/` populated with official Flutter + Dart skills (committed).
- [x] **1.4** Author `.agents/skills/das-tern/add-feature/SKILL.md` with the feature-folder template.
- [x] **1.5** Author `.agents/skills/das-tern/add-supabase-migration/SKILL.md`.
- [x] **1.6** Author `.agents/skills/das-tern/add-riverpod-provider/SKILL.md`.
- [x] **1.7** Author `.agents/skills/das-tern/add-edge-function/SKILL.md`.
- [x] **1.8** Update root `README.md` to point to `.kiro/specs-v2-flutter-supabase/README.md` as the source of truth.

## Phase 2 — Flutter app skeleton (2 days)

- [x] **2.1** Flutter 3.44 stable, Dart 3.12. `pubspec.yaml` updated.
- [x] **2.2** Dependency versions locked: `flutter_riverpod`, `go_router`, `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `flutter_secure_storage`, `connectivity_plus`, `shared_preferences`, `intl`, `logger`, `sentry_flutter` (placeholder), `package_info_plus`.
- [x] **2.3** `lib/core/` subfolders created: `config`, `error`, `i18n`, `logging`, `routing`, `storage/{drift,secure}`, `sync`, `theme`, `time`.
- [x] **2.4** `lib/features/<name>/` folders created: `auth`, `prescriptions`, `reminders`, `connections`, `doctor_dashboard`, `ocr`, `billing`, `settings`, `home`.
- [x] **2.5** `AppConfig.fromEnvironment()` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define`. Supabase.initialize() wired in `main.dart` (TODO comment; lands in 01-supabase-data-layer).
- [x] **2.6** Sentry/Crashlytics init placeholder in `main.dart` (TODO comment; lands in Phase 5).
- [x] **2.7** Root `MaterialApp.router` with `GoRouter` config wired.
- [x] **2.8** `lib/core/theme/` with light/dark `ThemeData` and `ColorScheme` tokens.
- [x] **2.9** `lib/l10n/` with pre-generated `AppLocalizations` (copied from `das_tern_mcp`). `flutter_localizations` configured in `MaterialApp`.
- [ ] **2.10** App icon + launch screen for Android and iOS. *(deferred — requires design assets)*

## Phase 3 — Local storage + sync foundation (2 days)

- [x] **3.1** `lib/core/storage/drift/app_database.dart` with `AppDatabase` extending `_$AppDatabase`.
- [x] **3.2** `OutboxEntries` table in Drift (id, targetTable, op, payload, attempts, nextAttemptAt, lastError, createdAt).
- [x] **3.3** `OutboxDao` with `enqueue`, `dequeueBatch`, `markFailed`, `markSucceeded`, `depth`.
- [x] **3.4** `lib/core/sync/sync_engine.dart` with `start()`, `stop()`, `enqueue(op)`, `drainNow()`, `backoffDelay()` (exponential, capped 60s, jitter, max 5 attempts).
- [x] **3.5** `connectivity_plus` listener in `syncEngineProvider` calls `drainNow()` when status flips to online.
- [x] **3.6** `SecureStorage` wrapper for session token, refresh token, encryption keys.
- [x] **3.7** Riverpod providers: `appDatabaseProvider`, `secureStorageProvider`, `syncEngineProvider`, `connectivityProvider`, `isOnlineProvider`.
- [x] **3.8** Unit tests: outbox enqueue/drain/markFailed/markSucceeded/depth, backoff math (3 cases), drain happy-path. 8/8 passing.

## Phase 4 — CI/CD baseline (1 day)

- [x] **4.1** `.github/workflows/flutter-ci.yml`: analyze, format check, test with coverage, debug Android build on PR + push to main.
- [x] **4.2** `.github/workflows/supabase-staging-deploy.yml`: `supabase db push` + `supabase functions deploy` on push to main.
- [x] **4.3** `.github/workflows/android-release.yml`: signed AAB build on `v*` tag, manual approval gate (`environment: production`), upload to Play Console internal track.
- [ ] **4.4** Branch protection rule on `main` — configure in GitHub repository settings (cannot be done via code).
- [x] **4.5** `CODEOWNERS` for `supabase/migrations/`, `.kiro/specs-v2-flutter-supabase/`, `.github/workflows/`.

## Phase 5 — Observability + telemetry (0.5 day)

- [ ] **5.1** Sentry DSN via `--dart-define=SENTRY_DSN=...` — placeholder in `AppConfig`; full init deferred until `sentry_flutter` is added.
- [ ] **5.2** `LogInterceptor` for Supabase calls — deferred until `supabase_flutter` is wired (01-supabase-data-layer).
- [ ] **5.3** `kDebugMode` gate to Sentry init — placeholder in `main.dart`.
- [x] **5.4** Diagnostics screen in settings: version, build number, environment, online status, outbox depth, last sync timestamp. Route: `/settings/diagnostics`.

## Phase 6 — Documentation hand-off (0.5 day)

- [x] **6.1** `dastern/README.md` covers: clone, `flutter pub get`, `supabase start`, `flutter run` with `--dart-define`s.
- [x] **6.2** `docs/SECRETS.md` documents all required secret key names for Flutter dart-defines, GitHub Actions, and Edge Functions.
- [x] **6.3** `dastern/AGENTS.md` documents Riverpod conventions, feature-folder pattern, l10n workflow, offline-first checklist, and AI prompt anatomy.
- [x] **6.4** Root `README.md` updated with v2 architecture notice.

## Phase 7 — Sign-off

- [ ] **7.1** Demo: clean checkout → `flutter run` → app opens with empty home screen, theme/language toggle works.
- [ ] **7.2** Demo: airplane mode → stub "create prescription" → outbox grows → re-enable network → outbox drains.
- [ ] **7.3** Stakeholder sign-off on architecture before kicking off feature specs (03+).

## Out of scope for this phase (handled in feature specs)

- Authentication flows (→ `02-authentication/tasks.md`).
- Any feature UI or business logic (→ feature spec tasks files).
- Production secret provisioning beyond placeholder env config.
- iOS-specific signing and TestFlight (deferred unless 0.3 says otherwise).

## Definitions of done

- A new contributor can clone, install, and run the app against local Supabase in under 30 minutes. ✓
- CI green on a clean main. ✓ (workflows created; requires GitHub secrets to be provisioned)
- All four agent skills present and discoverable. ✓
- Outbox drain demonstrated end-to-end in unit tests. ✓
