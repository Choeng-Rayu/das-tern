// lib/core/widgets/app_glass_panel.dart
//
// RxCam Global Widget System — Foundation Glass Surface
// iOS 26 Liquid Glass aesthetic
//
// Requirements: 4.1–4.9

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The foundation frosted-glass surface widget used by all glass widgets.
///
/// Renders a `BackdropFilter` blur, specular top-edge border, floating shadow,
/// and a mode-aware gradient fill. Every glass widget in RxCam is built on top
/// of this widget — never compose `BackdropFilter` manually.
///
/// **Invariant (Req 4.9):** The widget tree always contains exactly one
/// `BackdropFilter` node. Nesting `AppGlassPanel` inside another does not
/// produce double-blur — the inner panel's blur is scoped to its own clip.
///
/// ```dart
/// AppGlassPanel(
///   borderRadius: AppSpacing.radiusLg,
///   padding: EdgeInsets.all(AppSpacing.md),
///   child: Text('Hello'),
/// )
/// ```
class AppGlassPanel extends StatelessWidget {
  const AppGlassPanel({
    super.key,
    required this.child,

    /// Corner radius. Defaults to [AppSpacing.radiusLg] (28 dp).
    this.borderRadius = AppSpacing.radiusLg,

    /// Optional tint colour that overrides the default mode-aware gradient fill.
    /// Pass [Colors.transparent] for ghost/no-fill buttons.
    this.tint,

    /// Blur sigma applied to backdrop. Defaults to 20 dp.
    this.blurRadius = 20.0,

    /// Overall widget opacity. Defaults to 1.0.
    this.opacity = 1.0,

    /// Inner padding. Defaults to [EdgeInsets.zero].
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final Color? tint;
  final double blurRadius;
  final double opacity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve the tint colour:
    // - ghost passes Colors.transparent which we honour
    // - null → use Colors.white (same base for both modes; opacities differ)
    final resolvedTint = tint ?? Colors.white;
    final isTransparent = resolvedTint == Colors.transparent;

    // ── Widget tree ──────────────────────────────────────────────────────────
    //
    //  Opacity
    //  └── DecoratedBox (shadow — outside clip so it isn't clipped)
    //      └── ClipRRect
    //          └── BackdropFilter (EXACTLY ONE per AppGlassPanel)
    //              └── DecoratedBox (gradient + top specular border)
    //                  └── Padding
    //                      └── child
    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colors.glassShadowColor,
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Gradient fill — transparent tint skips the gradient (ghost)
                gradient: isTransparent
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          resolvedTint.withValues(alpha: isDark ? 0.18 : 0.60),
                          resolvedTint.withValues(alpha: isDark ? 0.06 : 0.40),
                        ],
                      ),
                // Specular top-edge border (Req 4.2)
                border: Border(
                  top: BorderSide(color: colors.glassBorder, width: 0.8),
                ),
              ),
              child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
