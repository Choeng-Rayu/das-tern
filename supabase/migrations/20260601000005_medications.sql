-- supabase/migrations/20260601000005_medications.sql

create table public.medications (
  id                  uuid primary key default gen_random_uuid(),
  prescription_id     uuid not null references public.prescriptions(id) on delete cascade,
  row_number          integer not null,
  batch_id            uuid,
  medicine_name       varchar(255) not null,
  medicine_name_khmer varchar(255),
  image_url           text,
  medicine_type       medicine_type  not null default 'ORAL',
  unit                medicine_unit  not null default 'TABLET',
  dosage_amount       double precision not null default 1,
  description         text,
  additional_note     text,
  created_by          uuid references public.profiles(id),
  morning_dosage      jsonb,
  afternoon_dosage    jsonb,
  evening_dosage      jsonb,
  night_dosage        jsonb,
  frequency           varchar(100),
  duration            integer,
  timing              varchar(100),
  is_prn              boolean not null default false,
  before_meal         boolean not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index medications_prescription_idx on public.medications(prescription_id);
create index medications_batch_idx        on public.medications(batch_id);

create trigger medications_set_updated_at
before update on public.medications
for each row execute function public.tg_set_updated_at();

alter table public.medications enable row level security;
alter table public.medications force row level security;

create policy "medications_select_via_prescription" on public.medications
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

create policy "medications_write_owner_or_doctor" on public.medications
  for all using (
    exists (
      select 1 from public.prescriptions p
      where p.id = prescription_id
        and (
          p.patient_id = auth.uid()
          or (p.doctor_id = auth.uid()
              and public.is_connected_doctor_for(p.patient_id, require_allowed := true))
        )
    )
  ) with check (
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
