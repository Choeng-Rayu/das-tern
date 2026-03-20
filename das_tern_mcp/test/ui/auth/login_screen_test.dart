import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:das_tern_mcp/l10n/app_localizations.dart';
import 'package:das_tern_mcp/providers/auth_provider.dart';
import 'package:das_tern_mcp/providers/locale_provider.dart';
import 'package:das_tern_mcp/ui/screens/auth/login_screen.dart';

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider() : super(enableTelegramDeepLinkListener: false);

  bool telegramCalled = false;

  @override
  Future<bool> signInWithTelegram({String? userRole}) async {
    telegramCalled = true;
    return false;
  }
}

void main() {
  testWidgets('renders Telegram button and handles tap', (tester) async {
    final fakeAuth = _FakeAuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
          routes: {
            '/register-role': (_) => const Scaffold(body: Text('register')),
            '/forgot-password': (_) => const Scaffold(body: Text('forgot')),
            '/patient': (_) => const Scaffold(body: Text('patient')),
            '/doctor': (_) => const Scaffold(body: Text('doctor')),
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign in with Telegram'), findsOneWidget);

    await tester.ensureVisible(find.text('Sign in with Telegram'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with Telegram'));
    await tester.pumpAndSettle();

    expect(fakeAuth.telegramCalled, isTrue);
  });
}
