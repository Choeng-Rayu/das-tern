import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Local SQLite database for offline dose caching and sync queue.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  static Database? _database;
  static const int _dbVersion = 1;
  static const String _dbName = 'das_tern.db';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cached dose events for offline viewing & reminder scheduling
    await db.execute('''
      CREATE TABLE dose_events (
        id TEXT PRIMARY KEY,
        prescription_id TEXT NOT NULL,
        medication_id TEXT NOT NULL,
        patient_id TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        time_period TEXT NOT NULL,
        reminder_time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'DUE',
        taken_at TEXT,
        skip_reason TEXT,
        was_offline INTEGER NOT NULL DEFAULT 0,
        medication_name TEXT NOT NULL DEFAULT '',
        dosage TEXT NOT NULL DEFAULT '',
        medication_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Sync queue for offline actions
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        body TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Cached prescriptions
    await db.execute('''
      CREATE TABLE prescriptions (
        id TEXT PRIMARY KEY,
        data_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Index for fast schedule lookups
    await db.execute(
        'CREATE INDEX idx_dose_scheduled ON dose_events(scheduled_time)');
    await db.execute(
        'CREATE INDEX idx_dose_status ON dose_events(status)');
    await db.execute(
        'CREATE INDEX idx_sync_queue_created ON sync_queue(created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ────────────────────────────────────────────
  // Dose Events
  // ────────────────────────────────────────────

  /// Save/update a list of dose events from the server.
  Future<void> cacheDoseEvents(List<Map<String, dynamic>> doses) async {
    final db = await database;
    final batch = db.batch();
    for (final dose in doses) {
      batch.insert(
        'dose_events',
        _doseToRow(dose),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get cached dose events for a given date (yyyy-MM-dd).
  Future<List<Map<String, dynamic>>> getCachedDosesByDate(String date) async {
    final db = await database;
    final rows = await db.query(
      'dose_events',
      where: "scheduled_time LIKE ?",
      whereArgs: ['$date%'],
      orderBy: 'scheduled_time ASC',
    );
    return rows.map(_rowToDose).toList();
  }

  /// Get all unsynced dose events.
  Future<List<Map<String, dynamic>>> getUnsyncedDoses() async {
    final db = await database;
    final rows = await db.query(
      'dose_events',
      where: 'synced = 0',
    );
    return rows.map(_rowToDose).toList();
  }

  /// Mark a dose as taken locally (offline).
  Future<void> markDoseTakenLocally(String id, DateTime takenAt) async {
    final db = await database;
    await db.update(
      'dose_events',
      {
        'status': 'TAKEN_ON_TIME',
        'taken_at': takenAt.toIso8601String(),
        'was_offline': 1,
        'synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark a dose as skipped locally (offline).
  Future<void> skipDoseLocally(String id, String reason) async {
    final db = await database;
    await db.update(
      'dose_events',
      {
        'status': 'SKIPPED',
        'skip_reason': reason,
        'was_offline': 1,
        'synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark doses as synced after successful server push.
  Future<void> markDosesSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.rawUpdate(
      'UPDATE dose_events SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  /// Get a single dose event by id.
  Future<Map<String, dynamic>?> getDoseById(String id) async {
    final db = await database;
    final rows = await db.query('dose_events', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToDose(rows.first);
  }

  // ────────────────────────────────────────────
  // Sync Queue
  // ────────────────────────────────────────────

  /// Add an action to the sync queue for later replay.
  Future<int> addToSyncQueue({
    required String action,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final db = await database;
    return db.insert('sync_queue', {
      'action': action,
      'endpoint': endpoint,
      'method': method,
      'body': body != null ? jsonEncode(body) : null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get all pending sync queue items.
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return db.query('sync_queue', orderBy: 'created_at ASC');
  }

  /// Remove a sync queue item after successful replay.
  Future<void> removeSyncQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Increment retry count and record last error.
  Future<void> recordSyncError(int id, String error) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  /// Remove items that have exceeded max retries.
  Future<int> pruneFailedItems({int maxRetries = 5}) async {
    final db = await database;
    return db.delete(
      'sync_queue',
      where: 'retry_count >= ?',
      whereArgs: [maxRetries],
    );
  }

  /// Get count of pending sync items.
  Future<int> pendingSyncCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ────────────────────────────────────────────
  // Prescriptions cache
  // ────────────────────────────────────────────

  /// Cache prescription data for offline access.
  Future<void> cachePrescriptions(List<Map<String, dynamic>> prescriptions) async {
    final db = await database;
    final batch = db.batch();
    for (final p in prescriptions) {
      batch.insert(
        'prescriptions',
        {
          'id': p['id'],
          'data_json': jsonEncode(p),
          'updated_at': p['updatedAt'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get cached prescriptions.
  Future<List<Map<String, dynamic>>> getCachedPrescriptions() async {
    final db = await database;
    final rows = await db.query('prescriptions', orderBy: 'updated_at DESC');
    return rows
        .map((r) =>
            Map<String, dynamic>.from(jsonDecode(r['data_json'] as String)))
        .toList();
  }

  // ────────────────────────────────────────────
  // Utilities
  // ────────────────────────────────────────────

  /// Clear all local data (for logout).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('dose_events');
    await db.delete('sync_queue');
    await db.delete('prescriptions');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // ── Row ↔ Map converters ──

  Map<String, dynamic> _doseToRow(Map<String, dynamic> dose) {
    return {
      'id': dose['id'],
      'prescription_id': dose['prescriptionId'],
      'medication_id': dose['medicationId'],
      'patient_id': dose['patientId'],
      'scheduled_time': dose['scheduledTime'],
      'time_period': dose['timePeriod'],
      'reminder_time': dose['reminderTime'],
      'status': dose['status'],
      'taken_at': dose['takenAt'],
      'skip_reason': dose['skipReason'],
      'was_offline': (dose['wasOffline'] == true) ? 1 : 0,
      'medication_name': dose['medicationName'] ??
          (dose['medication'] is Map
              ? dose['medication']['medicineName'] ?? ''
              : ''),
      'dosage': dose['dosage'] ??
          (dose['medication'] is Map
              ? '${dose['medication']['morningDosage'] ?? 0}'
              : ''),
      'medication_json':
          dose['medication'] != null ? jsonEncode(dose['medication']) : null,
      'created_at': dose['createdAt'],
      'updated_at': dose['updatedAt'],
      'synced': 1,
    };
  }

  Map<String, dynamic> _rowToDose(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'prescriptionId': row['prescription_id'],
      'medicationId': row['medication_id'],
      'patientId': row['patient_id'],
      'scheduledTime': row['scheduled_time'],
      'timePeriod': row['time_period'],
      'reminderTime': row['reminder_time'],
      'status': row['status'],
      'takenAt': row['taken_at'],
      'skipReason': row['skip_reason'],
      'wasOffline': row['was_offline'] == 1,
      'medicationName': row['medication_name'],
      'dosage': row['dosage'],
      'medication': row['medication_json'] != null
          ? jsonDecode(row['medication_json'] as String)
          : null,
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }
}
