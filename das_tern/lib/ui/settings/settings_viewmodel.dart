import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/app_notification.dart';
import 'package:das_tern/data/models/user.dart';
import 'package:das_tern/data/repositories/auth_repository.dart';
import 'package:das_tern/data/repositories/notification_repository.dart';
import 'package:flutter/foundation.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required NotificationRepository notificationRepository,
    required AuthRepository authRepository,
  }) : _notificationRepository = notificationRepository,
       _authRepository = authRepository {
    load = Command0(_load);
  }

  final NotificationRepository _notificationRepository;
  final AuthRepository _authRepository;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? _user;
  User? get user => _user;

  List<AppNotification> _notifications = <AppNotification>[];
  List<AppNotification> get notifications => _notifications;

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();

    _user = await _authRepository.getCurrentUser();
    _notifications = await _notificationRepository.getNotifications();

    _isLoading = false;
    notifyListeners();
  }
}
