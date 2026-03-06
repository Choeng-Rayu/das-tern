import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/theme_provider.dart';

/// Doctor profile tab.
class DoctorProfileTab extends StatelessWidget {
  const DoctorProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: const Icon(
                Icons.medical_services,
                size: 36,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Dr. ${user?['fullName'] ?? l10n.doctorRole}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (user?['specialty'] != null)
              Text(
                user!['specialty'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            if (user?['hospitalClinic'] != null)
              Text(
                user!['hospitalClinic'],
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(height: AppSpacing.lg),

            // Theme toggle
            Card(
              child: ListTile(
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
            ),
            const SizedBox(height: AppSpacing.sm),

            // Language
            Card(
              child: ListTile(
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
            ),
            const SizedBox(height: AppSpacing.lg),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (!context.mounted) return;
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (_) => false);
                },
                icon: const Icon(Icons.logout, color: AppColors.alertRed),
                label: Text(
                  l10n.logOut,
                  style: TextStyle(color: AppColors.alertRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
