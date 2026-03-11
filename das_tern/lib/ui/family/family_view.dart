import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/ui/family/family_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FamilyView extends StatelessWidget {
  const FamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Family',
      currentIndex: 3,
      body: Consumer<FamilyViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingView(message: 'Loading family...');
          }

          return ListView(
            children: [
              if (viewModel.currentUser != null)
                AppCard(
                  child: Text('Current user: ${viewModel.currentUser!.name}'),
                ),
              const SizedBox(height: 12),
              ...viewModel.familyMembers.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Text('${member.name} (${member.email})'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
