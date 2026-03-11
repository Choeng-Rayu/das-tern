import 'package:das_tern/data/services/notification_service.dart';

abstract class NotificationRepository {
  Future<List<String>> getNotifications();
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required NotificationService service})
    : _service = service;

  final NotificationService _service;

  @override
  Future<List<String>> getNotifications() {
    return _service.fetchNotifications();
  }
}
