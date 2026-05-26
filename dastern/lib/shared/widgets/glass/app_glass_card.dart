import 'package:flutter/material.dart';

import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../effects/frosted_surface.dart';

/// Tappable glass card — the primary list/detail surface.
///
/// Spec ref: liquid-glass-flutter SKILL.md §"AppGlassCard".
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppRadii.allMedium,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: FrostedSurface(
          borderRadius: borderRadius,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
