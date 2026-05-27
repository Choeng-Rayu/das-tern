import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';

/// Root application widget.
///
/// Subscribes to [onAuthStateChange] (§10.1) and handles:
/// - signedOut → clear secure storage + navigate to /welcome (§10.2)
/// - tokenRefreshed → persist new tokens (§10.3)
/// - userUpdated → invalidate profile cache (§10.4)
class DasTernApp extends ConsumerStatefulWidget {
  const DasTernApp({super.key});

  @override
  ConsumerState<DasTernApp> createState() => _DasTernAppState();
}

class _DasTernAppState extends ConsumerState<DasTernApp>
    with WidgetsBindingObserver {
  DateTime? _lastValidated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenAuthState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // §10.5 — re-validate on foreground resume if >30 min since last check
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    final last = _lastValidated;
    if (last == null || now.difference(last).inMinutes >= 30) {
      _refreshIfOnline();
    }
  }

  Future<void> _refreshIfOnline() async {
    try {
      await Supabase.instance.client.auth.refreshSession();
      _lastValidated = DateTime.now();
    } catch (_) {
      // Offline or session expired — redirect handled by onAuthStateChange
    }
  }

  void _listenAuthState() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
        final storage = ref.read(authSessionStorageProvider);
        switch (event.event) {
          case AuthChangeEvent.signedOut:
            // §10.2 — clear tokens
            await storage.clear();
            if (mounted) ref.read(appRouterProvider).go('/welcome');
          case AuthChangeEvent.tokenRefreshed:
            // §10.3 — persist refreshed tokens
            if (event.session != null) {
              await storage.persist(event.session!);
              _lastValidated = DateTime.now();
            }
          case AuthChangeEvent.userUpdated:
            // §10.4 — refetch profile
            ref.invalidate(currentUserProfileProvider);
          default:
            break;
        }
      });
    } catch (_) {
      // Supabase not initialized in tests
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

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
