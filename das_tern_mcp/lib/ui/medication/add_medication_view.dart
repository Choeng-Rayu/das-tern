import 'package:flutter/material.dart';
import 'package:das_tern_mcp/core/widgets/app_button.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/core/widgets/app_text_field.dart';
import 'package:das_tern_mcp/ui/medication/add_medication_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

class AddMedicationView extends StatefulWidget {
  const AddMedicationView({
    super.key,
    required this.viewModel,
    this.onSuccess,
  });
  final AddMedicationViewModel viewModel;
  final VoidCallback? onSuccess;

  @override
  State<AddMedicationView> createState() => _AddMedicationViewState();
}

class _AddMedicationViewState extends State<AddMedicationView> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();

  static const List<String> _units = ['tablet', 'mg', 'ml', 'capsule', 'g'];
  static const List<int> _frequencies = [1, 2, 3, 4];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        if (vm.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onSuccess?.call();
          });
        }
        return AppScaffold(
          title: 'Add Medication',
          showBackButton: true,
          showBottomNav: false,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Medication Name',
                  hint: 'e.g. Amoxicillin',
                  controller: _nameController,
                  onChanged: vm.setName,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Dosage',
                  hint: 'e.g. 500',
                  controller: _dosageController,
                  keyboardType: TextInputType.number,
                  onChanged: vm.setDosage,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Unit',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: vm.unit,
                  isExpanded: true,
                  items: _units
                      .map((u) =>
                          DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => vm.setUnit(v ?? 'tablet'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Frequency (per day)',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButton<int>(
                  value: vm.frequency,
                  isExpanded: true,
                  items: _frequencies
                      .map((f) =>
                          DropdownMenuItem(value: f, child: Text('$f x/day')))
                      .toList(),
                  onChanged: (v) => vm.setFrequency(v ?? 1),
                ),
                if (vm.hasError) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    vm.errorMessage ?? 'Failed to add medication.',
                    style:
                        const TextStyle(color: AppColors.alertRed),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Add Medication',
                  isFullWidth: true,
                  isLoading: vm.isLoading,
                  onPressed: vm.submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
