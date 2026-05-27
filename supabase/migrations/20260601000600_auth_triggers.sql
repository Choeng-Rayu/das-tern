-- supabase/migrations/20260601000600_auth_triggers.sql
-- Role immutability after bootstrap + updated handle_new_auth_user.

-- Update handle_new_auth_user to include phone and role from metadata.
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
declare
  v_role user_role := coalesce(
    (new.raw_user_meta_data->>'role')::user_role,
    'PATIENT'
  );
begin
  insert into public.profiles (id, email, phone_number, role, account_status)
  values (new.id, new.email, new.phone, v_role, 'ACTIVE')
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Role immutability: locked after first_name is set (bootstrap complete).
create or replace function public.tg_profiles_role_immutable()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if new.role is distinct from old.role
     and old.first_name is not null
     and coalesce(
       current_setting('request.jwt.claims', true)::json->>'role',
       ''
     ) <> 'service_role'
  then
    raise exception 'role_immutable_after_bootstrap';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_role_immutable on public.profiles;
create trigger profiles_role_immutable
before update of role on public.profiles
for each row execute function public.tg_profiles_role_immutable();
