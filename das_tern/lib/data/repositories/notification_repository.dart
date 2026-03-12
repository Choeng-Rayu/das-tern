import 'package:das_tern/data/models/app_notification.dart';
import 'package:das_tern/data/services/notification_service.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> deleteNotification(String id);
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required NotificationService service})
    : _service = service;

  final NotificationService _service;

  @override
  Future<List<AppNotification>> getNotifications() {
    return _service.fetchNotifications();
  }

  @override
  Future<void> markAsRead(String id) {
    return _service.markAsRead(id);
  }

  @override
  Future<void> deleteNotification(String id) {
    return _service.deleteNotification(id);
  }
}
