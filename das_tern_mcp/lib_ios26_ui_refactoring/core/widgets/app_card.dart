// lib/core/widgets/app_card.dart
//
// RxCam Global Widget System — Tappable Glass Card
// iOS 26 Liquid Glass aesthetic — spring-physics press animation
//
// Requirements: 11.1–11.8

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_glass_panel.dart';

/// Tappable glass card wrapping [AppGlassPanel].
///
/// When [onTap] is provided, applies a spring-scale animation on press
/// (1.0 → 0.97, 120 ms, easeOutBack) (Req 11.2).
///
/// Without [onTap], renders as a static decorative panel.
///
/// ```dart
/// AppCard(
///   onTap: () => navigateToDetail(),
///   child: MedicationRow(item: item),
/// )
/// ```
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius = AppSpacing.radiusLg,
    this.tint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Defaults to [AppSpacing.radiusLg] (28 dp) (Req 11.5)
  final double borderRadius;

  /// Optional tint override. When null, falls back to [colors.glassWhite].
  final Color? tint;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(AppCard old) {
    super.didUpdateWidget(old);
    // If onTap changed between null/non-null, re-setup animation
    if ((old.onTap == null) != (widget.onTap == null)) {
      _controller?.dispose();
      _controller = null;
      _scaleAnimation = null;
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    if (widget.onTap != null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
      );
      _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeOutBack),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller?.forward();
  void _onTapUp(_) => _controller?.reverse();
  void _onTapCancel() => _controller?.reverse();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final panel = AppGlassPanel(
      borderRadius: widget.borderRadius,
      tint: widget.tint ?? colors.glassWhite,
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
      child: widget.child,
    );

    if (widget.onTap == null) return panel;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation!,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnimation!.value, child: child),
        child: panel,
      ),
    );
  }
}
