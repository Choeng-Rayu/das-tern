import 'package:dastern/features/auth/data/credential_kind_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CredentialKindDetector.detect', () {
    test('valid email', () {
      expect(
        CredentialKindDetector.detect('user@example.com'),
        CredentialKind.email,
      );
    });

    test('email with subdomain', () {
      expect(
        CredentialKindDetector.detect('user@mail.example.co.uk'),
        CredentialKind.email,
      );
    });

    test('email with leading/trailing spaces', () {
      expect(
        CredentialKindDetector.detect('  user@example.com  '),
        CredentialKind.email,
      );
    });

    test('valid E.164 phone with +', () {
      expect(
        CredentialKindDetector.detect('+85512345678'),
        CredentialKind.phone,
      );
    });

    test('phone without + prefix', () {
      expect(
        CredentialKindDetector.detect('85512345678'),
        CredentialKind.phone,
      );
    });

    test('phone with spaces and dashes', () {
      expect(
        CredentialKindDetector.detect('+855 12-345-678'),
        CredentialKind.phone,
      );
    });

    test('too short number → unknown', () {
      expect(
        CredentialKindDetector.detect('1234567'),
        CredentialKind.unknown,
      );
    });

    test('empty string → unknown', () {
      expect(CredentialKindDetector.detect(''), CredentialKind.unknown);
    });

    test('plain text → unknown', () {
      expect(CredentialKindDetector.detect('notvalid'), CredentialKind.unknown);
    });

    test('missing TLD → unknown', () {
      expect(
        CredentialKindDetector.detect('user@example'),
        CredentialKind.unknown,
      );
    });
  });

  group('CredentialKindDetector.normalizePhone', () {
    test('adds + when missing', () {
      expect(CredentialKindDetector.normalizePhone('85512345678'), '+85512345678');
    });

    test('keeps + when present', () {
      expect(CredentialKindDetector.normalizePhone('+85512345678'), '+85512345678');
    });

    test('strips spaces and dashes', () {
      expect(
        CredentialKindDetector.normalizePhone('+855 12-345-678'),
        '+85512345678',
      );
    });
  });
}
