import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/drift/app_database.dart';
import '../../../../core/storage/drift/daos/dose_events_dao.dart';
import '../../data/medication_repository.dart';
import '../../data/prescription_repository.dart';
import '../../data/schedule_generator.dart';
import '../../domain/medication.dart';
import '../../domain/prescription_enums.dart';

/// Edits a medication. If any doses have been taken, bumps the prescription
/// version and regenerates future dose events.
/// Spec ref: 03-prescription-medication design §5.
class EditMedication {
  EditMedication(
    this._prescriptionRepo,
    this._medRepo,
    this._doseDao,
    this._scheduleGen,
  );

  final PrescriptionRepository _prescriptionRepo;
  final MedicationRepository _medRepo;
  final DoseEventsDao _doseDao;
  final ScheduleGenerator _scheduleGen;

  static const _uuid = Uuid();

  Future<Medication> call({    required Medication current,
    required Map<String, dynamic> updates,
    required String patientId,
    required String patientTimezone,
  }) async {
    final hasDoses = await _anyTakenFor(current.id);
    final updated = current.copyWith(
      medicineName: updates['medicine_name'] as String?,
      medicineNameKhmer: updates['medicine_name_khmer'] as String?,
      dosageAmount: (updates['dosage_amount'] as num?)?.toDouble(),
      isPrn: updates['is_prn'] as bool?,
      beforeMeal: updates['before_meal'] as bool?,
      updatedAt: DateTime.now(),
    );

    await _medRepo.update(updated);

    if (hasDoses) {
      final pres = await _prescriptionRepo.findById(current.prescriptionId);
      if (pres != null) {
        final nextVersion = pres.currentVersion + 1;
        await _prescriptionRepo.bumpVersion(pres.id, nextVersion);
        final snapshot = await _medRepo.snapshotFor(pres.id);
        await _prescriptionRepo.insertVersion(
          prescriptionId: pres.id,
          version: nextVersion,
          snapshot: snapshot,
        );
        // Regenerate future DUE events for this medication
        await _deleteFutureDue(current.id);
        final now = DateTime.now().toUtc();
        final drafts = _scheduleGen
            .generate(
              updated,
              patientId: patientId,
              startUtc: now,
              endUtc: now.add(const Duration(days: 30)),
              timezone: patientTimezone,
            )
            .toList();
        for (final d in drafts) {
          await _doseDao.upsert(
            DoseEventsTableCompanion.insert(
              id: _uuid.v4(),
              prescriptionId: d.prescriptionId,
              medicationId: d.medicationId,
              patientId: d.patientId,
              scheduledTime: d.scheduledTime,
              timePeriod: d.timePeriod.code,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    return updated;
  }

  Future<bool> _anyTakenFor(String medicationId) async {
    final rows = await (_doseDao.attachedDatabase
            .select(_doseDao.attachedDatabase.doseEventsTable)
          ..where(
            (t) =>
                t.medicationId.equals(medicationId) &
                t.status.isIn(<String>['TAKEN_ON_TIME', 'TAKEN_LATE']),
          )
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  Future<void> _deleteFutureDue(String medicationId) async {
    final now = DateTime.now();
    await (_doseDao.attachedDatabase
            .delete(_doseDao.attachedDatabase.doseEventsTable)
          ..where(
            (t) =>
                t.medicationId.equals(medicationId) &
                t.status.equals('DUE') &
                t.scheduledTime.isBiggerThanValue(now),
          ))
        .go();
  }
}
