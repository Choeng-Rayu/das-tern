// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dose_events_dao.dart';

// ignore_for_file: type=lint
mixin _$DoseEventsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DoseEventsTableTable get doseEventsTable => attachedDatabase.doseEventsTable;
  DoseEventsDaoManager get managers => DoseEventsDaoManager(this);
}

class DoseEventsDaoManager {
  final _$DoseEventsDaoMixin _db;
  DoseEventsDaoManager(this._db);
  $$DoseEventsTableTableTableManager get doseEventsTable =>
      $$DoseEventsTableTableTableManager(
        _db.attachedDatabase,
        _db.doseEventsTable,
      );
}
