import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../../services/google_auth_service.dart';

class PatientRegisterStep3Screen extends StatefulWidget {
  const PatientRegisterStep3Screen({super.key});

  @override
  State<PatientRegisterStep3Screen> createState() => _PatientRegisterStep3ScreenState();
}

class _PatientRegisterStep3ScreenState extends State<PatientRegisterStep3Screen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleUser();
  }

  void _checkGoogleUser() {
    final googleUser = GoogleAuthService.instance.currentUser;
    setState(() {
      _isGoogleUser = googleUser != null;
    });
  }

  Future<void> _handleVerify() async {
    if (!_isGoogleUser && _otpController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    // Simulate verification
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isGoogleUser 
            ? 'Registration complete with Google!' 
            : 'OTP verified successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      
      // Navigate to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _handleSkipForGoogle() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/dashboard');
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
                _isGoogleUser ? 'Step 3 of 3 - Google Account' : 'Step 3 of 3 - OTP Verification',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.md),
              
              if (_isGoogleUser) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
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
                const Text(
                  'Enter the verification code sent to your phone/email',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '000000',
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
                    onPressed: () {},
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
                  onPressed: _isLoading ? null : (_isGoogleUser ? _handleSkipForGoogle : _handleVerify),
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
