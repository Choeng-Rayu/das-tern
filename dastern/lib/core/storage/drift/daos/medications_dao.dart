import 'package:drift/drift.dart';

import '../app_database.dart';

part 'medications_dao.g.dart';

@DriftAccessor(tables: [MedicationsTable])
class MedicationsDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationsDaoMixin {
  MedicationsDao(super.db);

  Stream<List<MedicationsTableData>> watchByPrescription(
    String prescriptionId,
  ) =>
      (select(medicationsTable)
            ..where((t) => t.prescriptionId.equals(prescriptionId))
            ..orderBy([(t) => OrderingTerm.asc(t.rowNumber)]))
          .watch();

  Future<List<MedicationsTableData>> getByPrescription(
    String prescriptionId,
  ) =>
      (select(medicationsTable)
            ..where((t) => t.prescriptionId.equals(prescriptionId))
            ..orderBy([(t) => OrderingTerm.asc(t.rowNumber)]))
          .get();

  Future<void> upsert(MedicationsTableCompanion row) =>
      into(medicationsTable).insertOnConflictUpdate(row);

  Future<void> updateRow(MedicationsTableCompanion row) =>
      (update(medicationsTable)
            ..where((t) => t.id.equals(row.id.value)))
          .write(row);

  Future<void> deleteById(String id) =>
      (delete(medicationsTable)..where((t) => t.id.equals(id))).go();
}
