import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/schedule_slot.dart';
import 'package:das_tern/data/repositories/reminder_repository.dart';
import 'package:das_tern/domain/use_cases/generate_schedule_use_case.dart';
import 'package:flutter/foundation.dart';

class ReminderScheduleViewModel extends ChangeNotifier {
  ReminderScheduleViewModel({
    required ReminderRepository reminderRepository,
    required GenerateScheduleUseCase generateScheduleUseCase,
  }) : _reminderRepository = reminderRepository,
       _generateScheduleUseCase = generateScheduleUseCase {
    load = Command0(_load);
  }

  final ReminderRepository _reminderRepository;
  final GenerateScheduleUseCase _generateScheduleUseCase;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ScheduleSlot> _slots = <ScheduleSlot>[];
  List<ScheduleSlot> get slots => _slots;

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reminders = await _reminderRepository.getReminders();
      _slots = _generateScheduleUseCase(reminders);
    } catch (_) {
      _errorMessage = 'Unable to load schedule';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
