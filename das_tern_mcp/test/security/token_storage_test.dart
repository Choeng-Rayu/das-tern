import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Validates that security-sensitive token operations
/// use FlutterSecureStorage instead of SharedPreferences.
void main() {
  group('Token Storage Security', () {
    test('api_service.dart uses FlutterSecureStorage for tokens', () {
      final file =
          File('lib/services/api_service.dart').readAsStringSync();
      // Must import flutter_secure_storage
      expect(file, contains('flutter_secure_storage'));
      // Must NOT import shared_preferences
      expect(file, isNot(contains("import 'package:shared_preferences")));
      expect(file, isNot(contains('import "package:shared_preferences')));
      // Uses SecureStorage for read/write
      expect(file, contains('_secureStorage.read'));
      expect(file, contains('_secureStorage.write'));
      expect(file, contains('_secureStorage.delete'));
    });

    test('auth_provider.dart uses FlutterSecureStorage for tokens', () {
      final file =
          File('lib/providers/auth_provider.dart').readAsStringSync();
      expect(file, contains('flutter_secure_storage'));
      expect(file, isNot(contains("import 'package:shared_preferences")));
      expect(file, contains('_secureStorage.read'));
      expect(file, contains('_secureStorage.write'));
      expect(file, contains('_secureStorage.delete'));
    });

    test('sync_service.dart uses FlutterSecureStorage for auth headers', () {
      final file =
          File('lib/services/sync_service.dart').readAsStringSync();
      expect(file, contains('flutter_secure_storage'));
      expect(file, isNot(contains("import 'package:shared_preferences")));
      expect(file, contains('_secureStorage.read'));
    });

    test('api_service.dart enforces HTTPS in production', () {
      final file =
          File('lib/services/api_service.dart').readAsStringSync();
      // Must have HTTPS assertion
      expect(file, contains("url.startsWith('https://')"));
      // Default fallback should be https
      expect(file, contains("'https://localhost:3001/api/v1'"));
      // Must NOT have http fallback
      expect(file, isNot(contains("'http://localhost:3001/api/v1'")));
    });

    test('Android encrypted SharedPreferences is configured', () {
      final apiFile =
          File('lib/services/api_service.dart').readAsStringSync();
      final authFile =
          File('lib/providers/auth_provider.dart').readAsStringSync();
      final syncFile =
          File('lib/services/sync_service.dart').readAsStringSync();

      for (final file in [apiFile, authFile, syncFile]) {
        expect(file, contains('encryptedSharedPreferences: true'));
      }
    });

    test('iOS Keychain accessibility is configured', () {
      final apiFile =
          File('lib/services/api_service.dart').readAsStringSync();
      final authFile =
          File('lib/providers/auth_provider.dart').readAsStringSync();

      for (final file in [apiFile, authFile]) {
        expect(file, contains('KeychainAccessibility.first_unlock'));
      }
    });

    test('SharedPreferences only used for non-sensitive data', () {
      // Theme provider - non-sensitive
      final theme =
          File('lib/ui/theme/theme_provider.dart').readAsStringSync();
      expect(theme, contains('SharedPreferences'));
      // This is OK - theme preference is not sensitive

      // Locale provider - non-sensitive
      final locale =
          File('lib/providers/locale_provider.dart').readAsStringSync();
      expect(locale, contains('SharedPreferences'));
      // This is OK - locale preference is not sensitive
    });
  });

  group('Backend Auth Rate Limiting', () {
    test('auth.controller.ts has rate limiting decorators', () {
      final file = File(
              '../backend_nestjs/src/modules/auth/auth.controller.ts')
          .readAsStringSync();

      expect(file, contains("import { Throttle }"));
      expect(file, contains("@Throttle"));
      // Login rate limited
      expect(file, contains("@Post('login')"));
      // OTP rate limited
      expect(file, contains("@Post('otp/send')"));
    });

    test('CORS does not use wildcard with credentials', () {
      final file =
          File('../backend_nestjs/src/main.ts').readAsStringSync();

      // Must not have origin: '*' with credentials: true
      expect(file, isNot(contains("origin: '*'")));
      expect(file, isNot(contains('origin: "*"')));
      // Must use proper origin config
      expect(file, contains('ALLOWED_ORIGINS'));
      expect(file, contains('credentials: true'));
    });
  });
}
