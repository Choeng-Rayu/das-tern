import 'package:drift/drift.dart';

/// Mirrors public.notifications.
class NotificationsTable extends Table {
  @override
  String get tableName => 'notifications';

  TextColumn get id => text()();
  TextColumn get recipientId => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get data => text().nullable()(); // JSON string
  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
