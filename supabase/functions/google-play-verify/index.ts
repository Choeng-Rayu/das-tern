// supabase/functions/google-play-verify/index.ts
// Verifies a Google Play purchase token and writes to the subscriptions table.
// Spec ref: 08-google-play-billing

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // TODO: implement in 08-google-play-billing spec
  return new Response(
    JSON.stringify({ error: 'not_implemented' }),
    { status: 501, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  );
});
