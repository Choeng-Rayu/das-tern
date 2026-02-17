import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/telegram_phone_field.dart';

/// Patient registration – two-step form with step indicator.
/// Step 1: Personal info (lastName, firstName, gender, dateOfBirth, idCardNumber).
/// Step 2: Account info (phoneNumber, password, confirmPassword).
class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1 controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _gender = 'MALE';
  DateTime? _dateOfBirth;
  final _idCardController = TextEditingController();

  // Step 2 controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneFieldKey = GlobalKey<TelegramStylePhoneFieldState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idCardController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _formKey1.currentState!.validate()) {
      if (_dateOfBirth == null) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectDateOfBirth)),
        );
        return;
      }
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey2.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final phoneText = _phoneController.text.trim();
    String? phone;
    if (phoneText.isNotEmpty) {
      phone = _phoneFieldKey.currentState?.fullPhoneNumber;
    }

    final result = await auth.registerPatient(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth!.toIso8601String().split('T')[0],
      idCardNumber: _idCardController.text.trim().isNotEmpty
          ? _idCardController.text.trim()
          : null,
      email: email,
      phoneNumber: phone,
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
    final success = await auth.signInWithGoogle(userRole: 'PATIENT');

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/patient');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
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
            onBack: () {
              if (_currentStep > 0) {
                setState(() => _currentStep = 0);
              } else {
                Navigator.of(context).pop();
              }
            },
            trailing: const LanguageSwitcherButton(),
          ),

          // ── Title + step indicator ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                Text(
                  l10n.createNewAccount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthStepIndicator(
                  currentStep: _currentStep,
                  totalSteps: 2,
                  stepLabel: _currentStep == 0
                      ? l10n.step1PersonalInfo
                      : l10n.step2AccountInfo,
                ),
              ],
            ),
          ),

          // ── Form content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _currentStep == 0
                  ? _buildStep1()
                  : _buildStep2(auth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Last name
          AuthFieldLabel(l10n.lastName),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _lastNameController,
            hintText: l10n.fillLastNameHint,
            validator: (v) =>
                v?.isEmpty ?? true ? l10n.fillLastNameError : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // First name
          AuthFieldLabel(l10n.firstName),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _firstNameController,
            hintText: l10n.fillFirstNameHint,
            validator: (v) =>
                v?.isEmpty ?? true ? l10n.fillFirstNameError : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // Gender
          AuthFieldLabel(l10n.gender),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _gender,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'MALE', child: Text(l10n.genderMale)),
                  DropdownMenuItem(value: 'FEMALE', child: Text(l10n.genderFemale)),
                  DropdownMenuItem(value: 'OTHER', child: Text(l10n.genderOther)),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'MALE'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date of birth
          AuthFieldLabel(l10n.dateOfBirth),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                          : l10n.dateFormatPlaceholder,
                      style: TextStyle(
                        color: _dateOfBirth != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ID Card (optional)
          AuthFieldLabel('${l10n.idCardNumber} ${l10n.idCardOptional}'),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _idCardController,
            hintText: l10n.idCardNumberHint,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Continue button
          AuthPrimaryButton(
            onPressed: _nextStep,
            label: l10n.continueButton,
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
              onPressed: _handleGoogleRegister,
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
    );
  }

  Widget _buildStep2(AuthProvider auth) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email (required)
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

          // Phone number (optional)
          AuthFieldLabel('${l10n.phoneNumber} ${l10n.phoneOptional}'),
          const SizedBox(height: AppSpacing.xs),
          TelegramStylePhoneField(
            key: _phoneFieldKey,
            controller: _phoneController,
          ),
          const SizedBox(height: AppSpacing.md),

          // Password
          AuthFieldLabel(l10n.password),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _passwordController,
            hintText: l10n.passwordHint,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
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

          // Confirm password
          AuthFieldLabel(l10n.confirmPassword),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _confirmPasswordController,
            hintText: l10n.confirmPasswordHint,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
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
          const SizedBox(height: AppSpacing.md),

          // Terms checkbox
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.termsNotice,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  onChanged: (v) =>
                      setState(() => _agreedToTerms = v ?? false),
                  fillColor: WidgetStateProperty.all(Colors.white),
                  checkColor: AppColors.primaryBlue,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.termsRead,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),

          // Error
          if (auth.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthErrorBanner(message: auth.error!),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Register button
          AuthPrimaryButton(
            onPressed: _agreedToTerms ? _handleRegister : null,
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
    );
  }
}
