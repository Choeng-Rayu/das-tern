import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../../ui/theme/theme_provider.dart';

/// Patient profile tab – shows user info, settings, and logout.
class PatientProfileTab extends StatelessWidget {
  const PatientProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Avatar and name
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                _initials(user),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              user?['firstName'] != null
                  ? '${user!['firstName']} ${user['lastName'] ?? ''}'
                  : 'Patient',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              user?['phoneNumber'] ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Settings list
            _SettingsSection(
              title: 'Preferences',
              children: [
                // Theme toggle
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 16)),
                      ButtonSegment(
                          value: ThemeMode.system, icon: Icon(Icons.settings, size: 16)),
                      ButtonSegment(
                          value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 16)),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (v) => themeProvider.setThemeMode(v.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                // Language
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

            _SettingsSection(
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
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to change password
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('My Connections'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to connections
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.alertRed),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.alertRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(Map<String, dynamic>? user) {
    if (user == null) return '?';
    final first = (user['firstName'] ?? '').toString();
    final last = (user['lastName'] ?? '').toString();
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}
