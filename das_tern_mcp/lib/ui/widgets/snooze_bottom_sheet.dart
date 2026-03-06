import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SnoozeBottomSheet extends StatelessWidget {
  final int currentSnoozeCount;

  const SnoozeBottomSheet({
    super.key,
    this.currentSnoozeCount = 0,
  });

  static Future<int?> show(BuildContext context, {int currentSnoozeCount = 0}) {
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SnoozeBottomSheet(currentSnoozeCount: currentSnoozeCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 3 - currentSnoozeCount;
    final isDisabled = remaining <= 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Snooze Reminder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isDisabled
                ? 'Maximum snooze limit reached (3/3)'
                : '$remaining snooze${remaining == 1 ? '' : 's'} remaining',
            style: TextStyle(
              fontSize: 13,
              color: isDisabled ? AppColors.alertRed : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final duration in [5, 10, 15])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                enabled: !isDisabled,
                leading: const Icon(Icons.snooze),
                title: Text('$duration minutes'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: AppColors.neutral200),
                ),
                onTap: isDisabled ? null : () => Navigator.pop(context, duration),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
