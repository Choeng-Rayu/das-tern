import 'package:flutter/widgets.dart';

/// Spacing tokens follow a 4px base grid: 4, 8, 16, 24, 32, 48, 64.
///
/// Use these constants instead of hard-coded numeric values so a future
/// density change is a one-line edit. If a value isn't on the scale,
/// reach for [AppSpacing.custom] sparingly and document why in the call
/// site.
///
/// Spec ref: 09-design-system-localization §Requirement 1, §Requirement 9.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Page-level horizontal padding. Adapts at breakpoints in the layout
  /// helpers (see `breakpoints.dart`).
  static const EdgeInsets pageCompact = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pageMedium = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pageExpanded = EdgeInsets.symmetric(horizontal: xl);

  /// Standard vertical gap between major sections inside a screen.
  static const SizedBox sectionGap = SizedBox(height: lg);
  static const SizedBox itemGap = SizedBox(height: md);
  static const SizedBox tightGap = SizedBox(height: sm);
}
