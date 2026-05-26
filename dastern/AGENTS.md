# AGENTS.md — Working with AI on the Das Tern Flutter app

> Audience: AI coding assistants (Kiro, Claude, Copilot, Cursor, …) **and**
> humans pairing with them. Read this top-to-bottom before opening a PR.
>
> Source of truth: [`.kiro/specs-v2-flutter-supabase/`](../.kiro/specs-v2-flutter-supabase/)
> at the repo root. **Specs win.** This file is the working contract for
> turning specs into code.

---

## ⚓ STEERING DIRECTIVE — auto-apply the Liquid Glass concept on every UI task

> **This is a hard rule, not a suggestion.** Any task that creates, modifies, or
> reviews UI code in `dastern/lib/` **MUST** load the
> [`liquid-glass-flutter`](../.agents/skills/liquid-glass-flutter/SKILL.md)
> skill **before writing any code** and follow its workflow. The skill fuses
> the project's layered architecture (Riverpod + Drift + Repository + feature
> folders) with the iOS-26 Liquid Glass visual language (FrostedSurface, mesh
> background, role-aware AppScaffold, glass widget catalog, motion catalogue).
>
> If the skill is absent or fails to load, **stop and surface the problem**
> rather than improvising — improvised UI will violate the visual contract,
> the layered architecture, or both.
>
> ### Triggers that automatically invoke this directive
>
> The directive applies whenever any of the following is true:
>
> - You are touching anything under `dastern/lib/features/*/presentation/`,
>   `dastern/lib/shared/widgets/`, or `dastern/lib/core/theme/`.
> - You are creating or editing a `*Page`, `*View`, `*Sheet`, `*Dialog`,
>   `*Card`, `*Chip`, `*Banner`, or any `Widget` subclass.
> - You are adding, changing, or styling: navigation, an app bar, a bottom
>   sheet, a dialog, a button, a card, a chip, a list row, a form field,
>   a status badge, an empty / loading / error state, or a glass surface.
> - You are wiring a route, screen transition, or `GoRouter` entry.
> - You are working from any task in `.kiro/specs-v2-flutter-supabase/02-…`
>   through `08-…` that lists a UI sub-task.
> - You are working from any task in
>   `.kiro/specs-v2-flutter-supabase/09-design-system-localization/` or
>   `.kiro/specs-v2-flutter-supabase/10-frontend-liquid-glass/`.
> - You are reviewing or refactoring an existing widget file.
>
> ### What "auto-apply" means in practice
>
> 1. **Read the skill first.** Open
>    `/home/rayu/das-tern/.agents/skills/liquid-glass-flutter/SKILL.md` and
>    skim its **Hard rules** and **Workflow** sections before writing code.
> 2. **Wrap every page in `AppScaffold`.** Never `Scaffold(...)` directly.
> 3. **Use the glass widgets** (`AppGlassCard`, `AppGlassChip`, `AppGlassDialog`,
>    `AppGlassBottomSheet`, `AppGlassFab`, `AppGlassHeader`, `AppGlassNavBar`)
>    rather than raw Material equivalents.
> 4. **Never call `BackdropFilter(...)` outside
>    `lib/shared/widgets/effects/frosted_surface.dart`** — go through
>    `FrostedSurface` or one of its composites instead.
> 5. **Reference tokens** for every color, spacing, radius, blur sigma,
>    duration, and curve. No magic numbers in widget bodies.
> 6. **Localise every string** through `app_km.arb` + `app_en.arb` (Khmer first).
> 7. **Run the verification commands** in §14 before requesting review.
>
> ### Triggers that do **not** invoke this directive
>
> The directive does not apply when you are working purely on:
> non-UI Dart logic (repositories, services, sync engine, time helpers),
> Supabase SQL migrations, Edge Functions (Deno), Play Console / GCP
> configuration, or fastlane / CI workflow files. Those have their own specs
> and skills.

---

## 1. The contract in one paragraph

The Das Tern Flutter app is a **single codebase** with **Supabase as the
only backend**, written **offline-first** with **Riverpod + Drift**, organised
into **feature folders**, themed via **Material 3 design tokens**, localised
to **Khmer + English (defualt) **, and styled with the **iOS-26-inspired
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
└── l10n/                             # pre-generated AppLocalizations (do NOT run gen-l10n)
```

**Hard rules:**

1. UI **never** calls Supabase or Drift directly. Repositories are the only
   bridge, and they are exposed as Riverpod providers.
2. `core/` may not depend on `features/`. Ever.
3. A reusable widget moves into `shared/widgets/` only when at least two
   features use it.
4. Generated code (`*.g.dart`, `*.freezed.dart`, `app_localizations*.dart`)
   is committed. **Never delete or regenerate `lib/l10n/app_localizations*.dart`** —
   these files are the source of truth, copied from `das_tern_mcp/lib/l10n/`.

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

Add keys to **both** `lib/l10n/app_km.arb` and `lib/l10n/app_en.arb`, then
copy the updated files (and the regenerated `app_localizations*.dart`) from
`das_tern_mcp/lib/l10n/` into `dastern/lib/l10n/`. **Do not run
`flutter gen-l10n` inside this project** — codegen is owned by
`das_tern_mcp`; we consume its output.

```json
"prescriptionsListTitle": "វេជ្ជបញ្ជារបស់ខ្ញុំ"
```

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
| `FrostedSurface` | iOS-26 glass primitive. Always go through this (or one of the glass composites in §6.5) — never `BackdropFilter` directly. |
| `AdaptiveScaffold` | Breakpoint-aware navigation; **the role-aware glass `AppScaffold` (§6.5.3) is the production wrapper** — `AdaptiveScaffold` is the underlying responsive primitive. |

Before building a new component:

1. Search `lib/shared/widgets/` first.
2. Compose existing primitives if possible.
3. Promote to `shared/` only when ≥2 features use it.

---

## 6.5 Liquid Glass — visual layer

> **Canonical agent entrypoint:** [`liquid-glass-flutter`](../.agents/skills/liquid-glass-flutter/SKILL.md) skill (auto-applied per the Steering Directive at the top of this file).
>
> **Spec source of truth:** [`.kiro/specs-v2-flutter-supabase/10-frontend-liquid-glass/`](../.kiro/specs-v2-flutter-supabase/10-frontend-liquid-glass/) (`requirements.md`, `design.md`, `tasks.md`).
>
> The summary below is a quick-reference when the skill cannot be loaded. **The skill is authoritative when the two disagree.**

The app's visual identity is iOS-26 Liquid Glass. Three promises:

- **Glass that breathes** — `BackdropFilter` blurs content **behind** the surface, never the surface itself. Specular border on top, soft shadow underneath.
- **Motion with intent** — every interaction uses tokens from `lib/core/theme/tokens/motion.dart` (press 0.94 spring, tab expand `easeOutCubic`, page transition 320 ms slide+fade, mesh orbs 9/13/17 s reverse loops).
- **Tokens, not opinions** — every glass value is a `GlassTokens` field on `Theme.of(context).extension<GlassTokens>()!`.

### 6.5.1 Glass widgets you must compose with

| Widget | Where it lives | Compose with |
|---|---|---|
| `FrostedSurface` | `lib/shared/widgets/effects/frosted_surface.dart` | The atomic primitive. Every other glass widget builds on it. |
| `AppMeshBackground` | `lib/shared/widgets/glass/app_mesh_background.dart` | Always at the root of `AppScaffold`. Three orbs over a tuned base color. |
| `AppGlassHeader` | `lib/shared/widgets/glass/app_glass_header.dart` | `PreferredSizeWidget`; large title + subtitle slot; blurs scroll-under content. |
| `AppGlassNavBar` | `lib/shared/widgets/glass/app_glass_nav_bar.dart` | Floating glass pill at the bottom of patient screens; selected pill expands with label. |
| `AppGlassFab` | `lib/shared/widgets/glass/app_glass_fab.dart` | Round glass action button (e.g., the patient QR FAB). |
| `AppGlassCard` | `lib/shared/widgets/glass/app_glass_card.dart` | Tappable list / detail surface. |
| `AppGlassChip` | `lib/shared/widgets/glass/app_glass_chip.dart` | Pill-radius glass — status badges, filter chips. |
| `AppGlassDialog` / `AppGlassBottomSheet` | `lib/shared/widgets/glass/...` | Confirm dialogs and approval sheets. |

Don't compose `BackdropFilter` directly inside a feature — always go through `FrostedSurface` or one of the composites above.

### 6.5.2 BackdropFilter coalescing — share keys

Every `BackdropFilter` inside the app must carry a `BackdropKey`. We share keys per scope so the engine performs **one** blur pass per screen.

```dart
// lib/shared/widgets/effects/backdrop_keys.dart
abstract class BackdropKeys {
  static final shellHeader  = BackdropKey();
  static final contentList  = BackdropKey();
  static final modal        = BackdropKey();
  static final qrSurface    = BackdropKey();
}
```

CI fails if any `BackdropFilter` outside `frosted_surface.dart` is missing a `key`.

### 6.5.3 Role-aware navigation shell

`AppScaffold` reads `currentUserProfileProvider` and switches its layout:

- **Patient bottom nav** — five entries: `Today`, `Prescriptions`, **center QR FAB** (action sheet for *Show my QR* / *Scan QR*), `Connections`, `Settings`.
- **Doctor bottom nav** — four tabs: `Home`, `Patients`, `Compose`, `Settings`. The QR action lives as a glass icon in the app bar trailing area (doctors typically scan a patient's QR face-to-face).
- **Auth shell** — Welcome → Method chooser → Sign-up/Sign-in. No bottom nav. Mesh dialed to 70% opacity, orbs at 60% speed.
- **Tablet / desktop breakpoints** — auto-switch from bottom nav to a left rail (`medium`) or permanent drawer (`expanded`).

When you implement a screen, **never wrap it in a raw `Scaffold`**. Use `AppScaffold` (extended in `09-design-system-localization` and composed with mesh + glass header + role-aware nav per `10-frontend-liquid-glass`).

### 6.5.4 Adaptive opacity

`AdaptiveGlassOpacity` increases tint α whenever:

- `MediaQuery.accessibleNavigation` or `MediaQuery.disableAnimations` is true,
- The caller passes `textHeavy: true` (long-form content inside a glass card),
- The `PerformanceProbe` flips to the `'reduced'` profile (p90 frame time ≥ 18 ms).

You don't read this directly — `FrostedSurface` consumes it. Just pass `textHeavy: true` when you put a big block of body text inside a glass card.

### 6.5.5 Motion tokens

```dart
// lib/core/theme/tokens/motion.dart  (already exists)
abstract class AppMotion {
  static const pressDown      = Duration(milliseconds: 160);
  static const pressUp        = Duration(milliseconds: 200);
  static const tabExpand      = Duration(milliseconds: 260);
  static const pageTransition = Duration(milliseconds: 320);
  static const bottomSheet    = Duration(milliseconds: 360);
  static const dialog         = Duration(milliseconds: 220);
  static const toast          = Duration(milliseconds: 280);
  // mesh orb cycles are configured in AppMeshBackground
}
```

Always use these tokens. Never hardcode `Duration(...)` literals in widget bodies.

When `MediaQuery.disableAnimations` is true, durations collapse to `Duration.zero` automatically inside the helpers we ship in `lib/core/theme/tokens/motion.dart`.

### 6.5.6 Performance budget

| Device class | Frame target | Blur sigma | Mesh orbs |
|---|---|---|---|
| iPhone 12+, Pixel 7+ | 60 fps | 24/28 (light/dark) | 3 |
| iPhone 11, Pixel 5–6 | 60 fps | 20/22 | 3 |
| Pre-2020 Android (Skia) | 50 fps | 16 | 2 (orb C dropped) |

The `PerformanceProbe` watches p90 frame time and downgrades the `glass_profile` automatically. You don't write to this; you just don't fight it. If a screen needs a special-case lower blur, use the `blurSigma` override on `FrostedSurface` — but document why in a code comment.

### 6.5.7 Accessibility on glass

- Every glass surface that contains text must pass `meets_text_contrast_guideline` over the worst-case bright orb position (covered by golden tests).
- Tap targets ≥ 44×44 dp.
- `MediaQuery.textScaler` up to 200% — surfaces grow vertically; never clip.
- When iOS / Android Reduced Transparency is on, glass surfaces become near-opaque (handled by `AdaptiveGlassOpacity`).

### 6.5.8 Recipe: "I'm building a screen"

1. Wrap the page in `AppScaffold(role: ..., title: l.someTitle, body: ...)`. Never `Scaffold` directly.
2. For elevated content, use `AppGlassCard` (tappable) or `FrostedSurface` (custom).
3. For status pills, use `AppGlassChip` styled by your domain `Variant` enum.
4. For confirmation flows, use `AppGlassDialog`; for approval / action menus, use `AppGlassBottomSheet`.
5. Never `BackdropFilter(...)` inline.
6. Reference motion via `AppMotion.*` tokens.
7. Run a golden test in light **and** dark before opening a PR.

---

## 7. l10n rules (pre-generated, no codegen)

> **We do NOT use `flutter gen-l10n` or `l10n.yaml` in this project.**
> The `AppLocalizations` class and its per-locale files are pre-generated
> in `das_tern_mcp/lib/l10n/` and copied here. Treat `lib/l10n/` as
> read-only output, not a codegen input.

- **Every** user-visible string lives in `lib/l10n/*.arb`. Never inline a
  literal in a widget.
- Keys are `camelCase` (e.g. `prescriptionsListTitle`, `doseTakeAction`).
- To add a new string:
  1. Add the key to `das_tern_mcp/lib/l10n/app_km.arb` (Khmer first) and
     `app_en.arb`.
  2. Run `flutter gen-l10n` **inside `das_tern_mcp/`**.
  3. Copy the five updated files into `dastern/lib/l10n/`.
- Plural / placeholder messages use ICU syntax with `@<key>` metadata.
- `AppLocalizations.of(context)` returns nullable — always use `!`:
  ```dart
  final l = AppLocalizations.of(context)!;
  ```

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
- ❌ Don't run `flutter gen-l10n` inside this project — codegen lives in `das_tern_mcp`.
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

**Do not run `flutter gen-l10n`** — `lib/l10n/` is pre-generated output.
To update strings, edit ARBs in `das_tern_mcp/lib/l10n/`, run codegen
there, then copy the five files here.

If any of these fail, fix before requesting review. The AI assistant is
expected to run them itself.

---

## 15. Pointers to deeper docs

- **Auto-applied UI skill** → `.agents/skills/liquid-glass-flutter/SKILL.md` (load this before any UI task — see Steering Directive at the top)
- Architecture decisions → `.kiro/specs-v2-flutter-supabase/00-overview/design.md`
- Data layer + RLS → `.kiro/specs-v2-flutter-supabase/01-supabase-data-layer/design.md`
- Offline reminder lifecycle → `.kiro/specs-v2-flutter-supabase/04-reminder-adherence/design.md`
- Design system + l10n → `.kiro/specs-v2-flutter-supabase/09-design-system-localization/design.md`
- **Liquid Glass visual layer** → `.kiro/specs-v2-flutter-supabase/10-frontend-liquid-glass/design.md` (mesh background, FrostedSurface, glass widgets, role-aware nav, motion catalogue, screen-by-screen visual contract)
- Account & connection model refinement → `.kiro/specs-v2-flutter-supabase/ADDENDUM-001-account-and-connection-refinement.md`

When in doubt, the spec wins. When the spec is silent, this file wins.
When both are silent, ask.
