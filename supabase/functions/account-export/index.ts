// supabase/functions/account-export/index.ts
// Exports the authenticated user's data as a JSON archive and returns
// a signed Storage URL valid for 1 hour.
// Spec ref: 02-authentication §11.2

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
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "unauthorized" }, 401);

  const { data: { user }, error: userErr } = await supabaseAdmin.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );
  if (userErr || !user) return json({ error: "unauthorized" }, 401);

  const uid = user.id;

  // Collect all user-owned data
  const [profile, prescriptions, doseEvents, connections, notifications, auditLogs] =
    await Promise.all([
      supabaseAdmin.from("profiles").select("*").eq("id", uid).maybeSingle(),
      supabaseAdmin.from("prescriptions").select("*, medications(*)").eq("patient_id", uid),
      supabaseAdmin.from("dose_events").select("*").eq("patient_id", uid),
      supabaseAdmin.from("connections").select("*").or(`initiator_id.eq.${uid},recipient_id.eq.${uid}`),
      supabaseAdmin.from("notifications").select("*").eq("recipient_id", uid),
      supabaseAdmin.from("audit_logs").select("*").eq("actor_id", uid),
    ]);

  const archive = JSON.stringify({
    exported_at: new Date().toISOString(),
    user_id: uid,
    profile: profile.data,
    prescriptions: prescriptions.data ?? [],
    dose_events: doseEvents.data ?? [],
    connections: connections.data ?? [],
    notifications: notifications.data ?? [],
    audit_logs: auditLogs.data ?? [],
  });

  // Upload to Storage (private bucket, user-scoped path)
  const path = `${uid}/export_${Date.now()}.json`;
  const { error: uploadErr } = await supabaseAdmin.storage
    .from("profile-pictures") // reuse existing private bucket
    .upload(path, new TextEncoder().encode(archive), {
      contentType: "application/json",
      upsert: true,
    });
  if (uploadErr) return json({ error: "upload_failed", detail: uploadErr.message }, 500);

  const { data: signed, error: signErr } = await supabaseAdmin.storage
    .from("profile-pictures")
    .createSignedUrl(path, 3600);
  if (signErr) return json({ error: "sign_failed", detail: signErr.message }, 500);

  return json({ url: signed.signedUrl, expires_in: 3600 });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
