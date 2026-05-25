# Design: Google Play Billing & Subscription Management

## 1. Sequence diagram: purchase flow

```
User      Flutter App        Play Billing       Verifier Edge Fn       Google Android      Supabase Postgres
                                                                       Publisher API
 │            │                    │                    │                    │                    │
 │ tap Subscribe                   │                    │                    │                    │
 │──────────►│                    │                    │                    │                    │
 │            │ buyNonConsumable() │                    │                    │                    │
 │            │───────────────────►│                    │                    │                    │
 │            │                    │ Purchase UI         │                    │                    │
 │            │                    │   ↓                 │                    │                    │
 │            │ purchaseStream    │                    │                    │                    │
 │            │ {status:purchased}│                    │                    │                    │
 │            │◄───────────────────│                    │                    │                    │
 │            │                                                                                    │
 │            │ POST /functions/v1/google-play-verify                                              │
 │            │   Authorization: Bearer <user_jwt>                                                 │
 │            │   {purchase_token, product_id, package_name}                                       │
 │            │──────────────────────────────────────────►│                                       │
 │            │                                          │ get user from JWT                      │
 │            │                                          │ get service_account access_token       │
 │            │                                          │   (cached 50min)                       │
 │            │                                          │ GET subscriptionsv2/tokens/<token>     │
 │            │                                          │──────────────────────────►│             │
 │            │                                          │                            │            │
 │            │                                          │ subscriptionState=ACTIVE   │            │
 │            │                                          │◄──────────────────────────│             │
 │            │                                          │ acknowledge                │            │
 │            │                                          │──────────────────────────►│             │
 │            │                                          │ upsert subscriptions row   │            │
 │            │                                          │──────────────────────────────────────►│
 │            │ {ok:true,tier,expires_at}                │                                        │
 │            │◄──────────────────────────────────────────│                                        │
 │            │ completePurchase()                                                                 │
 │            │───────────────────►                                                                │
 │            │ purchaseStream {pendingCompletePurchase:false}                                     │
 │            │◄───────────────────                                                                │
 │            │ Realtime row update → UI shows "Premium active"                                    │
 │◄────────────                                                                                    │
```

## 2. Module structure

```
lib/features/billing/
├── data/
│   ├── billing_service.dart          # in_app_purchase wrapper
│   ├── products.dart                 # product id constants
│   ├── verifier_client.dart          # invokes Verifier Edge Fn
│   └── subscription_repository.dart  # reads subscriptions + family_members
├── domain/
│   ├── play_state.dart
│   ├── tier.dart
│   ├── feature_flag.dart
│   └── usecases/
│       ├── load_products.dart
│       ├── start_purchase.dart
│       ├── change_subscription.dart
│       ├── restore_purchases.dart
│       ├── add_family_member.dart
│       └── remove_family_member.dart
└── presentation/
    ├── pages/
    │   ├── subscription_page.dart
    │   ├── upgrade_prompt_page.dart
    │   ├── family_members_page.dart
    │   └── billing_error_page.dart
    └── widgets/
        ├── tier_card.dart
        ├── feature_comparison_table.dart
        ├── play_state_banner.dart
        └── manage_in_play_button.dart
```

## 3. Products

```dart
// lib/features/billing/data/products.dart
class Products {
  static const String premiumMonthly = 'dastern_premium_monthly';
  static const String familyPremiumMonthly = 'dastern_family_premium_monthly';
  static const Set<String> all = {premiumMonthly, familyPremiumMonthly};
}

extension ProductTier on String {
  Tier get tier {
    switch (this) {
      case Products.premiumMonthly:        return Tier.premium;
      case Products.familyPremiumMonthly:  return Tier.familyPremium;
      default:                             return Tier.freemium;
    }
  }
}
```

## 4. BillingService

```dart
class BillingService {
  BillingService(this._iap, this._verifier, this._sub);
  final InAppPurchase _iap;
  final VerifierClient _verifier;
  final SubscriptionRepository _sub;

  StreamSubscription<List<PurchaseDetails>>? _stream;

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    _stream = _iap.purchaseStream.listen(_onPurchaseUpdate, onDone: () => _stream?.cancel());
    // restore on cold start (post sign-in)
    await _iap.restorePurchases();
  }

  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(Products.all);
    if (response.notFoundIDs.isNotEmpty) {
      log('Products not found: ${response.notFoundIDs}');
    }
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> changeTo(ProductDetails newProduct, PurchaseDetails old) async {
    final param = GooglePlayPurchaseParam(
      productDetails: newProduct,
      changeSubscriptionParam: ChangeSubscriptionParam(
        oldPurchaseDetails: old,
        replacementMode: ReplacementMode.withTimeProration,
      ),
    );
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      switch (p.status) {
        case PurchaseStatus.pending:
          // show pending UI in state provider
          _emit(BillingState.pending(p));
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndComplete(p);
          break;
        case PurchaseStatus.error:
          _emit(BillingState.failed(p.error?.message ?? 'unknown'));
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.canceled:
          _emit(const BillingState.cancelled());
          break;
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails p) async {
    final google = p as GooglePlayPurchaseDetails;
    try {
      final result = await _verifier.verify(
        purchaseToken: google.billingClientPurchase.purchaseToken,
        productId: google.productID,
        packageName: google.billingClientPurchase.packageName,
      );
      _emit(BillingState.success(result));
    } catch (e) {
      _emit(BillingState.failed(e.toString()));
    } finally {
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }
}
```

## 5. Verifier Edge Function

```ts
// supabase/functions/google-play-verify/index.ts
import { serve } from "https://deno.land/std@0.217.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { create as jwtCreate, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const SERVICE_ACCOUNT = JSON.parse(Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON")!);
const PACKAGE_NAME    = Deno.env.get("ANDROID_PACKAGE_NAME")!;
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

let cachedToken: { value: string; expiresAt: number } | null = null;

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  // Identify caller
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return json({ error: "unauthorized" }, 401);
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  const body = await req.json() as {
    purchase_token: string; product_id: string; package_name: string;
  };
  if (body.package_name !== PACKAGE_NAME) {
    return json({ error: "package_mismatch" }, 400);
  }

  // 1. Get service-account access token
  const accessToken = await getAccessToken();

  // 2. Fetch subscription state from Google
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${body.purchase_token}`;
  const gResp = await fetch(url, { headers: { authorization: `Bearer ${accessToken}` } });
  if (!gResp.ok) {
    return json({ error: "google_fetch_failed", status: gResp.status, detail: await gResp.text() }, 502);
  }
  const sub = await gResp.json();

  const state = sub.subscriptionState;
  if (state !== "SUBSCRIPTION_STATE_ACTIVE" && state !== "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
    return json({ error: "not_active", state }, 409);
  }

  const lineItem = (sub.lineItems ?? [])[0];
  const expiresAt = lineItem?.expiryTime;
  const tier = body.product_id === "dastern_family_premium_monthly" ? "FAMILY_PREMIUM" : "PREMIUM";
  const playState = state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" ? "IN_GRACE" : "ACTIVE";

  // 3. Acknowledge if not already
  if (sub.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING") {
    await fetch(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/purchases/subscriptions/${body.product_id}/tokens/${body.purchase_token}:acknowledge`, {
      method: "POST",
      headers: { authorization: `Bearer ${accessToken}`, "content-type": "application/json" },
      body: JSON.stringify({ developerPayload: user.id }),
    });
  }

  // 4. Upsert subscriptions row using service role
  const storageQuota = tier === "FREEMIUM" ? 5368709120 : 21474836480; // 5GB or 20GB
  await supabase.from("subscriptions").upsert({
    user_id: user.id,
    tier,
    storage_quota: storageQuota,
    expires_at: expiresAt,
    play_purchase_token: body.purchase_token,
    play_product_id: body.product_id,
    play_subscription_id: sub.subscriptionId ?? null,
    play_state: playState,
    play_acknowledged: true,
    play_renewal_at: expiresAt,
    play_last_event: sub,
  }, { onConflict: "user_id" });

  // 5. Audit log
  await supabase.rpc("create_audit_log", {
    p_action: "SUBSCRIPTION_CHANGE",
    p_resource_type: "subscriptions",
    p_resource_id: user.id,
    p_details: { tier, product_id: body.product_id, source: "purchase_verify" },
  });

  return json({ ok: true, tier, expires_at: expiresAt });
});

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) return cachedToken.value;

  const claims = {
    iss: SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const privateKey = await importPkcs8(SERVICE_ACCOUNT.private_key);
  const jwt = await jwtCreate({ alg: "RS256", typ: "JWT" }, claims, privateKey);

  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const j = await r.json();
  cachedToken = { value: j.access_token, expiresAt: now + (j.expires_in - 60) };
  return j.access_token;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status, headers: { "content-type": "application/json" },
  });
}
```

## 6. RTDN Edge Function

```ts
// supabase/functions/google-play-rtdn/index.ts
import { serve } from "https://deno.land/std@0.217.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { jwtVerify } from "https://esm.sh/jose@5.9.6";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const PACKAGE_NAME = Deno.env.get("ANDROID_PACKAGE_NAME")!;
const RTDN_AUDIENCE = Deno.env.get("RTDN_AUDIENCE")!; // your service-account email
const SERVICE_ACCOUNT = JSON.parse(Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON")!);

serve(async (req) => {
  // 1. Verify Pub/Sub OIDC token
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return new Response("unauthorized", { status: 401 });
  const token = auth.slice(7);
  const { payload } = await jwtVerify(token, await getGooglePublicKeys(), {
    audience: RTDN_AUDIENCE,
  });
  if (payload.email_verified !== true) return new Response("unauthorized", { status: 401 });

  // 2. Parse Pub/Sub envelope
  const env = await req.json();
  const data = JSON.parse(atob(env.message.data));
  const sub = data.subscriptionNotification;
  if (!sub) return new Response("ignored", { status: 200 });

  const purchaseToken = sub.purchaseToken;
  const subscriptionId = sub.subscriptionId;

  // 3. Fetch fresh state from Google
  const accessToken = await getAccessToken();
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${purchaseToken}`;
  const r = await fetch(url, { headers: { authorization: `Bearer ${accessToken}` } });
  const live = await r.json();

  const state = live.subscriptionState;
  const playState = mapPlayState(state);
  const tier = subscriptionId === "dastern_family_premium_monthly" ? "FAMILY_PREMIUM" :
               subscriptionId === "dastern_premium_monthly" ? "PREMIUM" : "FREEMIUM";

  // 4. Update subscription row
  const updates: Record<string, unknown> = {
    play_state: playState,
    play_last_event: { rtdn: sub, live },
  };
  if (state === "SUBSCRIPTION_STATE_ACTIVE" || state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
    updates.tier = tier;
    updates.expires_at = (live.lineItems?.[0]?.expiryTime) ?? null;
  } else if (state === "SUBSCRIPTION_STATE_EXPIRED" || state === "SUBSCRIPTION_STATE_CANCELED") {
    updates.tier = "FREEMIUM";
    updates.storage_quota = 5368709120;
  }

  await supabase.from("subscriptions")
    .update(updates)
    .eq("play_purchase_token", purchaseToken);

  return new Response("ok", { status: 200 });
});

function mapPlayState(s: string): string {
  switch (s) {
    case "SUBSCRIPTION_STATE_ACTIVE":          return "ACTIVE";
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD": return "IN_GRACE";
    case "SUBSCRIPTION_STATE_ON_HOLD":         return "ON_HOLD";
    case "SUBSCRIPTION_STATE_PAUSED":          return "PAUSED";
    case "SUBSCRIPTION_STATE_CANCELED":        return "CANCELED";
    case "SUBSCRIPTION_STATE_EXPIRED":         return "EXPIRED";
    case "SUBSCRIPTION_STATE_PENDING":         return "PENDING";
    default:                                   return "UNKNOWN";
  }
}
```

## 7. Riverpod state

```dart
@riverpod
Stream<SubscriptionRow?> currentSubscription(Ref ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return Supabase.instance.client
    .from('subscriptions')
    .stream(primaryKey: ['id'])
    .eq('user_id', user.id)
    .map((rows) => rows.isEmpty ? null : SubscriptionRow.fromJson(rows.first));
}

@riverpod
Tier currentTier(Ref ref) {
  final sub = ref.watch(currentSubscriptionProvider).valueOrNull;
  if (sub == null) return Tier.freemium;
  if (!_isActiveState(sub.playState)) return Tier.freemium;
  return sub.tier;
}

bool _isActiveState(String? s) =>
  s == 'ACTIVE' || s == 'IN_GRACE';
```

## 8. Family Premium member management

```dart
class AddFamilyMemberUseCase {
  Future<void> call(String memberUserId) async {
    final me = Supabase.instance.client.auth.currentUser!.id;
    final sub = await _supabase.from('subscriptions')
        .select('id, tier').eq('user_id', me).single();
    if (sub['tier'] != 'FAMILY_PREMIUM') {
      throw const BillingFailure.notFamilyPlan();
    }
    final count = await _supabase.from('family_members')
        .select('id').eq('subscription_id', sub['id']).count();
    if (count.count >= 2) throw const BillingFailure.familyLimitReached();
    // service-role required to insert into family_members; call edge function:
    await _supabase.functions.invoke('family-add-member',
        body: {'subscription_id': sub['id'], 'member_id': memberUserId});
  }
}
```

```sql
-- Trigger to enforce 2-member cap (3 total with owner)
create or replace function public.check_family_limit()
returns trigger language plpgsql as $$
declare v_count integer;
begin
  select count(*) into v_count from public.family_members where subscription_id = new.subscription_id;
  if v_count >= 2 then raise exception 'family_limit_reached'; end if;
  return new;
end;
$$;
create trigger family_members_limit
before insert on public.family_members
for each row execute function public.check_family_limit();
```

## 9. Feature flag layer

```dart
class FeatureFlags {
  FeatureFlags(this._tier);
  final Tier _tier;

  bool get canCreateMultiplePrescriptions => _tier != Tier.freemium;
  bool get canAddMoreThanOneCaregiver     => _tier != Tier.freemium;
  bool get canUseCloudOcr                 => true; // both tiers, but quotas differ
  bool get hasIncreasedStorage            => _tier != Tier.freemium;
  int  get caregiverLimit => switch (_tier) {
    Tier.freemium       => 1,
    Tier.premium        => 5,
    Tier.familyPremium  => 10,
  };
  int  get cloudOcrDailyLimit => switch (_tier) {
    Tier.freemium       => 30,
    Tier.premium        => 200,
    Tier.familyPremium  => 200,
  };
}

@riverpod
FeatureFlags features(Ref ref) => FeatureFlags(ref.watch(currentTierProvider));
```

## 10. Configuration

| Env var / secret | Where | Notes |
|---|---|---|
| `ANDROID_PACKAGE_NAME` | Edge | e.g. `com.dastern.app` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Edge | Service account with `androidpublisher` scope; granted access to the app in Play Console |
| `RTDN_AUDIENCE` | Edge | OIDC audience configured on the Pub/Sub push subscription |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge | For RLS-bypassed writes |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Both Edge and Flutter |

## 11. Testing

- **Edge Function tests (Deno):** mock Google API responses, assert correct upsert; assert acknowledge called only when pending; assert RTDN parsing for each notification type.
- **Flutter integration tests:** Use Play Billing Library's test product IDs (`android.test.purchased`, `android.test.canceled`) on internal test track to validate the full client→Edge→DB→UI loop.
- **End-to-end test plan:** Internal track release → tester subscribes → app shows premium → cancel in Play Store → RTDN updates state → app reverts to freemium.
- **Race condition tests:** Verify is idempotent (same purchase token verified twice → same state). RTDN can arrive before or after client verify.

## 12. Failure handling

- Verifier returns 5xx → client shows "Verification failed, please try again" and does NOT call `completePurchase()`. The next launch's `restorePurchases` will retry.
- RTDN delivery failure → Pub/Sub auto-retries with exponential backoff up to 7 days.
- Pub/Sub message duplication → Verifier and RTDN are both idempotent (upsert by user_id and play_purchase_token).
- Refund/chargeback → RTDN handles via `SUBSCRIPTION_VOIDED` → tier reverts to FREEMIUM.

## 13. Migration from Bakong

The v1 Bakong service is decommissioned. Existing Bakong subscribers (none in v2 launch) would be migrated by:
1. Identify active Bakong subscriptions in v1 DB.
2. Send a one-time email with instructions to subscribe via Google Play.
3. Honor remaining time as a manual `subscriptions.expires_at` extension.

For v2 MVP this section is theoretical since Bakong was never publicly launched.
