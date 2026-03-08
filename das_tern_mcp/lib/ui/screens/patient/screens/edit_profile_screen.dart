import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common_widgets.dart';

/// Edit profile screen for patients.
/// Pre-fills all fields from current user data and saves via PATCH /users/me.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _idCardController;
  String _gender = 'MALE';
  DateTime? _dateOfBirth;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    _firstNameController =
        TextEditingController(text: user?['firstName'] ?? '');
    _lastNameController =
        TextEditingController(text: user?['lastName'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController =
        TextEditingController(text: user?['phoneNumber'] ?? '');
    _idCardController =
        TextEditingController(text: user?['idCardNumber'] ?? '');
    _gender = user?['gender'] ?? 'MALE';

    if (user?['dateOfBirth'] != null) {
      _dateOfBirth = DateTime.tryParse(user!['dateOfBirth'].toString());
    }

    // Listen for changes
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _idCardController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final data = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
    };

    final email = _emailController.text.trim();
    if (email.isNotEmpty) data['email'] = email;

    final success = await auth.updateUserProfile(data);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsSaved),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? l10n.failedToSave),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.editProfile,
        actions: [
          TextButton(
            onPressed: _hasChanges && !auth.isLoading ? _handleSave : null,
            child: auth.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: TextStyle(
                      color: _hasChanges
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Profile Avatar ──
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primaryBlue,
                        size: 48,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E1E2E)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── First Name ──
              _buildField(
                label: l10n.firstName,
                controller: _firstNameController,
                icon: Icons.person_outline,
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? l10n.fillFirstNameError : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Last Name ──
              _buildField(
                label: l10n.lastName,
                controller: _lastNameController,
                icon: Icons.person_outline,
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? l10n.fillLastNameError : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Gender ──
              _buildLabel(l10n.gender),
              const SizedBox(height: 6),
              _buildGroupCard(isDark, [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.wc_outlined,
                          size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _gender,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                  value: 'MALE', child: Text(l10n.genderMale)),
                              DropdownMenuItem(
                                  value: 'FEMALE',
                                  child: Text(l10n.genderFemale)),
                              DropdownMenuItem(
                                  value: 'OTHER',
                                  child: Text(l10n.genderOther)),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _gender = v ?? 'MALE';
                                _hasChanges = true;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),

              // ── Date of Birth ──
              _buildLabel(l10n.dateOfBirth),
              const SizedBox(height: 6),
              _buildGroupCard(isDark, [
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _dateOfBirth != null
                                ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                                : l10n.selectDateOfBirth,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: _dateOfBirth != null
                                      ? null
                                      : AppColors.textSecondary,
                                ),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),

              // ── Email ──
              _buildField(
                label: l10n.email,
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return l10n.emailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Phone Number (read-only display) ──
              _buildField(
                label: l10n.phoneNumber,
                controller: _phoneController,
                icon: Icons.phone_outlined,
                readOnly: true,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── ID Card Number (read-only display) ──
              _buildField(
                label: '${l10n.idCardNumber} ${l10n.idCardOptional}',
                controller: _idCardController,
                icon: Icons.badge_outlined,
                readOnly: true,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        _buildGroupCard(isDark, [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    readOnly: readOnly,
                    keyboardType: keyboardType,
                    validator: validator,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: readOnly ? AppColors.textSecondary : null,
                        ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (readOnly)
                  Icon(Icons.lock_outline,
                      size: 16,
                      color:
                          AppColors.textSecondary.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildGroupCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
