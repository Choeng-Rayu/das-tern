/// Detects whether a credential string is an email, E.164 phone, or unknown.
enum CredentialKind { email, phone, unknown }

class CredentialKindDetector {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneRe = RegExp(r'^\+?[0-9]{8,15}$');

  static CredentialKind detect(String input) {
    final s = input.trim();
    if (_emailRe.hasMatch(s)) return CredentialKind.email;
    if (_phoneRe.hasMatch(s.replaceAll(RegExp(r'[\s\-()]'), ''))) {
      return CredentialKind.phone;
    }
    return CredentialKind.unknown;
  }

  static String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    return digits.startsWith('+') ? digits : '+$digits';
  }
}
