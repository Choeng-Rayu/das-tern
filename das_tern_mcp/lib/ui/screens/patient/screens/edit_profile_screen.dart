import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/user_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/profile_editor_view_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common_widgets.dart';

/// Edit profile screen — thin view backed by [ProfileEditorViewModel].
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileEditorViewModel _vm;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final repo = context.read<UserRepository>();

    // Use typed currentUser if available, fall back to legacy map
    final currentUser =
        auth.currentUser ??
        (auth.user != null ? CurrentUser.fromJson(auth.user!) : null) ??
        const CurrentUser(id: '', firstName: '', role: UserRole.patient);

    _vm = ProfileEditorViewModel(user: currentUser, userRepository: repo);

    _firstNameCtrl = TextEditingController(text: _vm.firstName);
    _lastNameCtrl = TextEditingController(text: _vm.lastName);
    _emailCtrl = TextEditingController(text: _vm.email);
    _phoneCtrl = TextEditingController(text: _vm.phone);

    for (final c in [_firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    _vm.updateField(() {
      _vm.firstName = _firstNameCtrl.text;
      _vm.lastName = _lastNameCtrl.text;
      _vm.email = _emailCtrl.text;
      _vm.phone = _phoneCtrl.text;
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await _vm.pickImage(source);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vm.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _vm.updateField(() => _vm.dateOfBirth = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await _vm.save();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (success) {
      // Sync updated profile back to AuthProvider
      context.read<AuthProvider>().refreshProfile();
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
          content: Text(_vm.error ?? l10n.failedToSave),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final isSaving = _vm.saveStatus == SaveStatus.saving;

        return Scaffold(
          appBar: AppHeader(
            title: l10n.editProfile,
            actions: [
              TextButton(
                onPressed: _vm.canSave && !isSaving ? _handleSave : null,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.save,
                        style: TextStyle(
                          color: _vm.canSave
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
                  const SizedBox(height: AppSpacing.sm),
                  // Avatar
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: AppColors.primaryBlue.withValues(
                              alpha: 0.12,
                            ),
                            backgroundImage: _vm.pickedImage != null
                                ? FileImage(_vm.pickedImage!) as ImageProvider
                                : (_vm.existingImageUrl != null &&
                                      _vm.existingImageUrl!.startsWith('data:'))
                                ? MemoryImage(
                                    base64Decode(
                                      _vm.existingImageUrl!.split(',').last,
                                    ),
                                  )
                                : (_vm.existingImageUrl != null &&
                                      _vm.existingImageUrl!.isNotEmpty)
                                ? NetworkImage(_vm.existingImageUrl!)
                                : null,
                            child:
                                (_vm.pickedImage == null &&
                                    (_vm.existingImageUrl == null ||
                                        _vm.existingImageUrl!.isEmpty))
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.primaryBlue,
                                    size: 52,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF1E1E2E)
                                      : Colors.white,
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildField(
                    label: l10n.firstName,
                    controller: _firstNameCtrl,
                    icon: Icons.person_outline,
                    validator: (_) {
                      final e = _vm.validateFirstName();
                      return e == null ? null : l10n.fillFirstNameError;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildField(
                    label: l10n.lastName,
                    controller: _lastNameCtrl,
                    icon: Icons.person_outline,
                    validator: (_) {
                      final e = _vm.validateLastName();
                      return e == null ? null : l10n.fillLastNameError;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildGenderRow(l10n, isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildDobRow(l10n, isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildField(
                    label: l10n.email,
                    controller: _emailCtrl,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (_) {
                      final e = _vm.validateEmail();
                      return e == null ? null : l10n.emailInvalid;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildField(
                    label: l10n.phoneNumber,
                    controller: _phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.alertRed,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.alertRed,
                  width: 1.8,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderRow(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            l10n.gender,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Gender>(
              value: _vm.gender,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: Gender.male,
                  child: Text(l10n.genderMale),
                ),
                DropdownMenuItem(
                  value: Gender.female,
                  child: Text(l10n.genderFemale),
                ),
                DropdownMenuItem(
                  value: Gender.other,
                  child: Text(l10n.genderOther),
                ),
              ],
              onChanged: (v) {
                if (v != null) _vm.updateField(() => _vm.gender = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDobRow(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            l10n.dateOfBirth,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _vm.dateOfBirth != null
                        ? '${_vm.dateOfBirth!.day.toString().padLeft(2, '0')}/${_vm.dateOfBirth!.month.toString().padLeft(2, '0')}/${_vm.dateOfBirth!.year}'
                        : l10n.selectDateOfBirth,
                    style: TextStyle(
                      color: _vm.dateOfBirth != null
                          ? null
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
