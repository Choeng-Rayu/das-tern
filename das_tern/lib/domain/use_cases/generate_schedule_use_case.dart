import 'package:das_tern/data/models/reminder.dart';
import 'package:das_tern/data/models/schedule_slot.dart';

class GenerateScheduleUseCase {
  List<ScheduleSlot> call(List<Reminder> reminders) {
    final List<Reminder> morning = <Reminder>[];
    final List<Reminder> afternoon = <Reminder>[];
    final List<Reminder> night = <Reminder>[];

    for (final Reminder reminder in reminders) {
      if (reminder.hour >= 5 && reminder.hour <= 11) {
        morning.add(reminder);
      } else if (reminder.hour >= 12 && reminder.hour <= 17) {
        afternoon.add(reminder);
      } else {
        night.add(reminder);
      }
    }

    return <ScheduleSlot>[
      ScheduleSlot(period: SchedulePeriod.morning, reminders: morning),
      ScheduleSlot(period: SchedulePeriod.afternoon, reminders: afternoon),
      ScheduleSlot(period: SchedulePeriod.night, reminders: night),
    ];
  }
}
