// supabase/functions/auth-telegram/index.ts
// Validates a Telegram OIDC PKCE code-exchange, creates/links a Supabase
// user, and returns a Supabase session.
// Spec ref: 00-overview/design.md §7 "Telegram OIDC"

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // TODO: implement in 02-authentication spec
  return new Response(
    JSON.stringify({ error: 'not_implemented' }),
    { status: 501, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  );
});
