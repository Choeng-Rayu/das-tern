import 'package:das_tern/core/router/app_router.dart';
import 'package:das_tern/core/theme/app_colors.dart';
import 'package:das_tern/core/theme/app_spacing.dart';
import 'package:das_tern/core/widgets/app_button.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'DasTern',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.welcomeMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                label: l10n.signIn,
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.login);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.register,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.register);
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
