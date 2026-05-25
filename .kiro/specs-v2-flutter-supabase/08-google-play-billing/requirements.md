# Requirements: Google Play Billing & Subscription Management

## Introduction

This spec defines how Das Tern v2 sells subscriptions through Google Play Billing using the Flutter `in_app_purchase` plugin, verifies purchases server-side via a Supabase Edge Function calling Google's Android Publisher API, and keeps subscription state synchronized via Real-time Developer Notifications (RTDN).

The v1 Bakong KHQR payment service is decommissioned (kept in repo as historical reference). Bakong can be reintroduced as a parallel local-payment side channel later, but it is out of MVP scope.

## Glossary

- **Play_Billing** — Google Play Billing system, accessed in Flutter via the `in_app_purchase` plugin and on Android natively via Play Billing Library 6+.
- **Purchase_Token** — A Google-issued opaque token returned with each purchase that the server uses to verify and acknowledge.
- **Acknowledgement** — Required Play Billing step within 3 days of purchase (otherwise it is auto-refunded).
- **RTDN** — Real-time Developer Notifications. Google publishes subscription state events to a Pub/Sub topic that pushes to a Supabase Edge Function webhook.
- **Verifier_Edge_Function** — `supabase/functions/google-play-verify/` — invoked by the client immediately after a purchase to verify, acknowledge, and persist subscription state.
- **RTDN_Edge_Function** — `supabase/functions/google-play-rtdn/` — receives Google Pub/Sub push notifications for subscription lifecycle events.
- **Tier** — `FREEMIUM`, `PREMIUM`, `FAMILY_PREMIUM` (existing schema).
- **Family_Member_Slot** — A user added to a `FAMILY_PREMIUM` subscription's `family_members` table, granting them PREMIUM features.

## Requirements

### Requirement 1: Product catalog and Play Console setup

**User Story:** As a product owner, I want subscriptions configured in Play Console, so that users can purchase them in-app.

#### Acceptance Criteria

1. THE Play_Billing SHALL host two subscription products in Play Console with the following IDs:
   - `dastern_premium_monthly` — $0.50 / month
   - `dastern_family_premium_monthly` — $1.00 / month
2. EACH product SHALL have at least one base plan (`monthly`) and may have offer plans (e.g., 7-day free trial for first-time buyers).
3. THE Play_Billing SHALL be configured for auto-renewing subscriptions.
4. THE app SHALL declare these product IDs as constants in `lib/features/billing/data/products.dart`.
5. THE app SHALL ship to the Play Store internal test track first; production release gated on staging verification.

### Requirement 2: Subscription store screen

**User Story:** As a user, I want a clear screen showing my current plan and upgrade options, so that I can choose what to buy.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Manage subscription" screen showing: current tier, expiry date, renewal status, and feature comparison table.
2. THE Flutter_App SHALL load product details using `InAppPurchase.queryProductDetails(productIds)` and display localized titles/prices from the store.
3. THE Flutter_App SHALL surface a "Subscribe" button per available product when the current tier is FREEMIUM, or "Upgrade/Manage" when an active subscription exists.
4. THE Flutter_App SHALL display a "Manage in Play Store" deep link (`https://play.google.com/store/account/subscriptions?package=...&sku=...`) for users to cancel.
5. THE Flutter_App SHALL show storage quota usage progress vs the quota for the current tier.

### Requirement 3: Purchase flow

**User Story:** As a user, I want to subscribe with one tap, so that the upgrade is fast and trustworthy.

#### Acceptance Criteria

1. THE Flutter_App SHALL connect to the underlying store via `InAppPurchase.instance.isAvailable()` on app startup; if unavailable, billing UI SHALL display "Billing is not available on this device".
2. THE Flutter_App SHALL subscribe to the `purchaseStream` early in app lifecycle (before any UI that depends on it is shown).
3. WHEN the user taps "Subscribe", THE Flutter_App SHALL call `buyNonConsumable(PurchaseParam(productDetails: ...))` (subscriptions use buyNonConsumable in the plugin's API).
4. WHEN the purchase completes successfully, THE Flutter_App SHALL receive a `PurchaseDetails` event with status `purchased`.
5. THE Flutter_App SHALL call the Verifier_Edge_Function with the purchase data BEFORE calling `completePurchase()`.
6. THE Flutter_App SHALL call `completePurchase()` only after the verifier returns success.
7. WHEN a purchase fails or is cancelled, THE Flutter_App SHALL display a localized error and remain on the store screen.

### Requirement 4: Server-side verification

**User Story:** As a security engineer, I want every purchase verified server-side, so that we cannot be cheated by a tampered client.

#### Acceptance Criteria

1. THE Verifier_Edge_Function SHALL accept `{purchase_token, product_id, package_name}` plus the user's Supabase JWT in the Authorization header.
2. THE Verifier_Edge_Function SHALL identify the calling user via `getUser()` from the JWT.
3. THE Verifier_Edge_Function SHALL fetch a Google service-account access token (cached for 50 minutes) using stored credentials.
4. THE Verifier_Edge_Function SHALL call `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{package_name}/purchases/subscriptionsv2/tokens/{purchase_token}` to retrieve the verified subscription state.
5. THE Verifier_Edge_Function SHALL reject the request if `subscriptionState` is not `SUBSCRIPTION_STATE_ACTIVE` or `SUBSCRIPTION_STATE_IN_GRACE_PERIOD`.
6. THE Verifier_Edge_Function SHALL upsert a row in `public.subscriptions` mapping `product_id` to `tier` and persisting `play_purchase_token`, `play_subscription_id`, `play_state`, `play_acknowledged`, `play_renewal_at`, `expires_at`.
7. THE Verifier_Edge_Function SHALL acknowledge the purchase if not yet acknowledged: `POST .../tokens/{purchase_token}:acknowledge`.
8. THE Verifier_Edge_Function SHALL return `{ok: true, tier, expires_at}` to the client.
9. ALL writes to `subscriptions` SHALL use the service-role client (RLS allows only service_role writes).

### Requirement 5: Real-Time Developer Notifications (RTDN)

**User Story:** As a backend, I want to receive subscription state changes (renewals, cancellations, refunds, grace) without polling, so that user state stays current.

#### Acceptance Criteria

1. THE Play Console SHALL be configured with a Pub/Sub topic for RTDN, e.g., `projects/<gcp-project>/topics/dastern-rtdn`.
2. A Pub/Sub push subscription SHALL deliver to `https://<supabase>.functions.supabase.co/google-play-rtdn` with an authentication header.
3. THE RTDN_Edge_Function SHALL validate the bearer token (Pub/Sub OIDC) against the configured `RTDN_AUTH_AUDIENCE`.
4. THE RTDN_Edge_Function SHALL parse the message body, base64-decode the `data` field to get the notification payload (`subscriptionNotification` or `oneTimeProductNotification`).
5. THE RTDN_Edge_Function SHALL fetch the latest subscription state from Google Android Publisher API to confirm the change (since RTDN payload is just a hint).
6. THE RTDN_Edge_Function SHALL update the matching `subscriptions` row by `play_purchase_token` lookup with the new state, expiry, and a `play_last_event` JSON snapshot.
7. THE RTDN_Edge_Function SHALL respond 200 within 3 seconds (Pub/Sub retries on non-2xx).
8. THE RTDN_Edge_Function SHALL emit a notification of `SUBSCRIPTION_CHANGE` audit log entry.

### Requirement 6: Subscription state machine

**User Story:** As the app, I need to map Google subscription states to local tier and gating logic, so that features lock/unlock correctly.

#### Acceptance Criteria

1. THE Flutter_App SHALL define an enum `PlayState` mirroring Google's: `ACTIVE`, `IN_GRACE`, `ON_HOLD`, `PAUSED`, `CANCELED`, `EXPIRED`, `RECOVERED`, `RESTARTED`, `PENDING`.
2. WHEN `play_state IN ('ACTIVE', 'IN_GRACE')`, THE Flutter_App SHALL apply premium tier features.
3. WHEN `play_state IN ('ON_HOLD', 'PAUSED', 'CANCELED', 'EXPIRED')`, THE Flutter_App SHALL revert tier to FREEMIUM and grandfather existing data (don't delete prescriptions, but block creation beyond limits).
4. THE Flutter_App SHALL display state-specific banners: in-grace ("Your payment is being retried"), on-hold ("Update your payment method"), paused ("Subscription paused; resume in Play Store").

### Requirement 7: Restoration on reinstall / new device

**User Story:** As a user reinstalling the app, I want my subscription restored, so that I keep my premium features.

#### Acceptance Criteria

1. THE Flutter_App SHALL call `InAppPurchase.instance.restorePurchases()` once per fresh sign-in.
2. EACH restored purchase SHALL be re-verified by the Verifier_Edge_Function (idempotent).
3. THE Flutter_App SHALL also fetch `subscriptions` row from Supabase as the source of truth (RTDN may have updated state since the device was offline).

### Requirement 8: Family Premium member management

**User Story:** As a Family Premium subscriber, I want to add up to 2 additional members (3 total including me), so that they get premium features too.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Add family member" screen on the subscription page when tier is FAMILY_PREMIUM.
2. THE Flutter_App SHALL allow inviting via email or via the family connection token flow (linking a family member already on the app).
3. WHEN added, THE Flutter_App SHALL `INSERT` into `family_members(subscription_id, member_id)` (only the subscription owner can do this).
4. THE Postgres trigger on `family_members INSERT` SHALL enforce `count <= 2` (3 total including owner) per subscription.
5. THE Flutter_App SHALL show added members and allow removal; removed members revert to FREEMIUM unless they have their own subscription.
6. THE feature-gating layer SHALL grant PREMIUM features to any user that is the owner of a non-FREEMIUM subscription OR a member of a FAMILY_PREMIUM subscription.

### Requirement 9: Tier change (upgrade / downgrade)

**User Story:** As a user, I want to upgrade from Premium to Family Premium without buying a fresh subscription, so that I'm credited for unused time.

#### Acceptance Criteria

1. THE Flutter_App SHALL use `GooglePlayPurchaseParam` with `ChangeSubscriptionParam(oldPurchaseDetails: ..., replacementMode: ReplacementMode.withTimeProration)`.
2. THE Verifier_Edge_Function SHALL handle the new `purchase_token` and supersede the old subscription row in the database.
3. THE Flutter_App SHALL display the proration result returned by Google (immediate or deferred).
4. THE Flutter_App SHALL prevent simultaneous active subscriptions (handled automatically by Google when ChangeSubscriptionParam is used).

### Requirement 10: Free trial

**User Story:** As a first-time user, I want to try Premium for 7 days free, so that I can decide before paying.

#### Acceptance Criteria

1. THE Play Console SHALL offer a 7-day free trial as an offer plan on `dastern_premium_monthly`.
2. THE Flutter_App SHALL display "7-day free trial" on the upgrade button when the user is eligible (Google enforces eligibility server-side per Play account).
3. WHEN the trial converts, THE RTDN_Edge_Function SHALL update `play_state = 'ACTIVE'` and `subscriptions.has_used_trial = true`.
4. WHEN the trial is cancelled before conversion, THE state moves to `CANCELED` then `EXPIRED`.

### Requirement 11: Quota and feature gating

**User Story:** As a developer, I want feature flags driven by tier, so that gating is centralized.

#### Acceptance Criteria

1. THE Flutter_App SHALL expose a Riverpod provider `currentTierProvider` that reads from Supabase `subscriptions` and Drift cache.
2. THE Flutter_App SHALL provide `Feature.canCreatePrescription`, `Feature.canAddCaregiver`, `Feature.canUploadImage`, `Feature.canUseCloudOcr` predicates.
3. WHEN a feature is gated and tapped, THE Flutter_App SHALL show the upgrade prompt with deep-link to the subscription screen.
4. THE Postgres-side enforcement (per `03-prescription-medication`) SHALL be the source of truth; the client check is a UX optimization only.

### Requirement 12: Refunds and chargebacks

**User Story:** As a user, I want my access revoked promptly when I issue a refund, so that the app never lets me consume premium content I didn't pay for.

#### Acceptance Criteria

1. THE RTDN_Edge_Function SHALL handle the `SUBSCRIPTION_VOIDED` notification by setting `play_state = 'EXPIRED'` and tier = FREEMIUM.
2. THE Flutter_App SHALL detect the change via Realtime and update UI within 30 seconds.
3. THE Flutter_App SHALL retain user-created prescriptions but block new ones beyond freemium limits.

### Requirement 13: Observability

**User Story:** As an operations engineer, I want metrics on billing, so that we catch issues early.

#### Acceptance Criteria

1. THE Verifier_Edge_Function SHALL log structured events: verification result, latency, product, user_id (hashed), tier transition.
2. THE RTDN_Edge_Function SHALL log every notification type and outcome.
3. THE Flutter_App SHALL log billing-related Sentry breadcrumbs (without secrets).
4. THE team SHALL track conversion rate (FREEMIUM → trial → paid), churn (cancellations / month), and verification failure rate via Supabase logs analytics.

### Requirement 14: Security

**User Story:** As a security engineer, I want billing-related secrets handled correctly, so that they cannot leak.

#### Acceptance Criteria

1. THE Google service-account JSON SHALL be stored only as a Supabase Edge Function secret (`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`).
2. THE service-account SHALL have only the minimum scope: `https://www.googleapis.com/auth/androidpublisher`.
3. THE RTDN_Edge_Function SHALL validate the Pub/Sub bearer token's audience and verified email.
4. THE Flutter_App SHALL NEVER ship the service-account JSON, RTDN auth secret, or Play Console credentials.
5. THE Verifier_Edge_Function SHALL reject `purchase_token`s that don't match the package name.
6. THE pgsql code SHALL prevent client writes to `subscriptions` (only service_role writes), already enforced by RLS.

### Requirement 15: iOS App Store (deferred)

**User Story:** As an iOS user, I want App Store subscriptions in a future release, so that the app is on iOS too.

#### Acceptance Criteria

1. THE same `in_app_purchase` plugin SHALL handle iOS App Store purchases without code changes in the UI layer.
2. A separate Edge Function `apple-iap-verify` SHALL verify App Store receipts using App Store Server API.
3. App Store Server Notifications V2 SHALL be configured to push to `apple-iap-notifications` Edge Function (mirror of RTDN).
4. iOS support is OUT of MVP scope but the architecture SHALL not preclude it.
