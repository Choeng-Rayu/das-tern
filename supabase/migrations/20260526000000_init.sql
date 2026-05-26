-- supabase/migrations/20260526000000_init.sql
-- Placeholder migration — establishes the extension baseline.
-- The full schema (profiles, prescriptions, dose_events, connections, …)
-- lands in 01-supabase-data-layer/tasks.md.

-- Enable UUID generation (required by all tables).
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable pg_cron for the nightly-cleanup Edge Function trigger.
-- (Requires Supabase Pro or self-hosted with pg_cron installed.)
-- CREATE EXTENSION IF NOT EXISTS "pg_cron";
