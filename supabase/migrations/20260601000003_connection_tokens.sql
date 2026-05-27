-- supabase/migrations/20260601000003_connection_tokens.sql

create table public.connection_tokens (
  id               uuid primary key default gen_random_uuid(),
  patient_id       uuid not null references public.profiles(id) on delete cascade,
  token            varchar(20) not null unique,
  permission_level permission_level not null default 'ALLOWED',
  intended_role    user_role not null default 'PATIENT',  -- ADDENDUM-001
  expires_at       timestamptz not null,
  used_at          timestamptz,
  used_by_id       uuid references public.profiles(id),
  created_at       timestamptz not null default now()
);

create index connection_tokens_token_idx   on public.connection_tokens(token);
create index connection_tokens_patient_idx on public.connection_tokens(patient_id);
create index connection_tokens_expires_idx on public.connection_tokens(expires_at);

alter table public.connection_tokens enable row level security;
alter table public.connection_tokens force row level security;

create policy "connection_tokens_owner_all" on public.connection_tokens
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());

create policy "connection_tokens_validate_read" on public.connection_tokens
  for select using (auth.role() = 'authenticated');
