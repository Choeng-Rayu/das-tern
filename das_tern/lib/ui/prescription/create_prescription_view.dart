import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/ui/prescription/create_prescription_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreatePrescriptionView extends StatelessWidget {
  const CreatePrescriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Create Prescription',
      showBackButton: true,
      body: Consumer<CreatePrescriptionViewModel>(
        builder: (context, viewModel, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCard(
                child: Text('Minimal migration screen using mock repository.'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Create Sample',
                isLoading: viewModel.isLoading,
                onPressed: viewModel.createSamplePrescription,
              ),
              if (viewModel.created) ...[
                const SizedBox(height: 12),
                const Text('Prescription created successfully.'),
              ],
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(viewModel.errorMessage!),
              ],
            ],
          );
        },
      ),
    );
  }
}
