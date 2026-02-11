import 'package:flutter/material.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Intro screen for family connection flow.
/// Patient chooses to share their QR or enter a caregiver's code.
class FamilyConnectIntroScreen extends StatelessWidget {
  const FamilyConnectIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ភ្ជាប់គ្រួសារ'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.family_restroom,
                  size: 60,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'ភ្ជាប់ជាមួយគ្រួសារ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'ចែករំលែកព័ត៌មានថ្នាំរបស់អ្នកជាមួយគ្រួសារ\nដើម្បីឱ្យពួកគេអាចជួយត្រួតពិនិត្យ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Patient action: Share QR Code
              _buildOptionCard(
                context,
                icon: Icons.qr_code_2,
                title: 'ចែករំលែកកូដ QR',
                subtitle: 'បង្កើតកូដដើម្បីឱ្យគ្រួសារស្កេន',
                color: AppColors.primaryBlue,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/family/access-level',
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Caregiver action: Scan QR Code
              _buildOptionCard(
                context,
                icon: Icons.qr_code_scanner,
                title: 'ស្កេនកូដ QR',
                subtitle: 'ស្កេនកូដពីអ្នកជំងឺដើម្បីភ្ជាប់',
                color: AppColors.successGreen,
                onTap: () {
                  Navigator.pushNamed(context, '/family/scan');
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Manual code entry
              _buildOptionCard(
                context,
                icon: Icons.keyboard,
                title: 'បញ្ចូលកូដដោយដៃ',
                subtitle: 'បញ្ចូលកូដតភ្ជាប់ ៨ ខ្ទង់',
                color: AppColors.warningOrange,
                onTap: () {
                  Navigator.pushNamed(context, '/family/enter-code');
                },
              ),

              const Spacer(),

              // Info text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'កូដមានសុពលភាព ២៤ ម៉ោង',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.neutral400),
        ],
      ),
    );
  }
}
