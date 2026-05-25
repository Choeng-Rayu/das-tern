# Design: Supabase Data Layer (Postgres + RLS + Storage)

## 1. Schema overview

This document maps every v1 Prisma model into Supabase Postgres SQL with RLS. Field types and indexes are preserved 1:1 except where noted.

### 1.1 Schema diagram (logical)

```
auth.users (Supabase-managed)
   │ 1:1 ON DELETE CASCADE
   ▼
public.profiles ── 1:N ─► public.connections (initiator/recipient)
   │  1:1                     │ 1:N
   │  ▼                       ▼
   │  meal_time_preferences   connection_tokens
   │
   │  1:N
   ▼
public.prescriptions ─── 1:N ─► public.medications ── 1:N ─► public.dose_events
   │  1:N                          │  1:N (batch)
   ▼                               ▼
public.prescription_versions    public.medication_batches

public.notifications  (recipient_id → profiles.id)
public.audit_logs     (actor_id, resource_id)
public.subscriptions ── 1:N ─► public.family_members
public.doctor_notes   (doctor_id, patient_id → profiles)
```

## 2. Enums

```sql
-- supabase/migrations/20260601000000_enums.sql
-- ADDENDUM-001: user_role reduced to two values; FAMILY_MEMBER removed.
create type user_role            as enum ('PATIENT', 'DOCTOR');
create type gender                as enum ('MALE', 'FEMALE', 'OTHER');
create type language              as enum ('KHMER', 'ENGLISH');
create type theme                 as enum ('LIGHT', 'DARK');
create type account_status        as enum ('ACTIVE', 'PENDING_VERIFICATION', 'VERIFIED', 'REJECTED', 'LOCKED');
create type connection_status     as enum ('PENDING', 'ACCEPTED', 'REVOKED');
create type permission_level      as enum ('NOT_ALLOWED', 'REQUEST', 'SELECTED', 'ALLOWED');
create type prescription_status   as enum ('DRAFT', 'ACTIVE', 'PAUSED', 'INACTIVE');
create type time_period           as enum ('MORNING', 'AFTERNOON', 'EVENING', 'NIGHT');
create type dose_event_status     as enum ('DUE', 'TAKEN_ON_TIME', 'TAKEN_LATE', 'MISSED', 'SKIPPED');
create type subscription_tier     as enum ('FREEMIUM', 'PREMIUM', 'FAMILY_PREMIUM');
create type notification_type     as enum (
  'CONNECTION_REQUEST', 'PRESCRIPTION_UPDATE', 'MISSED_DOSE_ALERT',
  'URGENT_PRESCRIPTION_CHANGE', 'FAMILY_ALERT', 'VITAL_ANOMALY',
  'EMERGENCY_ALERT', 'REMINDER_ESCALATION', 'DOSE_CONFIRMED'
);
create type audit_action_type     as enum (
  'CONNECTION_REQUEST', 'CONNECTION_ACCEPT', 'CONNECTION_REVOKE',
  'PERMISSION_CHANGE', 'PRESCRIPTION_CREATE', 'PRESCRIPTION_UPDATE',
  'PRESCRIPTION_CONFIRM', 'PRESCRIPTION_RETAKE', 'DOSE_TAKEN',
  'DOSE_SKIPPED', 'DOSE_MISSED', 'DATA_ACCESS', 'NOTIFICATION_SENT',
  'SUBSCRIPTION_CHANGE', 'DOCTOR_NOTE_CREATE', 'DOCTOR_NOTE_UPDATE',
  'DOCTOR_DISCONNECT', 'VITAL_RECORDED', 'EMERGENCY_TRIGGERED'
);
create type medicine_type         as enum ('PO', 'ORAL', 'INJECTION', 'TOPICAL', 'OTHER');
create type medicine_unit         as enum ('TABLET', 'CAPSULE', 'ML', 'MG', 'DROP', 'OTHER');
```

## 3. Core tables

### 3.1 profiles

```sql
-- supabase/migrations/20260601000001_profiles.sql
create table public.profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  role                user_role not null default 'PATIENT',
  first_name          varchar(100),
  last_name           varchar(100),
  full_name           varchar(200),
  phone_number        varchar(20) unique,
  email               varchar(255) unique,
  google_id           varchar(255) unique,
  telegram_id         varchar(255) unique,
  telegram_username   varchar(255),
  telegram_first_name varchar(255),
  telegram_last_name  varchar(255),
  telegram_photo_url  text,
  gender              gender,
  date_of_birth       date,
  id_card_number      varchar(50) unique,
  profile_picture_url text,
  language            language not null default 'KHMER',
  theme               theme    not null default 'LIGHT',
  timezone            text     not null default 'Asia/Phnom_Penh',
  hospital_clinic     varchar(255),
  specialty           varchar(100),
  license_number      varchar(100) unique,
  license_photo_url   text,
  grace_period_minutes integer not null default 30,
  account_status      account_status not null default 'ACTIVE',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index profiles_phone_idx on public.profiles(phone_number);
create index profiles_email_idx on public.profiles(email);
create index profiles_role_idx on public.profiles(role);
create index profiles_account_status_idx on public.profiles(account_status);

-- Auto-create profile when an auth user is created
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- Auto-update updated_at
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.tg_set_updated_at();

-- RLS
alter table public.profiles enable row level security;
alter table public.profiles force row level security;

create policy "profiles_self_select" on public.profiles
  for select using (id = auth.uid());

create policy "profiles_self_update" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

create policy "profiles_connected_select" on public.profiles
  for select using (public.is_connected_with(id));
```

### 3.2 Connections

```sql
-- supabase/migrations/20260601000002_connections.sql
create table public.connections (
  id                uuid primary key default gen_random_uuid(),
  initiator_id      uuid not null references public.profiles(id) on delete cascade,
  recipient_id      uuid not null references public.profiles(id) on delete cascade,
  status            connection_status not null default 'PENDING',
  permission_level  permission_level not null default 'ALLOWED',
  metadata          jsonb,
  requested_at      timestamptz not null default now(),
  accepted_at       timestamptz,
  revoked_at        timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (initiator_id, recipient_id),
  check (initiator_id <> recipient_id)
);
create index connections_initiator_idx on public.connections(initiator_id);
create index connections_recipient_idx on public.connections(recipient_id);
create index connections_status_idx on public.connections(status);

create trigger connections_set_updated_at
before update on public.connections
for each row execute function public.tg_set_updated_at();

alter table public.connections enable row level security;
alter table public.connections force row level security;

create policy "connections_self_select" on public.connections
  for select using (initiator_id = auth.uid() or recipient_id = auth.uid());
create policy "connections_self_insert" on public.connections
  for insert with check (initiator_id = auth.uid());
create policy "connections_self_update" on public.connections
  for update using (initiator_id = auth.uid() or recipient_id = auth.uid())
              with check (initiator_id = auth.uid() or recipient_id = auth.uid());
create policy "connections_self_delete" on public.connections
  for delete using (initiator_id = auth.uid() or recipient_id = auth.uid());
```

### 3.3 Connection tokens

```sql
-- supabase/migrations/20260601000003_connection_tokens.sql
create table public.connection_tokens (
  id                uuid primary key default gen_random_uuid(),
  patient_id        uuid not null references public.profiles(id) on delete cascade,
  token             varchar(20) not null unique,
  permission_level  permission_level not null default 'ALLOWED',
  intended_role     user_role not null default 'PATIENT',  -- ADDENDUM-001: was 'FAMILY_MEMBER'
  expires_at        timestamptz not null,
  used_at           timestamptz,
  used_by_id        uuid references public.profiles(id),
  created_at        timestamptz not null default now()
);
create index connection_tokens_token_idx on public.connection_tokens(token);
create index connection_tokens_patient_idx on public.connection_tokens(patient_id);
create index connection_tokens_expires_idx on public.connection_tokens(expires_at);

alter table public.connection_tokens enable row level security;
alter table public.connection_tokens force row level security;

-- Patient can manage their own tokens
create policy "connection_tokens_owner_all" on public.connection_tokens
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());

-- Anyone authenticated can validate by token (read single row)
create policy "connection_tokens_validate_read" on public.connection_tokens
  for select using (auth.role() = 'authenticated');

-- Atomic consume via SQL function (see § 5)
```

### 3.4 Prescriptions, versions, medications

```sql
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
create index prescriptions_patient_idx on public.prescriptions(patient_id);
create index prescriptions_doctor_idx on public.prescriptions(doctor_id);
create index prescriptions_status_idx on public.prescriptions(status);
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
  id                    uuid primary key default gen_random_uuid(),
  prescription_id       uuid not null references public.prescriptions(id) on delete cascade,
  version_number        integer not null,
  author_id             uuid references public.profiles(id),
  change_reason         text,
  medications_snapshot  jsonb not null,
  created_at            timestamptz not null default now(),
  unique (prescription_id, version_number)
);
create index prescription_versions_prescription_idx on public.prescription_versions(prescription_id);

alter table public.prescription_versions enable row level security;
alter table public.prescription_versions force row level security;

create policy "prescription_versions_select_via_prescription" on public.prescription_versions
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

create policy "prescription_versions_insert_owner_or_doctor" on public.prescription_versions
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

-- Versions are append-only
create policy "prescription_versions_no_update" on public.prescription_versions
  for update using (false);
create policy "prescription_versions_no_delete" on public.prescription_versions
  for delete using (false);
```

### 3.5 Medications

```sql
-- supabase/migrations/20260601000005_medications.sql
create table public.medications (
  id                  uuid primary key default gen_random_uuid(),
  prescription_id     uuid not null references public.prescriptions(id) on delete cascade,
  row_number          integer not null,
  batch_id            uuid,
  medicine_name       varchar(255) not null,
  medicine_name_khmer varchar(255),
  image_url           text,
  medicine_type       medicine_type not null default 'ORAL',
  unit                medicine_unit not null default 'TABLET',
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
create index medications_batch_idx on public.medications(batch_id);

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

create policy "medications_write_owner_or_authoring_doctor" on public.medications
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
```

### 3.6 Dose events

```sql
-- supabase/migrations/20260601000006_dose_events.sql
create table public.dose_events (
  id                uuid primary key default gen_random_uuid(),
  prescription_id   uuid not null references public.prescriptions(id) on delete cascade,
  medication_id     uuid not null references public.medications(id) on delete cascade,
  patient_id        uuid not null references public.profiles(id) on delete cascade,
  scheduled_time    timestamptz not null,
  time_period       time_period not null,
  reminder_time     varchar(10),
  status            dose_event_status not null default 'DUE',
  taken_at          timestamptz,
  skip_reason       text,
  was_offline       boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index dose_events_patient_idx on public.dose_events(patient_id);
create index dose_events_scheduled_idx on public.dose_events(scheduled_time);
create index dose_events_status_idx on public.dose_events(status);
create index dose_events_patient_scheduled_idx on public.dose_events(patient_id, scheduled_time);
create index dose_events_prescription_idx on public.dose_events(prescription_id);

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

-- Doctors and peer-Patients cannot delete dose events
create policy "dose_events_no_external_delete" on public.dose_events
  for delete using (patient_id = auth.uid());
```

### 3.7 Notifications

```sql
-- supabase/migrations/20260601000007_notifications.sql
create table public.notifications (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references public.profiles(id) on delete cascade,
  type          notification_type not null,
  title         varchar(255) not null,
  message       text not null,
  data          jsonb,
  is_read       boolean not null default false,
  read_at       timestamptz,
  created_at    timestamptz not null default now()
);
create index notifications_recipient_idx on public.notifications(recipient_id);
create index notifications_recipient_read_idx on public.notifications(recipient_id, is_read);
create index notifications_created_idx on public.notifications(created_at);

alter table public.notifications enable row level security;
alter table public.notifications force row level security;

create policy "notifications_recipient_select" on public.notifications
  for select using (recipient_id = auth.uid());

create policy "notifications_recipient_update" on public.notifications
  for update using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

-- Inserts only via service_role (Edge Function) or via SQL function `create_notification`
create policy "notifications_no_client_insert" on public.notifications
  for insert with check (false);

create policy "notifications_no_client_delete" on public.notifications
  for delete using (false);
```

### 3.8 Audit logs

```sql
-- supabase/migrations/20260601000008_audit_logs.sql
create table public.audit_logs (
  id            uuid primary key default gen_random_uuid(),
  actor_id      uuid references public.profiles(id),
  actor_role    user_role,
  action_type   audit_action_type not null,
  resource_type varchar(100) not null,
  resource_id   uuid,
  details       jsonb,
  ip_address    varchar(45),
  created_at    timestamptz not null default now()
);
create index audit_actor_idx on public.audit_logs(actor_id);
create index audit_resource_idx on public.audit_logs(resource_id);
create index audit_created_idx on public.audit_logs(created_at);
create index audit_action_idx on public.audit_logs(action_type);

alter table public.audit_logs enable row level security;
alter table public.audit_logs force row level security;

-- Read: actor sees their own, patients see logs targeting their resources
create policy "audit_actor_select" on public.audit_logs
  for select using (actor_id = auth.uid());

create policy "audit_resource_owner_select" on public.audit_logs
  for select using (
    exists (
      select 1 from public.prescriptions p
      where p.id = resource_id and p.patient_id = auth.uid()
    )
    or exists (
      select 1 from public.dose_events d
      where d.id = resource_id and d.patient_id = auth.uid()
    )
  );

-- Append-only
create policy "audit_no_update" on public.audit_logs
  for update using (false);
create policy "audit_no_delete" on public.audit_logs
  for delete using (false);
-- Inserts go through SQL function only
create policy "audit_no_direct_insert" on public.audit_logs
  for insert with check (false);
```

### 3.9 Subscriptions and family members

```sql
-- supabase/migrations/20260601000009_subscriptions.sql
create table public.subscriptions (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null unique references public.profiles(id) on delete cascade,
  tier                  subscription_tier not null default 'FREEMIUM',
  storage_quota         bigint not null default 5368709120,  -- 5 GB
  storage_used          bigint not null default 0,
  expires_at            timestamptz,
  has_used_trial        boolean not null default false,
  -- Google Play tracking
  play_purchase_token   text,           -- last verified purchase token
  play_product_id       text,           -- e.g. "premium_monthly"
  play_subscription_id  text,           -- subscriptionId from Play
  play_state            text,           -- ACTIVE | IN_GRACE | ON_HOLD | PAUSED | CANCELED | EXPIRED
  play_acknowledged     boolean not null default false,
  play_renewal_at       timestamptz,
  play_last_event       jsonb,          -- last RTDN payload
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
create index subscriptions_user_idx on public.subscriptions(user_id);
create index subscriptions_tier_idx on public.subscriptions(tier);
create index subscriptions_play_token_idx on public.subscriptions(play_purchase_token);

create trigger subscriptions_set_updated_at
before update on public.subscriptions
for each row execute function public.tg_set_updated_at();

alter table public.subscriptions enable row level security;
alter table public.subscriptions force row level security;

create policy "subscriptions_self_select" on public.subscriptions
  for select using (user_id = auth.uid());
create policy "subscriptions_no_client_write" on public.subscriptions
  for all using (false) with check (false);  -- service_role bypasses RLS

create table public.family_members (
  id              uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  member_id       uuid not null references public.profiles(id) on delete cascade,
  added_at        timestamptz not null default now(),
  unique (subscription_id, member_id)
);
create index family_members_subscription_idx on public.family_members(subscription_id);

alter table public.family_members enable row level security;
alter table public.family_members force row level security;

create policy "family_members_owner_or_member_select" on public.family_members
  for select using (
    member_id = auth.uid()
    or exists (
      select 1 from public.subscriptions s
      where s.id = subscription_id and s.user_id = auth.uid()
    )
  );

create policy "family_members_no_client_write" on public.family_members
  for all using (false) with check (false);
```

### 3.10 Other tables (compact)

```sql
-- meal_time_preferences
create table public.meal_time_preferences (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null unique references public.profiles(id) on delete cascade,
  morning_meal    varchar(20),
  afternoon_meal  varchar(20),
  evening_meal    varchar(20),
  night_meal      varchar(20),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
alter table public.meal_time_preferences enable row level security;
alter table public.meal_time_preferences force row level security;
create policy "mtp_owner_all" on public.meal_time_preferences
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- doctor_notes (private to the doctor that wrote them; never visible to the patient)
create table public.doctor_notes (
  id          uuid primary key default gen_random_uuid(),
  doctor_id   uuid not null references public.profiles(id) on delete cascade,
  patient_id  uuid not null references public.profiles(id) on delete cascade,
  content     text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index doctor_notes_doctor_idx on public.doctor_notes(doctor_id);
create index doctor_notes_patient_idx on public.doctor_notes(patient_id);
create index doctor_notes_doctor_patient_idx on public.doctor_notes(doctor_id, patient_id);
alter table public.doctor_notes enable row level security;
alter table public.doctor_notes force row level security;

-- Only the doctor who wrote the note can see/edit it
create policy "doctor_notes_author_all" on public.doctor_notes
  for all using (doctor_id = auth.uid()) with check (doctor_id = auth.uid());

-- medication_batches
create table public.medication_batches (
  id              uuid primary key default gen_random_uuid(),
  patient_id      uuid not null references public.profiles(id) on delete cascade,
  name            varchar(255) not null,
  scheduled_time  varchar(10) not null,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
alter table public.medication_batches enable row level security;
alter table public.medication_batches force row level security;
create policy "med_batches_owner_all" on public.medication_batches
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());
```

## 4. Policy helper functions

```sql
-- supabase/migrations/20260601000100_policy_helpers.sql

create or replace function public.is_connected_with(other_id uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from public.connections c
    where c.status = 'ACCEPTED'
      and (
        (c.initiator_id = auth.uid() and c.recipient_id = other_id)
        or (c.recipient_id = auth.uid() and c.initiator_id = other_id)
      )
  );
$$;

create or replace function public.is_connected_doctor_for(
  p_patient_id uuid,
  require_allowed boolean default false
) returns boolean language sql stable as $$
  select exists (
    select 1
    from public.connections c
    join public.profiles me on me.id = auth.uid()
    where c.status = 'ACCEPTED'
      and me.role = 'DOCTOR'
      and (
        (c.initiator_id = auth.uid() and c.recipient_id = p_patient_id)
        or (c.recipient_id = auth.uid() and c.initiator_id = p_patient_id)
      )
      and (
        not require_allowed
        or c.permission_level = 'ALLOWED'
      )
  );
$$;

create or replace function public.is_connected_peer_patient_for(p_patient_id uuid)
returns boolean language sql stable as $$
  -- ADDENDUM-001: replaces is_connected_family_for. Mutual: both endpoints must be PATIENT.
  select exists (
    select 1
    from public.connections c
    join public.profiles me on me.id = auth.uid()
    join public.profiles other on other.id = p_patient_id
    where c.status = 'ACCEPTED'
      and me.role = 'PATIENT'
      and other.role = 'PATIENT'
      and c.permission_level <> 'NOT_ALLOWED'
      and (
        (c.initiator_id = auth.uid() and c.recipient_id = p_patient_id)
        or (c.recipient_id = auth.uid() and c.initiator_id = p_patient_id)
      )
  );
$$;
```

## 5. Postgres functions for atomic ops

```sql
-- supabase/migrations/20260601000200_functions.sql

-- 5.1 consume connection token
create or replace function public.consume_connection_token(p_token text)
returns uuid language plpgsql security definer as $$
declare
  v_row public.connection_tokens;
  v_connection_id uuid;
begin
  select * into v_row from public.connection_tokens
   where token = p_token
   for update;
  if not found then raise exception 'token_not_found' using errcode = 'P0002'; end if;
  if v_row.expires_at < now() then raise exception 'token_expired'; end if;
  if v_row.used_at is not null then raise exception 'token_already_used'; end if;
  if v_row.patient_id = auth.uid() then raise exception 'self_connection_not_allowed'; end if;

  update public.connection_tokens
     set used_at = now(), used_by_id = auth.uid()
   where id = v_row.id;

  insert into public.connections (initiator_id, recipient_id, permission_level, status)
  values (auth.uid(), v_row.patient_id, v_row.permission_level, 'PENDING')
  on conflict (initiator_id, recipient_id) do update set status = 'PENDING'
  returning id into v_connection_id;

  insert into public.audit_logs (actor_id, action_type, resource_type, resource_id, details)
  values (auth.uid(), 'CONNECTION_REQUEST', 'connections', v_connection_id,
          jsonb_build_object('token_id', v_row.id, 'patient_id', v_row.patient_id));

  return v_connection_id;
end;
$$;

-- 5.2 accept connection
create or replace function public.accept_connection(
  p_connection_id uuid,
  p_permission permission_level default null
) returns public.connections language plpgsql security definer as $$
declare
  v_row public.connections;
begin
  select * into v_row from public.connections where id = p_connection_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_row.recipient_id <> auth.uid() and v_row.initiator_id <> auth.uid() then
    raise exception 'forbidden';
  end if;
  if v_row.status <> 'PENDING' then raise exception 'invalid_state'; end if;

  update public.connections
     set status = 'ACCEPTED',
         permission_level = coalesce(p_permission, permission_level),
         accepted_at = now()
   where id = p_connection_id
   returning * into v_row;

  insert into public.audit_logs (actor_id, action_type, resource_type, resource_id, details)
  values (auth.uid(), 'CONNECTION_ACCEPT', 'connections', v_row.id,
          jsonb_build_object('permission_level', v_row.permission_level));
  return v_row;
end;
$$;

-- 5.3 mark dose event
create or replace function public.mark_dose(
  p_dose_id uuid,
  p_status dose_event_status,
  p_taken_at timestamptz default now(),
  p_skip_reason text default null,
  p_was_offline boolean default false
) returns public.dose_events language plpgsql security definer as $$
declare v_row public.dose_events;
begin
  select * into v_row from public.dose_events where id = p_dose_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_row.patient_id <> auth.uid() then raise exception 'forbidden'; end if;
  if v_row.status not in ('DUE','MISSED') then raise exception 'invalid_state'; end if;

  update public.dose_events
     set status = p_status,
         taken_at = case when p_status in ('TAKEN_ON_TIME','TAKEN_LATE') then p_taken_at else taken_at end,
         skip_reason = case when p_status = 'SKIPPED' then p_skip_reason else null end,
         was_offline = was_offline or p_was_offline
   where id = p_dose_id
   returning * into v_row;

  insert into public.audit_logs (actor_id, action_type, resource_type, resource_id, details)
  values (auth.uid(),
          case p_status
            when 'TAKEN_ON_TIME' then 'DOSE_TAKEN'::audit_action_type
            when 'TAKEN_LATE'    then 'DOSE_TAKEN'::audit_action_type
            when 'SKIPPED'       then 'DOSE_SKIPPED'::audit_action_type
            when 'MISSED'        then 'DOSE_MISSED'::audit_action_type
            else 'DOSE_TAKEN'::audit_action_type
          end,
          'dose_events', v_row.id,
          jsonb_build_object('status', p_status, 'was_offline', p_was_offline));
  return v_row;
end;
$$;

-- 5.4 create_audit_log (only via this function, never direct INSERT)
create or replace function public.create_audit_log(
  p_action audit_action_type,
  p_resource_type text,
  p_resource_id uuid,
  p_details jsonb default '{}'::jsonb
) returns void language plpgsql security definer as $$
begin
  insert into public.audit_logs (actor_id, actor_role, action_type, resource_type, resource_id, details)
  values (auth.uid(),
          (select role from public.profiles where id = auth.uid()),
          p_action, p_resource_type, p_resource_id, p_details);
end;
$$;

-- 5.5 adherence (period: 'today' | '7d' | '30d')
create or replace function public.get_adherence(p_patient_id uuid, p_period text default '7d')
returns numeric language sql stable security definer as $$
  with bounds as (
    select case p_period
      when 'today' then date_trunc('day', now())
      when '7d'    then now() - interval '7 days'
      when '30d'   then now() - interval '30 days'
      when '90d'   then now() - interval '90 days'
    end as start_at
  ),
  doses as (
    select status from public.dose_events de
    where de.patient_id = p_patient_id
      and de.scheduled_time >= (select start_at from bounds)
      and de.scheduled_time <= now()
      and not exists (
        select 1 from public.medications m
        where m.id = de.medication_id and m.is_prn = true
      )
  )
  select case when count(*) = 0 then 100
              else round(100.0 * count(*) filter (where status in ('TAKEN_ON_TIME','TAKEN_LATE')) / count(*), 2)
         end
  from doses;
$$;

-- 5.6 expire missed doses (called by pg_cron)
create or replace function public.expire_missed_doses()
returns integer language plpgsql security definer as $$
declare v_count integer;
begin
  with affected as (
    update public.dose_events de
       set status = 'MISSED'
      from public.profiles p
     where de.status = 'DUE'
       and de.patient_id = p.id
       and de.scheduled_time + (p.grace_period_minutes || ' minutes')::interval < now()
     returning de.id, de.patient_id
  )
  select count(*) into v_count from affected;
  return v_count;
end;
$$;
```

## 6. Realtime publication

```sql
-- supabase/migrations/20260601000300_realtime.sql
alter publication supabase_realtime add table
  public.dose_events,
  public.notifications,
  public.prescriptions,
  public.connections;

-- For Realtime to respect RLS, the publication is filtered by the same policies above.
-- See https://supabase.com/docs/guides/realtime/postgres-changes#row-level-security
```

## 7. Storage buckets

```sql
-- supabase/migrations/20260601000400_storage.sql
insert into storage.buckets (id, name, public)
values
  ('profile-pictures',    'profile-pictures',    false),
  ('prescription-images', 'prescription-images', false),
  ('doctor-licenses',     'doctor-licenses',     false),
  ('app-assets',          'app-assets',          true)
on conflict (id) do nothing;

-- Path conventions enforced by policies:
--   profile-pictures/{user_id}/...
--   prescription-images/{patient_id}/{prescription_id}/...
--   doctor-licenses/{doctor_id}/...

-- profile-pictures: user can read/write only their own
create policy "pp_owner_read" on storage.objects for select
  using (bucket_id = 'profile-pictures'
         and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pp_owner_write" on storage.objects for insert
  with check (bucket_id = 'profile-pictures'
              and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pp_owner_update" on storage.objects for update
  using (bucket_id = 'profile-pictures'
         and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pp_owner_delete" on storage.objects for delete
  using (bucket_id = 'profile-pictures'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- prescription-images: patient owns; connected doctors can read
create policy "pi_owner_all" on storage.objects for all
  using (bucket_id = 'prescription-images'
         and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'prescription-images'
              and (storage.foldername(name))[1] = auth.uid()::text);

create policy "pi_doctor_read" on storage.objects for select
  using (bucket_id = 'prescription-images'
         and public.is_connected_doctor_for(((storage.foldername(name))[1])::uuid));
```

## 8. Drift mirror schema

The Flutter app uses Drift tables that mirror the Supabase tables 1:1 for offline use. Each Drift table has the same columns; enums are stored as `text` and validated in Dart.

```dart
// das_tern_mcp/lib/core/storage/drift/tables/profiles_table.dart
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get role => text().withLength(min: 1, max: 32)();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get fullName => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get language => text().withDefault(const Constant('KHMER'))();
  TextColumn get theme => text().withDefault(const Constant('LIGHT'))();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Phnom_Penh'))();
  IntColumn  get gracePeriodMinutes => integer().withDefault(const Constant(30))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // ... all other profile columns

  @override
  Set<Column> get primaryKey => {id};
}
```

Drift tables: `Profiles`, `Connections`, `ConnectionTokens`, `Prescriptions`, `PrescriptionVersions`, `Medications`, `DoseEvents`, `Notifications`, `MealTimePreferences`, `MedicationBatches`, `Subscriptions`, `FamilyMembers`, `DoctorNotes`, `OutboxEntries`, `AuditLogs`.

`AuditLogs` is mirrored read-only — never written locally; populated only by sync from Supabase.

## 9. RLS testing with pgtap

```sql
-- supabase/tests/rls/prescriptions.test.sql
begin;
select plan(8);

-- set up two test users via auth.users insert (admin via service_role in test runner)
-- ...

-- Patient can SELECT own prescription
set local request.jwt.claims to '{"sub":"<patient_uuid>","role":"authenticated"}';
select results_eq(
  $$ select count(*)::int from public.prescriptions where id = '<own_id>' $$,
  $$ values (1) $$,
  'patient sees own prescription'
);

-- Patient cannot SELECT another patient's prescription
select results_eq(
  $$ select count(*)::int from public.prescriptions where id = '<other_id>' $$,
  $$ values (0) $$,
  'patient cannot see another patient prescription'
);

-- Connected doctor can SELECT
set local request.jwt.claims to '{"sub":"<doctor_uuid>","role":"authenticated"}';
-- ... etc

select * from finish();
rollback;
```

CI runs: `supabase test db --project-ref <staging-ref>` on every PR.

## 10. Migration strategy

1. **Forward-only migrations** — no editing of merged migration files.
2. **Naming** — `YYYYMMDDHHMMSS_<short_description>.sql` (UTC timestamp).
3. **Reversibility** — migrations should be designed to be applied to a populated dev DB without data loss; destructive changes require explicit team review.
4. **Local dev** — `supabase db reset` re-runs the entire migration set + `seed.sql`.
5. **Staging** — `supabase db push` from CI on `main` merge.
6. **Production** — manual `supabase db push` after release approval.

## 11. Storage usage tracking (subscription quota)

The `subscriptions.storage_used` column is updated by a Postgres function that runs on Storage object insert/delete via the `storage.objects` table:

```sql
create or replace function public.update_storage_usage()
returns trigger language plpgsql as $$
begin
  if (tg_op = 'INSERT') then
    update public.subscriptions s
       set storage_used = storage_used + new.metadata->>'size'::bigint
     where s.user_id = (storage.foldername(new.name))[1]::uuid;
  elsif (tg_op = 'DELETE') then
    update public.subscriptions s
       set storage_used = greatest(0, storage_used - old.metadata->>'size'::bigint)
     where s.user_id = (storage.foldername(old.name))[1]::uuid;
  end if;
  return null;
end;
$$;

create trigger storage_usage_track
after insert or delete on storage.objects
for each row execute function public.update_storage_usage();
```

## 12. Indexes summary

All indexes from v1 Prisma schema are preserved. Additional indexes added for v2:

- `subscriptions(play_purchase_token)` — for RTDN webhook lookups.
- `connections(initiator_id, recipient_id, status)` — composite for connection-check policies.
- `dose_events(patient_id, status)` — for "today's dues" queries.
