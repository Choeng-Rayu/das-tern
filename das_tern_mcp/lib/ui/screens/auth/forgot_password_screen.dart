import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';

/// Forgot Password screen – user enters email or phone to receive reset code.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();
    final success = await auth.forgotPassword(identifier);

    if (!mounted) return;
    if (success) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.resetCodeSent),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.of(context).pushNamed(
        '/reset-password',
        arguments: {'identifier': identifier},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return AuthGradientScaffold(
      child: Column(
        children: [
          // ── Header ──
          AuthHeader(
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            trailing: const LanguageSwitcherButton(),
          ),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // ── Lock icon ──
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Title ──
                  Text(
                    l10n.forgotPasswordTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.forgotPasswordSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Form ──
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthFieldLabel(l10n.emailOrPhone),
                        const SizedBox(height: AppSpacing.xs),
                        AuthTextField(
                          controller: _identifierController,
                          hintText: l10n.emailOrPhoneHint,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.emailOrPhoneEmpty;
                            }
                            return null;
                          },
                        ),

                        // Error
                        if (auth.error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          AuthErrorBanner(message: auth.error!),
                        ],
                        const SizedBox(height: AppSpacing.xl),

                        // Send Reset Code button
                        AuthPrimaryButton(
                          onPressed: _handleSendResetCode,
                          isLoading: auth.isLoading,
                          label: l10n.sendResetCode,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Back to login
                        AuthLinkRow(
                          message: '',
                          actionText: l10n.backToLogin,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
