import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_empty_view.dart';
import 'package:das_tern/core/widgets/app_error_view.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/ui/prescription/prescription_list_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrescriptionListView extends StatelessWidget {
  const PrescriptionListView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Prescriptions',
      currentIndex: 1,
      showBackButton: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.createPrescription);
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<PrescriptionListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingView(message: 'Loading prescriptions...');
          }

          if (viewModel.errorMessage != null) {
            return AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.load.execute,
            );
          }

          if (viewModel.prescriptions.isEmpty) {
            return AppEmptyView(
              title: 'No prescriptions yet',
              subtitle: 'Create your first prescription',
              action: AppButton(
                label: 'Reload',
                onPressed: viewModel.load.execute,
              ),
            );
          }

          return ListView.separated(
            itemCount: viewModel.prescriptions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final prescription = viewModel.prescriptions[index];
              return AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Dr. ${prescription.doctorName}'),
                  subtitle: Text(
                    '${prescription.medications.length} medications',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.prescriptionDetail,
                      arguments: prescription.id,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
