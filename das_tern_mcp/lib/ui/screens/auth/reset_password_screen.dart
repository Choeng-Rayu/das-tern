import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';

/// Reset Password screen – user enters OTP code + new password.
class ResetPasswordScreen extends StatefulWidget {
  final String identifier;

  const ResetPasswordScreen({super.key, required this.identifier});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final otp = _otpCode;
    if (otp.length < 4) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpFillError)),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPasswordWithOtp(
      widget.identifier,
      otp,
      _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordResetSuccess),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0) return;
    final auth = context.read<AuthProvider>();
    await auth.forgotPassword(widget.identifier);
    _startCountdown();
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
              child: Form(
                key: _formKey,
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
                          Icons.lock_open_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Title ──
                    Text(
                      l10n.resetPasswordTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.resetPasswordSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.identifier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── OTP boxes ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 64,
                          height: 64,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextField(
                            controller: _otpControllers[i],
                            focusNode: _otpFocusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) {
                              if (v.isNotEmpty && i < 3) {
                                _otpFocusNodes[i + 1].requestFocus();
                              } else if (v.isEmpty && i > 0) {
                                _otpFocusNodes[i - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Resend ──
                    Center(
                      child: TextButton(
                        onPressed: _resendSeconds == 0 ? _handleResend : null,
                        child: Text(
                          _resendSeconds > 0
                              ? l10n.resendCodeIn(_resendSeconds)
                              : l10n.resendCode,
                          style: TextStyle(
                            color: _resendSeconds > 0
                                ? Colors.white54
                                : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── New Password ──
                    AuthFieldLabel(l10n.newPassword),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _passwordController,
                      hintText: l10n.newPasswordHint,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.newPasswordEmpty;
                        if (v.length < 6) return l10n.passwordTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Confirm Password ──
                    AuthFieldLabel(l10n.confirmNewPassword),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _confirmPasswordController,
                      hintText: l10n.confirmNewPasswordHint,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return l10n.passwordMismatch;
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

                    // Reset button
                    AuthPrimaryButton(
                      onPressed: _handleResetPassword,
                      isLoading: auth.isLoading,
                      label: l10n.resetPassword,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Back to login
                    AuthLinkRow(
                      message: '',
                      actionText: l10n.backToLogin,
                      onTap: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (_) => false),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
