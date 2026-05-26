import 'package:flutter/material.dart';
import 'package:das_tern_mcp/core/widgets/app_badge.dart';
import 'package:das_tern_mcp/core/widgets/app_card.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/data/models/prescription.dart';
import 'package:das_tern_mcp/ui/prescription/prescription_detail_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

class PrescriptionDetailView extends StatefulWidget {
  const PrescriptionDetailView({super.key, required this.viewModel});
  final PrescriptionDetailViewModel viewModel;

  @override
  State<PrescriptionDetailView> createState() =>
      _PrescriptionDetailViewState();
}

class _PrescriptionDetailViewState extends State<PrescriptionDetailView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadPrescription();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        if (vm.isLoading) {
          return const AppScaffold(
            title: 'Prescription',
            showBackButton: true,
            showBottomNav: false,
            body: AppLoadingView(),
          );
        }
        if (vm.hasError) {
          return AppScaffold(
            title: 'Prescription',
            showBackButton: true,
            showBottomNav: false,
            body: AppErrorView(
              message: vm.errorMessage ?? 'Failed to load.',
              onRetry: vm.loadPrescription,
            ),
          );
        }
        final p = vm.prescription;
        if (p == null) {
          return const AppScaffold(
            title: 'Prescription',
            showBackButton: true,
            showBottomNav: false,
            body: AppErrorView(message: 'Prescription not found.'),
          );
        }
        return AppScaffold(
          title: 'Prescription Details',
          showBackButton: true,
          showBottomNav: false,
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _statusBadge(p.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (p.startDate != null)
                      _InfoRow(label: 'Start', value: _fmt(p.startDate!)),
                    if (p.endDate != null)
                      _InfoRow(label: 'End', value: _fmt(p.endDate!)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (p.medications.isNotEmpty) ...[
                Text(
                  'Medications',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...p.medications.map(
                  (m) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: AppCard(
                      hasShadow: false,
                      child: Row(
                        children: [
                          const Icon(Icons.medication,
                              color: AppColors.primaryBlue),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${m.name} — ${m.dosage} ${m.unit}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return AppBadge.active();
      case PrescriptionStatus.paused:
        return AppBadge.paused();
      default:
        return AppBadge.completed(
          label: status.name[0].toUpperCase() + status.name.substring(1),
        );
    }
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
