# Design Document: Bakong Payment Integration Backend Service

## Overview

The Bakong Payment Integration Backend Service is a standalone Next.js application that handles all payment operations for Das-tern subscriptions through Cambodia's national payment system (Bakong). The service runs independently on a separate VPS and communicates with the main Das-tern backend via secure REST APIs.

### Key Design Principles

1. **Separation of Concerns**: Payment processing is completely isolated from the main application
2. **Security First**: All payment data is encrypted, authenticated, and validated
3. **Reliability**: Automatic retry mechanisms and comprehensive error handling
4. **Auditability**: Complete transaction history and audit trails
5. **Scalability**: Stateless design with Redis for caching and session management

### Technology Stack

- **Framework**: Next.js 11+ (App Router)
- **Language**: TypeScript
- **ORM**: Prisma
- **Database**: PostgreSQL 17
- **Cache**: Redis
- **Authentication**: API Key-based (inter-service)
- **Deployment**: Standalone VPS (separate from main backend)

## Architecture

### System Context

```
┌─────────────────┐         ┌──────────────────────┐         ┌─────────────────┐
│                 │         │                      │         │                 │
│  Main Backend   │◄───────►│  Bakong Payment      │◄───────►│  Bakong API     │
│  (Das-tern)     │  REST   │  Integration Service │  HTTPS  │  (NBC)          │
│                 │         │                      │         │                 │
└─────────────────┘         └──────────────────────┘         └─────────────────┘
        │                            │
        │                            │
        ▼                            ▼
┌─────────────────┐         ┌──────────────────────┐
│                 │         │                      │
│  PostgreSQL     │         │  PostgreSQL          │
│  (Main DB)      │         │  (Payment DB)        │
│                 │         │                      │
└─────────────────┘         └──────────────────────┘
                                     │
                                     ▼
                            ┌──────────────────────┐
                            │                      │
                            │  Redis               │
                            │  (Cache/Sessions)    │
                            │                      │
                            └──────────────────────┘
```

### Component Architecture

```
bakong-payment-integration/
├── app/
│   └── api/
│       ├── payments/
│       │   ├── create/route.ts            # Create payment & generate QR
│       │   ├── status/[md5]/route.ts      # Check payment status by MD5
│       │   ├── monitor/route.ts           # Start payment monitoring
│       │   ├── bulk-check/route.ts        # Bulk payment status check
│       │   └── history/route.ts           # Get payment history
│       ├── subscriptions/
│       │   ├── status/[userId]/route.ts   # Get subscription status
│       │   ├── upgrade/route.ts           # Handle plan upgrades
│       │   └── downgrade/route.ts         # Handle plan downgrades
│       └── health/route.ts                # Health check endpoint
├── lib/
│   ├── bakong/
│   │   ├── khqr.ts                        # KHQR SDK implementation
│   │   ├── client.ts                      # Bakong API client
│   │   └── monitor.ts                     # Auto payment monitor
│   ├── services/
│   │   ├── payment.service.ts             # Payment business logic
│   │   ├── subscription.service.ts        # Subscription management
│   │   └── notification.service.ts        # Webhook notifications to main backend
│   ├── middleware/
│   │   ├── auth.ts                        # API key authentication
│   │   └── rate-limit.ts                  # Rate limiting
│   ├── utils/
│   │   ├── encryption.ts                  # Data encryption utilities
│   │   ├── logger.ts                      # Structured logging (Winston)
│   │   └── retry.ts                       # Retry logic utilities
│   └── prisma.ts                          # Prisma client singleton
├── prisma/
│   ├── schema.prisma                      # Database schema
│   └── migrations/                        # Database migrations
├── types/
│   ├── bakong.ts                          # Bakong API types
│   ├── payment.ts                         # Payment types
│   └── subscription.ts                    # Subscription types
├── public/
│   └── qr-codes/                          # Generated QR code images
└── .env                                   # Environment variables
```

## Components and Interfaces

### Bakong SDK Integration

This service integrates with the Bakong payment system using the KHQR (Khmer QR) specification. The implementation is based on the `@bakong_js` SDK pattern, which provides:

- **EMV-compliant QR code generation**: Creates standardized KHQR codes
- **MD5-based payment tracking**: Uses MD5 hash of QR string for payment identification
- **Real-time payment monitoring**: Polls Bakong API for payment status updates
- **Deep link generation**: Creates Bakong mobile app deep links for seamless payment
- **Bulk payment checking**: Supports checking up to 50 transactions simultaneously

**Important Notes**:
- Bakong API requires Cambodia IP address for access
- Developer token authentication is required for all API calls
- QR codes can be static (reusable) or dynamic (single-use)
- Payment status is checked via MD5 hash, not traditional payment references
- The system uses polling (not webhooks) for payment status updates

### 1. Bakong API Client

**Purpose**: Interface with Bakong's payment API for QR code generation and payment verification using the Bakong KHQR specification.

**Key Methods**:
```typescript
interface BakongClient {
  createQR(params: KHQRParams): string
  generateMD5(qrCode: string): string
  checkPayment(md5Hash: string): Promise<PaymentStatus>
  generateQRImage(qrCode: string, options?: ImageOptions): Promise<Buffer>
  generateDeeplink(qrCode: string, options?: DeeplinkOptions): Promise<string>
}

interface KHQRParams {
  bankAccount: string        // Merchant ID
  merchantName: string       // Merchant display name
  merchantCity: string       // Merchant city
  amount: number            // Payment amount
  currency: string          // USD or KHR
  storeLabel?: string       // Store identifier
  phoneNumber: string       // Merchant phone (without +)
  billNumber: string        // Unique bill/invoice number
  terminalLabel?: string    // Terminal identifier
  isStatic?: boolean        // Static vs dynamic QR
}

interface PaymentStatus {
  status: 'PENDING' | 'PAID' | 'FAILED' | 'EXPIRED'
  transactionId?: string
  md5Hash: string
  amount: number
  currency: string
  paidAt?: Date
  bakongData?: {
    fromAccountId: string
    toAccountId: string
    hash: string
    description: string
  }
}

interface ImageOptions {
  format: 'png' | 'svg' | 'buffer'
  size?: number
  margin?: number
}

interface DeeplinkOptions {
  callback?: string         // Success callback URL
  appIconUrl?: string      // App icon URL
  appName?: string         // App name for display
}
```

**Implementation Notes**:
- Uses Bakong KHQR SDK (based on @bakong_js implementation)
- QR codes follow EMV® QR code payment specification
- MD5 hash used for payment tracking (generated from QR string)
- API endpoint: `https://api-bakong.nbc.gov.kh/v1`
- Requires Cambodia IP address for API access
- Developer token authentication required
- Implements exponential backoff for retries
- Caches merchant configuration in Redis
- Validates all responses against expected schema

**Bakong API Error Codes**:
- 400: Bad request - Invalid input parameters
- 401: Unauthorized - Invalid or expired developer token
- 403: Forbidden - IP address not whitelisted (must be Cambodia IP)
- 404: Not found - Invalid API endpoint
- 429: Rate limited - Too many requests
- 500: Internal server error - Bakong server issue
- 504: Gateway timeout - Bakong server busy

### 2. Payment Service

**Purpose**: Core business logic for payment processing and transaction management.

**Key Methods**:
```typescript
interface PaymentService {
  initiatePayment(params: PaymentInitiationParams): Promise<PaymentTransaction>
  monitorPayment(transactionId: string, options?: MonitorOptions): Promise<PaymentTransaction>
  checkPaymentStatus(md5Hash: string): Promise<PaymentTransaction>
  handlePaymentTimeout(transactionId: string): Promise<void>
  bulkCheckPayments(md5Hashes: string[]): Promise<PaymentTransaction[]>
}

interface PaymentInitiationParams {
  userId: string
  planType: 'PREMIUM' | 'FAMILY_PREMIUM'
  amount: number
  currency: 'USD' | 'KHR'
  billNumber: string        // Unique invoice number
  isUpgrade?: boolean
  isRenewal?: boolean
  callback?: string         // Success callback URL
  appIconUrl?: string
  appName?: string
}

interface MonitorOptions {
  timeout?: number          // Total monitoring timeout (default: 300000ms = 5 min)
  interval?: number         // Check interval (default: 5000ms = 5 sec)
  maxAttempts?: number      // Max check attempts (default: 60)
  priority?: 'low' | 'normal' | 'high'
}

interface PaymentTransaction {
  id: string                // UUID v4
  userId: string
  billNumber: string        // Unique bill/invoice number
  md5Hash: string          // MD5 hash of QR code for tracking
  amount: number
  currency: string
  status: PaymentStatus
  qrCode?: string          // KHQR string
  qrImagePath?: string     // Path to QR image file
  deepLink?: string        // Bakong app deep link
  bakongData?: {           // Data from Bakong API
    fromAccountId: string
    toAccountId: string
    hash: string
    description: string
  }
  createdAt: Date
  updatedAt: Date
  completedAt?: Date
  paidAt?: Date
}

enum PaymentStatus {
  PENDING = 'PENDING',
  PAID = 'PAID',
  FAILED = 'FAILED',
  TIMEOUT = 'TIMEOUT',
  EXPIRED = 'EXPIRED',
  CANCELLED = 'CANCELLED'
}
```

**Business Rules**:
- Bill numbers must be unique per merchant
- MD5 hash generated from QR code string for payment tracking
- Payments timeout after 15 minutes if not completed
- Duplicate payment confirmations are logged but not processed (idempotency via MD5 hash)
- All status changes are recorded with timestamps
- Payment monitoring uses configurable intervals (default: check every 5 seconds)
- High-priority payments (upgrades) checked more frequently
- Automatic cleanup of expired/completed transactions after 30 days

### 3. Subscription Service

**Purpose**: Manage subscription lifecycles, plan changes, and billing cycles.

**Key Methods**:
```typescript
interface SubscriptionService {
  createSubscription(params: CreateSubscriptionParams): Promise<Subscription>
  renewSubscription(userId: string): Promise<Subscription>
  upgradeSubscription(params: UpgradeParams): Promise<Subscription>
  downgradeSubscription(params: DowngradeParams): Promise<Subscription>
  cancelSubscription(userId: string): Promise<Subscription>
  getSubscriptionStatus(userId: string): Promise<Subscription | null>
}

interface Subscription {
  id: string
  userId: string
  planType: 'PREMIUM' | 'FAMILY_PREMIUM'
  status: SubscriptionStatus
  startDate: Date
  nextBillingDate: Date
  cancelledAt?: Date
  createdAt: Date
  updatedAt: Date
}

enum SubscriptionStatus {
  ACTIVE = 'active',
  EXPIRED = 'expired',
  CANCELLED = 'cancelled',
  PENDING = 'pending'
}

interface UpgradeParams {
  userId: string
  newPlanType: 'FAMILY_PREMIUM'
  currentSubscription: Subscription
}

interface DowngradeParams {
  userId: string
  newPlanType: 'PREMIUM'
  currentSubscription: Subscription
}
```

**Business Rules**:
- Billing cycles are 30 days from start date
- Upgrades are immediate with prorated payment
- Downgrades take effect at next billing cycle
- Prorated amounts calculated based on remaining days
- Formula: `proratedAmount = (newPrice - oldPrice) * (remainingDays / 30)`

### 4. Notification Service

**Purpose**: Send webhook notifications to the main Das-tern backend about payment events.

**Key Methods**:
```typescript
interface NotificationService {
  notifyPaymentCompleted(payment: PaymentTransaction): Promise<void>
  notifySubscriptionActivated(subscription: Subscription): Promise<void>
  notifySubscriptionExpired(subscription: Subscription): Promise<void>
  notifyPaymentFailed(payment: PaymentTransaction): Promise<void>
}

interface WebhookPayload {
  event: WebhookEvent
  timestamp: Date
  data: PaymentTransaction | Subscription
  signature: string
}

enum WebhookEvent {
  PAYMENT_COMPLETED = 'payment.completed',
  PAYMENT_FAILED = 'payment.failed',
  SUBSCRIPTION_ACTIVATED = 'subscription.activated',
  SUBSCRIPTION_EXPIRED = 'subscription.expired',
  SUBSCRIPTION_CANCELLED = 'subscription.cancelled'
}
```

**Implementation Notes**:
- Uses HMAC-SHA256 for webhook signature
- Retries failed deliveries up to 3 times with exponential backoff (1s, 2s, 4s)
- Logs all webhook attempts and responses
- Marks notifications as failed after all retries exhausted

### 5. Authentication Middleware

**Purpose**: Secure API endpoints with API key authentication.

**Implementation**:
```typescript
interface AuthMiddleware {
  validateApiKey(request: Request): Promise<boolean>
  extractApiKey(request: Request): string | null
}

// API Key format: "Bearer <api_key>"
// Stored in environment variable: MAIN_BACKEND_API_KEY
// Validated against Redis cache for performance
```

**Security Features**:
- API keys are 256-bit random strings
- Keys are hashed before storage
- Rate limiting: 100 requests per minute per API key
- Failed authentication attempts are logged
- Automatic IP blocking after 10 failed attempts in 5 minutes

### 6. Rate Limiting Middleware

**Purpose**: Prevent abuse and ensure fair resource usage.

**Configuration**:
```typescript
interface RateLimitConfig {
  windowMs: number  // Time window in milliseconds
  maxRequests: number  // Max requests per window
  keyGenerator: (req: Request) => string  // Generate rate limit key
}

// Default configuration:
// - 100 requests per minute for authenticated requests
// - 10 requests per minute for webhook endpoints
// - Uses Redis for distributed rate limiting
```

## Data Models

### Database Schema (Prisma)

```prisma
// Payment Transaction Model
model PaymentTransaction {
  id                String        @id @default(uuid()) @db.Uuid
  userId            String        @db.Uuid
  billNumber        String        @unique @db.VarChar(100)  // Unique invoice number
  md5Hash           String        @unique @db.VarChar(32)   // MD5 hash of QR code
  amount            Decimal       @db.Decimal(10, 2)
  currency          String        @default("USD") @db.VarChar(3)
  status            PaymentStatus @default(PENDING)
  planType          PlanType
  
  // QR Code Data
  qrCode            String?       @db.Text              // KHQR string
  qrImagePath       String?       @db.VarChar(500)      // Path to QR image
  deepLink          String?       @db.Text              // Bakong app deep link
  
  // Payment Details
  isUpgrade         Boolean       @default(false)
  isRenewal         Boolean       @default(false)
  proratedAmount    Decimal?      @db.Decimal(10, 2)
  
  // Bakong Response Data
  bakongData        Json?         @db.JsonB             // Bakong API response
  
  // Monitoring
  checkAttempts     Int           @default(0)
  lastCheckedAt     DateTime?     @db.Timestamptz(3)
  
  // Timestamps
  createdAt         DateTime      @default(now()) @db.Timestamptz(3)
  updatedAt         DateTime      @updatedAt @db.Timestamptz(3)
  paidAt            DateTime?     @db.Timestamptz(3)
  expiredAt         DateTime?     @db.Timestamptz(3)
  
  // Relations
  subscription      Subscription? @relation(fields: [subscriptionId], references: [id])
  subscriptionId    String?       @db.Uuid
  statusHistory     PaymentStatusHistory[]
  
  @@index([userId])
  @@index([billNumber])
  @@index([md5Hash])
  @@index([status])
  @@index([createdAt])
  @@map("payment_transactions")
}

enum PaymentStatus {
  PENDING
  PAID
  FAILED
  TIMEOUT
  EXPIRED
  CANCELLED
}

enum PlanType {
  PREMIUM
  FAMILY_PREMIUM
}

// Payment Status History Model
model PaymentStatusHistory {
  id            String           @id @default(uuid()) @db.Uuid
  transactionId String           @db.Uuid
  oldStatus     PaymentStatus?
  newStatus     PaymentStatus
  reason        String?          @db.Text
  metadata      Json?            @db.JsonB
  createdAt     DateTime         @default(now()) @db.Timestamptz(3)
  
  transaction   PaymentTransaction @relation(fields: [transactionId], references: [id], onDelete: Cascade)
  
  @@index([transactionId])
  @@index([createdAt])
  @@map("payment_status_history")
}

// Subscription Model
model Subscription {
  id              String             @id @default(uuid()) @db.Uuid
  userId          String             @unique @db.Uuid
  planType        PlanType
  status          SubscriptionStatus @default(PENDING)
  
  // Billing Information
  startDate       DateTime           @db.Timestamptz(3)
  nextBillingDate DateTime           @db.Timestamptz(3)
  lastBillingDate DateTime?          @db.Timestamptz(3)
  
  // Cancellation
  cancelledAt     DateTime?          @db.Timestamptz(3)
  cancellationReason String?         @db.Text
  
  // Timestamps
  createdAt       DateTime           @default(now()) @db.Timestamptz(3)
  updatedAt       DateTime           @updatedAt @db.Timestamptz(3)
  
  // Relations
  payments        PaymentTransaction[]
  statusHistory   SubscriptionStatusHistory[]
  
  @@index([userId])
  @@index([status])
  @@index([nextBillingDate])
  @@map("subscriptions")
}

enum SubscriptionStatus {
  PENDING
  ACTIVE
  EXPIRED
  CANCELLED
}

// Subscription Status History Model
model SubscriptionStatusHistory {
  id             String             @id @default(uuid()) @db.Uuid
  subscriptionId String             @db.Uuid
  oldStatus      SubscriptionStatus?
  newStatus      SubscriptionStatus
  reason         String?            @db.Text
  metadata       Json?              @db.JsonB
  createdAt      DateTime           @default(now()) @db.Timestamptz(3)
  
  subscription   Subscription       @relation(fields: [subscriptionId], references: [id], onDelete: Cascade)
  
  @@index([subscriptionId])
  @@index([createdAt])
  @@map("subscription_status_history")
}

// Webhook Notification Model
model WebhookNotification {
  id            String            @id @default(uuid()) @db.Uuid
  event         WebhookEvent
  targetUrl     String            @db.VarChar(500)
  payload       Json              @db.JsonB
  signature     String            @db.VarChar(255)
  
  // Delivery Status
  status        WebhookStatus     @default(PENDING)
  attempts      Int               @default(0)
  lastAttemptAt DateTime?         @db.Timestamptz(3)
  nextRetryAt   DateTime?         @db.Timestamptz(3)
  
  // Response Data
  responseStatus Int?
  responseBody   String?          @db.Text
  errorMessage   String?          @db.Text
  
  // Timestamps
  createdAt     DateTime          @default(now()) @db.Timestamptz(3)
  updatedAt     DateTime          @updatedAt @db.Timestamptz(3)
  deliveredAt   DateTime?         @db.Timestamptz(3)
  
  @@index([status])
  @@index([nextRetryAt])
  @@index([createdAt])
  @@map("webhook_notifications")
}

enum WebhookEvent {
  PAYMENT_COMPLETED
  PAYMENT_FAILED
  SUBSCRIPTION_ACTIVATED
  SUBSCRIPTION_EXPIRED
  SUBSCRIPTION_CANCELLED
}

enum WebhookStatus {
  PENDING
  DELIVERED
  FAILED
}

// Audit Log Model
model AuditLog {
  id           String   @id @default(uuid()) @db.Uuid
  userId       String?  @db.Uuid
  action       String   @db.VarChar(100)
  resourceType String   @db.VarChar(50)
  resourceId   String?  @db.Uuid
  details      Json?    @db.JsonB
  ipAddress    String?  @db.VarChar(45)
  userAgent    String?  @db.Text
  createdAt    DateTime @default(now()) @db.Timestamptz(3)
  
  @@index([userId])
  @@index([action])
  @@index([resourceType])
  @@index([createdAt])
  @@map("audit_logs")
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Payment Reference Uniqueness
*For any* payment initiation request, the generated Payment_Reference must be unique (not exist in the database) and follow UUID v4 format.
**Validates: Requirements 1.1**

### Property 2: QR Code Generation Flow
*For any* successful QR code generation, the system must: (1) call Bakong_API with correct payment parameters, (2) store a Payment_Transaction with status "pending", and (3) return both qrCode and paymentReference in the response.
**Validates: Requirements 1.2, 1.3, 1.4**

### Property 3: QR Generation Error Handling
*For any* failed QR code generation attempt, the system must return a descriptive error message and create an audit log entry with the failure details.
**Validates: Requirements 1.5**

### Property 4: Webhook Signature Validation
*For any* incoming webhook, if the signature verification fails, the system must reject the request and create a security-level audit log entry.
**Validates: Requirements 2.1, 2.4**

### Property 5: Payment Status Transitions with History
*For any* payment transaction status change, the system must: (1) update the transaction status, (2) record the timestamp, and (3) create a PaymentStatusHistory record with old status, new status, and reason.
**Validates: Requirements 2.2, 2.3, 2.5**

### Property 6: Subscription Creation Consistency
*For any* completed payment for a new subscription, the system must create a Subscription_Record where: (1) status is "active", (2) startDate equals payment completedAt timestamp, and (3) nextBillingDate equals startDate + 30 days.
**Validates: Requirements 3.1, 3.2, 3.3**

### Property 7: Subscription Renewal Extension
*For any* confirmed renewal payment, the system must extend the subscription's nextBillingDate by exactly 30 days from the previous nextBillingDate.
**Validates: Requirements 3.4**

### Property 8: Subscription Termination
*For any* subscription, when a renewal payment fails, the status must become "expired", and when a user cancels, the status must become "cancelled" with cancelledAt timestamp recorded.
**Validates: Requirements 3.5, 3.6**

### Property 9: Prorated Amount Calculation
*For any* plan change request, the system must calculate proratedAmount using the formula: (newPrice - oldPrice) * (remainingDays / 30), and create a new Payment_Transaction with this amount.
**Validates: Requirements 4.1, 4.2, 4.3**

### Property 10: Plan Change Timing
*For any* plan upgrade with confirmed payment, the subscription planType must update immediately, and for any downgrade request, the plan change must be scheduled for the next billing cycle (not applied immediately).
**Validates: Requirements 4.4, 4.5**

### Property 11: API Key Authentication
*For any* API request, if the API_Key is invalid or missing, the system must return a 401 Unauthorized error and not process the request.
**Validates: Requirements 5.1, 5.2**

### Property 12: Payment Initiation Parameters
*For any* payment initiation request, the system must validate and accept userId, planType, and amount as required parameters.
**Validates: Requirements 5.3**

### Property 13: Payment Status Query
*For any* existing Payment_Reference, the status endpoint must return the current transaction status and details.
**Validates: Requirements 5.4**

### Property 14: Subscription Status Query
*For any* userId with an active subscription, the subscription status endpoint must return the complete Subscription_Record.
**Validates: Requirements 5.5**

### Property 15: Subscription Update Processing
*For any* valid subscription update request, the system must process the plan change and return the updated Subscription_Record.
**Validates: Requirements 5.6**

### Property 16: Webhook Notification Delivery
*For any* payment completion, subscription activation, or subscription expiration event, the system must create and send a webhook notification to Main_Backend with the event details.
**Validates: Requirements 6.1, 6.2, 6.3**

### Property 17: Webhook Retry Logic
*For any* failed webhook delivery, the system must retry exactly 3 times with exponential backoff (1s, 2s, 4s), and after all retries fail, mark the notification status as "failed" and log the failure.
**Validates: Requirements 6.4, 6.5**

### Property 18: Sensitive Data Encryption
*For any* payment transaction stored in the database, sensitive fields (card data, personal info) must be encrypted at rest.
**Validates: Requirements 7.1**

### Property 19: Webhook Payment Reference Validation
*For any* incoming webhook, if the Payment_Reference does not exist in the database, the system must reject the webhook and return an error.
**Validates: Requirements 7.3**

### Property 20: Payment Confirmation Idempotency
*For any* payment transaction, processing the same payment confirmation webhook multiple times must only update the status once (first confirmation processed, subsequent ones logged as duplicates).
**Validates: Requirements 7.4**

### Property 21: Authentication Rate Limiting
*For any* IP address, after 10 failed API_Key authentication attempts within 5 minutes, subsequent requests from that IP must be blocked.
**Validates: Requirements 7.5**

### Property 22: Transaction Data Completeness
*For any* created Payment_Transaction or Subscription_Record, all required fields (userId, amount, currency, paymentReference, timestamps for transactions; userId, planType, status, startDate, nextBillingDate for subscriptions) must be present and non-null.
**Validates: Requirements 8.1, 8.3**

### Property 23: Status Change History Tracking
*For any* Payment_Transaction or Subscription status change, a corresponding history record must be created with oldStatus, newStatus, reason, and timestamp.
**Validates: Requirements 8.2, 8.4**

### Property 24: Payment History Query Ordering
*For any* userId, querying payment history must return all Payment_Transactions for that user ordered by createdAt timestamp in descending order (newest first).
**Validates: Requirements 8.5**

### Property 25: External Service Error Responses
*For any* request when Bakong_API is unavailable, the system must return a 503 Service Unavailable error with a Retry-After header, and for any unexpected error, log the full stack trace while returning a generic error message to the client.
**Validates: Requirements 9.1, 9.4**

### Property 26: Payment Timeout Handling
*For any* Payment_Transaction with status "pending", if 15 minutes have elapsed since creation without status change, the system must automatically update the status to "timeout".
**Validates: Requirements 9.2**

### Property 27: Operation Retry Logic
*For any* failed database operation or webhook delivery, the system must retry the operation exactly 3 times with exponential backoff before marking it as failed.
**Validates: Requirements 9.3, 9.5**

### Property 28: Payment Initiation Audit Logging
*For any* payment initiation, the system must create an audit log entry containing userId, amount, and paymentReference.
**Validates: Requirements 10.1**

### Property 29: Status Change Audit Logging
*For any* payment or subscription status change, the system must create an audit log entry containing oldStatus, newStatus, and reason for change.
**Validates: Requirements 10.2**

### Property 30: Webhook Processing Audit Logging
*For any* received webhook, the system must create an audit log entry containing the webhook payload, signature verification result, and processing outcome.
**Validates: Requirements 10.3**

### Property 31: Inter-Service API Call Logging
*For any* API call between Bakong_Service and Main_Backend, the system must create an audit log entry containing endpoint, request parameters, and response status.
**Validates: Requirements 10.4**

### Property 32: Security Event Logging
*For any* security event (failed authentication, invalid webhook signature, rate limit violation), the system must create an audit log entry with level "SECURITY", containing event type, source IP, and timestamp.
**Validates: Requirements 10.5**

### Property 33: Subscription Renewal Failure Alerting
*For any* failed subscription renewal payment, the system must create an audit log entry with the failure reason and create an alert notification.
**Validates: Requirements 10.6**

## Error Handling

### Error Categories

1. **Client Errors (4xx)**
   - 400 Bad Request: Invalid parameters or malformed requests
   - 401 Unauthorized: Missing or invalid API key
   - 403 Forbidden: Valid authentication but insufficient permissions
   - 404 Not Found: Resource (payment, subscription) not found
   - 409 Conflict: Duplicate payment reference or conflicting state
   - 429 Too Many Requests: Rate limit exceeded

2. **Server Errors (5xx)**
   - 500 Internal Server Error: Unexpected application errors
   - 502 Bad Gateway: Bakong API communication failure
   - 503 Service Unavailable: Database or Redis unavailable
   - 504 Gateway Timeout: Bakong API timeout

### Error Response Format

```typescript
interface ErrorResponse {
  error: {
    code: string
    message: string
    details?: any
    timestamp: string
    requestId: string
  }
}

// Example:
{
  "error": {
    "code": "PAYMENT_NOT_FOUND",
    "message": "Payment transaction with reference 'abc-123' not found",
    "timestamp": "2024-02-08T10:30:00Z",
    "requestId": "req_xyz789"
  }
}
```

### Retry Strategies

1. **Bakong API Calls**
   - Retry on: 5xx errors, network timeouts
   - Max retries: 3
   - Backoff: Exponential (1s, 2s, 4s)
   - Circuit breaker: Open after 5 consecutive failures

2. **Database Operations**
   - Retry on: Connection errors, deadlocks
   - Max retries: 3
   - Backoff: Exponential (100ms, 200ms, 400ms)

3. **Webhook Deliveries**
   - Retry on: 5xx errors, network timeouts
   - Max retries: 3
   - Backoff: Exponential (1s, 2s, 4s)
   - Mark as failed after all retries exhausted

### Timeout Configuration

```typescript
const TIMEOUTS = {
  BAKONG_API_CALL: 10000,      // 10 seconds
  DATABASE_QUERY: 5000,         // 5 seconds
  WEBHOOK_DELIVERY: 10000,      // 10 seconds
  PAYMENT_EXPIRY: 900000,       // 15 minutes
}
```

## Testing Strategy

### Dual Testing Approach

The testing strategy employs both unit tests and property-based tests to ensure comprehensive coverage:

- **Unit Tests**: Verify specific examples, edge cases, and error conditions
- **Property Tests**: Verify universal properties across all inputs using randomized testing

### Property-Based Testing Configuration

- **Library**: fast-check (TypeScript property-based testing library)
- **Iterations**: Minimum 100 runs per property test
- **Test Tagging**: Each property test references its design document property number

Example property test structure:
```typescript
import fc from 'fast-check'

describe('Feature: bakong-payment-integration, Property 1: Payment Reference Uniqueness', () => {
  it('should generate unique UUID v4 payment references', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.record({
          userId: fc.uuid(),
          planType: fc.constantFrom('PREMIUM', 'FAMILY_PREMIUM'),
          amount: fc.double({ min: 0.5, max: 1.0 }),
        }),
        async (paymentParams) => {
          const paymentRef = await paymentService.generatePaymentReference()
          
          // Property: Payment reference must be UUID v4
          expect(paymentRef).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i)
          
          // Property: Payment reference must be unique
          const existing = await prisma.paymentTransaction.findUnique({
            where: { paymentReference: paymentRef }
          })
          expect(existing).toBeNull()
        }
      ),
      { numRuns: 100 }
    )
  })
})
```

### Unit Testing Focus Areas

1. **API Endpoint Tests**
   - Request validation
   - Response format verification
   - Authentication and authorization
   - Error handling

2. **Service Layer Tests**
   - Business logic correctness
   - State transitions
   - Data transformations
   - Integration with external services (mocked)

3. **Database Tests**
   - Schema validation
   - Constraint enforcement
   - Transaction integrity
   - Query performance

4. **Security Tests**
   - API key validation
   - Webhook signature verification
   - Rate limiting
   - Data encryption

### Integration Testing

1. **Bakong API Integration** (with mocks)
   - QR code generation flow
   - Webhook processing
   - Error handling

2. **Main Backend Integration** (with mocks)
   - API authentication
   - Webhook delivery
   - Status synchronization

3. **Database Integration**
   - Transaction management
   - Concurrent access handling
   - Data consistency

### Test Coverage Goals

- **Line Coverage**: Minimum 80%
- **Branch Coverage**: Minimum 75%
- **Property Tests**: All 33 correctness properties implemented
- **Unit Tests**: All critical paths and edge cases covered

### Continuous Testing

- Run unit tests on every commit
- Run property tests on every pull request
- Run integration tests before deployment
- Monitor test execution time and flakiness

## Deployment and Configuration

### Environment Variables

```bash
# Application
NODE_ENV=production
PORT=3000
API_BASE_URL=https://payment.dastern.com

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/bakong_payment
DATABASE_POOL_SIZE=20

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=your_redis_password

# Bakong API Configuration
BAKONG_API_URL=https://api-bakong.nbc.gov.kh/v1
BAKONG_MERCHANT_ID=your_merchant_id
BAKONG_PHONE_NUMBER=85512345678
BAKONG_DEVELOPER_TOKEN=your_developer_token

# Default Merchant Info
DEFAULT_MERCHANT_NAME=Das-tern
DEFAULT_MERCHANT_CITY=Phnom Penh
DEFAULT_STORE_LABEL=DasTern-Store
DEFAULT_TERMINAL_LABEL=POS-01

# Main Backend Integration
MAIN_BACKEND_URL=https://api.dastern.com
MAIN_BACKEND_API_KEY=your_main_backend_api_key
MAIN_BACKEND_WEBHOOK_URL=https://api.dastern.com/webhooks/payment

# Security
JWT_SECRET=your_jwt_secret
ENCRYPTION_KEY=your_encryption_key_32_chars

# Monitoring
LOG_LEVEL=info
LOG_DIR=./logs
SENTRY_DSN=your_sentry_dsn

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# Payment Monitoring
PAYMENT_TIMEOUT_MS=900000          # 15 minutes
PAYMENT_CHECK_INTERVAL_MS=5000     # 5 seconds
PAYMENT_MAX_ATTEMPTS=60            # 60 attempts * 5 seconds = 5 minutes
```

### Docker Deployment

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build Nest.js application
RUN npm run build

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
```

### Docker Compose Configuration

```yaml
version: '3.8'

services:
  bakong-payment:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/bakong_payment
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  postgres:
    image: postgres:17-alpine
    environment:
      - POSTGRES_DB=bakong_payment
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass password
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

### Health Checks

```typescript
// app/api/health/route.ts
export async function GET() {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    checks: {
      database: await checkDatabase(),
      redis: await checkRedis(),
      bakongApi: await checkBakongApi(),
    }
  }
  
  const isHealthy = Object.values(health.checks).every(check => check.status === 'up')
  
  return Response.json(health, {
    status: isHealthy ? 200 : 503
  })
}
```

### Monitoring and Alerting

1. **Application Metrics**
   - Request rate and latency
   - Error rate by endpoint
   - Payment success/failure rates
   - Webhook delivery success rates

2. **Infrastructure Metrics**
   - CPU and memory usage
   - Database connection pool utilization
   - Redis memory usage
   - Disk I/O

3. **Business Metrics**
   - Total payments processed
   - Revenue by plan type
   - Subscription churn rate
   - Average payment processing time

4. **Alerts**
   - Payment failure rate > 5%
   - Webhook delivery failure rate > 10%
   - Database connection pool exhausted
   - API response time > 2 seconds
   - Bakong API unavailable

### Security Considerations

1. **API Key Management**
   - Store API keys in environment variables
   - Rotate keys every 90 days
   - Use different keys for different environments

2. **Data Encryption**
   - Encrypt sensitive data at rest using AES-256
   - Use TLS 1.2+ for all network communication
   - Hash API keys before storage

3. **Audit Logging**
   - Log all payment transactions
   - Log all API calls
   - Log all security events
   - Retain logs for 1 year

4. **Access Control**
   - Restrict database access to application only
   - Use read-only database replicas for reporting
   - Implement IP whitelisting for admin endpoints

5. **Compliance**
   - PCI DSS compliance for payment data
   - GDPR compliance for user data
   - Regular security audits
   - Penetration testing

## Conclusion

This design document provides a comprehensive blueprint for implementing the Bakong Payment Integration Backend Service. The architecture emphasizes security, reliability, and maintainability while ensuring seamless integration with both the Bakong payment system and the main Das-tern backend.

Key design decisions:
- Standalone service architecture for isolation and scalability
- Property-based testing for comprehensive correctness verification
- Comprehensive audit logging for transparency and debugging
- Retry mechanisms and error handling for reliability
- API key authentication for secure inter-service communication

The implementation should follow this design closely, with any deviations documented and justified.
