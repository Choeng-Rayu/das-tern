import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Centralized logging service with structured, filterable logs.
/// All logs are timestamped and categorized by level and source.
class LoggerService {
  static final LoggerService instance = LoggerService._();
  LoggerService._();

  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _green = '\x1B[32m';
  static const String _cyan = '\x1B[36m';
  static const String _magenta = '\x1B[35m';

  final _dateFormat = DateFormat('HH:mm:ss.SSS');

  /// Log a debug message (development only).
  void debug(String source, String message, [Object? data]) {
    if (kDebugMode) {
      _log('DEBUG', _cyan, source, message, data);
    }
  }

  /// Log an info message (always logged).
  void info(String source, String message, [Object? data]) {
    _log('INFO', _blue, source, message, data);
  }

  /// Log a warning message (always logged).
  void warning(String source, String message, [Object? data]) {
    _log('WARN', _yellow, source, message, data);
  }

  /// Log an error message (always logged).
  void error(String source, String message, Object error, [StackTrace? stackTrace]) {
    _log('ERROR', _red, source, message, error);
    if (stackTrace != null && kDebugMode) {
      debugPrint('$_red[STACK] $stackTrace$_reset');
    }
  }

  /// Log a success message (always logged).
  void success(String source, String message, [Object? data]) {
    _log('SUCCESS', _green, source, message, data);
  }

  /// Log an API request.
  void apiRequest(String method, String endpoint, [Object? body]) {
    _log('API→', _magenta, 'ApiService', '$method $endpoint', body);
  }

  /// Log an API response.
  void apiResponse(String method, String endpoint, int statusCode, [Object? data]) {
    final color = statusCode >= 200 && statusCode < 300 ? _green : _red;
    _log('API←', color, 'ApiService', '$method $endpoint [$statusCode]', data);
  }

  /// Log a state change.
  void stateChange(String provider, String from, String to, [String? reason]) {
    final msg = reason != null ? '$from → $to ($reason)' : '$from → $to';
    _log('STATE', _cyan, provider, msg, null);
  }

  /// Log a database operation.
  void dbOperation(String operation, String table, [Object? details]) {
    _log('DB', _blue, 'DatabaseService', '$operation on $table', details);
  }

  /// Log a sync operation.
  void syncOperation(String operation, [Object? details]) {
    _log('SYNC', _magenta, 'SyncService', operation, details);
  }

  /// Log a notification operation.
  void notificationOperation(String operation, [Object? details]) {
    _log('NOTIF', _yellow, 'NotificationService', operation, details);
  }

  void _log(String level, String color, String source, String message, Object? data) {
    final timestamp = _dateFormat.format(DateTime.now());
    final prefix = '$color[$timestamp][$level][$source]$_reset';
    debugPrint('$prefix $message');
    if (data != null && kDebugMode) {
      debugPrint('$color  ↳ Data: ${_truncate(data.toString(), 500)}$_reset');
    }
  }

  String _truncate(String text, int maxLength) {
    return text.length <= maxLength ? text : '${text.substring(0, maxLength)}...';
  }
}
