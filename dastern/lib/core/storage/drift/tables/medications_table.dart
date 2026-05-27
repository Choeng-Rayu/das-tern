import 'package:drift/drift.dart';

/// Mirrors public.medications.
class MedicationsTable extends Table {
  @override
  String get tableName => 'medications';

  TextColumn get id => text()();
  TextColumn get prescriptionId => text()();
  IntColumn get rowNumber => integer()();
  TextColumn get batchId => text().nullable()();
  TextColumn get medicineName => text()();
  TextColumn get medicineNameKhmer => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get medicineType =>
      text().withDefault(const Constant('ORAL'))();
  TextColumn get unit =>
      text().withDefault(const Constant('TABLET'))();
  RealColumn get dosageAmount =>
      real().withDefault(const Constant(1.0))();
  TextColumn get description => text().nullable()();
  TextColumn get morningDosage => text().nullable()();   // JSON DosageSlot
  TextColumn get afternoonDosage => text().nullable()(); // JSON DosageSlot
  TextColumn get eveningDosage => text().nullable()();   // JSON DosageSlot
  TextColumn get nightDosage => text().nullable()();     // JSON DosageSlot
  TextColumn get frequency => text().nullable()();
  IntColumn get duration => integer().nullable()();
  BoolColumn get isPrn =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get beforeMeal =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
