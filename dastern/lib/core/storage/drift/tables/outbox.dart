import 'package:drift/drift.dart';

/// Outbox operation type — mirrors the Supabase REST verbs.
enum OutboxOpType { create, update, delete, rpc }

/// Pending mutations queued while offline.
///
/// Each row represents one write that the [SyncEngine] will replay against
/// Supabase when connectivity returns. Rows survive process restarts because
/// they live in SQLite.
///
/// Spec ref: 00-overview/design.md §5 "Sync engine".
class OutboxEntries extends Table {
  /// ULID string — sortable, collision-free, generated client-side.
  TextColumn get id => text()();

  /// Target Supabase table name (e.g. `'prescriptions'`).
  TextColumn get targetTable => text()();

  /// Operation type serialised as string.
  TextColumn get op => textEnum<OutboxOpType>()();

  /// JSON-encoded payload (row data for create/update, `{id}` for delete).
  TextColumn get payload => text()();

  /// How many times the SyncEngine has attempted this entry.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Earliest time the SyncEngine may retry (exponential backoff).
  DateTimeColumn get nextAttemptAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Last error message, if any.
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
