# Das-Tern Backend Architecture - Complete Overview

## 1. Project Structure

```
das-tern/
├── backend_nestjs/          # Main API server (NestJS)
├── bakong_payment/          # Payment service (NestJS microservice)
├── ocr/                     # OCR extraction service (Python FastAPI)
├── ai-llm-service/          # AI enhancement service (Python FastAPI)
├── database/                # Database initialization scripts
├── docker-compose.yml       # Main orchestration
├── docker-compose.prod.yml  # Production deployment
└── nginx/                   # Nginx configuration for reverse proxy
```

---

## 2. Backend NestJS Architecture

### 2.1 Overview
- **Framework**: NestJS 10.3.0
- **Port**: 3001 (dev), configurable
- **Language**: TypeScript
- **API Prefix**: `/api/v1`
- **Database**: PostgreSQL 17 with Prisma ORM
- **Cache**: Redis 7.4
- **Queue**: RabbitMQ 4.0 (Bull integration)
- **Storage**: MinIO (S3-compatible)

### 2.2 Entry Point
**File**: `/backend_nestjs/src/main.ts`

```
Bootstrap → AppModule → All Services
    ↓
Security (Helmet) + CORS + Compression
    ↓
Global Validation Pipe
    ↓
Rate Limiting (Throttler)
    ↓
Listen on PORT 3001
```

### 2.3 Core Module Structure

#### **App Module** (`src/app.module.ts`)
Imports all feature modules:
- AuthModule
- UsersModule
- ConnectionsModule
- PrescriptionsModule
- DosesModule
- NotificationsModule
- AuditModule
- SubscriptionsModule
- EmailModule
- DoctorDashboardModule
- MedicinesModule
- AdherenceModule
- BakongPaymentModule
- HealthMonitoringModule
- OcrModule
- BatchMedicationModule

#### **Database Module** (`src/database/`)
- **PrismaService**: Global database connection
- Manages all ORM operations
- Uses PostgreSQL connection string from `.env`

#### **Common Module** (`src/common/`)
- **Decorators**: `@CurrentUser()`, `@Roles()`
- **Guards**: `RolesGuard` for role-based access control
- Global validators and interceptors

---

## 3. Database Schema (PostgreSQL + Prisma)

### 3.1 Core Models

#### **Users**
```sql
- id (UUID, PK)
- role (PATIENT, DOCTOR, FAMILY_MEMBER)
- firstName, lastName, fullName
- phoneNumber (UNIQUE)
- email (UNIQUE)
- passwordHash
- googleId, telegramId
- gender, dateOfBirth
- idCardNumber, licenseNumber
- profilePictureUrl, licensePhotoUrl
- language (KHMER/ENGLISH)
- theme (LIGHT/DARK)
- accountStatus (ACTIVE, PENDING_VERIFICATION, VERIFIED, REJECTED, LOCKED)
- failedLoginAttempts, lockedUntil
- resetToken, resetTokenExpiry
- timestamps: createdAt, updatedAt
- Relations: connections, prescriptions, vitals, doses, notifications, etc.
```

**Indexes**: phoneNumber, email, role, accountStatus

#### **Connections** (Doctor-Patient Relationships)
```sql
- id (UUID, PK)
- initiatorId → User (doctor/family member)
- recipientId → User (patient)
- status (PENDING, ACCEPTED, REVOKED)
- permissionLevel (NOT_ALLOWED, REQUEST, SELECTED, ALLOWED)
- metadata (JSON)
- timestamps: requestedAt, acceptedAt, revokedAt
```

**Unique Constraint**: (initiatorId, recipientId)

#### **Prescriptions** (Core Medication Data)
```sql
- id (UUID, PK)
- patientId → User
- doctorId → User (nullable)
- patientName, patientGender, patientAge
- symptoms, diagnosis, clinicalNote
- doctorLicenseNumber
- followUpDate, startDate, endDate
- ocrMetadata (JSON - OCR extraction data)
- status (DRAFT, ACTIVE, PAUSED, INACTIVE)
- currentVersion (for versioning)
- isUrgent, urgentReason
- timestamps: createdAt, updatedAt
- Relations: medications, doseEvents, versions
```

**Indexes**: patientId, doctorId, status, (patientId, status)

#### **Medications** (Within Prescriptions)
```sql
- id (UUID, PK)
- prescriptionId → Prescription
- rowNumber (order within prescription)
- batchId → MedicationBatch (optional)
- medicineName, medicineNameKhmer
- imageUrl
- medicineType (ORAL, INJECTION, TOPICAL, OTHER)
- unit (TABLET, CAPSULE, ML, MG, DROP, OTHER)
- dosageAmount
- description, additionalNote
- morningDosage, afternoonDosage, eveningDosage, nightDosage (JSON)
- frequency, duration, timing
- isPRN (as needed), beforeMeal
- timestamps: createdAt, updatedAt
- Relations: doseEvents, batch
```

#### **DoseEvents** (Individual Dose Tracking)
```sql
- id (UUID, PK)
- prescriptionId → Prescription
- medicationId → Medication
- patientId → User
- scheduledTime (DateTime)
- timePeriod (MORNING, AFTERNOON, EVENING, NIGHT)
- reminderTime (HH:MM)
- status (DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED)
- takenAt (DateTime, nullable)
- skipReason (nullable)
- wasOffline (Boolean)
- timestamps: createdAt, updatedAt
```

**Indexes**: patientId, scheduledTime, status, (patientId, scheduledTime)

#### **HealthVitals** (Blood Pressure, Glucose, Heart Rate, etc.)
```sql
- id (UUID, PK)
- patientId → User
- vitalType (BLOOD_PRESSURE, GLUCOSE, HEART_RATE, WEIGHT, TEMPERATURE, SPO2)
- value (Float)
- valueSecondary (Float, nullable - e.g., diastolic for BP)
- unit (String)
- measuredAt (DateTime)
- notes, isAbnormal
- source (manual/device)
- timestamps: createdAt, updatedAt
- Relations: alerts
```

#### **VitalThresholds** (Patient Alert Ranges)
```sql
- id (UUID, PK)
- patientId → User
- vitalType
- minValue, maxValue
- minSecondary, maxSecondary
- timestamps: createdAt, updatedAt
```

**Unique Constraint**: (patientId, vitalType)

#### **HealthAlerts** (Vital Anomalies)
```sql
- id (UUID, PK)
- patientId → User
- vitalId → HealthVital (nullable)
- alertType (String)
- severity (LOW, MEDIUM, HIGH, CRITICAL)
- message, isResolved
- resolvedAt, resolvedBy
- timestamps: createdAt, updatedAt
```

#### **Notifications**
```sql
- id (UUID, PK)
- recipientId → User
- type (CONNECTION_REQUEST, PRESCRIPTION_UPDATE, MISSED_DOSE_ALERT, VITAL_ANOMALY, etc.)
- title, message
- data (JSON)
- isRead, readAt
- timestamps: createdAt
```

**Indexes**: (recipientId, isRead), createdAt

#### **MedicationBatch** (Batch/Time-based Grouping)
```sql
- id (UUID, PK)
- patientId → User
- name (e.g., "Morning Routine")
- scheduledTime (HH:MM)
- isActive (Boolean)
- timestamps: createdAt, updatedAt
- Relations: medications (many)
```

#### **Subscription** (Freemium Model)
```sql
- id (UUID, PK)
- userId (UNIQUE) → User
- tier (FREEMIUM, PREMIUM, FAMILY_PREMIUM)
- storageQuota (BigInt, bytes)
- storageUsed (BigInt, bytes)
- expiresAt (DateTime, nullable)
- hasUsedTrial (Boolean)
- timestamps: createdAt, updatedAt
- Relations: familyMembers, payments (bakong_payment DB)
```

#### **FamilyMember** (Subscription Sharing)
```sql
- id (UUID, PK)
- subscriptionId → Subscription
- memberId → User
- addedAt (DateTime)
```

**Unique Constraint**: (subscriptionId, memberId)

#### **AuditLog** (Activity Tracking)
```sql
- id (UUID, PK)
- actorId → User (nullable)
- actorRole (UserRole, nullable)
- actionType (CONNECTION_REQUEST, DOSE_TAKEN, PRESCRIPTION_UPDATE, etc.)
- resourceType (Connection, Prescription, etc.)
- resourceId (UUID, nullable)
- details (JSON)
- ipAddress (String, nullable)
- timestamps: createdAt
```

**Indexes**: actorId, resourceId, createdAt, actionType

#### **PrescriptionVersion** (Change History)
```sql
- id (UUID, PK)
- prescriptionId → Prescription
- versionNumber (Int)
- authorId → User (nullable)
- changeReason (nullable)
- medicationsSnapshot (JSON - full medications array)
- timestamps: createdAt
```

**Unique Constraint**: (prescriptionId, versionNumber)

#### **DoctorNote** (Doctor-Patient Communication)
```sql
- id (UUID, PK)
- doctorId → User
- patientId → User
- content (String)
- timestamps: createdAt, updatedAt
```

#### **ConnectionToken** (Invite/QR Code)
```sql
- id (UUID, PK)
- patientId → User
- token (UNIQUE, 20-char)
- permissionLevel
- targetRole
- expiresAt (DateTime)
- usedAt, usedById
- timestamps: createdAt
```

#### **MealTimePreference** (For Dosage Timing Context)
```sql
- id (UUID, PK)
- userId (UNIQUE) → User
- morningMeal, afternoonMeal, eveningMeal, nightMeal (HH:MM)
- timestamps: createdAt, updatedAt
```

### 3.2 Enums
```
UserRole: PATIENT, DOCTOR, FAMILY_MEMBER
Gender: MALE, FEMALE, OTHER
Language: KHMER, ENGLISH
Theme: LIGHT, DARK
AccountStatus: ACTIVE, PENDING_VERIFICATION, VERIFIED, REJECTED, LOCKED
ConnectionStatus: PENDING, ACCEPTED, REVOKED
PermissionLevel: NOT_ALLOWED, REQUEST, SELECTED, ALLOWED
PrescriptionStatus: DRAFT, ACTIVE, PAUSED, INACTIVE
TimePeriod: MORNING, AFTERNOON, EVENING, NIGHT
DoseEventStatus: DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED
SubscriptionTier: FREEMIUM, PREMIUM, FAMILY_PREMIUM
NotificationType: CONNECTION_REQUEST, PRESCRIPTION_UPDATE, MISSED_DOSE_ALERT, URGENT_PRESCRIPTION_CHANGE, FAMILY_ALERT, VITAL_ANOMALY, EMERGENCY_ALERT, REMINDER_ESCALATION, DOSE_CONFIRMED
AuditActionType: CONNECTION_REQUEST, CONNECTION_ACCEPT, CONNECTION_REVOKE, PERMISSION_CHANGE, PRESCRIPTION_CREATE, PRESCRIPTION_UPDATE, PRESCRIPTION_CONFIRM, PRESCRIPTION_RETAKE, DOSE_TAKEN, DOSE_SKIPPED, DOSE_MISSED, DATA_ACCESS, NOTIFICATION_SENT, SUBSCRIPTION_CHANGE, DOCTOR_NOTE_CREATE, DOCTOR_NOTE_UPDATE, DOCTOR_DISCONNECT, VITAL_RECORDED, EMERGENCY_TRIGGERED
MedicineType: PO, ORAL, INJECTION, TOPICAL, OTHER
MedicineUnit: TABLET, CAPSULE, ML, MG, DROP, OTHER
VitalType: BLOOD_PRESSURE, GLUCOSE, HEART_RATE, WEIGHT, TEMPERATURE, SPO2
AlertSeverity: LOW, MEDIUM, HIGH, CRITICAL
```

---

## 4. Backend Modules & Controllers

### 4.1 Authentication Module (`src/modules/auth/`)

**Controllers**: `auth.controller.ts`

**Endpoints**:
```
POST   /auth/login                 - Email/Phone + Password login
POST   /auth/register/patient      - Patient registration
POST   /auth/register/doctor       - Doctor registration
POST   /auth/otp/send              - Send OTP (SMS/Email)
POST   /auth/otp/verify            - Verify OTP
POST   /auth/refresh               - Refresh JWT token
POST   /auth/google                - Google OAuth (mobile)
GET    /auth/google/callback       - Google OAuth callback
POST   /auth/telegram              - Telegram login (mobile)
GET    /auth/telegram/callback     - Telegram OAuth callback
POST   /auth/forgot-password       - Request password reset
POST   /auth/reset-password        - Reset password with token
POST   /auth/change-password       - Change password (authenticated)
```

**Services**:
- `AuthService`: JWT, password validation, multi-auth strategies
- `OtpService`: OTP generation, storage, verification

**Key Features**:
- JWT + Refresh token system
- Passport strategies: JWT, Google OAuth, Telegram OAuth
- OTP via Email (SendGrid) or SMS (to be implemented)
- Account lockout after 5 failed attempts
- Grace period for password resets

---

### 4.2 Users Module (`src/modules/users/`)

**Endpoints**:
```
GET    /users/me                   - Get current user profile
GET    /users/:id                  - Get user details
PATCH  /users/me                   - Update profile
PATCH  /users/me/preferences       - Update language, theme
GET    /users/search               - Search doctors/patients
GET    /users/:id/patients         - List patients (doctor only)
```

**Services**:
- `UsersService`: User CRUD, profile management, search

---

### 4.3 Connections Module (`src/modules/connections/`)

**Endpoints**:
```
POST   /connections                - Create connection request
GET    /connections                - List connections
GET    /connections/:id            - Get connection details
POST   /connections/:id/accept     - Accept request
POST   /connections/:id/revoke     - Revoke connection
GET    /connection-tokens          - List invite tokens
POST   /connection-tokens          - Generate new token
GET    /doctor-search              - Search available doctors
POST   /connections/token/use      - Use invite token (join patient)
POST   /connections/nudge          - Send nudge reminder
```

**Services**:
- `ConnectionsService`: Manage doctor-patient relationships
- `ConnectionTokenService`: Generate/verify invite tokens
- `NudgeService`: Send reminder nudges

**Key Features**:
- Bidirectional relationship management
- Connection tokens (20-char unique code)
- Permission levels: NOT_ALLOWED, REQUEST, SELECTED, ALLOWED
- Invitation via QR code or token

---

### 4.4 Prescriptions Module (`src/modules/prescriptions/`)

**Endpoints**:
```
GET    /prescriptions               - List prescriptions (patient/doctor)
GET    /prescriptions/:id           - Get prescription details
POST   /prescriptions               - Create prescription (doctor)
POST   /prescriptions/patient       - Create self-prescription (patient from OCR)
PATCH  /prescriptions/:id           - Update prescription (doctor)
POST   /prescriptions/:id/urgent-update - Urgent update (doctor)
POST   /prescriptions/:id/confirm   - Confirm prescription (patient)
POST   /prescriptions/:id/retake    - Retake prescription (patient)
DELETE /prescriptions/:id           - Delete prescription (patient)
POST   /prescriptions/:id/pause     - Pause prescription (patient)
POST   /prescriptions/:id/resume    - Resume prescription (patient)
POST   /prescriptions/:id/reject    - Reject prescription (patient)
```

**Services**:
- `PrescriptionsService`: Full prescription lifecycle management

**Key Features**:
- OCR metadata storage
- Version history tracking
- Draft → Active → Paused → Inactive states
- Urgent update notifications
- Multi-medication support

---

### 4.5 Doses Module (`src/modules/doses/`)

**Endpoints**:
```
GET    /doses/schedule              - Get daily dose schedule
POST   /doses/:id/mark-taken        - Mark dose as taken
POST   /doses/:id/skip              - Skip dose
GET    /doses/history               - Dose history (time range)
GET    /doses/adherence             - Adherence stats
```

**Services**:
- `DosesService`: Schedule management, marking, tracking

**Key Features**:
- Auto-generates dose events from prescription
- Time window logic: TAKEN_ON_TIME vs TAKEN_LATE
- Offline support (wasOffline flag)
- Daily progress calculation
- Grouping by time period (MORNING, AFTERNOON, EVENING, NIGHT)

**Jobs**:
- `MissedDoseJob`: Cron job to mark past due doses as MISSED

---

### 4.6 Health Monitoring Module (`src/modules/health-monitoring/`)

**Endpoints**:
```
GET    /health-monitoring/vitals    - Get vital records
POST   /health-monitoring/vitals    - Record vital (BP, glucose, HR, etc.)
GET    /health-monitoring/thresholds - Get alert thresholds
PATCH  /health-monitoring/thresholds - Update thresholds
GET    /health-monitoring/alerts    - Get health alerts
POST   /health-monitoring/emergency - Trigger emergency
```

**Services**:
- `HealthMonitoringService`: Vital tracking, threshold alerts

**Key Features**:
- Support for 6 vital types: Blood Pressure, Glucose, Heart Rate, Weight, Temperature, SPO2
- Automatic anomaly detection
- Threshold-based alerts (4 severity levels)
- Emergency alert system

---

### 4.7 OCR Module (`src/modules/ocr/`)

**Endpoints**:
```
POST   /ocr/scan                    - Upload & scan prescription (create)
POST   /ocr/extract                 - Extract only (preview)
GET    /ocr/health                  - Check OCR service status
```

**Services**:
- `OcrService`: Communication with Python OCR service, AI enhancement

**Key Features**:
- Image upload (10MB max)
- Formats: PNG, JPG, JPEG, WebP, PDF
- OCR extraction via Python service
- AI enhancement via LLM service
- Automatic prescription creation
- Error handling with fallback to raw OCR

---

### 4.8 Bakong Payment Module (`src/modules/bakong-payment/`)

**Endpoints**:
```
POST   /bakong-payment/create       - Create payment
GET    /bakong-payment/status/:md5  - Check status
POST   /bakong-payment/webhook      - Bakong webhook
GET    /bakong-payment/history      - Payment history
```

**Services**:
- `BakongPaymentService`: KHQR code generation, payment monitoring

---

### 4.9 Notifications Module (`src/modules/notifications/`)

**Endpoints**:
```
GET    /notifications               - List notifications
PATCH  /notifications/:id/read      - Mark as read
```

**Services**:
- `NotificationsService`: Notification creation, delivery

**Key Features**:
- 9 notification types
- Push notifications (Firebase Cloud Messaging)
- Email notifications (SendGrid)
- In-app notifications (persistent)

---

### 4.10 Other Modules

- **AuditModule**: Audit log creation & querying
- **EmailModule**: SendGrid integration, email templates
- **SubscriptionsModule**: Subscription tier management
- **DoctorDashboardModule**: Doctor-specific analytics & notes
- **MedicinesModule**: Medicine database/catalog
- **AdherenceModule**: Adherence metrics & reporting
- **BatchMedicationModule**: Medication batch/time-based grouping

---

## 5. Bakong Payment Service (Microservice)

**Location**: `/bakong_payment`
**Framework**: NestJS 10.3.0
**Port**: 3002
**Database**: Separate PostgreSQL instance (bakong_payment schema)

### 5.1 Database Schema

**PaymentTransaction**
```sql
- id (UUID, PK)
- userId (UUID)
- billNumber (UNIQUE) - Invoice number
- md5Hash (UNIQUE) - QR code hash
- amount (Decimal)
- currency (USD)
- status (PENDING, PAID, FAILED, TIMEOUT, EXPIRED, CANCELLED)
- planType (PREMIUM, FAMILY_PREMIUM)
- qrCode (String - KHQR)
- qrImagePath (path to saved QR image)
- deepLink (Bakong app link)
- isUpgrade, isRenewal (Boolean)
- proratedAmount (Decimal, nullable)
- bakongData (JSON - Bakong API response)
- checkAttempts (Int)
- lastCheckedAt (DateTime)
- timestamps: createdAt, updatedAt, paidAt, expiredAt
- Relations: subscription, statusHistory
```

**PaymentStatusHistory**
```sql
- id (UUID, PK)
- transactionId → PaymentTransaction
- oldStatus, newStatus (PaymentStatus)
- reason (String)
- metadata (JSON)
- timestamps: createdAt
```

**Subscription**
```sql
- id (UUID, PK)
- userId (UNIQUE) (UUID)
- planType (PREMIUM, FAMILY_PREMIUM)
- status (PENDING, ACTIVE, EXPIRED, CANCELLED)
- startDate, nextBillingDate, lastBillingDate
- cancelledAt, cancellationReason
- timestamps: createdAt, updatedAt
- Relations: payments, statusHistory
```

**SubscriptionStatusHistory**
```sql
- Similar to PaymentStatusHistory
```

**WebhookNotification**
```sql
- id (UUID, PK)
- event (WebhookEvent)
- targetUrl (String)
- payload (JSON)
- signature (String)
- status (PENDING, DELIVERED, FAILED)
- attempts (Int)
- lastAttemptAt, nextRetryAt (DateTime)
- responseStatus (Int), responseBody (String), errorMessage (String)
- timestamps: createdAt, updatedAt, deliveredAt
```

**AuditLog**
```sql
- id, userId, action, resourceType, resourceId, details, ipAddress, userAgent, createdAt
```

### 5.2 Controllers & Routes

**PaymentController**:
```
POST   /api/payments/create              - Create payment + QR
GET    /api/payments/status/:md5         - Check payment status
GET    /api/payments/history             - Get payment history
POST   /api/payments/monitor             - Monitor payment status
GET    /api/payments/:transactionId      - Get transaction details
```

**SubscriptionController**:
```
GET    /api/subscriptions                - Get user subscription
POST   /api/subscriptions/activate       - Activate subscription
POST   /api/subscriptions/cancel         - Cancel subscription
GET    /api/subscriptions/plans          - List available plans
```

**HealthController**:
```
GET    /api/health                       - Service health check
```

### 5.3 Key Flow

```
1. Frontend calls POST /bakong-payment/create {userId, planType, amount}
   ↓
2. Service generates KHQR code, MD5 hash
   ↓
3. Payment saved with PENDING status
   ↓
4. QR image generated & stored in public/qr-codes/
   ↓
5. Return: transactionId, qrCode, qrImagePath, deepLink
   ↓
6. Frontend displays QR code, user scans with Bakong app
   ↓
7. User completes payment
   ↓
8. Bakong webhook hits POST /api/payments/webhook
   ↓
9. Payment status updated to PAID
   ↓
10. Subscription activated in main backend
```

---

## 6. OCR Service (Python FastAPI)

**Location**: `/ocr`
**Language**: Python 3.11+
**Framework**: FastAPI
**Port**: 8000 (or 8003 in Docker)
**OCR Engine**: Kiri-OCR (for Khmer + English)

### 6.1 Architecture

```
FastAPI App
    ↓
Router (api/routes.py)
    ├── POST /api/v1/extract
    ├── GET /api/v1/health
    └── GET /api/v1/config
    ↓
Pipeline.Orchestrator (performs full extraction)
    ├── Preprocessor (image enhancement)
    ├── OCREngine (Kiri-OCR)
    ├── LayoutAnalyzer (table/region detection)
    ├── TextParser (parse into structured form)
    └── Formatter (build response JSON)
```

### 6.2 Key Components

**ocr_engine.py**
- Loads Kiri-OCR model
- `extract()` method returns (full_text, line_results)
- Supports Khmer + English text

**orchestrator.py**
- Main pipeline orchestrator
- Coordinates: Preprocessor → OCREngine → Parser → Formatter
- Returns structured prescription data

**preprocessor.py**
- Image normalization
- Orientation detection
- Contrast enhancement
- Max dimension constraints

**layout.py**
- Table detection
- Region segmentation
- Logical grouping of text

**text_parser.py**
- Parse raw OCR text into structured form
- Extract: Patient info, medications (name, dosage, frequency), diagnosis, prescriber
- Handles Khmer drug names

**formatter.py**
- Build dynamic prescription structure
- Create extraction summary (confidence score)
- Add metadata (image dimensions, processing time)

### 6.3 API Response Model

```json
{
  "success": true,
  "data": {
    "prescription": {
      "patient": {
        "name": "String",
        "age": Int,
        "gender": "M|F|O",
        "patient_id": "String (optional)"
      },
      "prescriber": {
        "name": "String",
        "license_number": "String (optional)",
        "hospital_clinic": "String (optional)"
      },
      "medications": {
        "items": [
          {
            "item_number": Int,
            "brand_name": "String",
            "generic_name": "String",
            "strength": "String",
            "unit": "TABLET|CAPSULE|ML|MG|DROP",
            "dosage": Float,
            "frequency": "String",
            "duration": Int (days, optional),
            "timing": "MORNING|AFTERNOON|EVENING|NIGHT",
            "before_meal": Boolean,
            "is_prn": Boolean,
            "additional_note": "String (optional)"
          }
        ],
        "count": Int
      },
      "diagnosis": ["String"],
      "follow_up_date": "YYYY-MM-DD (optional)",
      "clinical_note": "String (optional)"
    }
  },
  "extraction_summary": {
    "total_medications": Int,
    "confidence_score": Float (0-1),
    "extraction_quality": "GOOD|FAIR|POOR",
    "processing_time_ms": Int,
    "flags": ["String (warnings)"]
  }
}
```

---

## 7. AI-LLM Service (Python FastAPI)

**Location**: `/ai-llm-service`
**Language**: Python 3.11+
**Framework**: FastAPI
**Port**: 8001
**LLM Provider**: Ollama (local) or OpenRouter (cloud)

### 7.1 Architecture

```
FastAPI App
    ↓
Router (api/extraction_routes.py)
    ├── POST /api/v1/enhance          (OCR enhancement)
    ├── POST /api/v1/correct          (Text correction)
    ├── POST /api/v1/validate         (Prescription validation)
    ├── POST /api/v1/generate-reminders (Reminder generation)
    ├── POST /api/v1/chat             (Chatbot)
    └── GET /api/v1/health
    ↓
LLMClient (core/llm_client.py or ollama_client.py)
    ├── Ollama (local inference)
    └── OpenRouter (cloud inference)
    ↓
Safety Checks
    ├── MedicalSafetyCheck
    ├── LanguageDetection
    └── DrugAdviceRefusal
    ↓
Features
    ├── PrescriptionProcessor
    ├── PrescriptionValidator
    ├── PrescriptionEnhancer
    └── ReminderGenerator
```

### 7.2 Key Endpoints

```
POST /api/v1/enhance
Request:
{
  "ocr_result": {...}  // Raw OCR extraction
}
Response:
{
  "success": true,
  "ai_enhanced": true,
  "enhanced": {
    "medications": [
      {
        "item_number": Int,
        "corrected_brand_name": "String",
        "corrected_generic_name": "String",
        "strength": "String",
        "was_corrected": Boolean
      }
    ],
    "patient": {
      "name": "String",
      "age": Int,
      "gender": "String"
    },
    "prescriber_name": "String",
    "diagnoses": ["String"],
    "prescription_date": "YYYY-MM-DD"
  }
}

POST /api/v1/validate
Request: { "prescription_data": {...} }
Response:
{
  "safe": Boolean,
  "warnings": ["String"],
  "errors": ["String"]
}

POST /api/v1/generate-reminders
Request: { "prescription": {...} }
Response:
{
  "reminders": [
    {
      "medication": "String",
      "time": "HH:MM",
      "message": "String"
    }
  ]
}

POST /api/v1/chat
Request: { "message": "String", "prescription_context": {...} }
Response:
{
  "message": "String",
  "is_safe_response": Boolean
}
```

### 7.3 Safety Features

- **Medical Safety**: Refuses diagnosis requests, drug advice requests
- **Language Detection**: Supports Khmer + English
- **Prescription Validation**: Checks for drug interactions (basic)
- **Safe Refusal**: Polite rejection of medical requests outside scope

---

## 8. Configuration & Environment

### 8.1 Docker Compose Services

```yaml
Services:
├── postgres:17             # PostgreSQL 17
├── redis:7.4              # Redis cache
├── rabbitmq:4.0           # Message queue
├── minio:latest           # S3-compatible storage
├── backend:3001           # NestJS backend (commented by default)
├── bakong-payment:3002    # Payment service
├── ocr:8003               # OCR service
└── ai-llm:8001            # AI-LLM service

Volumes:
├── postgres_data
├── redis_data
├── rabbitmq_data
└── minio_data

Network: dastern-network (bridge)
```

### 8.2 Key Environment Variables

**Backend (.env)**
```
# Database
DATABASE_URL=postgresql://dastern_user:dastern_rayu@localhost:5432/dastern?schema=public
POSTGRES_USER=dastern_user
POSTGRES_PASSWORD=dastern_rayu

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=dastern_redis_password

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production-min-32-chars
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Google OAuth
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...

# SendGrid Email
SENDGRID_API_KEY=...
SENDGRID_FROM_EMAIL=noreply@dastern.com

# Service URLs (Docker internal)
OCR_SERVICE_URL=http://localhost:8003
AI_SERVICE_URL=http://localhost:8001
BAKONG_SERVICE_URL=http://localhost:3002

# Other
NODE_ENV=development
PORT=3001
HOST=0.0.0.0
API_PREFIX=api/v1
```

**Bakong Payment (.env)**
```
DATABASE_URL=postgresql://...
PORT=3002
BAKONG_API_KEY=...
BAKONG_WEBHOOK_SECRET=...
```

**OCR (.env)**
```
PORT=8000
OCR_MODEL=kiri_ocr
MAX_UPLOAD_SIZE_MB=10
PREPROCESS_MAX_DIMENSION=2048
```

**AI-LLM (.env)**
```
PORT=8001
LLM_PROVIDER=ollama|openrouter
OLLAMA_ENDPOINT=http://localhost:11434
OPENROUTER_API_KEY=...
MODEL_NAME=llama2|neural-chat|...
```

---

## 9. API Flow & Interaction

### 9.1 Prescription Creation Flow (OCR)

```
1. Patient logs in → JWT token
2. Frontend: POST /ocr/extract { prescription image }
3. Backend/OcrService:
   a. Validate file (size, format)
   b. Call Python OCR: POST http://ocr:8000/api/v1/extract
   c. OCR returns: medications, patient info, diagnosis
   d. Call AI-LLM: POST http://ai-llm:8001/api/v1/enhance
   e. AI returns: corrected drug names, validated prescriber
   f. Merge results (OCR + AI enhancement)
   g. Return structured prescription to frontend
4. Frontend: Review prescription, click "Create"
5. Backend: POST /prescriptions/patient
   a. Create Prescription record (DRAFT status)
   b. Create Medication records (one per item)
   c. Generate DoseEvents for each medication
   d. Send notification: "Prescription created"
6. Patient starts tracking doses

```

### 9.2 Dose Marking Flow

```
1. Patient: GET /doses/schedule?date=2024-01-15
   Returns: [DoseEvent, DoseEvent, ...]
2. Patient: POST /doses/{doseId}/mark-taken
   a. Calculate time window (on-time vs late)
   b. Update DoseEvent.status
   c. Update DoseEvent.takenAt
   d. Trigger: NotificationsService.sendDoseConfirmation
   e. Calculate daily progress
   f. If adherence < threshold: Send alert to connected doctor
3. Doctor: GET /doctor-dashboard/patients/{patientId}
   Returns: Adherence stats, missed doses, vital anomalies

```

### 9.3 Connection Flow (Doctor-Patient)

```
1. Patient: POST /connections/token/generate
   Returns: token (20-char unique code)
2. Patient shares token via QR code / messaging
3. Doctor: POST /connections { targetUserId: patientId }
   OR Doctor: POST /connections/token/use { token }
4. Patient: GET /connections (shows PENDING)
5. Patient: POST /connections/{connectionId}/accept
6. Both: Connection status → ACCEPTED
7. Doctor: GET /connections (can now see patient's prescriptions)
8. Doctor: POST /prescriptions { patientId, medications, ... }
9. Patient: GET /prescriptions (sees doctor's prescription)
10. Patient: POST /prescriptions/{prescriptionId}/confirm
11. Doses auto-generated from prescription schedule

```

### 9.4 Payment Flow

```
1. Patient: Clicks "Upgrade to Premium"
2. Frontend: POST /bakong-payment/create { userId, planType: "PREMIUM", amount: 0.50 }
3. Bakong Service:
   a. Generate bill number & MD5 hash
   b. Create KHQR code
   c. Save QR image to public/qr-codes/
   d. Create PaymentTransaction (PENDING)
   e. Return: qrCode, qrImagePath, deepLink
4. Frontend: Display QR code + Bakong deep link
5. User: Scans QR with Bakong app → completes payment
6. Bakong: Sends webhook POST /api/payments/webhook
7. Bakong Service:
   a. Verify signature
   b. Update PaymentTransaction → PAID
   c. Call backend: Update Subscription tier
8. Backend:
   a. Update User.subscription.tier = PREMIUM
   b. Send notification: "Upgrade successful"
9. Frontend: Show success page

```

---

## 10. Data Flow Diagram

```
┌─────────────────┐
│   Client (Web)  │
│   Flutter App   │
└────────┬────────┘
         │
         │ HTTP/HTTPS
         ▼
    ┌─────────────────────────────────────────┐
    │    Nginx Reverse Proxy                  │
    │    (Port 80/443)                        │
    └────────┬────────┬───────────┬──────────┘
             │        │           │
             ▼        ▼           ▼
    ┌──────────────┐  ┌────────┐  ┌──────────────┐
    │ Backend      │  │Bakong  │  │  OCR/AI      │
    │ NestJS       │  │Payment │  │  Services    │
    │ Port: 3001   │  │Port:3002   │Port:8000/8001
    └──────┬───────┘  └────────┘  └──────────────┘
           │
    ┌──────┴──────────────────────────────────┐
    │                                          │
    ▼                                          ▼
┌─────────────────────────┐      ┌──────────────────────┐
│   PostgreSQL 17         │      │   Redis 7.4          │
│   (Main Database)       │      │   (Cache + Sessions) │
│   - Users              │      │                      │
│   - Prescriptions      │      │                      │
│   - Doses              │      │                      │
│   - Connections        │      │                      │
│   - Vitals             │      │                      │
│   - Audit Logs         │      │                      │
└─────────────────────────┘      └──────────────────────┘

Separate Systems:
    ┌──────────────────────┐
    │  RabbitMQ 4.0        │
    │  (Message Queue)     │
    │  - Jobs              │
    │  - Async Tasks       │
    └──────────────────────┘

    ┌──────────────────────┐
    │  MinIO               │
    │  (S3-compatible)     │
    │  - Prescriptions     │
    │  - Profile Pictures  │
    │  - QR Codes          │
    └──────────────────────┘

    ┌──────────────────────┐
    │  SendGrid            │
    │  (Email)             │
    │  - OTP               │
    │  - Alerts            │
    └──────────────────────┘
```

---

## 11. Key Technologies Stack

```
Backend:
  - NestJS 10.3.0 (Framework)
  - Prisma 6.2.0 (ORM)
  - TypeScript 5.7.2
  - PostgreSQL 17
  - Redis 7.4
  - RabbitMQ 4.0
  - Bull (Job Queue)
  - Passport (Authentication)
  - JWT (Authorization)
  - Helmet (Security)
  - Compression
  - SendGrid (Email)

Microservices:
  - NestJS (Bakong Payment)
  - FastAPI (OCR, AI-LLM)
  - Python 3.11+

OCR:
  - Kiri-OCR (Khmer + English)
  - Pillow (Image processing)
  - FastAPI

AI:
  - Ollama (Local LLM inference)
  - OpenRouter (Cloud LLM)
  - FastAPI
  - Pydantic (Data validation)

Infrastructure:
  - Docker + Docker Compose
  - Nginx (Reverse Proxy)
  - MinIO (S3)
  - PostgreSQL (Database)

Other:
  - Passport.js (Auth strategies)
  - bcryptjs (Password hashing)
  - UUID (ID generation)
  - date-fns (Date manipulation)
  - Axios (HTTP client)
  - Form-data (Multipart uploads)
```

---

## 12. Security Features

1. **Authentication**
   - JWT tokens with expiry
   - Refresh token rotation
   - Multi-auth strategies (email/phone, Google, Telegram)
   - OTP verification

2. **Authorization**
   - Role-based access control (RBAC)
   - Permission levels for connections
   - Scope-based data access

3. **Data Protection**
   - Password hashing (bcryptjs)
   - Encryption for sensitive fields (optional)
   - HTTPS/SSL in production

4. **Rate Limiting**
   - Throttler guard
   - Per-endpoint limits
   - Login attempt lockout

5. **Input Validation**
   - Global validation pipe
   - DTO-based validation (class-validator)
   - Sanitization

6. **Audit Logging**
   - Track all user actions
   - Immutable audit trail
   - Timestamp + IP tracking

7. **CORS**
   - Restricted origins
   - Credentials support
   - Method whitelist

---

## 13. Deployment

### Production Docker Compose
- File: `/docker-compose.prod.yml`
- All services containerized
- Health checks for reliability
- Restart policies

### Nginx Configuration
- File: `/nginx/nginx.conf`
- Reverse proxy
- SSL termination
- Load balancing (optional)

### Environment
- `.env.example` → `.env` (production secrets)
- Database migrations via Prisma
- Redis persistence
- MinIO bucket initialization

---

## 14. Future Enhancements

1. **Microservices**
   - Separate user service
   - Separate prescription service
   - Message-driven architecture

2. **Scalability**
   - Horizontal scaling (multiple backend instances)
   - Database read replicas
   - Caching layer optimization

3. **Features**
   - Video consultations
   - Integration with pharmacy systems
   - Wearable device integration
   - Advanced analytics

4. **Performance**
   - GraphQL API
   - Real-time updates (WebSockets)
   - CDN for static assets

---

## Summary

Das-Tern backend is a modern, modular, microservice-ready healthcare application built with NestJS. It manages:

- **User Management**: Multi-role authentication, profiles, connections
- **Prescription Management**: OCR scanning, AI enhancement, versioning
- **Medication Tracking**: Dose scheduling, adherence monitoring, alerts
- **Health Monitoring**: Vital signs tracking, anomaly detection
- **Doctor-Patient Relationships**: Secure data sharing, permissions
- **Payment Processing**: KHQR-based Bakong integration
- **Notifications**: Multi-channel (in-app, email, push)
- **Audit Trail**: Comprehensive action logging

The architecture supports horizontal scaling, async processing, and integration with multiple microservices (OCR, AI, Payments).

