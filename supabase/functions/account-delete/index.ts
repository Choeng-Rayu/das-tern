// supabase/functions/account-delete/index.ts
// Deletes the authenticated user's account via the Supabase Admin API.
// All owned rows cascade-delete via FK ON DELETE CASCADE.
// Spec ref: 02-authentication §11.1

import { serve } from "https://deno.land/std@0.217.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }
  if (req.method !== "DELETE") return json({ error: "method_not_allowed" }, 405);

  // Verify the caller's JWT to get their user ID.
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "unauthorized" }, 401);

  const { data: { user }, error: userErr } = await supabaseAdmin.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );
  if (userErr || !user) return json({ error: "unauthorized" }, 401);

  const { error } = await supabaseAdmin.auth.admin.deleteUser(user.id);
  if (error) return json({ error: "delete_failed", detail: error.message }, 500);

  return json({ deleted: true });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
