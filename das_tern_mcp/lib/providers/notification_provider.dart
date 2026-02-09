import 'package:flutter/material.dart';
import '../models/notification_model/notification.dart';
import '../services/api_service.dart';

/// Manages notification state.
class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool _isLoading = false;
  String? _error;
  List<AppNotification> _notifications = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Fetch notifications.
  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getNotifications(unreadOnly: unreadOnly);
      final list = result['notifications'] ?? result['data'] ?? [];
      _notifications =
          (list as List).map((n) => AppNotification.fromJson(n)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        await fetchNotifications(); // Refresh
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
