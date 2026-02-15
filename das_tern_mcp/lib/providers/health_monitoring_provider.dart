import 'package:flutter/material.dart';
import '../models/health_model/health_vital.dart';
import '../models/health_model/vital_threshold.dart';
import '../models/health_model/health_alert.dart';
import '../services/api_service.dart';

class HealthMonitoringProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool _isLoading = false;
  String? _error;
  List<HealthVital> _vitals = [];
  List<HealthVital> _latestVitals = [];
  List<dynamic> _trends = [];
  List<VitalThreshold> _thresholds = [];
  List<HealthAlert> _alerts = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<HealthVital> get vitals => _vitals;
  List<HealthVital> get latestVitals => _latestVitals;
  List<dynamic> get trends => _trends;
  List<VitalThreshold> get thresholds => _thresholds;
  List<HealthAlert> get alerts => _alerts;

  int get unresolvedAlertCount =>
      _alerts.where((a) => !a.isResolved).length;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchLatestVitals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getLatestVitals();
      _latestVitals =
          result.map((v) => HealthVital.fromJson(v)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVitals({
    String? vitalType,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getVitals(
        vitalType: vitalType,
        startDate: startDate,
        endDate: endDate,
      );
      _vitals = result.map((v) => HealthVital.fromJson(v)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordVital(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.recordVital(data);
      await fetchLatestVitals();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVital(String id) async {
    try {
      await _api.deleteVital(id);
      _vitals.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchTrends({
    String? vitalType,
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _trends = await _api.getVitalTrends(
        vitalType: vitalType,
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchThresholds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getVitalThresholds();
      _thresholds =
          result.map((t) => VitalThreshold.fromJson(t)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateThreshold(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.updateVitalThreshold(data);
      await fetchThresholds();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAlerts({bool? resolved}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getHealthAlerts(resolved: resolved);
      _alerts = result.map((a) => HealthAlert.fromJson(a)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resolveAlert(String id) async {
    try {
      await _api.resolveHealthAlert(id);
      final idx = _alerts.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _alerts.removeAt(idx);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> triggerEmergency(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.triggerEmergency(data);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
