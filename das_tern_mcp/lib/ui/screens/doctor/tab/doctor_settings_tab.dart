import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/common_widgets.dart';

/// Settings tab for doctor - clean professional UI matching design standard.
class DoctorSettingsTab extends StatefulWidget {
  const DoctorSettingsTab({super.key});

  @override
  State<DoctorSettingsTab> createState() => _DoctorSettingsTabState();
}

class _DoctorSettingsTabState extends State<DoctorSettingsTab> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppHeader(title: l10n.settings),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor info card
            Container(
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: AppColors.primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _doctorName(auth.user),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user?['specialty'] ?? l10n.doctorRole,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // APPEARANCE
            _sectionLabel('APPEARANCE'),
            _buildGroupCard(isDark, [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.brightness_6_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.theme, style: Theme.of(context).textTheme.bodyLarge),
                    const Spacer(),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System', style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light', style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (v) => themeProvider.setThemeMode(v.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              _divider(isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.language_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.language, style: Theme.of(context).textTheme.bodyLarge),
                    const Spacer(),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: localeProvider.locale.languageCode,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'km', child: Text('\u1781\u17d2\u1798\u17c2\u179a')),
                        ],
                        onChanged: (v) {
                          if (v != null) localeProvider.changeLocale(Locale(v));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // NOTIFICATION PERMISSION
            _buildGroupCard(isDark, [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccess.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.statusSuccess,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Permission',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.statusSuccess, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Granted',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.statusSuccess,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // ACCOUNT (Edit Profile + Security + Logout)
            _sectionLabel('ACCOUNT'),
            _buildGroupCard(isDark, [
              _buildNavRow(
                context,
                icon: Icons.person_outline,
                label: l10n.editProfile,
                onTap: () {
                  // TODO: Navigate to edit profile page
                },
              ),
              _divider(isDark),
              _buildNavRow(
                context,
                icon: Icons.lock_outline,
                label: l10n.changePassword,
                onTap: () => _showChangePasswordSheet(context, l10n),
              ),
              _divider(isDark),
              InkWell(
                onTap: () => _confirmLogout(context, auth),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: AppColors.statusError, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.logout,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.statusError,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // SUBSCRIPTION
            _sectionLabel('SUBSCRIPTION'),
            _buildGroupCard(isDark, [
              _buildNavRow(
                context,
                icon: Icons.workspace_premium_outlined,
                label: 'Manage Subscriptions',
                onTap: () {
                  Navigator.pushNamed(context, '/subscription/upgrade');
                },
              ),
              _divider(isDark),
              _buildNavRow(
                context,
                icon: Icons.restore_rounded,
                label: 'Restore Subscription',
                isLast: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restoring subscription\u2026')),
                  );
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // RATE APP
            _buildGroupCard(isDark, [
              _buildNavRow(
                context,
                icon: Icons.star_outline_rounded,
                label: 'Rate App',
                isLast: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening app store\u2026')),
                  );
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // SUPPORT
            _sectionLabel('SUPPORT'),
            _buildGroupCard(isDark, [
              _buildNavRow(
                context,
                icon: Icons.mail_outline_rounded,
                label: 'Contact Us',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening contact\u2026')),
                  );
                },
              ),
              _divider(isDark),
              _buildNavRow(
                context,
                icon: Icons.article_outlined,
                label: 'Terms of Use',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Terms of Use\u2026')),
                  );
                },
              ),
              _divider(isDark),
              _buildNavRow(
                context,
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                isLast: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Privacy Policy\u2026')),
                  );
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  //  Helpers 

  String _doctorName(Map<String, dynamic>? user) {
    if (user == null) return 'Doctor';
    final first = user['firstName'] ?? '';
    final last = user['lastName'] ?? '';
    return '$first $last'.trim().isEmpty ? 'Doctor' : '$first $last'.trim();
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
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

  Widget _buildNavRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            )
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 48,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
    );
  }

  void _showChangePasswordSheet(BuildContext context, AppLocalizations l10n) {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.changePassword,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.oldPasswordHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newPasswordHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  // TODO: Implement change password API call
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.passwordChangeComingSoon)),
                  );
                },
                child: Text(l10n.changePassword),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.statusError),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
