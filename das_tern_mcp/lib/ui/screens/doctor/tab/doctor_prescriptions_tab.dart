import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/prescription_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../../utils/app_router.dart';
import '../../widgets/common_widgets.dart';

/// Doctor prescriptions tab – manage all prescriptions.
class DoctorPrescriptionsTab extends StatefulWidget {
  const DoctorPrescriptionsTab({super.key});

  @override
  State<DoctorPrescriptionsTab> createState() => _DoctorPrescriptionsTabState();
}

class _DoctorPrescriptionsTabState extends State<DoctorPrescriptionsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().fetchPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppHeader(
        title: l10n.prescriptions,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.doctorCreatePrescription);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchPrescriptions(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.prescriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 64, color: AppColors.neutral300),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.noPrescriptions,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          text: l10n.createPrescription,
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.doctorCreatePrescription);
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: provider.prescriptions.length,
                    itemBuilder: (context, index) {
                      final rx = provider.prescriptions[index];
                      final patientName = rx.patient != null
                          ? '${rx.patient!['firstName'] ?? ''} ${rx.patient!['lastName'] ?? ''}'.trim()
                          : rx.patientName;
                      return Padding(
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
                                  Expanded(
                                    child: Text(
                                      patientName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  StatusBadge(
                                    label: rx.status.toUpperCase(),
                                    color: _prescriptionStatusColor(rx.status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${rx.medications.length} medication${rx.medications.length != 1 ? 's' : ''} · v${rx.currentVersion}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
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

Color _prescriptionStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      return AppColors.successGreen;
    case 'DRAFT':
      return AppColors.warningOrange;
    case 'PAUSED':
      return AppColors.neutral400;
    default:
      return AppColors.neutral400;
  }
}
