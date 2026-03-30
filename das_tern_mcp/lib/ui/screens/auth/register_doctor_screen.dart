import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/telegram_phone_field.dart';
import '../../widgets/app_button.dart';

// ── Google logo widget (same as login screen) ───────────────────────────────
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset c = Offset(r, r);
    final double sw = r * 0.36;
    final double mr = r - sw / 2;

    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: c, radius: mr);

    canvas.drawArc(rect, _rad(14), _rad(91), false, arc(_yellow));
    canvas.drawArc(rect, _rad(105), _rad(91), false, arc(_green));
    canvas.drawArc(rect, _rad(196), _rad(150), false, arc(_blue));
    canvas.drawArc(rect, _rad(346), _rad(28), false, arc(_red));

    canvas.drawRect(
      Rect.fromLTRB(c.dx - 1, c.dy - sw / 2, c.dx + r, c.dy + sw / 2),
      Paint()
        ..color = _blue
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
// ─────────────────────────────────────────────────────────────────────────────

/// Doctor registration – two-step form with step indicator.
/// Step 1: Personal info (fullName, email, phone).
/// Step 2: Professional info + Security (hospital, specialty, license, password).
class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key});

  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1 controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneFieldKey = GlobalKey<TelegramStylePhoneFieldState>();

  // Step 2 controllers
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _formKey1.currentState!.validate()) {
      setState(() => _currentStep = 1);
    }
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
    if (!_formKey2.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final phoneText = _phoneController.text.trim();
    String? phone;
    if (phoneText.isNotEmpty) {
      phone = _phoneFieldKey.currentState?.fullPhoneNumber;
    }

    final result = await auth.registerDoctor(
      fullName:
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
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
      Navigator.of(
        context,
      ).pushNamed('/otp-verification', arguments: {'identifier': email});
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

  Future<void> _handleTelegramRegister() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithTelegram(userRole: 'DOCTOR');

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
    final size = MediaQuery.of(context).size;
    final hPad = (size.width * 0.06).clamp(16.0, 40.0);
    final titleFontSize = size.width < 360 ? 16.0 : 20.0;

    return AuthGradientScaffold(
      child: Column(
        children: [
          AuthHeader(
            showBackButton: true,
            onBack: () {
              if (_currentStep > 0) {
                setState(() => _currentStep = 0);
              } else {
                Navigator.of(context).pop();
              }
            },
            trailing: const LanguageSwitcherButton(lightBackground: true),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                Text(
                  l10n.doctorRegistrationTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthStepIndicator(
                  currentStep: _currentStep,
                  totalSteps: 2,
                  stepLabel: _currentStep == 0
                      ? l10n.doctorStep1PersonalInfo
                      : l10n.doctorStep2ProfessionalInfo,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: hPad,
                vertical: AppSpacing.md,
              ),
              child: _currentStep == 0 ? _buildStep1() : _buildStep2(auth),
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
          AuthFieldLabel(l10n.lastName),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _lastNameController,
            hintText: l10n.fillLastNameHint,
            validator: (v) =>
                v?.isEmpty ?? true ? l10n.fillLastNameError : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthFieldLabel(l10n.firstName),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _firstNameController,
            hintText: l10n.fillFirstNameHint,
            validator: (v) =>
                v?.isEmpty ?? true ? l10n.fillFirstNameError : null,
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
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            text: l10n.continueButton,
            onPressed: _nextStep,
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, Color(0xFF4069DE)],
            ),
            shape: AppButtonShape.pill,
            size: AppButtonSize.large,
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.neutral300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  l10n.orRegisterWith,
                  style: const TextStyle(
                    color: AppColors.neutralGray,
                    fontSize: 12,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.neutral300)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _handleGoogleRegister,
              icon: const _GoogleIcon(size: 20),
              label: Text(
                l10n.registerWithGoogle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.neutral300, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _handleTelegramRegister,
              icon: const Icon(
                Icons.send_rounded,
                color: Color(0xFF229ED9),
                size: 20,
              ),
              label: Text(
                l10n.registerWithTelegram,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.neutral300, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          AuthLinkRow(
            message: l10n.alreadyHaveAccount,
            actionText: l10n.signIn,
            onTap: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (_) => false),
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
          AuthFieldLabel(
            '${l10n.hospitalClinic} ${l10n.hospitalClinicOptional}',
          ),
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
              border: Border.all(color: AppColors.neutral300, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSpecialty,
                isExpanded: true,
                hint: Text(
                  l10n.specialty,
                  style: const TextStyle(
                    color: AppColors.neutral400,
                    fontSize: 13,
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

          AuthFieldLabel(
            '${l10n.medicalLicense} ${l10n.medicalLicenseOptional}',
          ),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _licenseController,
            hintText: l10n.medicalLicenseHint,
          ),
          const SizedBox(height: AppSpacing.md),

          AuthFieldLabel(l10n.password),
          const SizedBox(height: AppSpacing.xs),
          AuthTextField(
            controller: _passwordController,
            hintText: l10n.passwordTooShort,
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
              if (v != _passwordController.text) return l10n.passwordMismatch;
              return null;
            },
          ),

          if (auth.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthErrorBanner(message: auth.error!),
          ],
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            text: l10n.createAccount,
            onPressed: _handleRegister,
            isLoading: auth.isLoading,
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, Color(0xFF4069DE)],
            ),
            shape: AppButtonShape.pill,
            size: AppButtonSize.large,
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            l10n.accountVerificationInfo,
            style: const TextStyle(color: AppColors.neutralGray, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          AuthLinkRow(
            message: l10n.alreadyHaveAccount,
            actionText: l10n.signIn,
            onTap: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (_) => false),
          ),
        ],
      ),
    );
  }
}
