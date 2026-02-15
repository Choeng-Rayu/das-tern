import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/subscription_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
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
                  : l10n.patient,
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

            // Subscription card
            _SubscriptionCard(),
            const SizedBox(height: AppSpacing.md),

            // Settings list
            _SettingsSection(
              title: l10n.preferences,
              children: [
                // Theme toggle
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: Text(l10n.theme),
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

            _SettingsSection(
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
                  leading: const Icon(Icons.lock),
                  title: Text(l10n.changePassword),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to change password
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: Text(l10n.myConnections),
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
                label: Text(
                  l10n.logOut,
                  style: const TextStyle(color: AppColors.alertRed),
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

class _SubscriptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final tier = sub.currentTier;
    final isPremium = sub.isPremium;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/subscription/upgrade'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPremium
                      ? const Color(0xFF6B4AA3).withValues(alpha: 0.1)
                      : AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPremium ? Icons.diamond : Icons.star_outline,
                  color: isPremium ? const Color(0xFF6B4AA3) : AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.replaceAll('_', ' '),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      isPremium ? l10n.allFeaturesUnlocked : l10n.upgradeToUnlock,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.upgrade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
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
