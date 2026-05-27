import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/app_logger.dart';
import '../storage/drift/app_database.dart';

/// Subscribes to Supabase Realtime channels and merges incoming rows
/// into the local Drift database.
///
/// Lifecycle: call [subscribe] after sign-in, [unsubscribe] on sign-out.
///
/// Spec ref: 01-supabase-data-layer §Phase 6.
class RealtimeSubscriber {
  RealtimeSubscriber({required this._supabase, required this._db});

  final SupabaseClient _supabase;
  final AppDatabase _db;

  RealtimeChannel? _channel;

  void subscribe(String userId) {
    _channel = _supabase
        .channel('user-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dose_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: userId,
          ),
          callback: _mergeDoseEvent,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: _mergeNotification,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'prescriptions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: userId,
          ),
          callback: _mergePrescription,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'connections',
          callback: _mergeConnection,
        )
        .subscribe((status, [error]) {
          if (error != null) {
            appLogger.e('Realtime subscribe error', error: error);
          } else {
            appLogger.d('Realtime status: $status');
          }
        });
  }

  Future<void> unsubscribe() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  // ── Merge helpers ────────────────────────────────────────────────────

  Future<void> _mergeDoseEvent(PostgresChangePayload p) async {
    final row = p.newRecord;
    if (row.isEmpty) return;
    try {
      await _db.into(_db.doseEventsTable).insertOnConflictUpdate(
            DoseEventsTableCompanion.insert(
              id: row['id'] as String,
              prescriptionId: row['prescription_id'] as String,
              medicationId: row['medication_id'] as String,
              patientId: row['patient_id'] as String,
              scheduledTime: DateTime.parse(row['scheduled_time'] as String),
              timePeriod: row['time_period'] as String,
              status: Value(row['status'] as String? ?? 'DUE'),
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
            ),
          );
    } catch (e) {
      appLogger.e('Realtime merge dose_event failed', error: e);
    }
  }

  Future<void> _mergeNotification(PostgresChangePayload p) async {
    final row = p.newRecord;
    if (row.isEmpty) return;
    try {
      await _db.into(_db.notificationsTable).insertOnConflictUpdate(
            NotificationsTableCompanion.insert(
              id: row['id'] as String,
              recipientId: row['recipient_id'] as String,
              type: row['type'] as String,
              title: row['title'] as String,
              message: row['message'] as String,
              isRead: Value(row['is_read'] as bool? ?? false),
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          );
    } catch (e) {
      appLogger.e('Realtime merge notification failed', error: e);
    }
  }

  Future<void> _mergePrescription(PostgresChangePayload p) async {
    final row = p.newRecord;
    if (row.isEmpty) return;
    try {
      await _db.into(_db.prescriptionsTable).insertOnConflictUpdate(
            PrescriptionsTableCompanion.insert(
              id: row['id'] as String,
              patientId: row['patient_id'] as String,
              patientName: row['patient_name'] as String,
              patientGender: row['patient_gender'] as String,
              patientAge: row['patient_age'] as int,
              status: Value(row['status'] as String? ?? 'DRAFT'),
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
            ),
          );
    } catch (e) {
      appLogger.e('Realtime merge prescription failed', error: e);
    }
  }

  Future<void> _mergeConnection(PostgresChangePayload p) async {
    final row = p.newRecord;
    if (row.isEmpty) return;
    try {
      await _db.into(_db.connectionsTable).insertOnConflictUpdate(
            ConnectionsTableCompanion.insert(
              id: row['id'] as String,
              initiatorId: row['initiator_id'] as String,
              recipientId: row['recipient_id'] as String,
              status: Value(row['status'] as String? ?? 'PENDING'),
              requestedAt: DateTime.parse(row['requested_at'] as String),
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
            ),
          );
    } catch (e) {
      appLogger.e('Realtime merge connection failed', error: e);
    }
  }
}
