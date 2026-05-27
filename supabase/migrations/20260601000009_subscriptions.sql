-- supabase/migrations/20260601000009_subscriptions.sql

create table public.subscriptions (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null unique references public.profiles(id) on delete cascade,
  tier                 subscription_tier not null default 'FREEMIUM',
  storage_quota        bigint not null default 5368709120, -- 5 GB
  storage_used         bigint not null default 0,
  expires_at           timestamptz,
  has_used_trial       boolean not null default false,
  play_purchase_token  text,
  play_product_id      text,
  play_subscription_id text,
  play_state           text,
  play_acknowledged    boolean not null default false,
  play_renewal_at      timestamptz,
  play_last_event      jsonb,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index subscriptions_user_idx       on public.subscriptions(user_id);
create index subscriptions_tier_idx       on public.subscriptions(tier);
create index subscriptions_play_token_idx on public.subscriptions(play_purchase_token);

create trigger subscriptions_set_updated_at
before update on public.subscriptions
for each row execute function public.tg_set_updated_at();

alter table public.subscriptions enable row level security;
alter table public.subscriptions force row level security;

create policy "subscriptions_self_select" on public.subscriptions
  for select using (user_id = auth.uid());
create policy "subscriptions_no_client_write" on public.subscriptions
  for all using (false) with check (false);

-- family_members
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
    or exists (select 1 from public.subscriptions s where s.id = subscription_id and s.user_id = auth.uid())
  );
create policy "family_members_no_client_write" on public.family_members
  for all using (false) with check (false);
