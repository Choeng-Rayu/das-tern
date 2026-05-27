import 'package:flutter/material.dart';

import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../effects/backdrop_keys.dart';
import '../effects/frosted_surface.dart';

/// Glass-styled modal bottom sheet.
/// Spec ref: 10-frontend-liquid-glass §5.7.
class AppGlassBottomSheet extends StatelessWidget {
  const AppGlassBottomSheet({
    super.key,
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  /// Shows the bottom sheet.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => AppGlassBottomSheet(title: title, child: child),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FrostedSurface(
      borderRadius: AppRadii.topXLarge,
      backdropKey: BackdropKeys.modal,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: AppRadii.allSmall,
              ),
            ),
          ),
          if (title != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(title!, style: theme.textTheme.titleLarge),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
