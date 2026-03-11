import 'dart:async';

abstract class NotificationService {
  Future<List<String>> fetchNotifications();
}

class MockNotificationService implements NotificationService {
  @override
  Future<List<String>> fetchNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const <String>[
      'Morning reminder enabled',
      'OCR result is ready for review',
    ];
  }
}
