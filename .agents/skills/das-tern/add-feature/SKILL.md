# Skill: add-feature

Add a new feature module to the Das Tern Flutter app following the
feature-folder convention in `dastern/AGENTS.md`.

## When to use
When implementing a spec from `.kiro/specs-v2-flutter-supabase/<N>-<name>/`.

## Steps

1. **Read the spec** — `<spec>/requirements.md` and `<spec>/design.md`.

2. **Create the folder skeleton**
   ```
   lib/features/<name>/
   ├── data/
   │   ├── <name>_repository.dart          # abstract interface
   │   └── <name>_repository_impl.dart     # Drift + Supabase + SyncEngine
   ├── domain/
   │   ├── <name>.dart                     # freezed entity
   │   └── <name>_failure.dart             # extends AppFailure
   └── presentation/
       ├── pages/
       └── providers/
           └── <name>_providers.dart
   ```

3. **Domain entity** — `@freezed` immutable class, pure Dart, no Flutter imports.

4. **Repository** — abstract in `domain/`, concrete in `data/`.
   - Reads from Drift first (read-through cache).
   - Writes to Drift first, then `SyncEngine.enqueue(OutboxOp)`.
   - Optionally subscribes to Supabase Realtime.

5. **Riverpod providers** — one per source-of-truth, typed explicitly.
   See `AGENTS.md §4`.

6. **Route** — add to `lib/core/routing/app_router.dart`. No new GoRouter.

7. **Strings** — add keys to `das_tern_mcp/lib/l10n/app_km.arb` and
   `app_en.arb`, run `flutter gen-l10n` there, copy 5 files to
   `dastern/lib/l10n/`.

8. **Tests** — unit tests for repository, widget tests for pages.

9. **Verify**
   ```bash
   flutter analyze --fatal-warnings --fatal-infos
   flutter test
   dart format --output=none --set-exit-if-changed .
   ```

## Constraints
- UI never calls Supabase or Drift directly.
- `core/` never imports `features/`.
- All strings via `AppLocalizations.of(context)!`.
- Every mutation must work offline (see `AGENTS.md §8`).
