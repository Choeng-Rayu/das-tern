import 'package:flutter/material.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

/// Design-system card with optional tap handling, configurable padding, and
/// an optional shadow toggle.
///
/// Wraps Flutter's [Card] and applies an [InkWell] when [onTap] is provided.
///
/// Usage:
/// ```dart
/// AppCard(
///   onTap: () => _openDetail(),
///   child: Text('Card content'),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.hasShadow = true,
    this.margin,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool hasShadow;
  final EdgeInsets? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);

    return Card(
      elevation: hasShadow ? 2 : 0,
      margin: margin,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}
