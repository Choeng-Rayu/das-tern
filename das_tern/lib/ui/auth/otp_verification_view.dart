import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/theme/app_spacing.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/core/widgets/app_text_field.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/auth/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OtpVerificationView extends StatelessWidget {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyCodeTitle)),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.otpSentMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  viewModel.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: l10n.verifyCodeTitle,
                  hint: '0000',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => viewModel.otp = value,
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
                  label: l10n.verifyButton,
                  isLoading: viewModel.isLoading,
                  onPressed: () async {
                    final success = await viewModel.verifyOtp();
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
          );
        },
      ),
    );
  }
}
