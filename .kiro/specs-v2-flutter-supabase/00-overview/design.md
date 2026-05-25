# Design: Architecture Overview & Project Foundation

## 1. System context

```
┌────────────────────────────────────────────────────────────────────────┐
│                Patient (with peer-Patient family) / Doctor              │
│                          (Android phone, iPhone)                        │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │
                               ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter App (single codebase)                    │
│                                                                         │
│  ┌────────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌───────┐  │
│  │ Presentation│ │  Domain  │ │   Data   │ │ Local Store │ │ OS    │  │
│  │  (Riverpod) │ │ (Freezed)│ │ (Repos)  │ │  (Drift)    │ │ APIs  │  │
│  └────────────┘  └──────────┘  └────┬─────┘  └────────────┘  └───┬───┘  │
│                                     │                            │      │
│   • Local notifications                                                 │
│   • Camera (OCR), QR scanner                                            │
│   • flutter_secure_storage                                              │
│   • in_app_purchase, supabase_flutter, google_mlkit_text_recognition,   │
│     flutter_tesseract_ocr, drift, riverpod, freezed, qr_flutter         │
└──────────────────┬───────────────────────────────────┬─────────────────┘
                   │ HTTPS / WSS                        │ Platform IPC
                   ▼                                    ▼
┌──────────────────────────────────────────────┐  ┌──────────────────────┐
│           Supabase Project (managed)          │  │  Google Play Billing │
│                                                │  │   (Play Store SDK)   │
│  ┌────────────┐  ┌──────────┐  ┌──────────┐   │  └──────────┬───────────┘
│  │ Postgres   │  │   Auth   │  │ Storage  │   │             │
│  │ + RLS      │  │ (JWT)    │  │ (S3-like)│   │             │
│  └─────┬──────┘  └────┬─────┘  └────┬─────┘   │             │
│        │              │             │          │             │
│  ┌─────┴──────────────┴─────────────┴───┐     │             │
│  │           Edge Functions             │     │             │
│  │  • google-play-verify  ────────────────────┼─────────────┘
│  │  • google-play-rtdn    ◀──── Pub/Sub push ─┤
│  │  • ocr-cloud-vision    ────► Google Cloud Vision
│  │  • auth-telegram       ────► oauth.telegram.org JWKS
│  └──────────────────────────────────────┘     │
│                                                │
│  ┌──────────────┐                              │
│  │   Realtime   │ ◀──── pgsockets ───┐         │
│  └──────────────┘                    │         │
└──────────────────────────────────────┼─────────┘
                                       │
                            (live updates to peer-Patient dashboards,
                             doctor adherence, connection events)
```

## 2. Tech stack (locked-in choices)

| Layer | Choice | Why |
|---|---|---|
| App framework | Flutter 3.24+ stable | Existing skills in team; one codebase iOS+Android. |
| Language | Dart 3.5+ | Sound null safety, pattern matching, records. |
| State | `flutter_riverpod` 2.x | Compile-safe DI, async-friendly, no `BuildContext` for reads. |
| Models | `freezed` + `json_serializable` | Immutable + sealed unions for `AsyncValue`-friendly states. |
| Routing | `go_router` 14+ | Declarative routes, deep-link friendly, type-safe paths. |
| Local DB | `drift` (SQLite) | Type-safe queries, reactive streams, mature. |
| Secure storage | `flutter_secure_storage` | Keystore/Keychain backed. |
| BaaS SDK | `supabase_flutter` 2.x | Postgres, Auth, Storage, Realtime, Edge Functions. |
| Auth | Supabase Auth + `google_sign_in` + `sign_in_with_apple` (later) + Telegram OIDC | Native sign-in, OIDC compatible. |
| Local notifications | `flutter_local_notifications` 18+ | Offline reminder firing. |
| Push notifications | Supabase + `firebase_messaging` (FCM) | Peer-Patient/doctor missed-dose alerts. |
| OCR (on-device Latin) | `google_mlkit_text_recognition` | Free, fast, no network. |
| OCR (on-device Khmer) | `flutter_tesseract_ocr` with `khm.traineddata` from `tessdata_best` | The only on-device option that supports Khmer. |
| OCR (cloud fallback) | Edge Function → Google Cloud Vision API | Best handwriting + Khmer accuracy. |
| Billing | `in_app_purchase` 3.x + Edge Function verifier | Required by Play Store policy; iOS-ready. |
| QR | `qr_flutter` (display) + `mobile_scanner` (read) | Standard, well-maintained. |
| Camera | `camera` + `image_picker` | Standard. |
| Connectivity | `connectivity_plus` | Online/offline detection. |
| Logging | `logger` | Structured local logs. |
| Crash reporting | `sentry_flutter` | Cross-platform. |
| Testing | `flutter_test`, `mocktail`, `integration_test`, `patrol` (optional) | |

## 3. Project structure

```
das-tern/
├── das_tern_mcp/                    # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── config/              # Env, Supabase keys, feature flags
│   │   │   ├── error/               # AppFailure, error mappers
│   │   │   ├── i18n/                # arb generation, translation helpers
│   │   │   ├── logging/
│   │   │   ├── network/             # Connectivity, retry policies
│   │   │   ├── routing/             # GoRouter config
│   │   │   ├── storage/
│   │   │   │   ├── drift/           # Database, DAOs, OutboxDao
│   │   │   │   └── secure/          # Secure storage wrapper
│   │   │   ├── sync/                # SyncEngine, conflict resolver
│   │   │   ├── theme/               # Light/dark themes, design tokens
│   │   │   └── time/                # Cambodia timezone helpers
│   │   ├── features/
│   │   │   ├── auth/                # 02-authentication
│   │   │   ├── prescriptions/       # 03-prescription-medication
│   │   │   ├── reminders/           # 04-reminder-adherence
│   │   │   ├── connections/         # 05-family-doctor-connections
│   │   │   ├── doctor_dashboard/    # 06-doctor-dashboard
│   │   │   ├── ocr/                 # 07-ocr-prescription-scanning
│   │   │   ├── billing/             # 08-google-play-billing
│   │   │   └── settings/
│   │   ├── shared/
│   │   │   ├── widgets/             # Reusable widgets
│   │   │   └── models/              # Cross-feature freezed models
│   │   ├── platform/                # Platform-specific glue
│   │   │   ├── android/
│   │   │   └── ios/
│   │   └── l10n/                    # Generated ARB-based localizations
│   │       ├── app_en.arb
│   │       └── app_km.arb
│   ├── test/
│   ├── integration_test/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── supabase/                        # Supabase project source
│   ├── migrations/                  # Versioned SQL migrations
│   │   ├── 20260601000000_init.sql
│   │   └── 20260601000100_rls_policies.sql
│   ├── functions/                   # Deno edge functions
│   │   ├── _shared/                 # Shared TS code
│   │   ├── google-play-verify/
│   │   │   └── index.ts
│   │   ├── google-play-rtdn/
│   │   │   └── index.ts
│   │   ├── ocr-cloud-vision/
│   │   │   └── index.ts
│   │   └── auth-telegram/
│   │       └── index.ts
│   ├── seed.sql                     # Local dev seed data
│   └── config.toml
├── .agents/
│   └── skills/
│       ├── flutter/                 # From flutter/skills
│       ├── dart-lang/               # From dart-lang/skills
│       └── das-tern/                # Project-specific skills
│           ├── add-feature/
│           ├── add-supabase-migration/
│           ├── add-riverpod-provider/
│           └── add-edge-function/
├── .kiro/
│   ├── specs/                       # v1 specs (historical)
│   └── specs-v2-flutter-supabase/   # this spec set
├── .github/
│   └── workflows/
│       ├── flutter-ci.yml
│       ├── supabase-staging-deploy.yml
│       └── android-release.yml
└── README.md
```

> **Note:** The v1 services (`backend_nestjs/`, `bakong_payment/`, `ocr/`, `ai-llm-service/`) are kept for historical reference but are no longer wired into builds, deployments, or Docker Compose. A follow-up cleanup PR can delete them once v2 is in production.

## 4. Layered architecture inside Flutter

```
┌───────────────────────────────────────────────────────┐
│                    Presentation                       │
│   Widgets ── ConsumerWidget ── Riverpod providers     │
└────────────────────────┬──────────────────────────────┘
                         │
                         ▼
┌───────────────────────────────────────────────────────┐
│                       Domain                          │
│   Entities (freezed) · Use cases (pure Dart classes)  │
└────────────────────────┬──────────────────────────────┘
                         │
                         ▼
┌───────────────────────────────────────────────────────┐
│                        Data                           │
│   Repository (interface in domain, impl in data)      │
│   ├── Remote source: SupabaseClient                   │
│   ├── Local source:  Drift DAO                        │
│   └── Sync orchestration: SyncEngine                  │
└───────────────────────────────────────────────────────┘
```

**Repository pattern** — every feature exposes a `<Feature>Repository` that:
- Reads from `Drift` first (read-through cache).
- Writes to `Drift` first, then enqueues an `OutboxEntry` that the `SyncEngine` will replay against Supabase when online.
- Optionally subscribes to Supabase Realtime to push remote changes back into Drift.

```dart
// Example: lib/features/prescriptions/data/prescription_repository.dart
abstract class PrescriptionRepository {
  Stream<List<Prescription>> watchActive();
  Future<Prescription> create(PrescriptionDraft draft);
  Future<void> markUrgent(String id, String reason);
}

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  PrescriptionRepositoryImpl(this._db, this._supabase, this._sync);
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final SyncEngine _sync;

  @override
  Stream<List<Prescription>> watchActive() => _db.prescriptionDao.watchActive();

  @override
  Future<Prescription> create(PrescriptionDraft draft) async {
    final row = await _db.prescriptionDao.insert(draft);
    await _sync.enqueue(OutboxOp.create('prescriptions', row.toJson()));
    return row.toDomain();
  }

  @override
  Future<void> markUrgent(String id, String reason) async {
    await _db.prescriptionDao.markUrgent(id, reason);
    await _sync.enqueue(OutboxOp.update('prescriptions', id, {
      'is_urgent': true,
      'urgent_reason': reason,
    }));
  }
}
```

## 5. Sync engine

The `SyncEngine` is the only component that talks to Supabase for mutations. It owns:

1. **Outbox draining** — On startup and on connectivity restore, replay queued ops in order.
2. **Conflict resolution** — Server is authoritative for `updated_at`; local writes win on `dose_events` (offline truth) but lose on `prescriptions` (doctor authority).
3. **Realtime ingest** — Subscribes to Supabase Realtime channels for tables the user has visibility on; merges remote rows into Drift, fires Riverpod invalidation.
4. **Backoff** — Exponential with jitter (1s → 2s → 4s → … capped at 60s, max 5 attempts per entry per cycle).

```dart
// Simplified outbox entry
class OutboxEntry {
  final String id;            // ULID
  final String table;
  final OutboxOp op;          // CREATE | UPDATE | DELETE | RPC
  final Map<String, dynamic> payload;
  final int attempts;
  final DateTime nextAttemptAt;
  final String? lastError;
}
```

## 6. Authentication flow (high-level — see 02-authentication)

1. User launches app.
2. `supabase_flutter` is initialized with anon key + URL.
3. The app reads `Supabase.instance.client.auth.currentSession`. If valid, route to home.
4. Otherwise, show sign-in screen (Email OTP, Google native, Apple native, Telegram OIDC).
5. After sign-in, the app upserts a `profiles` row keyed by `auth.uid()` to capture role and language preferences.

## 7. Telegram OIDC (replacing the v1 NestJS module)

The Telegram OIDC PKCE flow is preserved, but the server-side step (token exchange + ID-token validation) moves into a Supabase Edge Function `auth-telegram`:

1. Flutter generates `state` and `code_verifier`/`code_challenge`, opens `oauth.telegram.org/auth?…` in external browser.
2. Telegram redirects back to `dastern://auth/telegram/callback?code=…&state=…`.
3. Flutter posts `{code, codeVerifier, redirectUri}` to Edge Function `POST /functions/v1/auth-telegram`.
4. Edge Function exchanges code for `id_token` at Telegram's token endpoint, validates signature against JWKS, and either:
   - signs in / signs up via Supabase Admin API (`createUser` / `signInWithIdToken`-equivalent server-side approach), then returns Supabase access + refresh tokens.
   - or returns a short-lived custom JWT that Flutter exchanges via `signInWithIdToken`.
5. Flutter stores the Supabase session in `flutter_secure_storage`.

## 8. Edge Function inventory

| Function | Trigger | Secrets | Purpose |
|---|---|---|---|
| `auth-telegram` | HTTP from Flutter | `TELEGRAM_BOT_CLIENT_ID`, `TELEGRAM_BOT_CLIENT_SECRET`, `SUPABASE_SERVICE_ROLE_KEY` | Validates Telegram OIDC ID token, creates/links Supabase user, returns session. |
| `google-play-verify` | HTTP from Flutter | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Verifies a purchase token via `androidpublisher.purchases.subscriptions.get`, writes to `subscriptions` table, ack's the purchase. |
| `google-play-rtdn` | HTTPS push from Google Pub/Sub | `RTDN_AUTH_HEADER`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Receives Real-time Developer Notifications, updates `subscriptions` row state. |
| `ocr-cloud-vision` | HTTP from Flutter (only on low-confidence path) | `GCP_VISION_API_KEY` | Proxies to Google Cloud Vision `images:annotate`, returns OCR result + bounding boxes. |
| `nightly-cleanup` | Postgres cron via `pg_cron` | (none beyond service role inside Supabase) | Marks past-grace `dose_events` as `MISSED`, expires `connection_tokens`. |

## 9. Local notifications & background reminders

- The Flutter app generates the next 30 days of `dose_events` locally (mirrored from Supabase). Each row schedules a local notification through `flutter_local_notifications`.
- On Android 12+ we request `SCHEDULE_EXACT_ALARM` for time-critical reminders.
- On reboot, an Android `BootReceiver` (provided by the plugin) reschedules all pending notifications from Drift.
- iOS uses `UNUserNotificationCenter` with calendar triggers; we keep ≤64 pending notifications (iOS hard limit) by rolling the next 24h window forward as the user opens the app.
- See `04-reminder-adherence/design.md` for the full reminder lifecycle.

## 10. Build, run, deploy

### Local dev

```bash
# 1. Spin up local Supabase
supabase start

# 2. Apply migrations
supabase db reset

# 3. Run Flutter
cd das_tern_mcp
flutter pub get
flutter run --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
           --dart-define=SUPABASE_ANON_KEY=...
```

### CI

- PR: `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed`, debug Android build.
- main: above + `supabase db push` to staging project.
- Release tag (v*): signed AAB build, manual approval, upload to Play Console internal track via fastlane.

### Production environments

- `supabase-prod` — Postgres + Edge Functions + Storage.
- Play Store internal → closed → open testing tracks.
- Firebase project (FCM only) for push delivery.

## 11. Agent skills

Per the [Flutter Agent Skills](https://docs.flutter.dev/ai/agent-skills) docs, skills are progressive-disclosure blueprints that AI assistants read on demand.

### Installation (run once per checkout, commit results)

```bash
npx skills add flutter/skills --skill '*' --agent universal
npx skills add dart-lang/skills --skill '*' --agent universal
```

### Project-specific skills under `.agents/skills/das-tern/`

Each skill is a folder with a `SKILL.md` and supporting files. We ship four to start:

1. **`add-feature/`** — How to scaffold a new feature module (`features/<name>/{data,domain,presentation}` + Riverpod providers + GoRouter route + i18n entries).
2. **`add-supabase-migration/`** — How to add an SQL migration (`supabase migration new <name>`), declare the table, write RLS policies, and add a corresponding Drift table.
3. **`add-riverpod-provider/`** — Conventions for naming, scoping, family providers, async providers, and invalidation.
4. **`add-edge-function/`** — How to scaffold an Edge Function (`supabase functions new <name>`), wire secrets, write a Deno test, and document it in this spec set.

### Refresh

```bash
# Pull new skill versions
npx skills update flutter/skills
npx skills update dart-lang/skills
```

## 12. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Supabase outage | Low | High | Offline-first design means the app remains functional. Local notifications keep firing. Push notifications are the only feature that hard-fails. |
| Edge Function cold start | Medium | Low | Verify-purchase is the only synchronous user-facing edge call; we can show a 2–3s loading spinner. RTDN ingest is async, latency tolerated. |
| Google Cloud Vision quota / cost | Medium | Medium | Cloud OCR is the fallback path only. Hard-cap monthly calls in the Edge Function (return cached or local-only result on quota exhaustion). |
| `in_app_purchase` plugin breakage on a Play Billing major version bump | Medium | High | Pin plugin to a known-good version; subscribe to flutter/packages release notes; treat billing layer as a thin adapter we own. |
| RLS misconfiguration leaking data | Medium | Critical | All RLS policies tested with `pgtap` in CI; default-deny stance on every table; no service role in client. |
| Khmer Tesseract accuracy | Medium | Medium | Confidence threshold drops to cloud fallback; manual review screen always shown before saving. |

## 13. Open decisions (track in this doc, decide before MVP)

- [ ] Hosting region for Supabase project (Singapore vs Tokyo for Cambodia latency).
- [ ] Sentry vs Crashlytics for crash reporting.
- [ ] Whether to ship Telegram auth in MVP or defer behind feature flag.
- [ ] Whether to keep `health_vitals` tables in v2 schema (future-proofing) or remove until needed.
- [ ] Whether iOS App Store IAP ships in MVP or in v2.1.
