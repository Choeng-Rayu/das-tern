import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';

/// OTP verification screen – 4-digit code with auto-verify and resend timer.
class OtpVerificationScreen extends StatefulWidget {
  final String identifier;

  const OtpVerificationScreen({super.key, required this.identifier});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final l10n = AppLocalizations.of(context)!;
    final otp = _otpCode;
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpFillError)),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(widget.identifier, otp);

    if (!mounted) return;
    if (success) {
      final role = auth.userRole;
      Navigator.of(context).pushNamedAndRemoveUntil(
        role == 'DOCTOR' ? '/doctor' : '/patient',
        (_) => false,
      );
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0) return;
    final auth = context.read<AuthProvider>();
    await auth.sendOtp(widget.identifier);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // ── Phone icon ──
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.identifier.contains('@')
                            ? Icons.email_rounded
                            : Icons.phone_android_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Title ──
                  Text(
                    l10n.verifyCodeTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.otpSentMessage,
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
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
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
                              _focusNodes[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                            if (_otpCode.length == 4) _handleVerify();
                          },
                        ),
                      );
                    }),
                  ),

                  // Error
                  if (auth.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AuthErrorBanner(message: auth.error!),
                  ],
                  const SizedBox(height: AppSpacing.xl),

                  // ── Verify button ──
                  AuthPrimaryButton(
                    onPressed: _handleVerify,
                    isLoading: auth.isLoading,
                    label: l10n.verifyButton,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
