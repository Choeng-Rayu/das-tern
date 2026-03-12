import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/health_vital.dart';
import 'package:das_tern/data/repositories/health_repository.dart';
import 'package:flutter/foundation.dart';

class HealthViewModel extends ChangeNotifier {
  HealthViewModel({required HealthRepository healthRepository})
    : _healthRepository = healthRepository {
    load = Command0(_load);
  }

  final HealthRepository _healthRepository;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<HealthVital> _vitals = <HealthVital>[];
  List<HealthVital> get vitals => _vitals;

  List<HealthAlert> _alerts = <HealthAlert>[];
  List<HealthAlert> get alerts => _alerts;

  int get unresolvedAlertCount => _alerts.where((a) => !a.isResolved).length;

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vitals = await _healthRepository.getLatestVitals();
      _alerts = await _healthRepository.getAlerts();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> recordVital(HealthVital vital) async {
    try {
      final recorded = await _healthRepository.recordVital(vital);
      _vitals = [recorded, ..._vitals];
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> resolveAlert(String id) async {
    try {
      await _healthRepository.resolveAlert(id);
      _alerts = _alerts.where((a) => a.id != id).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
