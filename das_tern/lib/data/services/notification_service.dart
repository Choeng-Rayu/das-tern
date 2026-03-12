import 'dart:async';

import 'package:das_tern/data/models/app_notification.dart';
import 'package:das_tern/data/models/enums.dart';

abstract class NotificationService {
  Future<List<AppNotification>> fetchNotifications();
  Future<void> markAsRead(String id);
  Future<void> deleteNotification(String id);
}

class MockNotificationService implements NotificationService {
  final List<AppNotification> _items = [
    AppNotification(
      id: 'notif-1',
      userId: 'user-1',
      type: NotificationType.prescriptionUpdate,
      title: 'Morning Reminder',
      message: 'Morning reminder enabled',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif-2',
      userId: 'user-1',
      type: NotificationType.prescriptionUpdate,
      title: 'OCR Result',
      message: 'OCR result is ready for review',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<AppNotification>.unmodifiable(_items);
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final index = _items.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _items.removeWhere((n) => n.id == id);
  }
}
