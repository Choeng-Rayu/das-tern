import 'package:flutter/material.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

/// Visual variant for [AppButton].
enum AppButtonVariant {
  /// Filled primary action button.
  primary,

  /// Outlined secondary action button.
  secondary,

  /// Filled button with destructive / error colouring.
  destructive,

  /// Transparent, text-only button.
  ghost,
}

/// Design-system button used throughout the app.
///
/// Supports all four [AppButtonVariant]s, an optional [isLoading] state that
/// replaces the label with a [CircularProgressIndicator], full-width mode via
/// [isFullWidth], and an optional leading [icon].
///
/// Usage:
/// ```dart
/// AppButton(
///   label: 'Save',
///   onPressed: _save,
///   variant: AppButtonVariant.primary,
///   isFullWidth: true,
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _indicatorColor(context),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.alertRed,
            foregroundColor: AppColors.white,
          ),
          child: child,
        );
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: 48, child: button);
    }
    return SizedBox(height: 48, child: button);
  }

  Color _indicatorColor(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return AppColors.white;
      case AppButtonVariant.secondary:
        return AppColors.primaryBlue;
      case AppButtonVariant.ghost:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
