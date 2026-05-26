import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// String extensions
// ─────────────────────────────────────────────────────────────────────────────

extension StringExtensions on String {
  /// Returns `true` when the string is not empty after trimming.
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns `true` when the string is empty or contains only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Capitalises the first letter of the string.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Converts `snake_case` or `kebab-case` to `Title Case`.
  String get toTitleCase => split(RegExp(r'[_\- ]'))
      .map((w) => w.isEmpty ? w : w.capitalised)
      .join(' ');

  /// Returns `true` when the string looks like a valid e-mail address.
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  /// Returns `true` when the string contains 6–15 digits (international phones).
  bool get isValidPhone =>
      RegExp(r'^\+?[0-9]{6,15}$').hasMatch(replaceAll(' ', ''));

  /// Truncates to [maxLength] characters and appends `…` if the string is longer.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';
}

extension NullableStringExtensions on String? {
  /// Returns `true` when null or blank.
  bool get isNullOrBlank => this == null || this!.isBlank;
}

// ─────────────────────────────────────────────────────────────────────────────
// DateTime extensions
// ─────────────────────────────────────────────────────────────────────────────

extension DateTimeExtensions on DateTime {
  /// Formats as `dd/MM/yyyy` — the standard display format for the app.
  String get toDisplayDate => DateFormat('dd/MM/yyyy').format(this);

  /// Formats as `dd MMM yyyy` (e.g. `01 Jan 2025`).
  String get toMediumDate => DateFormat('dd MMM yyyy').format(this);

  /// Formats as `hh:mm a` (e.g. `09:30 AM`).
  String get toDisplayTime => DateFormat('hh:mm a').format(this);

  /// Formats as `dd/MM/yyyy hh:mm a`.
  String get toDisplayDateTime =>
      DateFormat('dd/MM/yyyy hh:mm a').format(this);

  /// Returns `true` when this date falls on today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns `true` when this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns a human-friendly relative label: *Today*, *Yesterday*, or the
  /// short medium date.
  String get toRelativeLabel {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return toMediumDate;
  }

  /// Returns the start of this day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the end of this day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extensions
// ─────────────────────────────────────────────────────────────────────────────

extension BuildContextExtensions on BuildContext {
  // ── Theme helpers ─────────────────────────────────────────────────────────

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── Screen size helpers ───────────────────────────────────────────────────

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  bool get isLargeScreen => screenWidth >= 600;

  // ── Navigation helpers ────────────────────────────────────────────────────

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(
        MaterialPageRoute(builder: (_) => page),
      );

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);

  Future<T?> pushReplacementNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.of(this)
          .pushReplacementNamed<T, dynamic>(routeName, arguments: arguments);

  Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName, {
    Object? arguments,
  }) =>
      Navigator.of(this).pushNamedAndRemoveUntil<T>(
        routeName,
        (route) => false,
        arguments: arguments,
      );

  // ── Snackbar helpers ──────────────────────────────────────────────────────

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showErrorSnackBar(String message) => showSnackBar(message, isError: true);
}
