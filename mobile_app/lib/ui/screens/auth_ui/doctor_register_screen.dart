import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/google_auth_service.dart';
import '../../theme/design_tokens.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedSpecialty;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isGoogleSignUp = false;
  String? _googleIdToken;

  static const _specialtyOptions = [
    {'value': 'GENERAL_PRACTICE', 'label': 'General Practice'},
    {'value': 'INTERNAL_MEDICINE', 'label': 'Internal Medicine'},
    {'value': 'CARDIOLOGY', 'label': 'Cardiology'},
    {'value': 'ENDOCRINOLOGY', 'label': 'Endocrinology'},
    {'value': 'DERMATOLOGY', 'label': 'Dermatology'},
    {'value': 'PEDIATRICS', 'label': 'Pediatrics'},
    {'value': 'PSYCHIATRY', 'label': 'Psychiatry'},
    {'value': 'SURGERY', 'label': 'Surgery'},
    {'value': 'NEUROLOGY', 'label': 'Neurology'},
    {'value': 'OPHTHALMOLOGY', 'label': 'Ophthalmology'},
    {'value': 'OTHER', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _licenseController.dispose();
    _hospitalController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      final googleData = await GoogleAuthService.instance.signInAndGetToken();

      if (googleData != null && mounted) {
        setState(() {
          _isGoogleSignUp = true;
          _googleIdToken = googleData['idToken'] as String?;
          _fullNameController.text = googleData['displayName'] ?? '';
          _emailController.text = googleData['email'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isGoogleSignUp && _googleIdToken != null) {
        await ApiService.instance.googleLogin(
          _googleIdToken!,
          userRole: 'DOCTOR',
        );

        if (!mounted) return;
        // Update doctor-specific fields
        final profileData = <String, dynamic>{};
        if (_hospitalController.text.trim().isNotEmpty) {
          profileData['hospitalClinic'] = _hospitalController.text.trim();
        }
        if (_selectedSpecialty != null) {
          profileData['specialty'] = _selectedSpecialty;
        }
        if (_licenseController.text.trim().isNotEmpty) {
          profileData['licenseNumber'] = _licenseController.text.trim();
        }
        if (_phoneController.text.trim().isNotEmpty) {
          profileData['phoneNumber'] = _phoneController.text.trim();
        }
        if (profileData.isNotEmpty) {
          try {
            await ApiService.instance.updateProfile(profileData);
          } catch (_) {}
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor registration complete!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pushReplacementNamed(context, '/doctor/dashboard');
      } else {
        final result = await ApiService.instance.registerDoctor(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          licenseNumber: _licenseController.text.trim().isNotEmpty
              ? _licenseController.text.trim()
              : null,
          hospitalClinic: _hospitalController.text.trim().isNotEmpty
              ? _hospitalController.text.trim()
              : null,
          specialty: _selectedSpecialty,
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );

        if (mounted) {
          // Show OTP verification dialog
          if (result['requiresOTP'] == true) {
            _showOtpVerificationDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Registration submitted'),
                backgroundColor: AppColors.successGreen,
              ),
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
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

  void _showOtpVerificationDialog() {
    final otpController = TextEditingController();
    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.darkBlue,
              title: const Text('Verify Email', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter the verification code sent to ${_emailController.text.trim()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '0000',
                      hintStyle: const TextStyle(color: Colors.white30),
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      try {
                        await ApiService.instance.sendOtp(_emailController.text.trim());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code resent'), backgroundColor: AppColors.successGreen),
                          );
                        }
                      } catch (_) {}
                    },
                    child: Text('Resend Code', style: TextStyle(color: AppColors.primaryBlue)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading ? null : () {
                    Navigator.of(dialogContext).pop();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Skip for now', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: dialogLoading ? null : () async {
                    if (otpController.text.trim().isEmpty) return;
                    setDialogState(() => dialogLoading = true);

                    try {
                      final result = await ApiService.instance.verifyOtp(
                        _emailController.text.trim(),
                        otpController.text.trim(),
                      );

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email verified! Welcome, Doctor.'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                        Navigator.pushReplacementNamed(context, '/doctor/dashboard');
                      }
                    } on ApiException catch (e) {
                      setDialogState(() => dialogLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message), backgroundColor: AppColors.alertRed),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => dialogLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  child: dialogLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Doctor Registration',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Complete your professional profile',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (!_isGoogleSignUp) ...[
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignUp,
                    icon: Icon(Icons.login, color: AppColors.primaryBlue),
                    label: Text(
                      'Sign up with Google',
                      style: TextStyle(fontSize: 16, color: AppColors.primaryBlue),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      side: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white30)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text('OR', style: TextStyle(color: Colors.white70)),
                      ),
                      Expanded(child: Divider(color: Colors.white30)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (_isGoogleSignUp)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.successGreen),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Google linked. Please complete doctor details.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Full Name
                _buildField('Full Name', _fullNameController, 'Dr. Full Name'),

                // Email (Required)
                _buildField('Email', _emailController, 'doctor@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) return 'Enter a valid email';
                      return null;
                    }),

                // Phone Number (Optional)
                _buildField('Phone Number (Optional)', _phoneController, '+855 12 345 678',
                    required: false, keyboardType: TextInputType.phone),

                // Specialty (Optional - Dropdown)
                const Text('Specialty (Optional)', style: TextStyle(fontSize: 14, color: Colors.white)),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  dropdownColor: AppColors.darkBlue,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Select specialty',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  items: _specialtyOptions
                      .map((s) => DropdownMenuItem(value: s['value'], child: Text(s['label']!)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSpecialty = v),
                ),
                const SizedBox(height: AppSpacing.md),

                // License Number (Optional)
                _buildField('License Number (Optional)', _licenseController, 'MC-12345',
                    required: false),

                // Hospital/Clinic (Optional)
                _buildField('Hospital / Clinic (Optional)', _hospitalController, 'Hospital name',
                    required: false),

                // Password fields (non-Google only)
                if (!_isGoogleSignUp) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Password', style: TextStyle(fontSize: 14, color: Colors.white)),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.neutralGray,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Confirm Password', style: TextStyle(fontSize: 14, color: Colors.white)),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Confirm password',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.neutralGray,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text('Login', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint,
      {bool required = true, TextInputType keyboardType = TextInputType.text,
       String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          validator: validator ?? (required ? (v) => v?.isEmpty ?? true ? 'Required' : null : null),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
