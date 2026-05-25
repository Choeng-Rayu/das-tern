# Design: Doctor Dashboard

## 1. Module structure

```
lib/features/doctor_dashboard/
├── data/
│   ├── doctor_patient_repository.dart    # query patients connected to current doctor
│   ├── doctor_note_repository.dart       # private notes
│   └── doctor_alert_repository.dart      # adherence alerts
├── domain/
│   ├── doctor_patient_summary.dart       # freezed
│   ├── adherence_alert.dart
│   └── usecases/
│       ├── load_doctor_home.dart
│       ├── search_my_patients.dart
│       ├── add_note.dart
│       ├── edit_note.dart
│       ├── delete_note.dart
│       └── acknowledge_alert.dart
└── presentation/
    ├── pages/
    │   ├── doctor_home_page.dart
    │   ├── patient_list_page.dart
    │   ├── patient_detail_page.dart
    │   ├── notes_tab.dart
    │   ├── adherence_tab.dart
    │   └── prescriptions_tab.dart
    └── widgets/
        ├── adherence_indicator.dart
        ├── critical_alert_card.dart
        ├── patient_row.dart
        └── note_editor.dart
```

## 2. Patient list query

The doctor's patient list is built from the `connections` table joined with `profiles` and a per-patient `get_adherence` call. Postgres view simplifies this:

```sql
-- supabase/migrations/20260601000600_doctor_views.sql
create or replace view public.doctor_patient_summary as
select
  p.id              as patient_id,
  p.full_name       as patient_name,
  p.date_of_birth,
  p.profile_picture_url,
  c.id              as connection_id,
  c.permission_level,
  c.accepted_at,
  -- last activity = max(updated_at) across patient's recent dose_events
  (select max(updated_at) from public.dose_events de
    where de.patient_id = p.id) as last_activity_at,
  -- active prescriptions
  (select count(*) from public.prescriptions pr
    where pr.patient_id = p.id and pr.status = 'ACTIVE') as active_prescription_count
from public.profiles p
join public.connections c
  on (c.recipient_id = p.id and c.initiator_id = auth.uid())
  or (c.initiator_id = p.id and c.recipient_id = auth.uid())
where c.status = 'ACCEPTED'
  and p.role = 'PATIENT'
  and exists (select 1 from public.profiles me
               where me.id = auth.uid() and me.role = 'DOCTOR');

-- adherence is fetched per row via rpc to avoid joining a large table
```

```dart
@riverpod
Future<List<DoctorPatientSummary>> doctorPatients(
  DoctorPatientsRef ref, {
  AdherenceBand? adherenceBand,
  String? query,
  int page = 0,
}) async {
  final supabase = ref.watch(supabaseClientProvider);
  final base = supabase.from('doctor_patient_summary')
    .select('*')
    .order('last_activity_at', ascending: false)
    .range(page * 20, page * 20 + 19);
  final rows = query == null || query.isEmpty
    ? await base
    : await base.ilike('patient_name', '%$query%');

  // Fetch adherence in parallel
  final summaries = await Future.wait((rows as List).map((row) async {
    final pct = await supabase.rpc('get_adherence', params: {
      'p_patient_id': row['patient_id'],
      'p_period': '7d',
    });
    return DoctorPatientSummary.fromRow(row, (pct as num).toDouble());
  }));

  // Filter by adherence band client-side after fetch
  if (adherenceBand != null) {
    return summaries.where((s) => s.adherenceBand == adherenceBand).toList();
  }
  return summaries;
}
```

## 3. Critical alerts

A SQL function flags patients who triggered alerts in the last 7 days:

```sql
create or replace function public.doctor_critical_alerts()
returns table (
  patient_id uuid,
  patient_name text,
  alert_kind text,           -- 'consecutive_missed' | 'low_adherence_7d'
  detected_at timestamptz,
  details jsonb
) language sql stable security definer as $$
  with my_patients as (
    select p.id as patient_id, p.full_name as patient_name
      from public.profiles p
      join public.connections c
        on (c.initiator_id = p.id or c.recipient_id = p.id)
     where c.status = 'ACCEPTED'
       and (c.initiator_id = auth.uid() or c.recipient_id = auth.uid())
       and p.role = 'PATIENT'
       and (select role from public.profiles where id = auth.uid()) = 'DOCTOR'
  ),
  consecutive as (
    select mp.patient_id, mp.patient_name,
           'consecutive_missed' as alert_kind,
           max(de.scheduled_time) as detected_at,
           jsonb_build_object('count', count(*)) as details
      from my_patients mp
      join public.dose_events de on de.patient_id = mp.patient_id
     where de.status = 'MISSED'
       and de.scheduled_time > now() - interval '3 days'
     group by mp.patient_id, mp.patient_name
    having count(*) >= 3
  ),
  low_adh as (
    select mp.patient_id, mp.patient_name,
           'low_adherence_7d' as alert_kind,
           now() as detected_at,
           jsonb_build_object('adherence', public.get_adherence(mp.patient_id, '7d')) as details
      from my_patients mp
     where public.get_adherence(mp.patient_id, '7d') < 70
  )
  select * from consecutive
  union all
  select * from low_adh
$$;
```

```dart
@riverpod
Future<List<AdherenceAlert>> doctorAlerts(DoctorAlertsRef ref) async {
  final res = await Supabase.instance.client.rpc('doctor_critical_alerts');
  return (res as List).map((r) => AdherenceAlert.fromJson(r)).toList();
}
```

## 4. Doctor home page layout

```dart
class DoctorHomePage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(doctorPatientsProvider());
    final alerts = ref.watch(doctorAlertsProvider);
    return Scaffold(
      body: ListView(children: [
        SummaryRow(
          totalPatients: patients.valueOrNull?.length ?? 0,
          underAdherence: patients.valueOrNull
              ?.where((p) => p.adherence < 70).length ?? 0,
        ),
        if (alerts.valueOrNull != null && alerts.value!.isNotEmpty)
          CriticalAlertsSection(alerts: alerts.value!),
        RecentActivityFeed(),
        QuickPatientList(patients: patients),
      ]),
    );
  }
}
```

## 5. Patient detail tabs

`PatientDetailPage` uses `TabBar` with three tabs:

1. **Overview** — basic info, active prescriptions, today's adherence.
2. **Adherence** — 30-day timeline chart, weekly/monthly breakdown.
3. **Notes** — private doctor notes (CRUD).
4. **History** — version history of prescriptions, audit trail of doctor's own actions.

`prescriptions` tab links into `03-prescription-medication`'s authoring page when the doctor wants to add/edit.

## 6. Notes CRUD

```dart
class DoctorNoteRepository {
  Stream<List<DoctorNote>> watchForPatient(String patientId) =>
    _db.doctorNoteDao.watchByPatient(patientId);

  Future<DoctorNote> add(String patientId, String content) async {
    final row = {
      'doctor_id': _supabase.auth.currentUser!.id,
      'patient_id': patientId,
      'content': content,
    };
    final inserted = await _supabase.from('doctor_notes').insert(row).select().single();
    final note = DoctorNote.fromJson(inserted);
    await _db.doctorNoteDao.upsert(note);
    return note;
  }

  Future<void> edit(String id, String newContent) async {
    await _supabase.from('doctor_notes').update({'content': newContent}).eq('id', id);
    await _db.doctorNoteDao.updateContent(id, newContent);
  }

  Future<void> delete(String id) async {
    await _supabase.from('doctor_notes').delete().eq('id', id);
    await _db.doctorNoteDao.delete(id);
  }
}
```

RLS guarantees only the authoring doctor can read/write.

## 7. Realtime ingest for doctor

```dart
class DoctorRealtimeListener {
  void start(String doctorId) {
    final supabase = Supabase.instance.client;
    supabase.channel('doctor-$doctorId')
      ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dose_events',
          callback: _onDoseChange)
      ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'prescriptions',
          callback: _onPrescriptionChange)
      ..subscribe();
  }
  void _onDoseChange(PostgresChangePayload p) {
    _ref.invalidate(doctorPatientsProvider);
    _ref.invalidate(doctorAlertsProvider);
  }
  ...
}
```

## 8. Performance notes

- Patient list page caches results for 60 seconds in Riverpod, refreshes on pull-to-refresh.
- Adherence values cached in Drift for 5 minutes (already from `04-reminder-adherence`).
- Bulk-fetch patient summaries via the `doctor_patient_summary` view to avoid N+1.
- Search debounced at 300 ms.

## 9. Accessibility

- All buttons have semantic labels.
- Adherence indicator includes both color and shape (icon) for color-blind users.
- Notes editor supports system text scaling.

## 10. Testing

- Unit: AdherenceBand calculation from raw percentage.
- Widget: PatientRow renders correct color indicator for various percentages.
- Integration: doctor connects to patient → sees them in list within 5s of accept.
- pgtap: doctor_critical_alerts returns correct rows for seeded data.
- Security: doctor without `permission_level = 'ALLOWED'` cannot create prescriptions (verified by RLS test).
