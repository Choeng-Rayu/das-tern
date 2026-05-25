# Tasks: Google Play Billing & Subscription Management

## Phase 1 — Play Console + GCP setup (1 day)

- [ ] **1.1** Register app in Play Console under the configured `package_name` (e.g., `com.dastern.app`).
- [ ] **1.2** Create subscription products: `dastern_premium_monthly` ($0.50/mo), `dastern_family_premium_monthly` ($1.00/mo).
- [ ] **1.3** Create base plans (`monthly`) and offer plan (`7-day-free-trial` on premium_monthly).
- [ ] **1.4** Create GCP service account with `androidpublisher` scope; download JSON key.
- [ ] **1.5** Grant the service account "Financial data, payments only" access in Play Console > API access.
- [ ] **1.6** Create Pub/Sub topic `dastern-rtdn` in GCP project; configure Play Console > Monetization > Real-time developer notifications to publish to it.
- [ ] **1.7** Create Pub/Sub push subscription with audience set to the Edge Function URL and OIDC token attached.

## Phase 2 — Edge Function: google-play-verify (2 days)

- [ ] **2.1** Scaffold `supabase/functions/google-play-verify/index.ts` per design § 5.
- [ ] **2.2** Set Edge secrets: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `ANDROID_PACKAGE_NAME`, `SUPABASE_SERVICE_ROLE_KEY`.
- [ ] **2.3** Implement service-account JWT signing + token caching.
- [ ] **2.4** Implement `subscriptionsv2.tokens.get` call.
- [ ] **2.5** Implement `acknowledge` call for unacknowledged purchases.
- [ ] **2.6** Upsert into `subscriptions` table.
- [ ] **2.7** Audit log call.
- [ ] **2.8** Deno tests with mocked Google API.
- [ ] **2.9** Deploy: `supabase functions deploy google-play-verify`.

## Phase 3 — Edge Function: google-play-rtdn (1.5 days)

- [ ] **3.1** Scaffold `supabase/functions/google-play-rtdn/index.ts` per design § 6.
- [ ] **3.2** Pub/Sub OIDC token verification.
- [ ] **3.3** Notification parsing for all subscriptionNotification types.
- [ ] **3.4** Re-fetch subscription state from Google before applying.
- [ ] **3.5** Update subscriptions row by `play_purchase_token`.
- [ ] **3.6** Idempotency tests.
- [ ] **3.7** Deploy and configure Pub/Sub push subscription endpoint.

## Phase 4 — Flutter billing module (2 days)

- [ ] **4.1** Add deps: `in_app_purchase`, `in_app_purchase_android`.
- [ ] **4.2** `lib/features/billing/data/products.dart` — product IDs.
- [ ] **4.3** `BillingService.initialize()` in app shell — connects to store, listens to purchaseStream, restores purchases on sign-in.
- [ ] **4.4** `loadProducts()` to populate UI.
- [ ] **4.5** `buy(product)` calling `buyNonConsumable`.
- [ ] **4.6** `_verifyAndComplete` flow per design § 4.
- [ ] **4.7** `changeTo(newProduct, oldPurchase)` for upgrade/downgrade.
- [ ] **4.8** Riverpod providers: `currentSubscriptionProvider`, `currentTierProvider`, `featuresProvider`.

## Phase 5 — Subscription page (1 day)

- [ ] **5.1** `SubscriptionPage` showing current tier, expiry, renewal status, feature comparison.
- [ ] **5.2** "Subscribe" / "Upgrade to Family" / "Manage in Play Store" buttons.
- [ ] **5.3** State banners: in-grace, on-hold, paused, cancelled, expired.
- [ ] **5.4** Storage quota progress widget.

## Phase 6 — Family Premium UI (1 day)

- [ ] **6.1** `FamilyMembersPage` with add/remove members.
- [ ] **6.2** Add via existing family connection or via member email lookup.
- [ ] **6.3** Edge Function `family-add-member` (uses service role to bypass RLS on `family_members`).
- [ ] **6.4** SQL trigger `check_family_limit` enforcing 2-member cap.
- [ ] **6.5** Removal flow with confirmation; removed members revert to FREEMIUM.

## Phase 7 — Feature gating + upgrade prompts (0.5 day)

- [ ] **7.1** `FeatureFlags` class per design § 9.
- [ ] **7.2** `UpgradePromptPage` shown when a gated action is attempted.
- [ ] **7.3** Wire all feature checks (prescription create, caregiver add, OCR cloud) through the flag.

## Phase 8 — Restoration flow (0.5 day)

- [ ] **8.1** `restorePurchases()` called after successful sign-in.
- [ ] **8.2** `Subscription` row read from Supabase as source of truth alongside restored Play purchases.
- [ ] **8.3** Reconcile mismatches (Play has active sub but DB doesn't → re-verify).

## Phase 9 — Tests (1.5 days)

- [ ] **9.1** Edge Function tests: verify, acknowledge, RTDN handling for each notification type (1 = recovered, 2 = renewed, 3 = canceled, 4 = purchased, 5 = on hold, 6 = grace, 7 = restarted, 8 = price change, 9 = deferred, 10 = paused, 11 = pause schedule changed, 12 = revoked, 13 = expired).
- [ ] **9.2** Flutter unit: BillingService state transitions.
- [ ] **9.3** Flutter widget: SubscriptionPage rendering for each Tier × PlayState combination.
- [ ] **9.4** Integration test on Play internal track:
  - Subscribe with test card → premium active.
  - Cancel in Play → grace → expired.
  - Family add 2 members → 3rd fails.
  - Upgrade premium → family premium with proration.
- [ ] **9.5** Refund test: Play Console refund → RTDN VOIDED → tier reverts.

## Phase 10 — Observability (0.5 day)

- [ ] **10.1** Structured logs in both Edge Functions.
- [ ] **10.2** Sentry breadcrumbs on Flutter side.
- [ ] **10.3** Dashboard query in Supabase logs explorer for verification failures and tier transitions.

## Phase 11 — Release prep

- [ ] **11.1** Privacy policy updated to mention Google Play subscriptions and data flow.
- [ ] **11.2** Terms of service updated.
- [ ] **11.3** Play Console "Data safety" section reflects what is and isn't collected (e.g., no payment data sent to our backend, only purchase tokens).
- [ ] **11.4** App listing copy emphasizes free tier, mentions $0.50/mo Premium, $1.00/mo Family Premium.

## Phase 12 — Sign-off

- [ ] **12.1** Demo: subscribe with internal-test account → verifier acknowledges → subscription row updates → premium UI active.
- [ ] **12.2** Demo: cancel in Play Store → RTDN flips state → app reverts within 30s.
- [ ] **12.3** Demo: family premium adds 2 members → all three see premium features.
- [ ] **12.4** Demo: re-install app on a fresh device → restorePurchases brings back premium.
- [ ] **12.5** Security review: confirm no service account JSON or RTDN secret is reachable from the Flutter app.
