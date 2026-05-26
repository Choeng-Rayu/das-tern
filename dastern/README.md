# Das Tern — Flutter app

> Patient-centred medication management for Cambodia. Offline-first.
> Bilingual (Khmer / English). Single Flutter codebase backed by Supabase.

This directory holds the Flutter client. The full v2 specification lives at
[`../.kiro/specs-v2-flutter-supabase/`](../.kiro/specs-v2-flutter-supabase/) — read
[`README.md`](../.kiro/specs-v2-flutter-supabase/README.md) there before
making structural changes.

For working with AI coding assistants on this codebase, see
[`AGENTS.md`](./AGENTS.md).

---

## Requirements

| Tool | Version |
|---|---|
| Flutter SDK | ≥ 3.32 stable |
| Dart SDK | ≥ 3.12 (bundled with Flutter) |
| Android Studio | Hedgehog or newer (for Android builds) |
| Xcode | 15+ (macOS only, for iOS builds) |

Verify your toolchain:

```bash
flutter doctor -v
```

---

## Quick start

```bash
# 1. From the repo root, enter the Flutter project
cd dastern

# 2. Install pinned dependencies
flutter pub get

# 3. (Optional) Spin up local Supabase — requires Supabase CLI
#    https://supabase.com/docs/guides/cli/getting-started
#    supabase start   ← run from the repo root, not dastern/
#    This prints the local URL and anon key to use in step 4.

# 4. Run on a connected device or emulator
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<local-anon-key-from-supabase-start> \
  --dart-define=APP_ENV=dev
```

The first run launches a Khmer home screen. Open the gear icon → Appearance
to switch to English or toggle dark mode. Both choices persist across
restarts.

---

## Project structure

```
lib/
├── main.dart                  # entry point
├── app.dart                   # root MaterialApp.router
├── core/                      # cross-cutting infra (theme, l10n controller, logging, …)
├── features/                  # one folder per spec module
├── shared/widgets/            # reusable UI catalog
└── l10n/                      # pre-generated AppLocalizations (copied from das_tern_mcp)
```

See [`AGENTS.md` §2](./AGENTS.md) for the full map and rules.

---

## Common commands

```bash
# Static analysis (must be green before merge)
flutter analyze --fatal-warnings --fatal-infos

# Format check (CI runs this with --set-exit-if-changed)
dart format .

# Tests with coverage
flutter test --coverage

# Debug Android build
flutter build apk --debug --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…

# iOS (macOS host only)
flutter build ios --debug --dart-define=…
```

> **Do NOT run `flutter gen-l10n` here.** `lib/l10n/` contains
> pre-generated files copied from `das_tern_mcp/lib/l10n/`. To add or
> change strings: edit the ARBs in `das_tern_mcp/lib/l10n/`, run
> `flutter gen-l10n` there, then copy the five files into `dastern/lib/l10n/`.

---

## Environment variables (`--dart-define`)

| Name | Required | Notes |
|---|---|---|
| `SUPABASE_URL` | Yes (non-debug) | Project URL, e.g. `https://xyz.supabase.co`. |
| `SUPABASE_ANON_KEY` | Yes (non-debug) | Public anon key. **Never** ship the service-role key. |
| `APP_ENV` | No (default `dev`) | One of `dev`, `staging`, `prod`. |
| `SENTRY_DSN` | No | Enables Sentry in release builds when present. |

Local dev with the Supabase CLI:

```bash
# In a separate terminal, from the repo root
supabase start
# Then use the printed URL + anon key for the dart-defines above.
```

---

## Theming and localisation

- Light + dark `ThemeData` are built from a single brand seed
  (`#1A8E5F`) in `lib/core/theme/app_theme.dart`. Components are themed
  centrally — feature widgets should not override styling case-by-case.
- All strings live in `lib/l10n/app_km.arb` (default) and
  `lib/l10n/app_en.arb`. Keys are `camelCase` with a feature prefix
  (e.g., `prescriptionsListTitle`). Both files must stay in sync — CI
  fails if a key exists in only one.

See [`AGENTS.md` §5–§7](./AGENTS.md) for the full design-system + i18n rules.

---

## Where to add new code

| Goal | Location |
|---|---|
| New feature module (per spec) | `lib/features/<name>/{data,domain,presentation}/` |
| New reusable widget (≥ 2 features) | `lib/shared/widgets/<group>/` |
| New design token | `lib/core/theme/tokens/` |
| New shared infra (logging, network, …) | `lib/core/<area>/` |
| New strings | Edit ARBs in `das_tern_mcp/lib/l10n/`, run `flutter gen-l10n` there, copy 5 files to `dastern/lib/l10n/` |
| New top-level route | `lib/core/routing/app_router.dart` |

---

## Contributing

1. Read the relevant spec under `../.kiro/specs-v2-flutter-supabase/`.
2. Follow the recipe in [`AGENTS.md` §3](./AGENTS.md) for the feature.
3. Run `flutter analyze && flutter test && dart format .` before pushing.
4. Open a PR against `main`. CI runs analyze + format + test + a debug
   Android build.

Any change touching `supabase/migrations/` or
`.kiro/specs-v2-flutter-supabase/` requires a senior reviewer
(see `CODEOWNERS`).

---

## Status

This is the foundation scaffold (Phase 2 of `00-overview/tasks.md`). The
following are intentionally **not yet wired**:

- ⏳ Supabase client init — added in `01-supabase-data-layer`.
- ⏳ Drift database + sync engine — added in Phase 3.
- ⏳ Authentication — added in `02-authentication`.
- ⏳ Local notifications — added in `04-reminder-adherence`.
- ⏳ OCR pipeline — added in `07-ocr-prescription-scanning`.
- ⏳ Google Play Billing — added in `08-google-play-billing`.

Each subsequent phase appends to `pubspec.yaml`, follows the `AGENTS.md`
recipe, and ships golden + widget tests for new UI.
