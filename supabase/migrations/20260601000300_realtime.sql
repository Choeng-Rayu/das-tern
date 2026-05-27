-- supabase/migrations/20260601000300_realtime.sql
-- Enable Realtime for tables the Flutter app subscribes to.
-- RLS policies above are respected automatically by Supabase Realtime.

alter publication supabase_realtime add table
  public.dose_events,
  public.notifications,
  public.prescriptions,
  public.connections;
