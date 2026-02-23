# Backend Service Communication & Dependency Map

> Quick reference for understanding module interactions and data flow

---

## 📊 Module Dependency Hierarchy

```
AppModule (Root)
│
├─── ConfigModule (Global Configuration)
├─── ThrottlerModule (Rate Limiting)
├─── CacheModule (Redis)
│
├─── DatabaseModule
│    └─── PrismaService (PostgreSQL ORM)
│
└─── Feature Modules:
    │
    ├─── AuthModule
    │    ├─ Depends on: UserModule, Database
    │    ├─ Provides: JWT tokens, OAuth
    │    └─ Consumed by: All protected routes
    │
    ├─── UsersModule
    │    ├─ Depends on: Database, AuditModule
    │    ├─ Provides: User CRUD operations
    │    └─ Consumed by: Auth, Connections, Admin Dashboard
    │
    ├─── ConnectionsModule
    │    ├─ Depends on: UsersModule, Database
    │    ├─ Provides: Doctor-Patient relationships
    │    └─ Consumed by: PrescriptionsModule, DoctorDashboard, HealthMonitoring
    │
    ├─── PrescriptionsModule
    │    ├─ Depends on: UsersModule, MedicinesModule, ConnectionsModule, Database
    │    ├─ Provides: Prescription management
    │    └─ Consumed by: DosesModule, DoctorDashboard, Notifications
    │
    ├─── DosesModule
    │    ├─ Depends on: PrescriptionsModule, Database
    │    ├─ Provides: Dose scheduling & tracking
    │    └─ Consumed by: AdherenceModule, NotificationsModule, HealthMonitoring
    │
    ├─── AdherenceModule
    │    ├─ Depends on: DosesModule, PrescriptionsModule, Database
    │    ├─ Provides: Adherence analytics & reports
    │    └─ Consumed by: DoctorDashboard, HealthMonitoring
    │
    ├─── HealthMonitoringModule
    │    ├─ Depends on: UsersModule, PrescriptionsModule, ConnectionsModule, Database
    │    ├─ Provides: Vital signs & alerts
    │    └─ Consumed by: NotificationsModule, DoctorDashboard
    │
    ├─── MedicinesModule
    │    ├─ Depends on: Database
    │    ├─ Provides: Medicine catalog & info
    │    └─ Consumed by: PrescriptionsModule, BatchMedicationModule, OcrModule
    │
    ├─── NotificationsModule
    │    ├─ Depends on: UsersModule, EmailModule, Database
    │    ├─ Provides: Notification queue management
    │    └─ Consumed by: PrescriptionsModule, DosesModule, HealthMonitoring, Payments
    │
    ├─── EmailModule
    │    ├─ Depends on: Configuration
    │    ├─ Provides: SMTP email sending
    │    └─ Consumed by: NotificationsModule, AuthModule, SubscriptionsModule
    │
    ├─── BakongPaymentModule
    │    ├─ Depends on: UsersModule, Database
    │    ├─ Provides: Payment processing
    │    └─ Consumed by: SubscriptionsModule, Notifications
    │
    ├─── SubscriptionsModule
    │    ├─ Depends on: UsersModule, BakongPaymentModule, Database
    │    ├─ Provides: Subscription management
    │    └─ Consumed by: AuditModule
    │
    ├─── DoctorDashboardModule
    │    ├─ Depends on: ConnectionsModule, PrescriptionsModule, AdherenceModule, 
    │    │               HealthMonitoringModule, Database
    │    ├─ Provides: Doctor aggregate data & views
    │    └─ Consumed by: Frontend (doctor users)
    │
    ├─── OcrModule
    │    ├─ Depends on: MedicinesModule, PrescriptionsModule, Database
    │    ├─ Provides: OCR prescription parsing
    │    └─ Consumed by: PrescriptionsModule creation flow
    │
    ├─── BatchMedicationModule
    │    ├─ Depends on: PrescriptionsModule, MedicinesModule, Database
    │    ├─ Provides: Batch prescription operations
    │    └─ Consumed by: DoctorDashboard (for bulk operations)
    │
    └─── AuditModule
         ├─ Depends on: Database
         ├─ Provides: Audit logging & compliance
         └─ Consumed by: All modules (via interceptor)
```

---

## 🔄 Request/Response Flow Examples

### Example 1: Create Prescription

```
REQUEST:
  POST /api/prescriptions
  Authorization: Bearer [JWT]
  Body: { medicineId, dosage, frequency, patientId }
  ↓
AUTHENTICATION CHAIN:
  1. JwtGuard → Validates token signature & expiry
  2. RolesGuard → Checks user has DOCTOR role
  3. DTOValidation → Validates request body structure
  ↓
CONTROLLER: PrescriptionsController.create()
  ↓
SERVICE CHAIN:
  1. ConnectionsService.validateAccess(doctorId, patientId)
     → Checks doctor has active connection with patient
  2. MedicinesService.findById(medicineId)
     → Validates medicine exists
  3. PrescriptionsService.create(prescription)
     → Stores prescription in PostgreSQL
  4. DosesService.generateSchedule(prescriptionId)
     → Creates dose records
  5. AuditService.log(CREATE, 'Prescription', ...)
     → Logs action for compliance
  6. CacheService.invalidate(patientId)
     → Clears patient data cache
  7. NotificationsService.enqueue(patientId)
     → Queues notification to patient
  ↓
BACKGROUND JOBS:
  1. Email sent via Bull Queue
  2. Push notification via Firebase (future)
  ↓
RESPONSE:
  200 OK
  {
    id: "uuid",
    status: "ACTIVE",
    createdAt: "2026-02-20T10:30:00Z"
  }
```

### Example 2: Record Dose as Taken

```
REQUEST:
  POST /api/doses/:doseId/mark-taken
  Authorization: Bearer [JWT]
  Body: { takenAt, notes }
  ↓
AUTHENTICATION:
  1. JwtGuard → Validates JWT
  2. OwnershipGuard → Ensures patient owns the dose
  ↓
CONTROLLER: DosesController.markTaken()
  ↓
SERVICE CHAIN:
  1. DosesService.findById(doseId)
  2. DosesService.markTaken(doseId, takenAt)
     → Updates database
  3. AdherenceService.recalculate(patientId)
     → Updates adherence metrics
  4. HealthMonitoringService.checkAlerts(patientId)
     → Generates alerts if needed
  5. AuditService.log(UPDATE, 'Dose', ...)
  6. CacheService.invalidate(['doses:patient', 'adherence:patient'])
  ↓
CONDITIONAL FLOWS:
  IF adherence improved:
    → Send congratulations notification
  IF missed dose detected:
    → Send alert to doctor
  IF health indicator abnormal:
    → Create health alert
  ↓
RESPONSE:
  200 OK
  { adherenceRate: 95.5, message: "Great job!" }
```

### Example 3: Bakong Payment Webhook

```
EXTERNAL EVENT:
  POST /api/payments/webhook (from Bakong Service)
  Body: { transactionId, status, amount, timestamp, signature }
  ↓
WEBHOOK VERIFICATION:
  1. SignatureGuard → Validates Bakong signature
  2. DecryptionService → Decrypts payload if needed
  ↓
WEBHOOK HANDLER: BakongPaymentWebhookHandler
  ↓
SERVICE CHAIN:
  1. PaymentService.findByTransactionId(transactionId)
     → Retrieves payment record
  2. PaymentService.updateStatus(paymentId, status)
     → Updates in PostgreSQL
  3. SubscriptionsService.activateIfNeeded(userId)
     → Activates subscription if payment successful
  4. AuditService.log(UPDATE, 'Payment', ...)
  5. EmailService.enqueue(paymentConfirmation)
     → Queue confirmation email
  6. NotificationsService.enqueue(paymentComplete)
     → Queue mobile notification
  7. CacheService.invalidate(['subscription:', 'user:'])
  ↓
BACKGROUND JOBS:
  1. Email sent via Bull Queue
  2. Notification pushed via Firebase
  ↓
RESPONSE:
  200 OK
  { transactionId, status: "COMPLETED" }
```

---

## 🌊 Data Flow Through System Layers

### Synchronous Flow (API Request)

```
┌──────────────────┐
│ Client Request   │ (Flutter/Web)
└────────┬─────────┘
         │ HTTPS
         ↓
┌──────────────────┐
│ API Gateway      │ (Nginx/Load Balancer)
└────────┬─────────┘
         │ Route matching
         ↓
┌──────────────────┐
│ NestJS Middleware│ (Logging, CORS, Compression)
└────────┬─────────┘
         │ Request validation
         ↓
┌──────────────────┐
│ Guard Chain      │ (Auth, RBAC, Custom)
└────────┬─────────┘
         │ Authorization checks
         ↓
┌──────────────────┐
│ Pipe Chain       │ (Validation, Transformation)
└────────┬─────────┘
         │ Data validation & transformation
         ↓
┌──────────────────┐
│ Controller       │ (Route handler)
└────────┬─────────┘
         │ Request -> Service method
         ↓
┌──────────────────┐
│ Service Layer    │ (Business logic)
└────────┬─────────┘
         │ Execute use cases
         ↓
┌──────────────────┐
│ Repository/ORM   │ (Data access)
└────────┬─────────┘
         │ Database operations
         ↓
┌──────────────────┐
│ PostgreSQL       │ (Persistence)
└────────┬─────────┘
         │ Query execution
         ↓
┌──────────────────┐
│ Response Mapper  │ (Serialize data)
└────────┬─────────┘
         │ Object -> JSON
         ↓
┌──────────────────┐
│ Client Response  │ (200/201/400/500)
└──────────────────┘
```

### Asynchronous Flow (Background Jobs)

```
┌──────────────────┐
│ Service enqueues │ (NotificationsService.enqueue(userId))
│ background job   │
└────────┬─────────┘
         │ Bull Queue
         ↓
┌──────────────────┐
│ Redis Storage    │ (Job persisted)
└────────┬─────────┘
         │ Job scheduled
         ↓
┌──────────────────┐
│ Bull Worker      │ (Process from queue)
└────────┬─────────┘
         │ Pick up job
         ↓
┌──────────────────┐
│ Execute Handler  │ (Email/Notification logic)
└────────┬─────────┘
         │ Actual work performed
         ↓
┌──────────────────┐
│ External Service │ (SMTP/Firebase/SMS)
└────────┬─────────┘
         │ Deliver message
         ↓
┌──────────────────┐
│ Job Complete     │ (Mark as done in Redis)
└────────┬─────────┘
         │ Retry if failed (exponential backoff)
         ↓
┌──────────────────┐
│ Dead Letter Queue │ (If max retries exceeded)
└──────────────────┘
```

---

## 💾 Database Access Patterns

### Pattern 1: Read Heavy (User Profile)

```
Request → Controller → Service.getProfile(userId)
         ↓
    Check Cache (Redis)
         ↓
    Cache HIT?
    ├─ YES: Return cached data (fast)
    │
    └─ NO: Query PostgreSQL
         ↓ SELECT * FROM users WHERE id = ?
         PostgreSQL → Users table
         ↓ Parse result
         Memory → Store in Redis (TTL: 1 hour)
         ↓
    Return to Client
```

### Pattern 2: Write Heavy (Record Doses)

```
Request → Controller → Service.recordDose(doseId, takenAt)
         ↓
    Begin Transaction
         ↓
    1. UPDATE doses SET takenTime = ?, status = 'TAKEN'
    2. INSERT INTO audit_logs VALUES (...)
    3. INVALIDATE cache key: doses:patient:*
         ↓
    All succeed? → COMMIT
    Any fail? → ROLLBACK
         ↓
    Return response
```

### Pattern 3: Real-time Data (Health Alerts)

```
VitalSigns Service detects abnormal value
         ↓
Insert into PostgreSQL (persistent)
         ↓
Publish to Redis Pub/Sub (real-time)
         ↓
WebSocket server receives message
         ↓
Broadcast to doctor's WebSocket room
         ↓
Doctor's mobile app receives real-time alert
         ↓
Show notification/alert UI
         ↓
Enqueue email notification (Bull Queue)
         ↓
Background job sends email confirmation
```

---

## 🔐 Security Data Flow

### Login & Token Generation

```
User submits credentials (email, password)
         ↓
AuthService.login(email, password)
         ↓
1. Find user by email (PostgreSQL query)
2. Hash submitted password with bcrypt
3. Compare with stored password hash
         ↓
Password correct?
├─ NO: Return 401 Unauthorized
│
└─ YES: Generate JWT token
         ↓
JWT Payload: { sub: userId, role, email }
JWT Signed: HMAC-SHA256(payload, SECRET)
         ↓
Store in Redis: jwt:token → expiry=24h
         ↓
Return token to client
         ↓
Client stores in secure storage
         ↓
Subsequent requests include: Authorization: Bearer [TOKEN]
```

### Access Control Check

```
Request arrives with Authorization header
         ↓
JwtGuard.canActivate()
         ↓
1. Extract token from header
2. Verify signature (SECRET key)
3. Check expiration (exp claim)
4. Check token blacklist (Redis)
         ↓
Token valid?
├─ NO: Return 401 Unauthorized
│
└─ YES: Extract user ID from token
         ↓
Load user from cache/database
         ↓
RolesGuard checks: @Roles(Role.DOCTOR)
         ↓
User role matches?
├─ NO: Return 403 Forbidden
│
└─ YES: Proceed to controller
         ↓
Business logic executes
         ↓
Return 200 OK with response
```

---

## 📈 Caching Strategy by Module

```
MODULE                  CACHED DATA              TTL          INVALIDATION
─────────────────────────────────────────────────────────────────────────
Users                   User profiles            1 hour       On update
Medicines               Medicine catalog         24 hours     Weekly refresh
Connections             Active connections      15 minutes   On connect/revoke
Prescriptions           Patient's Rx list        1 hour       On add/modify
Doses                   Weekly schedule          6 hours      On record taken
Adherence               Adherence metrics        30 minutes   After dose update
Health Monitoring       Recent vital signs       15 minutes   On new reading
Notifications           Unread count             5 minutes    On read/create
Sessions                JWT tokens               24 hours     On logout
Rate Limits             Request counts           1 minute     Sliding window
```

---

## 🚀 Initialization & Startup Flow

```
Docker Compose Up
    │
    ├─ PostgreSQL Container starts
    │  ├─ Creates database schema
    │  ├─ Runs migrations: 20260208122556_init
    │  ├─ Other migrations apply
    │  └─ Ready to accept connections
    │
    ├─ Redis Container starts
    │  ├─ Initializes in-memory store
    │  ├─ Loads migration scripts
    │  └─ Ready at port 6379
    │
    └─ NestJS Container starts
       ├─ Load environment variables (.env)
       ├─ Initialize ConfigModule
       ├─ Connect to PostgreSQL (Prisma)
       ├─ Connect to Redis (cache-manager)
       ├─ Initialize all modules
       ├─ Register all controllers & routes
       ├─ Start Bull queues
       ├─ Register scheduled tasks
       ├─ Listen on port 3000
       └─ Ready: "NestJS server running on http://localhost:3000"
```

---

## 📋 Common Error Handling Flows

### Database Connection Error

```
Service tries to query PostgreSQL
         ↓
Connection fails: ECONNREFUSED
         ↓
Prisma catches error
         ↓
Retry logic (configurable):
  Attempt 1: Immediate
  Attempt 2: 100ms delay
  Attempt 3: 200ms delay
  ↓
All retries exhausted?
├─ Return 503 Service Unavailable
│  (or 500 Internal Server Error)
└─ Log error to console & monitoring
```

### Validation Error

```
Request arrives with invalid data
  { email: "not-an-email", password: "123" }
         ↓
Pipe validation runs:
  - class-validator checks @IsEmail()
  - @MinLength(8) fails for password
         ↓
Return 400 Bad Request
  {
    message: "Validation failed",
    errors: [
      { field: "email", message: "must be valid email" },
      { field: "password", message: "must be 8 chars" }
    ]
  }
```

### Unauthorized Access

```
Request to protected endpoint
  GET /api/prescriptions/:id
         ↓
JwtGuard checks Authorization header
         ↓
No token or invalid token?
  ├─ Return 401 Unauthorized
  └─ Log access attempt
         ↓
Valid token but user is PATIENT trying to access other patient's Rx?
  ├─ OwnershipGuard validation fails
  ├─ Return 403 Forbidden
  └─ Log unauthorized access attempt (audit)
```

---

## 🔄 Module Interaction Diagram

```
                    ┌─────────────┐
                    │  AuthModule │
                    └──────┬──────┘
                           │ provides JWT
                           ↓
            ┌──────────────────────────────────┐
            │  JwtGuard (All protected routes)  │
            └──────────────────────────────────┘
                    │      │       │
        ┌───────────┘      │       └───────────┐
        ↓                  ↓                    ↓
    ┌──────────┐   ┌────────────┐    ┌──────────────┐
    │ Users    │   │Connections │    │Prescriptions │
    │ Module   │   │ Module     │    │  Module      │
    └────┬─────┘   └─────┬──────┘    └──────┬───────┘
         │                │                  │
         │ validates      │ validates       │ creates
         │ user owner     │ doctor access   │ doses
         │                │                  │
         │                └────────┬─────────┘
         │                         ↓
         │                    ┌──────────┐
         │                    │ Doses    │
         │                    │ Module   │
         │                    └────┬─────┘
         │                         │ calculate
         │                         ↓
         │                    ┌──────────────┐
         │                    │ Adherence    │
         │                    │ Module       │
         │                    └────┬─────────┘
         │                         │ generate
         │                         ↓
         │                    ┌────────────────┐
         │                    │ HealthMonitor. │◄─── vitals
         │                    │ Module         │
         │                    └────┬───────────┘
         │                         │ alerts
         │                         ↓
         │              ┌──────────────────────┐
         │              │ NotificationsModule  │
         │              └────────┬─────────────┘
         │                       │ queues
         │                       ↓
         └─────────────► ┌──────────────┐
                         │ EmailModule  │
                         │ (SMTP)       │
                         └──────────────┘
                                 │
                                 ↓
                         External Email Service
```

---

## 📞 External Service Call Examples

### Call to Bakong Service

```
Backend triggers payment:
  POST /bakong-payment/initiate
  {
    userId: "uuid",
    amount: 100000,
    currency: "KHR"
  }
         ↓
PaymentService encrypts payload
         ↓
Axios HTTP client sends to:
  POST https://bakong-service.vps:5000/api/payments/create
  Headers: X-API-Key: [secret]
  Body: { encrypted_payload }
         ↓
Bakong Service:
  1. Decrypts payload
  2. Validates against API key
  3. Calls Bakong Aggregator API
  4. Receives QR code
  5. Returns to backend
         ↓
Backend receives:
  {
    transactionId: "TRX123",
    qrCode: "base64-encoded-image",
    expiresAt: timestamp
  }
         ↓
Send QR to mobile app
```

### Call to Email Service

```
NotificationService enqueues email job:
  {
    recipientEmail: "user@example.com",
    templateName: "prescription_shared",
    templateData: { doctorName, medicineList }
  }
         ↓
Bull Queue stores job in Redis
         ↓
Worker picks up job
         ↓
EmailService processes:
  1. Load template
  2. Render HTML (fill variables)
  3. Create nodemailer transport
  4. SendEmail via SMTP
         ↓
Email provider (Gmail):
  1. Receives SMTP AUTH
  2. Validates sender
  3. Queues for delivery
  4. Sends to inbox
         ↓
User receives email
```

---

**Last Updated**: February 20, 2026  
**For**: DAS-TERN Backend Architecture Reference
