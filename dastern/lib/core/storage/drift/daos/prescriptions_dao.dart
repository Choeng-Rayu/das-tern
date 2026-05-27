import 'package:drift/drift.dart';

import '../app_database.dart';

part 'prescriptions_dao.g.dart';

@DriftAccessor(tables: [PrescriptionsTable, PrescriptionVersionsTable])
class PrescriptionsDao extends DatabaseAccessor<AppDatabase>
    with _$PrescriptionsDaoMixin {
  PrescriptionsDao(super.db);

  /// Reactive stream of all prescriptions for [patientId], newest first.
  Stream<List<PrescriptionsTableData>> watchByPatient(String patientId) =>
      (select(prescriptionsTable)
            ..where((t) => t.patientId.equals(patientId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Reactive stream filtered by status.
  Stream<List<PrescriptionsTableData>> watchByStatus(
    String patientId,
    String status,
  ) =>
      (select(prescriptionsTable)
            ..where(
              (t) =>
                  t.patientId.equals(patientId) & t.status.equals(status),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<PrescriptionsTableData?> findById(String id) =>
      (select(prescriptionsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsert(PrescriptionsTableCompanion row) =>
      into(prescriptionsTable).insertOnConflictUpdate(row);

  Future<void> updateStatus(String id, String status) =>
      (update(prescriptionsTable)..where((t) => t.id.equals(id))).write(
        PrescriptionsTableCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> bumpVersion(String id, int version) =>
      (update(prescriptionsTable)..where((t) => t.id.equals(id))).write(
        PrescriptionsTableCompanion(
          currentVersion: Value(version),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> insertVersion(PrescriptionVersionsTableCompanion row) =>
      into(prescriptionVersionsTable).insertOnConflictUpdate(row);

  Future<List<PrescriptionVersionsTableData>> versionsFor(
    String prescriptionId,
  ) =>
      (select(prescriptionVersionsTable)
            ..where((t) => t.prescriptionId.equals(prescriptionId))
            ..orderBy([(t) => OrderingTerm.asc(t.versionNumber)]))
          .get();
}
