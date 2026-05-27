import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../providers/auth_providers.dart';
import '../widgets/credential_field.dart';

/// Spec ref: 02-authentication §9.1–9.2.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _credCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _credCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(_credCtrl.text);
      if (mounted) setState(() => _sent = true);
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
      title: l.forgotPassword,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.mark_email_read_outlined, size: 64),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Check your email or SMS for a reset link.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l.ok,
                    onPressed: () => context.go('/sign-in'),
                    fullWidth: true,
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    CredentialField(controller: _credCtrl),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l.continueButton,                      onPressed: _loading ? null : _submit,
                      loading: _loading,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
