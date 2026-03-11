import 'package:das_tern/core/widgets/app_badge.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_empty_view.dart';
import 'package:das_tern/core/widgets/app_error_view.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/medication/medication_list_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MedicationListView extends StatelessWidget {
  const MedicationListView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.medications,
      currentIndex: 1,
      showBackButton: true,
      body: Consumer<MedicationListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingView(message: 'Loading medications...');
          }

          if (viewModel.errorMessage != null) {
            return AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.load.execute,
            );
          }

          if (viewModel.medications.isEmpty) {
            return AppEmptyView(
              title: l10n.noMedications,
              subtitle: l10n.addMedication,
              action: AppButton(
                label: 'Reload',
                variant: AppButtonVariant.secondary,
                onPressed: viewModel.load.execute,
              ),
            );
          }

          return ListView.separated(
            itemCount: viewModel.medications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final medication = viewModel.medications[index];
              return AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${medication.dosage} ${medication.unit} • ${medication.frequency}',
                          ),
                        ],
                      ),
                    ),
                    AppBadge(
                      label: medication.isActive ? l10n.active : l10n.inactive,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}