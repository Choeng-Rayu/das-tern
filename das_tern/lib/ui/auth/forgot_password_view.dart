import 'package:das_tern/core/theme/app_spacing.dart';
import 'package:das_tern/core/utils/validators.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_text_field.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/auth/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.resetPasswordSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.email,
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => viewModel.email = value,
                    validator: (value) =>
                        Validators.requiredField(value, message: l10n.email),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        viewModel.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_sent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        l10n.resendCode,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  AppButton(
                    label: l10n.sendResetCode,
                    isLoading: viewModel.isLoading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final success = await viewModel.forgotPassword();
                      if (success && mounted) {
                        setState(() => _sent = true);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
