import 'package:flutter/material.dart';

import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../effects/backdrop_keys.dart';
import '../effects/frosted_surface.dart';

/// Glass app bar — large title + optional subtitle, blurs scroll-under content.
///
/// Implements [PreferredSizeWidget] so it can be passed directly to
/// [Scaffold.appBar].
///
/// Spec ref: liquid-glass-flutter SKILL.md §"AppGlassHeader".
class AppGlassHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppGlassHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  /// When true renders a large-title style (48 dp tall instead of 56 dp).
  final bool large;

  @override
  Size get preferredSize => Size.fromHeight(large ? 80 : 56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FrostedSurface(
      borderRadius: BorderRadius.zero,
      backdropKey: BackdropKeys.shellHeader,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: large
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (actions != null) ...?actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact glass card used inside [AppGlassHeader] for inline chips.
class AppGlassHeaderChip extends StatelessWidget {
  const AppGlassHeaderChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FrostedSurface(
        borderRadius: AppRadii.allLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) Icon(icon!, size: 14),
            if (icon != null) const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
