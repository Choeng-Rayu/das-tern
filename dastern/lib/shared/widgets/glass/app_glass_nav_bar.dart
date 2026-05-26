import 'package:flutter/material.dart';

import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../effects/backdrop_keys.dart';
import '../effects/frosted_surface.dart';

/// A glass navigation destination for [AppGlassNavBar].
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final String label;
  final IconData? selectedIcon;
}

/// Floating glass pill navigation bar.
///
/// The selected item expands to show its label; unselected items show only
/// the icon. Sits above the system nav bar via [SafeArea].
///
/// Spec ref: liquid-glass-flutter SKILL.md §"AppGlassNavBar".
class AppGlassNavBar extends StatelessWidget {
  const AppGlassNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<GlassNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: FrostedSurface(
          borderRadius: AppRadii.allXLarge,
          backdropKey: BackdropKeys.shellHeader,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(destinations.length, (i) {
              final dest = destinations[i];
              final selected = i == selectedIndex;
              return Semantics(
                label: dest.label,
                button: true,
                selected: selected,
                child: GestureDetector(
                  onTap: () => onDestinationSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? AppSpacing.md : AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: selected
                        ? BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.18),
                            borderRadius: AppRadii.allLarge,
                          )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          selected
                              ? (dest.selectedIcon ?? dest.icon)
                              : dest.icon,
                          size: 22,
                          color: selected ? cs.primary : cs.onSurfaceVariant,
                        ),
                        if (selected) ...<Widget>[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            dest.label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: cs.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
