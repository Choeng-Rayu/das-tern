import 'package:flutter/material.dart';

import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';

/// Reusable card surface used across the app.
///
/// Slightly raised tonal surface (M3 `surfaceContainer`) with rounded
/// corners and consistent padding. When [onTap] is provided the entire
/// card becomes a tap target with proper material ink + the accessibility
/// hint.
///
/// Spec ref: 09-design-system-localization §Requirement 3.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget surface = Material(
      color: cs.surfaceContainer,
      borderRadius: AppRadii.allMedium,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (semanticLabel == null) return surface;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: surface,
    );
  }
}
