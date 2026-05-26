import 'package:flutter/material.dart';

import '../../../core/theme/tokens/spacing.dart';
import '../buttons/app_button.dart';

/// Empty placeholder shown when a list/screen has nothing to display yet.
///
/// Use a custom [icon] for the most common case; pass an [illustration]
/// widget (e.g. SvgPicture) when a feature has a bespoke empty graphic.
///
/// Spec ref: 09-design-system-localization §Requirement 3, §Requirement 4.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (illustration != null)
              illustration!
            else if (icon != null)
              Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
