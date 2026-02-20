# DAS-TERN Backend Architecture Documentation

> **Enterprise-Grade Medication Management Platform Backend**  
> Built with NestJS, PostgreSQL, Redis, and modern cloud-native practices

---

## 📑 Table of Contents

1. [System Overview](#system-overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Service Architecture](#service-architecture)
4. [Database Architecture](#database-architecture)
5. [Infrastructure & DevOps](#infrastructure--devops)
6. [External Services Integration](#external-services-integration)
7. [Data Flow & Communication](#data-flow--communication)
8. [Security Architecture](#security-architecture)
9. [Deployment Model](#deployment-model)
10. [Scalability & Performance](#scalability--performance)

---

## 1. System Overview

### Purpose
DAS-TERN Backend is a comprehensive REST API server that manages:
- User authentication and authorization
- Patient-doctor connections and relationships
- Medical prescriptions and medication tracking
- Medication adherence monitoring
- Health monitoring and vital signs
- Payment processing (Bakong integration)
- Email notifications and communications
- Audit logging and compliance
- OCR-based prescription scanning
- Medication batch management

### Core Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Framework** | NestJS | ^10.3.0 |
| **Runtime** | Node.js | >=22.0.0 |
| **Language** | TypeScript | ^5.7.2 |
| **Primary DB** | PostgreSQL | 17 |
| **Cache Layer** | Redis | 7.4 |
| **ORM** | Prisma | ^6.2.0 |
| **Auth** | Passport.js + JWT | - |
| **Container** | Docker | Latest |

### Key Characteristics
- ✅ **Type-Safe**: Full TypeScript with strict mode
- ✅ **Modular**: 16 independent feature modules
- ✅ **Scalable**: Horizontal scaling ready
- ✅ **Secure**: Multi-layer security (JWT, RBAC, encryption)
- ✅ **Observable**: Comprehensive audit logging
- ✅ **Resilient**: Error handling, retries, circuit breakers
- ✅ **Performant**: Caching, connection pooling, query optimization

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER (External)                      │
├─────────────────────────────────────────────────────────────────┤
│ Flutter Mobile App | Web Client | External Systems              │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTPS
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                  API GATEWAY & ROUTING                          │
│  (NestJS HTTP Server, Rate Limiting, Request Validation)        │
└──────────────────────────────┬──────────────────────────────────┘
                               │
          ┌────────────────────┼─────────────────────────┐
          ↓                    ↓                         ↓
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  AUTH & SECURITY │ │  CORE SERVICES   │ │  EXTERNAL SVCS   │
│  - JWT Tokens    │ │  - Prescriptions │ │  - Email (SMTP)  │
│  - OAuth Google  │ │  - Health Mgmt   │ │  - OCR Service   │
│  - RBAC Guards   │ │  - Adherence     │ │  - Bakong Payment│
└────────┬─────────┘ └────────┬─────────┘ └────────┬─────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    DATA PERSISTENCE LAYER                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────┐    ┌──────────────────────┐           │
│  │  PostgreSQL 17       │    │  Redis Cache 7.4     │           │
│  │  (Primary Database)  │    │  (Session & Cache)   │           │
│  │  - Persistent Data   │    │  - Session Storage   │           │
│  │  - Transactions      │    │  - Rate Limit Buckets│           │
│  │  - ACID Compliance   │    │  - Real-time Cache   │           │
│  └──────────────────────┘    └──────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Service Architecture

### 3.1 Modular Service Design

The backend is built on 16 independent feature modules, each handling a specific business domain:

#### 🔐 **Authentication & Authorization Module**
```
auth/
├── auth.service.ts        # JWT generation, validation, OAuth
├── auth.controller.ts     # Login, logout, token refresh
├── strategies/
│   ├── jwt.strategy.ts    # JWT validation strategy
│   └── google.strategy.ts # Google OAuth strategy
├── dto/
│   ├── login.dto.ts
│   ├── signup.dto.ts
│   └── refresh-token.dto.ts
└── otp.service.ts         # One-time password for 2FA
```

**Responsibilities:**
- User login/signup with email or Google OAuth
- JWT token generation and validation
- Password hashing and verification
- OTP generation and verification
- Session management via Redis
- Token refresh mechanism

**Key Flows:**
```
Mobile App → Login Request → Auth Service → Validate Credentials
                                              ↓
                              Generate JWT Token → Store in Redis
                                              ↓
                              Return Token to App
```

---

#### 👥 **Users Module**
```
users/
├── users.service.ts       # User CRUD, profile management
├── users.controller.ts    # HTTP endpoints
├── dto/
│   ├── create-user.dto.ts
│   ├── update-user.dto.ts
│   └── user-profile.dto.ts
└── users.repository.ts    # Database queries
```

**Responsibilities:**
- Create, read, update, delete user accounts
- User profile management
- Role assignment (PATIENT, DOCTOR, ADMIN)
- User metadata and preferences
- Account activation and deactivation

**Database Schema:**
```sql
User {
  id: UUID PRIMARY KEY
  email: VARCHAR UNIQUE NOT NULL
  firstName: VARCHAR
  lastName: VARCHAR
  password: VARCHAR (hashed)
  role: ENUM (PATIENT, DOCTOR, ADMIN)
  googleId: VARCHAR NULLABLE
  isActive: BOOLEAN
  createdAt: TIMESTAMP
  updatedAt: TIMESTAMP
}
```

---

#### 🏥 **Doctor-Patient Connections Module**
```
connections/
├── connections.service.ts       # Connection management
├── connections.controller.ts    # HTTP endpoints
├── dto/
│   ├── create-connection.dto.ts
│   └── connection-list.dto.ts
└── connection-tokens.service.ts # Secure connection tokens
```

**Responsibilities:**
- Establish patient-doctor relationships
- Manage connection requests and approvals
- Generate secure connection tokens
- Attribute access rights between doctor and patient
- Connection history tracking

**Connection Flow:**
```
Patient → Send Connection Request → Doctor Receives Request
         ↓                                    ↓
      Approve/Reject → Token Generated → Mobile App Stores Token
         ↓
   Doctor can access patient's prescriptions & health data
```

---

#### 💊 **Prescriptions Module**
```
prescriptions/
├── prescriptions.service.ts     # Prescription logic
├── prescriptions.controller.ts  # HTTP endpoints
├── dto/
│   ├── create-prescription.dto.ts
│   ├── update-prescription.dto.ts
│   └── prescription-list.dto.ts
└── prescription.repository.ts
```

**Responsibilities:**
- CRUD operations on prescriptions
- Prescription status management (DRAFT, ACTIVE, EXPIRED, COMPLETED)
- Medication dosage schedules
- Access control (only assigned doctor can modify)
- Prescription history and audit

**Database Schema:**
```sql
Prescription {
  id: UUID PRIMARY KEY
  patientId: UUID FOREIGN KEY
  doctorId: UUID FOREIGN KEY
  medicineId: UUID FOREIGN KEY
  dosage: VARCHAR
  frequency: VARCHAR
  startDate: DATE
  endDate: DATE
  status: ENUM (DRAFT, ACTIVE, EXPIRED, COMPLETED)
  notes: TEXT
  createdAt: TIMESTAMP
  updatedAt: TIMESTAMP
}
```

---

#### 📊 **Doses & Adherence Tracking Module**
```
doses/
├── doses.service.ts       # Dose records
├── doses.controller.ts
└── dose.repository.ts

adherence/
├── adherence.service.ts   # Adherence analytics
├── adherence.controller.ts
└── adherence.repository.ts
```

**Responsibilities:**
- Record when medications were taken
- Track adherence rates
- Calculate adherence metrics
- Generate adherence reports
- Identify missed doses

**Adherence Metrics:**
```
Adherence Rate = (Doses Taken / Expected Doses) × 100%

Track:
- Daily adherence
- Weekly adherence
- Monthly adherence
- Trend analysis
```

---

#### ❤️ **Health Monitoring Module**
```
health-monitoring/
├── health-monitoring.service.ts
├── health-monitoring.controller.ts
├── dto/
│   ├── vital-signs.dto.ts
│   ├── health-record.dto.ts
│   └── health-analytics.dto.ts
└── vital-signs.repository.ts
```

**Responsibilities:**
- Store vital signs (blood pressure, heart rate, temperature, etc.)
- Health record management
- Health analytics and trends
- Alert generation for abnormal values
- Health history retrieval

**Tracked Vital Signs:**
- Blood Pressure (Systolic/Diastolic)
- Heart Rate (BPM)
- Temperature (°C)
- Blood Sugar (mg/dL)
- Oxygen Saturation (SpO2)
- Weight (kg)
- Height (cm)

---

#### 🔔 **Notifications & Email Module**
```
notifications/
├── notifications.service.ts
├── notifications.controller.ts
├── notification.repository.ts
└── notification-queue.ts

email/
├── email.service.ts       # SMTP integration
├── email.controller.ts
├── templates/
│   ├── welcome.template.ts
│   ├── prescription.template.ts
│   ├── appointment.template.ts
│   └── alert.template.ts
└── email.repository.ts
```

**Responsibilities:**
- Send email notifications via SMTP
- Store notification history
- Push notifications (future: Firebase Cloud Messaging)
- Notification preferences management
- Email templating and rendering
- Retry logic for failed sends

**Email Templates:**
- Welcome email
- Prescription shared notification
- Appointment reminders
- Health alert notifications
- Password reset
- Account verification

---

#### 💳 **Bakong Payment Integration Module**
```
bakong-payment/
├── bakong-payment.service.ts   # Bakong API calls
├── bakong-payment.controller.ts
├── bakong-payment.dto.ts
├── payment-encryption.service.ts
├── payment.repository.ts
└── payment-webhook.handler.ts
```

**Responsibilities:**
- Initiate payment requests to Bakong
- Generate QR codes for payments
- Process payment callbacks
- Store payment records
- Transaction history
- Refund handling

**Payment Flow:**
```
1. Mobile App → Backend: Create Payment Request
2. Backend → Bakong Service: Encrypted Payload
3. Bakong Service → Bakong API: Generate QR Code
4. Backend → Mobile App: Return QR Code
5. User Scans QR → Makes Payment via Bakong
6. Bakong → Bakong Service: Payment Notification
7. Bakong Service → Backend: Confirm Payment
8. Backend → PostgreSQL: Update Payment Status
9. Backend → Mobile App: Confirm Success
```

---

#### 🏥 **Doctor Dashboard Module**
```
doctor-dashboard/
├── doctor-dashboard.service.ts
├── doctor-dashboard.controller.ts
└── dashboard.repository.ts
```

**Responsibilities:**
- Aggregate data for doctor view
- Patient list for connected doctors
- Medication history of patients
- Health metrics summaries
- Adherence reports
- Alert management

---

#### 💊 **Medicines Module**
```
medicines/
├── medicines.service.ts
├── medicines.controller.ts
├── medicine.repository.ts
└── dto/
    ├── create-medicine.dto.ts
    └── medicine-list.dto.ts
```

**Responsibilities:**
- Maintain medicine database
- Medicine metadata (dosage forms, strengths)
- Medicine search and filtering
- Medicine interactions checking
- Medicine categories

---

#### 📦 **Batch Medication Module**
```
batch-medication/
├── batch-medication.service.ts
├── batch-medication.controller.ts
└── batch.repository.ts
```

**Responsibilities:**
- Batch prescribe medications to multiple patients
- Bulk operations
- Batch status tracking
- Batch history and audit

---

#### 📝 **OCR Service Integration Module**
```
ocr/
├── ocr.service.ts        # OCR processing
├── ocr.controller.ts
├── ocr-webhook.handler.ts
└── prescription-parser.ts
```

**Responsibilities:**
- Accept prescription images from mobile app
- Send images to external OCR service
- Parse OCR results
- Extract medication details
- Create prescription from OCR data
- Handle OCR failures and retries

**OCR Flow:**
```
Mobile App → Upload Prescription Image → Backend OCR Service
    ↓                                            ↓
Stores Image    ←→ External OCR API ← Extract Text & Metadata
    ↓
Generate Structured Prescription Data
    ↓
Return to Mobile App for Confirmation
```

---

#### 📋 **Audit Module**
```
audit/
├── audit.service.ts              # Audit logging
├── audit.controller.ts
├── audit-interceptor.ts          # Automatic audit on all requests
├── audit.repository.ts
└── dto/
    └── audit-log.dto.ts
```

**Responsibilities:**
- Log all data modifications
- Track who did what and when
- Store action history
- Compliance reporting
- User activity tracking

**Audit Tracking:**
```
Every Request → Interceptor Captures:
  - User ID
  - Action Type (CREATE, READ, UPDATE, DELETE)
  - Resource Type
  - Resource ID
  - Changes Made (before/after)
  - IP Address
  - User Agent
  - Timestamp
  - Status Code

→ Stored in PostgreSQL for compliance
```

---

#### 💳 **Subscriptions Module**
```
subscriptions/
├── subscriptions.service.ts
├── subscriptions.controller.ts
└── subscription.repository.ts
```

**Responsibilities:**
- Manage subscription plans
- Subscription lifecycle (active, cancelled, expired)
- Payment integration for subscriptions
- Subscription renewal
- Feature entitlements

---

### 3.2 Service Interaction Map

```
                    ┌─────────────┐
                    │   AuthMod   │
                    └─────┬───────┘
                          │
           ┌──────────────┼──────────────┐
           ↓              ↓              ↓
      ┌────────┐  ┌──────────────┐ ┌──────────┐
      │ Users  │  │ Connections  │ │ AuditMod │
      └─────┬──┘  └──────┬───────┘ └──────────┘
            │            │
    ┌───────┴────────────┴───────────┐
    │                                 │
    ↓                                 ↓
┌──────────────┐            ┌─────────────────┐
│ Prescriptions│            │ Doctor Dashboard│
└──────┬───────┘            └────────┬────────┘
       │                             │
   ┌───┴────────┬────────────────────┴──────┐
   ↓            ↓                           ↓
┌──────┐   ┌────────┐   ┌────────┐   ┌──────────┐
│Doses │   │ Health │   │ Medicines  │ Adherence│
│      │   │Monitoring│   │      │   │         │
└──────┘   └────────┘   └──────────┘ └──────────┘
   │            │              │           │
   └────────────┴──────────────┴───────────┘
                      │
        ┌─────────────┼─────────────┐
        ↓             ↓             ↓
    ┌────────┐  ┌─────────┐  ┌──────────┐
    │ Email  │  │ Notify  │  │ Payment  │
    └────────┘  └─────────┘  └──────────┘
        │             │           │
        └─────────────┴───────────┘
                      │
               ┌──────┴──────┐
               ↓             ↓
        ┌──────────┐  ┌──────────┐
        │ OCR      │  │ Batch    │
        │ Service  │  │ Meds     │
        └──────────┘  └──────────┘
```

---

## 4. Database Architecture

### 4.1 PostgreSQL Structure

**Database Server:**
- **Type**: PostgreSQL 17 (Alpine container)
- **Container Name**: `dastern-postgres-nestjs`
- **Storage**: Persistent volume `postgres_data`
- **Port**: 5432 (internal network only)
- **Environment**: Docker-based, not exposed to public

**Connection Details:**
```yaml
Host: postgres (Docker network DNS)
Port: 5432
Database: dastern
User: dastern_user
Password: [from .env]
SSL Mode: require (for production)
Connection Pool: 10 (Prisma)
```

### 4.2 Core Data Models

```sql
┌─────────────────────────────────────────────────────────┐
│                   USER MANAGEMENT                       │
├─────────────────────────────────────────────────────────┤

TABLE Users {
  id: UUID PRIMARY KEY
  email: VARCHAR UNIQUE NOT NULL
  firstName: VARCHAR
  lastName: VARCHAR
  passwordHash: VARCHAR (bcrypt)
  role: ENUM (PATIENT, DOCTOR, ADMIN)
  googleId: VARCHAR NULLABLE (for OAuth)
  isActive: BOOLEAN DEFAULT true
  lastLogin: TIMESTAMP NULLABLE
  createdAt: TIMESTAMP DEFAULT now()
  updatedAt: TIMESTAMP DEFAULT now()
}

TABLE Connections {
  id: UUID PRIMARY KEY
  patientId: UUID FOREIGN KEY → Users
  doctorId: UUID FOREIGN KEY → Users
  status: ENUM (PENDING, ACTIVE, REVOKED)
  connectionToken: VARCHAR UNIQUE
  tokenExpiresAt: TIMESTAMP
  createdAt: TIMESTAMP
  updatedAt: TIMESTAMP
}
```

```sql
┌─────────────────────────────────────────────────────────┐
│               MEDICAL MANAGEMENT                        │
├─────────────────────────────────────────────────────────┤

TABLE Medicines {
  id: UUID PRIMARY KEY
  name: VARCHAR NOT NULL
  description: TEXT
  category: VARCHAR
  dosageForm: VARCHAR (tablet, liquid, etc.)
  strength: VARCHAR
  manufacturer: VARCHAR
  createdAt: TIMESTAMP
}

TABLE Prescriptions {
  id: UUID PRIMARY KEY
  patientId: UUID FOREIGN KEY → Users
  doctorId: UUID FOREIGN KEY → Users
  medicineId: UUID FOREIGN KEY → Medicines
  dosage: VARCHAR (e.g., "500mg")
  frequency: VARCHAR (e.g., "2x daily")
  startDate: DATE
  endDate: DATE
  status: ENUM (DRAFT, ACTIVE, EXPIRED, COMPLETED)
  instructions: TEXT
  notes: TEXT
  createdAt: TIMESTAMP
  updatedAt: TIMESTAMP
}

TABLE Doses {
  id: UUID PRIMARY KEY
  prescriptionId: UUID FOREIGN KEY → Prescriptions
  patientId: UUID FOREIGN KEY → Users
  scheduledTime: TIMESTAMP
  takenTime: TIMESTAMP NULLABLE (null = not taken)
  status: ENUM (SCHEDULED, TAKEN, MISSED)
  notes: TEXT
  createdAt: TIMESTAMP
}
```

```sql
┌─────────────────────────────────────────────────────────┐
│               HEALTH MONITORING                         │
├─────────────────────────────────────────────────────────┤

TABLE VitalSigns {
  id: UUID PRIMARY KEY
  patientId: UUID FOREIGN KEY → Users
  recordedAt: TIMESTAMP
  bloodPressureSystolic: INTEGER NULLABLE
  bloodPressureDiastolic: INTEGER NULLABLE
  heartRate: INTEGER NULLABLE (BPM)
  temperature: DECIMAL NULLABLE (°C)
  bloodSugar: INTEGER NULLABLE (mg/dL)
  oxygenSaturation: DECIMAL NULLABLE (%)
  weight: DECIMAL NULLABLE (kg)
  height: DECIMAL NULLABLE (cm)
  notes: TEXT
  createdAt: TIMESTAMP
}

TABLE HealthAlerts {
  id: UUID PRIMARY KEY
  patientId: UUID FOREIGN KEY → Users
  doctorId: UUID FOREIGN KEY → Users NULLABLE
  alertType: VARCHAR (abnormal_vitals, missed_dose, etc.)
  severity: ENUM (LOW, MEDIUM, HIGH, CRITICAL)
  message: TEXT
  isRead: BOOLEAN DEFAULT false
  createdAt: TIMESTAMP
}
```

```sql
┌─────────────────────────────────────────────────────────┐
│              PAYMENT & SUBSCRIPTION                     │
├─────────────────────────────────────────────────────────┤

TABLE Payments {
  id: UUID PRIMARY KEY
  userId: UUID FOREIGN KEY → Users
  amount: DECIMAL
  currency: VARCHAR (KHR, USD)
  status: ENUM (PENDING, COMPLETED, FAILED, REFUNDED)
  bakongTransactionId: VARCHAR UNIQUE NULLABLE
  qrCode: TEXT NULLABLE
  paymentMethod: VARCHAR (BAKONG)
  createdAt: TIMESTAMP
  completedAt: TIMESTAMP NULLABLE
}

TABLE Subscriptions {
  id: UUID PRIMARY KEY
  userId: UUID FOREIGN KEY → Users
  planName: VARCHAR
  status: ENUM (ACTIVE, CANCELLED, EXPIRED)
  startDate: DATE
  endDate: DATE
  autoRenew: BOOLEAN
  paymentId: UUID FOREIGN KEY → Payments NULLABLE
  createdAt: TIMESTAMP
}
```

```sql
┌─────────────────────────────────────────────────────────┐
│              NOTIFICATIONS & AUDIT                      │
├─────────────────────────────────────────────────────────┤

TABLE Notifications {
  id: UUID PRIMARY KEY
  userId: UUID FOREIGN KEY → Users
  title: VARCHAR
  message: TEXT
  type: VARCHAR (PRESCRIPTION, ADHERENCE, HEALTH_ALERT)
  status: ENUM (UNREAD, READ)
  createdAt: TIMESTAMP
  readAt: TIMESTAMP NULLABLE
}

TABLE AuditLogs {
  id: UUID PRIMARY KEY
  userId: UUID FOREIGN KEY → Users
  action: VARCHAR (CREATE, READ, UPDATE, DELETE)
  resourceType: VARCHAR (User, Prescription, etc.)
  resourceId: UUID
  changes: JSONB (before/after values)
  ipAddress: VARCHAR
  userAgent: VARCHAR
  statusCode: INTEGER
  createdAt: TIMESTAMP
}
```

### 4.3 Database Migrations

**Current Migrations:**
```
20260208122556_init
  ↓ defines core schema (Users, Prescriptions, etc.)

20260209171124_add_connection_tokens_grace_period_metadata
  ↓ adds connection token grace period support

20260210073839_add_doctor_notes_model
  ↓ adds doctor notes table for patient observations

20260210073943_add_doctor_notes
  ↓ doctor notes field migration

20260216065810_add_missing_user_fields
  ↓ adds lastLogin, isActive fields

20260216071239_add_reset_token_fields
  ↓ adds password reset token support

20260216100000_add_medication_batch
  ↓ adds batch medication table
```

### 4.4 Prisma ORM Configuration

**Prisma Client:**
- Auto-generated type-safe database client
- Automatic migration management
- Query builder with TypeScript support
- Connection pooling (10 connections default)
- Lazy initialization
- Error handling and validation

**Key Files:**
```
prisma/
├── schema.prisma          # Data model definitions
├── seed.ts                # Database seed script
└── migrations/            # All migration files
    └── migration_lock.toml
```

---

## 5. Infrastructure & DevOps

### 5.1 Docker-Compose Architecture

```yaml
services:
  # PostgreSQL Database
  postgres:
    image: postgres:17-alpine
    container_name: dastern-postgres-nestjs
    restart: unless-stopped
    ports:
      - "5432:5432"           # Internal only in production
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Persistent
      - ./docker/postgres/init:/docker-entrypoint-initdb.d
    environment:
      POSTGRES_USER: dastern_user
      POSTGRES_PASSWORD: [from .env]
      POSTGRES_DB: dastern
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dastern_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7.4-alpine
    container_name: dastern-redis-nestjs
    restart: unless-stopped
    ports:
      - "6379:6379"           # Internal only in production
    volumes:
      - redis_data:/data      # Persistent
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s

  # OAuth2 Server (Future: Keycloak/Auth0)
  # Email Server (Future: MailHog)
  # Log Aggregation (Future: ELK Stack)

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  dastern-network:
    driver: bridge
```

### 5.2 NestJS Application Server

**Configuration:**
```typescript
// Environment Variables
NEST_PORT=3000
NODE_ENV=development|production
LOG_LEVEL=debug|info|warn|error

// Database
DATABASE_URL=postgresql://user:pass@postgres:5432/dastern

// Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=optional

// JWT Authentication
JWT_SECRET=[random-secret-key]
JWT_EXPIRATION=24h

// OAuth
GOOGLE_CLIENT_ID=[google-oauth-id]
GOOGLE_CLIENT_SECRET=[google-oauth-secret]

// Email SMTP
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=[email]
SMTP_PASSWORD=[password]

// External Services
BAKONG_API_URL=https://api.bakong.com
BAKONG_WEBHOOK_SECRET=[secret]
OCR_SERVICE_URL=https://ocr-service.com
```

### 5.3 Application Server Structure

```
NestJS Application
├── HTTP Server (Port 3000)
│   ├── Route: /api/auth
│   ├── Route: /api/users
│   ├── Route: /api/prescriptions
│   ├── Route: /api/prescriptions/{id}/doses
│   ├── Route: /api/health-monitoring
│   ├── Route: /api/adherence
│   ├── Route: /api/connections
│   ├── Route: /api/doctors
│   ├── Route: /api/medicines
│   ├── Route: /api/notifications
│   ├── Route: /api/payments
│   ├── Route: /api/subscriptions
│   ├── Route: /api/audit
│   ├── Route: /api/ocr
│   └── Route: /api/batch-medications

├── Background Jobs (Bull Queue)
│   ├── Email sending queue
│   ├── Notification processing
│   ├── Audit log writes (batched)
│   ├── Health alert generation
│   └── OCR processing

├── WebSocket Server (Port 3000/socket.io)
│   ├── Real-time health alert notifications
│   ├── Prescription updates
│   ├── Connection requests
│   └── Message notifications

├── Middleware Stack
│   ├── CORS handler
│   ├── Helmet (security headers)
│   ├── Request logging
│   ├── Rate limiting (100 req/min)
│   ├── JWT token validation
│   ├── Request validation DTOs
│   └── Error handling

└── Scheduled Tasks (@nestjs/schedule)
    ├── Adherence calculation (daily)
    ├── Health alert checks (every 10 min)
    ├── Expired prescription cleanup (daily)
    ├── Session cleanup (hourly)
    └── Audit log archival (weekly)
```

### 5.4 Deployment Targets

**Development:**
```bash
Docker Compose (local machine)
  ↓
PostgreSQL + Redis in containers
  ↓
NestJS dev server (watch mode)
```

**Production:**
```bash
  Cloud Platform (AWS/GCP/Azure/DigitalOcean)
    ↓
  Kubernetes Cluster (optional)
    ├── NestJS Pods (auto-scaling)
    ├── PostgreSQL Managed DB
    ├── Redis Managed Cache
    └── Load Balancer
    ↓
  CDN (CloudFlare)
    ↓
  Mobile App & Web Clients
```

---

## 6. External Services Integration

### 6.1 Bakong Payment Service

**Architecture:**
```
Mobile App
    ↓ (1) Payment Request
Backend NestJS
    ↓ (2) Encrypt & Forward
Bakong Service (Separate VPS)
    ↓ (3) Call Bakong API
Bakong Platform
    ↓ (4) Generate QR Code
Bakong Service
    ↓ (5) Return QR to Backend
Backend NestJS
    ↓ (6) Send QR to Mobile App
Mobile App
    ↓ (7) User Scans & Pays
Bakong Platform
    ↓ (8) Payment Callback
Bakong Service
    ↓ (9) Verify & Notify Backend
Backend NestJS
    ↓ (10) Update Payment Status
PostgreSQL
```

**Integration Points:**
- **Request Encryption**: Payload encrypted before sending to Bakong Service
- **Webhook Handling**: Backend receives payment callbacks
- **Transaction Recording**: All payments stored in PostgreSQL
- **Error Handling**: Retry logic for failed payments
- **Audit Trail**: All payment operations logged in AuditLogs

**Payment Status Flow:**
```
PENDING → PROCESSING → COMPLETED / FAILED / EXPIRED
```

### 6.2 Email Service (SMTP)

**Provider**: Gmail SMTP / Custom Mail Server

**Integration:**
```
Email Request Queue (Bull)
    ↓
Email Service
    ↓ (Validate, Render Template)
SMTP Connection
    ↓
Email Provider (Gmail/SendGrid)
    ↓
User Inbox
```

**Email Types:**
- Welcome email
- Password reset
- Prescription notifications
- Appointment reminders
- Adherence alerts
- Health warnings

**Retry Logic:**
```
Attempt 1 (Immediate)
    ↓ (Failed)
Attempt 2 (5 min delay)
    ↓ (Failed)
Attempt 3 (15 min delay)
    ↓ (Failed)
Attempt 4 (1 hour delay)
    ↓
Log failure in audit
```

### 6.3 OCR Service Integration

**Architecture:**
```
Mobile App
    ↓ (1) Upload Prescription Image
Backend NestJS
    ↓ (2) Store Image Temporarily
OCR Service (External)
    ↓ (3) Process & Extract Text
    ↓ (4) Return OCR Results
Backend Parser
    ↓ (5) Extract Medicine/Dosage/Frequency
Prescription Parser Module
    ↓ (6) Create Structured Prescription
PostgreSQL
    ↓ (7) Store Prescription
Mobile App
    ↓ (8) Confirm & Save
```

**OCR Response Processing:**
```json
{
  "success": true,
  "text": "Aspirin 500mg...",
  "structured": {
    "medicines": [
      {
        "name": "Aspirin",
        "dosage": "500mg",
        "frequency": "2x daily",
        "duration": "10 days"
      }
    ]
  }
}
```

### 6.4 Google OAuth Integration

**Flow:**
```
Mobile App
    ↓ (1) Google Sign-In
Google OAuth Provider
    ↓ (2) Redirect with Auth Code
    ↓ (3) Return Auth Code to Backend
Backend Auth Service
    ↓ (4) Exchange Code for Token
Google OAuth API
    ↓ (5) Return User Profile
Backend Auth Service
    ↓ (6) Create/Link User in PostgreSQL
    ↓ (7) Generate JWT Token
Mobile App
    ↓ (8) Store JWT Token
Subsequent Requests
    ↓ (9) Use JWT Token in Headers
```

**User Linking:**
```
If first Google login:
  ↓ Create new user with googleId
If returning user:
  ↓ Update lastLogin timestamp
  ↓ Return existing JWT
```

### 6.5 Future External Services

**Planned Integrations:**
- Firebase Cloud Messaging (Push notifications)
- AWS S3 (Image/document storage)
- Twilio (SMS notifications)
- Analytics Platform (Usage tracking)
- Error Tracking (Sentry)

---

## 7. Data Flow & Communication

### 7.1 Request/Response Cycle

```
┌─────────────────────────────────────────────────────────────┐
│  CLIENT REQUEST (Flutter Mobile App)                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ POST /api/prescriptions                             │   │
│  │ Header: Authorization: Bearer [JWT_TOKEN]           │   │
│  │ Body: { medicineId, dosage, frequency, ... }        │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  NestJS Backend Server (Port 3000)                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 1. Routing: Match URL to Controller                 │   │
│  │ 2. Auth Guard: Validate JWT Token                   │   │
│  │ 3. RBAC Guard: Check User Permissions               │   │
│  │ 4. DTOValidation: Validate request body             │   │
│  │ 5. Business Logic: Prescription Service             │   │
│  │ 6. Database: Prisma ORM Query                       │   │
│  │ 7. Audit: Log action in AuditLogs                   │   │
│  │ 8. Cache: Update Redis cache if needed              │   │
│  │ 9. Response: Serialize & return to client           │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────┬──────────────────────────────────────────────┘
                 │
        ┌────────┼────────┐
        ↓        ↓        ↓
    ┌────────────────────────────────────────────────────────┐
    │ PostgreSQL  Redis      Email Queue                     │
    │ (Write)     (Update)   (Enqueue)                       │
    └────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────┐
│  CLIENT RESPONSE (HTTP 200 or Error)                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ {                                                   │   │
│  │   success: true,                                    │   │
│  │   data: {                                           │   │
│  │     id: "uuid",                                     │   │
│  │     status: "ACTIVE",                               │   │
│  │     createdAt: "2026-02-20T10:30:00Z"              │   │
│  │   }                                                 │   │
│  │ }                                                   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 Real-Time Communication (WebSocket)

```
WebSocket Connection (socket.io)
    ↓
Connected to: wss://backend.com/socket.io
    ↓
Authenticated with JWT Token
    ↓
Client Joins Room: patient_{patientId}
    ↓ (Real-time Events)
    │
    ├─ "prescription.updated" → Push to connected patients
    ├─ "health.alert" → Push to doctor on call
    ├─ "dose.reminder" → Push scheduled dose notification
    ├─ "message.received" → Push new messages
    └─ "connection.request" → Push connection requests
    ↓
Server Broadcasts Event
    ↓
Subscribed Clients Receive Notification (in real-time)
```

### 7.3 Database Transaction Flow

```
Request Arrives
    ↓
Begin Transaction
    ↓ (Atomicity guaranteed)
1. Create Prescription
2. Create associated Doses
3. Create Notification
4. Log to AuditLogs
5. Update Doctor's cache
    ↓
All succeed? → Commit → PostgreSQL persists
Any fails? → Rollback → No partial data
    ↓
Response sent to client
```

---

## 8. Security Architecture

### 8.1 Authentication & Authorization

**JWT Token Structure:**
```javascript
Header: {
  "alg": "HS256",
  "typ": "JWT"
}

Payload: {
  "sub": "user-uuid",
  "email": "user@example.com",
  "role": "PATIENT" | "DOCTOR" | "ADMIN",
  "iat": 1613654400,
  "exp": 1613740800  // 24 hours
}

Signature: HMAC-SHA256(header + payload + secret)
```

**Token Validation Flow:**
```
Request Headers: Authorization: Bearer [TOKEN]
    ↓
JWT Guard
    ↓
1. Verify Signature (secret key)
2. Check Expiration
3. Check Token Blacklist (Redis)
4. Extract User ID
    ↓
AuthService
    ↓
Load User from Database
    ↓
Attach User to Request Context
    ↓
Proceed to Controller
```

**RBAC (Role-Based Access Control):**
```
Decorators on Routes:
  @Roles(Role.DOCTOR, Role.ADMIN)
  async updatePrescription(...)

Execution Flow:
  ↓
RolesGuard checks
  ↓
User role matches allowed? YES → Proceed
User role doesn't match? NO → 403 Forbidden
```

### 8.2 Encryption & Data Protection

**Password Hashing:**
```
User Input: "MyPassword123"
    ↓
bcrypt.hash(password, salt=10)
    ↓
Hashed: "$2b$10$..." (never stored in plain text)
    ↓
Stored in PostgreSQL
```

**Sensitive Data Encryption:**
```
Bakong Payment Payload
    ↓
AES-256 Encryption
    ↓
Base64 Encode
    ↓
Send to Bakong Service
    ↓
Bakong Service Decrypts with Key
```

**Database SSL:**
```
Production PostgreSQL Connection:
  ↓ sslmode=require
  ↓ All data in transit encrypted
  ↓ Certificate validation
```

### 8.3 API Security

**Rate Limiting:**
```
ThrottlerGuard
  ↓
Per-route limit: 100 requests per minute
  ↓
Stored in Redis
  ↓
Exceeded? → 429 Too Many Requests
```

**CORS Policy:**
```
Allowed Origins:
  - https://app.dastern.com (production)
  - http://localhost:3000 (dev)

Methods: GET, POST, PUT, DELETE
Headers: Authorization, Content-Type
Credentials: Include cookies if needed
```

**Input Validation:**
```
Every DTO has class-validator rules:
  @IsEmail()
  @IsString()
  @MinLength(8)
  @Matches(/regex/)

Invalid input → 400 Bad Request
```

### 8.4 Audit & Compliance

**Audit Logging:**
```
Every data modification automatically logged:
  ✓ User ID (who)
  ✓ Action type (what)
  ✓ Resource (which)
  ✓ Changes (before/after)
  ✓ Timestamp (when)
  ✓ IP address (where from)

Stored for: Compliance, debugging, security investigation
Retention: 2+ years (configurable)
```

**Data Privacy:**
```
PII Data Fields:
  - Passwords (hashed, never logged)
  - Health records (encrypted, access-controlled)
  - Personal notes (access-logged)

Access Control:
  - Only own data visible to patients
  - Only connected patients visible to doctors
  - Admins can view anonymized reports
```

---

## 9. Deployment Model

### 9.1 Development Environment

```bash
# Start services
docker-compose up -d

# Run migrations
npx prisma migrate dev

# Start NestJS server (watch mode)
npm run start:dev

# Access API
http://localhost:3000/api/docs
```

### 9.2 Production Environment

```
Git Repository
    ↓ (push to main branch)
CI/CD Pipeline (GitHub Actions)
    ↓
1. Build Docker image
2. Run tests
3. Push to container registry
4. Deploy to Kubernetes
    ↓
Kubernetes Cluster
    ├─ NestJS Pods (3+ replicas, auto-scaling)
    ├─ PostgreSQL (managed service)
    ├─ Redis (managed service)
    └─ Ingress (load balancer + SSL)
    ↓
CloudFlare CDN
    ↓
Client Applications
```

### 9.3 Environment Variables

**.env (Development)**
```
NODE_ENV=development
NEST_PORT=3000
DATABASE_URL=postgresql://dastern_user:password@postgres:5432/dastern
REDIS_HOST=redis
REDIS_PORT=6379
JWT_SECRET=dev-secret-key
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxx
SMTP_HOST=smtp.gmail.com
```

**.env (Production)**
```
NODE_ENV=production
NEST_PORT=3000
DATABASE_URL=postgresql://prod-user:strong-pwd@managed-postgres.aws.com:5432/dastern
REDIS_HOST=managed-redis.aws.com
REDIS_PORT=6379
REDIS_PASSWORD=[strong-password]
JWT_SECRET=[long-random-secret]
JWT_EXPIRATION=24h
```

### 9.4 Scaling Strategy

**Horizontal Scaling:**
```
Single NestJS Instance
    ↓ (Bottleneck)
Load Balancer (Nginx/HAProxy)
    ↓
Multiple NestJS Pods
    ├─ Pod 1 (300 req/sec)
    ├─ Pod 2 (300 req/sec)
    ├─ Pod 3 (300 req/sec)
    └─ Pod N (auto-scale up)
    ↓
Shared PostgreSQL (connection pooling)
Shared Redis (cluster for large scale)
```

**Caching Strategy:**
```
Frequently Accessed Data:
  - User profiles → Redis (TTL: 1 hour)
  - Medicine list → Redis (TTL: 24 hours)
  - Doctor's patient list → Redis (TTL: 15 min)

Cache Invalidation:
  - On write: Invalidate related keys
  - On expiry: TTL-based eviction
  - Manual: On critical updates
```

---

## 10. Scalability & Performance

### 10.1 Performance Optimization

**Database:**
```
Indexes Created:
  - Users.email (fast login lookup)
  - Connections.patientId (fast patient list)
  - Prescriptions.status (fast filtering)
  - Doses.takenTime (fast adherence queries)
  - AuditLogs.userId (fast audit retrieval)

Query Optimization:
  - N+1 queries prevented (Prisma relations)
  - Pagination for large datasets
  - Batched writes for bulk operations
```

**Caching Layers:**
```
L1 Cache: Response caching (HTTP 304 Not Modified)
L2 Cache: Redis (application data)
L3 Cache: CDN (static assets, API responses)
L4 Cache: Browser cache (client-side)
```

**Connection Pooling:**
```
PostgreSQL:
  - Max connections: 10 (development)
  - Max connections: 100+ (production)
  - Idle connection timeout: 5 min

Redis:
  - Connection pool manager
  - Automatic reconnection on failure
```

### 10.2 Monitoring & Alerts

**Metrics to Track:**
```
Application:
  - Request latency (p50, p95, p99)
  - Error rates
  - Active user count
  - API endpoint popularity

Database:
  - Query execution time
  - Connection pool usage
  - Table size growth
  - Replication lag (if applicable)

Infrastructure:
  - CPU usage
  - Memory usage
  - Disk I/O
  - Network throughput
```

**Alert Thresholds:**
```
CRITICAL:
  ├─ API response time > 1 second
  ├─ Database connection pool exhausted
  ├─ Redis memory usage > 90%
  └─ Error rate > 1%

WARNING:
  ├─ P99 latency > 500ms
  ├─ Database connection usage > 75%
  └─ Disk usage > 70%
```

### 10.3 Load Testing

**Estimated Capacity:**
```
Single NestJS Instance (4 CPU, 8GB RAM):
  - ~1,000 concurrent users
  - ~500-1,000 req/sec
  - p95 latency: <200ms

With 3 instances (load balanced):
  - ~3,000 concurrent users
  - ~1,500-3,000 req/sec
  - p95 latency: <200ms
```

---

## 11. Troubleshooting Guide

### Common Issues

**Database Connection Refused**
```
Cause: PostgreSQL service not running
Fix: docker-compose up -d postgres
Verify: docker logs dastern-postgres-nestjs
```

**Redis Connection Timeout**
```
Cause: Redis service down or wrong host
Fix: docker-compose up -d redis
Check: redis-cli -h localhost ping
```

**JWT Token Expired**
```
Cause: Token TTL exceeded
Fix: Call refresh-token endpoint
Response: Get new JWT token
```

**Rate Limit Exceeded**
```
Error: 429 Too Many Requests
Cause: >100 requests/minute from same IP
Wait: 60 seconds before retry
```

---

## 12. Future Enhancements

1. **WebSocket Optimization**
   - Socket.io scaling with Redis adapter
   - Real-time collaboration features

2. **Microservices Migration**
   - Split into independent services
   - API Gateway (Kong/Tyk)
   - Service-to-service communication (gRPC)

3. **Advanced Analytics**
   - Elasticsearch for audit log search
   - Kibana dashboards
   - User behavior analytics

4. **Machine Learning**
   - Adherence prediction models
   - Health risk scoring
   - Medication recommendation engine

5. **Mobile Push Notifications**
   - Firebase Cloud Messaging
   - Smart scheduling of notifications
   - Notification testing framework

6. **GraphQL Layer**
   - Apollo Server integration
   - Real-time subscriptions
   - Query optimization

---

## 13. Architecture Diagrams

### System Components Relationship

```
┌─────────────────────────────────────────────────────────────────┐
│            CLIENT PRESENTATIONS                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Flutter App  │  │ Web Browser  │  │ Admin Panel  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTPS/REST/WebSocket
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│         API GATEWAY & LOAD BALANCER                             │
│         (CloudFlare/Nginx - Port 443)                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│    NESTJS APPLICATION SERVER CLUSTER                            │
│    ┌──────────────────────────────────────────────────────┐    │
│    │  Instance 1 (3000)  Instance 2  Instance 3  ...      │    │
│    │  ├─ HTTP Server                                      │    │
│    │  ├─ WebSocket Server                                │    │
│    │  ├─ Background Jobs                                 │    │
│    │  └─ Scheduled Tasks                                 │    │
│    └──────────────────────────────────────────────────────┘    │
└────────────────┬──────────────────────────────────────────────────┘
                 │
   ┌─────────────┼──────────────┐
   ↓             ↓              ↓
┌───────────┐┌──────────┐┌─────────────────┐
│PostgreSQL │ │ Redis    ││External Services│
│(Port 5432)│ │(Port6379)│├─────────────────┤
│           │ │          ││ Bakong Service  │
│ ┌─────┐   │ │┌───────┐ ││ OCR Service     │
│ │Users│   │ ││Sessions││ Email (SMTP)    │
│ ├─────┤   │ │├Cache  │ │ Google OAuth    │
│ │Prescp│   │ ││Tokens │ │ Analytics (GA)  │
│ ├─────┤   │ │└───────┘ │ Monitoring (DD) │
│ │Doses│   │ │          │ Logging (ELK)   │
│ ├─────┤   │ │          └─────────────────┘
│ │Health│  │ │
│ ├─────┤   │ │
│ │Audits│  │ │
│ └─────┘   │ │
│(Persistent)│ │(Volatile)
└───────────┘└──────────┘
```

---

## 14. Contact & Support

For questions about backend architecture:
- Review the README.md for quick start
- Check environment setup in .env.example
- Run `npm run start:dev` for development
- Enable debug logs with `LOG_LEVEL=debug`

---

**Last Updated**: February 20, 2026  
**Version**: 1.0.0  
**Status**: Production Ready
