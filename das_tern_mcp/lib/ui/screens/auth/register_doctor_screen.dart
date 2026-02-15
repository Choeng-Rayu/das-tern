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
  final _phoneController = TextEditingController();
  final _phoneFieldKey = GlobalKey<TelegramStylePhoneFieldState>();
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
    final phone = _phoneFieldKey.currentState!.fullPhoneNumber;

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

                    AuthFieldLabel(l10n.phoneNumber),
                    const SizedBox(height: AppSpacing.xs),
                    TelegramStylePhoneField(
                      key: _phoneFieldKey,
                      controller: _phoneController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.phoneNumberEmpty;
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        final country =
                            _phoneFieldKey.currentState?.selectedCountry;
                        if (country != null &&
                            !country.validationPattern.hasMatch(digits)) {
                          return l10n.phoneNumberInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Professional Info Section ──
                    _SectionHeader(title: l10n.professionalInfoSection),
                    const SizedBox(height: AppSpacing.sm),

                    AuthFieldLabel(l10n.hospitalClinic),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _hospitalController,
                      hintText: l10n.hospitalClinicHint,
                      validator: (v) =>
                          v?.isEmpty ?? true ? l10n.hospitalClinicError : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AuthFieldLabel(l10n.specialty),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _specialtyController,
                      hintText: l10n.specialtyHint,
                      validator: (v) =>
                          v?.isEmpty ?? true ? l10n.specialtyError : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AuthFieldLabel(l10n.medicalLicense),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _licenseController,
                      hintText: l10n.medicalLicenseHint,
                      validator: (v) =>
                          v?.isEmpty ?? true ? l10n.medicalLicenseError : null,
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
