import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../storage/drift/app_database.dart';
import '../storage/secure/secure_storage.dart';
import '../sync/sync_engine.dart';

// ── Database ─────────────────────────────────────────────────────────

/// Singleton [AppDatabase]. Override in tests with an in-memory executor.
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((
  Ref ref,
) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Secure storage ───────────────────────────────────────────────────

final Provider<SecureStorage> secureStorageProvider = Provider<SecureStorage>(
  (Ref ref) => const SecureStorage(),
);

// ── Connectivity ─────────────────────────────────────────────────────

/// Emits the latest [ConnectivityResult] list whenever the network changes.
final StreamProvider<List<ConnectivityResult>> connectivityProvider =
    StreamProvider<List<ConnectivityResult>>(
      (Ref ref) => Connectivity().onConnectivityChanged,
    );

/// True when at least one non-none connectivity result is present.
final Provider<bool> isOnlineProvider = Provider<bool>((Ref ref) {
  final results = ref.watch(connectivityProvider).valueOrNull ?? [];
  return results.any((r) => r != ConnectivityResult.none);
});

// ── Sync engine ──────────────────────────────────────────────────────

/// Singleton [SyncEngine]. Starts on first access; stops on dispose.
final Provider<SyncEngine> syncEngineProvider = Provider<SyncEngine>((Ref ref) {
  final engine = SyncEngine(db: ref.watch(appDatabaseProvider))..start();
  // ignore: cascade_invocations
  ref.onDispose(engine.stop);

  // ignore: cascade_invocations
  ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
    if (isOnline && previous == false) {
      appLogger.d('SyncEngine: connectivity restored — draining outbox');
      engine.drainNow();
    }
  });

  return engine;
});
