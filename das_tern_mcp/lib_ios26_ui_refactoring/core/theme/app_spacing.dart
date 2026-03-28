// lib/core/theme/app_spacing.dart
//
// RxCam Global Widget System — Design Token: Spacing & Border Radius
// iOS 26 Liquid Glass aesthetic — superellipse radius scale
//
// Requirements: 2.1, 2.2

/// Spacing and border-radius design tokens for the RxCam app.
///
/// Always reference these constants instead of hardcoding pixel values.
///
/// Spacing scale is in logical pixels (dp).
/// Border-radius values produce superellipse (squircle-like) shapes.
class AppSpacing {
  AppSpacing._();

  // ── Spacing scale (dp) ─────────────────────────────────────────────────────

  /// 4 dp — smallest nudge, icon gaps, tight padding
  static const double xs = 4;

  /// 8 dp — compact padding, small gaps
  static const double sm = 8;

  /// 16 dp — standard content padding
  static const double md = 16;

  /// 24 dp — section spacing, button horizontal padding
  static const double lg = 24;

  /// 32 dp — large section gaps
  static const double xl = 32;

  /// 48 dp — extra-large separation
  static const double xxl = 48;

  // ── Superellipse border-radius tokens (dp) ─────────────────────────────────

  /// 12 dp — small elements: chips, compact badges
  static const double radiusSm = 12;

  /// 20 dp — input fields, smaller cards
  static const double radiusMd = 20;

  /// 28 dp — standard cards, panels
  static const double radiusLg = 28;

  /// 36 dp — large panels, sheet headers
  static const double radiusXl = 36;

  /// 100 dp — pill shape: buttons, bottom nav, full-circle badges
  static const double radiusFull = 100;
}
