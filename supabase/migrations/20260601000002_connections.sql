-- supabase/migrations/20260601000002_connections.sql

create table public.connections (
  id                uuid primary key default gen_random_uuid(),
  initiator_id      uuid not null references public.profiles(id) on delete cascade,
  recipient_id      uuid not null references public.profiles(id) on delete cascade,
  status            connection_status not null default 'PENDING',
  permission_level  permission_level  not null default 'ALLOWED',
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
create index connections_status_idx    on public.connections(status);

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
  for update using  (initiator_id = auth.uid() or recipient_id = auth.uid())
             with check (initiator_id = auth.uid() or recipient_id = auth.uid());

create policy "connections_self_delete" on public.connections
  for delete using (initiator_id = auth.uid() or recipient_id = auth.uid());
