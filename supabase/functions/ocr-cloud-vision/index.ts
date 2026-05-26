// supabase/functions/ocr-cloud-vision/index.ts
// Proxies to Google Cloud Vision for low-confidence OCR fallback.
// Spec ref: 07-ocr-prescription-scanning

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // TODO: implement in 07-ocr-prescription-scanning spec
  return new Response(
    JSON.stringify({ error: 'not_implemented' }),
    { status: 501, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  );
});
