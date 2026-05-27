import 'package:intl/intl.dart';

/// Khmer numeral helper.
/// Spec ref: 09-design-system-localization §7.1.
class KhmerNumber {
  const KhmerNumber._();

  static const List<String> _digits = <String>[
    '០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩',
  ];

  /// Converts an integer to its Khmer numeral representation.
  /// e.g. 42 → '៤២'
  static String fromInt(int n) => n.toString().split('').map((c) {
        final d = int.tryParse(c);
        return d != null ? _digits[d] : c;
      }).join();

  /// Converts a double to Khmer numerals with [fractionDigits] decimal places.
  static String fromDouble(double n, {int fractionDigits = 0}) =>
      n.toStringAsFixed(fractionDigits).split('').map((c) {
        final d = int.tryParse(c);
        return d != null ? _digits[d] : c;
      }).join();
}

/// Date and currency formatters that respect the active locale.
/// Spec ref: 09-design-system-localization §7.2–7.3.
class AppFormatters {
  const AppFormatters._();

  /// Formats a [DateTime] as a short date string for the given [locale].
  /// e.g. en → "Jan 15, 2026"  |  km → "15 មករា 2026"
  static String date(DateTime dt, String locale) =>
      DateFormat.yMMMd(locale).format(dt);

  /// Formats a [DateTime] as a short time string for the given [locale].
  /// Both en and km use 12h format per spec.
  static String time(DateTime dt, String locale) =>
      DateFormat.jm(locale).format(dt);

  /// Formats a [DateTime] as date + time.
  static String dateTime(DateTime dt, String locale) =>
      '${date(dt, locale)} ${time(dt, locale)}';

  /// Formats a USD amount. Always uses the $ symbol regardless of locale.
  /// e.g. 0.5 → "\$0.50"
  /// Spec ref: 09-design-system-localization §7.3.
  static String usd(double amount) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);

  /// Formats a percentage for the given locale.
  /// When locale is 'km', uses Khmer numerals.
  static String percent(double ratio, String locale) {
    final pct = (ratio * 100).round();
    if (locale == 'km') return '${KhmerNumber.fromInt(pct)}%';
    return '$pct%';
  }
}
