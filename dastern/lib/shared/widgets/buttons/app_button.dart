import 'package:flutter/material.dart';

import '../../../core/theme/tokens/colors.dart';

/// Variants supported by [AppButton].
enum AppButtonVariant {
  /// Solid background, primary call-to-action.
  filled,

  /// Outlined; secondary action.
  outlined,

  /// Text-only; tertiary or destructive in a non-emphasised slot.
  text,

  /// Solid red background; destructive primary action.
  danger,
}

/// Sizes supported by [AppButton]. Heights map to consistent tap targets;
/// the `regular` size already meets the 48px accessibility target.
enum AppButtonSize { compact, regular, large }

/// Reusable button widget.
///
/// Wraps Material's `ElevatedButton`/`OutlinedButton`/`TextButton` with the
/// app's tokens (radius, padding, typography) and adds:
/// - a [loading] state that swaps the label for a spinner;
/// - a [danger] variant for destructive actions;
/// - automatic icon spacing.
///
/// Spec ref: 09-design-system-localization §Requirement 3.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  double get _height => switch (size) {
    AppButtonSize.compact => 40,
    AppButtonSize.regular => 48,
    AppButtonSize.large => 56,
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool disabled = onPressed == null || loading;

    final Widget child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.danger
                    ? Colors.white
                    : cs.onPrimary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final VoidCallback? cb = disabled ? null : onPressed;
    final Size minSize = Size(fullWidth ? double.infinity : 0, _height);

    final Widget button = switch (variant) {
      AppButtonVariant.filled => ElevatedButton(
        onPressed: cb,
        style: ElevatedButton.styleFrom(minimumSize: minSize),
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: cb,
        style: OutlinedButton.styleFrom(minimumSize: minSize),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: cb,
        style: TextButton.styleFrom(minimumSize: minSize),
        child: child,
      ),
      AppButtonVariant.danger => ElevatedButton(
        onPressed: cb,
        style: ElevatedButton.styleFrom(
          minimumSize: minSize,
          backgroundColor: AppColors.danger,
          foregroundColor: AppColors.white,
        ),
        child: child,
      ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
