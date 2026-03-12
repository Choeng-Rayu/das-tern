import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/theme/app_spacing.dart';
import 'package:das_tern/core/utils/validators.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_text_field.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/auth/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signIn)),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: l10n.email,
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => viewModel.email = value,
                    validator: (value) =>
                        Validators.requiredField(value, message: l10n.email),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.password,
                    hint: '••••••••',
                    obscureText: true,
                    onChanged: (value) => viewModel.password = value,
                    validator: (value) =>
                        Validators.requiredField(value, message: l10n.password),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRouter.forgotPassword);
                      },
                      child: Text(l10n.forgotPassword),
                    ),
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
                  AppButton(
                    label: l10n.signIn,
                    isLoading: viewModel.isLoading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final success = await viewModel.signIn();
                      if (success && context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRouter.home,
                          (_) => false,
                        );
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
