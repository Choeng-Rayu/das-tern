import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../providers/auth_providers.dart';
import '../widgets/credential_field.dart';
import '../widgets/google_button.dart';
import '../widgets/password_field.dart';
import '../widgets/telegram_button.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _credCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _credCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signInWithPassword(
            credential: _credCtrl.text,
            password: _passCtrl.text,
          );
      if (mounted) context.go('/profile-bootstrap');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
    return AppScaffold(
      title: l.signIn,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.xl),
              CredentialField(controller: _credCtrl),
              const SizedBox(height: AppSpacing.md),
              PasswordField(controller: _passCtrl),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(l.forgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.login,
                onPressed: _loading ? null : _signIn,
                loading: _loading,
                fullWidth: true,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(children: <Widget>[
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(l.orDivider),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => context.push('/welcome'),
                child: Text(l.dontHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
