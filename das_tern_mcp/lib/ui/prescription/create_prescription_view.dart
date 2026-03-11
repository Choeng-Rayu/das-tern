import 'package:flutter/material.dart';
import 'package:das_tern_mcp/core/widgets/app_button.dart';
import 'package:das_tern_mcp/core/widgets/app_card.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/core/widgets/app_text_field.dart';
import 'package:das_tern_mcp/ui/prescription/create_prescription_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

class CreatePrescriptionView extends StatefulWidget {
  const CreatePrescriptionView({
    super.key,
    required this.viewModel,
    this.onSuccess,
  });
  final CreatePrescriptionViewModel viewModel;
  final VoidCallback? onSuccess;

  @override
  State<CreatePrescriptionView> createState() =>
      _CreatePrescriptionViewState();
}

class _CreatePrescriptionViewState extends State<CreatePrescriptionView> {
  final _titleController = TextEditingController();
  final _medNameController = TextEditingController();
  final _medDosageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _medNameController.dispose();
    _medDosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return AppScaffold(
          title: 'New Prescription',
          showBackButton: true,
          showBottomNav: false,
          body: Column(
            children: [
              _StepIndicator(
                current: vm.currentStep,
                total: vm.totalSteps,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _buildStep(vm),
                ),
              ),
              _BottomActions(
                vm: vm,
                onNext: _onNext,
                onBack: vm.previousStep,
                onSubmit: _onSubmit,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep(CreatePrescriptionViewModel vm) {
    switch (vm.currentStep) {
      case 0:
        return _StepOne(
          titleController: _titleController,
          vm: vm,
        );
      case 1:
        return _StepTwo(
          medNameController: _medNameController,
          medDosageController: _medDosageController,
          vm: vm,
        );
      default:
        return _StepThree(vm: vm);
    }
  }

  void _onNext() {
    if (widget.viewModel.currentStep == 0) {
      widget.viewModel.setTitle(_titleController.text.trim());
    }
    widget.viewModel.nextStep();
  }

  Future<void> _onSubmit() async {
    await widget.viewModel.submitPrescription();
    if (!widget.viewModel.hasError) {
      widget.onSuccess?.call();
    }
  }
}

// ── Step widgets ──────────────────────────────────────────────────────────────

class _StepOne extends StatelessWidget {
  const _StepOne({required this.titleController, required this.vm});
  final TextEditingController titleController;
  final CreatePrescriptionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Details',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Title',
          hint: 'e.g. Hypertension Treatment',
          controller: titleController,
        ),
        const SizedBox(height: AppSpacing.md),
        _DatePickerRow(
          label: 'Start Date',
          value: vm.startDate,
          onChanged: vm.setStartDate,
        ),
        const SizedBox(height: AppSpacing.sm),
        _DatePickerRow(
          label: 'End Date',
          value: vm.endDate,
          onChanged: vm.setEndDate,
        ),
      ],
    );
  }
}

class _StepTwo extends StatelessWidget {
  const _StepTwo({
    required this.medNameController,
    required this.medDosageController,
    required this.vm,
  });
  final TextEditingController medNameController;
  final TextEditingController medDosageController;
  final CreatePrescriptionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Medications',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Medication Name',
          hint: 'e.g. Paracetamol',
          controller: medNameController,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Dosage',
          hint: 'e.g. 500mg',
          controller: medDosageController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Add Medication',
          icon: Icons.add,
          onPressed: () {
            final name = medNameController.text.trim();
            final dosage = medDosageController.text.trim();
            if (name.isNotEmpty) {
              vm.addMedication({'name': name, 'dosage': dosage});
              medNameController.clear();
              medDosageController.clear();
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ...vm.medications.asMap().entries.map(
              (e) => ListTile(
                leading: const Icon(Icons.medication,
                    color: AppColors.primaryBlue),
                title: Text(e.value['name']?.toString() ?? ''),
                subtitle: Text(e.value['dosage']?.toString() ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.alertRed),
                  onPressed: () => vm.removeMedication(e.key),
                ),
              ),
            ),
      ],
    );
  }
}

class _StepThree extends StatelessWidget {
  const _StepThree({required this.vm});
  final CreatePrescriptionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Review',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${vm.title}'),
              if (vm.startDate != null)
                Text('Start: ${_fmt(vm.startDate!)}'),
              if (vm.endDate != null) Text('End: ${_fmt(vm.endDate!)}'),
              const SizedBox(height: AppSpacing.sm),
              Text('Medications (${vm.medications.length}):',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ...vm.medications.map(
                (m) => Text(
                    '• ${m['name']} ${m['dosage'] != '' ? '— ${m['dosage']}' : ''}'),
              ),
            ],
          ),
        ),
        if (vm.hasError) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            vm.errorMessage ?? 'Failed to create prescription.',
            style:
                const TextStyle(color: AppColors.alertRed),
          ),
        ],
      ],
    );
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= current;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color:
                    active ? AppColors.primaryBlue : AppColors.neutral400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: value == null
          ? 'Tap to select'
          : '${value!.day}/${value!.month}/${value!.year}',
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        onChanged(picked);
      },
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.vm,
    required this.onNext,
    required this.onBack,
    required this.onSubmit,
  });
  final CreatePrescriptionViewModel vm;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (vm.currentStep > 0)
            Expanded(
              child: AppButton(
                label: 'Back',
                variant: AppButtonVariant.secondary,
                onPressed: onBack,
              ),
            ),
          if (vm.currentStep > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: vm.currentStep < vm.totalSteps - 1
                ? AppButton(label: 'Next', onPressed: onNext)
                : AppButton(
                    label: 'Submit',
                    isLoading: vm.isLoading,
                    onPressed: onSubmit,
                  ),
          ),
        ],
      ),
    );
  }
}
