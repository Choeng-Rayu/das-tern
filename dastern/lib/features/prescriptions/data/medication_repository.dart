import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/data/base_repository.dart';
import '../../../core/storage/drift/app_database.dart';
import '../../../core/storage/drift/daos/medications_dao.dart';
import '../domain/medication.dart';

abstract class MedicationRepository {
  Stream<List<Medication>> watchByPrescription(String prescriptionId);
  Future<List<Medication>> getByPrescription(String prescriptionId);
  Future<Medication> insert(String prescriptionId, Map<String, dynamic> row);
  Future<void> update(Medication med);
  Future<String> snapshotFor(String prescriptionId);
}

class MedicationRepositoryImpl extends BaseRepository
    implements MedicationRepository {
  MedicationRepositoryImpl({required super.db, required super.sync})
      : _dao = MedicationsDao(db);

  final MedicationsDao _dao;

  @override
  Stream<List<Medication>> watchByPrescription(String prescriptionId) =>
      _dao.watchByPrescription(prescriptionId).map(
            (rows) => rows.map(_fromRow).toList(),
          );

  @override
  Future<List<Medication>> getByPrescription(String prescriptionId) async {
    final rows = await _dao.getByPrescription(prescriptionId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Medication> insert(
    String prescriptionId,
    Map<String, dynamic> row,
  ) async {
    final now = DateTime.now();
    final fullRow = <String, dynamic>{
      ...row,
      'prescription_id': prescriptionId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    final companion = _toCompanion(fullRow);
    await _dao.upsert(companion);
    await enqueueOp(
      id: '${row['id']}_create',
      targetTable: 'medications',
      op: OutboxOpType.create,
      payload: fullRow,
    );
    return Medication.fromMap(fullRow);
  }

  @override
  Future<void> update(Medication med) async {
    final m = med.toMap();
    await _dao.updateRow(_toCompanion(m));
    await enqueueOp(
      id: '${med.id}_update',
      targetTable: 'medications',
      op: OutboxOpType.update,
      payload: m,
    );
  }

  @override
  Future<String> snapshotFor(String prescriptionId) async {
    final meds = await getByPrescription(prescriptionId);
    return jsonEncode(meds.map((m) => m.toMap()).toList());
  }

  static Medication _fromRow(MedicationsTableData r) => Medication.fromMap(<String, dynamic>{
        'id': r.id,
        'prescription_id': r.prescriptionId,
        'row_number': r.rowNumber,
        'medicine_name': r.medicineName,
        'medicine_name_khmer': r.medicineNameKhmer,
        'medicine_type': r.medicineType,
        'unit': r.unit,
        'dosage_amount': r.dosageAmount,
        'morning_dosage': r.morningDosage,
        'afternoon_dosage': r.afternoonDosage,
        'evening_dosage': r.eveningDosage,
        'night_dosage': r.nightDosage,
        'frequency': r.frequency,
        'duration': r.duration,
        'is_prn': r.isPrn,
        'before_meal': r.beforeMeal,
        'created_at': r.createdAt.toIso8601String(),
        'updated_at': r.updatedAt.toIso8601String(),
      });

  static MedicationsTableCompanion _toCompanion(Map<String, dynamic> m) =>
      MedicationsTableCompanion.insert(
        id: m['id'] as String,
        prescriptionId: m['prescription_id'] as String,
        rowNumber: m['row_number'] as int,
        medicineName: m['medicine_name'] as String,
        medicineNameKhmer: Value(m['medicine_name_khmer'] as String?),
        medicineType: Value(m['medicine_type'] as String? ?? 'ORAL'),
        unit: Value(m['unit'] as String? ?? 'TABLET'),
        dosageAmount: Value(
          (m['dosage_amount'] as num?)?.toDouble() ?? 1.0,
        ),
        morningDosage: Value(m['morning_dosage'] as String?),
        afternoonDosage: Value(m['afternoon_dosage'] as String?),
        eveningDosage: Value(m['evening_dosage'] as String?),
        nightDosage: Value(m['night_dosage'] as String?),
        frequency: Value(m['frequency'] as String?),
        duration: Value(m['duration'] as int?),
        isPrn: Value(m['is_prn'] as bool? ?? false),
        beforeMeal: Value(m['before_meal'] as bool? ?? false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}

// Extension to allow Medication.fromMap from a Drift row map
extension MedicationFromDriftRow on Medication {
  static Medication fromDriftRow(MedicationsTableData r) =>
      Medication.fromMap(<String, dynamic>{
        'id': r.id,
        'prescription_id': r.prescriptionId,
        'row_number': r.rowNumber,
        'medicine_name': r.medicineName,
        'medicine_name_khmer': r.medicineNameKhmer,
        'medicine_type': r.medicineType,
        'unit': r.unit,
        'dosage_amount': r.dosageAmount,
        'morning_dosage': r.morningDosage,
        'afternoon_dosage': r.afternoonDosage,
        'evening_dosage': r.eveningDosage,
        'night_dosage': r.nightDosage,
        'frequency': r.frequency,
        'duration': r.duration,
        'is_prn': r.isPrn,
        'before_meal': r.beforeMeal,
        'created_at': r.createdAt.toIso8601String(),
        'updated_at': r.updatedAt.toIso8601String(),
      });
}
