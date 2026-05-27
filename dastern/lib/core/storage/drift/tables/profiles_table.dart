import 'package:drift/drift.dart';

/// Mirrors public.profiles.
/// Enums stored as text; validated in domain layer.
class ProfilesTable extends Table {
  @override
  String get tableName => 'profiles';

  TextColumn get id => text()();
  TextColumn get role => text().withDefault(const Constant('PATIENT'))();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get fullName => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get language => text().withDefault(const Constant('KHMER'))();
  TextColumn get theme => text().withDefault(const Constant('LIGHT'))();
  TextColumn get timezone =>
      text().withDefault(const Constant('Asia/Phnom_Penh'))();
  IntColumn get gracePeriodMinutes =>
      integer().withDefault(const Constant(30))();
  TextColumn get accountStatus =>
      text().withDefault(const Constant('ACTIVE'))();
  TextColumn get profilePictureUrl => text().nullable()();
  TextColumn get hospitalClinic => text().nullable()();
  TextColumn get specialty => text().nullable()();
  TextColumn get licenseNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
