import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../../../ui/theme/main_them.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Language Setting
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Consumer<LocaleProvider>(
              builder: (context, provider, _) {
                return Text(
                  provider.locale.languageCode == 'km' ? 'ភាសាខ្មែរ' : 'English',
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(),

          // Theme Setting
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n.theme),
            subtitle: Consumer<ThemeProvider>(
              builder: (context, provider, _) {
                return Text(
                  provider.themeMode == ThemeMode.light
                      ? l10n.lightTheme
                      : provider.themeMode == ThemeMode.dark
                          ? l10n.darkTheme
                          : l10n.systemTheme,
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          const Divider(),

          // Placeholder Settings
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(l10n.profile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comingSoon)),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(l10n.notifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comingSoon)),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.security),
            title: Text(l10n.security),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comingSoon)),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comingSoon)),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(l10n.logout, style: TextStyle(color: theme.colorScheme.error)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comingSoon)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<LocaleProvider>();

    showDialog(
      context: context,
      builder: (context) {
        final currentLocale = provider.locale.languageCode;
        return SimpleDialog(
          title: Text(l10n.selectLanguage),
          children: [
            SimpleDialogOption(
              onPressed: () {
                provider.changeLocale(const Locale('en'));
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    currentLocale == 'en' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  const Text('English'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                provider.changeLocale(const Locale('km'));
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    currentLocale == 'km' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  const Text('ភាសាខ្មែរ'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (context) {
        final currentTheme = provider.themeMode;
        return SimpleDialog(
          title: Text(l10n.selectTheme),
          children: [
            SimpleDialogOption(
              onPressed: () {
                provider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    currentTheme == ThemeMode.light ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(l10n.lightTheme),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                provider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    currentTheme == ThemeMode.dark ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(l10n.darkTheme),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                provider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    currentTheme == ThemeMode.system ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(l10n.systemTheme),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
