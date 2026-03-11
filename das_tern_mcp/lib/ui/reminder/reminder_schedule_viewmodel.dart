import 'package:flutter/foundation.dart';
import 'package:das_tern_mcp/data/models/reminder.dart';
import 'package:das_tern_mcp/data/models/schedule_slot.dart';
import 'package:das_tern_mcp/data/repositories/medication_repository.dart';
import 'package:das_tern_mcp/data/repositories/reminder_repository.dart';
import 'package:das_tern_mcp/domain/use_cases/generate_schedule_use_case.dart';

class ReminderScheduleViewModel extends ChangeNotifier {
  ReminderScheduleViewModel({
    required ReminderRepository reminderRepository,
    required MedicationRepository medicationRepository,
    GenerateScheduleUseCase? generateScheduleUseCase,
  })  : _reminderRepo = reminderRepository,
        _medicationRepo = medicationRepository,
        _generateSchedule =
            generateScheduleUseCase ?? const GenerateScheduleUseCase();

  final ReminderRepository _reminderRepo;
  final MedicationRepository _medicationRepo;
  final GenerateScheduleUseCase _generateSchedule;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  List<ScheduleSlot> _scheduleSlots = [];
  List<ScheduleSlot> get scheduleSlots => _scheduleSlots;

  List<Reminder> _todayReminders = [];
  List<Reminder> get todayReminders => _todayReminders;

  Future<void> loadSchedule() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
      final results = await Future.wait([
        _reminderRepo.getTodayReminders(),
        _medicationRepo.getMedications(''),
      ]);
      _todayReminders = results[0] as List<Reminder>;
      final meds = results[1];
      _scheduleSlots = _generateSchedule(meds);
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markTaken(String reminderId) async {
    try {
      final updated = await _reminderRepo.markReminderTaken(reminderId);
      final idx = _todayReminders.indexWhere((r) => r.id == reminderId);
      if (idx != -1) {
        _todayReminders = List.of(_todayReminders)..[idx] = updated;
        notifyListeners();
      }
    } catch (_) {
      // Silent fail — UI can still show optimistic update
    }
  }
}
