import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final AppButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget content = isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final Widget button = switch (variant) {
      case AppButtonVariant.primary:
        FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        ),
      case AppButtonVariant.secondary:
        OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        ),
      case AppButtonVariant.destructive:
        FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red.shade700,
          ),
          child: content,
        ),
      case AppButtonVariant.ghost:
        TextButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        ),
    };

    if (!isFullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
