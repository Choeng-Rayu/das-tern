import 'package:flutter/material.dart';
import '../models/batch_model/medication_batch.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

/// Manages medication batch state with offline cache fallback.
class BatchProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;
  final SyncService _sync = SyncService.instance;
  final NotificationService _notifications = NotificationService.instance;

  bool _isLoading = false;
  String? _error;
  List<MedicationBatch> _batches = [];
  MedicationBatch? _selectedBatch;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MedicationBatch> get batches => _batches;
  MedicationBatch? get selectedBatch => _selectedBatch;

  int get activeBatchCount =>
      _batches.where((b) => b.isActive).length;

  /// Fetch batches. Online -> API + cache. Offline -> SQLite.
  Future<void> fetchBatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (_sync.isOnline) {
        final result = await _api.getBatches();
        _batches = result
            .map((b) =>
                MedicationBatch.fromJson(Map<String, dynamic>.from(b)))
            .toList();
        await _db.cacheBatches(
            result.map((b) => Map<String, dynamic>.from(b)).toList());
      } else {
        final cached = await _db.getCachedBatches();
        _batches = cached
            .map((b) => MedicationBatch.fromJson(b))
            .toList();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      try {
        final cached = await _db.getCachedBatches();
        if (cached.isNotEmpty) {
          _batches = cached
              .map((b) => MedicationBatch.fromJson(b))
              .toList();
          _error = null;
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch single batch details.
  Future<void> fetchBatch(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getBatch(id);
      _selectedBatch = MedicationBatch.fromJson(result);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new medication batch.
  /// Schedules a local notification at the batch's scheduledTime.
  Future<bool> createBatch(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (_sync.isOnline) {
        final result = await _api.createBatch(data);
        final batch = MedicationBatch.fromJson(result);

        // Schedule local notification
        await _scheduleBatchNotification(batch);

        await fetchBatches();
      } else {
        // Offline: cache locally and queue for sync
        await _db.cacheBatchLocally(data);
        await _db.addToSyncQueue(
          action: 'create_batch',
          endpoint: '/batch-medications',
          method: 'POST',
          body: data,
        );

        // Schedule notification even when offline
        final medicines = data['medicines'] as List<dynamic>? ?? [];
        final medicineNames = medicines
            .map((m) => (m as Map<String, dynamic>)['medicineName'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        final timeParts = (data['scheduledTime'] as String).split(':');
        final now = DateTime.now();
        var reminderTime = DateTime(
          now.year, now.month, now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        if (reminderTime.isBefore(now)) {
          reminderTime = reminderTime.add(const Duration(days: 1));
        }
        await _notifications.scheduleBatchReminder(
          batchId: 'local_${now.millisecondsSinceEpoch}',
          batchName: data['name'] as String,
          medicineNames: medicineNames,
          reminderTime: reminderTime,
        );

        // Reload from cache
        final cached = await _db.getCachedBatches();
        _batches = cached.map((b) => MedicationBatch.fromJson(b)).toList();
      }
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

  /// Update an existing batch.
  Future<bool> updateBatch(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.updateBatch(id, data);
      await fetchBatches();

      // Reschedule notification if time changed
      if (data.containsKey('scheduledTime')) {
        final batch = _batches.where((b) => b.id == id).firstOrNull;
        if (batch != null) {
          await _notifications.cancelBatchReminder(id);
          await _scheduleBatchNotification(batch);
        }
      }
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

  /// Delete a batch.
  Future<bool> deleteBatch(String id) async {
    try {
      await _api.deleteBatch(id);
      await _notifications.cancelBatchReminder(id);
      _batches.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Add a medicine to a batch.
  Future<bool> addMedicineToBatch(
      String batchId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.addMedicineToBatch(batchId, data);
      await fetchBatches();

      // Reschedule notification with updated medicine list
      final batch = _batches.where((b) => b.id == batchId).firstOrNull;
      if (batch != null) {
        await _notifications.cancelBatchReminder(batchId);
        await _scheduleBatchNotification(batch);
      }
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

  /// Remove a medicine from a batch.
  Future<bool> removeMedicineFromBatch(
      String batchId, String medicineId) async {
    try {
      await _api.removeMedicineFromBatch(batchId, medicineId);
      await fetchBatches();

      // Reschedule notification with updated medicine list
      final batch = _batches.where((b) => b.id == batchId).firstOrNull;
      if (batch != null) {
        await _notifications.cancelBatchReminder(batchId);
        await _scheduleBatchNotification(batch);
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Helper to schedule a daily notification for a batch.
  Future<void> _scheduleBatchNotification(MedicationBatch batch) async {
    if (!batch.isActive || batch.id == null) return;

    final medicineNames =
        batch.medications.map((m) => m.medicineName).toList();
    if (medicineNames.isEmpty) return;

    final timeParts = batch.scheduledTime.split(':');
    if (timeParts.length < 2) return;

    final now = DateTime.now();
    var reminderTime = DateTime(
      now.year, now.month, now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    // If the time has already passed today, schedule for tomorrow
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    await _notifications.scheduleBatchReminder(
      batchId: batch.id!,
      batchName: batch.name,
      medicineNames: medicineNames,
      reminderTime: reminderTime,
    );
  }
}
