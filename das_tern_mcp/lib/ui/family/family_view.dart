import 'package:flutter/material.dart';
import 'package:das_tern_mcp/core/widgets/app_button.dart';
import 'package:das_tern_mcp/core/widgets/app_empty_view.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/ui/family/family_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

class FamilyView extends StatefulWidget {
  const FamilyView({
    super.key,
    required this.viewModel,
    this.onAddConnection,
  });
  final FamilyViewModel viewModel;
  final VoidCallback? onAddConnection;

  @override
  State<FamilyView> createState() => _FamilyViewState();
}

class _FamilyViewState extends State<FamilyView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadConnections();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        if (vm.isLoading) {
          return const AppScaffold(
            title: 'Family',
            currentIndex: 3,
            showBottomNav: false,
            body: AppLoadingView(),
          );
        }
        if (vm.hasError) {
          return AppScaffold(
            title: 'Family',
            currentIndex: 3,
            showBottomNav: false,
            body: AppErrorView(
              message: vm.errorMessage ?? 'Failed to load.',
              onRetry: vm.loadConnections,
            ),
          );
        }
        if (vm.connections.isEmpty) {
          return AppScaffold(
            title: 'Family',
            currentIndex: 3,
            showBottomNav: false,
            floatingActionButton: _fab(),
            body: const AppEmptyView(
              message: 'No family connections yet.',
              icon: Icons.people_outline,
              subtitle: 'Add a family member to get started.',
            ),
          );
        }
        return AppScaffold(
          title: 'Family',
          currentIndex: 3,
          showBottomNav: false,
          floatingActionButton: _fab(),
          body: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: vm.connections.length,
            itemBuilder: (context, i) => ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(vm.connections[i].toString()),
            ),
          ),
        );
      },
    );
  }

  Widget _fab() => FloatingActionButton(
        onPressed: widget.onAddConnection,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.person_add, color: AppColors.white),
      );
}
