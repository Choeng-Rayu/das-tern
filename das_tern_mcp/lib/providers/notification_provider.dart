import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model/notification.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';

/// Manages notification state.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    ApiService? apiService,
    LoggerService? loggerService,
  }) : _api = apiService ?? ApiService.instance,
       _log = loggerService ?? LoggerService.instance;

  final ApiService _api;
  final LoggerService _log;

  bool _isLoading = false;
  String? _error;
  List<AppNotification> _notifications = [];
  bool _hasFetched = false;

  /// Completer to deduplicate concurrent fetch calls.
  Completer<void>? _fetchCompleter;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasFetched => _hasFetched;

  /// Fetch notifications from the backend.
  /// Concurrent calls are deduplicated — if a fetch is in progress,
  /// subsequent callers await the same result.
  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    // If a fetch is already running, wait for it instead of starting another.
    if (_fetchCompleter != null) {
      _log.debug('NotificationProvider', 'Fetch already in progress, waiting…');
      return _fetchCompleter!.future;
    }

    _fetchCompleter = Completer<void>();
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _log.info(
        'NotificationProvider',
        'Fetching notifications (unreadOnly=$unreadOnly)',
      );
      final result = await _api.getNotifications(unreadOnly: unreadOnly);
      _log.debug(
        'NotificationProvider',
        'Raw API result keys: ${result.keys.toList()}',
      );

      // Backend returns { notifications: [...], unreadCount: N }
      dynamic rawList = result['notifications'] ?? result['data'] ?? [];
      final List list;
      if (rawList is List) {
        list = rawList;
      } else {
        _log.warning(
          'NotificationProvider',
          'Unexpected list type: ${rawList.runtimeType}',
        );
        list = <dynamic>[];
      }
      final parsed = list
          .map((n) {
            try {
              return AppNotification.fromJson(Map<String, dynamic>.from(n));
            } catch (e) {
              _log.error(
                'NotificationProvider',
                'Failed to parse notification',
                e,
              );
              return null;
            }
          })
          .whereType<AppNotification>()
          .toList();
      _notifications = parsed;
      _hasFetched = true;
      _log.success(
        'NotificationProvider',
        'Loaded ${_notifications.length} notifications',
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('NotificationProvider', 'fetchNotifications failed', e);
      // Keep existing _notifications so UI doesn't flash empty on transient errors
    } finally {
      _isLoading = false;
      _fetchCompleter?.complete();
      _fetchCompleter = null;
      notifyListeners();
    }
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      await fetchNotifications(); // Refresh full list
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('NotificationProvider', 'markAsRead failed', e);
      notifyListeners();
    }
  }

  /// Delete a notification.
  Future<void> deleteNotification(String id) async {
    try {
      await _api.deleteNotification(id);
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('NotificationProvider', 'deleteNotification failed', e);
      notifyListeners();
    }
  }

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
