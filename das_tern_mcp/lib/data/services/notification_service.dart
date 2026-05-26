/// Thin wrapper around [ApiService] for notification data endpoints.
///
/// NOTE: This is the *data-layer* notification service for fetching
/// in-app notification records from the backend. It is completely separate
/// from the platform push/local notification service at
/// `lib/services/notification_service.dart`.
library;

import '../../services/api_service.dart';

/// Service for in-app notification HTTP calls.
class NotificationDataService {
  NotificationDataService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  /// Fetches all notifications for the current user.
  ///
  /// Returns a map with `notifications` list and `unreadCount` keys.
  Future<Map<String, dynamic>> getNotifications({bool unreadOnly = false}) {
    return _api.getNotifications(unreadOnly: unreadOnly);
  }

  /// Marks a single notification as read by [id].
  Future<Map<String, dynamic>> markRead(String id) {
    return _api.markNotificationRead(id);
  }

  /// Marks every notification for the current user as read.
  ///
  /// Fetches all unread notifications and marks each one individually.
  Future<void> markAllRead() async {
    final data = await _api.getNotifications(unreadOnly: true);
    final list = data['notifications'];
    if (list is List) {
      final ids = list
          .whereType<Map<String, dynamic>>()
          .map((item) => item['id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();
      await Future.wait(ids.map((id) => _api.markNotificationRead(id)));
    }
  }

  /// Deletes a single notification by [id].
  Future<void> deleteNotification(String id) {
    return _api.deleteNotification(id);
  }
}
