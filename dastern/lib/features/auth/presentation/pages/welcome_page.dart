import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../domain/chosen_role.dart';
import '../providers/auth_providers.dart';
import '../widgets/role_chooser_card.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              Text(
                l.appTitle,
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.appTagline,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              RoleChooserCard(
                role: ChosenRole.patient,
                onTap: () => _selectRole(context, ref, ChosenRole.patient),
              ),
              const SizedBox(height: AppSpacing.md),
              RoleChooserCard(
                role: ChosenRole.doctor,
                onTap: () => _selectRole(context, ref, ChosenRole.doctor),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => context.push('/sign-in'),
                child: Text(l.alreadyHaveAccount),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectRole(
    BuildContext context,
    WidgetRef ref,
    ChosenRole role,
  ) async {
    await ref.read(pendingRoleProvider.notifier).set(role);
    if (context.mounted) context.push('/method-chooser');
  }
}
