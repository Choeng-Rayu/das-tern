import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/prescription_model/prescription.dart';
import '../../../providers/prescription_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Prescription History tab – matches Figma tab: ប្រវិត្តវេជ្ជបញ្ជារ
/// Shows list of all prescriptions created by the doctor.
class DoctorPrescriptionHistoryTab extends StatefulWidget {
  const DoctorPrescriptionHistoryTab({super.key});

  @override
  State<DoctorPrescriptionHistoryTab> createState() =>
      _DoctorPrescriptionHistoryTabState();
}

class _DoctorPrescriptionHistoryTabState
    extends State<DoctorPrescriptionHistoryTab> {
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
      appBar: AppHeader(title: l10n.prescriptionHistory),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchPrescriptions(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.prescriptions.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: provider.prescriptions.length,
                    itemBuilder: (context, index) {
                      final rx = provider.prescriptions[index];
                      return _buildPrescriptionCard(context, rx);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              size: 64, color: AppColors.neutral300),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.noPrescriptionHistory,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.prescriptionsCreatedAppearHere,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(
    BuildContext context,
    Prescription rx,
  ) {
    final patientName = rx.patientName;
    final status = rx.status;
    final date = rx.createdAt.toIso8601String().split('T')[0];
    final medications = rx.medications;

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
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                date,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (medications.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: medications.take(3).map((med) {
                  final name = med.medicineName;
                  return Chip(
                    label: Text(name, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.statusSuccess;
      case 'PENDING':
        return AppColors.statusWarning;
      case 'COMPLETED':
        return AppColors.primaryBlue;
      case 'CANCELLED':
        return AppColors.statusError;
      default:
        return AppColors.neutral400;
    }
  }
}
