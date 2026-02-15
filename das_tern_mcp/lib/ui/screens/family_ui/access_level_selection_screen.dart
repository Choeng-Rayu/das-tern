import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enums_model/enums.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Screen for patient to choose what access level to grant the caregiver.
class AccessLevelSelectionScreen extends StatefulWidget {
  const AccessLevelSelectionScreen({super.key});

  @override
  State<AccessLevelSelectionScreen> createState() =>
      _AccessLevelSelectionScreenState();
}

class _AccessLevelSelectionScreenState
    extends State<AccessLevelSelectionScreen> {
  PermissionLevel _selectedLevel = PermissionLevel.request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final levels = [
      _LevelOption(
        level: PermissionLevel.request,
        title: l10n.viewOnly,
        description: l10n.viewOnlyDescription,
        icon: Icons.visibility,
        color: AppColors.primaryBlue,
      ),
      _LevelOption(
        level: PermissionLevel.selected,
        title: l10n.viewAndRemind,
        description: l10n.viewAndRemindDescription,
        icon: Icons.notifications_active,
        color: AppColors.warningOrange,
      ),
      _LevelOption(
        level: PermissionLevel.allowed,
        title: l10n.viewAndManage,
        description: l10n.viewAndManageDescription,
        icon: Icons.edit_note,
        color: AppColors.successGreen,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accessLevelTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: RadioGroup<PermissionLevel>(
            groupValue: _selectedLevel,
            onChanged: (v) {
              if (v != null) setState(() => _selectedLevel = v);
            },
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectAccessLevel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.accessLevelChangeableLater,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Permission level options
              ...List.generate(levels.length, (index) {
                final option = levels[index];
                final isSelected = _selectedLevel == option.level;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildLevelCard(context, option, isSelected),
                );
              }),

              const Spacer(),

              // Continue button
              PrimaryButton(
                text: l10n.continueButton,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/family/token-display',
                    arguments: {
                      'permissionLevel': _selectedLevel.name.toUpperCase(),
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    _LevelOption option,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = option.level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected ? option.color : AppColors.neutral300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(option.icon, color: option.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Radio<PermissionLevel>.adaptive(
              value: option.level,
              activeColor: option.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelOption {
  final PermissionLevel level;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _LevelOption({
    required this.level,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
