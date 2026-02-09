import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/prescription_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
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
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create prescription
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
                        Text('No prescriptions',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          text: 'Create Prescription',
                          onPressed: () {
                            // TODO: Navigate to create prescription
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
                            // TODO: Navigate to prescription detail
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
                                  _StatusBadge(status: rx.status),
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        color = AppColors.successGreen;
        break;
      case 'DRAFT':
        color = AppColors.warningOrange;
        break;
      case 'PAUSED':
        color = AppColors.neutral400;
        break;
      default:
        color = AppColors.neutral400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
