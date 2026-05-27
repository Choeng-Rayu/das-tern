import 'package:flutter/material.dart';

import '../effects/frosted_surface.dart';

/// Round glass floating action button.
/// Spec ref: 10-frontend-liquid-glass §5.6.
class AppGlassFab extends StatelessWidget {
  const AppGlassFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.size = 56,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: FrostedSurface(
          borderRadius: BorderRadius.circular(size / 2),
          tint: cs.primary,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: cs.onPrimary, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}
