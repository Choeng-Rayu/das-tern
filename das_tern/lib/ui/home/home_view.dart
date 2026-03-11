import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/widgets/app_badge.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_error_view.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.home,
      subtitle: l10n.welcomeMessage,
      currentIndex: 0,
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingView(message: 'Loading dashboard...');
          }
          if (viewModel.errorMessage != null) {
            return AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.load.execute,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AppBadge(label: '${viewModel.medicationCount} meds'),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todayMedications,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('You have ${viewModel.medicationCount} medications.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: l10n.medications,
                icon: Icons.arrow_forward,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.medications);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
