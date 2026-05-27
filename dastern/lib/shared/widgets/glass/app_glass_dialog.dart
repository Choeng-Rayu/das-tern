import 'package:flutter/material.dart';

import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../effects/backdrop_keys.dart';
import '../effects/frosted_surface.dart';

/// Glass-styled dialog.
/// Spec ref: 10-frontend-liquid-glass §5.7.
class AppGlassDialog extends StatelessWidget {
  const AppGlassDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
  });

  final String? title;
  final Widget content;
  final List<Widget>? actions;

  /// Shows the dialog and returns the result.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget content,
    List<Widget>? actions,
  }) =>
      showDialog<T>(
        context: context,
        barrierColor: Colors.black38,
        builder: (_) => AppGlassDialog(
          title: title,
          content: content,
          actions: actions,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FrostedSurface(
        borderRadius: AppRadii.allLarge,
        backdropKey: BackdropKeys.modal,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (title != null) ...<Widget>[
              Text(title!, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
            ],
            content,
            if (actions != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: a,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
