import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Grace period settings screen – patient sets how many minutes before
/// a missed dose triggers caregiver alerts.
class GracePeriodSettingsScreen extends StatefulWidget {
  const GracePeriodSettingsScreen({super.key});

  @override
  State<GracePeriodSettingsScreen> createState() =>
      _GracePeriodSettingsScreenState();
}

class _GracePeriodSettingsScreenState extends State<GracePeriodSettingsScreen> {
  int _selectedMinutes = 30;
  bool _isSaving = false;

  static const _options = [
    _GracePeriodOption(
      minutes: 10,
      label: '10 នាទី',
      description: 'ជូនដំណឹងភ្លាមបន្ទាប់ពីខកខាន',
      icon: Icons.timer,
    ),
    _GracePeriodOption(
      minutes: 20,
      label: '20 នាទី',
      description: 'ផ្តល់ពេលបន្តិចសម្រាប់ការពន្យឺត',
      icon: Icons.timer,
    ),
    _GracePeriodOption(
      minutes: 30,
      label: '30 នាទី',
      description: 'ការកំណត់ដើម (ណែនាំ)',
      icon: Icons.timer,
      isRecommended: true,
    ),
    _GracePeriodOption(
      minutes: 60,
      label: '1 ម៉ោង',
      description: 'ផ្តល់ពេលវេលាបន្ថែម',
      icon: Icons.timer,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Load current grace period from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSetting();
    });
  }

  Future<void> _loadCurrentSetting() async {
    // Could fetch from API; for now use default 30
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final provider = context.read<ConnectionProvider>();
      final success = await provider.updateGracePeriod(_selectedMinutes);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('បានរក្សាទុកការកំណត់'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'បរាជ័យក្នុងការរក្សាទុក'),
              backgroundColor: AppColors.alertRed,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ពេលវេលាផុតកំណត់'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: RadioGroup<int>(
            groupValue: _selectedMinutes,
            onChanged: (v) {
              if (v != null) setState(() => _selectedMinutes = v);
            },
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: AppColors.primaryBlue, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ពេលវេលាអនុគ្រោះ',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ពេលវេលារង់ចាំមុនពេលជូនដំណឹងគ្រួសារ\nពីថ្នាំដែលខកខាន',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Options
              ...List.generate(_options.length, (index) {
                final option = _options[index];
                final isSelected = _selectedMinutes == option.minutes;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildOptionCard(context, option, isSelected),
                );
              }),

              const Spacer(),

              // Save button
              PrimaryButton(
                text: 'រក្សាទុក',
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    _GracePeriodOption option,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMinutes = option.minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.neutral300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Radio<int>.adaptive(
              value: option.minutes,
              activeColor: AppColors.primaryBlue,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.label,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (option.isRecommended) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ណែនាំ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
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
          ],
        ),
      ),
    );
  }
}

class _GracePeriodOption {
  final int minutes;
  final String label;
  final String description;
  final IconData icon;
  final bool isRecommended;

  const _GracePeriodOption({
    required this.minutes,
    required this.label,
    required this.description,
    required this.icon,
    this.isRecommended = false,
  });
}
