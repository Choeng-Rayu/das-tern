import 'package:flutter/material.dart';

import 'package:das_tern_mcp/core/widgets/app_badge.dart';
import 'package:das_tern_mcp/core/widgets/app_button.dart';
import 'package:das_tern_mcp/core/widgets/app_card.dart';
import 'package:das_tern_mcp/core/widgets/app_empty_view.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/data/models/prescription.dart';
import 'package:das_tern_mcp/ui/prescription/prescription_list_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

/// Displays the list of prescriptions.
class PrescriptionListView extends StatefulWidget {
  const PrescriptionListView({
    super.key,
    required this.viewModel,
    this.onCreateTap,
    this.onPrescriptionTap,
  });

  final PrescriptionListViewModel viewModel;

  /// Called when the FAB / add button is tapped.
  final VoidCallback? onCreateTap;

  /// Called when a prescription row is tapped. Receives the prescription id.
  final ValueChanged<String>? onPrescriptionTap;

  @override
  State<PrescriptionListView> createState() => _PrescriptionListViewState();
}

class _PrescriptionListViewState extends State<PrescriptionListView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadPrescriptions();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        if (vm.isLoading) {
          return const AppScaffold(
            title: 'Prescriptions',
            showBottomNav: false,
            body: AppLoadingView(),
          );
        }

        if (vm.hasError) {
          return AppScaffold(
            title: 'Prescriptions',
            showBottomNav: false,
            body: AppErrorView(
              message: vm.errorMessage ?? 'Something went wrong.',
              onRetry: vm.loadPrescriptions,
            ),
          );
        }

        if (vm.isEmpty) {
          return AppScaffold(
            title: 'Prescriptions',
            showBottomNav: false,
            floatingActionButton: _buildFab(),
            body: const AppEmptyView(
              message: 'No prescriptions yet.',
              icon: Icons.description_outlined,
              subtitle: 'Tap + to add your first prescription.',
            ),
          );
        }

        return AppScaffold(
          title: 'Prescriptions',
          showBottomNav: false,
          floatingActionButton: _buildFab(),
          body: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: vm.prescriptions.length,
            itemBuilder: (context, index) {
              final prescription = vm.prescriptions[index];
              return _PrescriptionCard(
                prescription: prescription,
                onTap: () => widget.onPrescriptionTap?.call(prescription.id),
                onDelete: () => vm.deletePrescription(prescription.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: widget.onCreateTap,
      backgroundColor: AppColors.primaryBlue,
      child: const Icon(Icons.add, color: AppColors.white),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    this.onTap,
    this.onDelete,
  });

  final Prescription prescription;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prescription.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _statusBadge(prescription.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (prescription.startDate != null)
              Text(
                'Started: ${_formatDate(prescription.startDate!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Delete',
                  variant: AppButtonVariant.destructive,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return AppBadge.active();
      case PrescriptionStatus.paused:
        return AppBadge.paused();
      case PrescriptionStatus.inactive:
      case PrescriptionStatus.draft:
        return AppBadge(
          label: status.name[0].toUpperCase() + status.name.substring(1),
          color: AppColors.neutralGray,
        );
    }
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
