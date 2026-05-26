import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/locale_controller.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'l10n/app_localizations.dart';

/// Root application widget.
///
/// Reads the active [ThemeMode] and [Locale] from Riverpod controllers and
/// rebuilds [MaterialApp.router] in place when either changes — no app
/// restart required.
class DasTernApp extends ConsumerWidget {
  const DasTernApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeControllerProvider);
    final Locale locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'Das Tern',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: mode,
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
