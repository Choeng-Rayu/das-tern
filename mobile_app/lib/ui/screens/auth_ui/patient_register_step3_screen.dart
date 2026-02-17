import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../../services/api_service.dart';
import '../../../services/google_auth_service.dart';
import 'patient_register_step1_screen.dart';

class PatientRegisterStep3Screen extends StatefulWidget {
  const PatientRegisterStep3Screen({super.key});

  @override
  State<PatientRegisterStep3Screen> createState() => _PatientRegisterStep3ScreenState();
}

class _PatientRegisterStep3ScreenState extends State<PatientRegisterStep3Screen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  PatientRegistrationData? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= ModalRoute.of(context)?.settings.arguments as PatientRegistrationData?;
  }

  bool get _isGoogleUser => _data?.isGoogleSignUp ?? false;

  Future<void> _handleVerify() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verify OTP using email as identifier
      final result = await ApiService.instance.verifyOtp(
        _data?.email ?? '',
        _otpController.text.trim(),
      );

      // Save tokens from verification response
      if (mounted) {
        final user = result['user'];
        final role = user?['role'] ?? 'PATIENT';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Registration complete.'),
            backgroundColor: AppColors.successGreen,
          ),
        );

        if (role == 'DOCTOR') {
          Navigator.pushReplacementNamed(context, '/doctor/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.alertRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleComplete() async {
    setState(() => _isLoading = true);

    try {
      final idToken = _data?.googleIdToken;
      if (idToken == null) {
        throw Exception('Google token not available');
      }

      final result = await ApiService.instance.googleLogin(idToken, userRole: 'PATIENT');

      if (mounted) {
        final user = result['user'];
        final role = user?['role'] ?? 'PATIENT';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration complete with Google!'),
            backgroundColor: AppColors.successGreen,
          ),
        );

        if (role == 'DOCTOR') {
          Navigator.pushReplacementNamed(context, '/doctor/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.alertRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_data?.email == null) return;

    try {
      await ApiService.instance.sendOtp(_data!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent to your email'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.alertRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend code: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete Registration',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isGoogleUser ? 'Step 3 of 3 - Google Account' : 'Step 3 of 3 - Email Verification',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_isGoogleUser) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.successGreen),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.successGreen, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Google Account Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        GoogleAuthService.instance.currentUser?.email ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Your account has been verified with Google. No OTP verification needed.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Enter the verification code sent to ${_data?.email ?? "your email"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: '0000',
                    hintStyle: const TextStyle(color: Colors.white30),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: _resendOtp,
                    child: Text(
                      'Resend Code',
                      style: TextStyle(color: AppColors.primaryBlue, fontSize: 14),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isGoogleUser ? _handleGoogleComplete : _handleVerify),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isGoogleUser ? 'Complete Registration' : 'Verify & Complete',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
