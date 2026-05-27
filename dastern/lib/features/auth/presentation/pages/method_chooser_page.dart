import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/states/loading_state.dart';
import '../providers/auth_providers.dart';
import '../widgets/google_button.dart';
import '../widgets/telegram_button.dart';

class MethodChooserPage extends ConsumerStatefulWidget {
  const MethodChooserPage({super.key});

  @override
  ConsumerState<MethodChooserPage> createState() => _MethodChooserPageState();
}

class _MethodChooserPageState extends ConsumerState<MethodChooserPage> {
  bool _loading = false;
  String? _error;

  Future<void> _withLoading(Future<void> Function() fn) async {
    setState(() { _loading = true; _error = null; });
    try {
      await fn();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) return const AppScaffold(body: LoadingState());

    return AppScaffold(
      title: l.createNewAccount,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              GoogleButton(
                onPressed: () => _withLoading(() async {
                  await ref.read(authRepositoryProvider).signInOrSignUpWithGoogle();
                  if (context.mounted) context.go('/profile-bootstrap');
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              TelegramButton(
                onPressed: () => _withLoading(() async {
                  await ref.read(authRepositoryProvider).signInOrSignUpWithTelegram();
                  if (context.mounted) context.go('/profile-bootstrap');
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.push('/sign-up'),
                child: Text(l.signIn), // email/phone
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
