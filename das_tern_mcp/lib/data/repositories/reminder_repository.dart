/// Repository for daily medication reminders (dose events).
///
/// Translates raw JSON from [ReminderService] into clean
/// [Reminder] domain models.
library;

import '../models/reminder.dart';
import '../services/reminder_service.dart';

/// Abstract contract enabling easy test doubles.
abstract class ReminderRepository {
  /// Returns all dose reminders scheduled for today.
  Future<List<Reminder>> getTodayReminders();

  /// Marks the dose identified by [id] as taken.
  ///
  /// Returns the updated [Reminder] reflecting the new state.
  Future<Reminder> markReminderTaken(String id);

  /// Returns upcoming dose reminders (next 7 days).
  Future<List<Reminder>> getUpcomingReminders();
}

// ── Implementation ────────────────────────────────────────────────────────────

/// Concrete implementation backed by [ReminderService].
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({ReminderService? service})
      : _service = service ?? ReminderService();

  final ReminderService _service;

  @override
  Future<List<Reminder>> getTodayReminders() async {
    try {
      final json = await _service.getTodayReminders();
      return _extractRemindersFromSchedule(json);
    } catch (e) {
      throw ReminderException('Failed to fetch today\'s reminders: $e');
    }
  }

  @override
  Future<Reminder> markReminderTaken(String id) async {
    try {
      final json = await _service.markReminderTaken(id);
      return Reminder.fromJson(json);
    } catch (e) {
      throw ReminderException('Failed to mark reminder $id as taken: $e');
    }
  }

  @override
  Future<List<Reminder>> getUpcomingReminders() async {
    try {
      final list = await _service.getUpcomingReminders();
      return list
          .whereType<Map<String, dynamic>>()
          .map(Reminder.fromJson)
          .toList();
    } catch (e) {
      throw ReminderException('Failed to fetch upcoming reminders: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// The backend returns a schedule keyed by period (e.g. `{"morning": [...]}`).
  /// This helper flattens all periods into a single [Reminder] list.
  List<Reminder> _extractRemindersFromSchedule(Map<String, dynamic> json) {
    final reminders = <Reminder>[];

    // Try a flat `doses` or `schedule` list first.
    final directList = json['doses'] ?? json['schedule'];
    if (directList is List) {
      return directList
          .whereType<Map<String, dynamic>>()
          .map(Reminder.fromJson)
          .toList();
    }

    // Otherwise iterate period keys.
    for (final key in json.keys) {
      final value = json[key];
      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            reminders.add(Reminder.fromJson(item));
          }
        }
      }
    }
    return reminders;
  }
}

// ── Exception ─────────────────────────────────────────────────────────────────

/// Thrown by [ReminderRepositoryImpl] when an operation fails.
class ReminderException implements Exception {
  const ReminderException(this.message);
  final String message;

  @override
  String toString() => 'ReminderException: $message';
}
