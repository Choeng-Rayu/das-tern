import 'package:flutter/material.dart';
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

  static const _levels = [
    _LevelOption(
      level: PermissionLevel.request,
      title: 'មើលប៉ុណ្ណោះ',
      titleEn: 'View Only',
      description: 'គ្រួសារអាចមើលតារាងថ្នាំប៉ុណ្ណោះ',
      descriptionEn: 'Caregiver can only view medication schedules',
      icon: Icons.visibility,
      color: AppColors.primaryBlue,
    ),
    _LevelOption(
      level: PermissionLevel.selected,
      title: 'មើល + រំលឹក',
      titleEn: 'View + Remind',
      description: 'គ្រួសារអាចមើលនិងផ្ញើការរំលឹក',
      descriptionEn: 'Caregiver can view and send nudge reminders',
      icon: Icons.notifications_active,
      color: AppColors.warningOrange,
    ),
    _LevelOption(
      level: PermissionLevel.allowed,
      title: 'មើល + គ្រប់គ្រង',
      titleEn: 'View + Manage',
      description: 'គ្រួសារអាចមើល រំលឹក និងកែប្រែតារាង',
      descriptionEn: 'Caregiver can view, remind and edit schedules',
      icon: Icons.edit_note,
      color: AppColors.successGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('កម្រិតការចូលប្រើ'),
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
                'ជ្រើសរើសកម្រិតការចូលប្រើ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'អ្នកអាចផ្លាស់ប្តូរកម្រិតនេះនៅពេលក្រោយ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Permission level options
              ...List.generate(_levels.length, (index) {
                final option = _levels[index];
                final isSelected = _selectedLevel == option.level;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildLevelCard(context, option, isSelected),
                );
              }),

              const Spacer(),

              // Continue button
              PrimaryButton(
                text: 'បន្ត',
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
  final String titleEn;
  final String description;
  final String descriptionEn;
  final IconData icon;
  final Color color;

  const _LevelOption({
    required this.level,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.icon,
    required this.color,
  });
}
