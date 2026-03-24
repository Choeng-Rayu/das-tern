// lib/core/theme/app_text_styles.dart
//
// RxCam Global Widget System — Design Token: Typography
// iOS 26 Liquid Glass aesthetic — bilingual (EN + KH) support
//
// Requirements: 2.3, 2.4, 2.5

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography design tokens for the RxCam app.
///
/// Supports both **English** (system default sans-serif) and **Khmer**
/// ([kKhmerFontFamily]) via [fontFamilyForLocale].
///
/// Base [TextStyle] constants intentionally omit colour — colours are always
/// resolved at call-site via [AppColors.of(context)] so styles adapt to the
/// active light/dark theme.
///
/// Usage:
/// ```dart
/// // Preferred: use a convenience resolver
/// Text('Title', style: AppTextStyles.headlineMediumResolved(context));
///
/// // Locale-aware font family (pass to AppTheme):
/// final font = AppTextStyles.fontFamilyForLocale(Localizations.localeOf(context));
/// ```
class AppTextStyles {
  AppTextStyles._();

  /// Font family name for Khmer script — must match pubspec.yaml declaration.
  static const String kKhmerFontFamily = 'NotoSansKhmer';

  /// Returns [kKhmerFontFamily] when the locale language is Khmer ('km'),
  /// otherwise returns null (system default san-serif).
  static String? fontFamilyForLocale(Locale locale) =>
      locale.languageCode == 'km' ? kKhmerFontFamily : null;

  // ── Base styles — no colour, no fontFamily applied ────────────────────────
  // FontFamily is applied at the ThemeData level via AppTheme.

  /// 34/700 — large display text, hero sections
  static const TextStyle displayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// 28/600 — medium display text, screen heroes
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  /// 22/600 — section headers, large titles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  /// 18/600 — navigation bar title, card headers
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  /// 17/400 — primary body content
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
  );

  /// 15/400 — standard body text, subtitles
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  /// 13/400 — small supplementary text
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// 15/600 — button labels, tab labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// 11/600 — overline labels, badge text, field labels
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ── Colour resolvers ───────────────────────────────────────────────────────

  /// Returns [base] with [textPrimary] colour for the active brightness.
  static TextStyle resolve(TextStyle base, BuildContext context) {
    return base.copyWith(color: AppColors.of(context).textPrimary);
  }

  /// [headlineMedium] resolved with [textPrimary] colour.
  static TextStyle headlineMediumResolved(BuildContext context) =>
      headlineMedium.copyWith(color: AppColors.of(context).textPrimary);

  /// [bodyMedium] resolved with [textSecondary] colour.
  static TextStyle bodyMediumResolved(BuildContext context) =>
      bodyMedium.copyWith(color: AppColors.of(context).textSecondary);

  /// [labelSmall] resolved, with optional colour override.
  static TextStyle labelSmallResolved(BuildContext context, {Color? color}) =>
      labelSmall.copyWith(
        color: color ?? AppColors.of(context).textTertiary,
      );
}
