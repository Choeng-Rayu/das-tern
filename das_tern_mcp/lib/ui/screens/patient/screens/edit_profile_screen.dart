import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String _gender = 'MALE';
  DateTime? _dateOfBirth;
  bool _hasChanges = false;
  File? _pickedImage;
  String? _existingProfilePictureUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    _firstNameController = TextEditingController(
      text: user?['firstName'] ?? '',
    );
    _lastNameController = TextEditingController(text: user?['lastName'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phoneNumber'] ?? '');
    _existingProfilePictureUrl = user?['profilePictureUrl'];
    _gender = user?['gender'] ?? 'MALE';

    if (user?['dateOfBirth'] != null) {
      _dateOfBirth = DateTime.tryParse(user!['dateOfBirth'].toString());
    }

    // Listen for changes
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
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

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) data['phoneNumber'] = phone;

    if (_pickedImage != null) {
      final bytes = await _pickedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = _pickedImage!.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      data['profilePictureUrl'] = 'data:$mime;base64,$base64Image';
    }

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
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: AppColors.primaryBlue.withValues(
                          alpha: 0.12,
                        ),
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!) as ImageProvider
                            : (_existingProfilePictureUrl != null &&
                                  _existingProfilePictureUrl!.startsWith(
                                    'data:',
                                  ))
                            ? MemoryImage(
                                base64Decode(
                                  _existingProfilePictureUrl!.split(',').last,
                                ),
                              )
                            : (_existingProfilePictureUrl != null &&
                                  _existingProfilePictureUrl!.isNotEmpty)
                            ? NetworkImage(_existingProfilePictureUrl!)
                            : null,
                        child:
                            (_pickedImage == null &&
                                (_existingProfilePictureUrl == null ||
                                    _existingProfilePictureUrl!.isEmpty))
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
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wc_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _gender,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'MALE',
                                child: Text(l10n.genderMale),
                              ),
                              DropdownMenuItem(
                                value: 'FEMALE',
                                child: Text(l10n.genderFemale),
                              ),
                              DropdownMenuItem(
                                value: 'OTHER',
                                child: Text(l10n.genderOther),
                              ),
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
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                            _dateOfBirth != null
                                ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                                : l10n.selectDateOfBirth,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: _dateOfBirth != null
                                      ? null
                                      : AppColors.textSecondary,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
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

              // ── Phone Number ──
              _buildField(
                label: l10n.phoneNumber,
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
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
    final focusColor = AppColors.primaryBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE0E0E0),
              width: 1.2,
            ),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            validator: validator,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: readOnly ? AppColors.textSecondary : null,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, size: 20, color: AppColors.textSecondary),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
              suffixIcon: readOnly
                  ? Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 40),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: focusColor, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.alertRed, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.alertRed, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorStyle: TextStyle(fontSize: 12, color: AppColors.alertRed),
            ),
          ),
        ),
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
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
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
