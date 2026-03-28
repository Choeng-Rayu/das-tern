// lib/core/theme/app_theme.dart
//
// RxCam Global Widget System — Theme Assembly
// iOS 26 Liquid Glass aesthetic — light + dark ThemeData
// Bilingual: supports NotoSansKhmer font family via fontFamily param
//
// Requirements: 3.1, 3.2, 3.5, 3.6

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Assembles [ThemeData] for both light and dark modes with optional
/// locale-aware font family (pass [AppTextStyles.kKhmerFontFamily] for Khmer).
///
/// Usage in [MaterialApp]:
/// ```dart
/// // System locale (English default):
/// theme: AppTheme.light(),
/// darkTheme: AppTheme.dark(),
///
/// // Khmer locale:
/// final font = AppTextStyles.fontFamilyForLocale(locale);
/// theme: AppTheme.light(fontFamily: font),
/// darkTheme: AppTheme.dark(fontFamily: font),
/// ```
class AppTheme {
  AppTheme._();

  // ── Dark theme (Req 3.1) ───────────────────────────────────────────────────

  /// Full dark-mode [ThemeData].
  ///
  /// - [scaffoldBackgroundColor]: [AppColors.meshDeep] (#050A14)
  /// - [colorScheme.primary]: [AppColors.primary] (#009DFF)
  /// - App bar: transparent, elevation 0
  /// - [fontFamily]: optional font family override (e.g. NotoSansKhmer for km)
  static ThemeData dark({String? fontFamily}) => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.meshDeep,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.meshMid,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: _buildTextTheme(isDark: true, fontFamily: fontFamily),
    useMaterial3: true,
  );

  // ── Light theme (Req 3.2) ──────────────────────────────────────────────────

  /// Full light-mode [ThemeData].
  ///
  /// - [scaffoldBackgroundColor]: [AppColors.lightBackground] (#F2F2F7)
  /// - [colorScheme.primary]: [AppColors.primary] (#009DFF)
  /// - App bar: transparent, elevation 0
  /// - [fontFamily]: optional font family override (e.g. NotoSansKhmer for km)
  static ThemeData light({String? fontFamily}) => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.lightSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: _buildTextTheme(isDark: false, fontFamily: fontFamily),
    useMaterial3: true,
  );

  // ── Private helper (Req 3.6) ───────────────────────────────────────────────

  /// Builds a [TextTheme] from [AppTextStyles] with correct colours + font.
  ///
  /// [fontFamily] propagates to every [TextStyle] so Khmer text renders
  /// with NotoSansKhmer throughout.
  static TextTheme _buildTextTheme({required bool isDark, String? fontFamily}) {
    final primary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    // Helper: apply colour + optional fontFamily to a base style
    TextStyle p(TextStyle s) =>
        s.copyWith(color: primary, fontFamily: fontFamily);
    TextStyle sec(TextStyle s) =>
        s.copyWith(color: secondary, fontFamily: fontFamily);

    return TextTheme(
      displayLarge: p(AppTextStyles.displayLarge),
      displayMedium: p(AppTextStyles.displayMedium),
      headlineLarge: p(AppTextStyles.headlineLarge),
      headlineMedium: p(AppTextStyles.headlineMedium),
      bodyLarge: p(AppTextStyles.bodyLarge),
      bodyMedium: sec(AppTextStyles.bodyMedium),
      bodySmall: sec(AppTextStyles.bodySmall),
      labelLarge: p(AppTextStyles.labelLarge),
      labelSmall: sec(AppTextStyles.labelSmall),
    );
  }
}
