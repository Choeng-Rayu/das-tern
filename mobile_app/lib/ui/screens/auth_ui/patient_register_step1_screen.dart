import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/design_tokens.dart';
import '../../../services/google_auth_service.dart';

class PatientRegistrationData {
  String? fullName;
  String? firstName;
  String? lastName;
  String? gender;
  DateTime? dateOfBirth;
  String? email;
  String? phoneNumber;
  String? password;
  bool isGoogleSignUp;
  String? googleIdToken;

  PatientRegistrationData({this.isGoogleSignUp = false});
}

class PatientRegisterStep1Screen extends StatefulWidget {
  final Map<String, dynamic>? googleUserData;

  const PatientRegisterStep1Screen({super.key, this.googleUserData});

  @override
  State<PatientRegisterStep1Screen> createState() => _PatientRegisterStep1ScreenState();
}

class _PatientRegisterStep1ScreenState extends State<PatientRegisterStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _isGoogleSignUp = false;
  String? _googleIdToken;

  @override
  void initState() {
    super.initState();
    if (widget.googleUserData != null) {
      _isGoogleSignUp = true;
      _nameController.text = widget.googleUserData!['name'] ?? '';
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isGoogleSignUp = true);

    try {
      final googleData = await GoogleAuthService.instance.signInAndGetToken();
      final account = googleData != null ? googleData['account'] as GoogleSignInAccount? : null;

      if (account != null && mounted) {
        setState(() {
          _nameController.text = account.displayName ?? '';
          _googleIdToken = googleData!['idToken'] as String?;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as ${account.email}')),
        );
      } else {
        if (mounted) setState(() => _isGoogleSignUp = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleSignUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed')),
        );
      }
    }
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    final nameParts = _nameController.text.trim().split(' ');
    final data = PatientRegistrationData(isGoogleSignUp: _isGoogleSignUp)
      ..fullName = _nameController.text.trim()
      ..firstName = nameParts.first
      ..lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''
      ..gender = _gender!.toUpperCase()
      ..dateOfBirth = _dob
      ..googleIdToken = _googleIdToken;

    if (_isGoogleSignUp) {
      Navigator.pushNamed(context, '/register/step3', arguments: data);
    } else {
      Navigator.pushNamed(context, '/register/step2', arguments: data);
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Step 1 of 3 - Personal Information',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (!_isGoogleSignUp) ...[
                  OutlinedButton.icon(
                    onPressed: _handleGoogleSignUp,
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
                      Expanded(child: Divider(color: Colors.white30, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text('OR', style: TextStyle(color: Colors.white70)),
                      ),
                      Expanded(child: Divider(color: Colors.white30, thickness: 1)),
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
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Text(
                            'Signed in with Google. Please complete your profile.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _gender,
                  dropdownColor: AppColors.darkBlue,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _dob = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                    ),
                    child: Text(
                      _dob == null
                          ? 'Select date'
                          : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                      style: TextStyle(
                        color: _dob == null ? Colors.white54 : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _proceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Next', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
