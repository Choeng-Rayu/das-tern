-- supabase/migrations/20260601000200_functions.sql

-- consume_connection_token
create or replace function public.consume_connection_token(p_token text)
returns uuid language plpgsql security definer
set search_path = public
as $$
declare
  v_row public.connection_tokens;
  v_connection_id uuid;
begin
  select * into v_row from public.connection_tokens where token = p_token for update;
  if not found                    then raise exception 'token_not_found'           using errcode = 'P0002'; end if;
  if v_row.expires_at < now()     then raise exception 'token_expired'; end if;
  if v_row.used_at is not null    then raise exception 'token_already_used'; end if;
  if v_row.patient_id = auth.uid() then raise exception 'self_connection_not_allowed'; end if;

  update public.connection_tokens set used_at = now(), used_by_id = auth.uid() where id = v_row.id;

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

-- accept_connection
create or replace function public.accept_connection(
  p_connection_id uuid,
  p_permission    permission_level default null
) returns public.connections language plpgsql security definer
set search_path = public
as $$
declare v_row public.connections;
begin
  select * into v_row from public.connections where id = p_connection_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_row.recipient_id <> auth.uid() and v_row.initiator_id <> auth.uid() then raise exception 'forbidden'; end if;
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

-- mark_dose
create or replace function public.mark_dose(
  p_dose_id    uuid,
  p_status     dose_event_status,
  p_taken_at   timestamptz default now(),
  p_skip_reason text default null,
  p_was_offline boolean default false
) returns public.dose_events language plpgsql security definer
set search_path = public
as $$
declare v_row public.dose_events;
begin
  select * into v_row from public.dose_events where id = p_dose_id for update;
  if not found then raise exception 'not_found'; end if;
  if v_row.patient_id <> auth.uid() then raise exception 'forbidden'; end if;
  if v_row.status not in ('DUE','MISSED') then raise exception 'invalid_state'; end if;

  update public.dose_events
     set status      = p_status,
         taken_at    = case when p_status in ('TAKEN_ON_TIME','TAKEN_LATE') then p_taken_at else taken_at end,
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
            else                      'DOSE_MISSED'::audit_action_type
          end,
          'dose_events', v_row.id,
          jsonb_build_object('status', p_status, 'was_offline', p_was_offline));
  return v_row;
end;
$$;

-- create_audit_log (only via this function, never direct INSERT)
create or replace function public.create_audit_log(
  p_action        audit_action_type,
  p_resource_type text,
  p_resource_id   uuid,
  p_details       jsonb default '{}'::jsonb
) returns void language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.audit_logs (actor_id, actor_role, action_type, resource_type, resource_id, details)
  values (auth.uid(),
          (select role from public.profiles where id = auth.uid()),
          p_action, p_resource_type, p_resource_id, p_details);
end;
$$;

-- get_adherence
create or replace function public.get_adherence(p_patient_id uuid, p_period text default '7d')
returns numeric language sql stable security definer
set search_path = public
as $$
  with bounds as (
    select case p_period
      when 'today' then date_trunc('day', now())
      when '7d'    then now() - interval '7 days'
      when '30d'   then now() - interval '30 days'
      when '90d'   then now() - interval '90 days'
    end as start_at
  ),
  doses as (
    select de.status from public.dose_events de
    join public.medications m on m.id = de.medication_id
    where de.patient_id = p_patient_id
      and de.scheduled_time >= (select start_at from bounds)
      and de.scheduled_time <= now()
      and m.is_prn = false
  )
  select case when count(*) = 0 then 100
              else round(100.0 * count(*) filter (where status in ('TAKEN_ON_TIME','TAKEN_LATE')) / count(*), 2)
         end
  from doses;
$$;

-- expire_missed_doses (called by pg_cron every 5 minutes)
create or replace function public.expire_missed_doses()
returns integer language plpgsql security definer
set search_path = public
as $$
declare v_count integer;
begin
  with affected as (
    update public.dose_events de
       set status = 'MISSED'
      from public.profiles p
     where de.status = 'DUE'
       and de.patient_id = p.id
       and de.scheduled_time + (p.grace_period_minutes || ' minutes')::interval < now()
     returning de.id
  )
  select count(*) into v_count from affected;
  return v_count;
end;
$$;
