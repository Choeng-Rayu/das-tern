# Skill: add-edge-function

Add a new Supabase Edge Function (Deno) to the Das Tern project.

## When to use
When server-side logic requires privileged credentials (payment verification,
OCR proxy, webhook ingest, OIDC token exchange). Never for plain CRUD —
use RLS-protected tables instead.

## Steps

1. **Scaffold**
   ```bash
   supabase functions new <function-name>
   # Creates supabase/functions/<function-name>/index.ts
   ```

2. **Implement** — use the shared CORS helper:
   ```typescript
   // supabase/functions/<function-name>/index.ts
   import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
   import { corsHeaders, handleCors } from '../_shared/cors.ts';

   serve(async (req) => {
     const corsResponse = handleCors(req);
     if (corsResponse) return corsResponse;

     // Read secrets from environment (never from request body)
     const secret = Deno.env.get('MY_SECRET')!;

     try {
       // ... logic ...
       return new Response(JSON.stringify({ ok: true }), {
         headers: { ...corsHeaders, 'Content-Type': 'application/json' },
       });
     } catch (err) {
       console.error(JSON.stringify({ error: String(err) }));
       return new Response(JSON.stringify({ error: 'internal' }), {
         status: 500,
         headers: { ...corsHeaders, 'Content-Type': 'application/json' },
       });
     }
   });
   ```

3. **Register secrets** (never commit values):
   ```bash
   supabase secrets set MY_SECRET=<value> --project-ref <ref>
   ```
   Document the key name (not value) in `docs/SECRETS.md`.

4. **Deploy**
   ```bash
   supabase functions deploy <function-name> --project-ref <ref>
   ```

5. **Document** — add a row to the Edge Function inventory table in
   `00-overview/design.md §8`.

## Constraints
- Secrets come from `Deno.env.get(...)` only — never from request bodies.
- Always emit structured JSON logs (`console.error(JSON.stringify(...))`).
- Return CORS headers on every response including errors.
- Keep functions stateless and idempotent.
