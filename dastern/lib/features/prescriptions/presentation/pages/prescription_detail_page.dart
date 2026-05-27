import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/colors.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_glass_card.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/states/error_state.dart';
import '../../../../shared/widgets/states/loading_state.dart';
import '../../domain/prescription.dart';
import '../../domain/prescription_enums.dart';
import '../../domain/usecases/prescription_lifecycle.dart';
import '../providers/prescription_providers.dart';

class PrescriptionDetailPage extends ConsumerWidget {
  const PrescriptionDetailPage({super.key, required this.prescriptionId});

  final String prescriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(prescriptionDetailProvider(prescriptionId));
    final repo = ref.read(prescriptionRepositoryProvider);

    return async.when(
      loading: () => AppScaffold(title: l.savePrescription, body: const LoadingState()),
      error: (e, _) => AppScaffold(
        title: l.savePrescription,
        body: ErrorState(message: e.toString()),
      ),
      data: (Prescription? p) {
        if (p == null) {
          return AppScaffold(
            title: l.savePrescription,
            body: const ErrorState(message: 'Prescription not found'),
          );
        }
        return AppScaffold(
          title: p.patientName,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kToolbarHeight + AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            children: <Widget>[
              if (p.isUrgent)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  color: AppColors.danger.withValues(alpha: 0.12),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.warning_amber, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          p.urgentReason ?? 'Urgent change',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              AppGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Row('Status', p.status.code),
                    _Row('Symptoms', p.symptoms),
                    if (p.diagnosis != null) _Row('Diagnosis', p.diagnosis!),
                    if (p.clinicalNote != null) _Row('Note', p.clinicalNote!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Lifecycle actions
              if (p.status == PrescriptionStatus.active) ...<Widget>[
                AppButton(
                  label: 'Pause',
                  variant: AppButtonVariant.outlined,
                  onPressed: () async {
                    await PausePrescription(repo).call(prescriptionId);
                    ref.invalidate(prescriptionDetailProvider(prescriptionId));
                  },
                  fullWidth: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Stop',
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    await StopPrescription(repo).call(prescriptionId);
                    ref.invalidate(prescriptionDetailProvider(prescriptionId));
                  },
                  fullWidth: true,
                ),
              ],
              if (p.status == PrescriptionStatus.paused)
                AppButton(
                  label: 'Resume',
                  onPressed: () async {
                    await ResumePrescription(repo).call(prescriptionId);
                    ref.invalidate(prescriptionDetailProvider(prescriptionId));
                  },
                  fullWidth: true,
                ),
              if (p.status == PrescriptionStatus.draft) ...<Widget>[
                AppButton(
                  label: 'Confirm',
                  onPressed: () async {
                    await ConfirmPrescription(repo).call(prescriptionId);
                    ref.invalidate(prescriptionDetailProvider(prescriptionId));
                  },
                  fullWidth: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Reject',
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    await RejectPrescription(repo).call(prescriptionId);
                    ref.invalidate(prescriptionDetailProvider(prescriptionId));
                  },
                  fullWidth: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 100,
              child: Text(label,
                  style: Theme.of(context).textTheme.labelMedium),
            ),
            Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
}
