// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medications_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicationsTableTable get medicationsTable =>
      attachedDatabase.medicationsTable;
  MedicationsDaoManager get managers => MedicationsDaoManager(this);
}

class MedicationsDaoManager {
  final _$MedicationsDaoMixin _db;
  MedicationsDaoManager(this._db);
  $$MedicationsTableTableTableManager get medicationsTable =>
      $$MedicationsTableTableTableManager(
        _db.attachedDatabase,
        _db.medicationsTable,
      );
}
