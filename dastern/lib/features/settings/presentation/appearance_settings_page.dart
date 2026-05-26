import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass/app_scaffold.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    return AppScaffold(
      title: l.appearance,
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + 8),
        children: <Widget>[
          _Header(l.theme),
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (next) {
              if (next == null) return;
              ref.read(themeModeControllerProvider.notifier).setMode(next);
            },
            child: Column(
              children: <Widget>[
                RadioListTile<ThemeMode>(
                  title: Text(l.lightTheme),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l.darkTheme),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l.systemTheme),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
          const Divider(),
          _Header(l.language),
          RadioGroup<Locale>(
            groupValue: locale,
            onChanged: (next) {
              if (next == null) return;
              ref.read(localeControllerProvider.notifier).setLocale(next);
            },
            child: Column(
              children: <Widget>[
                RadioListTile<Locale>(
                  title: Text(l.khmer),
                  value: const Locale('km'),
                ),
                RadioListTile<Locale>(
                  title: Text(l.english),
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

class _Header extends StatelessWidget {
  const _Header(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}
