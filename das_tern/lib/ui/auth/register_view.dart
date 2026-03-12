import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/theme/app_spacing.dart';
import 'package:das_tern/core/utils/validators.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_text_field.dart';
import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/auth/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.selectRoleTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<UserRole>(
                    segments: [
                      ButtonSegment(
                        value: UserRole.patient,
                        label: Text(l10n.patientRole),
                        icon: const Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: UserRole.doctor,
                        label: Text(l10n.doctorRole),
                        icon: const Icon(Icons.medical_services),
                      ),
                    ],
                    selected: {viewModel.selectedRole},
                    onSelectionChanged: (roles) {
                      viewModel.selectedRole = roles.first;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.fullName,
                    hint: l10n.fullNameHint,
                    onChanged: (value) => viewModel.name = value,
                    validator: (value) => Validators.requiredField(
                      value,
                      message: l10n.fullNameError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    label: l10n.phoneNumber,
                    hint: l10n.phoneNumberHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => viewModel.phoneNumber = value,
                    validator: (value) => Validators.requiredField(
                      value,
                      message: l10n.phoneNumberEmpty,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.password,
                    hint: l10n.passwordHint,
                    obscureText: true,
                    onChanged: (value) => viewModel.password = value,
                    validator: (value) => Validators.requiredField(
                      value,
                      message: l10n.passwordEmpty,
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
                    label: l10n.register,
                    isLoading: viewModel.isLoading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final success = await viewModel.register();
                      if (success && context.mounted) {
                        Navigator.pushNamed(context, AppRouter.otpVerification);
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
