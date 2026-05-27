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

create index audit_actor_idx    on public.audit_logs(actor_id);
create index audit_resource_idx on public.audit_logs(resource_id);
create index audit_created_idx  on public.audit_logs(created_at);
create index audit_action_idx   on public.audit_logs(action_type);

alter table public.audit_logs enable row level security;
alter table public.audit_logs force row level security;

create policy "audit_actor_select" on public.audit_logs
  for select using (actor_id = auth.uid());

create policy "audit_resource_owner_select" on public.audit_logs
  for select using (
    exists (select 1 from public.prescriptions p where p.id = resource_id and p.patient_id = auth.uid())
    or exists (select 1 from public.dose_events d where d.id = resource_id and d.patient_id = auth.uid())
  );

create policy "audit_no_update"        on public.audit_logs for update using (false);
create policy "audit_no_delete"        on public.audit_logs for delete using (false);
create policy "audit_no_direct_insert" on public.audit_logs for insert with check (false);
