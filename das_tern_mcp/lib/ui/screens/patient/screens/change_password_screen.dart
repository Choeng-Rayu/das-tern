import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common_widgets.dart';

/// Full-page change password screen.
/// Requires current password + new password + confirm new password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordUpdated),
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
      appBar: AppHeader(title: l10n.changePassword),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Security icon header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primaryBlue,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Current Password ──
              _buildPasswordField(
                controller: _currentPasswordController,
                label: l10n.currentPassword,
                hint: l10n.oldPasswordHint,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.passwordEmpty;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ── New Password ──
              _buildPasswordField(
                controller: _newPasswordController,
                label: l10n.newPassword,
                hint: l10n.newPasswordHint,
                obscure: _obscureNew,
                onToggle: () =>
                    setState(() => _obscureNew = !_obscureNew),
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.newPasswordEmpty;
                  if (v.length < 6) return l10n.passwordTooShort;
                  if (v == _currentPasswordController.text) {
                    return 'New password must be different from current';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Confirm New Password ──
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: l10n.confirmNewPassword,
                hint: l10n.confirmNewPasswordHint,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                isDark: isDark,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return l10n.passwordMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.changePassword,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
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
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.28 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    obscureText: obscure,
                    validator: validator,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onToggle,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
