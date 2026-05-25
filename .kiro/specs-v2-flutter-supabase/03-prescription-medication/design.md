# Design: Prescription & Medication Management

## 1. Module structure

```
lib/features/prescriptions/
├── data/
│   ├── prescription_repository.dart
│   ├── medication_repository.dart
│   ├── prescription_image_repository.dart
│   └── schedule_generator.dart        # pure-Dart dose-event generator
├── domain/
│   ├── prescription.dart              # freezed
│   ├── medication.dart                # freezed
│   ├── prescription_status.dart
│   ├── medicine_type.dart
│   └── usecases/
│       ├── create_prescription.dart
│       ├── add_medication.dart
│       ├── edit_medication.dart        # versions on edit-after-dose
│       ├── pause_prescription.dart
│       ├── resume_prescription.dart
│       ├── stop_prescription.dart
│       ├── mark_urgent.dart            # doctor-only
│       ├── confirm_prescription.dart   # patient-only
│       └── reject_prescription.dart    # patient-only
└── presentation/
    ├── pages/
    │   ├── prescription_list_page.dart
    │   ├── prescription_detail_page.dart
    │   ├── create_prescription_page.dart
    │   ├── medication_form_page.dart
    │   ├── version_history_page.dart
    │   └── doctor_prescription_authoring_page.dart
    ├── widgets/
    │   ├── prescription_card.dart
    │   ├── medication_row.dart
    │   ├── lifecycle_badge.dart
    │   └── urgent_banner.dart
    └── providers/
        ├── prescription_list_provider.dart
        ├── prescription_detail_provider.dart
        └── medication_form_provider.dart
```

## 2. Domain entities

```dart
@freezed
class Prescription with _$Prescription {
  const factory Prescription({
    required String id,
    required String patientId,
    String? doctorId,
    required String patientName,
    required Gender patientGender,
    required int patientAge,
    required String symptoms,
    String? diagnosis,
    String? clinicalNote,
    DateTime? followUpDate,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? ocrMetadata,
    required PrescriptionStatus status,
    required int currentVersion,
    required bool isUrgent,
    String? urgentReason,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Prescription;
}

@freezed
class Medication with _$Medication {
  const factory Medication({
    required String id,
    required String prescriptionId,
    required int rowNumber,
    String? batchId,
    required String medicineName,
    String? medicineNameKhmer,
    String? imageUrl,
    required MedicineType medicineType,
    required MedicineUnit unit,
    required double dosageAmount,
    String? description,
    String? additionalNote,
    String? createdBy,
    DosageSlot? morningDosage,
    DosageSlot? afternoonDosage,
    DosageSlot? eveningDosage,
    DosageSlot? nightDosage,
    String? frequency,
    int? duration,
    String? timing,
    required bool isPrn,
    required bool beforeMeal,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Medication;
}

@freezed
class DosageSlot with _$DosageSlot {
  const factory DosageSlot({
    required double amount,
    required MedicineUnit unit,
    String? note,
  }) = _DosageSlot;
  factory DosageSlot.fromJson(Map<String, dynamic> json) => _$DosageSlotFromJson(json);
}
```

## 3. Schedule generator (pure-Dart, deterministic)

```dart
// lib/features/prescriptions/data/schedule_generator.dart
class ScheduleGenerator {
  ScheduleGenerator(this._mealTime);
  final MealTimePreference _mealTime;

  Iterable<DoseEventDraft> generate(
    Medication med, {
    required DateTime startUtc,
    required DateTime endUtc,
    required String timezone,
  }) sync* {
    if (med.isPrn) return;

    final loc = tz.getLocation(timezone);
    final start = tz.TZDateTime.from(startUtc, loc);
    final end   = tz.TZDateTime.from(endUtc, loc);

    for (var day = DateTime(start.year, start.month, start.day);
         day.isBefore(end);
         day = day.add(const Duration(days: 1))) {

      void emit(TimePeriod period, DosageSlot? slot, String mealTime) {
        if (slot == null) return;
        final hm = mealTime.split(':');
        var local = tz.TZDateTime(loc, day.year, day.month, day.day,
            int.parse(hm[0]), int.parse(hm[1]));
        if (med.beforeMeal) local = local.subtract(const Duration(minutes: 30));
        yield DoseEventDraft(
          medicationId: med.id,
          prescriptionId: med.prescriptionId,
          patientId: med.patientId,    // injected by caller
          scheduledTime: local.toUtc(),
          timePeriod: period,
        );
      }

      emit(TimePeriod.morning,   med.morningDosage,   _mealTime.morningMeal   ?? '07:00');
      emit(TimePeriod.afternoon, med.afternoonDosage, _mealTime.afternoonMeal ?? '12:00');
      emit(TimePeriod.evening,   med.eveningDosage,   _mealTime.eveningMeal   ?? '18:00');
      emit(TimePeriod.night,     med.nightDosage,     _mealTime.nightMeal     ?? '21:00');
    }
  }
}
```

> Generator is unit-tested with a fixed timezone + meal preferences and asserted byte-for-byte.

## 4. Create-prescription flow (patient)

```dart
// usecase
class CreatePrescription {
  CreatePrescription(this._prescriptionRepo, this._medRepo, this._scheduleGen, this._doseRepo);

  Future<Prescription> call(PrescriptionDraft draft) async {
    final p = await _prescriptionRepo.insert(draft.toRow());
    for (final m in draft.medications) {
      final med = await _medRepo.insert(p.id, m);
      final events = _scheduleGen.generate(
        med,
        startUtc: DateTime.now().toUtc(),
        endUtc: DateTime.now().toUtc().add(const Duration(days: 30)),
        timezone: draft.patientTimezone,
      ).toList();
      await _doseRepo.insertMany(events);
    }
    await _prescriptionRepo.insertVersion(p.id, version: 1, snapshot: draft.medicationsAsJson());
    return p;
  }
}
```

Each repository write goes Drift first → outbox enqueue → Supabase on next online sync.

## 5. Edit-with-versioning logic

```dart
Future<Medication> editMedication(Medication current, MedicationDraft updates) async {
  final hasDoses = await _doseRepo.anyTakenFor(current.id);
  if (!hasDoses) {
    // In-place edit, no new version
    final next = current.copyWith.fromDraft(updates);
    await _medRepo.update(next);
    return next;
  }

  // Bump version
  final pres = await _prescriptionRepo.findById(current.prescriptionId);
  final nextVersion = pres.currentVersion + 1;
  final updatedMed = current.copyWith.fromDraft(updates);

  await _medRepo.update(updatedMed);
  await _prescriptionRepo.bumpVersion(pres.id, nextVersion);
  await _prescriptionRepo.insertVersion(pres.id, version: nextVersion,
      snapshot: await _medRepo.snapshotFor(pres.id));
  // Regenerate FUTURE dose events for this medication only
  await _doseRepo.deleteFutureDue(updatedMed.id);
  final events = _scheduleGen.generate(updatedMed, startUtc: DateTime.now().toUtc(),
      endUtc: DateTime.now().toUtc().add(const Duration(days: 30)),
      timezone: pres.timezone);
  await _doseRepo.insertMany(events.toList());
  return updatedMed;
}
```

## 6. Lifecycle transitions

| From → To | Trigger | Side effects |
|---|---|---|
| DRAFT → ACTIVE | Patient confirms doctor prescription, OR patient-created prescription is finalized | Generate 30 days dose events, schedule local notifications |
| ACTIVE → PAUSED | Patient pauses | Cancel future local notifications; keep dose events as DUE (will be marked MISSED after grace) |
| PAUSED → ACTIVE | Patient resumes | Regenerate dose events from now+30d, reschedule notifications |
| ACTIVE/PAUSED → INACTIVE | Patient stops, OR doctor stops | Cancel all future notifications, no new dose events |
| INACTIVE → ACTIVE | Patient retakes (creates a new prescription via "retake" template) | Treated as NEW prescription with ref to old |

## 7. Doctor authoring flow

```dart
class DoctorAuthoringController {
  Future<Prescription> create({
    required String patientId,
    required PrescriptionDraft draft,
    required bool isUrgent,
    String? urgentReason,
  }) async {
    final connection = await _connectionRepo.findAccepted(patientId, requireAllowed: true);
    if (connection == null) throw const AppFailure.notConnected();

    final initialStatus = isUrgent ? PrescriptionStatus.active : PrescriptionStatus.draft;
    final p = await _prescriptionRepo.insert(draft.toRow().copyWith(
      doctorId: _currentDoctorId,
      patientId: patientId,
      status: initialStatus,
      isUrgent: isUrgent,
      urgentReason: urgentReason,
    ));
    // Notify patient — done by Postgres trigger emitting `notifications` row.
    return p;
  }
}
```

A Postgres trigger on `prescriptions.INSERT` emits a notification:

```sql
create or replace function public.tg_prescription_inserted()
returns trigger language plpgsql security definer as $$
begin
  if new.doctor_id is not null and new.doctor_id <> new.patient_id then
    insert into public.notifications (recipient_id, type, title, message, data)
    values (new.patient_id,
            case when new.is_urgent then 'URGENT_PRESCRIPTION_CHANGE'::notification_type
                 else 'PRESCRIPTION_UPDATE'::notification_type end,
            case when new.is_urgent then 'Urgent prescription update'
                 else 'New prescription from your doctor' end,
            coalesce(new.urgent_reason, 'Open the app to review.'),
            jsonb_build_object('prescription_id', new.id, 'doctor_id', new.doctor_id));
  end if;
  return new;
end;
$$;
create trigger prescription_after_insert
after insert on public.prescriptions
for each row execute function public.tg_prescription_inserted();
```

## 8. Subscription-tier enforcement

This is enforced both client-side (UX) and server-side (RLS + check function):

```sql
create or replace function public.check_freemium_limits()
returns trigger language plpgsql as $$
declare
  v_tier subscription_tier;
  v_active_count integer;
begin
  select tier into v_tier from public.subscriptions where user_id = new.patient_id;
  if v_tier = 'FREEMIUM' then
    select count(*) into v_active_count from public.prescriptions
     where patient_id = new.patient_id and status in ('DRAFT','ACTIVE','PAUSED');
    if v_active_count >= 1 then
      raise exception 'freemium_limit_prescriptions';
    end if;
  end if;
  return new;
end;
$$;

create trigger prescriptions_freemium_check
before insert on public.prescriptions
for each row execute function public.check_freemium_limits();
```

Flutter handles the exception:

```dart
try {
  await _supabase.from('prescriptions').insert(row);
} on PostgrestException catch (e) {
  if (e.message.contains('freemium_limit_prescriptions')) {
    throw const AppFailure.freemiumLimit('prescriptions', current: 1, limit: 1);
  }
  rethrow;
}
```

## 9. Image upload flow

```dart
Future<String> uploadPrescriptionImage(String prescriptionId, File file) async {
  final patientId = _supabase.auth.currentUser!.id;
  final fileName = '${const Uuid().v4()}.jpg';
  final path = '$patientId/$prescriptionId/$fileName';
  await _supabase.storage.from('prescription-images').upload(
    path, file, fileOptions: const FileOptions(contentType: 'image/jpeg'),
  );
  return path;
}
```

The path is appended to `prescriptions.ocr_metadata.images` array.

## 10. Realtime ingest

`PrescriptionRepository.watchActive()` returns a Drift stream. The `RealtimeSubscriber` listens to Supabase Realtime on the `prescriptions` table filtered by `patient_id = auth.uid()` (RLS-enforced server-side) and merges deltas into Drift, which causes the stream to fire automatically.

For a doctor's view, the same channel is used but filtered by `doctor_id = auth.uid()` AND the connection-doctor RLS policy allows it.

## 11. Audit trail

Every mutation calls `public.create_audit_log()` (either directly or via the SQL function). Audit categories used here:

- `PRESCRIPTION_CREATE`
- `PRESCRIPTION_UPDATE` (with `details.is_urgent`, `details.field_changes`)
- `PRESCRIPTION_CONFIRM`
- `PRESCRIPTION_RETAKE`

These are written by the Flutter app's repository methods (which call the SQL function via `rpc`) so they always co-exist with the underlying mutation.

## 12. Edge cases

- **Multi-medication transactional consistency:** Inserting a prescription + N medications + N versions + ~M dose events is non-atomic in client→Supabase. Mitigation: insert prescription first; if any subsequent insert fails, mark prescription `status = 'DRAFT'` until the next sync attempt completes the rest.
- **Clock skew:** Use server `now()` for `dose_events` audit timestamps; client time only for the user's perceived "I took it now" timestamp.
- **Timezone change mid-prescription:** When user changes `profiles.timezone`, regenerate future dose events for all active prescriptions in the new timezone.

## 13. Testing

- Unit: `ScheduleGenerator` for fixed inputs (BID, TID, before-meal, PRN).
- Unit: lifecycle transition rules (paused → active regenerates correctly).
- Widget: form validation, urgent banner display, version-history list rendering.
- Integration: create → 30-day events appear in Drift → Supabase outbox drains → server view matches.
- RLS: pgtap asserts that doctor with `permission_level = 'REQUEST'` cannot insert; with `ALLOWED` can.
