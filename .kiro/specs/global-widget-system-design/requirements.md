# Requirements Document

## Introduction

This spec defines the **visual design** of the RxCam global widget system — the set of reusable
Flutter widgets that every screen in the app must use. RxCam is a prescription and medication
management app for Cambodian healthcare users built with the iOS 26 Liquid Glass aesthetic.

Primary brand colour: `#009DFF`. All widgets must support both **light mode** and **dark mode**
through the `AppColors` token system. No hardcoded colour values are permitted anywhere.

This spec is focused exclusively on visual design, theming, and widget-level behaviour. Architecture,
routing, and data layer concerns are covered in the `ios26-liquid-glass-refactor` spec.

---

## Glossary

- **App**: The RxCam Flutter application.
- **AppColors**: The design token class defining all colour constants for both light and dark modes.
- **AppSpacing**: The design token class defining spacing scale and superellipse border-radius constants.
- **AppTextStyles**: The design token class defining the full typography scale.
- **AppTheme**: The class that assembles `ThemeData` for both light and dark modes.
- **AppScaffold**: The global screen-wrapper widget composing mesh background, header, body, and bottom nav.
- **AppHeader**: The iOS 26 glass navigation bar at the top of every screen.
- **AppBottomNav**: The floating glass tab bar with five navigation tabs.
- **AppButton**: The glass button widget with four variants.
- **AppGlassPanel**: The foundation frosted-glass surface widget used by all glass widgets.
- **AppCard**: A tappable glass card wrapping AppGlassPanel.
- **AppTextField**: The glass input field widget.
- **AppBadge**: A status pill badge with five variants.
- **AppAvatar**: A user avatar with a glass ring border.
- **AppLoadingView**: Full-screen loading state widget.
- **AppErrorView**: Full-screen error state widget.
- **AppEmptyView**: Full-screen empty state widget.
- **Liquid Glass**: The iOS 26 visual design language using BackdropFilter blur, specular borders, spring physics, and animated mesh backgrounds.
- **Design Token**: A named constant in `core/theme/` that must be referenced instead of hardcoded values.
- **Light Mode**: The `Brightness.light` theme variant with white/light-grey backgrounds and dark text.
- **Dark Mode**: The `Brightness.dark` theme variant with deep navy backgrounds and white text.
- **Superellipse**: A rounded rectangle shape with a continuous curvature (squircle), used for all card and button shapes.
- **Mesh Background**: The animated three-orb radial-gradient background rendered behind all screen content.
- **Glass Surface**: A frosted, semi-transparent layer rendered using `BackdropFilter` blur.
- **Specular Border**: A thin bright top-edge border that simulates light reflection on glass.
- **Touch Target**: The minimum tappable area for an interactive element (44×44 dp per accessibility guidelines).

---

## Requirements

### Requirement 1: Design Token System — AppColors (Light & Dark)

**User Story:** As a developer, I want all colours defined as named tokens with explicit light-mode
and dark-mode values, so that every widget automatically adapts to the active theme without any
per-widget conditional logic.

#### Acceptance Criteria

1. THE AppColors SHALL define a `primary` token as `#009DFF` used for brand accents, active states, and focus borders in both modes.
2. THE AppColors SHALL define dark-mode mesh background tokens: `meshDeep` as `#050A14` and `meshMid` as `#0A1628`.
3. THE AppColors SHALL define light-mode background tokens: `lightBackground` as `#F2F2F7` and `lightSurface` as `#FFFFFF`.
4. THE AppColors SHALL define dark-mode glass surface tokens: `glassWhiteDark` as white at 10% opacity (`#1AFFFFFF`) and `glassBorderDark` as white at 20% opacity (`#33FFFFFF`).
5. THE AppColors SHALL define light-mode glass surface tokens: `glassWhiteLight` as white at 60% opacity (`#99FFFFFF`) and `glassBorderLight` as black at 12% opacity (`#1F000000`).
6. THE AppColors SHALL define dark-mode text tokens: `textPrimaryDark` as `#FFFFFF`, `textSecondaryDark` as white at 70% (`#B3FFFFFF`), `textTertiaryDark` as white at 40% (`#66FFFFFF`).
7. THE AppColors SHALL define light-mode text tokens: `textPrimaryLight` as `#0D0D0D`, `textSecondaryLight` as `#3C3C43` at 60% opacity (`#993C3C43`), `textTertiaryLight` as `#3C3C43` at 30% opacity (`#4D3C3C43`).
8. THE AppColors SHALL define semantic colour tokens shared across both modes: `success` as `#34C759`, `danger` as `#FF3B30`, `warning` as `#FF9500`, `info` as `#5AC8FA`.
9. THE AppColors SHALL define glass tint tokens: `glassPrimary` as `#009DFF` at 10% opacity (`#1A009DFF`) and `glassDanger` as `#FF3B30` at 10% opacity (`#1AFF3B30`).
10. THE AppColors SHALL define a `glassShadow` token as black at 25% opacity (`#40000000`) for floating shadows in dark mode, and `glassShadowLight` as black at 10% opacity (`#1A000000`) for light mode.
11. WHEN `flutter analyze` is executed, THE App SHALL report zero inline `Color(0x...)` or `Colors.` references in any file under `lib/ui/` or `lib/core/widgets/`.


### Requirement 2: Design Token System — AppSpacing and AppTextStyles

**User Story:** As a developer, I want spacing, radius, and typography defined as tokens, so that
all widgets share a consistent visual rhythm and I never hardcode a pixel value.

#### Acceptance Criteria

1. THE AppSpacing SHALL define a spacing scale in dp: `xs=4`, `sm=8`, `md=16`, `lg=24`, `xl=32`, `xxl=48`.
2. THE AppSpacing SHALL define superellipse border-radius tokens: `radiusSm=12`, `radiusMd=20`, `radiusLg=28`, `radiusXl=36`, `radiusFull=100`.
3. THE AppTextStyles SHALL define a typography scale with at minimum: `displayLarge` (34/700), `displayMedium` (28/600), `headlineLarge` (22/600), `headlineMedium` (18/600), `bodyLarge` (17/400), `bodyMedium` (15/400), `bodySmall` (13/400), `labelLarge` (15/600), `labelSmall` (11/600).
4. THE AppTextStyles SHALL reference only `AppColors` tokens for text colours — no inline `Color(...)` values.
5. THE AppTextStyles SHALL provide a `resolve(BuildContext)` method or equivalent that returns the correct colour variant (light or dark) based on the active `ThemeData.brightness`.


### Requirement 3: AppTheme — Light and Dark ThemeData

**User Story:** As a developer, I want both a light and a dark `ThemeData` assembled from tokens,
so that the app switches modes correctly when the device theme changes.

#### Acceptance Criteria

1. THE AppTheme SHALL expose a `dark` getter returning a `ThemeData` with `brightness: Brightness.dark`, `scaffoldBackgroundColor: AppColors.meshDeep`, and a transparent `AppBarTheme`.
2. THE AppTheme SHALL expose a `light` getter returning a `ThemeData` with `brightness: Brightness.light`, `scaffoldBackgroundColor: AppColors.lightBackground`, and a transparent `AppBarTheme`.
3. WHEN the device is in dark mode, THE App SHALL use `AppTheme.dark` and all widgets SHALL render using dark-mode tokens.
4. WHEN the device is in light mode, THE App SHALL use `AppTheme.light` and all widgets SHALL render using light-mode tokens.
5. THE AppTheme SHALL configure `colorScheme.primary` to `AppColors.primary` in both themes.
6. THE AppTheme SHALL configure `textTheme` entries mapped from `AppTextStyles` in both themes.


### Requirement 4: AppGlassPanel — Frosted Glass Surface

**User Story:** As a developer, I want a single reusable glass surface widget that handles blur,
gradient, border, and shadow, so that I never manually compose BackdropFilter in individual widgets.

#### Acceptance Criteria

1. THE AppGlassPanel SHALL apply `BackdropFilter` with `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` as the frosted glass layer.
2. THE AppGlassPanel SHALL render a specular top-edge border using the active `glassBorder` token at 0.8 logical pixels width.
3. THE AppGlassPanel SHALL render a floating shadow using the active `glassShadow` token with `blurRadius: 32` and `offset: Offset(0, 8)`.
4. WHEN in dark mode, THE AppGlassPanel SHALL use `AppColors.glassWhiteDark` as the default fill gradient.
5. WHEN in light mode, THE AppGlassPanel SHALL use `AppColors.glassWhiteLight` as the default fill gradient, producing a brighter, more opaque frosted surface.
6. THE AppGlassPanel SHALL accept an optional `tint` colour parameter that overrides the default fill gradient.
7. THE AppGlassPanel SHALL accept `borderRadius`, `blurRadius`, `opacity`, and `padding` parameters.
8. THE AppGlassPanel SHALL clip its content to the specified `borderRadius` using `ClipRRect`.
9. FOR ALL valid `AppGlassPanel` configurations, the widget tree SHALL contain exactly one `BackdropFilter` node (invariant — no double-blur stacking).
10. THE AppGlassPanel SHALL have a minimum touch target of 44×44 dp when used as an interactive surface.


### Requirement 5: AppMeshBackground — Animated Background

**User Story:** As a user, I want a living animated background on every screen, so that the app
feels dynamic rather than static.

#### Acceptance Criteria

1. WHEN in dark mode, THE AppMeshBackground SHALL render `AppColors.meshDeep` (`#050A14`) as the base background colour.
2. WHEN in light mode, THE AppMeshBackground SHALL render `AppColors.lightBackground` (`#F2F2F7`) as the base background colour with orb opacities reduced to 0.12, 0.08, and 0.06 respectively to keep the light surface subtle.
3. THE AppMeshBackground SHALL animate three radial-gradient orbs using `AppColors.primary`, `AppColors.primaryDark`, and `AppColors.primaryLight` as orb colours in both modes.
4. THE AppMeshBackground SHALL use two `AnimationController` instances with `repeat(reverse: true)` at 9 seconds and 13 seconds.
5. WHEN the widget is disposed, THE AppMeshBackground SHALL dispose both `AnimationController` instances.
6. THE AppMeshBackground SHALL accept a `child` widget rendered above all orb layers.


### Requirement 6: AppScaffold — Screen Layout Wrapper

**User Story:** As a developer, I want a single screen-wrapper widget, so that every screen
automatically gets the correct background, header, and bottom navigation without duplicating setup.

#### Acceptance Criteria

1. THE AppScaffold SHALL wrap the `body` in `AppMeshBackground` on every screen.
2. THE AppScaffold SHALL render `AppHeader` as the `appBar`.
3. WHEN `currentNavIndex` is provided, THE AppScaffold SHALL render `AppBottomNav` as the `bottomNavigationBar`.
4. WHEN `currentNavIndex` is null, THE AppScaffold SHALL render no bottom navigation bar.
5. THE AppScaffold SHALL set `extendBody: true` and `extendBodyBehindAppBar: true` so glass panels bleed under the header and tab bar.
6. THE AppScaffold SHALL accept `showBackButton`, `headerActions`, `subtitle`, and `floatingActionButton` parameters.
7. WHEN in light mode, THE AppScaffold body background SHALL be `AppColors.lightBackground` with the mesh orbs rendered at reduced opacity per Requirement 5.2.
8. WHEN in dark mode, THE AppScaffold body background SHALL be `AppColors.meshDeep` with full-opacity mesh orbs.


### Requirement 7: AppHeader — Top Navigation Bar

**User Story:** As a user, I want a glass navigation bar at the top of every screen that adapts to
light and dark mode, so that the header always feels part of the iOS 26 design language.

#### Acceptance Criteria

1. THE AppHeader SHALL implement `PreferredSizeWidget` with `preferredSize` of `Size.fromHeight(kToolbarHeight + 16)` (approximately 72 dp).
2. THE AppHeader SHALL apply `BackdropFilter` with `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` behind the header content.
3. WHEN in dark mode, THE AppHeader SHALL use `AppColors.glassWhiteDark` as the background fill and `AppColors.glassBorderDark` for the bottom border at 0.5 logical pixels.
4. WHEN in light mode, THE AppHeader SHALL use `AppColors.glassWhiteLight` as the background fill and `AppColors.glassBorderLight` for the bottom border at 0.5 logical pixels, producing a clearly visible frosted white bar.
5. THE AppHeader SHALL render the `title` using `AppTextStyles.headlineMedium` resolved for the active mode.
6. WHEN `showBackButton` is true, THE AppHeader SHALL render a `CupertinoIcons.chevron_left` icon in `AppColors.primary` with a minimum touch target of 44×44 dp.
7. WHEN `subtitle` is provided, THE AppHeader SHALL render it below the title using `AppTextStyles.bodyMedium` with `TextOverflow.ellipsis`.
8. WHEN `actions` are provided, THE AppHeader SHALL render them at the trailing end of the header row with a minimum touch target of 44×44 dp per action.
9. THE AppHeader SHALL use `SafeArea(bottom: false)` to respect the device status bar in both modes.
10. WHEN in light mode, THE AppHeader title text SHALL use `AppColors.textPrimaryLight` (`#0D0D0D`) for sufficient contrast against the light frosted background.
11. WHEN in dark mode, THE AppHeader title text SHALL use `AppColors.textPrimaryDark` (`#FFFFFF`) for sufficient contrast against the dark frosted background.


### Requirement 8: AppBottomNav — Tab Bar

**User Story:** As a user, I want a floating glass tab bar with five tabs — Home, Medication, Scan,
Connection, and Settings — so that I can navigate the app with clear visual feedback in both light
and dark mode.

#### Acceptance Criteria

1. THE AppBottomNav SHALL render exactly five tabs in this order: Home (index 0), Medication (index 1), Scan (index 2), Connection (index 3), Settings (index 4).
2. THE AppBottomNav SHALL use these icons: Home → `CupertinoIcons.house` / `house_fill`, Medication → `CupertinoIcons.pills` / `pills_fill`, Scan → `CupertinoIcons.camera` / `camera_fill`, Connection → `CupertinoIcons.person_2` / `person_2_fill`, Settings → `CupertinoIcons.settings` / `settings_solid`.
3. THE Scan tab (index 2) SHALL be visually prominent: rendered with a circular `AppColors.primary` background at 48×48 dp, elevated 4 dp above the tab bar baseline, and always showing the camera icon in white regardless of selection state.
4. WHEN a tab is selected (indices 0, 1, 3, 4), THE AppBottomNav SHALL animate the tab item to expand horizontally and display the label text alongside the filled icon in `AppColors.primary`.
5. WHEN a tab is not selected, THE AppBottomNav SHALL show only the outline icon in the active `textTertiary` token.
6. THE AppBottomNav SHALL use `AnimatedContainer` with a 260 ms `easeOutCubic` curve for the expand/collapse animation.
7. WHEN in dark mode, THE AppBottomNav SHALL use `AppColors.glassWhiteDark` as the background fill and `AppColors.glassBorderDark` for the border.
8. WHEN in light mode, THE AppBottomNav SHALL use `AppColors.glassWhiteLight` as the background fill and `AppColors.glassBorderLight` for the border, producing a bright frosted pill shape.
9. THE AppBottomNav SHALL float above screen content with bottom padding equal to `MediaQuery.padding.bottom + 12` dp.
10. THE AppBottomNav SHALL have a `borderRadius` of `AppSpacing.radiusFull` (100 dp) giving it a pill shape.
11. WHEN in light mode, tab labels and icons SHALL use `AppColors.textPrimaryLight` for selected state and `AppColors.textTertiaryLight` for unselected state.
12. WHEN in dark mode, tab labels and icons SHALL use `AppColors.textPrimaryDark` for selected state and `AppColors.textTertiaryDark` for unselected state.
13. FOR ALL tab indices 0–4, exactly one tab SHALL be in the selected state at any time (invariant).
14. THE AppBottomNav SHALL ensure every tab item has a minimum touch target of 44×44 dp.


### Requirement 9: AppButton — Glass Button

**User Story:** As a developer, I want a single glass button widget with four variants and spring
physics, so that every interactive button in the app has consistent feedback and adapts to both modes.

#### Acceptance Criteria

1. THE AppButton SHALL support four variants: `primary`, `secondary`, `destructive`, and `ghost`.
2. WHEN the `primary` variant is used, THE AppButton SHALL apply `AppColors.glassPrimary` as the tint and `AppColors.primary` as the label colour in both modes.
3. WHEN the `secondary` variant is used in dark mode, THE AppButton SHALL apply `AppColors.glassWhiteDark` as the tint and `AppColors.textPrimaryDark` as the label colour.
4. WHEN the `secondary` variant is used in light mode, THE AppButton SHALL apply `AppColors.glassWhiteLight` as the tint and `AppColors.textPrimaryLight` as the label colour.
5. WHEN the `destructive` variant is used, THE AppButton SHALL apply `AppColors.glassDanger` as the tint and `AppColors.danger` as the label colour in both modes.
6. WHEN the `ghost` variant is used in dark mode, THE AppButton SHALL use a transparent background and `AppColors.textSecondaryDark` as the label colour.
7. WHEN the `ghost` variant is used in light mode, THE AppButton SHALL use a transparent background and `AppColors.textSecondaryLight` as the label colour.
8. THE AppButton SHALL apply a spring-physics scale animation from `1.0` to `0.94` on `onTapDown`, reversed on `onTapUp` or `onTapCancel`, using `AnimationController` with 160 ms duration and `Curves.easeOutBack`.
9. WHEN `isLoading` is true, THE AppButton SHALL replace the label with a `CircularProgressIndicator` in `AppColors.primary` and disable the `onPressed` callback.
10. WHEN `onPressed` is null, THE AppButton SHALL render at 50% opacity to indicate a disabled state.
11. WHEN `isFullWidth` is true, THE AppButton SHALL expand to fill the available horizontal space.
12. WHEN `icon` is provided, THE AppButton SHALL render the icon at 18 dp to the left of the label text.
13. THE AppButton SHALL have a minimum height of 44 dp and minimum horizontal padding of `AppSpacing.lg` (24 dp) to meet touch target requirements.
14. THE AppButton SHALL use `AppSpacing.radiusFull` (100 dp) as the default border radius for a pill shape.


### Requirement 10: AppTextField — Glass Input Field

**User Story:** As a developer, I want a single glass input field widget that adapts to light and
dark mode, so that every form field in the app has consistent blur, border, and focus styling.

#### Acceptance Criteria

1. THE AppTextField SHALL apply `BackdropFilter` with `ImageFilter.blur(sigmaX: 16, sigmaY: 16)` behind the input area.
2. WHEN in dark mode, THE AppTextField SHALL use `AppColors.glassWhiteDark` as the background fill.
3. WHEN in light mode, THE AppTextField SHALL use `AppColors.glassWhiteLight` as the background fill, producing a clearly visible frosted white input area.
4. THE AppTextField SHALL render the `label` in uppercase using `AppTextStyles.labelSmall` above the input field.
5. WHEN in dark mode, THE AppTextField enabled border SHALL use `AppColors.glassBorderDark` at 0.8 px and the focused border SHALL use `AppColors.primary` at 1.5 px.
6. WHEN in light mode, THE AppTextField enabled border SHALL use `AppColors.glassBorderLight` at 0.8 px and the focused border SHALL use `AppColors.primary` at 1.5 px.
7. THE AppTextField error border SHALL use `AppColors.danger` at 1.0 px in both modes.
8. WHEN in dark mode, THE AppTextField input text SHALL use `AppColors.textPrimaryDark` and hint text SHALL use `AppColors.textTertiaryDark`.
9. WHEN in light mode, THE AppTextField input text SHALL use `AppColors.textPrimaryLight` and hint text SHALL use `AppColors.textTertiaryLight`.
10. THE AppTextField SHALL accept `prefix`, `suffix`, `validator`, `keyboardType`, `obscureText`, and `maxLines` parameters.
11. THE AppTextField SHALL have a minimum height of 44 dp for the input area to meet touch target requirements.
12. THE AppTextField SHALL use `AppSpacing.radiusMd` (20 dp) as the border radius.


### Requirement 11: AppCard — Tappable Glass Card

**User Story:** As a developer, I want a reusable glass card widget that adapts to both modes, so
that list items and content panels are visually consistent across all screens.

#### Acceptance Criteria

1. THE AppCard SHALL wrap `AppGlassPanel` with a default padding of `AppSpacing.md` (16 dp).
2. WHEN `onTap` is provided, THE AppCard SHALL wrap the panel in a `GestureDetector` and apply a spring-scale animation on press (scale 1.0 → 0.97, 120 ms, `easeOutBack`).
3. WHEN in dark mode, THE AppCard SHALL use `AppColors.glassWhiteDark` as the glass fill.
4. WHEN in light mode, THE AppCard SHALL use `AppColors.glassWhiteLight` as the glass fill, producing a bright frosted card surface.
5. THE AppCard SHALL use `AppSpacing.radiusLg` (28 dp) as the default border radius.
6. THE AppCard SHALL render the specular top-edge border using the active `glassBorder` token.
7. WHEN in light mode, THE AppCard SHALL render a subtle shadow using `AppColors.glassShadowLight` to lift the card off the light background.
8. WHEN in dark mode, THE AppCard SHALL render a shadow using `AppColors.glassShadow` with `blurRadius: 32` and `offset: Offset(0, 8)`.


### Requirement 12: AppBadge — Status Badge

**User Story:** As a developer, I want a reusable status badge widget with five semantic variants,
so that prescription and medication statuses are visually consistent and readable in both modes.

#### Acceptance Criteria

1. THE AppBadge SHALL support five variants: `active`, `pending`, `completed`, `flagged`, and `info`.
2. WHEN the `active` variant is used, THE AppBadge SHALL use `AppColors.success` (`#34C759`) as the badge colour.
3. WHEN the `pending` variant is used, THE AppBadge SHALL use `AppColors.warning` (`#FF9500`) as the badge colour.
4. WHEN the `completed` variant is used, THE AppBadge SHALL use `AppColors.primary` (`#009DFF`) as the badge colour.
5. WHEN the `flagged` variant is used, THE AppBadge SHALL use `AppColors.danger` (`#FF3B30`) as the badge colour.
6. WHEN the `info` variant is used, THE AppBadge SHALL use `AppColors.info` (`#5AC8FA`) as the badge colour.
7. THE AppBadge SHALL render the label in uppercase using `AppTextStyles.labelSmall` with the badge colour as the text colour.
8. THE AppBadge SHALL render a semi-transparent background at 15% opacity of the badge colour in both light and dark modes.
9. THE AppBadge SHALL use `AppSpacing.radiusFull` (100 dp) as the border radius for a pill shape.
10. THE AppBadge SHALL have a minimum height of 22 dp and horizontal padding of `AppSpacing.sm` (8 dp).


### Requirement 13: AppAvatar — User Avatar

**User Story:** As a developer, I want a reusable avatar widget with a glass ring border, so that
user profile images are consistently styled across all screens in both modes.

#### Acceptance Criteria

1. THE AppAvatar SHALL render a circular profile image when `imageUrl` is provided.
2. WHEN `imageUrl` is null, THE AppAvatar SHALL render the user's `initials` text centred in the circle using `AppTextStyles.labelLarge`.
3. THE AppAvatar SHALL render a glass ring border using the active `glassBorder` token at 1.5 px width.
4. WHEN in dark mode, THE AppAvatar ring background SHALL use a `LinearGradient` from `AppColors.glassWhiteDark` to transparent.
5. WHEN in light mode, THE AppAvatar ring background SHALL use a `LinearGradient` from `AppColors.glassWhiteLight` to transparent.
6. THE AppAvatar SHALL accept a `radius` parameter defaulting to 24 dp.
7. THE AppAvatar SHALL have a minimum touch target of 44×44 dp when used as an interactive element.


### Requirement 14: AppLoadingView, AppErrorView, AppEmptyView — State Views

**User Story:** As a user, I want consistent full-screen feedback states for loading, errors, and
empty data that adapt to both light and dark mode, so that I always understand the current app state.

#### Acceptance Criteria

1. THE AppLoadingView SHALL render a centred `CircularProgressIndicator` in `AppColors.primary` with an optional message using the active `bodyMedium` text style.
2. THE AppErrorView SHALL render a centred `Icons.error_outline` icon in `AppColors.danger` at 48 dp, a message, and an optional retry `AppButton`.
3. THE AppEmptyView SHALL render a centred icon (defaulting to `Icons.inbox_outlined`) in the active `textTertiary` token at 48 dp and a message.
4. WHEN `onRetry` is provided to `AppErrorView`, THE AppErrorView SHALL render an `AppButton` with the `primary` variant labelled "Try Again" that calls `onRetry` on press.
5. WHEN in dark mode, THE AppLoadingView, AppErrorView, and AppEmptyView message text SHALL use `AppColors.textSecondaryDark`.
6. WHEN in light mode, THE AppLoadingView, AppErrorView, and AppEmptyView message text SHALL use `AppColors.textSecondaryLight`.
7. FOR ALL ViewModel states where `isLoading` is true, THE View SHALL render `AppLoadingView` and SHALL NOT render data content simultaneously (invariant).
8. FOR ALL ViewModel states where `hasError` is true and `isLoading` is false, THE View SHALL render `AppErrorView` and SHALL NOT render data content simultaneously (invariant).


### Requirement 15: Accessibility — Touch Targets and Contrast

**User Story:** As a user with motor or visual impairments, I want all interactive elements to be
large enough to tap and all text to have sufficient contrast, so that the app is usable for everyone.

#### Acceptance Criteria

1. THE App SHALL ensure every interactive widget (AppButton, AppBottomNav tabs, AppHeader back button and actions, AppCard with onTap, AppAvatar with onTap) has a minimum touch target of 44×44 dp.
2. WHEN in dark mode, THE App SHALL ensure body text (`AppColors.textPrimaryDark` on `AppColors.meshDeep`) meets a minimum contrast ratio of 4.5:1.
3. WHEN in light mode, THE App SHALL ensure body text (`AppColors.textPrimaryLight` on `AppColors.lightBackground`) meets a minimum contrast ratio of 4.5:1.
4. WHEN in dark mode, THE App SHALL ensure secondary text (`AppColors.textSecondaryDark` on glass surfaces) meets a minimum contrast ratio of 3.0:1.
5. WHEN in light mode, THE App SHALL ensure secondary text (`AppColors.textSecondaryLight` on glass surfaces) meets a minimum contrast ratio of 3.0:1.
6. THE AppBottomNav Scan tab elevated button SHALL have a minimum touch target of 48×48 dp.
7. THE App SHALL not rely on colour alone to convey status — THE AppBadge SHALL always include a text label alongside the colour indicator.
8. THE AppTextField SHALL render a visible label above the input field in both modes so the field purpose is always clear.
