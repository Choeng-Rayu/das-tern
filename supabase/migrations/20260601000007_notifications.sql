-- supabase/migrations/20260601000007_notifications.sql

create table public.notifications (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  type         notification_type not null,
  title        varchar(255) not null,
  message      text not null,
  data         jsonb,
  is_read      boolean not null default false,
  read_at      timestamptz,
  created_at   timestamptz not null default now()
);

create index notifications_recipient_idx      on public.notifications(recipient_id);
create index notifications_recipient_read_idx on public.notifications(recipient_id, is_read);
create index notifications_created_idx        on public.notifications(created_at);

alter table public.notifications enable row level security;
alter table public.notifications force row level security;

create policy "notifications_recipient_select" on public.notifications
  for select using (recipient_id = auth.uid());

create policy "notifications_recipient_update" on public.notifications
  for update using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

-- Inserts only via service_role or SQL function create_notification
create policy "notifications_no_client_insert" on public.notifications
  for insert with check (false);

create policy "notifications_no_client_delete" on public.notifications
  for delete using (false);
