-- supabase/migrations/20260601000500_pg_cron.sql
-- Requires pg_cron extension enabled on the Supabase project.
-- Enable via: Dashboard → Database → Extensions → pg_cron

-- Expire missed doses every 5 minutes
select cron.schedule(
  'expire-missed-doses',
  '*/5 * * * *',
  $$ select public.expire_missed_doses(); $$
);

-- Clean up expired/used connection tokens daily at 02:00 UTC
select cron.schedule(
  'cleanup-connection-tokens',
  '0 2 * * *',
  $$
    delete from public.connection_tokens
    where expires_at < now() - interval '1 day'
       or used_at is not null;
  $$
);
