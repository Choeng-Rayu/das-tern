-- supabase/migrations/20260601000004_prescriptions.sql

create table public.prescriptions (
  id                    uuid primary key default gen_random_uuid(),
  patient_id            uuid not null references public.profiles(id) on delete cascade,
  doctor_id             uuid references public.profiles(id),
  patient_name          varchar(200) not null,
  patient_gender        gender not null,
  patient_age           integer not null,
  symptoms              text not null default '',
  diagnosis             text,
  clinical_note         text,
  doctor_license_number varchar(100),
  follow_up_date        date,
  start_date            date,
  end_date              date,
  ocr_metadata          jsonb,
  status                prescription_status not null default 'DRAFT',
  current_version       integer not null default 1,
  is_urgent             boolean not null default false,
  urgent_reason         text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create index prescriptions_patient_idx        on public.prescriptions(patient_id);
create index prescriptions_doctor_idx         on public.prescriptions(doctor_id);
create index prescriptions_status_idx         on public.prescriptions(status);
create index prescriptions_patient_status_idx on public.prescriptions(patient_id, status);

create trigger prescriptions_set_updated_at
before update on public.prescriptions
for each row execute function public.tg_set_updated_at();

alter table public.prescriptions enable row level security;
alter table public.prescriptions force row level security;

create policy "prescriptions_patient_all" on public.prescriptions
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());

create policy "prescriptions_connected_doctor_select" on public.prescriptions
  for select using (public.is_connected_doctor_for(patient_id));

create policy "prescriptions_connected_doctor_write" on public.prescriptions
  for insert with check (
    doctor_id = auth.uid()
    and public.is_connected_doctor_for(patient_id, require_allowed := true)
  );

create policy "prescriptions_connected_doctor_update" on public.prescriptions
  for update using (
    doctor_id = auth.uid()
    and public.is_connected_doctor_for(patient_id, require_allowed := true)
  ) with check (doctor_id = auth.uid());

create policy "prescriptions_peer_patient_select" on public.prescriptions
  for select using (public.is_connected_peer_patient_for(patient_id));

-- prescription_versions (immutable history)
create table public.prescription_versions (
  id                   uuid primary key default gen_random_uuid(),
  prescription_id      uuid not null references public.prescriptions(id) on delete cascade,
  version_number       integer not null,
  author_id            uuid references public.profiles(id),
  change_reason        text,
  medications_snapshot jsonb not null,
  created_at           timestamptz not null default now(),
  unique (prescription_id, version_number)
);

create index prescription_versions_prescription_idx on public.prescription_versions(prescription_id);

alter table public.prescription_versions enable row level security;
alter table public.prescription_versions force row level security;

create policy "prescription_versions_select" on public.prescription_versions
  for select using (
    exists (
      select 1 from public.prescriptions p
      where p.id = prescription_id
        and (
          p.patient_id = auth.uid()
          or public.is_connected_doctor_for(p.patient_id)
          or public.is_connected_peer_patient_for(p.patient_id)
        )
    )
  );

create policy "prescription_versions_insert" on public.prescription_versions
  for insert with check (
    exists (
      select 1 from public.prescriptions p
      where p.id = prescription_id
        and (
          p.patient_id = auth.uid()
          or (p.doctor_id = auth.uid()
              and public.is_connected_doctor_for(p.patient_id, require_allowed := true))
        )
    )
  );

create policy "prescription_versions_no_update" on public.prescription_versions
  for update using (false);

create policy "prescription_versions_no_delete" on public.prescription_versions
  for delete using (false);
