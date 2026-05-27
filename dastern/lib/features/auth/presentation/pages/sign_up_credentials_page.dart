import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../providers/auth_providers.dart';
import '../widgets/credential_field.dart';
import '../widgets/password_field.dart';

class SignUpCredentialsPage extends ConsumerStatefulWidget {
  const SignUpCredentialsPage({super.key});

  @override
  ConsumerState<SignUpCredentialsPage> createState() =>
      _SignUpCredentialsPageState();
}

class _SignUpCredentialsPageState extends ConsumerState<SignUpCredentialsPage> {
  final _credCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _credCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final role = ref.read(pendingRoleProvider);
    if (role == null) { context.go('/welcome'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      final result = await ref.read(authRepositoryProvider).signUpWithPassword(
            credential: _credCtrl.text,
            password: _passCtrl.text,
            role: role,
          );
      if (!mounted) return;
      if (result.pendingPhoneOtp) {
        context.push('/phone-otp', extra: _credCtrl.text);
      } else {
        context.go('/profile-bootstrap');
      }
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
      title: l.createAccount,
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
              PasswordField(controller: _passCtrl, showStrength: true),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                controller: _confirmCtrl,
                label: l.register, // reuse "confirm password" label
                validator: (v) =>
                    v != _passCtrl.text ? 'Passwords do not match' : null,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l.createAccount,
                onPressed: _loading ? null : _signUp,
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
