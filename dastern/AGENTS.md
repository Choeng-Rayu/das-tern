# AGENTS.md — Working with AI on the Das Tern Flutter app

> Audience: AI coding assistants (Kiro, Claude, Copilot, Cursor, …) **and**
> humans pairing with them. Read this top-to-bottom before opening a PR.
>
> Source of truth: [`.kiro/specs-v2-flutter-supabase/`](../.kiro/specs-v2-flutter-supabase/)
> at the repo root. **Specs win.** This file is the working contract for
> turning specs into code.

---

## 1. The contract in one paragraph

The Das Tern Flutter app is a **single codebase** with **Supabase as the
only backend**, written **offline-first** with **Riverpod + Drift**, organised
into **feature folders**, themed via **Material 3 design tokens**, localised
to **Khmer (default) + English**, and styled with the **iOS-26-inspired
visual language** documented in `09-design-system-localization`. Every
mutation goes Drift → Outbox → Supabase. Every patient action must work
offline. Every screen ships in two languages and two themes.

If you find yourself about to violate any of those, stop and ask.

---

## 2. Folder map (where new code goes)

```
lib/
├── main.dart                         # entry point — keep slim
├── app.dart                          # root MaterialApp.router
├── core/                             # cross-cutting infra (NEVER feature code)
│   ├── config/
│   ├── error/
│   ├── i18n/
│   ├── logging/
│   ├── network/
│   ├── routing/
│   ├── storage/{drift,secure}/
│   ├── sync/
│   ├── theme/
│   │   ├── tokens/                   # colors, spacing, radii, motion …
│   │   ├── app_theme.dart            # buildAppTheme() + lightTheme()/darkTheme()
│   │   └── theme_controller.dart
│   └── time/
├── features/<name>/                  # ONE folder per spec module
│   ├── data/                         # repositories + remote/local sources
│   ├── domain/                       # entities + use cases (pure Dart)
│   └── presentation/                 # widgets + Riverpod providers
├── shared/widgets/                   # reusable UI (AppButton, AppCard, …)
├── platform/{android,ios}/           # platform-only glue
└── l10n/                             # ARB files + generated AppLocalizations
```

**Hard rules:**

1. UI **never** calls Supabase or Drift directly. Repositories are the only
   bridge, and they are exposed as Riverpod providers.
2. `core/` may not depend on `features/`. Ever.
3. A reusable widget moves into `shared/widgets/` only when at least two
   features use it.
4. Generated code (`*.g.dart`, `*.freezed.dart`, `app_localizations*.dart`)
   is committed.

---

## 3. Adding a new feature — the recipe

When you read a spec like `03-prescription-medication/`, follow this
sequence. Each step is small enough that you can run `flutter analyze`
between them and keep the tree green.

### Step 1: Skeleton

```
features/prescriptions/
├── data/
│   ├── prescription_remote_source.dart
│   ├── prescription_local_source.dart
│   └── prescription_repository.dart
├── domain/
│   ├── prescription.dart            # freezed entity
│   └── prescription_failure.dart    # extends AppFailure
└── presentation/
    ├── pages/
    └── providers/
```

### Step 2: Domain

Define the entity as a `@freezed` immutable class. Stay in **pure Dart**:
no Flutter, no Supabase imports here.

```dart
// features/prescriptions/domain/prescription.dart
@freezed
class Prescription with _$Prescription {
  const factory Prescription({
    required String id,
    required String patientId,
    required String name,
    required PrescriptionLifecycle lifecycle,
    required DateTime updatedAt,
  }) = _Prescription;

  factory Prescription.fromJson(Map<String, dynamic> json) =>
      _$PrescriptionFromJson(json);
}
```

### Step 3: Repository

Define the abstract repository in `domain/`, the concrete one in `data/`.
Read-through Drift, write-through outbox.

```dart
// features/prescriptions/domain/prescription_repository.dart
abstract class PrescriptionRepository {
  Stream<List<Prescription>> watchActive();
  Future<Result<Prescription, AppFailure>> create(PrescriptionDraft draft);
}
```

### Step 4: Riverpod providers

One provider per source-of-truth. Always type the provider; never `var`.

```dart
final prescriptionRepositoryProvider = Provider<PrescriptionRepository>(
  (ref) => PrescriptionRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    supabase: ref.watch(supabaseClientProvider),
    sync: ref.watch(syncEngineProvider),
  ),
);

final activePrescriptionsProvider = StreamProvider<List<Prescription>>(
  (ref) => ref.watch(prescriptionRepositoryProvider).watchActive(),
);
```

### Step 5: Routes

Add the route to `core/routing/app_router.dart`. Do **not** create a new
`GoRouter` per feature.

### Step 6: Strings

Add bilingual ARB entries to **both** `lib/l10n/app_km.arb` and
`lib/l10n/app_en.arb`. Khmer is the template — add it first.

```json
"prescriptionsListTitle": "វេជ្ជបញ្ជារបស់ខ្ញុំ",
```

Then run `flutter gen-l10n` (or just `flutter run` — it's automatic).

### Step 7: UI

Compose using `lib/shared/widgets/`. If you need a new shared widget,
check whether any other feature also needs it before promoting.

### Step 8: Tests

Each feature ships:
- Unit tests for the repository (mock Supabase + in-memory Drift).
- Widget tests for each page using `pumpWidget` + `ProviderScope` overrides.
- A golden test for the default state of any page that lives in
  `shared/widgets/`.

---

## 4. State management — Riverpod conventions

| Need | Use | Why |
|---|---|---|
| Singletons (Supabase client, Drift DB) | `Provider<T>` | Plain DI. |
| Async one-shot (e.g., remote `Future<List<X>>`) | `FutureProvider<T>` | Caches result; rebuilds on `invalidate`. |
| Reactive stream (Drift `watch*`, Supabase `.stream()`) | `StreamProvider<T>` | First-class `AsyncValue`. |
| User-controlled state (theme mode, draft form) | `StateNotifierProvider` | Predictable transitions, easy to test. |
| Family / parameterised query | `*Provider.family<T, P>` | Don't pass IDs through props. |

**Names end in `Provider`.** Type the provider explicitly. Never expose a
`Notifier`'s mutable state — only the typed value.

```dart
// ✅ good
final activeDoseEventsProvider = StreamProvider<List<DoseEvent>>(
  (ref) => ref.watch(doseEventRepositoryProvider).watchToday(),
);

// ❌ bad — untyped, mixed concerns
final stuff = Provider((ref) => ref.read(supabaseClientProvider).from('dose_events'));
```

UI consumes via `ConsumerWidget` or `ConsumerStatefulWidget`. Inside a
non-build method, prefer `ref.read`; inside `build`, use `ref.watch`.

---

## 5. Design system — how to consume tokens

Every numeric value in a layout/style should resolve to a token.

```dart
// ✅ good
Padding(
  padding: const EdgeInsets.all(AppSpacing.md),
  child: Container(
    decoration: BoxDecoration(
      color: cs.surfaceContainer,
      borderRadius: AppRadii.allMedium,
      boxShadow: AppElevations.softCardShadow,
    ),
    child: Text('Hi', style: theme.textTheme.titleLarge),
  ),
);

// ❌ bad — magic numbers, hard-coded color
Padding(
  padding: const EdgeInsets.all(16),
  child: Container(
    decoration: BoxDecoration(
      color: const Color(0xFFEFEFEF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text('Hi', style: TextStyle(fontSize: 18)),
  ),
);
```

Token sources:
- `lib/core/theme/tokens/colors.dart` — semantic + adherence colors only;
  use `Theme.of(context).colorScheme` for everything else.
- `lib/core/theme/tokens/spacing.dart` — `xs` (4) … `xxxl` (64).
- `lib/core/theme/tokens/radii.dart` — small / medium / large / xlarge.
- `lib/core/theme/tokens/typography.dart` — already wired into `TextTheme`.
- `lib/core/theme/tokens/motion.dart` — durations + curves.
- `lib/core/theme/tokens/breakpoints.dart` — `Breakpoint.of(context)`.

If you can't express a layout with tokens, add a token rather than a magic
value. Document the addition in the spec.

---

## 6. Reusable widgets — the catalog

| Widget | Use for |
|---|---|
| `AppButton` | Every primary/secondary action. Variants: `filled`, `outlined`, `text`, `danger`. Set `loading: true` during async work. |
| `AppCard` | Any card-like surface. Pass `onTap` to make the whole card tappable. |
| `AppTextField` | All text inputs — handles labels, helper, error consistently. |
| `EmptyState` | Empty list / first-run placeholder. Pair with an illustration when feature gets one. |
| `LoadingState` | Async-loading placeholder. Use `compact: true` inside cards. |
| `ErrorState` | `AsyncValue.when(error: …)` consumer. Always pass `onRetry`. |
| `AdherenceRing` | Adherence percentage as ring + label, colour-coded. |
| `DoseStatusBadge` | `due`, `takenOnTime`, `takenLate`, `missed`, `skipped`. |
| `LifecycleBadge` | Prescription lifecycle pill. |
| `PermissionChip` | Connection permission level chip. |
| `FrostedSurface` | iOS-26 glass surface — sticky headers, modal sheets only. |
| `AdaptiveScaffold` | Top-level navigation that switches bottom-bar / rail / drawer by breakpoint. |

Before building a new component:

1. Search `lib/shared/widgets/` first.
2. Compose existing primitives if possible.
3. Promote to `shared/` only when ≥2 features use it.

---

## 7. i18n rules

- **Every** user-visible string lives in `lib/l10n/*.arb`. Never inline a
  literal in a widget.
- Keys are `camelCase`. Group by feature prefix: `prescriptionsListTitle`,
  `doseTakeAction`, `connectionsRequestSent`. (Dots aren't allowed in
  Flutter ARB keys.)
- Khmer (`app_km.arb`) is the template. Add the Khmer string first; if you
  don't have a translation yet, use a placeholder and tag it with
  `@<key>: { "description": "TRANSLATION NEEDED" }`.
- Plural / placeholder messages use ICU syntax with metadata:

  ```json
  "doseDueIn": "{minutes, plural, =1{១នាទីទៀត} other{{minutes} នាទីទៀត}}",
  "@doseDueIn": {
    "description": "How many minutes until the next dose.",
    "placeholders": { "minutes": { "type": "int" } }
  }
  ```
- After editing ARBs, run `flutter gen-l10n`. CI fails if generated code is
  stale.

---

## 8. Offline-first checklist

For any patient-facing mutation, the AI must verify all five points:

1. ☐ The action writes to Drift first (never Supabase first).
2. ☐ An `OutboxEntry` is enqueued for the eventual server write.
3. ☐ The UI reads from Drift via `StreamProvider`, so it shows the optimistic
     state immediately.
4. ☐ The screen behaves correctly with `Connectivity().status == none`.
5. ☐ The mutation is idempotent — replaying it produces the same row.

If any box is unchecked, the change is **not** ready for review.

---

## 9. Error handling

Repositories return either a value or an [AppFailure] subclass — never a
raw exception. Use a `Result<T, AppFailure>` (sealed) when you need both
paths in the same return.

```dart
final result = await ref.read(prescriptionRepositoryProvider).create(draft);
result.when(
  ok: (prescription) => context.go('/prescriptions/${prescription.id}'),
  err: (failure) => showError(context, failure),
);
```

UI maps `AppFailure.message` to the localised string via `AppLocalizations`.

Caught exceptions in repositories must be logged with
`appLogger.e(...)`, **redacting PII** at the call site (log IDs, not
patient names).

---

## 10. Performance ground rules

- Default to `const` constructors. The analyzer enforces this.
- Use `ListView.builder` / `Sliver*` for any list ≥ 20 rows.
- Cache image network calls — never decode the same URL twice in one
  scroll session.
- Use `RepaintBoundary` around expensive subtrees (charts, animated rings).
- Never await inside a build method. Move it to a `FutureProvider`.

---

## 11. Accessibility (a11y) checklist

- ☐ Every `IconButton` / `GestureDetector` has a `tooltip` or `Semantics`.
- ☐ Tap targets ≥ 44 × 44 logical pixels.
- ☐ `MediaQuery.textScaler` up to 200% does not break layout (guarded
     with `LayoutBuilder` / `Flexible`).
- ☐ Colour contrast meets WCAG AA in both themes (golden test required).
- ☐ Forms describe errors near the field, not in a top-of-screen toast.

---

## 12. Working with an AI assistant — the prompt anatomy

When asking an AI to implement a piece of a spec, give it:

1. **The spec section.** Path + section anchor.
2. **The folder it should write into.** e.g., `lib/features/connections/`.
3. **The constraints from this file.** Quote the relevant section.
4. **The verification step.** "Run `flutter analyze` and `flutter test`
   when you're done."

Example prompt:

> Implement step 1.2 of `.kiro/specs-v2-flutter-supabase/05-family-doctor-connections/tasks.md`
> in `lib/features/connections/`. Follow the AGENTS.md feature recipe (§3),
> use `flutter_riverpod` per §4, all strings via `app_km.arb` and
> `app_en.arb` per §7, and run `flutter analyze && flutter test` when you
> finish.

---

## 13. Don't-do list

- ❌ Don't add a new state-management library. Riverpod only.
- ❌ Don't reach for Bloc / GetX / Provider (the package, not the pattern).
- ❌ Don't write `print(...)`. Use `appLogger`.
- ❌ Don't import `dart:io` from a widget — keep platform code in
   `lib/platform/`.
- ❌ Don't store auth tokens in `SharedPreferences`. Use `flutter_secure_storage`.
- ❌ Don't ship a string that isn't in both `app_km.arb` and `app_en.arb`.
- ❌ Don't introduce a new top-level `MaterialApp` in a test or page —
   one app shell, full stop.
- ❌ Don't `git push` to `main`. PR + review (per CI baseline).

---

## 14. Verification before opening a PR

```bash
# from /home/rayu/das-tern/dastern/
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-warnings --fatal-infos
flutter test --coverage
```

If you added/changed ARB keys:

```bash
flutter gen-l10n
git diff --exit-code lib/l10n/app_localizations*.dart
```

If any of these fail, fix before requesting review. The AI assistant is
expected to run them itself.

---

## 15. Pointers to deeper docs

- Architecture decisions → `.kiro/specs-v2-flutter-supabase/00-overview/design.md`
- Data layer + RLS → `.kiro/specs-v2-flutter-supabase/01-supabase-data-layer/design.md`
- Offline reminder lifecycle → `.kiro/specs-v2-flutter-supabase/04-reminder-adherence/design.md`
- Design system + i18n → `.kiro/specs-v2-flutter-supabase/09-design-system-localization/design.md`
- Account & connection model refinement → `.kiro/specs-v2-flutter-supabase/ADDENDUM-001-account-and-connection-refinement.md`

When in doubt, the spec wins. When the spec is silent, this file wins.
When both are silent, ask.
