import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Doctor registration – matching Figma gradient + Khmer labels.
class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key});

  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final phone = '+855${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

    final result = await auth.registerDoctor(
      fullName: _fullNameController.text.trim(),
      phoneNumber: phone,
      hospitalClinic: _hospitalController.text.trim(),
      specialty: _specialtyController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pushNamed(
        '/otp-verification',
        arguments: {'phoneNumber': phone},
      );
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
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
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'ដាស់តឿន',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Title ──
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'ចុះឈ្មោះវេជ្ជបណ្ឌិត',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // ── Form ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('ឈ្មោះពេញ'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _fullNameController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _fieldDecoration('សូមបំពេញឈ្មោះពេញរបស់អ្នក'),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'សូមបំពេញឈ្មោះពេញ' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _FieldLabel('លេខទូរស័ព្ទ'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _fieldDecoration('សូមបំពេញលេខទូរស័ព្ទរបស់អ្នក'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'សូមបំពេញលេខទូរស័ព្ទ';
                            final digits = v.replaceAll(RegExp(r'\D'), '');
                            if (digits.length < 8 || digits.length > 10) {
                              return 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _FieldLabel('មន្ទីរពេទ្យ / គ្លីនិក'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _hospitalController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _fieldDecoration('សូមបំពេញមន្ទីរពេទ្យ ឬ គ្លីនិក'),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'សូមបំពេញមន្ទីរពេទ្យ' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _FieldLabel('ឯកទេស'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _specialtyController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _fieldDecoration('ឧ. វេជ្ជសាស្ត្រទូទៅ, បេះដូង'),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'សូមបំពេញឯកទេស' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _FieldLabel('លេខអាជ្ញាប័ណ្ណវេជ្ជសាស្ត្រ'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _licenseController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _fieldDecoration('សូមបំពេញលេខអាជ្ញាប័ណ្ណ'),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'សូមបំពេញលេខអាជ្ញាប័ណ្ណ' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _FieldLabel('លេខកូដសម្ងាត់'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              _fieldDecoration('យ៉ាងហោចណាស់ ៦ តួអក្សរ').copyWith(
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
                            if (v == null || v.isEmpty) return 'សូមបំពេញលេខកូដសម្ងាត់';
                            if (v.length < 6) return 'យ៉ាងហោចណាស់ ៦ តួអក្សរ';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _FieldLabel('បញ្ជាក់លេខកូដសម្ងាត់'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              _fieldDecoration('សូមបំពេញលេខកូដសម្ងាត់ម្ដងទៀត')
                                  .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'លេខកូដសម្ងាត់មិនត្រូវគ្នា';
                            }
                            return null;
                          },
                        ),

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
                        const SizedBox(height: AppSpacing.xl),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF29B6F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
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
                                    'បង្កើតគណនី',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const Text(
                          'គណនីរបស់អ្នកនឹងត្រូវបានផ្ទៀងផ្ទាត់ដោយក្រុមការងាររបស់យើង។',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
