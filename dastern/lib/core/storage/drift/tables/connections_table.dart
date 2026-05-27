import 'package:drift/drift.dart';

/// Mirrors public.connections.
class ConnectionsTable extends Table {
  @override
  String get tableName => 'connections';

  TextColumn get id => text()();
  TextColumn get initiatorId => text()();
  TextColumn get recipientId => text()();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))();
  TextColumn get permissionLevel =>
      text().withDefault(const Constant('ALLOWED'))();
  TextColumn get metadata => text().nullable()(); // JSON string
  DateTimeColumn get requestedAt => dateTime()();
  DateTimeColumn get acceptedAt => dateTime().nullable()();
  DateTimeColumn get revokedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Mirrors public.connection_tokens.
class ConnectionTokensTable extends Table {
  @override
  String get tableName => 'connection_tokens';

  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get token => text()();
  TextColumn get permissionLevel =>
      text().withDefault(const Constant('ALLOWED'))();
  TextColumn get intendedRole =>
      text().withDefault(const Constant('PATIENT'))();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get usedAt => dateTime().nullable()();
  TextColumn get usedById => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
