import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/audit_logs_table.dart';
import 'tables/connections_table.dart';
import 'tables/dose_events_table.dart';
import 'tables/medications_table.dart';
import 'tables/notifications_table.dart';
import 'tables/other_tables.dart';
import 'tables/outbox.dart';
import 'tables/prescriptions_table.dart';
import 'tables/profiles_table.dart';
import 'tables/subscriptions_table.dart';

export 'tables/audit_logs_table.dart';
export 'tables/connections_table.dart';
export 'tables/dose_events_table.dart';
export 'tables/medications_table.dart';
export 'tables/notifications_table.dart';
export 'tables/other_tables.dart';
export 'tables/outbox.dart';
export 'tables/prescriptions_table.dart';
export 'tables/profiles_table.dart';
export 'tables/subscriptions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  // Outbox (sync engine)
  OutboxEntries,
  // Domain tables
  ProfilesTable,
  ConnectionsTable,
  ConnectionTokensTable,
  PrescriptionsTable,
  PrescriptionVersionsTable,
  MedicationsTable,
  DoseEventsTable,
  NotificationsTable,
  AuditLogsTable,
  SubscriptionsTable,
  FamilyMembersTable,
  MealTimePreferencesTable,
  DoctorNotesTable,
  MedicationBatchesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'das_tern'));

  @override
  int get schemaVersion => 2;
}
