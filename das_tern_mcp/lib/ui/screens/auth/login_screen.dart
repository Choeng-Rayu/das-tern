import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Login screen matching Figma design – blue gradient background,
/// ដាស់តឿន branding, Khmer labels.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final phone = '+855${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';
    final success = await auth.login(phone, _passwordController.text);

    if (!mounted) return;
    if (success) {
      final role = auth.userRole;
      Navigator.of(context).pushReplacementNamed(
        role == 'DOCTOR' ? '/doctor' : '/patient',
      );
    }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // ── Logo row: doctor avatar + ដាស់តឿន ──
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'ដាស់តឿន',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Title: ចូលគណនី ──
                  const Text(
                    'ចូលគណនី',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Phone number field ──
                  const Text(
                    'លេខទូរស័ព្ទ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'សូមបំពេញលេខទូរស័ព្ទរបស់អ្នក',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'សូមបំពេញលេខទូរស័ព្ទ';
                      }
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 8 || digits.length > 10) {
                        return 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Password field ──
                  const Text(
                    'លេខកូដសម្ងាត់',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'សូមបំពេញលេខកូដសម្ងាត់របស់អ្នក',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 14,
                      ),
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
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'សូមបំពេញលេខកូដសម្ងាត់';
                      }
                      if (v.length < 6) {
                        return 'លេខកូដសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួអក្សរ';
                      }
                      return null;
                    },
                  ),

                  // ── Error message ──
                  if (auth.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.alertRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Login button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
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
                              'ចូលគណនី',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Forgot password link ──
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: const Text(
                        'ភ្លេចលេខកូដសម្ងាត់',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl * 2),

                  // ── Register link ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'មិនមានគណនី? ',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/register-role');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'បង្កើតគណនី',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
