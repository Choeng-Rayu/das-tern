import 'package:flutter/material.dart';

/// Design tokens for the Liquid Glass visual language.
///
/// Consumed exclusively through `Theme.of(context).extension<GlassTokens>()!`.
/// Never hardcode blur sigmas, tint opacities, or shadow values in widget bodies.
///
/// Spec ref: liquid-glass-flutter SKILL.md §"Glass primitive reference".
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
    required this.meshOpacity,
  });

  final double blurRadius;
  final double tintHigh; // top-left gradient stop opacity
  final double tintLow; // bottom-right gradient stop opacity
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;
  final double meshOpacity; // AppMeshBackground overall opacity

  // ── Presets ──────────────────────────────────────────────────────────

  static const GlassTokens light = GlassTokens(
    blurRadius: 24,
    tintHigh: 0.72,
    tintLow: 0.52,
    borderColor: Color(0x33FFFFFF),
    borderWidth: 1.0,
    shadowColor: Color(0x1A000000),
    shadowBlur: 20,
    shadowOffset: Offset(0, 6),
    meshOpacity: 0.55,
  );

  static const GlassTokens dark = GlassTokens(
    blurRadius: 28,
    tintHigh: 0.60,
    tintLow: 0.40,
    borderColor: Color(0x22FFFFFF),
    borderWidth: 0.8,
    shadowColor: Color(0x33000000),
    shadowBlur: 24,
    shadowOffset: Offset(0, 8),
    meshOpacity: 0.45,
  );

  // ── ThemeExtension boilerplate ────────────────────────────────────────

  @override
  GlassTokens copyWith({
    double? blurRadius,
    double? tintHigh,
    double? tintLow,
    Color? borderColor,
    double? borderWidth,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
    double? meshOpacity,
  }) =>
      GlassTokens(
        blurRadius: blurRadius ?? this.blurRadius,
        tintHigh: tintHigh ?? this.tintHigh,
        tintLow: tintLow ?? this.tintLow,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        shadowColor: shadowColor ?? this.shadowColor,
        shadowBlur: shadowBlur ?? this.shadowBlur,
        shadowOffset: shadowOffset ?? this.shadowOffset,
        meshOpacity: meshOpacity ?? this.meshOpacity,
      );

  @override
  GlassTokens lerp(GlassTokens? other, double t) {
    if (other == null) return this;
    return GlassTokens(
      blurRadius: lerpDouble(blurRadius, other.blurRadius, t)!,
      tintHigh: lerpDouble(tintHigh, other.tintHigh, t)!,
      tintLow: lerpDouble(tintLow, other.tintLow, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      shadowBlur: lerpDouble(shadowBlur, other.shadowBlur, t)!,
      shadowOffset: Offset.lerp(shadowOffset, other.shadowOffset, t)!,
      meshOpacity: lerpDouble(meshOpacity, other.meshOpacity, t)!,
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
