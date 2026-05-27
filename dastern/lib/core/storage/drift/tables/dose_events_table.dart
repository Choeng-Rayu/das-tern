import 'package:drift/drift.dart';

/// Mirrors public.dose_events.
class DoseEventsTable extends Table {
  @override
  String get tableName => 'dose_events';

  TextColumn get id => text()();
  TextColumn get prescriptionId => text()();
  TextColumn get medicationId => text()();
  TextColumn get patientId => text()();
  DateTimeColumn get scheduledTime => dateTime()();
  TextColumn get timePeriod => text()();
  TextColumn get reminderTime => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('DUE'))();
  DateTimeColumn get takenAt => dateTime().nullable()();
  TextColumn get skipReason => text().nullable()();
  BoolColumn get wasOffline =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
