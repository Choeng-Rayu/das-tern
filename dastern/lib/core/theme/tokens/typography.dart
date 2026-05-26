import 'package:flutter/material.dart';

/// Typography tokens for Das Tern.
///
/// Font strategy:
/// - Khmer script is the default audience; the Khmer family is listed first
///   so any text containing Khmer codepoints renders correctly.
/// - Latin text falls through to Inter via [fallback].
/// - When the bundled fonts aren't yet present (initial scaffold), Flutter
///   uses the OS Noto fonts, which still render Khmer correctly on
///   Android 10+ and iOS 14+. The fallback chain is forgiving.
///
/// Type scale follows Material 3 with seven steps that the team agreed are
/// enough for the whole app — keep the surface small.
///
/// Spec ref: 09-design-system-localization §Requirement 1, §Requirement 8.
class AppTypography {
  const AppTypography._();

  /// Primary family (Khmer-first). Configured in `pubspec.yaml`.
  static const String primaryFamily = 'NotoSansKhmer';

  /// Latin family used as fallback for sections that are pure Latin.
  static const String latinFamily = 'Inter';

  /// Fallback chain — Flutter will try each family in order for every glyph.
  static const List<String> fallback = <String>[
    'NotoSansKhmer',
    'Inter',
    'Roboto', // shipped on Android by default
  ];

  /// Builds the [TextTheme] for a given [ColorScheme].
  ///
  /// Each style applies the fallback chain so Khmer + Latin text both render
  /// correctly without any caller having to set `fontFamilyFallback` again.
  static TextTheme textTheme(ColorScheme cs) {
    TextStyle base(
      double size,
      double height,
      FontWeight weight, {
      Color? color,
    }) => TextStyle(
      fontSize: size,
      height: height,
      fontWeight: weight,
      color: color ?? cs.onSurface,
      fontFamily: primaryFamily,
      fontFamilyFallback: fallback,
    );

    return TextTheme(
      displayLarge: base(36, 1.2, FontWeight.w700),
      headlineLarge: base(28, 1.25, FontWeight.w700),
      headlineMedium: base(22, 1.3, FontWeight.w600),
      titleLarge: base(18, 1.4, FontWeight.w600),
      titleMedium: base(16, 1.4, FontWeight.w600),
      bodyLarge: base(16, 1.5, FontWeight.w400),
      bodyMedium: base(14, 1.5, FontWeight.w400, color: cs.onSurfaceVariant),
      labelLarge: base(14, 1.4, FontWeight.w600),
      labelMedium: base(12, 1.4, FontWeight.w500, color: cs.onSurfaceVariant),
      labelSmall: base(11, 1.4, FontWeight.w500, color: cs.onSurfaceVariant),
    );
  }
}
