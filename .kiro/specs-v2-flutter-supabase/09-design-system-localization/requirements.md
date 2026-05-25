# Requirements: Design System & Localization

## Introduction

This spec defines the cross-cutting design system, theming, and localization that every other v2 feature consumes. It consolidates v1's `global-widget-system-design` and `ios26-liquid-glass-refactor` requirements with a clear set of design tokens, reusable widgets, and a fully bilingual (Khmer/English) i18n setup.

## Glossary

- **Design_Token** — A named value (color, spacing, radius, typography size) that components reference instead of hard-coding.
- **Token_Set** — A complete collection of design tokens for a specific theme (light or dark).
- **Reusable_Widget** — A general-purpose Flutter widget shipped under `lib/shared/widgets/` that any feature can compose.
- **i18n_Bundle** — An ARB file that maps message keys to translated strings.
- **Type_Scale** — The font-size + line-height steps applied across the app.

## Requirements

### Requirement 1: Design tokens

**User Story:** As a designer/developer, I want a single source of truth for colors, spacing, and typography, so that the app stays visually coherent.

#### Acceptance Criteria

1. THE Flutter_App SHALL define design tokens under `lib/core/theme/tokens/` as static const maps.
2. THE token categories SHALL include: colors, spacing, radii, elevations, typography, motion durations.
3. THE Flutter_App SHALL provide light and dark `ColorScheme` derived from a single seed color (`#1A8E5F` Das Tern green) plus accent overrides.
4. THE typography token set SHALL define 7 sizes: displayLarge, headlineLarge, headlineMedium, titleLarge, bodyLarge, bodyMedium, labelSmall (Material 3 alignment).
5. THE Flutter_App SHALL ship a Khmer-first font stack (Noto Sans Khmer or Battambang) plus a Latin fallback (Inter or Plus Jakarta Sans). Khmer text SHALL never fall back to a generic font.

### Requirement 2: ThemeData bundles

**User Story:** As a developer, I want ready-to-use `ThemeData` for light and dark, so that the app theme is consistent everywhere.

#### Acceptance Criteria

1. THE Flutter_App SHALL expose `lightTheme()` and `darkTheme()` functions in `lib/core/theme/`.
2. THE themes SHALL apply Material 3 (`useMaterial3: true`).
3. THE themes SHALL set `colorScheme`, `textTheme`, `cardTheme`, `appBarTheme`, `elevatedButtonTheme`, `outlinedButtonTheme`, `inputDecorationTheme`, `chipTheme`, `dialogTheme`, `bottomSheetTheme`, `floatingActionButtonTheme`.
4. THE themes SHALL pass WCAG AA contrast on every text-on-surface combination (verified by a unit test using `package:material_color_utilities`).
5. THE Flutter_App SHALL respect system dark mode toggle via `ThemeMode.system` when the user has not set a preference.

### Requirement 3: Reusable widgets

**User Story:** As a developer, I want a small but complete catalog of reusable widgets, so that I don't reinvent buttons or cards.

#### Acceptance Criteria

1. THE Flutter_App SHALL ship `AppButton` (variants: filled, outlined, text, danger, loading) under `lib/shared/widgets/buttons/`.
2. THE Flutter_App SHALL ship `AppTextField` with consistent error/help-text rendering and label/hint behavior in both languages.
3. THE Flutter_App SHALL ship `AppCard`, `AppDivider`, `AppChip`, `AppDialog`, `AppBottomSheet`.
4. THE Flutter_App SHALL ship feature-specific shared widgets where appropriate: `AdherenceRing`, `MedicationRow`, `DoseStatusBadge`, `ConnectionCard`, `PermissionChip`, `LifecycleBadge`, `EmptyState`, `LoadingState`, `ErrorState`.
5. EACH reusable widget SHALL be documented with a Flutter widget storybook entry (using `widgetbook` or similar, optional but recommended).
6. EACH reusable widget SHALL pass golden tests in light + dark.

### Requirement 4: Iconography and illustrations

**User Story:** As a designer, I want a consistent icon set, so that the visual language feels unified.

#### Acceptance Criteria

1. THE Flutter_App SHALL use Material Symbols (rounded variant) as the primary icon set via `material_symbols_icons`.
2. THE Flutter_App SHALL allow custom SVG illustrations under `assets/illustrations/` for empty states (no prescriptions, no connections, no notifications, etc.) — bilingual where text appears.
3. THE Flutter_App SHALL render SVG illustrations via `flutter_svg`.
4. THE Flutter_App SHALL include a simple animated success/failure illustration for completed actions.

### Requirement 5: Internationalization (i18n)

**User Story:** As a Khmer-speaking user, I want all UI in Khmer, so that I can use the app naturally.

#### Acceptance Criteria

1. THE Flutter_App SHALL use `flutter_localizations` + ARB files under `lib/l10n/`, with `app_km.arb` (default) and `app_en.arb`.
2. THE Flutter_App SHALL configure `MaterialApp.localizationsDelegates` with `AppLocalizations.delegate`, `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate`.
3. THE Flutter_App SHALL set `supportedLocales: [Locale('km'), Locale('en')]`.
4. WHEN a string is missing in Khmer, THE Flutter_App SHALL fall back to English and emit a debug warning.
5. THE Flutter_App SHALL provide a language toggle in settings + at sign-in.
6. THE Flutter_App SHALL persist language choice in `SharedPreferences` and apply without restart.

### Requirement 6: Localization tooling

**User Story:** As a translator, I want a clean ARB file with metadata, so that I can add translations confidently.

#### Acceptance Criteria

1. THE Flutter_App SHALL include a `l10n.yaml` config with `arb-dir: lib/l10n`, `template-arb-file: app_km.arb`, `output-localization-file: app_localizations.dart`, `synthetic-package: false`.
2. THE ARB files SHALL include `@<key>` metadata blocks with `description` and `placeholders` definitions.
3. THE app SHALL run `flutter gen-l10n` as a CI step and fail the build if generated code is stale.
4. THE app SHALL group keys by feature with a prefix convention (`auth.signIn.button`, `prescriptions.create.title`, etc.).

### Requirement 7: Number, date, and currency formatting

**User Story:** As a user, I want numbers and dates formatted for my locale, so that they read naturally.

#### Acceptance Criteria

1. THE Flutter_App SHALL use `intl` package's `DateFormat`, `NumberFormat` with the active locale.
2. THE Flutter_App SHALL render Khmer numerals (០-៩) when language is Khmer, in addition to standard digits where appropriate (e.g., dosage amounts may stay numeric for clarity — subject to UX review).
3. THE Flutter_App SHALL display currency as USD symbol for prices ("$0.50") regardless of locale.
4. THE Flutter_App SHALL display all timestamps in the user's `profiles.timezone`.
5. THE Flutter_App SHALL use 12h format in English and 12h format in Khmer with localized AM/PM markers.

### Requirement 8: Accessibility

**User Story:** As a user with accessibility needs, I want the app to support screen readers and large text, so that I can use it.

#### Acceptance Criteria

1. THE Flutter_App SHALL declare `Semantics` labels on every interactive widget.
2. THE Flutter_App SHALL use `MediaQuery.textScaler` to scale text up to 200% without breaking layouts.
3. THE Flutter_App SHALL meet WCAG AA contrast in both themes.
4. THE Flutter_App SHALL ensure tap targets are ≥ 44x44 px.
5. THE Flutter_App SHALL pass `flutter_test`'s `meetsGuideline(textContrastGuideline)` for golden screens.

### Requirement 9: Layout primitives

**User Story:** As a developer, I want responsive layout primitives, so that I don't reinvent breakpoints.

#### Acceptance Criteria

1. THE Flutter_App SHALL define `Breakpoint.compact` (<600), `medium` (<840), `expanded` (≥840).
2. THE Flutter_App SHALL provide an `AdaptiveScaffold` that switches between bottom-nav (compact) and rail/drawer (medium/expanded).
3. THE Flutter_App SHALL provide responsive padding (`AppPadding.page`, `AppPadding.section`) that adjusts by breakpoint.
4. THE Flutter_App SHALL test layouts at 320, 360, 411, 768, 1280 widths.

### Requirement 10: Motion and animations

**User Story:** As a user, I want subtle animations, so that the app feels alive without being distracting.

#### Acceptance Criteria

1. THE Flutter_App SHALL use Material 3 motion durations (`emphasized`, `standard`, `quick`) from token set.
2. THE Flutter_App SHALL respect `MediaQuery.disableAnimations` if set by the OS.
3. THE Flutter_App SHALL animate page transitions with a gentle slide+fade (60ms standard).
4. THE Flutter_App SHALL animate state changes (success toast slide-in, error shake) with a max 300ms duration.

### Requirement 11: Visual language (carried from ios26-liquid-glass-refactor)

**User Story:** As a designer, I want a distinctive visual identity inspired by iOS 26 "Liquid Glass" patterns, so that the app feels modern.

#### Acceptance Criteria

1. THE Flutter_App SHALL use frosted glass effects (`BackdropFilter` with blur) on key surfaces: bottom navigation, sticky headers in scroll views, modal sheets.
2. THE Flutter_App SHALL apply soft, layered shadows (rather than hard borders) on elevated surfaces.
3. THE Flutter_App SHALL use rounded corners with consistent radii (8, 12, 16, 24).
4. THE Flutter_App SHALL avoid heavy purely decorative gradients on text or icons.
5. THE Flutter_App SHALL consume the same patterns in light and dark mode (the glass effect adapts via underlying surface).

### Requirement 12: Theming preferences UI

**User Story:** As a user, I want to switch themes from settings, so that I can match my preference.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a Settings > Appearance screen with "Light", "Dark", "System default" options.
2. WHEN changed, THE Flutter_App SHALL apply immediately and persist in `SharedPreferences`.
3. THE Flutter_App SHALL apply on cold start using the saved value.

### Requirement 13: Testing

**User Story:** As a quality engineer, I want regression tests, so that visual changes are intentional.

#### Acceptance Criteria

1. THE Flutter_App SHALL ship a golden test suite under `test/golden/` for each reusable widget in light + dark.
2. THE Flutter_App SHALL ship a `widgetbook` (or similar) catalog accessible via a hidden dev-only route.
3. THE Flutter_App SHALL include layout tests at all 5 breakpoints.
4. CI SHALL fail if golden mismatches occur and require explicit `--update-goldens`.
