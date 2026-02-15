import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Manages adherence data for the patient dashboard.
class AdherenceProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _todayAdherence;
  Map<String, dynamic>? _weeklyAdherence;
  Map<String, dynamic>? _monthlyAdherence;
  Map<String, dynamic>? _trends;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get todayAdherence => _todayAdherence;
  Map<String, dynamic>? get weeklyAdherence => _weeklyAdherence;
  Map<String, dynamic>? get monthlyAdherence => _monthlyAdherence;
  Map<String, dynamic>? get trends => _trends;

  double get todayPercentage =>
      (_todayAdherence?['percentage'] as num?)?.toDouble() ?? 0.0;
  int get todayTaken => (_todayAdherence?['taken'] as int?) ?? 0;
  int get todayTotal => (_todayAdherence?['total'] as int?) ?? 0;

  /// Fetch today's adherence summary.
  Future<void> fetchTodayAdherence() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _todayAdherence = await _api.getTodayAdherence();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch weekly adherence (7-day breakdown).
  Future<void> fetchWeeklyAdherence() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _weeklyAdherence = await _api.getWeeklyAdherence();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch monthly adherence (30-day weekly breakdown).
  Future<void> fetchMonthlyAdherence() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _monthlyAdherence = await _api.getMonthlyAdherence();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch adherence trends.
  Future<void> fetchTrends({int days = 30}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _trends = await _api.getAdherenceTrends(days: days);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all adherence data at once.
  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getTodayAdherence(),
        _api.getWeeklyAdherence(),
        _api.getMonthlyAdherence(),
      ]);
      _todayAdherence = results[0];
      _weeklyAdherence = results[1];
      _monthlyAdherence = results[2];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
