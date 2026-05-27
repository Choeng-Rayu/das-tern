import 'package:drift/drift.dart';

/// Mirrors public.subscriptions.
class SubscriptionsTable extends Table {
  @override
  String get tableName => 'subscriptions';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get tier =>
      text().withDefault(const Constant('FREEMIUM'))();
  Int64Column get storageQuota =>
      int64().withDefault(Constant(BigInt.from(5368709120)))();
  Int64Column get storageUsed =>
      int64().withDefault(Constant(BigInt.from(0)))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  BoolColumn get hasUsedTrial =>
      boolean().withDefault(const Constant(false))();
  TextColumn get playState => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Mirrors public.family_members.
class FamilyMembersTable extends Table {
  @override
  String get tableName => 'family_members';

  TextColumn get id => text()();
  TextColumn get subscriptionId => text()();
  TextColumn get memberId => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
