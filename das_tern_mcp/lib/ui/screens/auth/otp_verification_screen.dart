import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_spacing.dart';

/// OTP verification screen – 4-digit code, Figma gradient style.
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

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
    final otp = _otpCode;
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('សូមបំពេញលេខកូដ ៤ ខ្ទង់')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(widget.phoneNumber, otp);

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
    await auth.sendOtp(widget.phoneNumber);
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2B7A9E),
              Color(0xFF1A5276),
              Color(0xFF154360),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back button ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Icon ──
                const Icon(Icons.sms_outlined, size: 64, color: Colors.white),
                const SizedBox(height: AppSpacing.lg),

                // ── Title ──
                const Text(
                  'បញ្ជាក់លេខកូដ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'យើងបានផ្ញើលេខកូដ ៤ ខ្ទង់ទៅ\n${widget.phoneNumber}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── OTP boxes ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
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

                if (auth.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    auth.error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),

                // ── Verify button ──
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF29B6F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'បញ្ជាក់',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Resend ──
                Center(
                  child: TextButton(
                    onPressed: _resendSeconds == 0 ? _handleResend : null,
                    child: Text(
                      _resendSeconds > 0
                          ? 'ផ្ញើលេខកូដម្ដងទៀតក្នុង $_resendSecondsវ'
                          : 'ផ្ញើលេខកូដម្ដងទៀត',
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
      ),
    );
  }
}
