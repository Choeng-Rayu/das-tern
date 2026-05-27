-- supabase/migrations/20260601000100_policy_helpers.sql
-- ADDENDUM-001: replaces is_connected_family_for with is_connected_peer_patient_for.
-- All functions use security definer + explicit search_path.

create or replace function public.is_connected_with(other_id uuid)
returns boolean language sql stable security definer
set search_path = public
as $$
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
  p_patient_id    uuid,
  require_allowed boolean default false
) returns boolean language sql stable security definer
set search_path = public
as $$
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
      and (not require_allowed or c.permission_level = 'ALLOWED')
  );
$$;

create or replace function public.is_connected_peer_patient_for(p_patient_id uuid)
returns boolean language sql stable security definer
set search_path = public
as $$
  -- ADDENDUM-001: mutual Patient↔Patient peer connection.
  select exists (
    select 1
    from public.connections c
    join public.profiles me    on me.id    = auth.uid()
    join public.profiles other on other.id = p_patient_id
    where c.status = 'ACCEPTED'
      and me.role    = 'PATIENT'
      and other.role = 'PATIENT'
      and c.permission_level <> 'NOT_ALLOWED'
      and (
        (c.initiator_id = auth.uid() and c.recipient_id = p_patient_id)
        or (c.recipient_id = auth.uid() and c.initiator_id = p_patient_id)
      )
  );
$$;
