import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../../ui/theme/theme_provider.dart';
import '../../widgets/common_widgets.dart';

/// Settings tab for patient – matches Figma tab: ការកំណត់
/// Includes security (change password), theme, language, and logout.
class PatientSettingsTab extends StatefulWidget {
  const PatientSettingsTab({super.key});

  @override
  State<PatientSettingsTab> createState() => _PatientSettingsTabState();
}

class _PatientSettingsTabState extends State<PatientSettingsTab> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _showChangePassword = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeader(title: l10n.settings),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security section (matches Figma: សុវត្ថិភាព)
            _buildSection(
              context,
              icon: Icons.security,
              title: l10n.security,
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.changePassword),
                  trailing: Icon(
                    _showChangePassword
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() => _showChangePassword = !_showChangePassword);
                  },
                ),
                if (_showChangePassword) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _oldPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: l10n.oldPasswordHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: l10n.newPasswordHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implement change password API
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.passwordChangeComingSoon),
                                ),
                              );
                            },
                            child: Text(l10n.changePassword),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Preferences section
            _buildSection(
              context,
              icon: Icons.tune,
              title: l10n.preferences,
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: Text(l10n.theme),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 16),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (v) =>
                        themeProvider.setThemeMode(v.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  trailing: DropdownButton<String>(
                    value: localeProvider.locale.languageCode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'km', child: Text('ខ្មែរ')),
                    ],
                    onChanged: (v) {
                      if (v != null) localeProvider.changeLocale(Locale(v));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Subscription section
            _buildSection(
              context,
              icon: Icons.diamond_outlined,
              title: l10n.subscription,
              children: [
                ListTile(
                  leading: const Icon(Icons.upgrade, color: AppColors.primaryBlue),
                  title: Text(l10n.upgradePlan),
                  subtitle: Text(l10n.unlockPremiumFeatures),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/subscription/upgrade');
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Account section
            _buildSection(
              context,
              icon: Icons.person_outline,
              title: l10n.account,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(l10n.editProfile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to edit profile
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: AppColors.statusError),
                  title: Text(
                    l10n.logout,
                    style: TextStyle(color: AppColors.statusError),
                  ),
                  onTap: () => _confirmLogout(context, auth),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.statusError,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
