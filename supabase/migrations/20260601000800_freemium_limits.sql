-- supabase/migrations/20260601000800_freemium_limits.sql
-- Blocks FREEMIUM users from creating more than 1 active prescription.
-- Spec ref: 03-prescription-medication design §8.

create or replace function public.check_freemium_limits()
returns trigger language plpgsql security definer
set search_path = public
as $$
declare
  v_tier subscription_tier;
  v_active_count integer;
begin
  -- Only check on INSERT of a non-INACTIVE prescription
  if new.status = 'INACTIVE' then
    return new;
  end if;

  select tier into v_tier
  from public.subscriptions
  where user_id = new.patient_id;

  -- No subscription row = treat as FREEMIUM
  if v_tier is null or v_tier = 'FREEMIUM' then
    select count(*) into v_active_count
    from public.prescriptions
    where patient_id = new.patient_id
      and status in ('DRAFT', 'ACTIVE', 'PAUSED')
      and id <> new.id;

    if v_active_count >= 1 then
      raise exception 'freemium_limit_prescriptions'
        using hint = 'Upgrade to Premium to create more prescriptions.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists prescriptions_freemium_check on public.prescriptions;
create trigger prescriptions_freemium_check
before insert on public.prescriptions
for each row execute function public.check_freemium_limits();
