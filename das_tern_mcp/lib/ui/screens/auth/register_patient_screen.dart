import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Patient registration – two-step form matching Figma design.
/// Step 1: Personal info (នាមត្រកូល, នាមខ្នុន, ភេទ, ថ្ងៃខែឆ្នាំកំណើត, លេខអត្តសញ្ញាណប័ណ្ណ).
/// Step 2: Account info (លេខទូរស័ព្ទ, លេខកូដសម្ងាត់, បញ្ជាក់លេខកូដសម្ងាត់, លេខកូដខ្លួង).
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _formKey1.currentState!.validate()) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('សូមជ្រើសរើសថ្ងៃខែឆ្នាំកំណើត')),
        );
        return;
      }
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey2.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final phone = '+855${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

    final result = await auth.registerPatient(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth!.toIso8601String().split('T')[0],
      idCardNumber: _idCardController.text.trim(),
      phoneNumber: phone,
      password: _passwordController.text,
      pinCode: _pinController.text,
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pushNamed(
        '/otp-verification',
        arguments: {'phoneNumber': phone},
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

  // Shared white-on-gradient text field decoration
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
              // ── Header: logo + back ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  _currentStep == 0 ? 'បង្កើតគណនីថ្មី' : 'បង្កើតគណនីថ្មី',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // ── Form content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child:
                      _currentStep == 0 ? _buildStep1() : _buildStep2(auth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // នាមត្រកូល (Last Name / Family name)
          const _FieldLabel('នាមត្រកូល'),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _lastNameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecoration('សូមបំពេញនាមត្រកូលរបស់អ្នក'),
            validator: (v) =>
                v?.isEmpty ?? true ? 'សូមបំពេញនាមត្រកូល' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // នាមខ្នុន (First Name)
          const _FieldLabel('នាមខ្នុន'),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _firstNameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecoration('សូមបំពេញនាមខ្នុនរបស់អ្នក'),
            validator: (v) =>
                v?.isEmpty ?? true ? 'សូមបំពេញនាមខ្នុន' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // ភេទ (Gender)
          const _FieldLabel('ភេទ'),
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
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('ប្រុស')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('ស្រី')),
                  DropdownMenuItem(value: 'OTHER', child: Text('ផ្សេងៗ')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'MALE'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ថ្ងៃ ខែ ឆ្នាំ កំណើត (Date of birth)
          const _FieldLabel('ថ្ងៃ ខែ ឆ្នាំ កំណើត'),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _DateBox(
                label: 'ថ្ងៃទី',
                value: _dateOfBirth != null
                    ? '${_dateOfBirth!.day}'
                    : '',
                onTap: _selectDate,
              ),
              const SizedBox(width: AppSpacing.sm),
              _DateBox(
                label: 'ខែ',
                value: _dateOfBirth != null
                    ? '${_dateOfBirth!.month}'
                    : '',
                onTap: _selectDate,
              ),
              const SizedBox(width: AppSpacing.sm),
              _DateBox(
                label: 'ឆ្នាំ',
                value: _dateOfBirth != null
                    ? '${_dateOfBirth!.year}'
                    : '',
                onTap: _selectDate,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // លេខអត្តសញ្ញាណប័ណ្ណ (ID Card)
          const _FieldLabel('លេខអត្តសញ្ញាណប័ណ្ណ'),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _idCardController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration:
                _fieldDecoration('សូមបំពេញលេខអត្តសញ្ញាណប័ណ្ណរបស់អ្នក'),
            validator: (v) =>
                v?.isEmpty ?? true ? 'សូមបំពេញលេខអត្តសញ្ញាណប័ណ្ណ' : null,
          ),
          const SizedBox(height: AppSpacing.xl),

          // បន្ត button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29B6F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                elevation: 0,
              ),
              child: const Text(
                'បន្ត',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // បានបង្កើតគណនីពីមុន link
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'បានបង្កើតគណនីពីមុន',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(AuthProvider auth) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _currentStep = 0),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              label: const Text(
                'ចយក្រោយ',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // លេខទូរស័ព្ទ
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

          // លេខកូដសម្ងាត់
          const _FieldLabel('លេខកូដសម្ងាត់'),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecoration('សូមបំពេញលេខកូដសម្ងាត់របស់អ្នក').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'សូមបំពេញលេខកូដសម្ងាត់';
              if (v.length < 6) return 'យ៉ាងហោចណាស់ ៦ តួអក្សរ';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // បញ្ជាក់លេខកូដសម្ងាត់
          const _FieldLabel('បញ្ជាក់លេខកូដសម្ងាត់'),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration:
                _fieldDecoration('សូមបំពេញលេខកូដសម្ងាត់របស់អ្នកម្ដងទៀត').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v != _passwordController.text) {
                return 'លេខកូដសម្ងាត់មិនត្រូវគ្នា';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // លេខកូដខ្លួង (PIN) – 4 boxes
          const _FieldLabel('លេខកូដខ្លួង'),
          const SizedBox(height: AppSpacing.xs),
          _PinBoxes(controller: _pinController),

          // Agree checkbox
          const SizedBox(height: AppSpacing.md),
          const Text(
            'សូមអានលក្ខន្ដិកៈ និងចុច្បប់មុនពេលប្រើប្រាស់កម្មវិធី',
            style: TextStyle(color: Colors.white70, fontSize: 12),
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
              const Text(
                'អានរួចរាល់',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
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
          const SizedBox(height: AppSpacing.lg),

          // បន្ត button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_agreedToTerms && !auth.isLoading)
                  ? _handleRegister
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29B6F6),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF29B6F6).withValues(alpha: 0.5),
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
                      'បន្ត',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ──

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

class _DateBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(
                value.isEmpty ? '--' : value,
                style: TextStyle(
                  color: value.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinBoxes extends StatefulWidget {
  final TextEditingController controller;
  const _PinBoxes({required this.controller});

  @override
  State<_PinBoxes> createState() => _PinBoxesState();
}

class _PinBoxesState extends State<_PinBoxes> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _updateParent() {
    widget.controller.text = _controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(4, (i) {
        return Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              _updateParent();
            },
          ),
        );
      }),
    );
  }
}
