import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../models/reminder_model/reminder.dart';
import '../models/reminder_model/reminder_settings.dart';

/// Manages reminder state for the patient dashboard.
class ReminderProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;

  bool _isLoading = false;
  String? _error;
  List<Reminder> _upcomingReminders = [];
  List<Reminder> _reminderHistory = [];
  ReminderSettings? _settings;
  int _historyPage = 1;
  bool _hasMoreHistory = true;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Reminder> get upcomingReminders => _upcomingReminders;
  List<Reminder> get reminderHistory => _reminderHistory;
  ReminderSettings? get settings => _settings;
  bool get hasMoreHistory => _hasMoreHistory;

  /// Load upcoming reminders (with offline fallback).
  Future<void> loadUpcoming({int days = 7}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getUpcomingReminders(days: days);
      _upcomingReminders = data
          .map((r) => Reminder.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      // Fallback to cached data
      try {
        final cached = await _db.getUpcomingCachedReminders();
        if (cached.isNotEmpty) {
          _upcomingReminders =
              cached.map((r) => Reminder.fromJson(r)).toList();
          _error = null;
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Snooze a reminder.
  Future<bool> snoozeReminder(String reminderId, int durationMinutes) async {
    try {
      await _api.snoozeReminder(reminderId, durationMinutes);
      final idx = _upcomingReminders.indexWhere((r) => r.id == reminderId);
      if (idx != -1) {
        _upcomingReminders[idx] = _upcomingReminders[idx].copyWith(
          status: 'SNOOZED',
          snoozeCount: _upcomingReminders[idx].snoozeCount + 1,
          snoozedUntil:
              DateTime.now().add(Duration(minutes: durationMinutes)),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Load reminder history (paginated).
  Future<void> loadHistory({
    String? startDate,
    String? endDate,
    String? status,
    bool refresh = false,
  }) async {
    if (refresh) {
      _historyPage = 1;
      _hasMoreHistory = true;
      _reminderHistory = [];
    }
    if (!_hasMoreHistory) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getReminderHistory(
        startDate: startDate,
        endDate: endDate,
        status: status,
        page: _historyPage,
      );
      final items = (data['data'] as List?)
              ?.map((r) =>
                  Reminder.fromJson(Map<String, dynamic>.from(r)))
              .toList() ??
          [];
      _reminderHistory.addAll(items);
      _hasMoreHistory = items.length >= 50;
      _historyPage++;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load reminder settings.
  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getReminderSettings();
      _settings = ReminderSettings.fromJson(data);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update reminder settings.
  Future<bool> updateSettings(Map<String, dynamic> data) async {
    try {
      final result = await _api.updateReminderSettings(data);
      _settings = ReminderSettings.fromJson(result);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Update medication reminder time.
  Future<bool> updateMedicationTime(
    String medicationId,
    String timePeriod,
    String newTime,
  ) async {
    try {
      await _api.updateMedicationReminderTime(
        medicationId,
        {'timePeriod': timePeriod, 'newTime': newTime},
      );
      await loadSettings();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Toggle medication reminders on/off.
  Future<bool> toggleMedicationReminders(
      String medicationId, bool enabled) async {
    try {
      await _api.toggleMedicationReminders(medicationId, enabled);
      await loadSettings();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Clear all state (for logout).
  void clear() {
    _upcomingReminders = [];
    _reminderHistory = [];
    _settings = null;
    _historyPage = 1;
    _hasMoreHistory = true;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
