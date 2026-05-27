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

create index profiles_phone_idx          on public.profiles(phone_number);
create index profiles_email_idx          on public.profiles(email);
create index profiles_role_idx           on public.profiles(role);
create index profiles_account_status_idx on public.profiles(account_status);

-- Shared updated_at trigger function (used by all tables)
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.tg_set_updated_at();

-- Auto-create profile row when auth user is created
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (
    new.id,
    new.email,
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'PATIENT')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- RLS
alter table public.profiles enable row level security;
alter table public.profiles force row level security;

create policy "profiles_self_select" on public.profiles
  for select using (id = auth.uid());

create policy "profiles_self_update" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

create policy "profiles_connected_select" on public.profiles
  for select using (public.is_connected_with(id));
