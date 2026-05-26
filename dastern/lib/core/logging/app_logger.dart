import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Project-wide [Logger] singleton.
///
/// Verbosity:
/// - Debug builds → `Level.debug` (everything from `d` and above).
/// - Release builds → `Level.warning` (only warnings/errors/wtf).
///
/// PII guidance: never pass patient names, phone numbers, prescription
/// text, or any free-form medical content into a log call. If an object
/// might contain PII, redact it at the call site (e.g., log the IDs only).
///
/// Spec ref: 00-overview §Requirement 6.
final Logger appLogger = Logger(
  level: kReleaseMode ? Level.warning : Level.debug,
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: !kReleaseMode,
    printEmojis: !kReleaseMode,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
