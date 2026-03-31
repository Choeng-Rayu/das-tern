# DasTern Subscription System Documentation

## Overview
DasTern implements a freemium subscription model with a 1-month Premium trial for new users. The system controls access to OCR scanning and family features based on subscription tiers.

## Subscription Tiers

### Freemium (Free)
- **Price**: Free forever
- **Features**:
  - ✅ Manual prescription input
  - ✅ Medication reminders
  - ✅ 5 GB storage
  - ❌ No OCR scanning
  - ❌ No family connections
- **Target Users**: Individual users who prefer manual entry

### Premium
- **Price Options**:
  - $0.50/month (monthly subscription)
  - $1.00/3 months (quarterly subscription - 33% savings)
- **Features**:
  - ✅ Unlimited OCR scanning
  - ✅ Up to 5 family member connections
  - ✅ 20 GB storage
  - ✅ All Freemium features
  - ✅ Priority support
- **Target Users**: Users who want OCR scanning and family coordination

### Free Trial
- **Duration**: 1 month (30 days)
- **Eligibility**: All new users (patient registrations and Google OAuth sign-ups)
- **Features**: Full Premium access during trial period
- **Expiration**: Automatic downgrade to Freemium when trial expires
- **Upgrade Path**: Users can manually subscribe to Premium at any time

---

## Backend Implementation

### 1. Subscription Service
**File**: `backend_nestjs/src/modules/subscriptions/subscriptions.service.ts`

#### Key Methods

##### `getTierLimits(tier: SubscriptionTier)`
Returns feature limits for each tier:

```typescript
FREEMIUM: {
  prescriptions: -1,      // Unlimited manual entries
  medicines: -1,          // Unlimited medicines
  familyConnections: 0,   // No family members
  storageGB: 5,           // 5 GB storage
  ocrEnabled: false       // No OCR access
}

PREMIUM: {
  prescriptions: -1,      // Unlimited prescriptions
  medicines: -1,          // Unlimited medicines
  familyConnections: 5,   // Up to 5 family members
  storageGB: 20,          // 20 GB storage
  ocrEnabled: true        // OCR enabled
}
```

##### `checkOcrPermission(userId: string)`
Checks if user has OCR access:
- Returns `{ ocrEnabled: boolean, tier: string }`
- Used by frontend before allowing OCR scanning

##### `findOne(userId: string)`
Retrieves subscription with automatic trial expiration checking:
- Checks if `expiresAt < now` and `tier === 'PREMIUM'`
- Auto-downgrades expired trials to FREEMIUM
- Returns updated subscription data

##### `updateTier(userId: string, newTier: SubscriptionTier)`
Updates user's subscription tier:
- Sets `expiresAt: null` when upgrading to clear trial status
- Updates storage quota based on new tier
- Prevents trial conflicts with paid subscriptions

##### `addFamilyMember(userId: string, email: string)`
Manages family member connections:
- Validates user is not FREEMIUM tier
- Enforces 5-member limit for PREMIUM
- Returns error if limits exceeded

##### `getFeatureComparison()`
Returns detailed tier comparison for UI display:
- Lists all features per tier
- Includes pricing options for Premium
- Used by upgrade plan screen

### 2. Subscription Controller
**File**: `backend_nestjs/src/modules/subscriptions/subscriptions.controller.ts`

#### Endpoints

```typescript
GET /subscriptions/me
// Returns current user's subscription with family members
// Response: { subscription, limits, familyMembers }

GET /subscriptions/limits
// Returns tier limits and current usage counts
// Response: { limits, usage }

GET /subscriptions/ocr/check
// Checks if user has OCR permission
// Response: { ocrEnabled: boolean, tier: string }

PATCH /subscriptions/tier
// Updates subscription tier (manual upgrade)
// Body: { tier: 'PREMIUM' | 'FREEMIUM' }
```

### 3. Authentication Service
**File**: `backend_nestjs/src/modules/auth/auth.service.ts`

#### Trial Subscription Creation

Both registration methods create Premium trial subscriptions:

```typescript
// Patient Registration
await this.db.subscription.create({
  data: {
    userId: newPatient.id,
    tier: 'PREMIUM',
    storageQuota: 21474836480n,  // 20 GB in bytes
    storageUsed: 0n,
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
  },
});

// Google OAuth Registration
// Same logic as patient registration
```

**Methods**:
- `registerPatient()` - Email/OTP registration
- `googleLoginMobile()` - Google OAuth sign-in
- `verifyOtp()` - Email verification completion

---

## Frontend Implementation

### 1. Subscription Provider
**File**: `das_tern_mcp/lib/providers/subscription_provider.dart`

#### State Management

```dart
class SubscriptionProvider extends ChangeNotifier {
  Map<String, dynamic>? _subscription;
  Map<String, dynamic>? _limits;
  
  // Getters
  String get currentTier;
  bool get isPremium;
  bool get hasOcrAccess;
  
  // Trial Information
  bool get isOnTrial;
  DateTime? get trialExpiresAt;
  int get trialDaysRemaining;
  
  // Methods
  Future<void> loadSubscription();
  Future<bool> createPayment(String planType);
}
```

#### Trial Status Getters

```dart
bool get isOnTrial {
  if (_subscription?['expiresAt'] == null) return false;
  final expiresAt = DateTime.tryParse(_subscription!['expiresAt']);
  if (expiresAt == null) return false;
  return DateTime.now().isBefore(expiresAt) && currentTier == 'PREMIUM';
}

int get trialDaysRemaining {
  if (!isOnTrial || trialExpiresAt == null) return 0;
  return trialExpiresAt!.difference(DateTime.now()).inDays;
}
```

### 2. Upgrade Plan Screen
**File**: `das_tern_mcp/lib/ui/screens/patient/screens/upgrade_plan_screen.dart`

#### Components

##### Current Plan Card
Shows user's current subscription tier with upgrade prompt for Freemium users.

##### Trial Banner
Displays when user is on active trial:
- Shows trial status with "🎉 Premium Trial Active"
- Displays days remaining
- Green gradient background
- Premium icon badge

```dart
_TrialBanner(
  daysRemaining: sub.trialDaysRemaining,
  expiresAt: sub.trialExpiresAt!,
  isDark: isDark,
)
```

##### Plan Cards
Shows available subscription plans:
- Premium plan with dual pricing options
- Feature highlights
- "Recommended" badge
- Upgrade button

##### Feature Comparison Table
Two-column comparison (Freemium vs. Premium):

| Feature | FREE | PREMIUM |
|---------|------|---------|
| Manual Input | ✓ | ✓ |
| OCR Scanning | ✗ | ✓ Unlimited |
| Reminders | ✓ | ✓ |
| Family Links | 0 | Up to 5 |
| Storage | 5 GB | 20 GB |
| Priority Support | ✗ | ✓ |

### 3. OCR Scan Tab
**File**: `das_tern_mcp/lib/ui/screens/patient/tab/patient_scan_tab.dart`

#### Feature Gating

```dart
Future<void> _scanImage() async {
  final subscription = Provider.of<SubscriptionProvider>(context, listen: false);
  
  if (!subscription.hasOcrAccess) {
    _showUpgradeDialog();
    return;
  }
  
  // Proceed with OCR scanning...
}
```

#### Upgrade Dialog
Shows when Freemium users attempt OCR scanning:
- **Title**: "Premium Feature" with premium icon
- **Benefits**:
  - ✓ Unlimited OCR scanning
  - ✓ Connect up to 5 family members
  - ✓ 20 GB storage
  - ✓ Priority support
- **Trial Banner**: "🎁 1-month free trial for new users!"
- **Actions**: "Cancel" or "Upgrade Now"

---

## Database Schema

### Subscription Model
**File**: `backend_nestjs/prisma/schema.prisma`

```prisma
model Subscription {
  id              String           @id @default(uuid())
  userId          String           @unique
  tier            SubscriptionTier @default(FREEMIUM)
  storageQuota    BigInt           @default(5368709120)
  storageUsed     BigInt           @default(0)
  expiresAt       DateTime?
  createdAt       DateTime         @default(now())
  updatedAt       DateTime         @updatedAt
  
  User            User             @relation(fields: [userId], references: [id], onDelete: Cascade)
}

enum SubscriptionTier {
  FREEMIUM
  PREMIUM
  FAMILY_PREMIUM  // Deprecated but kept for backward compatibility
}
```

**Key Fields**:
- `tier`: Current subscription level
- `storageQuota`: Bytes available (5GB for Freemium, 20GB for Premium)
- `storageUsed`: Current usage in bytes
- `expiresAt`: Trial expiration date (null for paid subscriptions)

---

## User Flows

### 1. New User Registration Flow

```
User Signs Up
    ↓
Email Verification
    ↓
Account Created with Premium Trial
    ↓
1-Month Premium Access
    ↓
Trial Expires After 30 Days
    ↓
Auto-Downgrade to Freemium
    ↓
User Can Upgrade to Premium Manually
```

### 2. OCR Scanning Flow (Freemium User)

```
User Taps "Scan Prescription"
    ↓
Check: subscription.hasOcrAccess
    ↓
If FALSE → Show Upgrade Dialog
    ↓
Dialog Shows Premium Benefits + Trial Offer
    ↓
User Taps "Upgrade Now"
    ↓
Navigate to Upgrade Plan Screen
    ↓
User Selects Premium Plan
    ↓
Navigate to Payment Method Screen
    ↓
Complete Bakong Payment
    ↓
Subscription Updated to PREMIUM
    ↓
OCR Access Granted
```

### 3. Trial Expiration Flow

```
User with Active Trial
    ↓
30 Days Pass
    ↓
expiresAt < Current Time
    ↓
User Opens App / Loads Subscription
    ↓
Backend: findOne() Checks expiresAt
    ↓
If Expired: updateTier(userId, 'FREEMIUM')
    ↓
Frontend: Receives FREEMIUM Tier
    ↓
Trial Banner Disappears
    ↓
OCR Feature Locked
    ↓
Upgrade Dialog Shows on OCR Attempt
```

### 4. Manual Upgrade Flow

```
User on Freemium (or Expired Trial)
    ↓
Navigate to Upgrade Plan Screen
    ↓
Select Premium Plan ($0.5/mo or $1/3mo)
    ↓
Tap "Upgrade Now"
    ↓
Choose Payment Method
    ↓
Generate Bakong QR Code
    ↓
Scan QR with Bakong App
    ↓
Complete Payment
    ↓
Backend: Bakong Webhook Confirms Payment
    ↓
Backend: updateTier(userId, 'PREMIUM')
    ↓
Backend: Set expiresAt = null (clear trial)
    ↓
Frontend: Subscription Reloaded
    ↓
Premium Features Unlocked
```

---

## Payment Integration

### Bakong Payment System
**Files**: 
- `backend_nestjs/src/modules/subscriptions/payment/bakong-payment.controller.ts`
- `backend_nestjs/src/modules/subscriptions/payment/bakong-payment.service.ts`

#### Payment Plans

```typescript
const BAKONG_PLANS = [
  {
    id: 'PREMIUM',
    name: 'Premium',
    tier: 'PREMIUM',
    amount: 0.5,
    currency: 'USD',
    duration: '1_MONTH',
    features: [
      'Unlimited OCR scanning',
      'Up to 5 family members',
      '20 GB storage',
      'All Freemium features',
      'Priority support',
    ],
    priceOptions: [
      { amount: 0.5, duration: '1_MONTH', label: '$0.5/month' },
      { amount: 1, duration: '3_MONTHS', label: '$1/3 months' },
    ],
  },
];
```

#### Payment Endpoints

```typescript
POST /subscriptions/bakong/payments
// Create new payment for plan
// Body: { planType: 'PREMIUM' }
// Returns: { payment: { qrCode, md5Hash, deepLink } }

GET /subscriptions/bakong/payments/:md5Hash
// Check payment status
// Returns: { status: 'PENDING' | 'PAID' | 'FAILED' | 'TIMEOUT' }

POST /subscriptions/bakong/webhook
// Bakong callback endpoint
// Validates payment signature
// Updates subscription tier on success
```

#### Payment Polling
Frontend polls payment status every 5 seconds for 15 minutes:
- **Interval**: 5 seconds
- **Max Attempts**: 180 (15 minutes total)
- **Statuses**: PENDING → PAID | FAILED | TIMEOUT

---

## Testing Guidelines

### Manual Testing Checklist

#### Registration & Trial
- [ ] New email registration creates Premium trial subscription
- [ ] Google OAuth registration creates Premium trial subscription
- [ ] Trial expiration is set to 30 days from registration
- [ ] Trial banner shows on upgrade screen with correct days remaining
- [ ] Premium features work during trial period

#### Trial Expiration
- [ ] Manually set `expiresAt` to past date in database
- [ ] Load subscription - should auto-downgrade to FREEMIUM
- [ ] Trial banner disappears after expiration
- [ ] OCR feature becomes locked after expiration

#### Feature Access Control
- [ ] Freemium users cannot access OCR scanning
- [ ] Upgrade dialog shows when Freemium user taps "Scan"
- [ ] Dialog displays all Premium benefits correctly
- [ ] Trial banner shows in upgrade dialog
- [ ] Premium users can access OCR scanning freely

#### Family Member Limits
- [ ] Freemium users cannot add family members
- [ ] Premium users can add up to 5 family members
- [ ] Error shown when attempting to add 6th member
- [ ] Family member count displayed correctly in limits

#### Manual Subscription
- [ ] User can upgrade from Freemium to Premium
- [ ] Payment QR code generates successfully
- [ ] Payment status polling works (every 5s)
- [ ] Subscription updates after payment confirmation
- [ ] `expiresAt` is null after manual upgrade
- [ ] Premium features unlock immediately

#### UI/UX
- [ ] Upgrade plan screen shows correct pricing
- [ ] Feature comparison table displays accurately
- [ ] Current plan card shows correct tier
- [ ] Trial banner has green gradient background
- [ ] Days remaining updates daily
- [ ] Premium badge shows on plan cards

### API Testing

```bash
# Check subscription
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/subscriptions/me

# Check OCR permission
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/subscriptions/ocr/check

# Check limits
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/subscriptions/limits

# Update tier (admin/testing)
curl -X PATCH \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"tier":"PREMIUM"}' \
  http://localhost:3000/api/subscriptions/tier
```

### Database Queries

```sql
-- Check user subscriptions
SELECT id, "userId", tier, "storageQuota", "expiresAt", "createdAt"
FROM "Subscription"
ORDER BY "createdAt" DESC;

-- Find active trials
SELECT s.id, u.email, s.tier, s."expiresAt",
       EXTRACT(DAY FROM (s."expiresAt" - NOW())) as days_remaining
FROM "Subscription" s
JOIN "User" u ON s."userId" = u.id
WHERE s."expiresAt" > NOW()
  AND s.tier = 'PREMIUM';

-- Find expired trials
SELECT s.id, u.email, s.tier, s."expiresAt"
FROM "Subscription" s
JOIN "User" u ON s."userId" = u.id
WHERE s."expiresAt" < NOW()
  AND s.tier = 'PREMIUM';

-- Manually set trial expiration for testing
UPDATE "Subscription"
SET "expiresAt" = NOW() - INTERVAL '1 day'
WHERE "userId" = '<user-id>';

-- Clear trial status (simulate manual upgrade)
UPDATE "Subscription"
SET "expiresAt" = NULL
WHERE "userId" = '<user-id>';
```

---

## Troubleshooting

### Trial Not Working

**Symptom**: New users don't get Premium trial

**Checks**:
1. Verify `auth.service.ts` creates subscription with `tier: 'PREMIUM'`
2. Check `expiresAt` is set to 30 days in future
3. Ensure `storageQuota` is 21474836480 (20GB)
4. Check database for subscription record

**Solution**: Review registration code in `registerPatient()` and `googleLoginMobile()`

### Trial Not Expiring

**Symptom**: Users stay on Premium after 30 days

**Checks**:
1. Verify `findOne()` checks `expiresAt < now`
2. Ensure `updateTier()` is called when expired
3. Check if subscription is being loaded on app start

**Solution**: Review auto-downgrade logic in `subscriptions.service.ts`

### OCR Still Accessible for Freemium

**Symptom**: Freemium users can use OCR scanning

**Checks**:
1. Verify `hasOcrAccess` getter checks tier correctly
2. Ensure `_scanImage()` checks subscription before proceeding
3. Check if subscription state is loaded

**Solution**: Review OCR gating in `patient_scan_tab.dart`

### Trial Banner Not Showing

**Symptom**: Trial banner doesn't appear for trial users

**Checks**:
1. Verify `isOnTrial` getter logic
2. Check if `expiresAt` is being returned from backend
3. Ensure subscription provider is loaded

**Solution**: Review `subscription_provider.dart` and upgrade screen implementation

### Payment Not Updating Subscription

**Symptom**: Paid subscription doesn't unlock features

**Checks**:
1. Verify Bakong webhook is being called
2. Check if payment signature validation passes
3. Ensure `updateTier()` is called in webhook handler
4. Verify `expiresAt` is set to null after payment

**Solution**: Check webhook logs and payment service implementation

---

## Future Enhancements

### Potential Features
1. **Annual Plans**: $10/year with 17% savings
2. **Family Premium**: Separate tier for larger families (6-10 members)
3. **Grace Period**: 7-day grace period after trial expiration
4. **Upgrade Reminders**: Email notifications 3 days before trial expires
5. **Usage Analytics**: Track feature usage by tier
6. **Referral Program**: Free month for referrals who subscribe
7. **Student Discount**: 50% off for verified students
8. **Auto-Renewal**: Automatic subscription renewal with saved payment methods
9. **Plan Switching**: Allow users to change between monthly/quarterly mid-subscription
10. **Family Sharing**: Share Premium benefits across family member accounts

### Subscription Metrics to Track
- Trial conversion rate (trial → paid Premium)
- Trial expiration churn rate
- Monthly recurring revenue (MRR)
- Average revenue per user (ARPU)
- Feature usage by tier (OCR scans, family connections)
- Payment success rate
- Upgrade funnel drop-off points

---

## Summary

The DasTern subscription system successfully implements:

✅ **Two-tier model**: Freemium and Premium
✅ **Free trial**: 1-month Premium for all new users
✅ **Auto-downgrade**: Seamless trial expiration handling
✅ **Feature gating**: OCR and family features restricted to Premium
✅ **Dual pricing**: Monthly and quarterly subscription options
✅ **Bakong integration**: Local payment method for Cambodian market
✅ **Clear upgrade path**: Multiple touchpoints for conversion
✅ **Trial visibility**: Banner and status indicators throughout UI

This monetization strategy provides:
- **User value**: Free manual entry with optional premium features
- **Revenue generation**: Affordable recurring subscriptions
- **Market fit**: Pricing tailored for Cambodian market ($0.50-1.00/month)
- **Conversion funnel**: Trial experience drives premium subscriptions
- **Scalability**: Backend architecture supports future tier additions
