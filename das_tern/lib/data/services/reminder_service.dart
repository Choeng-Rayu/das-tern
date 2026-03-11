import 'dart:async';

import 'package:das_tern/data/models/reminder.dart';

abstract class ReminderService {
  Future<List<Reminder>> fetchReminders();
}

class MockReminderService implements ReminderService {
  @override
  Future<List<Reminder>> fetchReminders() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return const <Reminder>[
      Reminder(id: 'r-1', medicationName: 'Metformin', hour: 8, minute: 0),
      Reminder(id: 'r-2', medicationName: 'Amlodipine', hour: 13, minute: 0),
      Reminder(id: 'r-3', medicationName: 'Vitamin D', hour: 20, minute: 30),
    ];
  }
}
