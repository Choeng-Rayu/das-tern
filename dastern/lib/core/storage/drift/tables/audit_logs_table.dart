import 'package:drift/drift.dart';

/// Mirrors public.audit_logs — read-only mirror; never written locally.
class AuditLogsTable extends Table {
  @override
  String get tableName => 'audit_logs';

  TextColumn get id => text()();
  TextColumn get actorId => text().nullable()();
  TextColumn get actorRole => text().nullable()();
  TextColumn get actionType => text()();
  TextColumn get resourceType => text()();
  TextColumn get resourceId => text().nullable()();
  TextColumn get details => text().nullable()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
