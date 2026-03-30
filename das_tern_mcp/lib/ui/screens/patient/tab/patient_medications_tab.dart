import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/dose_event_model/dose_event.dart';
import '../../../../providers/dose_provider.dart';
import '../../../../providers/prescription_provider.dart';
import '../../../../providers/batch_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../../core/router/app_router.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/dose_task_card.dart';
import '../../../widgets/header_widgets.dart';
import '../../../widgets/loading/health_loading_indicator.dart';

/// Medications tab – lists active prescriptions, batch groups, and their medications.
class PatientMedicationsTab extends StatefulWidget {
  final String? period; // optional: MORNING|AFTERNOON|EVENING|NIGHT
  const PatientMedicationsTab({super.key, this.period});

  @override
  State<PatientMedicationsTab> createState() => _PatientMedicationsTabState();
}

class _PatientMedicationsTabState extends State<PatientMedicationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().fetchPrescriptions();
      context.read<BatchProvider>().fetchBatches();
      // If opened with a specific period, ensure doses are loaded
      if (widget.period != null) {
        // DoseProvider is defined in the app – fetch today's schedule
        try {
          context.read<DoseProvider>().fetchTodaySchedule();
        } catch (_) {
          // DoseProvider may not be available in some contexts; ignore
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();
    final batchProvider = context.watch<BatchProvider>();
    // If period specified, try to get doses from DoseProvider
    final period = widget.period;
    List<DoseEvent>? periodDoses;
    if (period != null) {
      try {
        final doseProv = context.watch<DoseProvider>();
        periodDoses = doseProv.todaysDoses
            .where((d) => d.timePeriod.toUpperCase() == period)
            .toList();
      } catch (_) {
        periodDoses = null;
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'medications_tab_fab',
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.medicationChoice);
        },
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.createPrescription),
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchPrescriptions();
          await batchProvider.fetchBatches();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Sticky header ──
            PatientHeader(title: l10n.medications, showBackButton: false),

            // ── Content ──
            if (provider.isLoading && batchProvider.isLoading)
              SliverFillRemaining(
                child: Center(
                  child: HealthLoadingIndicator(
                    variant: HealthLoadingVariant.pills,
                    size: HealthLoadingSize.large,
                    message: l10n.loadingMedications,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pending Prescriptions Section (DRAFT from doctor)
                      ..._buildPendingSection(context, l10n, provider),

                      // Batch Groups Section
                      if (batchProvider.batches.isNotEmpty) ...[
                        Text(
                          l10n.batchGroupsTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...batchProvider.batches.map(
                          (batch) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        ?.copyWith(
                                          color: AppColors.primaryBlue,
                                        ),
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

                      // Prescriptions Section (ACTIVE only)
                      if (period == null &&
                          provider.prescriptions
                              .where((p) => p.status == 'ACTIVE')
                              .isNotEmpty) ...[
                        Text(
                          l10n.prescriptions,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...provider.prescriptions
                            .where((p) => p.status == 'ACTIVE')
                            .map(
                              (rx) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: AppCard(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.prescriptionDetail,
                                      arguments: {'prescriptionId': rx.id},
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              borderRadius:
                                                  BorderRadius.circular(
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () =>
                                                _confirmDeletePrescription(
                                                  context,
                                                  rx.id ?? '',
                                                ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: AppColors.alertRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        l10n.medicationCountLabel(
                                          rx.medications.length,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (rx.notes != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          rx.notes!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
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
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],

                      // If opened for a specific period, show filtered doses list
                      if (period != null) ...[
                        Builder(
                          builder: (context) {
                            final allPeriodDoses = periodDoses ?? [];
                            final pending = allPeriodDoses
                                .where(
                                  (d) =>
                                      d.status != 'TAKEN_ON_TIME' &&
                                      d.status != 'TAKEN_LATE' &&
                                      d.status != 'SKIPPED',
                                )
                                .toList();
                            final done = allPeriodDoses
                                .where(
                                  (d) =>
                                      d.status == 'TAKEN_ON_TIME' ||
                                      d.status == 'TAKEN_LATE' ||
                                      d.status == 'SKIPPED',
                                )
                                .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.medications,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    if (pending.isNotEmpty)
                                      TextButton(
                                        onPressed: () => _showMarkAllDoneSheet(
                                          context,
                                          pending,
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppColors.primaryBlue,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: const Size(0, 32),
                                        ),
                                        child: Text(
                                          l10n.markAllDone,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),

                                if (periodDoses == null)
                                  Center(
                                    child: HealthLoadingIndicator(
                                      variant: HealthLoadingVariant.pills,
                                      size: HealthLoadingSize.medium,
                                      message: l10n.loadingMedications,
                                    ),
                                  )
                                else if (allPeriodDoses.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.xxl,
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            size: 48,
                                            color: AppColors.successGreen,
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            l10n.noMoreMedicationsToday,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else ...[
                                  if (pending.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                      ),
                                      child: Text(
                                        l10n.noPendingDoses,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  else
                                    ...pending.map(
                                      (dose) => DoseTaskCard(dose: dose),
                                    ),

                                  // ── Collapsible completed section ──
                                  if (done.isNotEmpty)
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        childrenPadding: EdgeInsets.zero,
                                        title: Text(
                                          l10n.completedCount(done.length),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        children: done
                                            .map(
                                              (dose) => DoseTaskCard(
                                                dose: dose,
                                                readOnly: true,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ],
                            );
                          },
                        ),
                      ] else
                      // Empty state
                      if (provider.prescriptions
                              .where((p) => p.status == 'ACTIVE')
                              .isEmpty &&
                          provider.prescriptions
                              .where((p) => p.status == 'DRAFT')
                              .isEmpty &&
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.prescriptionsAppearHere,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
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

  /// Show confirmation sheet for marking multiple doses as taken.
  void _showMarkAllDoneSheet(BuildContext context, List<DoseEvent> pending) {
    final l10n = AppLocalizations.of(context)!;
    final doseProvider = context.read<DoseProvider>();
    final selected = List<bool>.filled(pending.length, true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final checkedCount = selected.where((s) => s).length;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.markAllDone,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      l10n.selectDosesToMark,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pending.length,
                        itemBuilder: (_, i) {
                          final dose = pending[i];
                          final st = dose.scheduledTime;
                          final timeStr =
                              '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';
                          return CheckboxListTile(
                            value: selected[i],
                            onChanged: (v) =>
                                setSheetState(() => selected[i] = v ?? false),
                            title: Text(dose.medicationName),
                            subtitle: Text('${dose.dosage}  ·  $timeStr'),
                            activeColor: AppColors.successGreen,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: checkedCount == 0
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                for (int i = 0; i < pending.length; i++) {
                                  if (selected[i]) {
                                    await doseProvider.markTaken(
                                      pending[i].id ?? '',
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.successGreen
                              .withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: Text(
                          '${l10n.markAllDone} ($checkedCount)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show a confirmation dialog and optionally delete a prescription.
  Future<void> _confirmDeletePrescription(
    BuildContext context,
    String prescriptionId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline,
              color: AppColors.alertRed,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.deletePrescription)),
          ],
        ),
        content: Text(l10n.deletePrescriptionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final prescProv = context.read<PrescriptionProvider>();
    final ok = await prescProv.deletePrescription(prescriptionId);

    if (!context.mounted) return;

    if (ok) {
      // Refresh dose schedule to remove any now-deleted doses
      context.read<DoseProvider>().fetchTodaySchedule();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.prescriptionDeleted),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prescProv.error ?? l10n.error),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  List<Widget> _buildPendingSection(
    BuildContext context,
    AppLocalizations l10n,
    PrescriptionProvider provider,
  ) {
    final pending = provider.prescriptions
        .where((p) => p.status == 'DRAFT')
        .toList();
    if (pending.isEmpty) return [];

    return [
      Text(
        l10n.pendingPrescriptions,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: AppSpacing.sm),
      ...pending.map(
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
                        color: AppColors.warningOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        rx.status.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.warningOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v${rx.currentVersion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          _confirmDeletePrescription(context, rx.id ?? ''),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.alertRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Doctor name
                Text(
                  l10n.prescriptionFromDoctor(
                    rx.doctor?['fullName'] as String? ?? '',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.medicationCountLabel(rx.medications.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: rx.medications.map((m) {
                    final name = m.medicationData?['name'] ?? m.medicineName;
                    return Chip(
                      label: Text(name, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                // Confirm / Reject buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final ok = await provider.rejectPrescription(rx.id!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? l10n.prescriptionRejected
                                      : (provider.error ?? ''),
                                ),
                                backgroundColor: ok ? null : AppColors.alertRed,
                              ),
                            );
                          }
                        },
                        child: Text(l10n.rejectPrescription),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final ok = await provider.confirmPrescription(rx.id!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? l10n.prescriptionConfirmed
                                      : (provider.error ?? ''),
                                ),
                                backgroundColor: ok
                                    ? AppColors.successGreen
                                    : AppColors.alertRed,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.confirmPrescription),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }
}
