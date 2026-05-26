import 'package:flutter/material.dart';

import '../../../core/theme/tokens/spacing.dart';

/// Reusable loading placeholder.
///
/// Use the default for full-screen loads. When embedding inside a smaller
/// surface, set [compact] to true so the spinner doesn't dominate.
///
/// Spec ref: 09-design-system-localization §Requirement 3.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message, this.compact = false});

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: compact ? 24 : 32,
              height: compact ? 24 : 32,
              child: const CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
