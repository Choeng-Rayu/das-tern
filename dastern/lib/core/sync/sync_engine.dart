import 'dart:async';
import 'dart:math' as math;

import '../logging/app_logger.dart';
import '../storage/drift/app_database.dart';
import '../storage/drift/daos/outbox_dao.dart';

/// Convenience constructor for an outbox entry.
OutboxEntriesCompanion outboxOp({
  required String id,
  required String targetTable,
  required OutboxOpType op,
  required Map<String, dynamic> payload,
}) => OutboxEntriesCompanion.insert(
  id: id,
  targetTable: targetTable,
  op: op,
  payload: payload
      .toString(), // JSON encoding added when supabase_flutter lands
);

/// Manages the offline-first write queue.
///
/// Responsibilities:
/// 1. Accept mutations from repositories via [enqueue].
/// 2. Drain the outbox against Supabase when online ([drainNow]).
/// 3. Retry failed entries with exponential backoff.
///
/// The Supabase client is injected as a nullable callback so the engine
/// compiles and tests cleanly before `supabase_flutter` is wired in
/// (01-supabase-data-layer task).
///
/// Spec ref: 00-overview/design.md §5 "Sync engine".
class SyncEngine {
  SyncEngine({required AppDatabase db, this._onFlush}) : _dao = OutboxDao(db);

  final OutboxDao _dao;
  final Future<void> Function(OutboxEntry entry)? _onFlush;

  bool _running = false;
  Timer? _retryTimer;

  // ── Backoff constants ────────────────────────────────────────────────
  static const int _maxAttempts = 5;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 60);

  /// Computes the next retry delay using exponential backoff with jitter.
  ///
  /// Formula: `min(base * 2^attempts, max) + jitter(0..1s)`
  static Duration backoffDelay(int attempts) {
    final exp = _baseDelay * math.pow(2, attempts).toInt();
    final capped = exp > _maxDelay ? _maxDelay : exp;
    final jitter = Duration(
      milliseconds: (math.Random().nextDouble() * 1000).toInt(),
    );
    return capped + jitter;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────

  /// Starts the engine. Schedules a periodic retry sweep every 30 s.
  void start() {
    if (_running) return;
    _running = true;
    _retryTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => drainNow(),
    );
    drainNow();
  }

  /// Stops the engine and cancels the retry timer.
  void stop() {
    _running = false;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  // ── Public API ───────────────────────────────────────────────────────

  /// Adds a mutation to the outbox.
  Future<void> enqueue(OutboxEntriesCompanion entry) => _dao.enqueue(entry);

  /// Drains all due outbox entries. Called on connectivity restore and
  /// by the periodic timer.
  Future<void> drainNow() async {
    if (_onFlush == null) return; // Supabase not yet wired
    final batch = await _dao.dequeueBatch();
    for (final entry in batch) {
      if (entry.attempts >= _maxAttempts) {
        appLogger.w(
          'SyncEngine: giving up on ${entry.id} after $_maxAttempts attempts',
        );
        await _dao.markSucceeded(entry.id); // remove to avoid infinite loop
        continue;
      }
      try {
        await _onFlush(entry);
        await _dao.markSucceeded(entry.id);
        appLogger.d('SyncEngine: flushed ${entry.id}');
      } catch (e, st) {
        final delay = backoffDelay(entry.attempts);
        final retryAt = DateTime.now().add(delay);
        appLogger.w(
          'SyncEngine: ${entry.id} failed, retry in $delay',
          error: e,
          stackTrace: st,
        );
        await _dao.markFailed(entry.id, e.toString(), retryAt);
      }
    }
  }

  /// Returns the current outbox depth (for the diagnostics screen).
  Future<int> depth() => _dao.depth();

  /// Timestamp of the last successful drain (null until first drain).
  DateTime? lastSyncAt;
}
