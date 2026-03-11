/// Form-field validator helpers.
///
/// Each function matches the signature expected by [FormField.validator]:
/// `String? Function(String?)`. Return `null` when valid; return an error
/// message string when invalid.
///
/// Usage:
/// ```dart
/// TextFormField(
///   validator: Validators.required('Please enter your name'),
/// )
/// // or chain them:
/// TextFormField(
///   validator: (v) =>
///       Validators.required()(v) ?? Validators.email()(v),
/// )
/// ```
class Validators {
  Validators._();

  // ── Required ──────────────────────────────────────────────────────────────

  /// Returns an error [message] when the value is null or blank, otherwise
  /// returns `null`.
  static String? Function(String?) required([
    String message = 'This field is required',
  ]) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  // ── Email ─────────────────────────────────────────────────────────────────

  /// Returns an error [message] when the value is not a valid e-mail address.
  /// An empty/null value passes (use [required] first to reject empties).
  static String? Function(String?) email([
    String message = 'Enter a valid email address',
  ]) =>
      (value) {
        if (value == null || value.trim().isEmpty) return null;
        final emailRe = RegExp(
          r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
        );
        return emailRe.hasMatch(value.trim()) ? null : message;
      };

  // ── Phone ─────────────────────────────────────────────────────────────────

  /// Returns an error [message] when the value is not a plausible phone number
  /// (6–15 digits, optional leading `+`).
  static String? Function(String?) phone([
    String message = 'Enter a valid phone number',
  ]) =>
      (value) {
        if (value == null || value.trim().isEmpty) return null;
        final phoneRe = RegExp(r'^\+?[0-9]{6,15}$');
        return phoneRe.hasMatch(value.replaceAll(' ', '')) ? null : message;
      };

  // ── Password ──────────────────────────────────────────────────────────────

  /// Returns an error [message] when the value is shorter than [minLength]
  /// (defaults to 6 characters).
  static String? Function(String?) password({
    int minLength = 6,
    String? message,
  }) =>
      (value) {
        if (value == null || value.isEmpty) return null;
        final errMsg = message ?? 'Password must be at least $minLength characters';
        return value.length >= minLength ? null : errMsg;
      };

  /// Returns an error message when [value] does not match [other].
  ///
  /// Typically used for the *Confirm Password* field:
  /// ```dart
  /// validator: (v) => Validators.confirmPassword(
  ///   other: _passwordController.text,
  /// )(v),
  /// ```
  static String? Function(String?) confirmPassword({
    required String other,
    String message = 'Passwords do not match',
  }) =>
      (value) => value == other ? null : message;

  // ── Length ────────────────────────────────────────────────────────────────

  /// Returns an error when the trimmed value length is below [min].
  static String? Function(String?) minLength(
    int min, [
    String? message,
  ]) =>
      (value) {
        if (value == null || value.trim().isEmpty) return null;
        final errMsg = message ?? 'Must be at least $min characters';
        return value.trim().length >= min ? null : errMsg;
      };

  /// Returns an error when the trimmed value length exceeds [max].
  static String? Function(String?) maxLength(
    int max, [
    String? message,
  ]) =>
      (value) {
        if (value == null) return null;
        final errMsg = message ?? 'Must be at most $max characters';
        return value.trim().length <= max ? null : errMsg;
      };

  // ── Compose ───────────────────────────────────────────────────────────────

  /// Runs multiple validators in order and returns the first error found,
  /// or `null` if all pass.
  ///
  /// ```dart
  /// validator: Validators.compose([
  ///   Validators.required(),
  ///   Validators.email(),
  /// ]),
  /// ```
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) =>
      (value) {
        for (final v in validators) {
          final result = v(value);
          if (result != null) return result;
        }
        return null;
      };
}
