import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_error_view.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/ui/prescription/prescription_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrescriptionDetailView extends StatelessWidget {
  const PrescriptionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final String? prescriptionId =
        ModalRoute.of(context)?.settings.arguments as String?;
    return AppScaffold(
      title: 'Prescription Detail',
      showBackButton: true,
      body: Consumer<PrescriptionDetailViewModel>(
        builder: (context, viewModel, _) {
          if (prescriptionId != null &&
              viewModel.prescription?.id != prescriptionId) {
            viewModel.setPrescriptionId(prescriptionId);
          }

          if (viewModel.isLoading) {
            return const AppLoadingView(message: 'Loading detail...');
          }

          if (viewModel.errorMessage != null) {
            return AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.load.execute,
            );
          }

          final prescription = viewModel.prescription;
          if (prescription == null) {
            return AppErrorView(
              message: 'Prescription not selected',
              onRetry: viewModel.load.execute,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doctor: ${prescription.doctorName}'),
                    const SizedBox(height: 8),
                    Text('Notes: ${prescription.notes ?? '-'}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: prescription.medications.length,
                  itemBuilder: (context, index) {
                    final med = prescription.medications[index];
                    return AppCard(
                      child: Text('${med.name} - ${med.dosage} ${med.unit}'),
                    );
                  },
                ),
              ),
              AppButton(
                label: 'Reload',
                variant: AppButtonVariant.secondary,
                onPressed: viewModel.load.execute,
              ),
            ],
          );
        },
      ),
    );
  }
}
