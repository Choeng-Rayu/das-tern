import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/colors.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_glass_bottom_sheet.dart';

/// Bottom sheet shown when a freemium limit is hit.
///
/// Shown by catching the `freemium_limit_prescriptions` Postgres exception
/// from the `check_freemium_limits` trigger.
///
/// Spec ref: 03-prescription-medication §7.3.
class FreemiumUpgradeSheet extends StatelessWidget {
  const FreemiumUpgradeSheet({super.key, this.resource = 'prescriptions'});

  final String resource;

  /// Shows the sheet. Returns true if the user tapped Upgrade.
  static Future<bool?> show(BuildContext context, {String resource = 'prescriptions'}) =>
      AppGlassBottomSheet.show<bool>(
        context,
        title: 'Upgrade to Premium',
        child: FreemiumUpgradeSheet(resource: resource),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Icon(Icons.workspace_premium, size: 56, color: AppColors.warning),
        const SizedBox(height: AppSpacing.md),
        Text(
          'You\'ve reached the free plan limit for $resource.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Upgrade to Premium (\$0.50/mo) to create unlimited prescriptions '
          'and unlock all features.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Upgrade to Premium',
          icon: Icons.workspace_premium,
          onPressed: () {
            Navigator.pop(context, true);
            context.push('/settings/subscription');
          },
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Not now',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(context, false),
          fullWidth: true,
        ),
      ],
    );
  }
}

/// Maps a caught exception to a freemium failure and shows the upgrade sheet.
/// Returns true if the error was a freemium limit error (sheet was shown).
Future<bool> handleFreemiumError(
  BuildContext context,
  Object error,
) async {
  final msg = error.toString().toLowerCase();
  if (msg.contains('freemium_limit')) {
    final resource = msg.contains('prescription') ? 'prescriptions' : 'this feature';
    await FreemiumUpgradeSheet.show(context, resource: resource);
    return true;
  }
  return false;
}
