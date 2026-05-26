import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/app_localizations.dart';

/// Theme + language switcher.
///
/// Both controls persist via the [ThemeModeController] / [LocaleController]
/// providers, which write to [SharedPreferences] under the hood. Changes
/// apply without restart because [MaterialApp] reads the controllers in
/// the root `App` widget.
///
/// Spec ref: 09-design-system-localization §Requirement 5, §Requirement 12.
class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final ThemeMode mode = ref.watch(themeModeControllerProvider);
    final Locale locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAppearance)),
      body: ListView(
        children: <Widget>[
          _SectionHeader(label: l.settingsAppearance),
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (ThemeMode? next) {
              if (next == null) return;
              ref.read(themeModeControllerProvider.notifier).setMode(next);
            },
            child: Column(
              children: <Widget>[
                RadioListTile<ThemeMode>(
                  title: Text(l.settingsThemeLight),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l.settingsThemeDark),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l.settingsThemeSystem),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(label: l.settingsLanguage),
          RadioGroup<Locale>(
            groupValue: locale,
            onChanged: (Locale? next) {
              if (next == null) return;
              ref.read(localeControllerProvider.notifier).setLocale(next);
            },
            child: Column(
              children: <Widget>[
                RadioListTile<Locale>(
                  title: Text(l.settingsLanguageKm),
                  value: const Locale('km'),
                ),
                RadioListTile<Locale>(
                  title: Text(l.settingsLanguageEn),
                  value: const Locale('en'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
