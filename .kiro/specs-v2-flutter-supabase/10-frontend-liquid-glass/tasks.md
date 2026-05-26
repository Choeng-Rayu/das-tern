# Tasks: Frontend — Liquid Glass Visual Layer

> Implementation roadmap for the Liquid Glass visual layer. Depends on `09-design-system-localization` having shipped its tokens and base widgets. Consumed by every feature spec — reference this file when wiring screen-by-screen visuals.
>
> Practical implementation guide for AI agents and humans: [`/home/rayu/das-tern/dastern/AGENTS.md`](../../../dastern/AGENTS.md).

## Phase 1 — Glass tokens (0.5 day)

- [ ] **1.1** Create `lib/core/theme/tokens/glass_tokens.dart` with the `GlassTokens` `ThemeExtension` (per design § 7.3). Implement `copyWith` and `lerp`.
- [ ] **1.2** Register `GlassTokens.light` on `lightTheme()` and `GlassTokens.dark` on `darkTheme()` via `ThemeData(extensions: [...])`.
- [ ] **1.3** Add `motion.dart` token entries: `pressScale`, `tabExpand`, `pageTransition`, `bottomSheet`, `dialog`, `toast`, `meshOrbs`.
- [ ] **1.4** Unit tests: `lerp` interpolates each field correctly mid-transition; `Theme.of(context).extension<GlassTokens>()` resolves at runtime.

## Phase 2 — FrostedSurface + BackdropKey (0.5 day)

- [ ] **2.1** Implement `lib/shared/widgets/effects/frosted_surface.dart` per design § 7.2.
- [ ] **2.2** Implement `lib/shared/widgets/effects/backdrop_keys.dart` exposing named `BackdropKey` instances: `shellHeader`, `contentList`, `modal`, `qrSurface`.
- [ ] **2.3** Add a CI lint or `dart_code_metrics` rule (or a simple grep gate in `flutter-ci.yml`) that fails when any `BackdropFilter` outside `frosted_surface.dart` lacks a `key`.
- [ ] **2.4** Golden tests: `FrostedSurface` in light + dark, with default tint, custom tint, and Reduced-Transparency mode.

## Phase 3 — AppMeshBackground (0.5 day)

- [ ] **3.1** Implement `lib/shared/widgets/glass/app_mesh_background.dart` (`StatefulWidget`) per design § 3.1.
- [ ] **3.2** Two `AnimationController`s (9 s, 13 s); orb C reuses the 13 s controller with phase offset.
- [ ] **3.3** Honor `MediaQuery.disableAnimations`: freeze orbs at start positions when true.
- [ ] **3.4** Dispose controllers in `dispose()`. Property test: `dispose` releases all listeners.
- [ ] **3.5** Golden test: stable frame at `t = 0` for both themes.

## Phase 4 — AdaptiveGlassOpacity + PerformanceProbe (1 day)

- [ ] **4.1** Implement `AdaptiveGlassOpacity` `InheritedWidget` exposing a `bonus` double.
- [ ] **4.2** Wire bonus drivers: `MediaQuery.accessibleNavigation`, `MediaQuery.disableAnimations`, `textHeavy`, performance-probe state.
- [ ] **4.3** Implement `PerformanceProbe` widget that uses `WidgetsBinding.addTimingsCallback` to track p90 frame time over a 5 s sliding window.
- [ ] **4.4** When p90 ≥ 18 ms (or device class is "low"), set `glassProfile = 'reduced'`: drop blur sigma to 16, drop orb C, increase tint α by 0.10.
- [ ] **4.5** Emit Sentry tag `glass_profile=<full|reduced>` per session.

## Phase 5 — Role-aware AppScaffold + glass widget catalog (1.5 days)

- [ ] **5.1** Extend `AppScaffold` (from `09-design-system-localization`) to compose `AppMeshBackground` + `AppGlassHeader` + role-aware nav.
- [ ] **5.2** Implement `AppGlassHeader` (`PreferredSizeWidget`) with title, optional subtitle, leading and trailing slots.
- [ ] **5.3** Implement `AppGlassNavBar` floating pill — selected pill expands with label (`AnimatedContainer` 260 ms `easeOutCubic`).
- [ ] **5.4** Patient nav: `[Today, Prescriptions, QR-FAB (centered), Connections, Settings]`.
- [ ] **5.5** Doctor nav: `[Home, Patients, Compose, Settings]` + QR icon in the app bar trailing area.
- [ ] **5.6** Implement `AppGlassFab` (round glass action button) used for the patient QR FAB.
- [ ] **5.7** Implement `AppGlassCard` (with `onTap` ripple), `AppGlassChip` (pill radius), `AppGlassDialog`, `AppGlassBottomSheet`.
- [ ] **5.8** Auth shell variant: hide bottom nav, dial mesh to 70% opacity, slow orbs to 60% speed.

## Phase 6 — Motion wiring (0.5 day)

- [ ] **6.1** Wire `pageTransition` token into the `GoRouter` page builder (replace defaults).
- [ ] **6.2** Wire `pressScale` into `AppButton` and `AppGlassFab` (existing buttons in 09 may already use it; verify).
- [ ] **6.3** Wire `tabExpand` into `AppGlassNavBar`.
- [ ] **6.4** All durations / curves come from `motion.dart` tokens — no inline magic numbers.

## Phase 7 — Screen integrations (per feature, ongoing)

> Each feature spec owns its screen tasks. This phase is a checklist for each feature owner.

- [ ] **7.1** Welcome + Method chooser (in `02-authentication`) wrapped in `AppScaffold` (auth-shell variant) — two glass role chooser cards, glass provider buttons.
- [ ] **7.2** Patient Today (in `04-reminder-adherence`) — adherence ring glass card, dose cards tinted by status, "Missed (N)" callout.
- [ ] **7.3** Patient Prescriptions (in `03-prescription-medication`) — glass list grouped by status; create FAB.
- [ ] **7.4** Patient Connections (in `05-family-doctor-connections`) — two glass-section panels; QR center FAB action sheet.
- [ ] **7.5** Show / Scan QR (in `05`) — glass-framed QR; full-screen camera with brand-glow framing overlay.
- [ ] **7.6** Doctor Home + Patients + Compose (in `06-doctor-dashboard`) — summary metric chips, critical alerts glass card, filterable list, glass timeline form.
- [ ] **7.7** OCR review (in `07-ocr-prescription-scanning`) — image preview pinned + glass cards per medication candidate.
- [ ] **7.8** Settings (per role) — stacked glass list groups; "Verify your practice" CTA banner inside doctor's settings.
- [ ] **7.9** Empty / loading / error states everywhere — `EmptyState` / `LoadingState` / `ErrorState` widgets render inside frosted glass cards.

## Phase 8 — Tests (1 day)

- [ ] **8.1** Golden tests: each glass widget × {light, dark} × {km, en} = 16 goldens per widget.
- [ ] **8.2** Contrast tests over the worst-case orb position using `meets_text_contrast_guideline`.
- [ ] **8.3** Motion respect test: `MediaQuery.disableAnimations = true` collapses durations to 0 ms but final state matches expected.
- [ ] **8.4** Performance benchmark on a "low" tier emulator: 5 cards + header + nav + mesh, p90 frame time ≤ 18 ms.
- [ ] **8.5** Reduced Transparency test: tint α stops increase to 0.95/0.85; shadow retained.
- [ ] **8.6** BackdropKey coalescing test: a screen with 5 glass surfaces sharing one key triggers exactly 1 blur shader pass (verify via `widgetTester.binding.platformDispatcher`'s render tree).

## Phase 9 — Sign-off

- [ ] **9.1** Demo: side-by-side light / dark of every primary screen.
- [ ] **9.2** Demo: airplane-mode patient app — glass surfaces and mesh continue to render.
- [ ] **9.3** Demo: enable Reduced Transparency in the OS — surfaces become near-opaque, app remains usable.
- [ ] **9.4** Demo: simulate slow device — `glass_profile = 'reduced'` kicks in, blur drops, orb C disappears.
- [ ] **9.5** Designer + accessibility reviewer sign-off.
