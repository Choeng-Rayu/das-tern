import 'package:flutter/material.dart';
import 'package:das_tern_mcp/core/widgets/app_button.dart';
import 'package:das_tern_mcp/core/widgets/app_card.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/ui/scan/ocr_review_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

class OcrReviewView extends StatelessWidget {
  const OcrReviewView({
    super.key,
    required this.viewModel,
    required this.prescriptionId,
    this.onSaved,
  });
  final OcrReviewViewModel viewModel;
  final String prescriptionId;
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        if (vm.isLoading) {
          return const AppScaffold(
            title: 'Review Scan',
            showBackButton: true,
            showBottomNav: false,
            body: AppLoadingView(),
          );
        }
        if (vm.hasError) {
          return const AppScaffold(
            title: 'Review Scan',
            showBackButton: true,
            showBottomNav: false,
            body: AppErrorView(message: 'Failed to save medications.'),
          );
        }
        if (vm.saved) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => onSaved?.call());
        }
        return AppScaffold(
          title: 'Review Scan',
          showBackButton: true,
          showBottomNav: false,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Text(
                      'Extracted Medications',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (vm.medications.isEmpty)
                      const Center(child: Text('No medications detected.'))
                    else
                      ...vm.medications.map(
                        (med) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs),
                          child: AppCard(
                            child: ListTile(
                              leading: const Icon(Icons.medication,
                                  color: AppColors.primaryBlue),
                              title: Text(med.name),
                              subtitle: Text(
                                  '${med.dosage} ${med.unit} × ${med.frequency}/day'),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Raw OCR Text',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(vm.ocrText,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: 'Confirm & Save',
                  isFullWidth: true,
                  isLoading: vm.isLoading,
                  onPressed: () => vm.confirmAndSave(prescriptionId),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
