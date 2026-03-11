import 'package:flutter/foundation.dart';

import 'package:das_tern_mcp/data/models/medication.dart';
import 'package:das_tern_mcp/data/models/reminder.dart';
import 'package:das_tern_mcp/data/models/schedule_slot.dart';
import 'package:das_tern_mcp/data/repositories/medication_repository.dart';
import 'package:das_tern_mcp/data/repositories/reminder_repository.dart';
import 'package:das_tern_mcp/domain/use_cases/generate_schedule_use_case.dart';

/// ViewModel for the Home screen.
///
/// Loads today's reminders and upcoming medications, then groups medications
/// into time-period schedule slots via [GenerateScheduleUseCase].
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
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

  // ── State ─────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Reminder> _todayReminders = [];
  List<Reminder> get todayReminders => _todayReminders;

  List<Medication> _upcomingMedications = [];
  List<Medication> get upcomingMedications => _upcomingMedications;

  List<ScheduleSlot> _scheduleSlots = [];
  List<ScheduleSlot> get scheduleSlots => _scheduleSlots;

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Returns a time-of-day greeting.
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetches today's reminders and upcoming medications.
  Future<void> loadData() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _reminderRepo.getTodayReminders(),
        _medicationRepo.getMedications(''),
      ]);

      _todayReminders = results[0] as List<Reminder>;
      _upcomingMedications = results[1] as List<Medication>;
      _scheduleSlots = _generateSchedule(_upcomingMedications);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load home data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes all data.
  Future<void> refresh() => loadData();
}
