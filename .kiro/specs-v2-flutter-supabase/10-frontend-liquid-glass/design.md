# Design: Frontend — Liquid Glass Visual Layer

> **Read order:** Skim [`README.md`](../README.md) and [`00-overview/design.md`](../00-overview/design.md) first for the architecture, then this document for the visual layer that wraps it.
> Implementation guide for AI agents and humans lives at [`/home/rayu/das-tern/dastern/AGENTS.md`](../../../dastern/AGENTS.md).

---

## 1. North star

Das Tern v2 is a Flutter app for patients and doctors managing medication. We rebuild the visual language on Apple's iOS 26 **Liquid Glass** vocabulary so the app feels alive, calm, and trustworthy — even when the user is anxious about a missed dose.

Three design promises drive every decision:

1. **Glass that breathes.** Surfaces blur the content behind them, never themselves. A faint specular highlight on top, a soft shadow underneath. The background lives — it is a slow mesh of three brand-tinted orbs.
2. **Motion with intent.** Press → 0.94 scale spring; tab switch → label expands with `easeOutCubic`; page transition → 320 ms slide+fade. No motion that doesn't communicate state.
3. **Tokens, not opinions.** Every color, radius, gap, blur, and duration is a named token. Screens never carry inline values. When marketing changes the brand, one file moves; the app follows.

## 2. Relationship to other v2 specs

| Concern | Owner spec | This document's role |
|---|---|---|
| Color/typography/spacing tokens | [`09-design-system-localization`](../09-design-system-localization/) | **Inherits** them. The Liquid Glass surfaces are styled exclusively via these tokens. |
| Reusable widgets (`AppButton`, `AppCard`, `AppTextField`, …) | `09-design-system-localization` | **Extends** them with glass-specific variants (`AppGlassPanel`, `FrostedSurface`, `AppMeshBackground`, glass tab bar, glass header). |
| Routing / state / data | All v2 feature specs (02 → 08) | **Consumes** them. This concept does not redefine flows; it dresses them in glass. |
| Bilingual + light/dark | `09-design-system-localization` | **Honours** them. Khmer and English; both themes; no Khmer-blocking serifs. |

A reader who only opens this folder should land on `requirements.md` first, then this `design.md`, then the v2 README.

## 3. The visual primitives

### 3.1 The mesh background

A persistent, full-screen background composed of:

- A **base** filled with `colorScheme.surface` (light) or `colorScheme.surfaceContainerLowest` (dark — tuned to a warm near-black `#0B1410`).
- Three **radial-gradient orbs**, each `RadialGradient` painted via `CustomPaint`:
  - Orb A — `brandSeed` (#1A8E5F, the v2 green) at 30% opacity, slow horizontal drift (9 s reverse loop).
  - Orb B — `brandSeed` darker (`#106B47`) at 22% opacity, vertical drift (13 s reverse loop).
  - Orb C — `brandSeed` lighter (`#5DBC92`) at 16% opacity, diagonal drift (17 s reverse loop).
- Two `AnimationController`s drive A and B; orb C reuses B's controller with a phase offset to keep memory low.
- All controllers `repeat(reverse: true)` and respect `MediaQuery.disableAnimations`.

The mesh is in every screen by default through `AppScaffold`. The user is never on a "blank" surface.

### 3.2 Glass surfaces

Every elevated surface is a `Glass`-flavoured composite:

```
Opacity → DecoratedBox(softShadow) → ClipRRect(radius)
       → BackdropFilter(blur)
       → DecoratedBox(linearGradient + specularBorder)
       → Padding(child)
```

Tokens (defined in `09-design-system-localization` and surfaced here as the canonical glass values):

| Property | Token | Value (light) | Value (dark) |
|---|---|---|---|
| Blur radius | `glass.blurRadius` | 24 | 28 |
| Surface tint α (top-left) | `glass.tintHigh` | 0.18 | 0.16 |
| Surface tint α (bottom-right) | `glass.tintLow` | 0.06 | 0.04 |
| Specular border color | `glass.border` | `surface @ 35%` | `surface @ 28%` |
| Specular border width | `glass.borderWidth` | 0.8 | 0.8 |
| Shadow color | `glass.shadow` | `black @ 12%` | `black @ 35%` |
| Shadow blur | `glass.shadowBlur` | 24 | 32 |
| Shadow offset | `glass.shadowOffset` | (0, 8) | (0, 8) |
| Default radius | `glass.radius` | 20 | 20 |
| Header radius | `glass.radiusHeader` | 28 (bottom only) | 28 |
| Pill radius | `glass.radiusPill` | 100 | 100 |

Tints are **always** applied via a `LinearGradient` between two color stops, not a flat fill — this is what gives the surface its "wet" look.

### 3.3 Backdrop coalescing

Flutter 3.13+ exposes `BackdropKey`. We **share one key** across all glass surfaces in a single screen so the engine performs the blur once. This is critical: a screen with 5 cards, a header, and a tab bar would otherwise issue 7 separate blur passes.

```dart
final _kHomeBackdropKey = BackdropKey();

BackdropFilter(
  key: _kHomeBackdropKey, // shared
  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
  child: ...,
);
```

Impeller is the preferred renderer (default on iOS; enable on Android). On older Android builds where Skia is in use, we drop the global blur sigma to 16 to keep frame budget.

### 3.4 Motion catalogue

| Interaction | Duration | Curve | Notes |
|---|---|---|---|
| Button press scale | 160 ms down / 200 ms up | `easeOutBack` | Scale 1.0 → 0.94 → 1.0 |
| Tab selection expand | 260 ms | `easeOutCubic` | Width tween, label `AnimatedOpacity` |
| Page transition | 320 ms | `easeOutCubic` | `SlideTransition` from `Offset(0.05, 0.0)` + `FadeTransition` |
| Bottom sheet | 360 ms | `decelerate` | Glass surface slides up |
| Dialog | 220 ms | `easeOut` | Scale 0.95 → 1.0 + fade |
| Toast / banner | 280 ms | `easeOutQuart` | Slide-down + fade |
| Mesh orbs | 9 / 13 / 17 s | linear, reverse | Continuous |
| Pull-to-refresh | 280 ms | `easeOut` | Glass spinner inside a frosted pill |

All motion respects `MediaQuery.disableAnimations`; when set, we collapse durations to 0 ms but keep state transitions.

### 3.5 Color palette

We inherit the v2 brand seed (`#1A8E5F` Das Tern green) from `09-design-system-localization`. The Liquid Glass derivative palette is:

| Token | Light | Dark | Usage |
|---|---|---|---|
| `brand.seed` | `#1A8E5F` | `#1A8E5F` | Primary actions, accent. |
| `brand.dark` | `#106B47` | `#106B47` | Mesh orb B. |
| `brand.light` | `#5DBC92` | `#5DBC92` | Mesh orb C, success accents. |
| `surface.base` | `#FCFAF6` (warm off-white) | `#0B1410` | Mesh base. |
| `surface.glass` | white @ 12% | white @ 6% | Glass fill. |
| `text.primary` | `#0F1A14` | `#F2F7F4` | Body and titles. |
| `text.secondary` | `#475A52` | `#9FB1A9` | Captions, helper text. |
| `state.success` | `#1FAA66` | `#5DD49A` | Adherence ≥ 90%, confirmations. |
| `state.warning` | `#F1A93A` | `#F9C56F` | Adherence 70–89%, soft alerts. |
| `state.danger` | `#D64545` | `#F08585` | Missed doses, destructive actions. |
| `state.info` | `#3A7BD6` | `#7CAEEA` | Informational chips. |

The palette is intentionally calm and warm — medical apps that lean cool-blue feel clinical and cold; we choose green-lit warm surfaces because patients are dealing with their own bodies, not specs in a hospital.

### 3.6 Typography

From `09-design-system-localization`:
- **Khmer-first** font stack — Battambang for Khmer; Inter (or Plus Jakarta Sans) for Latin. Khmer NEVER falls back to a generic font.
- 7-step Material 3 type scale, applied verbatim. We do not invent display sizes here.
- Numerals on dose-tracking screens stay Latin (Arabic numerals) for clarity even in Khmer locale, after UX review.

Glass surfaces increase type contrast slightly: titles use `FontWeight.w600` (vs `w500` on opaque surfaces) so they read crisply over blurred content.

## 4. Component catalogue (glass-flavoured)

These are the v2 reusable widgets that get glass treatment. They live under `lib/shared/widgets/effects/` and `lib/shared/widgets/glass/`.

| Widget | Built on | Notes |
|---|---|---|
| `FrostedSurface` | `BackdropFilter` + `DecoratedBox` | The atomic glass primitive — every other glass widget composes this. |
| `AppMeshBackground` | `Stack` + `CustomPaint` + `AnimationController × 2` | Always at the root of `AppScaffold`. |
| `AppScaffold` | `Scaffold` + `AppMeshBackground` + `AppGlassHeader` + `AppGlassNavBar` | Single screen wrapper. |
| `AppGlassHeader` | `FrostedSurface` + `PreferredSizeWidget` | iOS-style large title + subtitle slot, blurs content behind on scroll. |
| `AppGlassNavBar` | `FrostedSurface` + `Row` of animated tabs | Floating pill at bottom; selected tab expands and shows label. |
| `AppGlassButton` | Wraps `AppButton` (from 09) | Adds glass tint on filled variant; spring scale animation. |
| `AppGlassCard` | `FrostedSurface` + `InkWell` | List items, dose cards, connection cards. |
| `AppGlassChip` | `FrostedSurface` (pill radius) | Status badges, filter chips. |
| `AppGlassFab` | `FrostedSurface` (round) + `BackdropFilter` | The bottom-right FAB for quick actions. |
| `AppGlassDialog` | `FrostedSurface` + `Dialog` | Confirmation dialogs. |
| `AppGlassBottomSheet` | `FrostedSurface` + `showModalBottomSheet` | Approval sheets, action menus. |

Each widget passes through to its v2 base widget; the only override is the surface treatment. This way features keep using `AppButton` / `AppCard` from the design-system spec, and the glass aesthetic is layered on top.

### 4.1 Adaptive opacity

Glass surfaces increase opacity automatically when:
- Long-form text is rendered inside (legibility),
- The user has Reduced Transparency turned on at the OS level,
- The estimated frame-time exceeds 18 ms (graceful degradation).

This is implemented via a single `AdaptiveGlassOpacity` provider that adjusts `glass.tintHigh` and `glass.tintLow` upward by 0.10 in those cases.

## 5. Navigation shell — role-aware

The bottom navigation differs per role. Each tab is a glass pill that expands with its label when selected; unselected tabs are icon-only.

### 5.1 Patient bottom nav

```
┌─────────────────────────────────────────────────────────┐
│  ●  Today    ◐  Prescriptions    ●  Connections    ⚙  │
└─────────────────────────────────────────────────────────┘
                           ▲
                    Selected pill expands
```

Five entries, with the **center FAB** for QR (Show / Scan):

| # | Tab | Icon | Route | Source spec |
|---|---|---|---|---|
| 1 | Today | `medical_information` | `/patient/home` | 04-reminder-adherence |
| 2 | Prescriptions | `description` | `/patient/prescriptions` | 03-prescription-medication |
| 3 | **QR** (centered FAB, glass) | `qr_code_2` | Action sheet: "Show my QR" / "Scan QR" | 05-family-doctor-connections |
| 4 | Connections | `groups` | `/patient/connections` | 05-family-doctor-connections |
| 5 | Settings | `settings` | `/patient/settings` | various |

### 5.2 Doctor bottom nav

```
┌─────────────────────────────────────────────────────────┐
│  ●  Home    ◐  Patients    ⊕  Compose    ⚙          │
└─────────────────────────────────────────────────────────┘
                          ▲
                   Selected pill expands
```

Four tabs (no Connections tab — doctors get patient list), plus the same QR action anchored to the AppBar trailing area:

| # | Tab | Icon | Route | Source spec |
|---|---|---|---|---|
| 1 | Home | `dashboard` | `/doctor/home` | 06-doctor-dashboard |
| 2 | Patients | `people` | `/doctor/patients` | 06-doctor-dashboard |
| 3 | Compose | `add_circle` | `/doctor/compose` (new prescription picker) | 03-prescription-medication |
| 4 | Settings | `settings` | `/doctor/settings` | various |

The QR action lives as a glass icon button in the doctor's top bar (since they tend to scan a patient's QR while talking face-to-face, the gesture is from the top of the screen).

### 5.3 Auth shell (no bottom nav)

The Welcome → Method chooser → Sign-up/Sign-in flow uses a clean stack with the glass header but no bottom nav. The mesh background is dialled down to 70% opacity and the orbs slow to 60% of their normal speed — the tone is contemplative.

## 6. Screen-by-screen redesign

Every screen in the v2 feature specs gets a glass treatment. Below are the canonical layouts. Screens reference v2 specs; this section is purely visual.

### 6.1 Welcome

```
┌──────────────────────────────────────────────────────────┐
│        ⌐ KH | EN ⌐                              ⚙        │
│                                                          │
│                ┌──────────────────────┐                  │
│                │   Das Tern logo       │                  │
│                └──────────────────────┘                  │
│                                                          │
│              Welcome to Das Tern                         │
│                                                          │
│   ╭──────────────────────────────────╮                   │
│   │  ◯  Sign up as Patient        ›  │ ← glass card     │
│   │     Track meds and connect    ›  │                   │
│   ╰──────────────────────────────────╯                   │
│   ╭──────────────────────────────────╮                   │
│   │  ⚕  Sign up as Doctor         ›  │ ← glass card     │
│   │     Care for connected patients  │                   │
│   ╰──────────────────────────────────╯                   │
│                                                          │
│              I already have an account                   │
└──────────────────────────────────────────────────────────┘
```

Glass cards have specular borders + soft shadow. Tap → 0.94 spring → glass card pulses tint slightly → routes to method chooser.

### 6.2 Method chooser

Three glass options stacked: Continue with Google, Continue with Telegram, divider, "Continue with email/phone" outlined glass button. Each provider button keeps its brand colour but renders inside a frosted pill.

### 6.3 Patient — Today (home)

```
┌──────────────────────────────────────────────────────────┐
│  Today                                       •  Avatar   │
│  Tuesday · 21 Apr                                        │
├──────────────────────────────────────────────────────────┤
│   ╭──── Adherence ring (frosted glass card) ───────╮     │
│   │     ◐ 86%  this week                            │     │
│   │  ▁▃▅▇▅▃▆ sparkline 7d                          │     │
│   ╰──────────────────────────────────────────────────╯     │
│                                                          │
│   Morning  ── glass section header                       │
│   ╭──────────────────────────────────────────────────╮   │
│   │  💊  Amoxicillin · 500mg · 08:00      [ Take ▶ ]│   │
│   │  Status: Due in 12m                             │   │
│   ╰──────────────────────────────────────────────────╯   │
│                                                          │
│   Afternoon                                              │
│   ╭──────────────────────────────────────────────────╮   │
│   │  💊  Metformin · 850mg · 13:00       [✓ Taken ]│   │
│   ╰──────────────────────────────────────────────────╯   │
│                                                          │
│   Missed (1)  • peer alert sent                          │
│   ╭──────────────────────────────────────────────────╮   │
│   │  ⚠️  Vitamin D · 06:30                          │   │
│   │     [ Mark taken late ]   [ Skip ]              │   │
│   ╰──────────────────────────────────────────────────╯   │
└────────────────── ●  ◐  ⊕  ●  ⚙ ────────────────────────┘
```

The adherence ring is a glass card with the percentage in display-large + a 7-day sparkline. The dose cards are glass + colour-tinted by status (subtle warning tint for missed; subtle success tint for taken).

### 6.4 Patient — Prescriptions

A glass-section list grouped by status (Active, Paused, Inactive). The "Create" FAB at bottom-right is a glass round button. Tapping a row opens the detail sheet.

### 6.5 Patient — Connections

Two glass-section panels stacked:
- **My peers** (Patient↔Patient): each card shows avatar, name, mute toggle, last activity, "View" CTA.
- **Healthcare providers** (Doctor↔Patient): each card shows avatar (with Verified badge if applicable), specialty, permission chip, "Manage" CTA.

The center QR FAB opens an action sheet with two glass options: "Show my QR" → `ShowQrPage`, "Scan QR" → `ScanQrPage`.

### 6.6 Patient — Show / Scan QR

`ShowQrPage` renders the QR within a frosted glass frame, the user's name + role badge above, expiry countdown below, and a glass "Regenerate" pill button. The mesh orbs are slightly amplified here (35/27/20%) to make the QR pop.

`ScanQrPage` is a fullscreen camera with a glass framing overlay (rounded square cutout with specular border, corners glow with `brand.seed`). On detection, a glass progress sheet rises from the bottom showing "Connecting…".

### 6.7 Doctor — Home

```
┌──────────────────────────────────────────────────────────┐
│  Welcome, Dr. Sok                            [QR ▾]     │
│  Tuesday · 21 Apr                                        │
├──────────────────────────────────────────────────────────┤
│   3 patients     1 below 70%      2 alerts today         │
│   ╭──── Critical alerts (frosted) ────────────────╮      │
│   │ 🔴 Sopheaktra missed 3 doses · 7d adh 64%   ›│      │
│   ╰─────────────────────────────────────────────────╯      │
│   ╭──── Recent activity ────────────────────────╮         │
│   │ ✓ Bopha confirmed prescription · 2h ago     │         │
│   │ ✓ Dara took 12:00 dose · 5m ago             │         │
│   ╰─────────────────────────────────────────────────╯      │
└────────────────── ●  ●  ⊕  ⚙ ──────────────────────────┘
```

### 6.8 Doctor — Patients

A filterable glass list. Each row: avatar, name, age, adherence ring (small), last activity, role-aware shape icon (color + ring shape) for color-blind users. Tap → patient detail.

### 6.9 Doctor — Compose

A glass guided form: pick patient (only connected, ALLOWED) → pick template or start blank → add medications → review urgent toggle → submit. The form is laid out as a glass timeline with each step a glass step indicator at the top.

### 6.10 Settings (both roles)

Stacked glass list groups: Profile, Preferences (Language, Theme, Timezone), Notifications (per-medication toggles), Subscription (tier card with progress bars), Account (Verify your practice for doctors, Delete account, Export data, Sign out).

### 6.11 OCR scan flow (patient)

`ScanPrescriptionPage` opens the camera with a glass framing overlay tuned for paper documents (rounded rectangle, slightly larger than the QR overlay). Capture → glass progress sheet ("Recognising…") → `OcrReviewPage` (glass cards per medication candidate, image preview pinned to top half on phones, side-by-side on tablets).

### 6.12 Empty / loading / error states

All three states are full-screen glass cards centred:
- **Empty**: an SVG illustration above + bilingual hint + a glass primary button.
- **Loading**: the Mesh background continues to animate behind a centred frosted spinner.
- **Error**: a frosted card with a soft danger tint and a "Retry" glass button.

## 7. Implementation guide

### 7.1 Folder structure

```
lib/shared/widgets/
├── effects/
│   ├── frosted_surface.dart           # atomic glass primitive
│   ├── adaptive_glass_opacity.dart
│   └── backdrop_keys.dart             # named BackdropKey instances
├── glass/
│   ├── app_mesh_background.dart
│   ├── app_glass_header.dart
│   ├── app_glass_nav_bar.dart
│   ├── app_glass_card.dart
│   ├── app_glass_chip.dart
│   ├── app_glass_fab.dart
│   ├── app_glass_dialog.dart
│   ├── app_glass_bottom_sheet.dart
│   └── app_scaffold.dart              # composes mesh + header + nav
└── (existing 09-design-system widgets)
```

### 7.2 FrostedSurface reference

```dart
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
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final Color? tint;
  final double? blurSigma;
  final BackdropKey? backdropKey;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GlassTokens>()!;
    final actualTint = tint ?? Theme.of(context).colorScheme.surface;
    final adapt = AdaptiveGlassOpacity.of(context);
    final hi = (tokens.tintHigh + adapt.bonus).clamp(0.0, 1.0);
    final lo = (tokens.tintLow  + adapt.bonus).clamp(0.0, 1.0);
    final sigma = blurSigma ?? tokens.blurRadius;

    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [BoxShadow(
            color: tokens.shadowColor,
            blurRadius: tokens.shadowBlur,
            offset: tokens.shadowOffset,
          )],
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
                  colors: [actualTint.withOpacity(hi),
                           actualTint.withOpacity(lo)],
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

### 7.3 GlassTokens extension

```dart
@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.blurRadius,
    required this.tintHigh,
    required this.tintLow,
    required this.borderColor,
    required this.borderWidth,
    required this.shadowColor,
    required this.shadowBlur,
    required this.shadowOffset,
  });
  final double blurRadius;
  final double tintHigh;
  final double tintLow;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  static const light = GlassTokens(
    blurRadius: 24, tintHigh: 0.18, tintLow: 0.06,
    borderColor: Color(0x59FFFFFF), borderWidth: 0.8,
    shadowColor: Color(0x1F000000), shadowBlur: 24,
    shadowOffset: Offset(0, 8),
  );
  static const dark = GlassTokens(
    blurRadius: 28, tintHigh: 0.16, tintLow: 0.04,
    borderColor: Color(0x47FFFFFF), borderWidth: 0.8,
    shadowColor: Color(0x59000000), shadowBlur: 32,
    shadowOffset: Offset(0, 8),
  );
  // copyWith / lerp implementations omitted for brevity
}
```

Both `lightTheme()` and `darkTheme()` in `lib/core/theme/` register their respective `GlassTokens` via `extensions: [GlassTokens.light]` / `extensions: [GlassTokens.dark]`.

### 7.4 BackdropKey strategy

- `BackdropKeys.shellHeader` — header + nav bar share one key per route.
- `BackdropKeys.contentList` — list cards within the same scrollable share a second key.
- `BackdropKeys.modal` — bottom sheets / dialogs share a third key while presented.

A custom lint rule in CI flags any `BackdropFilter` without a `key` outside `frosted_surface.dart` so we never drift back into the multi-pass state.

### 7.5 Performance budget

| Device class | Frame target | Blur sigma | Mesh orbs |
|---|---|---|---|
| iPhone 12+, Pixel 7+ | 60 fps | 24/28 | 3 |
| iPhone 11, Pixel 5–6 | 60 fps | 20/22 | 3 |
| Pre-2020 Android (Skia) | 50 fps | 16 | 2 (orb C dropped) |

A `PerformanceProbe` wraps the app shell and downgrades the global glass profile if the rolling 90th-percentile frame time crosses 18 ms. The probe is silent in release; it logs to Sentry as a tag for analytics.

### 7.6 Accessibility

- All glass surfaces meet WCAG AA contrast for the **text on top of them**. We test with the worst-case background (full bright orb directly under the surface) using the `meets_text_contrast_guideline` matcher.
- `MediaQuery.disableAnimations` collapses spring/fade durations to 0 ms.
- `MediaQuery.textScaler` up to 200% — surfaces auto-grow vertically; no clipping.
- Reduced Transparency: glass tint stops jump to 0.95/0.85 (almost opaque), shadow stays.
- Every interactive widget has a `Semantics` label and meets the 44×44 dp tap target.

## 8. Migration from v1 visual

| v1 RxCam / iOS26 v1 | v2 Liquid Glass |
|---|---|
| `AppColors.primary = #009DFF` (cyan-blue) | `brand.seed = #1A8E5F` (Das Tern green). Existing screens swap palette via tokens — no widget code changes. |
| MVVM + Provider | Riverpod + Drift. ViewModels become Riverpod `Notifier`s; `AppRouter` is replaced by `GoRouter` (per v2 architecture). |
| 5-tab nav: Home / Med / Scan / Family / Settings | Role-aware nav per § 5. The "Family" tab is gone (peers live under "Connections"); QR moves to a center FAB. |
| FAMILY_MEMBER role | Role removed. "Family" is a peer-Patient connection. |
| Hardcoded brand cyan in glass tints | Glass tints derive from `colorScheme.surface` so they always match light/dark. |
| `liquid_glass_widgets` package proposal | We hand-roll on top of `BackdropFilter` to keep the surface area small and tokens centralised. |

## 9. Out of scope

- Custom Metal/MSL shaders. iOS 26's true Liquid Glass uses Metal shaders for the wet/specular look; Flutter's `BackdropFilter` plus a tinted gradient is a faithful approximation, not a 1:1 render. We accept the visual gap.
- Live wallpaper-aware tinting (would require platform channels). Mesh orbs are sufficient.
- Watch / wearable companion. Out of v2 MVP; the design tokens still apply when added.
