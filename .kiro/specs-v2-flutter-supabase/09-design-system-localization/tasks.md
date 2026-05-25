# Tasks: Design System & Localization

## Phase 1 — Tokens (1 day)

- [ ] **1.1** `lib/core/theme/tokens/colors.dart` — brand seed, semantic accents, adherence indicators.
- [ ] **1.2** `lib/core/theme/tokens/typography.dart` — type scale + Khmer + Latin font families.
- [ ] **1.3** `lib/core/theme/tokens/spacing.dart`, `radii.dart`, `elevations.dart`, `motion.dart`, `breakpoints.dart`.
- [ ] **1.4** Document each token with comment explaining usage.

## Phase 2 — Fonts (0.5 day)

- [ ] **2.1** Add Battambang (or Noto Sans Khmer) and Inter font files under `assets/fonts/`.
- [ ] **2.2** Configure `pubspec.yaml` font declarations.
- [ ] **2.3** Verify Khmer rendering on a sample screen.

## Phase 3 — ThemeData (1 day)

- [ ] **3.1** `lightTheme()` and `darkTheme()` per design § 5.
- [ ] **3.2** Component themes for cards, buttons, inputs, chips, dialogs, bottom sheets.
- [ ] **3.3** Contrast unit tests using `material_color_utilities`.

## Phase 4 — Localization setup (1 day)

- [ ] **4.1** `l10n.yaml` config.
- [ ] **4.2** `app_km.arb` (template) + `app_en.arb` with at least 100 starter keys grouped by feature.
- [ ] **4.3** Run `flutter gen-l10n`; commit generated `app_localizations.dart`.
- [ ] **4.4** `LocaleController` Riverpod provider per design § 11.
- [ ] **4.5** Test: every key in en exists in km and vice versa.
- [ ] **4.6** CI step: `flutter gen-l10n` runs and fails on stale generated code.

## Phase 5 — Reusable widgets (2 days)

- [ ] **5.1** `AppButton` (4 variants).
- [ ] **5.2** `AppTextField` with bilingual error/help.
- [ ] **5.3** `AppCard`, `AppDivider`, `AppChip`, `AppDialog`, `AppBottomSheet`.
- [ ] **5.4** `EmptyState`, `LoadingState`, `ErrorState` with bilingual copy.
- [ ] **5.5** `FrostedSurface` per design § 7.
- [ ] **5.6** `AdaptiveScaffold` per design § 8.

## Phase 6 — Domain widgets (1.5 days)

- [ ] **6.1** `AdherenceRing` widget with green/yellow/red color logic.
- [ ] **6.2** `DoseStatusBadge` for each `DoseEventStatus`.
- [ ] **6.3** `LifecycleBadge` for each `PrescriptionStatus`.
- [ ] **6.4** `PermissionChip`, `ConnectionCard`, `MedicationRow`.
- [ ] **6.5** Each widget bilingually labeled and golden-tested.

## Phase 7 — Number, date, currency formatting (0.5 day)

- [ ] **7.1** `KhmerNumber.fromInt` helper per design § 10.
- [ ] **7.2** Date formatter wrapper per active locale.
- [ ] **7.3** Currency formatter that always renders USD symbol.
- [ ] **7.4** Decision in UX review: dosage amounts → arabic-only or localized; document in `docs/UX_DECISIONS.md`.

## Phase 8 — Settings (0.5 day)

- [ ] **8.1** `AppearanceSettingsPage` per design § 12.
- [ ] **8.2** Toggle visible from sign-in screen too.

## Phase 9 — Accessibility audit (1 day)

- [ ] **9.1** Add `Semantics` labels on every interactive widget.
- [ ] **9.2** Layout tests at 200% text scale.
- [ ] **9.3** Color contrast verified for all token combinations.
- [ ] **9.4** Tap-target audit: every interactive element ≥ 44x44.

## Phase 10 — Storybook (1 day, optional)

- [ ] **10.1** Add `widgetbook` package.
- [ ] **10.2** Catalog every shared widget under `lib/shared/widgets/`.
- [ ] **10.3** Hidden dev route `/dev/widgetbook` gated by `kDebugMode`.

## Phase 11 — Tests (1 day)

- [ ] **11.1** Golden tests per shared widget × {light, dark} × {en, km}.
- [ ] **11.2** Layout tests at 5 breakpoints.
- [ ] **11.3** L10n parity test (key set equality between en and km).
- [ ] **11.4** Contrast unit tests.

## Phase 12 — Sign-off

- [ ] **12.1** Demo: switch language → all text updates without restart.
- [ ] **12.2** Demo: switch theme → all surfaces respond.
- [ ] **12.3** Demo: 200% text scaling on the home screen — no overflows.
- [ ] **12.4** Designer sign-off on visual fidelity to design tokens.
