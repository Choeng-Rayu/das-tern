import 'package:flutter/material.dart';

/// Centralized Liquid Glass design tokens.
///
/// All glass widgets reference these tokens — never hardcode blur, tint,
/// border, or shadow values directly. Respects accessibility via
/// [GlassTokens.resolve] which adjusts for reduced transparency.
class GlassTokens {
  GlassTokens._();

  // ── Blur ────────────────────────────────────────────────────────────────
  static const double blurRadius = 20.0;
  static const double blurRadiusLight = 12.0;

  // ── Tint opacity ────────────────────────────────────────────────────────
  static const double tintOpacityLight = 0.60;
  static const double tintOpacityDark = 0.18;
  static const double tintOpacityLightSecondary = 0.40;
  static const double tintOpacityDarkSecondary = 0.06;

  // ── Border ──────────────────────────────────────────────────────────────
  static const double borderWidth = 0.8;
  static const Color borderColorLight = Color(0x1F000000); // black 12%
  static const Color borderColorDark = Color(0x33FFFFFF); // white 20%

  // ── Shadow ──────────────────────────────────────────────────────────────
  static const Color shadowColorLight = Color(0x1A000000); // black 10%
  static const Color shadowColorDark = Color(0x40000000); // black 25%
  static const double shadowBlur = 32.0;
  static const Offset shadowOffset = Offset(0, 8);

  // ── Radius ──────────────────────────────────────────────────────────────
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 999.0;

  // ── Animation ───────────────────────────────────────────────────────────
  static const double pressedScale = 0.94;
  static const Duration pressDuration = Duration(milliseconds: 160);
  static const Curve pressCurve = Curves.easeOutBack;

  // ── Disabled / Accessibility ────────────────────────────────────────────
  static const double disabledOpacity = 0.5;

  /// Increased tint opacity for reduced-transparency accessibility mode.
  static const double highContrastTintLight = 0.85;
  static const double highContrastTintDark = 0.45;

  // ── Resolved tokens ─────────────────────────────────────────────────────

  /// Resolve mode-aware glass tokens from context.
  static ResolvedGlassTokens resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final reduceTransparency = mq.highContrast;
    final disableAnimations = mq.disableAnimations;

    return ResolvedGlassTokens(
      isDark: isDark,
      reduceTransparency: reduceTransparency,
      disableAnimations: disableAnimations,
    );
  }
}

/// Resolved glass tokens for the current context.
class ResolvedGlassTokens {
  const ResolvedGlassTokens({
    required this.isDark,
    this.reduceTransparency = false,
    this.disableAnimations = false,
  });

  final bool isDark;
  final bool reduceTransparency;
  final bool disableAnimations;

  double get blurRadius => reduceTransparency ? 0.0 : GlassTokens.blurRadius;

  double get tintOpacity => reduceTransparency
      ? (isDark
            ? GlassTokens.highContrastTintDark
            : GlassTokens.highContrastTintLight)
      : (isDark ? GlassTokens.tintOpacityDark : GlassTokens.tintOpacityLight);

  double get tintOpacitySecondary => reduceTransparency
      ? tintOpacity
      : (isDark
            ? GlassTokens.tintOpacityDarkSecondary
            : GlassTokens.tintOpacityLightSecondary);

  Color get borderColor =>
      isDark ? GlassTokens.borderColorDark : GlassTokens.borderColorLight;

  Color get shadowColor =>
      isDark ? GlassTokens.shadowColorDark : GlassTokens.shadowColorLight;

  Duration get pressDuration =>
      disableAnimations ? Duration.zero : GlassTokens.pressDuration;

  double get pressedScale => disableAnimations ? 1.0 : GlassTokens.pressedScale;
}
