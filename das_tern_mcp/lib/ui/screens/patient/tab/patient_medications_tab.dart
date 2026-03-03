import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/prescription_provider.dart';
import '../../../../providers/batch_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../../utils/app_router.dart';
import '../../../widgets/common_widgets.dart';

/// Medications tab – lists active prescriptions, batch groups, and their medications.
class PatientMedicationsTab extends StatefulWidget {
  const PatientMedicationsTab({super.key});

  @override
  State<PatientMedicationsTab> createState() => _PatientMedicationsTabState();
}

class _PatientMedicationsTabState extends State<PatientMedicationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().fetchPrescriptions(status: 'ACTIVE');
      context.read<BatchProvider>().fetchBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();
    final batchProvider = context.watch<BatchProvider>();

    return Scaffold(
      appBar: AppHeader(title: l10n.medications),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.medicationChoice);
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchPrescriptions(status: 'ACTIVE');
          await batchProvider.fetchBatches();
        },
        child: provider.isLoading && batchProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Batch Groups Section
                  if (batchProvider.batches.isNotEmpty) ...[
                    Text(
                      l10n.batchGroupsTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...batchProvider.batches.map(
                      (batch) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.batchDetail,
                              arguments: {'batchId': batch.id},
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.medication_liquid_outlined,
                                  color: AppColors.successGreen,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      batch.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.batchScheduledTime(
                                        batch.scheduledTime,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                l10n.batchMedicineCount(
                                  batch.medications.length,
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.primaryBlue),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Prescriptions Section
                  if (provider.prescriptions.isNotEmpty) ...[
                    Text(
                      l10n.prescriptions,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...provider.prescriptions.map(
                      (rx) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.prescriptionDetail,
                              arguments: {'prescriptionId': rx.id},
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                    child: Text(
                                      rx.status.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.successGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'v${rx.currentVersion}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.medicationCountLabel(
                                  rx.medications.length,
                                ),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (rx.notes != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  rx.notes!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: rx.medications.map((m) {
                                  final name =
                                      m.medicationData?['name'] ??
                                      m.medicineName;
                                  return Chip(
                                    label: Text(
                                      name,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Empty state
                  if (provider.prescriptions.isEmpty &&
                      batchProvider.batches.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 64,
                              color: AppColors.neutral300,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.noActivePrescriptions,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.prescriptionsAppearHere,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
