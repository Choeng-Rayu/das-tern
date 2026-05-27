-- supabase/migrations/20260601000006_dose_events.sql

create table public.dose_events (
  id              uuid primary key default gen_random_uuid(),
  prescription_id uuid not null references public.prescriptions(id) on delete cascade,
  medication_id   uuid not null references public.medications(id) on delete cascade,
  patient_id      uuid not null references public.profiles(id) on delete cascade,
  scheduled_time  timestamptz not null,
  time_period     time_period not null,
  reminder_time   varchar(10),
  status          dose_event_status not null default 'DUE',
  taken_at        timestamptz,
  skip_reason     text,
  was_offline     boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index dose_events_patient_idx           on public.dose_events(patient_id);
create index dose_events_scheduled_idx         on public.dose_events(scheduled_time);
create index dose_events_status_idx            on public.dose_events(status);
create index dose_events_patient_scheduled_idx on public.dose_events(patient_id, scheduled_time);
create index dose_events_prescription_idx      on public.dose_events(prescription_id);

create trigger dose_events_set_updated_at
before update on public.dose_events
for each row execute function public.tg_set_updated_at();

alter table public.dose_events enable row level security;
alter table public.dose_events force row level security;

create policy "dose_events_patient_all" on public.dose_events
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());

create policy "dose_events_connected_select" on public.dose_events
  for select using (
    public.is_connected_doctor_for(patient_id)
    or public.is_connected_peer_patient_for(patient_id)
  );

create policy "dose_events_no_external_delete" on public.dose_events
  for delete using (patient_id = auth.uid());
