# Backend Architecture Documentation Index

> **Quick navigation guide to understand the DAS-TERN backend system**

---

## 📚 Documentation Files

### 1. **ARCHITECTURE.md** (Start Here!)
Comprehensive system architecture documentation covering:

- **System Overview** - Purpose, tech stack, key characteristics
- **High-Level Architecture** - System diagram showing all components
- **Service Architecture** (16 Modules)
  - 🔐 Auth Module
  - 👥 Users Module
  - 🏥 Connections Module
  - 💊 Prescriptions Module
  - 📊 Doses & Adherence
  - ❤️ Health Monitoring
  - 🔔 Notifications & Email
  - 💳 Payment Integration
  - And more...
- **Database Architecture** - PostgreSQL schema, Prisma ORM
- **Infrastructure & DevOps** - Docker, deployment, scaling
- **External Services** - Bakong, OCR, OAuth, Email
- **Security Architecture** - JWT, encryption, audit
- **Troubleshooting Guide** - Common issues and fixes

**When to read**: Need complete understanding of system architecture

---

### 2. **ARCHITECTURE_DETAILED_FLOWS.md**
In-depth data flow examples and communication patterns:

- **Module Dependency Hierarchy** - What depends on what
- **Request/Response Flow Examples**
  - Creating a prescription
  - Recording a dose
  - Payment webhooks
- **Data Flow Through System Layers**
  - Synchronous flows (API requests)
  - Asynchronous flows (background jobs)
- **Database Access Patterns**
  - Read-heavy patterns
  - Write-heavy patterns
  - Real-time patterns
- **Security Data Flow** - Login and access control
- **Caching Strategy** - What gets cached and when
- **Initialization Flow** - Startup sequence
- **Error Handling** - Common error patterns

**When to read**: Need to understand how modules interact and data flows

---

### 3. **README.md** (Quick Start)
Getting started guide with:

- Features overview
- Technology stack summary
- Project structure
- Installation steps
- Running the application

**When to read**: Getting started with development

---

### 4. **architecture.puml** (Visual Diagram)
PlantUML diagram showing:

- Client layer (Flutter, Web, Admin)
- API Gateway & Middleware
- All 16 NestJS modules organized by category
- PostgreSQL & Redis infrastructure
- External services (Bakong, Email, OCR, OAuth)
- Monitoring and logging layer

**When to read**: Need visual representation of system

---

## 🗺️ Quick Navigation by Use Case

### "I want to understand the whole system"
1. Read **ARCHITECTURE.md** - System Overview section
2. View **architecture.puml** diagram
3. Read **ARCHITECTURE_DETAILED_FLOWS.md** - Data Flow section

### "I need to add a new feature"
1. Check **ARCHITECTURE.md** - Service Architecture section (find relevant module)
2. Review **ARCHITECTURE_DETAILED_FLOWS.md** - Module Dependency Hierarchy
3. Understand interactions in **ARCHITECTURE_DETAILED_FLOWS.md** - Module Interaction Diagram

### "I'm debugging a feature"
1. **ARCHITECTURE.md** - Security Architecture (for access control issues)
2. **ARCHITECTURE_DETAILED_FLOWS.md** - Error Handling Flows
3. Check relevant module in **ARCHITECTURE.md** - Service Architecture

### "I need to optimize performance"
1. **ARCHITECTURE.md** - Scalability & Performance section
2. **ARCHITECTURE_DETAILED_FLOWS.md** - Database Access Patterns
3. **ARCHITECTURE.md** - Caching Strategy

### "I need to integrate external service"
1. **ARCHITECTURE.md** - External Services Integration section
2. **ARCHITECTURE_DETAILED_FLOWS.md** - External Service Call Examples
3. Review the specific service module in Service Architecture

### "I'm setting up production"
1. **ARCHITECTURE.md** - Deployment Model section
2. **ARCHITECTURE.md** - Infrastructure & DevOps section
3. Check **README.md** for environment setup

### "I need to understand security"
1. **ARCHITECTURE.md** - Security Architecture section
2. **ARCHITECTURE_DETAILED_FLOWS.md** - Security Data Flow section
3. Check JWT and encryption details

---

## 🎯 Module Quick Reference

### Core Modules (Authentication & Users)
- **AuthModule** - JWT, OAuth, password management
  - Depends on: UserModule
  - Provides: Token generation & validation
  - Files: `src/modules/auth/`

- **UsersModule** - User profiles, RBAC
  - Depends on: Database
  - Provides: User CRUD
  - Files: `src/modules/users/`

- **ConnectionsModule** - Doctor-Patient relationships
  - Depends on: UsersModule, Database
  - Provides: Connection management
  - Files: `src/modules/connections/`

### Medical Modules (Prescriptions & Health)
- **PrescriptionsModule** - Prescription management
  - Depends on: Connections, Medicines, Database
  - Provides: Rx CRUD, status tracking
  - Files: `src/modules/prescriptions/`

- **DosesModule** - Dose scheduling & tracking
  - Depends on: Prescriptions, Database
  - Provides: Dose records
  - Files: `src/modules/doses/`

- **AdherenceModule** - Adherence analytics
  - Depends on: Doses, Prescriptions
  - Provides: Adherence metrics
  - Files: `src/modules/adherence/`

- **HealthMonitoringModule** - Vital signs & alerts
  - Depends on: Users, Connections, Database
  - Provides: Health records, alerts
  - Files: `src/modules/health-monitoring/`

- **MedicinesModule** - Medicine catalog
  - Depends on: Database
  - Provides: Medicine data
  - Files: `src/modules/medicines/`

### Business Modules (Payments & Subscriptions)
- **BakongPaymentModule** - Payment processing
  - Depends on: Users, Database
  - Provides: Payment handling, webhooks
  - Files: `src/modules/bakong-payment/`

- **SubscriptionsModule** - Subscription management
  - Depends on: Users, Payments, Database
  - Provides: Plan management
  - Files: `src/modules/subscriptions/`

### Communication Modules
- **NotificationsModule** - Notification queue
  - Depends on: Users, Email, Database
  - Provides: Notification management
  - Files: `src/modules/notifications/`

- **EmailModule** - SMTP email sending
  - Depends on: none
  - Provides: Email service
  - Files: `src/modules/email/`

### Administrative Modules
- **DoctorDashboardModule** - Doctor aggregate data
  - Depends on: Connections, Prescriptions, Adherence, Health
  - Provides: Dashboard data
  - Files: `src/modules/doctor-dashboard/`

- **AuditModule** - Compliance logging
  - Depends on: Database
  - Provides: Audit trail
  - Files: `src/modules/audit/`

### Integration Modules
- **OcrModule** - OCR prescription parsing
  - Depends on: Medicines, Prescriptions
  - Provides: OCR integration
  - Files: `src/modules/ocr/`

- **BatchMedicationModule** - Bulk operations
  - Depends on: Prescriptions, Medicines
  - Provides: Batch processing
  - Files: `src/modules/batch-medication/`

---

## 📊 Database Schema Quick Look

### User Management Tables
```
Users → Connections → (doctor-patient links)
     → Subscriptions → (plan info)
```

### Medical Tables
```
Prescriptions → (created by doctor for patient)
            → Medicines (reference)
            → Doses (scheduled doses)
            → VitalSigns (health data)
            → HealthAlerts (condition alerts)
            → DoctorNotes (observations)
```

### Operational Tables
```
Payments → (transaction history)
Notifications → (message queue)
AuditLogs → (compliance trail)
```

---

## 🔄 Request Path Examples

### Patient Taking a Dose
```
Mobile App
    ↓ POST /api/doses/:id/mark-taken
Backend: JwtGuard → RolesGuard → DosesController
    ↓
DosesService.markTaken()
    ↓ Update PostgreSQL
    ↓ Calculate adherence (AdherenceService)
    ↓ Check for alerts (HealthMonitoringService)
    ↓ Log action (AuditService)
    ↓ Clear cache
    ↓ Queue notification email (NotificationsService)
    ↓
Response: 200 OK with adherence metrics
    ↓
Background: EmailModule sends confirmation
```

### Doctor Creating Prescription
```
Mobile App
    ↓ POST /api/prescriptions
Backend: JwtGuard → RolesGuard(DOCTOR) → PrescriptionsController
    ↓
PrescriptionsService.create()
    ├─ Validate doctor-patient connection
    ├─ Verify medicine exists
    ├─ Create Prescription record
    ├─ Generate dose schedule (DosesService)
    ├─ Log action (AuditService)
    ├─ Cache invalidation
    └─ Queue notification (NotificationsService)
    ↓
Response: 201 Created with Rx details
    ↓
Background: EmailModule + Firebase notify patient
```

### Payment Processing
```
Mobile App
    ↓ POST /api/payments/initiate
Backend: BakongPaymentModule
    ↓ Create Payment record
    ↓ Encrypt payload
    ↓ Call Bakong Service via HTTPS
    ↓ Get QR code
    ↓ Return to app
    ↓
User scans QR and pays via Bakong
    ↓
Bakong → Bakong Service → Webhook to Backend
    ↓ POST /api/payments/webhook
    ↓ Verify signature & decrypt
    ↓ Update payment status
    ↓ Activate subscription (SubscriptionsModule)
    ↓ Log action (AuditService)
    ↓ Queue confirmation emails
    ↓
Response: 200 OK
Background: Emails sent, notifications pushed
```

---

## 🛠️ Development Workflow

### Add a New Feature

1. **Identify the Module**
   - Check ARCHITECTURE.md Service Architecture section
   - Find or create appropriate module in `src/modules/`

2. **Understand Dependencies**
   - Review ARCHITECTURE_DETAILED_FLOWS.md Module Dependency Hierarchy
   - Map out which services you'll need to call

3. **Implement the Service**
   - Create `.service.ts` with business logic
   - Add database queries using Prisma
   - Add error handling and logging

4. **Create the Controller**
   - Create `.controller.ts` with routes
   - Add guard decorators (@Roles, @Public, etc.)
   - Add DTO validation

5. **Add Database Migration**
   - `npx prisma migrate dev --name feature_name`
   - Update schema.prisma if needed

6. **Test the Feature**
   - Unit tests for service
   - E2E tests for API endpoints
   - Run `npm test` before submitting

---

## 🚀 Deployment Checklist

- [ ] All environment variables configured
- [ ] Database migrations applied
- [ ] Redis connectivity verified
- [ ] External services credentials set (Bakong, OAuth, SMTP)
- [ ] SSL/TLS certificates configured
- [ ] Rate limiting configured appropriately
- [ ] Monitoring and logging set up
- [ ] Backups scheduled
- [ ] Load balancer configured
- [ ] Auto-scaling policies defined
- [ ] Security hardening applied
- [ ] Documentation updated

---

## 💡 Key Concepts

### Request Flow
Every request follows: **Client → Guard → Pipe → Controller → Service → Database → Response**

### Service Dependencies
Services are injected via NestJS dependency injection. Most services depend on:
- Database (PrismaService)
- Cache (CacheManager via Redis)
- Audit (AuditService)

### Authorization
Two levels:
1. **Authentication**: JwtGuard validates token
2. **Authorization**: RolesGuard checks permissions

### Caching
Strategic caching of:
- User profiles (1 hour TTL)
- Connection lists (15 minutes TTL)
- Medicine catalog (24 hour TTL)
- Session tokens (24 hour TTL)

### Audit Trail
Every modify operation (CREATE, UPDATE, DELETE) is logged with:
- User ID
- Resource type & ID
- Before/after values
- Timestamp & IP address

---

## 📖 Additional Resources

### Code Examples
See individual module READMEs or implementation files:
- `src/modules/[module]/README.md`
- `src/modules/[module]/[module].service.ts`

### Configuration
- `.env` - Environment variables
- `nest-cli.json` - NestJS CLI config
- `tsconfig.json` - TypeScript config
- `docker-compose.yml` - Container config

### Database
- `prisma/schema.prisma` - Data model
- `prisma/migrations/` - Migration history

---

## 🤝 Getting Help

1. **Architecture questions** → Read ARCHITECTURE.md
2. **Data flow questions** → Read ARCHITECTURE_DETAILED_FLOWS.md
3. **Module usage** → Review module files in src/modules/
4. **API usage** → Check controller files for endpoint signatures
5. **Database schema** → Check prisma/schema.prisma

---

**Last Updated**: February 20, 2026

**Quick Start**:
1. Read ARCHITECTURE.md (System Overview)
2. Reference ARCHITECTURE_DETAILED_FLOWS.md (Data Flows)
3. Check specific module documentation
4. Review code in src/modules/[module]/
