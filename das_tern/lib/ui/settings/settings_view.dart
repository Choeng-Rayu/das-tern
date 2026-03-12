import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/ui/settings/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      currentIndex: 4,
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingView(message: 'Loading settings...');
          }

          return ListView(
            children: [
              if (viewModel.user != null)
                AppCard(child: Text('Signed in as ${viewModel.user!.name}')),
              const SizedBox(height: 12),
              ...viewModel.notifications.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(child: Text(item.message)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
