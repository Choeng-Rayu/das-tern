import 'package:flutter/material.dart';

import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../buttons/app_button.dart';

/// Reusable error state — used by `AsyncValue.when(error: …)` consumers
/// across the app.
///
/// The [message] is the user-facing string (already localised by the
/// caller). [retryLabel] / [onRetry] are optional and render an action
/// button when both are provided.
///
/// Spec ref: 09-design-system-localization §Requirement 3, §Requirement 8.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.title,
    this.retryLabel,
    this.onRetry,
  });

  final String message;
  final String? title;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              title ?? 'Something went wrong',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (retryLabel != null && onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: retryLabel!,
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
