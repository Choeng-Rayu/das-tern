import 'package:flutter/foundation.dart';
import '../models/dose_event_model/dose_event.dart';
import '../services/api_service.dart';

class DoseEventProviderV2 extends ChangeNotifier {
  Map<String, List<DoseEvent>> _dosesByTimeGroup = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<DoseEvent> getDoseEventsByTimeGroup(String timeGroup) {
    return _dosesByTimeGroup[timeGroup.toUpperCase()] ?? [];
  }

  int get totalCount {
    return _dosesByTimeGroup.values.fold(0, (sum, list) => sum + list.length);
  }

  int get completedCount {
    return _dosesByTimeGroup.values
        .fold(0, (sum, list) => sum + list.where((d) => d.status == 'TAKEN_ON_TIME' || d.status == 'TAKEN_LATE').length);
  }

  Future<void> loadTodayDoseEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final data = await ApiService.instance.getDoseSchedule(date: today);
      
      _dosesByTimeGroup = {};
      if (data['daytime'] != null) {
        _dosesByTimeGroup['DAYTIME'] = (data['daytime'] as List)
            .map((json) => DoseEvent.fromJson(json))
            .toList();
      }
      if (data['night'] != null) {
        _dosesByTimeGroup['NIGHT'] = (data['night'] as List)
            .map((json) => DoseEvent.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markDoseTaken(String doseId, {bool wasOffline = false}) async {
    try {
      final data = await ApiService.instance.markDoseTaken(
        doseId,
        takenAt: DateTime.now(),
        wasOffline: wasOffline,
      );
      final updated = DoseEvent.fromJson(data);
      _updateDoseInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> skipDose(String doseId, String reason) async {
    try {
      final data = await ApiService.instance.skipDose(doseId, reason);
      final updated = DoseEvent.fromJson(data);
      _updateDoseInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _updateDoseInList(DoseEvent updated) {
    for (var timeGroup in _dosesByTimeGroup.keys) {
      final list = _dosesByTimeGroup[timeGroup]!;
      final index = list.indexWhere((d) => d.id == updated.id);
      if (index != -1) {
        list[index] = updated;
        break;
      }
    }
  }
}
