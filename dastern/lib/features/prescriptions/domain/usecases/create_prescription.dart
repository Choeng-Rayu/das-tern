import 'package:uuid/uuid.dart';

import '../../../../core/storage/drift/app_database.dart';
import '../../../../core/storage/drift/daos/dose_events_dao.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../data/medication_repository.dart';
import '../../data/prescription_repository.dart';
import '../../data/schedule_generator.dart';
import '../../domain/medication.dart';
import '../../domain/prescription.dart';
import '../../domain/prescription_enums.dart';

/// Draft passed to [CreatePrescription].
class PrescriptionDraft {
  const PrescriptionDraft({
    required this.patientId,
    required this.patientName,
    required this.patientGender,
    required this.patientAge,
    required this.symptoms,
    this.diagnosis,
    this.clinicalNote,
    this.doctorId,
    this.startDate,
    this.endDate,
    required this.medications,
    required this.patientTimezone,
    this.isUrgent = false,
    this.urgentReason,
  });

  final String patientId;
  final String patientName;
  final Gender patientGender;
  final int patientAge;
  final String symptoms;
  final String? diagnosis;
  final String? clinicalNote;
  final String? doctorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> medications;
  final String patientTimezone;
  final bool isUrgent;
  final String? urgentReason;
}

/// Creates a prescription with medications and generates 30 days of dose events.
/// Spec ref: 03-prescription-medication design §4.
class CreatePrescription {
  CreatePrescription(
    this._prescriptionRepo,
    this._medRepo,
    this._scheduleGen,
    this._doseDao,
    this._sync,
  );

  final PrescriptionRepository _prescriptionRepo;
  final MedicationRepository _medRepo;
  final ScheduleGenerator _scheduleGen;
  final DoseEventsDao _doseDao;
  final SyncEngine _sync;

  static const _uuid = Uuid();

  Future<Prescription> call(PrescriptionDraft draft) async {
    final rxId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final end = now.add(const Duration(days: 30));

    final status = draft.isUrgent
        ? PrescriptionStatus.active
        : (draft.doctorId != null
            ? PrescriptionStatus.draft
            : PrescriptionStatus.active);

    final p = await _prescriptionRepo.insert(<String, dynamic>{
      'id': rxId,
      'patient_id': draft.patientId,
      if (draft.doctorId != null) 'doctor_id': draft.doctorId,
      'patient_name': draft.patientName,
      'patient_gender': draft.patientGender.code,
      'patient_age': draft.patientAge,
      'symptoms': draft.symptoms,
      if (draft.diagnosis != null) 'diagnosis': draft.diagnosis,
      if (draft.clinicalNote != null) 'clinical_note': draft.clinicalNote,
      'status': status.code,
      'current_version': 1,
      'is_urgent': draft.isUrgent,
      if (draft.urgentReason != null) 'urgent_reason': draft.urgentReason,
    });

    for (var i = 0; i < draft.medications.length; i++) {
      final medMap = <String, dynamic>{
        'id': _uuid.v4(),
        'prescription_id': rxId,
        'row_number': i + 1,
        ...draft.medications[i],
      };
      final med = await _medRepo.insert(rxId, medMap);

      if (status == PrescriptionStatus.active) {
        await _generateDoseEvents(
          med,
          patientId: draft.patientId,
          startUtc: now,
          endUtc: end,
          timezone: draft.patientTimezone,
        );
      }
    }

    final snapshot = await _medRepo.snapshotFor(rxId);
    await _prescriptionRepo.insertVersion(
      prescriptionId: rxId,
      version: 1,
      snapshot: snapshot,
    );

    return p;
  }

  Future<void> _generateDoseEvents(
    Medication med, {
    required String patientId,
    required DateTime startUtc,
    required DateTime endUtc,
    required String timezone,
  }) async {
    final drafts = _scheduleGen
        .generate(
          med,
          patientId: patientId,
          startUtc: startUtc,
          endUtc: endUtc,
          timezone: timezone,
        )
        .toList();

    for (final d in drafts) {
      final id = _uuid.v4();
      await _doseDao.upsert(
        DoseEventsTableCompanion.insert(
          id: id,
          prescriptionId: d.prescriptionId,
          medicationId: d.medicationId,
          patientId: d.patientId,
          scheduledTime: d.scheduledTime,
          timePeriod: d.timePeriod.code,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await _sync.enqueue(
        outboxOp(
          id: '${id}_create',
          targetTable: 'dose_events',
          op: OutboxOpType.create,
          payload: <String, dynamic>{
            'id': id,
            'prescription_id': d.prescriptionId,
            'medication_id': d.medicationId,
            'patient_id': d.patientId,
            'scheduled_time': d.scheduledTime.toIso8601String(),
            'time_period': d.timePeriod.code,
            'status': 'DUE',
          },
        ),
      );
    }
  }
}
