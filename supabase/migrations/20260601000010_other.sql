-- supabase/migrations/20260601000010_other.sql

-- meal_time_preferences
create table public.meal_time_preferences (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null unique references public.profiles(id) on delete cascade,
  morning_meal   varchar(20),
  afternoon_meal varchar(20),
  evening_meal   varchar(20),
  night_meal     varchar(20),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create trigger mtp_set_updated_at
before update on public.meal_time_preferences
for each row execute function public.tg_set_updated_at();

alter table public.meal_time_preferences enable row level security;
alter table public.meal_time_preferences force row level security;

create policy "mtp_owner_all" on public.meal_time_preferences
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- doctor_notes (private to the authoring doctor; never visible to the patient)
create table public.doctor_notes (
  id         uuid primary key default gen_random_uuid(),
  doctor_id  uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  content    text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index doctor_notes_doctor_idx         on public.doctor_notes(doctor_id);
create index doctor_notes_patient_idx        on public.doctor_notes(patient_id);
create index doctor_notes_doctor_patient_idx on public.doctor_notes(doctor_id, patient_id);

create trigger doctor_notes_set_updated_at
before update on public.doctor_notes
for each row execute function public.tg_set_updated_at();

alter table public.doctor_notes enable row level security;
alter table public.doctor_notes force row level security;

create policy "doctor_notes_author_all" on public.doctor_notes
  for all using (doctor_id = auth.uid()) with check (doctor_id = auth.uid());

-- medication_batches
create table public.medication_batches (
  id             uuid primary key default gen_random_uuid(),
  patient_id     uuid not null references public.profiles(id) on delete cascade,
  name           varchar(255) not null,
  scheduled_time varchar(10) not null,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create trigger med_batches_set_updated_at
before update on public.medication_batches
for each row execute function public.tg_set_updated_at();

alter table public.medication_batches enable row level security;
alter table public.medication_batches force row level security;

create policy "med_batches_owner_all" on public.medication_batches
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());
