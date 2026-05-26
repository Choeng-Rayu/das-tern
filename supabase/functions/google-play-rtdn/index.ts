// supabase/functions/google-play-rtdn/index.ts
// Receives Google Play Real-time Developer Notifications (Pub/Sub push).
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
