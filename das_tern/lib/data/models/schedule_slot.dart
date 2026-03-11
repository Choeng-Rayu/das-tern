import 'package:das_tern/data/models/reminder.dart';

enum SchedulePeriod { morning, afternoon, night }

class ScheduleSlot {
  const ScheduleSlot({
    required this.period,
    required this.reminders,
  });

  final SchedulePeriod period;
  final List<Reminder> reminders;
}
