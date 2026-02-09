import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../../ui/theme/theme_provider.dart';

/// Settings tab for doctor – matches Figma tab: ការកំណត់
/// Includes security, theme, language, and logout.
class DoctorSettingsTab extends StatefulWidget {
  const DoctorSettingsTab({super.key});

  @override
  State<DoctorSettingsTab> createState() => _DoctorSettingsTabState();
}

class _DoctorSettingsTabState extends State<DoctorSettingsTab> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('ការកំណត់'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor info card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.medical_services,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _doctorName(auth.user),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            auth.user?['specialty'] ?? 'Doctor',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Security section (matches Figma: សុវត្ថិភាព)
            _buildSection(
              context,
              icon: Icons.security,
              title: 'សុវត្ថិភាព',
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('ប្តូរលេខសម្ងាត់'),
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
                          decoration: const InputDecoration(
                            hintText: 'បំពេញលេខសម្ងាត់ចាស់',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'បំពេញលេខសម្ងាត់ថ្មី',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password change coming soon'),
                                ),
                              );
                            },
                            child: const Text('ប្តូរលេខសម្ងាត់'),
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

            // Preferences
            _buildSection(
              context,
              icon: Icons.tune,
              title: 'Preferences',
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
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
                  title: const Text('Language'),
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

            // Account
            _buildSection(
              context,
              icon: Icons.person_outline,
              title: 'Account',
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to edit profile
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: AppColors.statusError),
                  title: Text(
                    'Logout',
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

  String _doctorName(Map<String, dynamic>? user) {
    if (user == null) return 'Doctor';
    final first = user['firstName'] ?? '';
    final last = user['lastName'] ?? '';
    return '$first $last'.trim().isEmpty ? 'Doctor' : '$first $last'.trim();
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
