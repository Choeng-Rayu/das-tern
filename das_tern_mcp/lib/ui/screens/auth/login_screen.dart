import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';

/// Login screen – blue gradient background, email/phone + password fields,
/// Google Sign-In, register link.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();
    final success = await auth.login(identifier, _passwordController.text);

    if (!mounted) return;
    if (success) {
      final role = auth.userRole;
      Navigator.of(context).pushReplacementNamed(
        role == 'DOCTOR' ? '/doctor' : '/patient',
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();

    if (!mounted) return;
    if (success) {
      final role = auth.userRole;
      Navigator.of(context).pushReplacementNamed(
        role == 'DOCTOR' ? '/doctor' : '/patient',
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return AuthGradientScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: logo + language switcher placeholder ──
            const AuthHeader(
              trailing: LanguageSwitcherButton(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Welcome section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.signIn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.welcomeMessage,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Form card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email or Phone number
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
                      const SizedBox(height: AppSpacing.md),

                      // Password
                      AuthFieldLabel(l10n.password),
                      const SizedBox(height: AppSpacing.xs),
                      AuthTextField(
                        controller: _passwordController,
                        hintText: l10n.passwordHint,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.passwordEmpty;
                          }
                          if (v.length < 6) {
                            return l10n.passwordTooShort;
                          }
                          return null;
                        },
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/forgot-password');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      // Error message
                      if (auth.error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AuthErrorBanner(message: auth.error!),
                      ],
                      const SizedBox(height: AppSpacing.lg),

                      // Login button
                      AuthPrimaryButton(
                        onPressed: _handleLogin,
                        isLoading: auth.isLoading,
                        label: l10n.signIn,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── OR divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white30)),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      l10n.orDivider,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white30)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Google Sign-In button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.g_mobiledata,
                        color: Colors.red, size: 20),
                  ),
                  label: Text(
                    l10n.signInWithGoogle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Register link ──
            AuthLinkRow(
              message: l10n.dontHaveAccount,
              actionText: l10n.createAccount,
              onTap: () => Navigator.of(context).pushNamed('/register-role'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
