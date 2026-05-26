import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/outbox.dart';

part 'app_database.g.dart';

/// The single on-device SQLite database.
///
/// All Drift tables are registered here. Feature specs add their own tables
/// as they land — each table lives in `tables/<name>.dart` and is listed in
/// the `@DriftDatabase` annotation.
///
/// The generated `app_database.g.dart` is committed so CI builds do not
/// need to run `build_runner`.
///
/// Spec ref: 00-overview/design.md §"Local DB".
@DriftDatabase(tables: [OutboxEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'das_tern'));

  /// Increment this when the schema changes. Drift will run [migration].
  @override
  int get schemaVersion => 1;
}
