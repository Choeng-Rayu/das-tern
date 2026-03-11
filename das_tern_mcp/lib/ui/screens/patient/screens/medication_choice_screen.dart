import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

class MedicationChoiceScreen extends StatelessWidget {
  const MedicationChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.addMedicine),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            // Header icon
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 36,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.chooseCreationMethod,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Create Prescription (Wizard) — primary option
            _ChoiceCard(
              icon: Icons.description_outlined,
              title: l10n.createPrescriptionManual,
              description: l10n.createPrescriptionManualDesc,
              color: AppColors.primaryBlue,
              isPrimary: true,
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.patientPrescriptionWizard,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Scan Prescription
            _ChoiceCard(
              icon: Icons.document_scanner_outlined,
              title: l10n.scanPrescriptionOption,
              description: l10n.scanPrescriptionOptionDesc,
              color: AppColors.successGreen,
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.patientCreateMedicine),
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick Add (Single Medicine)
            _ChoiceCard(
              icon: Icons.medication_outlined,
              title: l10n.quickAddMedicine,
              description: l10n.quickAddMedicineDesc,
              color: const Color(0xFF7E57C2),
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.patientCreateMedicine),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isPrimary ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrimary ? color : color.withValues(alpha: 0.3),
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? color.withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
