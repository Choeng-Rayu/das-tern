DAS TERN – PROJECT OVERVIEW, ARCHITECTURE & AI AGENT RULES
============================================================

Project Summary
===============

Das Tern is a **medication management and adherence platform** for Cambodia.
It helps patients track prescriptions, follow dosing schedules, and manage
family medication oversight. The platform supports Khmer and English languages.

Key capabilities:
- Prescription management with OCR scanning of paper prescriptions
- Medication dose scheduling and adherence tracking
- Doctor-patient connections with family member oversight
- Bakong mobile payment integration (Cambodia's national payment system)
- Health vital monitoring with threshold alerts


Repository Structure
====================

```
das-tern/
├── backend_nestjs/        # Main backend API (NestJS, port 3001)
│   ├── src/
│   │   ├── modules/       # Feature modules (see below)
│   │   ├── common/        # Shared guards, decorators, pipes
│   │   ├── database/      # Prisma service, database module
│   │   └── main.ts
│   └── prisma/
│       └── schema.prisma  # PostgreSQL schema (all models)
│
├── bakong_payment/        # Bakong payment service (NestJS, port 3002)
│   └── src/
│       ├── bakong/        # Bakong API integration
│       ├── controllers/   # Payment endpoints
│       ├── services/      # Payment processing logic
│       ├── middleware/     # Encryption, validation
│       └── prisma/        # Minimal payment-only schema
│
├── ocr_service/           # OCR prescription scanning (FastAPI, port 8000)
│   ├── implementation.plan.md   # Full implementation plan
│   ├── prompt.ocr.md            # OCR design spec
│   └── test_space/              # Test images & ground truth JSON
│       ├── images_for_test/     # image.png, image1.png, image2.png
│       └── results/             # Expected output JSON formats
│
├── das_tern_mcp/          # Mobile app (Flutter)
│   └── lib/
│       ├── l10n/          # Localization (app_en.arb, app_km.arb)
│       ├── models/        # Data models
│       ├── providers/     # State management
│       ├── services/      # API services
│       ├── ui/
│       │   ├── screens/   # Feature screens
│       │   ├── widgets/   # Reusable widgets
│       │   └── theme/     # App theming
│       └── utils/         # Helpers
│
├── docs/
│   └── architectures/
│       └── README.md      # Full architecture documentation
│
├── docker-compose.yml     # PostgreSQL, Redis, RabbitMQ, MinIO
├── database/              # DB init scripts
└── Cluade.md              # This file (AI agent rules)
```


Architecture Overview
=====================

System Components:

1. backend_nestjs (NestJS, port 3001)
   - Main business logic and API gateway
   - Handles authentication, users, prescriptions, medications,
     dose events, connections, subscriptions, payments
   - Communicates with Bakong Payment service (encrypted)
   - Communicates with OCR Service (HTTP)
   - Connects to PostgreSQL and Redis (via Docker)
   - Modules:
     - auth (JWT authentication, registration, login)
     - users (profile management, preferences)
     - prescriptions (CRUD, status workflow: DRAFT→ACTIVE→PAUSED→INACTIVE)
     - medicines (medication catalog)
     - doses (dose scheduling and adherence tracking)
     - connections (doctor-patient, family-member links)
     - bakong-payment (payment processing via bakong_payment service)
     - notifications (push notifications, alerts)
     - subscriptions (tier management)
     - health-monitoring (vitals, thresholds, alerts)
     - doctor-dashboard (doctor-specific views)
     - adherence (adherence statistics)
     - audit (audit logging)
     - email (email notifications)

2. bakong_payment (NestJS, port 3002, separate VPS)
   - Handles Bakong payment integration only
   - Receives encrypted payload from backend
   - Generates QR code via Bakong API
   - Receives payment notification callback from Bakong
   - Sends payment success callback to main backend
   - Does NOT connect to the main PostgreSQL/Redis Docker
   - Has its own minimal Prisma schema for payment records only
   - Stores only transaction-related data

3. ocr_service (FastAPI Python, port 8000)
   - OCR prescription scanning microservice
   - Dual-engine: PaddleOCR PP-OCRv5 (English/Latin) + Tesseract 5.x (Khmer)
   - Table detection via PP-StructureV3
   - Image preprocessing via OpenCV (deskew, denoise, CLAHE contrast)
   - Outputs Dynamic Universal v2.0 JSON format
   - Stateless — no database, no persistent storage
   - CPU-only, all open-source (Apache-2.0 compatible)
   - Status: IMPLEMENTATION PLANNED (see ocr_service/implementation.plan.md)

4. das_tern_mcp (Flutter mobile app)
   - Mobile application for patients, doctors, and family members
   - MUST support English and Khmer languages
   - Localization files: das_tern_mcp/lib/l10n/ (app_en.arb, app_km.arb)
   - Communicates ONLY with backend_nestjs (never directly with other services)
   - Always run `flutter analyze` and fix issues before testing
   - Screens: auth, patient, doctor, family, profile, prescription detail, tabs

5. Infrastructure (Docker)
   - PostgreSQL 17-alpine (port 5432) — main database
   - Redis 7.4-alpine (port 6379) — caching, session store
   - RabbitMQ 4.0 (port 5672/15672) — async job queue
   - MinIO (port 9000/9001) — S3-compatible file/image storage
   - Docker is used ONLY for these infrastructure services
   - Timezone: Asia/Phnom_Penh


Database Schema (PostgreSQL via Prisma)
=======================================

Models:
- User (roles: PATIENT, DOCTOR, FAMILY_MEMBER)
- Connection (doctor-patient and family links, status workflow)
- ConnectionToken
- Prescription (status: DRAFT, ACTIVE, PAUSED, INACTIVE)
- PrescriptionVersion (version history)
- Medication (linked to Prescription)
- DoseEvent (status: DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED)
- Notification
- AuditLog
- Subscription (tiers: FREE, BASIC, PREMIUM)
- FamilyMember
- MealTimePreference
- DoctorNote
- HealthVital
- VitalThreshold
- HealthAlert

Key enums: UserRole, Gender, Language (KHMER/ENGLISH), AccountStatus,
ConnectionStatus, PrescriptionStatus, DoseEventStatus, SubscriptionTier,
NotificationType, MedicineType, MedicineUnit, VitalType, AlertSeverity

Schema file: backend_nestjs/prisma/schema.prisma


System Flows
============

Payment Flow:

1. Flutter app sends payment request to backend_nestjs.
2. Backend encrypts payload and sends to bakong_payment service.
3. bakong_payment calls Bakong API and generates QR code.
4. bakong_payment returns QR code response to backend.
5. Backend sends QR code to Flutter app.
6. User pays via Bakong mobile banking.
7. Bakong sends payment notification to bakong_payment.
8. bakong_payment validates and notifies backend.
9. Backend updates payment status in PostgreSQL.
10. Backend confirms successful payment to Flutter app.

OCR Prescription Scanning Flow:

1. Flutter app captures/uploads prescription image.
2. Backend receives image, stores in MinIO, forwards to OCR service.
3. OCR service preprocesses image (blur check, contrast, deskew).
4. Layout analyzer detects table, header, footer regions.
5. Per-region OCR: PaddleOCR for English text, Tesseract for Khmer.
6. Post-processor normalizes text, matches medication names via lexicon.
7. Formatter produces Dynamic Universal v2.0 JSON with confidence scores.
8. Response returned to backend.
9. Backend maps JSON to Prescription + Medication[] Prisma models.
10. Backend stores in PostgreSQL, returns structured data to Flutter.
11. Flutter shows scanned data for user review/correction.

Prescription Status Workflow:

  DRAFT → ACTIVE → PAUSED → ACTIVE (resume)
                  → INACTIVE (complete/cancel)

Dose Event Workflow:

  DUE → TAKEN_ON_TIME / TAKEN_LATE / MISSED / SKIPPED


Critical Communication Rules
=============================

- Flutter NEVER talks directly to bakong_payment service.
- Flutter NEVER talks directly to ocr_service.
- bakong_payment NEVER connects to main PostgreSQL/Redis Docker.
- ocr_service NEVER connects to main PostgreSQL/Redis Docker.
- Only backend_nestjs reads/writes the main database.
- Only backend_nestjs orchestrates communication between services.
- Payment confirmation must be verified by backend before updating status.
- OCR output must be validated by backend before storing in database.


Agent Execution Rules
=====================

1. Sub-Agent Task Delegation
----------------------------

The main agent MUST delegate tasks to sub-agents for complex features.

Example: "Create Medication Feature"

- Sub-agent 1: Implement backend (NestJS module, controller, service, DTOs)
- Sub-agent 2: Implement frontend (Flutter screens, providers, services)
- Sub-agent 3: Verify API contract and integration between backend and frontend

The main agent coordinates but does NOT implement everything alone.


2. Frontend UI Validation Rule
-------------------------------

When implementing or modifying Flutter UI:

- MUST use sub-agent with MCP server
- MUST check Figma design before implementing
- UI must match Figma structure, spacing, naming, and components
- All user-facing strings MUST be in l10n files (app_en.arb and app_km.arb)
- Always run `flutter analyze` and fix issues before testing


3. Todo List Requirement
-------------------------

Before implementing any feature:

- MUST create a detailed step-by-step Todo list
- Todo list must separate:
  - Backend tasks
  - Frontend tasks
  - OCR service tasks (if applicable)
  - Integration tasks
  - Testing tasks

No direct implementation without a structured Todo plan.


4. Sensitive Value Change Rule
-------------------------------

When changing any sensitive value:

Examples:
- .env variables
- Database schema (Prisma models/enums)
- API route paths
- DTO fields
- Encryption keys
- Redis keys
- Payment status enums
- OCR confidence thresholds
- OCR output format fields

The agent MUST:

- Identify all related fields affected across ALL services
- Update backend logic
- Update frontend API calls if needed
- Update OCR service if output format changes
- Update validation DTOs
- Update Prisma schema if required
- Update documentation (this file, architecture docs)
- Restart required services (if environment/database related)
- Run `npx prisma generate` after schema changes

No partial update is allowed.


5. Backend Responsibility Rule
------------------------------

- Only backend_nestjs can read/write PostgreSQL.
- bakong_payment must NOT access main database.
- ocr_service must NOT access main database.
- Payment confirmation must be verified by backend before updating status.
- OCR results must be validated by backend before storing.


6. Separation of Concerns Rule
------------------------------

- Flutter (das_tern_mcp) → UI, localization, user interaction only
- Backend (backend_nestjs) → Business logic, database, service orchestration
- Bakong Payment (bakong_payment) → Payment gateway communication only
- OCR Service (ocr_service) → Image processing and text extraction only
- Docker → Only PostgreSQL, Redis, RabbitMQ, MinIO


7. OCR Service Rules
---------------------

- OCR service is stateless — processes images and returns JSON, nothing else
- Output must follow Dynamic Universal v2.0 schema (see ocr_service/test_space/results/final.result.format.expected.json)
- Confidence thresholds: ≥0.80 auto-accept, 0.60-0.80 flag for review, <0.60 needs_review
- Test against ground truth: ocr_service/test_space/results/prescription_image_1_dynamic_populated.json
- All OCR dependencies must be open-source (Apache-2.0 compatible)
- CPU-only deployment (no GPU required)
- PaddleOCR for English/Latin text, Tesseract for Khmer text
- Never add database connections to ocr_service


8. Localization Rule
---------------------

Flutter app MUST support English and Khmer:
- Check das_tern_mcp/lib/l10n/ for existing localization files
- Follow the existing pattern in app_en.arb and app_km.arb
- Never hardcode user-facing strings — always use localization keys
- Run `flutter gen-l10n` after modifying .arb files


Expected Agent Behavior
=======================

- Always think in system architecture, not isolated features.
- Never break separation of concerns between services.
- Always validate backend ↔ frontend API contract consistency.
- Always validate backend ↔ ocr_service output format consistency.
- Always validate encryption and payment flow consistency.
- Always work with structured delegation and clear task boundaries.
- When modifying Prisma schema, update all dependent services and run migrations.
- When modifying OCR output format, update backend mapping AND frontend display.
- Reference docs/architectures/README.md for detailed architecture diagrams.
- Reference ocr_service/implementation.plan.md for OCR implementation details.


Technology Stack Quick Reference
================================

| Layer | Technology | Version/Notes |
|-------|-----------|---------------|
| Mobile | Flutter/Dart | English + Khmer l10n |
| Backend API | NestJS (TypeScript) | Port 3001 |
| Payment Service | NestJS (TypeScript) | Port 3002, separate VPS |
| OCR Service | FastAPI (Python) | Port 8000, CPU-only |
| Database | PostgreSQL | 17-alpine via Docker |
| Cache | Redis | 7.4-alpine via Docker |
| Queue | RabbitMQ | 4.0 via Docker |
| Object Storage | MinIO | S3-compatible via Docker |
| ORM | Prisma | v6.2.0 |
| OCR Engines | PaddleOCR + Tesseract | English + Khmer |
| Image Processing | OpenCV | Preprocessing pipeline |

End of Rules
============

End of Rules
============
