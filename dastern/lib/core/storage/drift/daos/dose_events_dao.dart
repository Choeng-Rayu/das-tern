import 'package:drift/drift.dart';

import '../app_database.dart';

part 'dose_events_dao.g.dart';

@DriftAccessor(tables: [DoseEventsTable])
class DoseEventsDao extends DatabaseAccessor<AppDatabase>
    with _$DoseEventsDaoMixin {
  DoseEventsDao(super.db);

  /// Reactive stream of today's dose events for [patientId], ordered by
  /// scheduled time.
  Stream<List<DoseEventsTableData>> watchToday(String patientId) {
    final start = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final end = start.add(const Duration(days: 1));
    return (select(doseEventsTable)
          ..where(
            (t) =>
                t.patientId.equals(patientId) &
                t.scheduledTime.isBetweenValues(start, end),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledTime)]))
        .watch();
  }

  /// Upsert a dose event row (used by sync bootstrap and Realtime merge).
  Future<void> upsert(DoseEventsTableCompanion row) =>
      into(doseEventsTable).insertOnConflictUpdate(row);

  /// Mark a dose event status locally (optimistic update before outbox flush).
  Future<void> updateStatus(
    String id,
    String status, {
    DateTime? takenAt,
    bool wasOffline = false,
  }) =>
      (update(doseEventsTable)..where((t) => t.id.equals(id))).write(
        DoseEventsTableCompanion(
          status: Value(status),
          takenAt: Value(takenAt),
          wasOffline: Value(wasOffline),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
