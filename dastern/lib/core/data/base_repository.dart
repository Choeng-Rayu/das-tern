import '../storage/drift/app_database.dart';
import '../sync/sync_engine.dart';
/// Base class for all feature repositories.
///
/// Provides the three primitives every repository needs:
/// - [db] — the local Drift database (read-through cache).
/// - [sync] — the outbox-based sync engine (write-through to Supabase).
/// - [enqueueOp] — convenience wrapper to queue a mutation.
///
/// Spec ref: 01-supabase-data-layer §Phase 5, liquid-glass-flutter SKILL.md
/// §"Data layer".
abstract class BaseRepository {
  const BaseRepository({required this.db, required this.sync});

  final AppDatabase db;
  final SyncEngine sync;

  /// Enqueues a mutation for eventual sync to Supabase.
  Future<void> enqueueOp({
    required String id,
    required String targetTable,
    required OutboxOpType op,
    required Map<String, dynamic> payload,
  }) =>
      sync.enqueue(
        outboxOp(
          id: id,
          targetTable: targetTable,
          op: op,
          payload: payload,
        ),
      );
}
