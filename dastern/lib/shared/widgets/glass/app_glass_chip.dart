import 'package:flutter/material.dart';

import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../effects/frosted_surface.dart';

/// Pill-radius glass chip for status badges and filter chips.
///
/// Spec ref: liquid-glass-flutter SKILL.md §"AppGlassChip".
class AppGlassChip extends StatelessWidget {
  const AppGlassChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData? icon;

  /// Accent colour for the chip. Defaults to `colorScheme.primary`.
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;

    return Semantics(
      label: label,
      button: onTap != null,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: FrostedSurface(
          borderRadius: AppRadii.allLarge,
          tint: selected ? accent : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: selected ? cs.onPrimary : accent),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? cs.onPrimary : accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
