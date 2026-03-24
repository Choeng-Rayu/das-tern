# Implementation Plan: Global Widget System

## Overview

Implement the RxCam global widget system in Flutter — design tokens, 13 reusable widgets, light/dark mode support, and property-based tests using the iOS 26 Liquid Glass aesthetic.

## Tasks

- [ ] 1. Phase 1 — Design Token System
  - [ ] 1.1 Create `lib/core/theme/app_colors.dart`
    - Implement `AppColors` static class with all shared tokens: `primary` (`#009DFF`), `primaryDark`, `primaryLight`, semantic colours (`success`, `danger`, `warning`, `info`), glass tints (`glassPrimary`, `glassDanger`)
    - Add dark-mode tokens: `meshDeep` (`#050A14`), `meshMid`, `glassWhiteDark`, `glassBorderDark`, `glassShadow`, `textPrimaryDark`, `textSecondaryDark`, `textTertiaryDark`
    - Add light-mode tokens: `lightBackground` (`#F2F2F7`), `lightSurface`, `glassWhiteLight`, `glassBorderLight`, `glassShadowLight`, `textPrimaryLight`, `textSecondaryLight`, `textTertiaryLight`
    - Implement `_AppColorScheme` class with `dark()` and `light()` const constructors exposing `background`, `surface`, `glassWhite`, `glassBorder`, `glassShadowColor`, `textPrimary`, `textSecondary`, `textTertiary`
    - Implement `AppColors.of(BuildContext)` static method resolving to `_AppColorScheme.dark()` or `_AppColorScheme.light()` based on `Theme.of(context).brightness`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10_

  - [ ] 1.2 Create `lib/core/theme/app_spacing.dart`
    - Implement `AppSpacing` static class with spacing scale: `xs=4`, `sm=8`, `md=16`, `lg=24`, `xl=32`, `xxl=48`
    - Add superellipse border-radius tokens: `radiusSm=12`, `radiusMd=20`, `radiusLg=28`, `radiusXl=36`, `radiusFull=100`
    - _Requirements: 2.1, 2.2_

  - [ ] 1.3 Create `lib/core/theme/app_text_styles.dart`
    - Implement `AppTextStyles` static class with 9 base `TextStyle` constants: `displayLarge` (34/700), `displayMedium` (28/600), `headlineLarge` (22/600), `headlineMedium` (18/600), `bodyLarge` (17/400), `bodyMedium` (15/400), `bodySmall` (13/400), `labelLarge` (15/600), `labelSmall` (11/600, letterSpacing 0.5)
    - Implement `resolve(TextStyle base, BuildContext context)` returning `base.copyWith(color: AppColors.of(context).textPrimary)`
    - Add convenience resolvers: `headlineMediumResolved(context)`, `bodyMediumResolved(context)` (uses `textSecondary`), `labelSmallResolved(context, {Color? color})`
    - _Requirements: 2.3, 2.4, 2.5_

  - [ ] 1.4 Create `lib/core/theme/app_theme.dart`
    - Implement `AppTheme` static class with `dark` getter: `brightness: Brightness.dark`, `scaffoldBackgroundColor: AppColors.meshDeep`, transparent `AppBarTheme`, `colorScheme.primary: AppColors.primary`, `useMaterial3: true`
    - Implement `light` getter: `brightness: Brightness.light`, `scaffoldBackgroundColor: AppColors.lightBackground`, transparent `AppBarTheme`, `colorScheme.primary: AppColors.primary`
    - Implement `_buildTextTheme({required bool isDark})` helper mapping all 9 `AppTextStyles` entries with correct primary/secondary colours
    - _Requirements: 3.1, 3.2, 3.5, 3.6_

  - [ ]* 1.5 Write unit tests for token system
    - Assert exact hex values for every `AppColors` constant (Property 13, validates Req 1.1–1.10)
    - Assert `AppColors.of(darkContext).glassWhite == AppColors.glassWhiteDark` and `textPrimary == AppColors.textPrimaryDark` (Property 14, validates Req 1.4–1.7, 2.5)
    - Assert `AppColors.of(lightContext).glassWhite == AppColors.glassWhiteLight` and `textPrimary == AppColors.textPrimaryLight`
    - Assert `AppTheme.dark.brightness == Brightness.dark`, `scaffoldBackgroundColor == AppColors.meshDeep`, `colorScheme.primary == AppColors.primary` (Property 12, validates Req 3.1, 3.5)
    - Assert `AppTheme.light.brightness == Brightness.light`, `scaffoldBackgroundColor == AppColors.lightBackground` (Property 11, validates Req 3.2, 3.5)
    - Assert WCAG contrast ratio ≥ 4.5:1 for `textPrimaryDark` on `meshDeep` and `textPrimaryLight` on `lightBackground`; ≥ 3.0:1 for secondary text pairs (Property 15, validates Req 15.2–15.5)
    - _Requirements: 1.1–1.10, 2.5, 3.1, 3.2, 3.5, 15.2–15.5_

- [ ] 2. Phase 2 — Foundation Glass Widgets
  - [ ] 2.1 Create `lib/core/widgets/app_glass_panel.dart`
    - Implement `AppGlassPanel` as `StatelessWidget` with params: `child`, `borderRadius` (default `AppSpacing.radiusLg`), `tint`, `blurRadius` (default 20.0), `opacity` (default 1.0), `padding`
    - Build widget tree: `Opacity` → `DecoratedBox` (shadow outside clip) → `ClipRRect` → `BackdropFilter(blur sigmaX/Y: blurRadius)` → `DecoratedBox` (gradient + top border) → `Padding` → `child`
    - Dark mode gradient stops: `resolvedTint.withOpacity(0.18)` → `resolvedTint.withOpacity(0.06)`; light mode: `0.60` → `0.40`
    - Shadow: `colors.glassShadowColor`, `blurRadius: 32`, `offset: Offset(0, 8)`
    - Top border: `colors.glassBorder` at 0.8 px; `resolvedTint` defaults to `Colors.white`, overridden by `tint`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

  - [ ]* 2.2 Write property tests for AppGlassPanel
    - **Property 1: Single BackdropFilter invariant** — for any combination of `borderRadius`, `blurRadius`, `opacity`, `padding`, `tint`, the widget tree contains exactly one `BackdropFilter` node
    - **Validates: Requirement 4.9**
    - **Property 2: Gradient opacity stops are mode-correct** — without custom `tint`, stops are `(0.18, 0.06)` in dark mode and `(0.60, 0.40)` in light mode; same stops apply when `tint` is provided
    - **Validates: Requirements 4.4, 4.5, 4.6**

  - [ ] 2.3 Create `lib/core/widgets/app_mesh_background.dart`
    - Implement `AppMeshBackground` as `StatefulWidget` with `child` param; mixin `TickerProviderStateMixin`
    - Create `_controller1` (9 s, `repeat(reverse: true)`) and `_controller2` (13 s, `repeat(reverse: true)`) in `initState`
    - Build `Stack`: base `Container(color: colors.background)`, three `AnimatedBuilder`/`CustomPaint` orbs using `_OrbPainter` with `AppColors.primary` (0.30/0.12), `AppColors.primaryDark` (0.22/0.08), `AppColors.primaryLight` (0.16/0.06) for dark/light opacities; third orb reuses `_controller1` with `Tween(0.3, 0.7)`
    - Implement `_OrbPainter` as `CustomPainter` drawing a `RadialGradient` with centre drifting ±10% of screen dimensions
    - Dispose both controllers in `dispose()`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [ ]* 2.4 Write property test for AppMeshBackground
    - **Property 16: AnimationController disposal** — for any `AppMeshBackground` instance that is mounted then unmounted, both `_controller1` and `_controller2` have `dispose()` called exactly once; no controller remains active after widget removal
    - **Validates: Requirement 5.5**

- [ ] 3. Phase 3 — Layout Widgets
  - [ ] 3.1 Create `lib/core/widgets/app_header.dart`
    - Implement `AppHeader extends StatelessWidget implements PreferredSizeWidget`; `preferredSize` returns `Size.fromHeight(kToolbarHeight + 16)`
    - Params: `title` (required), `showBackButton` (default false), `subtitle`, `actions`
    - Widget tree: `ClipRect` → `BackdropFilter(blur 20/20)` → `DecoratedBox(color: colors.glassWhite, bottom border: colors.glassBorder 0.5px)` → `SafeArea(bottom: false)` → `Padding` → `Row`
    - Row: optional `SizedBox(44×44)` back button with `CupertinoIcons.chevron_left` in `AppColors.primary`; `Expanded` column with title (`headlineMediumResolved`) and optional subtitle (`bodyMediumResolved`, `TextOverflow.ellipsis`); optional actions each wrapped in `SizedBox(44×44)`
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10, 7.11_

  - [ ] 3.2 Create `lib/core/widgets/app_bottom_nav.dart`
    - Define `NavTab` enum with indices 0–4 and `AppBottomNav` with `currentIndex` and `onTap` params
    - Implement `_NavItem` for indices 0, 1, 3, 4: `GestureDetector` → `AnimatedContainer(260ms, easeOutCubic)` with selected width expansion; selected state shows filled icon + label in `AppColors.primary` with 15% primary bg; unselected shows outline icon in `colors.textTertiary`; minimum height 44 dp
    - Implement `_ScanTab` for index 2: `GestureDetector` → `Transform.translate(Offset(0, -4))` → `Container(48×48, circle, AppColors.primary bg, primary glow shadow)` → `Icon(camera_fill, white, 22)`
    - Wrap all tabs in `AppGlassPanel(borderRadius: AppSpacing.radiusFull, padding: EdgeInsets.symmetric(h:8, v:8))` inside `Center` with `Padding(bottom: MediaQuery.padding.bottom + 12)`
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10, 8.11, 8.12, 8.14_

  - [ ]* 3.3 Write property tests for AppBottomNav
    - **Property 3: Exactly one tab selected** — for any `currentIndex` in [0, 4], exactly one tab item is in selected visual state (filled icon + label + primary highlight); remaining four are unselected
    - **Validates: Requirements 8.13, 8.4, 8.5**
    - **Property 4: Scan tab always has primary background** — for any `currentIndex` (0–4, including 2), the Scan tab always renders with circular `AppColors.primary` background at 48×48 dp and white camera icon; appearance does not change based on selection state
    - **Validates: Requirement 8.3**

  - [ ] 3.4 Create `lib/core/widgets/app_scaffold.dart`
    - Implement `AppScaffold` as `StatelessWidget` with params: `title`, `body` (required), `currentNavIndex`, `onNavTap`, `showBackButton` (default false), `subtitle`, `headerActions`, `floatingActionButton`
    - Build `Scaffold(extendBody: true, extendBodyBehindAppBar: true, backgroundColor: colors.background)`
    - Set `appBar: AppHeader(...)`, `body: AppMeshBackground(child: body)`, `bottomNavigationBar: currentNavIndex != null ? AppBottomNav(...) : null`
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

  - [ ]* 3.5 Write property tests for AppScaffold
    - **Property 9: Body always wrapped in AppMeshBackground** — for any `AppScaffold` with any `body` widget, the body is always the direct child of `AppMeshBackground`; no configuration renders body without mesh background
    - **Validates: Requirement 6.1**
    - **Property 10: Bottom nav present iff currentNavIndex non-null** — `bottomNavigationBar` contains `AppBottomNav` if and only if `currentNavIndex` is non-null; when null, slot is null (biconditional invariant)
    - **Validates: Requirements 6.3, 6.4**

- [ ] 4. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Phase 4 — Interactive Widgets
  - [ ] 5.1 Create `lib/core/widgets/app_button.dart`
    - Define `AppButtonVariant` enum (`primary`, `secondary`, `destructive`, `ghost`)
    - Implement `AppButton` as `StatefulWidget` with `TickerProviderStateMixin`; params: `label`, `onPressed`, `variant` (default primary), `isLoading`, `isFullWidth`, `icon`
    - Spring animation: `AnimationController(160ms)` + `CurvedAnimation(easeOutBack)` + `Tween(1.0, 0.94)`; `_startPress` calls `forward()`, `_endPress` calls `reverse()`
    - Widget tree: `Opacity(onPressed == null ? 0.5 : 1.0)` → `GestureDetector` → `AnimatedBuilder` → `Transform.scale` → `AppGlassPanel(tint: resolvedTint, borderRadius: AppSpacing.radiusFull, padding: h:lg, v:12)` → `SizedBox(width: isFullWidth ? infinity : null)` → `Row`
    - Variant colour matrix: primary→`glassPrimary`/`primary`; secondary→`colors.glassWhite`/`colors.textPrimary`; destructive→`glassDanger`/`danger`; ghost→transparent/`colors.textSecondary`
    - Loading state: replace label/icon with `SizedBox(18×18, CircularProgressIndicator(strokeWidth:2, color:primary))`; icon at 18 dp left of label when provided
    - Dispose controller in `dispose()`
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8, 9.9, 9.10, 9.11, 9.12, 9.13, 9.14_

  - [ ]* 5.2 Write property tests for AppButton
    - **Property 5: Scale reaches 0.94 on tap for all variants** — for any `AppButton` with any `AppButtonVariant` and non-null `onPressed`, on tap-down the `Transform.scale` value animates to `0.94`; on tap-up/cancel it returns to `1.0`; holds for all four variants
    - **Validates: Requirement 9.8**

  - [ ] 5.3 Create `lib/core/widgets/app_text_field.dart`
    - Implement `AppTextField` as `StatefulWidget`; params: `label`, `hint`, `controller`, `validator`, `keyboardType`, `obscureText` (default false), `maxLines` (default 1), `prefix`, `suffix`, `onChanged`
    - Widget tree: `Column` → `Padding(bottom: xs)` + `Text(label.toUpperCase(), labelSmallResolved)` above `ClipRRect(radiusMd)` → `BackdropFilter(blur 16/16)` → `TextFormField`
    - `InputDecoration`: `filled: true`, `fillColor: colors.glassWhite`; enabled border `colors.glassBorder 0.8px`; focused border `primary 1.5px`; error border `danger 1.0px`; focused error border `danger 1.5px`; `contentPadding: h:md, v:12` (≥44dp total)
    - Input text `colors.textPrimary`; hint text `colors.textTertiary`
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.9, 10.10, 10.11, 10.12_

  - [ ]* 5.4 Write property test for AppTextField
    - **Property 8: Label always uppercase** — for any `AppTextField` with any non-empty `label` string, the label text rendered above the input field is `label.toUpperCase()`; holds regardless of input casing (lowercase, uppercase, mixed, non-ASCII)
    - **Validates: Requirement 10.4**

  - [ ] 5.5 Create `lib/core/widgets/app_card.dart`
    - Implement `AppCard` as `StatefulWidget`; params: `child`, `onTap`, `padding`, `borderRadius` (default `AppSpacing.radiusLg`), `tint`
    - When `onTap` provided: wrap in `GestureDetector` + `AnimatedBuilder` + `Transform.scale`; spring animation `AnimationController(120ms)`, `easeOutBack`, `Tween(1.0, 0.97)`
    - Wrap `AppGlassPanel(borderRadius, tint: tint ?? colors.glassWhite, padding: padding ?? EdgeInsets.all(md))` with child
    - Dispose controller in `dispose()` when `onTap` was provided
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8_

  - [ ] 5.6 Create `lib/core/widgets/app_badge.dart`
    - Define `AppBadgeVariant` enum (`active`, `pending`, `completed`, `flagged`, `info`)
    - Implement `AppBadge` as `StatelessWidget`; params: `label`, `variant`
    - Variant colour map: active→`success`, pending→`warning`, completed→`primary`, flagged→`danger`, info→`info`
    - Widget tree: `Container(height ≥ 22, padding: h:sm v:3, decoration: color badgeColor.withOpacity(0.15), borderRadius: radiusFull)` → `Text(label.toUpperCase(), labelSmall.copyWith(color: badgeColor))`
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8, 12.9, 12.10_

  - [ ]* 5.7 Write property tests for AppBadge
    - **Property 6: Background always at 15% opacity of badge colour** — for any `AppBadge` with any `AppBadgeVariant`, the background container colour equals `badgeColor.withOpacity(0.15)`; holds in both light and dark mode
    - **Validates: Requirement 12.8**
    - **Property 7: Label always uppercase** — for any `AppBadge` with any non-empty `label` string, the rendered text is `label.toUpperCase()`; holds regardless of input casing
    - **Validates: Requirement 12.7**

  - [ ] 5.8 Create `lib/core/widgets/app_avatar.dart`
    - Implement `AppAvatar` as `StatelessWidget`; params: `imageUrl`, `initials`, `radius` (default 24), `onTap`
    - Widget tree: `GestureDetector(onTap)` → `SizedBox(max(radius*2, 44) × max(radius*2, 44))` → `Center` → `Container(radius*2 circle, gradient: colors.glassWhite→transparent, border: colors.glassBorder 1.5px)` → `ClipOval`
    - When `imageUrl` non-null: `Image.network(fit: cover, errorBuilder: fallback to initials)`; else `Container(primary.withOpacity(0.20))` with centred `Text(initials ?? '?', labelLarge, color: primary)`
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_

  - [ ] 5.9 Create `lib/core/widgets/app_loading_view.dart`, `app_error_view.dart`, `app_empty_view.dart`
    - `AppLoadingView(message?)`: `Center` → `Column(min)` → `CircularProgressIndicator(primary, strokeWidth:3)` + optional `Padding(top:md)` + `Text(message, bodyMedium, colors.textSecondary, center)`
    - `AppErrorView(message, onRetry?)`: `Center` → `Padding(xl)` → `Column(min)` → `Icon(error_outline, danger, 48)` + `Padding(top:md)` + `Text(message, bodyMedium, colors.textSecondary)` + optional `Padding(top:lg)` + `AppButton('Try Again', primary, onRetry)`
    - `AppEmptyView(message, icon?)`: `Center` → `Padding(xl)` → `Column(min)` → `Icon(icon ?? inbox_outlined, colors.textTertiary, 48)` + `Padding(top:md)` + `Text(message, bodyMedium, colors.textSecondary)`
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

- [ ] 6. Phase 5 — Integration & QA
  - [ ] 6.1 Verify all widgets use only AppColors tokens
    - Audit all files under `lib/core/widgets/` and `lib/core/theme/` for any `Colors.*` or `Color(0x...)` literals (except `Colors.transparent` in ghost button and `Colors.white` as `resolvedTint` base in `AppGlassPanel`)
    - Fix any violations found
    - _Requirements: 1.11_

  - [ ] 6.2 Verify all touch targets meet 44×44 dp minimum
    - Confirm `AppButton` minimum height 44 dp (padding enforced)
    - Confirm `AppHeader` back button and each action wrapped in `SizedBox(44×44)`
    - Confirm `AppBottomNav` `_NavItem` height 44 dp and `_ScanTab` 48×48 dp
    - Confirm `AppAvatar` `SizedBox(max(radius*2, 44))` when `onTap` provided
    - Confirm `AppCard` with `onTap` has sufficient tap area
    - _Requirements: 15.1, 15.6_

  - [ ] 6.3 Final checkpoint — Run full test suite
    - Ensure all property tests and unit tests pass
    - Run `flutter analyze` and confirm zero issues
    - Ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (Properties 1–17 from design doc)
- Unit tests validate specific examples and edge cases
- `fast_check` is the property-based testing library (minimum 100 iterations per property)
