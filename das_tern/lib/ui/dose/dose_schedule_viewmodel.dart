import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/dose_event.dart';
import 'package:das_tern/data/repositories/dose_repository.dart';
import 'package:flutter/foundation.dart';

class DoseScheduleViewModel extends ChangeNotifier {
  DoseScheduleViewModel({required DoseRepository doseRepository})
    : _doseRepository = doseRepository {
    load = Command0(_load);
  }

  final DoseRepository _doseRepository;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<DoseEvent> _doses = <DoseEvent>[];
  List<DoseEvent> get doses => _doses;

  int get totalDoses => _doses.length;
  int get takenDoses => _doses.where((d) => d.isTaken).length;
  double get progress => totalDoses > 0 ? takenDoses / totalDoses : 0;

  Map<String, List<DoseEvent>> get groupedDoses {
    final Map<String, List<DoseEvent>> groups = {};
    for (final dose in _doses) {
      final period = dose.timePeriod.isEmpty ? 'Other' : dose.timePeriod;
      groups.putIfAbsent(period, () => []).add(dose);
    }
    return groups;
  }

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _doses = await _doseRepository.getTodaySchedule();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markTaken(String doseId) async {
    try {
      final updated = await _doseRepository.markDoseTaken(doseId);
      final index = _doses.indexWhere((d) => d.id == doseId);
      if (index >= 0) {
        _doses = List.of(_doses)..[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> skipDose(String doseId, {String? reason}) async {
    try {
      final updated = await _doseRepository.skipDose(doseId, reason: reason);
      final index = _doses.indexWhere((d) => d.id == doseId);
      if (index >= 0) {
        _doses = List.of(_doses)..[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
