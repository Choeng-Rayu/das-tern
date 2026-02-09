import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/prescription_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Medications tab – lists active prescriptions and their medications.
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchPrescriptions(status: 'ACTIVE'),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.prescriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 64, color: AppColors.neutral300),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No active prescriptions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Your prescriptions will appear here\nonce added by your doctor.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: provider.prescriptions.length,
                    itemBuilder: (context, index) {
                      final rx = provider.prescriptions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () {
                            // TODO: Navigate to prescription detail
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
                                      color: AppColors.successGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.sm),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${rx.medications.length} medication${rx.medications.length != 1 ? 's' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (rx.notes != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  rx.notes!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              // Medication chips
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: rx.medications.map((m) {
                                  final name =
                                      m.medicationData?['name'] ?? m.medicineName;
                                  return Chip(
                                    label: Text(name,
                                        style: const TextStyle(fontSize: 12)),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
