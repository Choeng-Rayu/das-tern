# Requirements: Frontend — Liquid Glass Visual Layer

> **Visual layer that wraps every v2 feature.** This spec extends the base design system in [`09-design-system-localization`](../09-design-system-localization/) with the iOS 26 *Liquid Glass* surfaces, mesh background, role-aware navigation, and motion catalogue. It is consumed by every feature spec (02–08) but defines no business logic of its own.

## Introduction

Das Tern v2 wears the iOS 26 Liquid Glass visual language. Surfaces blur the content behind them, never themselves. A persistent three-orb mesh background lives behind every screen. Press feedback is a 0.94 spring; selected tabs expand and reveal their label; pages slide+fade in 320 ms. The aesthetic is calm, warm-green, and trustworthy — the opposite of clinical-cold blue.

This spec defines the visual contract every feature ships against. It does not redefine flows; it dresses them in glass.

## Glossary

- **Liquid Glass** — Apple's iOS 26 visual style that blends blur, transparency, specular highlights, and subtle motion. v2 approximates it with `BackdropFilter` plus a tinted gradient.
- **FrostedSurface** — The atomic glass primitive used by every elevated component. Always built on `BackdropFilter` + `ClipRRect` + a tinted `LinearGradient` overlay.
- **GlassTokens** — A `ThemeExtension<GlassTokens>` registered on both light and dark themes. Holds blur sigma, tint stops, border / shadow values, default radii.
- **AppMeshBackground** — A persistent full-screen background composed of three animated radial-gradient orbs over a base surface color.
- **BackdropKey** — Flutter 3.13+ mechanism for coalescing multiple `BackdropFilter`s into one render pass. v2 mandates shared keys per scope.
- **AdaptiveGlassOpacity** — A `Provider` that increases tint α when Reduced Transparency is on, when text is rendered inside, or when frame budget is tight.
- **PerformanceProbe** — A widget that monitors p90 frame time and downgrades the global glass profile (lower blur, fewer orbs) on slow devices.
- **Role-aware shell** — `AppScaffold` selects the navigation layout (tabs vs rail vs drawer) and the bottom-nav contents based on the signed-in user's `profiles.role`.

## Requirements

### Requirement 1: Glass tokens registered on both themes

**User Story:** As a developer, I want a single set of glass-surface values that swap correctly between light and dark, so that I never hardcode blur sigmas, tint α, or shadow colors.

#### Acceptance Criteria

1. THE Flutter_App SHALL define a `GlassTokens` `ThemeExtension<GlassTokens>` containing: `blurRadius`, `tintHigh`, `tintLow`, `borderColor`, `borderWidth`, `shadowColor`, `shadowBlur`, `shadowOffset`.
2. THE `lightTheme()` and `darkTheme()` factories SHALL register `GlassTokens.light` and `GlassTokens.dark` respectively via `ThemeData(extensions: [...])`.
3. THE light token set SHALL use blur radius 24, tintHigh 0.18, tintLow 0.06, shadow `black @ 12%`.
4. THE dark token set SHALL use blur radius 28, tintHigh 0.16, tintLow 0.04, shadow `black @ 35%`.
5. THE Flutter_App SHALL implement `lerp(other, t)` on `GlassTokens` so theme transitions interpolate smoothly.
6. THE Flutter_App SHALL expose token access as `Theme.of(context).extension<GlassTokens>()!` and never read the underlying constants directly outside the tokens file.

### Requirement 2: FrostedSurface as the atomic primitive

**User Story:** As a developer, I want one place that knows how to render a glass surface, so that every glass widget composes the same primitive.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide `lib/shared/widgets/effects/frosted_surface.dart` exposing a `FrostedSurface` `StatelessWidget`.
2. `FrostedSurface` SHALL accept: `child`, `borderRadius` (default `Radius.circular(20)`), `padding`, `tint`, `blurSigma`, `backdropKey`, `opacity`.
3. THE widget tree SHALL be: `Opacity → DecoratedBox(boxShadow) → ClipRRect → BackdropFilter → DecoratedBox(linearGradient + border) → Padding → child`.
4. THE tint SHALL be applied as a `LinearGradient` from top-left (α = `tintHigh`) to bottom-right (α = `tintLow`) — never as a flat fill.
5. WHEN `tint` is null, THE Flutter_App SHALL default to `Theme.of(context).colorScheme.surface`.
6. THE Flutter_App SHALL allow `blurSigma` to override the token value, but only via deliberate caller intent.
7. WHEN Reduced Transparency is active OR `AdaptiveGlassOpacity.bonus > 0`, THE tint stops SHALL increase by the bonus value, clamped to `[0.0, 1.0]`.

### Requirement 3: BackdropFilter coalescing via BackdropKey

**User Story:** As a developer, I want repeated glass surfaces on the same screen to share one blur pass, so that frame time stays under 16 ms even with many cards.

#### Acceptance Criteria

1. THE Flutter_App SHALL define named `BackdropKey` instances in `lib/shared/widgets/effects/backdrop_keys.dart`: `BackdropKeys.shellHeader`, `BackdropKeys.contentList`, `BackdropKeys.modal`, `BackdropKeys.qrSurface`.
2. WHEN two or more `FrostedSurface`s render on the same screen with the same scope, THEY SHALL share the same `BackdropKey` so the engine performs the blur once.
3. THE Flutter_App SHALL include a CI lint rule (custom `analyzer_plugin` or a CI grep gate) that flags any `BackdropFilter` outside `frosted_surface.dart` lacking a `key`.
4. THE Flutter_App SHALL document the chosen `BackdropKey` for every glass widget composition in code comments.

### Requirement 4: AppMeshBackground (always-on living background)

**User Story:** As a user, I want the app to feel alive even when no cards are visible, so that no screen feels blank.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide `lib/shared/widgets/glass/app_mesh_background.dart` as a `StatefulWidget` accepting `child` and rendering it above three animated orbs over a base color.
2. THE orbs SHALL be drawn via `CustomPaint` using `RadialGradient`. Three orbs: A (`brand.seed` α 0.30, 9 s reverse loop), B (`brand.dark` α 0.22, 13 s loop), C (`brand.light` α 0.16, 17 s loop).
3. THE Flutter_App SHALL drive orbs with two `AnimationController`s (9 s and 13 s); the third orb reuses the 13 s controller with a phase offset.
4. WHEN `MediaQuery.disableAnimations` is true, THE orbs SHALL freeze at their start positions.
5. WHEN the widget is disposed, ALL animation controllers SHALL be disposed in `dispose()`.
6. THE base color SHALL come from `colorScheme.surface` (light) or a tuned `surfaceContainerLowest` derivative (dark, e.g. `#0B1410`).

### Requirement 5: Role-aware navigation shell

**User Story:** As a Patient or Doctor, I want a navigation layout that fits my role, so that the most-used actions are one tap away.

#### Acceptance Criteria

1. THE `AppScaffold` widget (extended from `09-design-system-localization`) SHALL compose `AppMeshBackground` + `AppGlassHeader` + role-aware nav.
2. WHEN `profiles.role == 'PATIENT'`, the bottom nav SHALL render five entries: Today, Prescriptions, Connect (centered glass FAB), Connections, Settings.
3. WHEN `profiles.role == 'DOCTOR'`, the bottom nav SHALL render four tabs: Home, Patients, Compose, Settings; QR scan/show SHALL appear as a glass icon button in the app bar trailing area.
4. THE selected tab SHALL animate to a glass pill with the label visible (260 ms `easeOutCubic`); unselected tabs render the icon only.
5. WHEN the screen is the Welcome / Method-chooser / sign-in flow, THE bottom nav SHALL be hidden and the mesh orbs SHALL slow to 60% of their normal speed.
6. WHEN the breakpoint exceeds `medium`, THE shell SHALL switch to a left navigation rail; on `expanded`, to a permanent drawer.

### Requirement 6: Glass widget catalog

**User Story:** As a feature developer, I want a complete set of glass-flavoured widgets, so that I never compose `BackdropFilter` directly inside a feature.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide these glass composites under `lib/shared/widgets/glass/`:
   - `AppGlassHeader` — `PreferredSizeWidget` with title, optional subtitle, leading and trailing slots, blurs content behind on scroll.
   - `AppGlassNavBar` — Floating glass pill at the bottom of patient screens.
   - `AppGlassFab` — Round glass action button (used for the patient QR FAB).
   - `AppGlassCard` — Tappable list / detail surface that wraps `FrostedSurface` and accepts `onTap`.
   - `AppGlassChip` — Pill-radius glass surface for status badges and filter chips.
   - `AppGlassDialog` — `Dialog` styled with glass.
   - `AppGlassBottomSheet` — Bottom sheet styled with glass; max height 80% screen.
2. EACH glass composite SHALL pass through to the equivalent base widget from `09-design-system-localization` where one exists, adding only the surface treatment.
3. EACH glass composite SHALL be covered by golden tests in light + dark.

### Requirement 7: Adaptive opacity

**User Story:** As a user with accessibility settings or on a constrained device, I want the app to remain legible.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide an `AdaptiveGlassOpacity` `InheritedWidget` (or Riverpod `Provider`) accessible from `FrostedSurface`.
2. WHEN `MediaQuery.accessibleNavigation` is true OR `MediaQueryData.disableAnimations` is true, THE provider SHALL emit a `bonus` of 0.10.
3. WHEN long-form body text is rendered inside a glass surface (more than 80 characters), THE caller MAY pass `textHeavy: true` to add a 0.05 bonus.
4. WHEN the `PerformanceProbe`'s rolling p90 frame time exceeds 18 ms, THE provider SHALL emit a 0.10 bonus and reduce blur sigma by 4.
5. THE bonus SHALL clamp final tint α to `[0.0, 0.95]` so the surface never goes fully opaque.

### Requirement 8: Performance probe

**User Story:** As an engineer, I want the app to gracefully degrade visual fidelity on slower devices, so that frame budget is preserved.

#### Acceptance Criteria

1. THE Flutter_App SHALL ship a `PerformanceProbe` widget at the root of `app.dart` that uses `WidgetsBinding.addTimingsCallback` to track p90 frame time over a 5-second sliding window.
2. WHEN the device class detection (Android Skia pre-2020 OR iOS pre-iPhone 11) AND p90 ≥ 18 ms, THE probe SHALL set `glassProfile = 'reduced'`.
3. THE `'reduced'` profile SHALL: drop blur sigma to 16, drop orb C entirely, increase tint α by 0.10.
4. THE probe SHALL emit a Sentry tag `glass_profile=<full|reduced>` per session.

### Requirement 9: Motion catalogue

**User Story:** As a user, I want consistent and meaningful motion across the app.

#### Acceptance Criteria

1. THE Flutter_App SHALL define motion tokens in `lib/core/theme/tokens/motion.dart`:
   - `pressScale = 1.0 → 0.94` over 160 ms `easeOutBack` (down) / 200 ms (up).
   - `tabExpand = 260 ms easeOutCubic`.
   - `pageTransition = 320 ms easeOutCubic` (`SlideTransition` from `Offset(0.05, 0)` + `FadeTransition`).
   - `bottomSheet = 360 ms decelerate`, `dialog = 220 ms easeOut`, `toast = 280 ms easeOutQuart`.
   - `meshOrbs = [9s, 13s, 17s]` linear reverse.
2. WHEN `MediaQuery.disableAnimations` is true, THE Flutter_App SHALL collapse durations to 0 ms but preserve final state transitions.
3. EACH motion token SHALL be referenced via the tokens file — never hardcoded in widget bodies.
4. THE `pageTransition` SHALL be wired into the `GoRouter` page builder once and used by every route.

### Requirement 10: Screen-by-screen visual contract

**User Story:** As a designer/PM, I want every v2 screen specified visually so that implementation matches the concept.

#### Acceptance Criteria

1. **Welcome** — Two glass role-chooser cards (Patient, Doctor) with icons + subtitle; "I already have an account" outlined glass button at the bottom; mesh orbs at 70% opacity.
2. **Method chooser** — Provider buttons stacked: Continue with Google, Continue with Telegram, divider, "Continue with email/phone" outlined glass button. All three are glass pills, brand-coloured per provider.
3. **Patient — Today** — Adherence ring glass card at top; section headers per `time_period`; dose cards tinted by status (subtle warning tint for missed; subtle success tint for taken); a "Missed (N)" callout group.
4. **Patient — Prescriptions** — Glass list grouped by status; create FAB at bottom-right.
5. **Patient — Connections** — Two glass-section panels: My peers, Healthcare providers; tier-count chip in each header.
6. **Patient — Show / Scan QR** — Show: glass-framed QR with role badge, expiry countdown, regenerate pill; Scan: full-screen camera with glass framing overlay (brand-glow corners).
7. **Doctor — Home** — Summary metrics row (3 chips); critical alerts glass card; recent activity glass card; QR icon in app bar.
8. **Doctor — Patients** — Filterable glass list; adherence ring per row; role-aware shape icon for color-blind users.
9. **Doctor — Compose** — Glass timeline of steps (pick patient → template → medications → review); urgent toggle visible.
10. **Settings (both)** — Stacked glass list groups; "Verify your practice" CTA banner inside doctor's settings until verified.
11. **OCR Scan** — Camera with glass framing overlay tuned for paper documents; on capture, glass progress sheet ("Recognising…").
12. **Empty / Loading / Error states** — Centered frosted card with illustration, bilingual hint, and a glass action button.

### Requirement 11: Accessibility on glass

**User Story:** As a user with accessibility needs, I want glass surfaces to remain legible.

#### Acceptance Criteria

1. THE Flutter_App SHALL test text contrast over the worst-case background (full bright orb under the surface) and pass `meets_text_contrast_guideline` (WCAG AA) for both themes.
2. THE Flutter_App SHALL respect `MediaQuery.disableAnimations` for every spring/fade defined in this spec.
3. THE Flutter_App SHALL respect `MediaQuery.textScaler` up to 200% on every screen — surfaces grow vertically; no clipping.
4. WHEN Reduced Transparency is active, glass surfaces SHALL adopt α stops of 0.95 / 0.85 (near-opaque) but retain the shadow.
5. EVERY interactive widget SHALL have a `Semantics` label and tap target ≥ 44 × 44 dp.

### Requirement 12: Migration map (v1 → v2)

**User Story:** As a maintainer, I want the v1 → v2 visual changes documented so that screen-by-screen migration is unambiguous.

#### Acceptance Criteria

1. THE Flutter_App SHALL replace v1 brand `#009DFF` with v2 brand seed `#1A8E5F` via the token system; widget code does not change.
2. THE state-management migration from MVVM + Provider to Riverpod is owned by [`00-overview`](../00-overview/) and `lib/features/<name>/presentation/providers/`; this spec only references it.
3. THE 5-tab static nav (Home / Medication / Scan / Family / Settings) is replaced by the role-aware nav per Requirement 5.
4. THE `FAMILY_MEMBER` role is removed (per [ADDENDUM-001](../ADDENDUM-001-account-and-connection-refinement.md)); peer-Patient connections show under "Connections" using a peer card.
5. WHILE `liquid_glass_widgets` and similar packages exist, v2 SHALL hand-roll glass widgets on top of `BackdropFilter` so the surface area stays small and tokens stay centralised.
