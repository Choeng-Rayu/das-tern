# Skill: add-supabase-migration

Add a new Postgres migration to the Das Tern Supabase project.

## When to use
When a spec requires a new table, column, index, or RLS policy.

## Steps

1. **Create the migration file**
   ```bash
   # From repo root
   supabase migration new <description>
   # Creates supabase/migrations/YYYYMMDDHHMMSS_<description>.sql
   ```

2. **Write the SQL** — follow this template:
   ```sql
   -- supabase/migrations/<timestamp>_<description>.sql

   -- Table
   CREATE TABLE public.<table_name> (
     id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
     created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
     updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
   );

   -- RLS (default-deny, then grant)
   ALTER TABLE public.<table_name> ENABLE ROW LEVEL SECURITY;

   CREATE POLICY "<table_name>_owner_select"
     ON public.<table_name> FOR SELECT
     USING (auth.uid() = user_id);

   CREATE POLICY "<table_name>_owner_insert"
     ON public.<table_name> FOR INSERT
     WITH CHECK (auth.uid() = user_id);

   CREATE POLICY "<table_name>_owner_update"
     ON public.<table_name> FOR UPDATE
     USING (auth.uid() = user_id);

   -- updated_at trigger
   CREATE TRIGGER set_updated_at
     BEFORE UPDATE ON public.<table_name>
     FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);
   ```

3. **Add a matching Drift table** in
   `dastern/lib/core/storage/drift/tables/<table_name>.dart`.

4. **Test locally**
   ```bash
   supabase db reset   # applies all migrations + seed.sql
   ```

5. **RLS checklist**
   - [ ] `ENABLE ROW LEVEL SECURITY` on every new table.
   - [ ] Default-deny: no policy = no access.
   - [ ] No `service_role` key in Flutter client.
   - [ ] Policy tested with `pgtap` (add to `supabase/tests/`).

## Constraints
- Migration filenames must be `YYYYMMDDHHMMSS_<description>.sql`.
- Never edit an already-applied migration — create a new one.
- Never store secrets in SQL files.
