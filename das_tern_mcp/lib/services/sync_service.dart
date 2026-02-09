import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'database_service.dart';
import 'notification_service.dart';

/// Monitors connectivity and auto-syncs offline actions when back online.
/// Also pulls fresh data from the server after sync.
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._();
  SyncService._();

  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notifications = NotificationService.instance;
  final Connectivity _connectivity = Connectivity();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _isSyncing = false;
  bool _isOnline = true;
  int _pendingCount = 0;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingCount => _pendingCount;

  String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3001/api/v1';

  // ────────────────────────────────────────────
  // Lifecycle
  // ────────────────────────────────────────────

  /// Start listening for connectivity changes.
  Future<void> startListening() async {
    // Check initial state
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(result);
      notifyListeners();

      // Just came back online → trigger sync
      if (!wasOnline && _isOnline) {
        debugPrint('[SyncService] Back online – syncing pending changes');
        syncAll();
      }
    });

    await _refreshPendingCount();
    notifyListeners();
  }

  void stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  /// Check connectivity right now.
  Future<bool> checkOnline() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    notifyListeners();
    return _isOnline;
  }

  // ────────────────────────────────────────────
  // Full sync cycle
  // ────────────────────────────────────────────

  /// Run a full sync: push pending → pull fresh data.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    if (!_isOnline) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Push offline actions (sync queue)
      await _processSyncQueue();

      // 2. Push offline dose status changes
      await _pushUnsyncedDoses();

      // 3. Pull fresh schedule
      await _pullDoseSchedule();

      // 4. Pull fresh prescriptions
      await _pullPrescriptions();

      debugPrint('[SyncService] Sync complete');
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
    } finally {
      _isSyncing = false;
      await _refreshPendingCount();
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────
  // Push: replay sync queue
  // ────────────────────────────────────────────

  Future<void> _processSyncQueue() async {
    final queue = await _db.getSyncQueue();
    if (queue.isEmpty) return;

    debugPrint('[SyncService] Processing ${queue.length} queued actions');

    for (final item in queue) {
      try {
        final method = item['method'] as String;
        final endpoint = item['endpoint'] as String;
        final bodyStr = item['body'] as String?;
        final headers = await _authHeaders();

        http.Response res;
        final uri = Uri.parse('$_baseUrl$endpoint');

        switch (method) {
          case 'PATCH':
            res = await http.patch(uri,
                headers: headers, body: bodyStr ?? '{}');
            break;
          case 'POST':
            res = await http.post(uri,
                headers: headers, body: bodyStr ?? '{}');
            break;
          case 'DELETE':
            res = await http.delete(uri, headers: headers);
            break;
          default:
            res = await http.get(uri, headers: headers);
        }

        if (res.statusCode >= 200 && res.statusCode < 300) {
          await _db.removeSyncQueueItem(item['id'] as int);
        } else {
          await _db.recordSyncError(
              item['id'] as int, 'HTTP ${res.statusCode}');
        }
      } catch (e) {
        await _db.recordSyncError(item['id'] as int, e.toString());
      }
    }

    // Clean up items that failed too many times
    await _db.pruneFailedItems();
  }

  // ────────────────────────────────────────────
  // Push: unsynced dose changes
  // ────────────────────────────────────────────

  Future<void> _pushUnsyncedDoses() async {
    final unsynced = await _db.getUnsyncedDoses();
    if (unsynced.isEmpty) return;

    debugPrint('[SyncService] Pushing ${unsynced.length} unsynced doses');
    final syncedIds = <String>[];

    for (final dose in unsynced) {
      try {
        final id = dose['id'] as String;
        final status = dose['status'] as String;
        final headers = await _authHeaders();
        http.Response res;

        if (status == 'TAKEN_ON_TIME' || status == 'TAKEN_LATE') {
          res = await http.patch(
            Uri.parse('$_baseUrl/doses/$id/taken'),
            headers: headers,
            body: jsonEncode({
              if (dose['takenAt'] != null) 'takenAt': dose['takenAt'],
              'offline': true,
            }),
          );
        } else if (status == 'SKIPPED') {
          res = await http.patch(
            Uri.parse('$_baseUrl/doses/$id/skipped'),
            headers: headers,
            body: jsonEncode({'reason': dose['skipReason'] ?? ''}),
          );
        } else {
          continue;
        }

        if (res.statusCode >= 200 && res.statusCode < 300) {
          syncedIds.add(id);
        }
      } catch (e) {
        debugPrint('[SyncService] Failed to push dose ${dose['id']}: $e');
      }
    }

    if (syncedIds.isNotEmpty) {
      await _db.markDosesSynced(syncedIds);
      debugPrint('[SyncService] Synced ${syncedIds.length} doses');
    }
  }

  // ────────────────────────────────────────────
  // Pull: fresh dose schedule
  // ────────────────────────────────────────────

  Future<void> _pullDoseSchedule() async {
    try {
      final headers = await _authHeaders();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final uri = Uri.parse('$_baseUrl/doses/schedule')
          .replace(queryParameters: {'date': today, 'groupBy': 'timePeriod'});

      final res = await http.get(uri, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data['doses'] != null) {
          final doses = List<Map<String, dynamic>>.from(data['doses']);
          await _db.cacheDoseEvents(doses);
          // Re-schedule local notifications for DUE doses
          await _notifications.scheduleAllReminders(doses);
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Pull schedule error: $e');
    }
  }

  // ────────────────────────────────────────────
  // Pull: fresh prescriptions
  // ────────────────────────────────────────────

  Future<void> _pullPrescriptions() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/prescriptions'),
        headers: headers,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          await _db.cachePrescriptions(
              List<Map<String, dynamic>>.from(data));
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Pull prescriptions error: $e');
    }
  }

  // ────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await _secureStorage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _refreshPendingCount() async {
    _pendingCount = await _db.pendingSyncCount();
    final unsyncedDoses = await _db.getUnsyncedDoses();
    _pendingCount += unsyncedDoses.length;
  }
}
