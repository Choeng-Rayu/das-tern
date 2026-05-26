import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/tokens/glass_tokens.dart';

/// Atomic Liquid Glass primitive.
///
/// Every other glass widget in the catalog builds on this one.
/// **Never** call [BackdropFilter] directly inside a feature widget —
/// always go through [FrostedSurface] or one of the composites.
///
/// The blur sigma, tint opacities, border, and shadow all come from
/// [GlassTokens] on the ambient [Theme]. Override [blurSigma] only when
/// a specific surface needs a documented deviation.
///
/// Spec ref: liquid-glass-flutter SKILL.md §"Glass primitive reference".
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = EdgeInsets.zero,
    this.tint,
    this.blurSigma,
    this.backdropKey,
    this.opacity = 1.0,
    this.textHeavy = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final Color? tint;

  /// Override blur sigma. Defaults to `GlassTokens.blurRadius`.
  final double? blurSigma;

  /// Shared key for engine coalescing. Use [BackdropKeys.*].
  /// Passed as the widget [Key] on the [BackdropFilter].
  final Key? backdropKey;

  /// Overall widget opacity (for fade-in animations).
  final double opacity;

  /// Set to `true` when wrapping long-form body text so the tint is
  /// raised automatically for legibility.
  final bool textHeavy;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GlassTokens>()!;
    final cs = Theme.of(context).colorScheme;
    final actualTint = tint ?? cs.surface;
    final sigma = blurSigma ?? tokens.blurRadius;

    // Raise tint opacity for text-heavy surfaces.
    final bonus = textHeavy ? 0.05 : 0.0;
    final hi = (tokens.tintHigh + bonus).clamp(0.0, 0.95);
    final lo = (tokens.tintLow + bonus).clamp(0.0, 0.95);

    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: tokens.shadowColor,
              blurRadius: tokens.shadowBlur,
              offset: tokens.shadowOffset,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            key: backdropKey,
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    actualTint.withValues(alpha: hi),
                    actualTint.withValues(alpha: lo),
                  ],
                ),
                border: Border.all(
                  color: tokens.borderColor,
                  width: tokens.borderWidth,
                ),
                borderRadius: borderRadius,
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
