import 'package:flutter/foundation.dart';
import 'package:das_tern_mcp/data/repositories/medication_repository.dart';

class AddMedicationViewModel extends ChangeNotifier {
  AddMedicationViewModel({
    required MedicationRepository repository,
    required String prescriptionId,
  })  : _repository = repository,
        _prescriptionId = prescriptionId;

  final MedicationRepository _repository;
  final String _prescriptionId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _success = false;
  bool get success => _success;

  String _name = '';
  String get name => _name;

  String _dosage = '';
  String get dosage => _dosage;

  String _unit = 'tablet';
  String get unit => _unit;

  int _frequency = 1;
  int get frequency => _frequency;

  final List<String> _scheduleTimes = [];
  List<String> get scheduleTimes => List.unmodifiable(_scheduleTimes);

  void setName(String v) { _name = v; notifyListeners(); }
  void setDosage(String v) { _dosage = v; notifyListeners(); }
  void setUnit(String v) { _unit = v; notifyListeners(); }
  void setFrequency(int v) { _frequency = v; notifyListeners(); }

  void addScheduleTime(String time) {
    _scheduleTimes.add(time);
    notifyListeners();
  }

  Future<void> submit() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _success = false;
    notifyListeners();
    try {
      await _repository.addMedication(_prescriptionId, {
        'name': _name,
        'dosage': _dosage,
        'unit': _unit,
        'frequency': _frequency,
        'scheduleTimes': _scheduleTimes
            .map((t) => {'time': t, 'period': _periodForTime(t)})
            .toList(),
      });
      _success = true;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to add medication.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Derives a time period string from an HH:mm time string.
  ///
  /// - 05:00–11:59 → MORNING
  /// - 12:00–17:59 → DAYTIME
  /// - 18:00–04:59 → NIGHT
  String _periodForTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8;
    if (hour >= 5 && hour < 12) return 'MORNING';
    if (hour >= 12 && hour < 18) return 'DAYTIME';
    return 'NIGHT';
  }
}
