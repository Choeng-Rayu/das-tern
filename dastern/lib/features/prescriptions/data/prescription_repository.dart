import 'package:drift/drift.dart';

import '../../../core/data/base_repository.dart';
import '../../../core/storage/drift/app_database.dart';
import '../../../core/storage/drift/daos/prescriptions_dao.dart';
import '../domain/prescription.dart';
import '../domain/prescription_enums.dart';

abstract class PrescriptionRepository {
  Stream<List<Prescription>> watchByPatient(String patientId);
  Stream<List<Prescription>> watchActive(String patientId);
  Future<Prescription?> findById(String id);
  Future<Prescription> insert(Map<String, dynamic> row);
  Future<void> updateStatus(String id, PrescriptionStatus status);
  Future<void> bumpVersion(String id, int version);
  Future<void> insertVersion({
    required String prescriptionId,
    required int version,
    required String snapshot,
  });
}

class PrescriptionRepositoryImpl extends BaseRepository
    implements PrescriptionRepository {
  PrescriptionRepositoryImpl({required super.db, required super.sync})
      : _dao = PrescriptionsDao(db);

  final PrescriptionsDao _dao;

  @override
  Stream<List<Prescription>> watchByPatient(String patientId) =>
      _dao.watchByPatient(patientId).map(
            (rows) => rows.map(_fromRow).toList(),
          );

  @override
  Stream<List<Prescription>> watchActive(String patientId) =>
      _dao.watchByStatus(patientId, 'ACTIVE').map(
            (rows) => rows.map(_fromRow).toList(),
          );

  @override
  Future<Prescription?> findById(String id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Prescription> insert(Map<String, dynamic> row) async {
    final companion = _toCompanion(row);
    await _dao.upsert(companion);
    await enqueueOp(
      id: '${row['id']}_create',
      targetTable: 'prescriptions',
      op: OutboxOpType.create,
      payload: row,
    );
    return _fromRow(await _dao.findById(row['id'] as String) ??
        (throw StateError('Insert failed')));
  }

  @override
  Future<void> updateStatus(String id, PrescriptionStatus status) async {
    await _dao.updateStatus(id, status.code);
    await enqueueOp(
      id: '${id}_status_${status.code}',
      targetTable: 'prescriptions',
      op: OutboxOpType.update,
      payload: <String, dynamic>{'id': id, 'status': status.code},
    );
  }

  @override
  Future<void> bumpVersion(String id, int version) async {
    await _dao.bumpVersion(id, version);
    await enqueueOp(
      id: '${id}_v$version',
      targetTable: 'prescriptions',
      op: OutboxOpType.update,
      payload: <String, dynamic>{'id': id, 'current_version': version},
    );
  }

  @override
  Future<void> insertVersion({
    required String prescriptionId,
    required int version,
    required String snapshot,
  }) async {
    final versionId = '${prescriptionId}_v$version';
    await _dao.insertVersion(
      PrescriptionVersionsTableCompanion.insert(
        id: versionId,
        prescriptionId: prescriptionId,
        versionNumber: version,
        medicationsSnapshot: snapshot,
        createdAt: DateTime.now(),
      ),
    );
    await enqueueOp(
      id: '${versionId}_create',
      targetTable: 'prescription_versions',
      op: OutboxOpType.create,
      payload: <String, dynamic>{
        'id': versionId,
        'prescription_id': prescriptionId,
        'version_number': version,
        'medications_snapshot': snapshot,
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static Prescription _fromRow(PrescriptionsTableData r) => Prescription(
        id: r.id,
        patientId: r.patientId,
        doctorId: r.doctorId,
        patientName: r.patientName,
        patientGender: GenderX.fromCode(r.patientGender),
        patientAge: r.patientAge,
        symptoms: r.symptoms,
        diagnosis: r.diagnosis,
        status: PrescriptionStatusX.fromCode(r.status),
        currentVersion: r.currentVersion,
        isUrgent: r.isUrgent,
        urgentReason: r.urgentReason,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static PrescriptionsTableCompanion _toCompanion(Map<String, dynamic> m) =>
      PrescriptionsTableCompanion.insert(
        id: m['id'] as String,
        patientId: m['patient_id'] as String,
        doctorId: Value(m['doctor_id'] as String?),
        patientName: m['patient_name'] as String,
        patientGender: m['patient_gender'] as String,
        patientAge: m['patient_age'] as int,
        symptoms: Value(m['symptoms'] as String? ?? ''),
        status: Value(m['status'] as String? ?? 'DRAFT'),
        currentVersion: Value(m['current_version'] as int? ?? 1),
        isUrgent: Value(m['is_urgent'] as bool? ?? false),
        urgentReason: Value(m['urgent_reason'] as String?),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
