// supabase/functions/auth-telegram/index.ts
// Validates a Telegram OIDC PKCE code-exchange, creates/links a Supabase
// user, and returns a magiclink token for Flutter to consume.
// Spec ref: 02-authentication/design.md §7.2

import { serve } from "https://deno.land/std@0.217.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { jwtVerify, importJWK } from "https://esm.sh/jose@5.9.6";

const TELEGRAM_OIDC_ISSUER = "https://oauth.telegram.org";
const TELEGRAM_TOKEN_URL   = "https://oauth.telegram.org/token";
const TELEGRAM_JWKS_URL    = "https://oauth.telegram.org/.well-known/jwks.json";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const BOT_CLIENT_ID     = Deno.env.get("TELEGRAM_BOT_CLIENT_ID")!;
const BOT_CLIENT_SECRET = Deno.env.get("TELEGRAM_BOT_CLIENT_SECRET")!;

// ── Simple in-memory rate limiter: 10 req/min per IP (§12.5) ──────────
const _rateLimitWindow = 60_000; // 1 minute in ms
const _rateLimitMax = 10;
const _ipCounts = new Map<string, { count: number; resetAt: number }>();

function isRateLimited(ip: string): boolean {
  const now = Date.now();
  const entry = _ipCounts.get(ip);
  if (!entry || now > entry.resetAt) {
    _ipCounts.set(ip, { count: 1, resetAt: now + _rateLimitWindow });
    return false;
  }
  if (entry.count >= _rateLimitMax) return true;
  entry.count++;
  return false;
}

interface ReqBody {
  code: string;
  codeVerifier: string;
  redirectUri: string;
  role?: string;
}

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

  // Rate limit: 10 req/min per IP (§12.5)
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() ?? "unknown";
  if (isRateLimited(ip)) return json({ error: "rate_limited" }, 429);

  const body = await req.json() as ReqBody;
  if (!body.code || !body.codeVerifier || !body.redirectUri) {
    return json({ error: "missing_params" }, 400);
  }

  // Whitelist role values — ignore anything else.
  const role = body.role === "PATIENT" || body.role === "DOCTOR"
    ? body.role : null;

  // 1. Token exchange with Telegram
  const tokenResp = await fetch(TELEGRAM_TOKEN_URL, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      code: body.code,
      redirect_uri: body.redirectUri,
      code_verifier: body.codeVerifier,
      client_id: BOT_CLIENT_ID,
      client_secret: BOT_CLIENT_SECRET,
    }),
  });
  if (!tokenResp.ok) return json({ error: "token_exchange_failed" }, 401);
  const { id_token } = await tokenResp.json();

  // 2. Verify ID token against Telegram JWKS
  const jwks = await (await fetch(TELEGRAM_JWKS_URL)).json();
  let payload: Record<string, unknown>;
  try {
    const result = await jwtVerify(id_token, async (header) => {
      const jwk = jwks.keys.find((k: Record<string, unknown>) => k.kid === header.kid);
      if (!jwk) throw new Error("kid_not_found");
      return importJWK(jwk as Record<string, unknown>, header.alg!);
    }, { issuer: TELEGRAM_OIDC_ISSUER, audience: BOT_CLIENT_ID });
    payload = result.payload as Record<string, unknown>;
  } catch (e) {
    return json({ error: "invalid_id_token", detail: String(e) }, 401);
  }

  const tgUserId = String(payload.sub);

  // 3. Find or create Supabase user keyed on telegram_id
  const { data: existing } = await supabaseAdmin
    .from("profiles")
    .select("id, first_name")
    .eq("telegram_id", tgUserId)
    .maybeSingle();

  let userId: string;
  let isFreshProfile = false;

  if (existing) {
    userId = existing.id;
    isFreshProfile = existing.first_name == null;
  } else {
    const placeholderEmail = `tg_${tgUserId}@telegram.dastern.local`;
    const { data: created, error } = await supabaseAdmin.auth.admin.createUser({
      email: placeholderEmail,
      email_confirm: true,
      user_metadata: { telegram_id: tgUserId, role: role ?? "PATIENT" },
    });
    if (error) return json({ error: "user_create_failed", detail: error.message }, 500);
    userId = created.user.id;
    isFreshProfile = true;
  }

  // 4. Update profile with latest Telegram fields
  const profileUpdate: Record<string, unknown> = {
    telegram_id: tgUserId,
    telegram_username: payload.username ?? null,
    telegram_first_name: payload.first_name ?? null,
    telegram_last_name: payload.last_name ?? null,
    telegram_photo_url: payload.photo_url ?? null,
  };
  // Only set role on fresh profiles and only when explicitly provided.
  if (role && isFreshProfile) profileUpdate.role = role;
  await supabaseAdmin.from("profiles").update(profileUpdate).eq("id", userId);

  // 5. Generate a magiclink token for Flutter to consume
  const email = (payload.email as string | undefined)
    ?? `tg_${tgUserId}@telegram.dastern.local`;
  const { data: link, error: linkErr } = await supabaseAdmin.auth.admin
    .generateLink({ type: "magiclink", email });
  if (linkErr) {
    return json({ error: "session_generate_failed", detail: linkErr.message }, 500);
  }

  return json({
    user_id: userId,
    hashed_token: link.properties?.hashed_token,
    email,
  });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
