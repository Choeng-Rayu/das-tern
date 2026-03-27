// lib/core/widgets/app_button.dart
//
// RxCam Global Widget System — Glass Button
// iOS 26 Liquid Glass aesthetic — four variants, spring physics
//
// Requirements: 9.1–9.14

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_glass_panel.dart';

/// Button variant enum — four visual styles. (Req 9.1)
enum AppButtonVariant { primary, secondary, destructive, ghost }

/// Glass button with spring-physics scale animation on press.
///
/// | Variant     | Tint                    | Label colour            |
/// |-------------|-------------------------|-------------------------|
/// | primary     | `AppColors.glassPrimary`| `AppColors.primary`     |
/// | secondary   | `colors.glassWhite`     | `colors.textPrimary`    |
/// | destructive | `AppColors.glassDanger` | `AppColors.danger`      |
/// | ghost       | transparent             | `colors.textSecondary`  |
///
/// **Spring animation (Req 9.8):** 160 ms, easeOutBack, scale 1.0 → 0.94 on press.
/// **Disabled (Req 9.10):** opacity 0.5 when [onPressed] is null.
/// **Loading (Req 9.9):** replaces label with [CircularProgressIndicator].
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  /// Expands to fill available width when true (Req 9.11)
  final bool isFullWidth;

  /// Optional icon rendered 18 dp to the left of the label (Req 9.12)
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startPress(_) => _controller.forward();
  void _endPress(_) => _controller.reverse();
  void _endPressCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Variant colour matrix (Req 9.2–9.7)
    final Color resolvedTint;
    final Color resolvedLabelColor;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        resolvedTint = AppColors.glassPrimary;
        resolvedLabelColor = AppColors.primary;
      case AppButtonVariant.secondary:
        resolvedTint = colors.glassWhite;
        resolvedLabelColor = colors.textPrimary;
      case AppButtonVariant.destructive:
        resolvedTint = AppColors.glassDanger;
        resolvedLabelColor = AppColors.danger;
      case AppButtonVariant.ghost:
        resolvedTint = Colors.transparent;
        resolvedLabelColor = colors.textSecondary;
    }

    return Opacity(
      // 50% opacity when disabled (Req 9.10)
      opacity: widget.onPressed == null ? 0.5 : 1.0,
      child: GestureDetector(
        onTapDown: _startPress,
        onTapUp: _endPress,
        onTapCancel: _endPressCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (_, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: AppGlassPanel(
            tint: resolvedTint,
            borderRadius: AppSpacing.radiusFull, // pill shape (Req 9.14)
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, // 24 dp (Req 9.13)
              vertical: 12, // 12 dp × 2 + ~20 dp text = 44 dp
            ),
            child: SizedBox(
              width: widget.isFullWidth ? double.infinity : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    // Loading spinner replaces label (Req 9.9)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else ...[
                    // Icon 18 dp to the left of label (Req 9.12)
                    if (widget.icon != null) ...[
                      Icon(widget.icon!, color: resolvedLabelColor, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: resolvedLabelColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
