import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../providers/auth_providers.dart';
import '../widgets/password_field.dart';

/// Handles the `dastern://auth/reset` deep-link callback.
/// Spec ref: 02-authentication §9.2.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_passCtrl.text);
      // Sign out all other sessions after password change (§9.5)
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) context.go('/sign-in');
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.xl),
              PasswordField(controller: _passCtrl, showStrength: true),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                controller: _confirmCtrl,
                validator: (v) =>
                    v != _passCtrl.text ? 'Passwords do not match' : null,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l.save,
                onPressed: _loading ? null : _save,
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
