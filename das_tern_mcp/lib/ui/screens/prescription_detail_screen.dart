import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/prescription_provider.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final String prescriptionId;
  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PrescriptionProvider>().fetchPrescription(widget.prescriptionId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();
    final auth = context.watch<AuthProvider>();
    final rx = provider.selectedPrescription;
    final isDoctor = auth.user?['role'] == 'DOCTOR';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prescriptionDetails)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rx == null
              ? Center(child: Text(l10n.notFound))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(rx.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          rx.status,
                          style: TextStyle(
                            color: _statusColor(rx.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Patient info
                      _InfoRow(l10n.patient, rx.patientName),
                      _InfoRow(l10n.symptomsLabel, rx.symptoms),
                      if (rx.diagnosis != null)
                        _InfoRow(l10n.diagnosis, rx.diagnosis!),
                      if (rx.clinicalNote != null)
                        _InfoRow(l10n.clinicalNote, rx.clinicalNote!),
                      if (rx.doctorLicenseNumber != null)
                        _InfoRow(l10n.licenseNumber, rx.doctorLicenseNumber!),
                      if (rx.followUpDate != null)
                        _InfoRow(l10n.followUpLabel,
                            '${rx.followUpDate!.day}/${rx.followUpDate!.month}/${rx.followUpDate!.year}'),
                      _InfoRow(l10n.versionLabel, 'v${rx.currentVersion}'),

                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.medicines,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: AppSpacing.sm),

                      ...rx.medications.map((med) => Card(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med.medicineName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  if (med.medicineNameKhmer.isNotEmpty)
                                    Text(med.medicineNameKhmer,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text('${l10n.frequency}: ${med.frequency}'),
                                  Text('${l10n.timing}: ${med.timing}'),
                                  if (med.duration != null)
                                    Text('${l10n.durationDays}: ${med.duration} ${l10n.days}'),
                                  if (med.description != null)
                                    Text('${l10n.descriptionLabel}: ${med.description}'),
                                ],
                              ),
                            ),
                          )),

                      const SizedBox(height: AppSpacing.lg),

                      // Action buttons
                      if (!isDoctor && rx.status == 'PENDING_CONFIRMATION')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await provider
                                      .confirmPrescription(rx.id!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.successGreen,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(l10n.confirm),
                              ),
                            ),
                          ],
                        ),

                      if (!isDoctor && rx.status == 'ACTIVE')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    provider.pausePrescription(rx.id!),
                                child: Text(l10n.pauseButton),
                              ),
                            ),
                          ],
                        ),

                      if (!isDoctor && rx.status == 'PAUSED')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    provider.resumePrescription(rx.id!),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(l10n.resumeButton),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.successGreen;
      case 'PENDING_CONFIRMATION':
        return AppColors.warningOrange;
      case 'PAUSED':
        return AppColors.neutralGray;
      case 'REJECTED':
        return AppColors.alertRed;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
