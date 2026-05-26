import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/tokens/radii.dart';

/// Frosted-glass surface inspired by the iOS-26 visual language.
///
/// Wraps [child] with a backdrop blur + translucent surface tint. Use it
/// for sticky headers, bottom bars, and modal sheets where a glass effect
/// would feel right. Don't reach for it as a default — it is GPU-heavy on
/// older Android devices.
///
/// Spec ref: 09-design-system-localization §Requirement 11.
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.blur = 24,
    this.borderRadius = AppRadii.allLarge,
  });

  final Widget child;
  final double blur;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.7),
            borderRadius: borderRadius,
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}
