import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/telegram_phone_field.dart';

/// Doctor registration – single-page form with grouped sections.
class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key});

  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneFieldKey = GlobalKey<TelegramStylePhoneFieldState>();
  final _hospitalController = TextEditingController();
  String? _selectedSpecialty;
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Specialty options matching backend DoctorSpecialty enum
  static const List<String> _specialtyValues = [
    'GENERAL_PRACTICE',
    'INTERNAL_MEDICINE',
    'CARDIOLOGY',
    'ENDOCRINOLOGY',
    'DERMATOLOGY',
    'PEDIATRICS',
    'PSYCHIATRY',
    'SURGERY',
    'NEUROLOGY',
    'OPHTHALMOLOGY',
    'OTHER',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getSpecialtyLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'GENERAL_PRACTICE':
        return l10n.specialtyGeneralPractice;
      case 'INTERNAL_MEDICINE':
        return l10n.specialtyInternalMedicine;
      case 'CARDIOLOGY':
        return l10n.specialtyCardiology;
      case 'ENDOCRINOLOGY':
        return l10n.specialtyEndocrinology;
      case 'DERMATOLOGY':
        return l10n.specialtyDermatology;
      case 'PEDIATRICS':
        return l10n.specialtyPediatrics;
      case 'PSYCHIATRY':
        return l10n.specialtyPsychiatry;
      case 'SURGERY':
        return l10n.specialtySurgery;
      case 'NEUROLOGY':
        return l10n.specialtyNeurology;
      case 'OPHTHALMOLOGY':
        return l10n.specialtyOphthalmology;
      case 'OTHER':
        return l10n.specialtyOther;
      default:
        return value;
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final phoneText = _phoneController.text.trim();
    String? phone;
    if (phoneText.isNotEmpty) {
      phone = _phoneFieldKey.currentState?.fullPhoneNumber;
    }

    final result = await auth.registerDoctor(
      fullName: _fullNameController.text.trim(),
      email: email,
      phoneNumber: phone,
      hospitalClinic: _hospitalController.text.trim().isNotEmpty
          ? _hospitalController.text.trim()
          : null,
      specialty: _selectedSpecialty,
      licenseNumber: _licenseController.text.trim().isNotEmpty
          ? _licenseController.text.trim()
          : null,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pushNamed(
        '/otp-verification',
        arguments: {'identifier': email},
      );
    }
  }

  Future<void> _handleGoogleRegister() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle(userRole: 'DOCTOR');

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/doctor');
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
      child: Column(
        children: [
          // ── Header ──
          AuthHeader(
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            trailing: const LanguageSwitcherButton(),
          ),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.doctorRegistrationTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.doctorRegistrationSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
                    // ── Personal Info Section ──
                    _SectionHeader(title: l10n.personalInfoSection),
                    const SizedBox(height: AppSpacing.sm),

                    AuthFieldLabel(l10n.fullName),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _fullNameController,
                      hintText: l10n.fullNameHint,
                      validator: (v) =>
                          v?.isEmpty ?? true ? l10n.fullNameError : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AuthFieldLabel(l10n.email),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _emailController,
                      hintText: l10n.emailHint,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.emailEmpty;
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) return l10n.emailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AuthFieldLabel('${l10n.phoneNumber} ${l10n.phoneOptional}'),
                    const SizedBox(height: AppSpacing.xs),
                    TelegramStylePhoneField(
                      key: _phoneFieldKey,
                      controller: _phoneController,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Professional Info Section ──
                    _SectionHeader(title: l10n.professionalInfoSection),
                    const SizedBox(height: AppSpacing.sm),

                    AuthFieldLabel('${l10n.hospitalClinic} ${l10n.hospitalClinicOptional}'),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _hospitalController,
                      hintText: l10n.hospitalClinicHint,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AuthFieldLabel('${l10n.specialty} ${l10n.hospitalClinicOptional}'),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSpecialty,
                          isExpanded: true,
                          hint: Text(
                            l10n.selectSpecialty,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                          items: _specialtyValues.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(_getSpecialtyLabel(context, value)),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedSpecialty = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AuthFieldLabel('${l10n.medicalLicense} ${l10n.medicalLicenseOptional}'),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _licenseController,
                      hintText: l10n.medicalLicenseHint,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Security Section ──
                    _SectionHeader(title: l10n.accountSecuritySection),
                    const SizedBox(height: AppSpacing.sm),

                    AuthFieldLabel(l10n.password),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _passwordController,
                      hintText: l10n.passwordTooShort,
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
                        if (v == null || v.isEmpty) return l10n.passwordEmpty;
                        if (v.length < 6) return l10n.passwordTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AuthFieldLabel(l10n.confirmPassword),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _confirmPasswordController,
                      hintText: l10n.confirmPasswordHint,
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

                    // Register button
                    AuthPrimaryButton(
                      onPressed: _handleRegister,
                      isLoading: auth.isLoading,
                      label: l10n.createAccount,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── OR divider ──
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white30)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            l10n.orRegisterWith,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white30)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Google Register button ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading ? null : _handleGoogleRegister,
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
                          l10n.registerWithGoogle,
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
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      l10n.accountVerificationInfo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Already have account link
                    AuthLinkRow(
                      message: l10n.alreadyHaveAccount,
                      actionText: l10n.signIn,
                      onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (_) => false,
                      ),
                    ),
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

// ── Section Header ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF29B6F6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
