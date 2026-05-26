import 'package:flutter/material.dart';
import 'package:das_tern_mcp/core/widgets/app_card.dart';
import 'package:das_tern_mcp/core/widgets/app_empty_view.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/ui/medication/medication_list_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

class MedicationListView extends StatefulWidget {
  const MedicationListView({
    super.key,
    required this.viewModel,
    this.onAddTap,
  });
  final MedicationListViewModel viewModel;
  final VoidCallback? onAddTap;

  @override
  State<MedicationListView> createState() => _MedicationListViewState();
}

class _MedicationListViewState extends State<MedicationListView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        if (vm.isLoading) {
          return const AppScaffold(
            title: 'Medications',
            showBottomNav: false,
            showBackButton: true,
            body: AppLoadingView(),
          );
        }
        if (vm.hasError) {
          return AppScaffold(
            title: 'Medications',
            showBottomNav: false,
            showBackButton: true,
            body: AppErrorView(
              message: vm.errorMessage ?? 'Error loading medications.',
              onRetry: vm.loadMedications,
            ),
          );
        }
        if (vm.isEmpty) {
          return AppScaffold(
            title: 'Medications',
            showBottomNav: false,
            showBackButton: true,
            floatingActionButton: _fab(),
            body: const AppEmptyView(
              message: 'No medications yet.',
              icon: Icons.medication_outlined,
            ),
          );
        }
        return AppScaffold(
          title: 'Medications',
          showBottomNav: false,
          showBackButton: true,
          floatingActionButton: _fab(),
          body: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: vm.medications.length,
            itemBuilder: (_, i) {
              final med = vm.medications[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: AppCard(
                  child: ListTile(
                    leading: const Icon(Icons.medication,
                        color: AppColors.primaryBlue),
                    title: Text(med.name),
                    subtitle: Text('${med.dosage} ${med.unit} × ${med.frequency}/day'),
                    trailing: med.isActive
                        ? const Icon(Icons.check_circle,
                            color: AppColors.successGreen)
                        : const Icon(Icons.pause_circle,
                            color: AppColors.warningOrange),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _fab() => FloatingActionButton(
        onPressed: widget.onAddTap,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: AppColors.white),
      );
}
