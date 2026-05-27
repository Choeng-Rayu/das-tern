import 'package:drift/drift.dart';

/// Mirrors public.meal_time_preferences.
class MealTimePreferencesTable extends Table {
  @override
  String get tableName => 'meal_time_preferences';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get morningMeal => text().nullable()();
  TextColumn get afternoonMeal => text().nullable()();
  TextColumn get eveningMeal => text().nullable()();
  TextColumn get nightMeal => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Mirrors public.doctor_notes.
class DoctorNotesTable extends Table {
  @override
  String get tableName => 'doctor_notes';

  TextColumn get id => text()();
  TextColumn get doctorId => text()();
  TextColumn get patientId => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Mirrors public.medication_batches.
class MedicationBatchesTable extends Table {
  @override
  String get tableName => 'medication_batches';

  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get name => text()();
  TextColumn get scheduledTime => text()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
