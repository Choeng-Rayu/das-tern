// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prescriptions_dao.dart';

// ignore_for_file: type=lint
mixin _$PrescriptionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PrescriptionsTableTable get prescriptionsTable =>
      attachedDatabase.prescriptionsTable;
  $PrescriptionVersionsTableTable get prescriptionVersionsTable =>
      attachedDatabase.prescriptionVersionsTable;
  PrescriptionsDaoManager get managers => PrescriptionsDaoManager(this);
}

class PrescriptionsDaoManager {
  final _$PrescriptionsDaoMixin _db;
  PrescriptionsDaoManager(this._db);
  $$PrescriptionsTableTableTableManager get prescriptionsTable =>
      $$PrescriptionsTableTableTableManager(
        _db.attachedDatabase,
        _db.prescriptionsTable,
      );
  $$PrescriptionVersionsTableTableTableManager get prescriptionVersionsTable =>
      $$PrescriptionVersionsTableTableTableManager(
        _db.attachedDatabase,
        _db.prescriptionVersionsTable,
      );
}
