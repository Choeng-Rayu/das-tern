import 'package:flutter/material.dart';

import 'package:das_tern_mcp/core/widgets/app_button.dart';
import 'package:das_tern_mcp/core/widgets/app_card.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/ui/settings/settings_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

/// Settings screen — displays user profile, theme toggle, language, and logout.
///
/// All business logic lives in [SettingsViewModel]. This widget only reads
/// state and calls ViewModel methods on user interaction.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        if (vm.isLoading) {
          return const AppScaffold(
            title: 'Settings',
            currentIndex: 4,
            body: AppLoadingView(),
          );
        }

        if (vm.hasError) {
          return AppScaffold(
            title: 'Settings',
            currentIndex: 4,
            body: AppErrorView(
              message: vm.errorMessage ?? 'Something went wrong.',
              onRetry: vm.loadSettings,
            ),
          );
        }

        return AppScaffold(
          title: 'Settings',
          currentIndex: 4,
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ── Profile Section ────────────────────────────────────────
              if (vm.currentUser != null) ...[
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          _initials(
                            vm.currentUser!.firstName,
                            vm.currentUser!.lastName,
                          ),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vm.currentUser!.firstName} ${vm.currentUser!.lastName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (vm.currentUser!.email != null)
                              Text(
                                vm.currentUser!.email!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Appearance Section ────────────────────────────────────
              _SectionHeader(title: 'Appearance'),
              AppCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: vm.isDarkMode,
                  onChanged: (_) => vm.toggleTheme(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Language Section ───────────────────────────────────────
              _SectionHeader(title: 'Language'),
              AppCard(
                child: Column(
                  children: [
                    _LanguageTile(
                      label: 'English',
                      code: 'en',
                      selected: vm.language == 'en',
                      onTap: () => vm.changeLanguage('en'),
                    ),
                    const Divider(height: 1),
                    _LanguageTile(
                      label: 'ភាសាខ្មែរ',
                      code: 'km',
                      selected: vm.language == 'km',
                      onTap: () => vm.changeLanguage('km'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Logout Button ──────────────────────────────────────────
              AppButton(
                label: 'Log Out',
                variant: AppButtonVariant.destructive,
                isFullWidth: true,
                isLoading: vm.isLoading,
                onPressed: () async {
                  await vm.logout();
                  if (context.mounted && !vm.hasError) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (_) => false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l';
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primaryBlue)
          : null,
      onTap: onTap,
    );
  }
}
