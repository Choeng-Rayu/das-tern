---
name: liquid-glass-flutter
description: Implement Flutter screens for Das Tern v2 by combining the project's layered architecture (Riverpod + Drift + Repository pattern + feature folders) with the iOS-26 Liquid Glass visual language (FrostedSurface, mesh background, role-aware AppScaffold, glass widget catalog, motion catalogue). Use whenever you build, refactor, or extend any UI in `dastern/lib/`.
metadata:
  last_modified: Tue, 26 May 2026 22:43:00 GMT
---
# Liquid Glass Flutter — Architect & Style Das Tern Screens

## Contents
- [When to use this skill](#when-to-use-this-skill)
- [Source of truth](#source-of-truth)
- [Architectural layers](#architectural-layers)
- [Project structure](#project-structure)
- [Liquid Glass visual layer](#liquid-glass-visual-layer)
- [Workflow: implement a new screen end-to-end](#workflow-implement-a-new-screen-end-to-end)
- [Examples](#examples)
- [Hard rules](#hard-rules)
- [Verification before opening a PR](#verification-before-opening-a-pr)

## When to use this skill

Use this skill any time you are about to:

- Add a new feature module under `dastern/lib/features/<name>/`.
- Build or refactor a UI screen, widget, or page transition.
- Wire a repository, Drift DAO, Riverpod provider, or Supabase call.
- Decide which surface treatment, motion, or layout to apply.

Do **not** use it for non-Flutter work (e.g., SQL migrations, Edge Functions, Play Console setup) — those have their own specs.

## Source of truth

When this skill and the v2 spec set disagree, **the spec set wins**. Read the relevant spec files before implementing:

- Architecture: `.kiro/specs-v2-flutter-supabase/00-overview/design.md`
- Data layer + RLS: `.kiro/specs-v2-flutter-supabase/01-supabase-data-layer/design.md`
- Authentication flows: `.kiro/specs-v2-flutter-supabase/02-authentication/`
- Feature specs (03–08) for the feature you are touching
- Base design system + l10n: `.kiro/specs-v2-flutter-supabase/09-design-system-localization/design.md`
- **Liquid Glass visual contract:** `.kiro/specs-v2-flutter-supabase/10-frontend-liquid-glass/design.md`
- Working contract for AI agents: `dastern/AGENTS.md`
- Account & connection model refinement: `.kiro/specs-v2-flutter-supabase/ADDENDUM-001-account-and-connection-refinement.md`

## Architectural layers

Das Tern v2 enforces strict separation of concerns across three layers per feature. **Never mix UI rendering with business logic or data fetching.**

### Presentation layer (UI)

- Build screens with **Riverpod 2.x** (`flutter_riverpod`, `riverpod_annotation` if generation is used). The legacy MVVM + `provider` pattern is retired.
- Pages extend `ConsumerWidget` or `ConsumerStatefulWidget` and read state via `ref.watch(...)` inside `build`. Inside non-build methods use `ref.read(...)`.
- Use `AsyncValue<T>` from Riverpod for any UI state that originates asynchronously. Render its three branches with `.when(data:, loading:, error:)`.
- Pages **never** call Supabase, Drift, or `flutter_secure_storage` directly. They go through a feature repository exposed as a `Provider`.
- Wrap every page in `AppScaffold` (the role-aware glass shell). Never `Scaffold(...)` directly — see § Liquid Glass below.

### Domain layer

- Entities live as immutable `@freezed` classes under `features/<name>/domain/`. Pure Dart only — no Flutter, no Supabase imports.
- Failures are sealed subclasses of `AppFailure` (`lib/core/error/app_failure.dart`). Repositories return `Result<T, AppFailure>` (a sealed `Result` type) when both success and failure paths matter.
- Use cases are optional: add them only when business logic is non-trivial or shared between repositories.

### Data layer

- **Remote source** wraps `SupabaseClient` calls (RLS-protected).
- **Local source** wraps Drift DAOs (the offline-first cache).
- **Repository** orchestrates both:
  - Reads stream from Drift (read-through) so the UI sees optimistic state immediately.
  - Writes go to Drift first, then enqueue an `OutboxEntry` that the `SyncEngine` (already implemented in `lib/core/sync/`) replays against Supabase.
  - Optionally subscribes to Supabase Realtime to merge remote changes back into Drift.
- Repositories are exposed as `Provider<MyRepository>` — UI never instantiates them.

## Project structure

```text
dastern/lib/
├── main.dart                          # entry point — keep slim
├── app.dart                           # root MaterialApp.router
├── core/                              # cross-cutting infra (NEVER feature code)
│   ├── config/
│   ├── error/
│   ├── i18n/                          # locale controller only (no codegen here)
│   ├── logging/
│   ├── network/
│   ├── routing/
│   ├── storage/{drift,secure}/
│   ├── sync/
│   ├── theme/
│   │   ├── tokens/                    # colors, spacing, radii, motion, glass_tokens
│   │   ├── app_theme.dart             # buildAppTheme() + lightTheme()/darkTheme()
│   │   └── theme_controller.dart
│   └── time/                          # Cambodia timezone helpers
├── features/<name>/                   # ONE folder per spec module (auth, prescriptions, …)
│   ├── data/                          # remote/local sources + repository impl
│   ├── domain/                        # entities + failures + (optional) use cases
│   └── presentation/                  # pages + Riverpod providers + widgets
├── shared/widgets/                    # reusable UI shared by multiple features
│   ├── effects/                       # frosted_surface.dart, backdrop_keys.dart, adaptive_glass_opacity.dart
│   ├── glass/                         # app_mesh_background.dart, app_glass_header.dart, app_glass_nav_bar.dart, …
│   ├── buttons/  cards/  inputs/  states/  badges/  adherence/
│   └── adaptive_scaffold.dart
├── platform/{android,ios}/            # platform-only glue
└── l10n/                              # pre-generated AppLocalizations (do NOT run gen-l10n here)
```

Hard structure rules:

1. UI **never** calls Supabase or Drift directly.
2. `core/` may not depend on `features/`. Ever.
3. A widget moves into `shared/widgets/` only when ≥ 2 features use it.
4. Generated code (`*.g.dart`, `*.freezed.dart`, `app_localizations*.dart`) is committed.

## Liquid Glass visual layer

Three promises drive every visual decision:

- **Glass that breathes** — `BackdropFilter` blurs content **behind** the surface, never the surface itself. Specular border on top, soft shadow underneath.
- **Motion with intent** — every interaction uses tokens from `lib/core/theme/tokens/motion.dart`.
- **Tokens, not opinions** — every glass value is a `GlassTokens` field on `Theme.of(context).extension<GlassTokens>()!`. No magic numbers in widget bodies.

### Glass widgets you must compose with

| Widget | Lives in | Use for |
|---|---|---|
| `FrostedSurface` | `lib/shared/widgets/effects/frosted_surface.dart` | Atomic glass primitive. Every other glass widget builds on it. |
| `AppMeshBackground` | `lib/shared/widgets/glass/app_mesh_background.dart` | Persistent three-orb animated background. Already at the root of `AppScaffold`. |
| `AppScaffold` | `lib/shared/widgets/glass/app_scaffold.dart` | Role-aware shell — wraps every page. Composes mesh + header + nav. |
| `AppGlassHeader` | `lib/shared/widgets/glass/app_glass_header.dart` | `PreferredSizeWidget`; large title + subtitle; blurs scroll-under content. |
| `AppGlassNavBar` | `lib/shared/widgets/glass/app_glass_nav_bar.dart` | Floating glass pill at the bottom; selected pill expands with label. |
| `AppGlassFab` | `lib/shared/widgets/glass/app_glass_fab.dart` | Round glass action button (e.g. patient QR FAB). |
| `AppGlassCard` | `lib/shared/widgets/glass/app_glass_card.dart` | Tappable list / detail surface. |
| `AppGlassChip` | `lib/shared/widgets/glass/app_glass_chip.dart` | Pill-radius status badges and filter chips. |
| `AppGlassDialog` / `AppGlassBottomSheet` | `lib/shared/widgets/glass/...` | Confirmations and approval / action menus. |

**Never** call `BackdropFilter(...)` inline inside a feature. Always go through `FrostedSurface` or one of the composites.

### BackdropFilter coalescing — share keys

Every `BackdropFilter` must carry a `BackdropKey`. Share keys per scope so the engine performs **one** blur pass per screen.

```dart
// lib/shared/widgets/effects/backdrop_keys.dart
abstract class BackdropKeys {
  static final shellHeader = BackdropKey();
  static final contentList = BackdropKey();
  static final modal       = BackdropKey();
  static final qrSurface   = BackdropKey();
}
```

CI fails when a `BackdropFilter` outside `frosted_surface.dart` is missing a `key`. Do not bypass this lint.

### Role-aware navigation shell

`AppScaffold` reads `currentUserProfileProvider` and switches its layout:

- **Patient bottom nav** — five entries: `Today`, `Prescriptions`, **center QR FAB** (action sheet for *Show my QR* / *Scan QR*), `Connections`, `Settings`.
- **Doctor bottom nav** — four tabs: `Home`, `Patients`, `Compose`, `Settings`. The QR action lives as a glass icon in the app bar trailing area.
- **Auth shell** — Welcome → Method chooser → Sign-up/Sign-in. No bottom nav. Mesh dialed to 70% opacity, orbs at 60% speed.
- **Tablet / desktop breakpoints** — auto-switch from bottom nav to a left rail (`medium`) or permanent drawer (`expanded`).

### Motion tokens

```dart
// lib/core/theme/tokens/motion.dart
abstract class AppMotion {
  static const pressDown      = Duration(milliseconds: 160);
  static const pressUp        = Duration(milliseconds: 200);
  static const tabExpand      = Duration(milliseconds: 260);
  static const pageTransition = Duration(milliseconds: 320);
  static const bottomSheet    = Duration(milliseconds: 360);
  static const dialog         = Duration(milliseconds: 220);
  static const toast          = Duration(milliseconds: 280);
  // Mesh orb cycles configured inside AppMeshBackground.
}
```

Use these tokens. Never hardcode `Duration(...)` in widget bodies. When `MediaQuery.disableAnimations` is true, helpers in this file collapse durations to `Duration.zero` automatically.

### Adaptive opacity

`AdaptiveGlassOpacity` raises tint α automatically when:

- `MediaQuery.accessibleNavigation` or `MediaQuery.disableAnimations` is true,
- The caller passes `textHeavy: true` to `FrostedSurface` (long-form content inside),
- The `PerformanceProbe` flips to the `'reduced'` profile (p90 frame time ≥ 18 ms).

You don't read the provider directly — `FrostedSurface` consumes it. Just pass `textHeavy: true` when you wrap a big block of body text.

### Performance budget

| Device class | Frame target | Blur sigma | Mesh orbs |
|---|---|---|---|
| iPhone 12+ / Pixel 7+ | 60 fps | 24/28 | 3 |
| iPhone 11 / Pixel 5–6 | 60 fps | 20/22 | 3 |
| Pre-2020 Android (Skia) | 50 fps | 16 | 2 (orb C dropped) |

`PerformanceProbe` watches p90 frame time and downgrades the global glass profile automatically. Don't fight it. If a single screen needs an explicit lower blur, override via `FrostedSurface(blurSigma: ...)` and document why in a code comment.

### Accessibility on glass

- Every glass surface that contains text must pass `meets_text_contrast_guideline` over the worst-case bright orb position (covered by golden tests).
- Tap targets ≥ 44 × 44 dp.
- `MediaQuery.textScaler` up to 200% — surfaces grow vertically; never clip.
- When iOS / Android Reduced Transparency is on, glass surfaces become near-opaque (handled by `AdaptiveGlassOpacity`).

## Workflow: implement a new screen end-to-end

Follow this sequential workflow. Copy the checklist and tick items as you complete them.

### Task progress

- [ ] **Step 1 — Read the spec.** Open the relevant feature spec (e.g., `03-prescription-medication/`). Read `requirements.md`, the design section that covers your screen, and the matching task in `tasks.md`. Re-read `10-frontend-liquid-glass/design.md` § 6 for the visual contract for that screen.
- [ ] **Step 2 — Domain models.** Create or extend immutable `@freezed` entities under `features/<name>/domain/`. Add `fromJson` / `toJson` only if the entity crosses the wire. Pure Dart only.
- [ ] **Step 3 — Failures.** If the feature can fail in domain-specific ways, add subclasses of `AppFailure` (e.g., `class FreemiumLimitFailure extends AppFailure`).
- [ ] **Step 4 — Local source (Drift DAO).** Add or extend a Drift table under `lib/core/storage/drift/tables/` and a DAO under `daos/`. Expose `watchX()` streams the repository can read through.
- [ ] **Step 5 — Remote source.** Wrap the Supabase calls (RLS-protected `from('...').select/insert/update/delete` or `rpc(...)`). Return raw maps; do not construct domain entities here.
- [ ] **Step 6 — Repository.** Glue the two sources. Reads return Drift streams. Writes go Drift → outbox → Supabase. Convert raw remote rows to domain entities here. Apply optional caching / retry logic.
- [ ] **Step 7 — (Optional) Use cases.** Only when the logic is shared across repositories or too complex for a `Notifier`. Pure Dart.
- [ ] **Step 8 — Riverpod providers.** Expose the repository as a `Provider`. Expose page-level state via `StreamProvider`, `FutureProvider`, or a `Notifier` / `AsyncNotifier`. Always type the provider explicitly.
- [ ] **Step 9 — Strings.** Add keys to **both** `dastern/lib/l10n/app_km.arb` (Khmer first) and `app_en.arb`, then copy the regenerated `app_localizations*.dart` from `das_tern_mcp/lib/l10n/`. Do **not** run `flutter gen-l10n` inside `dastern/`.
- [ ] **Step 10 — UI (Liquid Glass).**
  - Wrap the page in `AppScaffold(role: ..., title: l.someTitle, body: ...)`. Never `Scaffold(...)` directly.
  - For elevated content, use `AppGlassCard` (tappable) or `FrostedSurface` (custom).
  - For status pills, use `AppGlassChip`.
  - For confirmation flows, use `AppGlassDialog`; for action menus and approvals, `AppGlassBottomSheet`.
  - Reference motion via `AppMotion.*` tokens.
  - Provide explicit semantics labels for every interactive element.
- [ ] **Step 11 — Routes.** Add the route to `lib/core/routing/app_router.dart`. Use the project's single `GoRouter`. Do not create a new one per feature.
- [ ] **Step 12 — Offline check.** Run through the Offline-first checklist from `dastern/AGENTS.md` § 8: write goes to Drift first, outbox enqueued, UI reads from Drift, idempotent replay.
- [ ] **Step 13 — Tests.**
  - Unit: repository (mock Supabase + in-memory Drift).
  - Widget: page using `pumpWidget` + `ProviderScope` overrides.
  - Golden: any new shared widget × {light, dark} × {km, en}.
  - Contrast: glass surfaces pass `meets_text_contrast_guideline`.
  - Motion respect: `MediaQuery.disableAnimations = true` collapses durations correctly.
- [ ] **Step 14 — Verification.** Run `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-warnings --fatal-infos`, and `flutter test --coverage` from `/home/rayu/das-tern/dastern/`.

## Examples

### Data layer — repository pattern (offline-first, Riverpod)

```dart
// features/prescriptions/data/prescription_repository.dart
abstract class PrescriptionRepository {
  Stream<List<Prescription>> watchActive();
  Future<Result<Prescription, AppFailure>> create(PrescriptionDraft draft);
}

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  PrescriptionRepositoryImpl({
    required this.db,
    required this.supabase,
    required this.sync,
  });

  final AppDatabase db;
  final SupabaseClient supabase;
  final SyncEngine sync;

  @override
  Stream<List<Prescription>> watchActive() =>
      db.prescriptionDao.watchActive().map(
            (rows) => rows.map(Prescription.fromRow).toList(),
          );

  @override
  Future<Result<Prescription, AppFailure>> create(
    PrescriptionDraft draft,
  ) async {
    try {
      final row = await db.prescriptionDao.insert(draft);
      await sync.enqueue(OutboxOp.create('prescriptions', row.toMap()));
      return Result.ok(Prescription.fromRow(row));
    } on PostgrestException catch (e) {
      if (e.message.contains('freemium_limit_prescriptions')) {
        return Result.err(const FreemiumLimitFailure(resource: 'prescriptions'));
      }
      return Result.err(AppFailure.unexpected(e.message));
    }
  }
}

// features/prescriptions/presentation/providers/prescription_providers.dart
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

### Presentation layer — page wrapped in glass

```dart
// features/prescriptions/presentation/pages/prescription_list_page.dart
class PrescriptionListPage extends ConsumerWidget {
  const PrescriptionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncList = ref.watch(activePrescriptionsProvider);

    return AppScaffold(
      role: ref.watch(currentUserRoleProvider),
      title: l.prescriptionsListTitle,
      body: asyncList.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e is AppFailure ? l.byFailure(e) : l.errorsUnexpected,
          onRetry: () => ref.invalidate(activePrescriptionsProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                title: l.prescriptionsEmptyTitle,
                action: AppButton(
                  label: l.prescriptionsCreateAction,
                  onPressed: () => context.push('/patient/prescriptions/new'),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppGlassCard(
                    onTap: () =>
                        context.push('/patient/prescriptions/${items[i].id}'),
                    child: PrescriptionRow(prescription: items[i]),
                  ),
                ),
              ),
      ),
    );
  }
}
```

### Glass primitive reference (do not edit casually)

```dart
// lib/shared/widgets/effects/frosted_surface.dart
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = EdgeInsets.zero,
    this.tint,
    this.blurSigma,
    this.backdropKey,
    this.opacity = 1.0,
    this.textHeavy = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final Color? tint;
  final double? blurSigma;
  final BackdropKey? backdropKey;
  final double opacity;
  final bool textHeavy;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GlassTokens>()!;
    final actualTint = tint ?? Theme.of(context).colorScheme.surface;
    final adapt = AdaptiveGlassOpacity.of(context);
    final bonus = adapt.bonus + (textHeavy ? 0.05 : 0.0);
    final hi = (tokens.tintHigh + bonus).clamp(0.0, 0.95);
    final lo = (tokens.tintLow + bonus).clamp(0.0, 0.95);
    final sigma = blurSigma ?? tokens.blurRadius;

    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: tokens.shadowColor,
              blurRadius: tokens.shadowBlur,
              offset: tokens.shadowOffset,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            key: backdropKey,
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    actualTint.withOpacity(hi),
                    actualTint.withOpacity(lo),
                  ],
                ),
                border: Border.all(
                  color: tokens.borderColor,
                  width: tokens.borderWidth,
                ),
                borderRadius: borderRadius,
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Hard rules

These are non-negotiable. If a change violates any of these, **stop and ask**.

1. ❌ No new state-management library. **Riverpod only**. No Bloc, GetX, or `provider` (the package).
2. ❌ No `BackdropFilter(...)` outside `lib/shared/widgets/effects/frosted_surface.dart`. The CI lint enforces this.
3. ❌ No `Scaffold(...)` directly inside a feature page. Always `AppScaffold`.
4. ❌ No hardcoded colors, spacings, radii, durations, or curves in widget bodies. Token files only.
5. ❌ No magic numbers for blur sigma — use the `GlassTokens` extension.
6. ❌ No raw `print(...)`. Use `appLogger`.
7. ❌ No PII in logs (patient names, phone numbers, prescription text). Log IDs only.
8. ❌ No store of auth tokens in `SharedPreferences`. Use `flutter_secure_storage`.
9. ❌ No string in a widget that isn't in both `app_km.arb` and `app_en.arb`.
10. ❌ No `flutter gen-l10n` inside `dastern/`. Codegen lives in `das_tern_mcp/`; we copy the output.
11. ❌ No new `MaterialApp` in a test or page — one app shell, full stop.
12. ❌ No `git push` to `main`. Always PR + review.
13. ❌ No removing the `FAMILY_MEMBER` role checks lazily — the role is gone entirely (per ADDENDUM-001). v2 has only `PATIENT` and `DOCTOR`.

## Verification before opening a PR

```bash
# from /home/rayu/das-tern/dastern/
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-warnings --fatal-infos
flutter test --coverage
```

If any of these fail, fix before requesting review. The agent is expected to run them itself after each task.
