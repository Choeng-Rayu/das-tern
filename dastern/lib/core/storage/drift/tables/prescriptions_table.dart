import 'package:drift/drift.dart';

/// Mirrors public.prescriptions.
class PrescriptionsTable extends Table {
  @override
  String get tableName => 'prescriptions';

  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get doctorId => text().nullable()();
  TextColumn get patientName => text()();
  TextColumn get patientGender => text()();
  IntColumn get patientAge => integer()();
  TextColumn get symptoms => text().withDefault(const Constant(''))();
  TextColumn get diagnosis => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('DRAFT'))();
  IntColumn get currentVersion =>
      integer().withDefault(const Constant(1))();
  BoolColumn get isUrgent =>
      boolean().withDefault(const Constant(false))();
  TextColumn get urgentReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Mirrors public.prescription_versions.
class PrescriptionVersionsTable extends Table {
  @override
  String get tableName => 'prescription_versions';

  TextColumn get id => text()();
  TextColumn get prescriptionId => text()();
  IntColumn get versionNumber => integer()();
  TextColumn get authorId => text().nullable()();
  TextColumn get changeReason => text().nullable()();
  TextColumn get medicationsSnapshot => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
