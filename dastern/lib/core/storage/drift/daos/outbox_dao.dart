import 'package:drift/drift.dart';

import '../app_database.dart';

part 'outbox_dao.g.dart';

/// Data-access object for the outbox queue.
///
/// The [SyncEngine] is the only consumer. Feature repositories call
/// `SyncEngine.enqueue(...)` — they never touch this DAO directly.
///
/// Spec ref: 00-overview/design.md §5 "Sync engine".
@DriftAccessor(tables: [OutboxEntries])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  /// Adds a new entry to the outbox.
  Future<void> enqueue(OutboxEntriesCompanion entry) =>
      into(outboxEntries).insert(entry);

  /// Returns up to [limit] entries whose [OutboxEntry.nextAttemptAt] is
  /// in the past, ordered by [OutboxEntry.createdAt] (FIFO).
  Future<List<OutboxEntry>> dequeueBatch({int limit = 20}) {
    final now = DateTime.now();
    return (select(outboxEntries)
          ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Increments [attempts] and sets [nextAttemptAt] for exponential backoff.
  Future<void> markFailed(String id, String error, DateTime retryAt) async {
    final entry = await (select(
      outboxEntries,
    )..where((t) => t.id.equals(id))).getSingle();
    await (update(outboxEntries)..where((t) => t.id.equals(id))).write(
      OutboxEntriesCompanion(
        attempts: Value(entry.attempts + 1),
        lastError: Value(error),
        nextAttemptAt: Value(retryAt),
      ),
    );
  }

  /// Removes a successfully synced entry.
  Future<void> markSucceeded(String id) =>
      (delete(outboxEntries)..where((t) => t.id.equals(id))).go();

  /// Returns the current queue depth (for the diagnostics screen).
  Future<int> depth() => outboxEntries.count().getSingle();
}
