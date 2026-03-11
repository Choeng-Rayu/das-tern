import 'package:das_tern/data/models/reminder.dart';
import 'package:das_tern/data/services/reminder_service.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getReminders();
}

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({required ReminderService service})
    : _service = service;

  final ReminderService _service;

  @override
  Future<List<Reminder>> getReminders() {
    return _service.fetchReminders();
  }
}
