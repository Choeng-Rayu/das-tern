// lib/core/theme/app_colors.dart
//
// RxCam Global Widget System — Design Token: Colours
// iOS 26 Liquid Glass aesthetic — light + dark mode support
//
// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10

import 'package:flutter/material.dart';

/// All colour design tokens for the RxCam app.
///
/// Use [AppColors.of(context)] to resolve mode-sensitive tokens at runtime.
/// Access shared tokens directly as static constants (e.g. [AppColors.primary]).
///
/// No widget may reference a raw `Color(0x...)` or `Colors.*` value directly.
class AppColors {
  AppColors._();

  // ── Shared tokens (identical in both light and dark modes) ─────────────────

  /// Primary brand accent — #009DFF (Req 1.1)
  static const Color primary = Color(0xFF009DFF);

  /// Darker brand shade for orbs/gradients
  static const Color primaryDark = Color(0xFF0070CC);

  /// Lighter brand shade for orbs/gradients
  static const Color primaryLight = Color(0xFF66C8FF);

  // Semantic colours (Req 1.8)
  static const Color success = Color(0xFF34C759);
  static const Color danger  = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info    = Color(0xFF5AC8FA);

  // Glass tint tokens (Req 1.9)
  /// primary at 10% opacity
  static const Color glassPrimary = Color(0x1A009DFF);

  /// danger at 10% opacity
  static const Color glassDanger  = Color(0x1AFF3B30);

  // ── Dark-mode mesh background tokens (Req 1.2) ────────────────────────────

  /// Deep navy background #050A14
  static const Color meshDeep = Color(0xFF050A14);

  /// Mid navy #0A1628
  static const Color meshMid  = Color(0xFF0A1628);

  // ── Dark-mode glass surface tokens (Req 1.4) ──────────────────────────────

  /// White at 10% opacity — glass fill in dark mode
  static const Color glassWhiteDark  = Color(0x1AFFFFFF);

  /// White at 20% opacity — specular border in dark mode
  static const Color glassBorderDark = Color(0x33FFFFFF);

  /// Black at 25% opacity — floating shadow in dark mode (Req 1.10)
  static const Color glassShadow     = Color(0x40000000);

  // ── Dark-mode text tokens (Req 1.6) ───────────────────────────────────────

  static const Color textPrimaryDark   = Color(0xFFFFFFFF);

  /// White at 70%
  static const Color textSecondaryDark = Color(0xB3FFFFFF);

  /// White at 40%
  static const Color textTertiaryDark  = Color(0x66FFFFFF);

  // ── Light-mode background tokens (Req 1.3) ────────────────────────────────

  /// Light system background #F2F2F7
  static const Color lightBackground = Color(0xFFF2F2F7);

  /// Pure white card surface
  static const Color lightSurface    = Color(0xFFFFFFFF);

  // ── Light-mode glass surface tokens (Req 1.5) ─────────────────────────────

  /// White at 60% opacity — glass fill in light mode
  static const Color glassWhiteLight  = Color(0x99FFFFFF);

  /// Black at 12% opacity — specular border in light mode
  static const Color glassBorderLight = Color(0x1F000000);

  /// Black at 10% opacity — floating shadow in light mode (Req 1.10)
  static const Color glassShadowLight = Color(0x1A000000);

  // ── Light-mode text tokens (Req 1.7) ──────────────────────────────────────

  /// Near-black #0D0D0D
  static const Color textPrimaryLight   = Color(0xFF0D0D0D);

  /// #3C3C43 at 60% opacity
  static const Color textSecondaryLight = Color(0x993C3C43);

  /// #3C3C43 at 30% opacity
  static const Color textTertiaryLight  = Color(0x4D3C3C43);

  // ── Context-resolved accessor ─────────────────────────────────────────────

  /// Returns the resolved colour scheme for the active [ThemeData.brightness].
  ///
  /// Use this at widget build-time to get mode-sensitive tokens:
  /// ```dart
  /// final colors = AppColors.of(context);
  /// colors.textPrimary // resolves to textPrimaryDark or textPrimaryLight
  /// ```
  static _AppColorScheme of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const _AppColorScheme.dark()
        : const _AppColorScheme.light();
  }
}

/// A fully resolved set of mode-sensitive colour tokens.
///
/// Construct via `_AppColorScheme.dark()` or `_AppColorScheme.light()`.
class _AppColorScheme {
  final Color background;
  final Color surface;
  final Color glassWhite;
  final Color glassBorder;
  final Color glassShadowColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const _AppColorScheme.dark()
      : background      = AppColors.meshDeep,
        surface         = AppColors.meshMid,
        glassWhite      = AppColors.glassWhiteDark,
        glassBorder     = AppColors.glassBorderDark,
        glassShadowColor= AppColors.glassShadow,
        textPrimary     = AppColors.textPrimaryDark,
        textSecondary   = AppColors.textSecondaryDark,
        textTertiary    = AppColors.textTertiaryDark;

  const _AppColorScheme.light()
      : background      = AppColors.lightBackground,
        surface         = AppColors.lightSurface,
        glassWhite      = AppColors.glassWhiteLight,
        glassBorder     = AppColors.glassBorderLight,
        glassShadowColor= AppColors.glassShadowLight,
        textPrimary     = AppColors.textPrimaryLight,
        textSecondary   = AppColors.textSecondaryLight,
        textTertiary    = AppColors.textTertiaryLight;
}
