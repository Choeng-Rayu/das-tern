# Das Tern — Technical Architecture & Implementation Report

**Version:** 1.0.0  
**Date:** February 18, 2026  
**Platform:** Patient-Centered Medication Management System

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Technology Stack](#3-technology-stack)
4. [Service Implementation Details](#4-service-implementation-details)
   - 4.1 [Backend API (NestJS)](#41-backend-api-nestjs)
   - 4.2 [Bakong Payment Service](#42-bakong-payment-service)
   - 4.3 [OCR Prescription Service](#43-ocr-prescription-service)
   - 4.4 [Flutter Mobile Application](#44-flutter-mobile-application)
5. [Database Design](#5-database-design)
6. [Security Implementation](#6-security-implementation)
7. [Performance Strategy](#7-performance-strategy)
8. [Offline-First Architecture](#8-offline-first-architecture)
9. [Payment Flow (Bakong KHQR)](#9-payment-flow-bakong-khqr)
10. [API Design & Communication](#10-api-design--communication)
11. [Infrastructure & Deployment](#11-infrastructure--deployment)
12. [Cross-Cutting Concerns](#12-cross-cutting-concerns)

---

## 1. Executive Summary

Das Tern is a comprehensive medication management platform designed specifically for the Cambodian healthcare market. It enables patients to own and control their medical data, collaborate with doctors, and receive support from family caregivers. The platform is built with an **offline-first** philosophy, meaning patients can track doses and receive medication reminders even without internet access.

The system is architected as **four distinct independent services**:

| Service | Technology | Responsibility |
|---|---|---|
| `backend_nestjs` | NestJS + TypeScript | Core business logic, database, authentication |
| `bakong_payment` | NestJS + TypeScript | Bakong QR payment processing (separate VPS) |
| `ocr_service` | Python FastAPI | Prescription image OCR scanning |
| `das_tern_mcp` | Flutter | Mobile application (Android & iOS) |

---

## 2. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                           │
│  (das_tern_mcp — Offline-First, Provider State Management)      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS REST API
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                  MAIN BACKEND (NestJS)                          │
│  Auth · Users · Prescriptions · Doses · Notifications           │
│  Connections · Adherence · Subscriptions · OCR forwarding       │
│  Health Monitoring · Doctor Dashboard · Audit Logs              │
├───────────────────────────┬─────────────────────────────────────┤
│     PostgreSQL 17         │            Redis                    │
│  (Docker, main data)      │  (Docker, cache + sessions)         │
└───────────────────────────┴─────────────────────────────────────┘
           │ Encrypted REST API                 │ Webhook callback
           ▼                                    │
┌──────────────────────────┐                   │
│  BAKONG PAYMENT SERVICE  │◄──────────────────┘
│  (Separate VPS — NestJS) │
│  KHQR Generation         │
│  Payment Monitoring      │──────► Bakong API (NBC Cambodia)
│  Subscription Updates    │
│  PostgreSQL (own DB)     │
│  Redis (own cache)       │
└──────────────────────────┘

┌──────────────────────────┐
│    OCR SERVICE           │
│  (Python FastAPI)        │
│  PaddleOCR + Tesseract   │
│  Prescription scanning   │
│  Khmer + English text    │
└──────────────────────────┘
```

### Architectural Principles

- **Separation of Concerns:** Each service has a single, well-defined responsibility. The Flutter app never communicates with the Bakong service directly. The Bakong service never writes to the main PostgreSQL database.
- **Patient Data Sovereignty:** The patient is always the owner of their medical data. All access by doctors or family members is explicitly permission-controlled.
- **Offline-First:** Prescription schedules and reminders are stored both in the cloud and locally on the device. Dose events queue offline for sync when connectivity returns.
- **Defense in Depth:** Multiple security layers are applied at each service boundary (JWT, rate limiting, Helmet HTTP headers, input validation, audit logs).

---

## 3. Technology Stack

### 3.1 Backend API — NestJS

| Category | Technology | Version | Purpose |
|---|---|---|---|
| Framework | NestJS | 10.x | Modular server-side framework |
| Language | TypeScript | 5.x | Type-safe application code |
| ORM | Prisma | 6.2.0 | Database access layer |
| Database | PostgreSQL | 17 | Primary relational data store |
| Cache | Redis (ioredis) | 5.x | Session caching, API caching |
| Authentication | JWT (Passport.js) | — | Access + Refresh tokens |
| Google OAuth | google-auth-library | 10.x | Social login |
| Password Hashing | bcryptjs | — | 12-round bcrypt |
| Rate Limiting | @nestjs/throttler | 5.x | 100 req/min global limit |
| Queue | Bull + Redis | 4.x | Background job processing |
| Scheduling | @nestjs/schedule | 6.x | Cron jobs for dose checking |
| HTTP Security | Helmet | 7.x | HTTP header protection |
| Compression | compression | — | Gzip response compression |
| Email | Nodemailer | 8.x | OTP + notifications |
| Validation | class-validator | 0.14 | DTO validation |

### 3.2 Bakong Payment Service — NestJS

| Category | Technology | Purpose |
|---|---|---|
| Framework | NestJS 11 | Payment API server |
| ORM | Prisma 6.2 | Payment database access |
| Database | PostgreSQL (own) | Payment-only data store |
| Cache | Redis (ioredis) | Payment session caching |
| QR Generation | qrcode-generator | EMV KHQR code image output |
| Encryption | crypto-js | MD5 hash for payment tracking |
| Logging | Winston | Structured JSON logging |

### 3.3 OCR Prescription Service — Python

| Category | Technology | Purpose |
|---|---|---|
| Framework | FastAPI | OCR REST API |
| OCR Engine (primary) | PaddleOCR 2.9 | Deep-learning OCR, Khmer support |
| OCR Engine (secondary) | Tesseract 5 (pytesseract) | Latin/English fallback OCR |
| Image Processing | OpenCV 4.8, Pillow | Preprocessing, layout analysis |
| Fuzzy Matching | rapidfuzz | Medication name correction |
| Validation | Pydantic v2 | Schema-based output validation |
| Async Server | Uvicorn | ASGI server |

### 3.4 Flutter Mobile Application

| Category | Technology | Purpose |
|---|---|---|
| Framework | Flutter / Dart | Cross-platform mobile (Android + iOS) |
| State Management | Provider 6 | Reactive state with ChangeNotifier |
| Local Database | sqflite | Offline dose events + sync queue |
| Secure Storage | flutter_secure_storage | JWT tokens (Keychain / Keystore) |
| Notifications | flutter_local_notifications | Offline-capable reminders |
| Connectivity | connectivity_plus | Online/offline detection |
| QR Scanner | mobile_scanner | Bakong QR code scanning |
| QR Display | qr_flutter | Generated QR display |
| Charts | fl_chart | Adherence trend visualizations |
| Localization | flutter_localizations + intl | Khmer (km) + English (en) |
| Camera / Gallery | image_picker | Prescription image capture for OCR |
| Sharing | share_plus | Export prescriptions |
| Timezone | timezone | Accurate reminder scheduling |

---

## 4. Service Implementation Details

### 4.1 Backend API (NestJS)

The backend is the central orchestrator. It is structured as **15 domain modules**, each encapsulating its own controller, service, and DTO layer.

#### Module Breakdown

```
src/modules/
├── auth/            — JWT, Google OAuth, OTP, account lock logic
├── users/           — Profile management, role handling
├── connections/     — Doctor ↔ Patient ↔ Family relationship graph
├── prescriptions/   — Prescription lifecycle + versioning
├── medications/     — Medication records within prescriptions
├── doses/           — DoseEvent generation + status tracking
├── adherence/       — Adherence statistics (Redis-cached)
├── notifications/   — In-app notification dispatch + missed-dose alerts
├── audit/           — Immutable audit log recording
├── subscriptions/   — Freemium/Premium/Family tier management
├── bakong-payment/  — Payment initiation relay to Bakong service
├── doctor-dashboard/— Doctor-side views of patient adherence
├── health-monitoring/— Vital signs recording + threshold alerts
├── ocr/             — Forward prescription images to OCR service
└── batch-medication/— Group medications into named batches
```

#### Authentication Flow

1. **Registration:** Patient or Doctor submits credentials → password hashed with `bcrypt` (12 rounds) → user created in PostgreSQL.
2. **Login:** Validates credentials → on success, issues `accessToken` (JWT, short-lived) and `refreshToken` (JWT, 7-day), stored client-side in secure storage.
3. **Account Lockout:** After 5 consecutive failed attempts → account locked for 15 minutes.
4. **Google OAuth:** ID token submitted to backend → verified against Google's public keys via `OAuth2Client` → user upserted.
5. **OTP Flow:** 6-digit OTP sent via email → verified within a time window for sensitive operations.
6. **Token Refresh:** Client sends refresh token → new access token issued without re-authentication.

```
POST /api/v1/auth/register/patient
POST /api/v1/auth/register/doctor
POST /api/v1/auth/login
POST /api/v1/auth/google
POST /api/v1/auth/refresh
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
```

#### Prescription Lifecycle

Prescriptions follow a strict state machine:

```
DRAFT ──activate──► ACTIVE ──pause──► PAUSED
                      │               │
                      └──resume───────┘
                      │
                      └──stop──► INACTIVE
```

When a prescription transitions to `ACTIVE`:
1. `DoseEvent` records are generated for each medication based on `morningDosage`, `daytimeDosage`, `nightDosage` fields.
2. A cron job (`@nestjs/schedule`) periodically checks for overdue `DUE` events and marks them `MISSED` after the grace period (`gracePeriodMinutes` per user, default 30 min).
3. Missed doses trigger family notification dispatch via `NotificationsService.sendMissedDoseAlert()`.

#### Versioning System

Every doctor modification to a prescription creates a new `PrescriptionVersion` record with a JSONB snapshot of the medications. The original prescription's `currentVersion` counter increments. No data is destructively deleted — old versions remain queryable for full history.

#### Connection System

The connection graph supports three roles: `PATIENT`, `DOCTOR`, `FAMILY_MEMBER`. A `Connection` record stores:
- `initiatorId` + `recipientId` (UUID foreign keys)
- `status`: `PENDING | ACCEPTED | REVOKED`
- `permissionLevel`: `NOT_ALLOWED | REQUEST | SELECTED | ALLOWED`

When a connection is accepted, the patient sets the permission level. All subsequent data access checks verify this level. Every access event is written to `AuditLog`.

#### Adherence Analytics

The `AdherenceService` computes daily, weekly, and monthly adherence percentages. Results are cached in Redis with a 5-minute TTL to avoid repeated database aggregation on dashboards.

```typescript
// Cache key pattern
`adherence:${patientId}:daily:${YYYY-MM-DD}`
`adherence:${patientId}:weekly:${YYYY-MM-DD}`
```

#### Health Monitoring Module

Patients can record vitals: `BLOOD_PRESSURE`, `GLUCOSE`, `HEART_RATE`, `WEIGHT`, `TEMPERATURE`, `SPO2`. Each vital type supports configurable per-patient thresholds (`VitalThreshold`). When a recorded value falls outside the threshold range, a `HealthAlert` is created with an appropriate `AlertSeverity` (`LOW | MEDIUM | HIGH | CRITICAL`), and a notification is dispatched.

---

### 4.2 Bakong Payment Service

This service runs on a **separate VPS** and is entirely isolated from the main backend's database. It communicates with both the Bakong NBC API and the main backend via HTTPS webhooks.

#### KHQR (Khmer QR) Implementation

The payment service implements the **EMV QR code specification** used by Bakong (National Bank of Cambodia). A KHQR string is constructed by assembling EMV TLV (Tag-Length-Value) data fields:

| Tag | Field | Value |
|---|---|---|
| 00 | Payload Format Indicator | `01` |
| 01 | Point of Initiation | `12` (dynamic) |
| 29 | Merchant Account (Bakong) | `kh.gov.nbc.bakong` + merchant ID + phone |
| 53 | Transaction Currency | `840` (USD) or `116` (KHR) |
| 54 | Transaction Amount | Dynamic per payment |
| 58 | Country Code | `KH` |
| 59 | Merchant Name | Configurable |
| 60 | Merchant City | Configurable |
| 62 | Additional Data | bill number, store label, terminal label |
| 63 | CRC | CRC16 checksum |

An MD5 hash of the final KHQR string is used as the payment tracking identifier. The Bakong API uses this hash to report payment status.

#### Payment Flow

```
1. Main backend receives subscription purchase request from Flutter
2. Main backend sends { userId, planType, amount } to Bakong service via encrypted REST call
3. Bakong service:
   a. Generates KHQR string + MD5 hash
   b. Creates QR code image (base64 PNG) via qrcode-generator
   c. Generates Bakong deeplink for in-app redirect
   d. Stores PaymentTransaction in its own PostgreSQL
   e. Returns { qrCode, qrImagePath, deepLink, transactionId } to main backend
4. Main backend relays QR data to Flutter
5. User scans QR in Bakong app and pays
6. Bakong NBC sends webhook to Bakong service
7. Bakong service validates MD5 hash and updates PaymentTransaction status
8. Bakong service calls main backend webhook → main backend updates Subscription tier
```

#### Payment Monitoring

For reliability, the Bakong service runs a background **polling monitor** that periodically queries the Bakong API (`/v1/transaction/checkMd5Hash`) for pending transactions. This handles cases where the webhook delivery fails. Retry logic with exponential backoff is implemented for transient API failures.

#### Subscription Plans

| Plan | Price | Features |
|---|---|---|
| `FREEMIUM` | Free | Basic medication tracking (5 GB storage) |
| `PREMIUM` | Paid | Full analytics, doctor collaboration, OCR scanning |
| `FAMILY_PREMIUM` | Paid | All Premium + family member accounts |

---

### 4.3 OCR Prescription Service

The OCR service processes images of physical Cambodian (H-EQIP format) prescriptions into structured JSON data.

#### Pipeline Architecture

The service implements a **5-stage pipeline** coordinated by `PipelineOrchestrator`:

```
Image Input
    │
    ▼ Stage 1: Preprocessing (preprocessor.py)
    │   - Convert to grayscale
    │   - Deskew (correct rotation)
    │   - Denoise (Gaussian blur, bilateral filter)
    │   - Adaptive threshold / binarization
    │   - Quality check (DPI estimation, blur detection)
    │
    ▼ Stage 2: Layout Analysis (layout.py)
    │   - Detect regions: header, patient info, clinical info, medication table, footer
    │   - Identify table bounding boxes
    │   - Column boundary detection (8 columns for H-EQIP format)
    │
    ▼ Stage 3: OCR Engine (ocr_engine.py)
    │   - PaddleOCR: Primary engine (supports Khmer script)
    │   - Tesseract: Fallback for Latin text regions
    │   - Per-region content-type hints (numeric, mixed, khmer)
    │
    ▼ Stage 4: Post-Processing (postprocessor.py)
    │   - Medication name fuzzy correction (rapidfuzz against lexicon)
    │   - Dosage normalization (numeric parsing)
    │   - Date/time format standardization
    │   - Khmer numeral conversion
    │
    ▼ Stage 5: Schema Formatting (formatter.py)
    │   - Map to Dynamic Universal Schema or Static Schema
    │   - Build extraction summary (confidence scores, warnings)
    │
    ▼ JSON Output
```

#### Column Mapping (H-EQIP Prescription Format)

Known column proportions (relative to table width):

```
[0.0, 0.043]   → item_number
[0.043, 0.322] → medication_name
[0.322, 0.458] → duration
[0.458, 0.568] → instructions
[0.568, 0.648] → morning
[0.648, 0.734] → midday
[0.734, 0.887] → afternoon
[0.887, 1.0]   → evening
```

#### Medication Lexicon

The service ships with two medication lexicons:
- `medications_en.txt` — English medication names
- `medications_km.txt` — Khmer medication names

`rapidfuzz` performs fuzzy matching against these lexicons to correct OCR recognition errors in medication names (e.g., `Amoxici11in` → `Amoxicillin`).

#### API Endpoint

```
POST /api/v1/ocr/scan
  Content-Type: multipart/form-data
  Body: { image: <file> }
  Response: { success, data: { header, patient, medications[], footer }, extraction_summary }
```

The main backend's `OcrModule` forwards images received from Flutter to this service via HTTP POST, then parses and returns the structured prescription data to the Flutter app for user review before saving.

---

### 4.4 Flutter Mobile Application

The Flutter app is the patient-facing interface. It communicates **only with the main NestJS backend** and never directly with Bakong or OCR services.

#### State Management

The app uses **Provider** (ChangeNotifier pattern) with one provider per domain:

| Provider | Responsibility |
|---|---|
| `AuthProvider` | JWT token lifecycle, login/logout state |
| `PrescriptionProvider` | Prescription list, status changes |
| `DoseProvider` | Dose events, mark taken/skipped |
| `ConnectionProvider` | Doctor/family connection management |
| `NotificationProvider` | In-app notification list and unread count |
| `SubscriptionProvider` | Current plan, upgrade flow |
| `DoctorDashboardProvider` | Doctor-specific patient overview |
| `HealthMonitoringProvider` | Vital signs recording and trends |
| `BatchProvider` | Grouped medication batches |
| `ThemeProvider` | Light/Dark theme preference (persisted) |
| `LocaleProvider` | Khmer/English locale preference (persisted) |
| `SyncService` | Connectivity monitoring + offline sync |

#### Localization

All user-facing text is fully localized in both English and Khmer via Flutter's `flutter_localizations` package. ARB files are stored in `lib/l10n/`. The `LocaleProvider` persists the user's language choice and rebuilds the entire widget tree when the language is switched.

#### Offline-First Implementation

The `SyncService` (singleton `ChangeNotifier`) monitors connectivity via `connectivity_plus`. The local database (`sqflite`) stores:
- Pending dose events (mark-taken actions performed offline)
- Prescription schedules for reminder firing
- A sync queue of all mutations performed while offline

When connectivity is restored, `SyncService.syncAll()` replays the queued actions to the backend in order, then pulls fresh server data.

**Notification Scheduling:** `flutter_local_notifications` + `timezone` schedules reminders at exact `DoseEvent.scheduledTime` values. These are scheduled locally and fire regardless of network state.

#### Security on Device

- All JWT tokens are stored in `flutter_secure_storage` which uses Android Keystore (encrypted shared preferences) and iOS Keychain.
- The `.env` file embedded in the assets contains only non-sensitive configuration (base URL, Google Client ID).
- Sensitive user data is stored in SQLite with platform-level encryption via secure storage keys.

---

## 5. Database Design

### 5.1 Main Database (PostgreSQL 17)

The main database uses **18 models** with comprehensive index coverage.

#### Core Entities and Relationships

```
User (1) ──── (M) Connection (M) ──── (1) User
User (1) ──── (M) Prescription [as patient]
User (1) ──── (M) Prescription [as doctor]
Prescription (1) ──── (M) Medication
Prescription (1) ──── (M) DoseEvent
Prescription (1) ──── (M) PrescriptionVersion
Medication (1) ──── (M) DoseEvent
User (1) ──── (1) Subscription
Subscription (1) ──── (M) FamilyMember
User (1) ──── (M) Notification
User (1) ──── (M) AuditLog
User (1) ──── (M) HealthVital
User (1) ──── (M) VitalThreshold
User (1) ──── (M) HealthAlert
User (1) ──── (M) MedicationBatch
MedicationBatch (1) ──── (M) Medication
User (1) ──── (M) DoctorNote [as doctor]
User (1) ──── (M) DoctorNote [as patient]
```

#### Index Strategy

All foreign keys are indexed. Additional composite indexes are defined for the most common query patterns:

| Table | Index | Query Pattern |
|---|---|---|
| `dose_events` | `(patientId, scheduledTime)` | Today's schedule |
| `dose_events` | `(patientId, status)` | Adherence calculation |
| `health_vitals` | `(patientId, vitalType, measuredAt)` | Trend queries |
| `audit_logs` | `(actionType, createdAt)` | Audit reporting |
| `connections` | `(initiatorId), (recipientId), (status)` | Graph traversal |
| `prescriptions` | `(patientId, status)` | Active prescription lookup |

#### Medication Dosage Storage

Dosage amounts per time period are stored as JSONB fields (`morningDosage`, `daytimeDosage`, `nightDosage`). This allows flexible dosage structures (e.g., "1 tablet + 5ml") without schema migrations as requirements evolve.

### 5.2 Bakong Payment Database (PostgreSQL — Isolated)

The Bakong service owns a completely separate database with only payment-relevant models:
- `PaymentTransaction` — KHQR metadata, MD5 hash, status, amount, currency
- `PaymentStatusHistory` — State transition audit trail
- `Subscription` (payment-facing) — Maps userId → plan tier, expiry

This isolation means a compromise of the payment database exposes zero medical data.

---

## 6. Security Implementation

### 6.1 Authentication & Authorization

| Mechanism | Details |
|---|---|
| Password hashing | bcrypt, 12 rounds (industry standard for medical data) |
| Access token | JWT, short-lived (configurable, typically 1h) |
| Refresh token | JWT, 7-day expiry, separate secret key |
| Account lockout | 5 failed attempts → locked 15 minutes |
| Role-based access | `PATIENT`, `DOCTOR`, `FAMILY_MEMBER` guards on all routes |
| Google OAuth | ID token verified server-side via Google's public keys |

### 6.2 Transport Security

- All services communicate over HTTPS only.
- `Helmet` middleware sets security headers: `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`, `Strict-Transport-Security`, `Content-Security-Policy`.
- CORS is configured to only allow explicitly whitelisted origins (`ALLOWED_ORIGINS` env var). No wildcard CORS in production.

### 6.3 Rate Limiting

Global throttler on the main backend: **100 requests per 60 seconds per IP** via `@nestjs/throttler`. The Bakong service implements its own rate limiting per payment endpoint to prevent QR flooding.

### 6.4 Input Validation

All API inputs are validated via `class-validator` DTOs with `ValidationPipe` configured in whitelist mode (`whitelist: true, forbidNonWhitelisted: true`). No unrecognized fields pass through. DTOs use strict type transformation.

### 6.5 Audit System

Every sensitive action writes an `AuditLog` record with:
- `actorId` + `actorRole`
- `actionType` (enum of 20+ action types)
- `resourceType` + `resourceId`
- `details` (JSON)
- `ipAddress`
- `createdAt`

This produces a tamper-evident, append-only audit trail for compliance and forensics. The log covers: connection changes, prescription mutations, dose events, data access, subscription changes, vital recordings, and emergency triggers.

### 6.6 Data Privacy

- Permission system ensures doctors and family members can only access patient data at the level the patient explicitly grants (`NOT_ALLOWED | REQUEST | SELECTED | ALLOWED`).
- All family and doctor access events generate `AuditLog` entries.
- Patients can revoke connections at any time, immediately removing access.
- Bakong payment data is stored in a completely separate database isolated from medical records.
- Secure storage on the mobile device uses platform-level hardware-backed encryption (Android Keystore, iOS Keychain).

---

## 7. Performance Strategy

### 7.1 Redis Caching

The main backend uses Redis as a distributed cache via `@nestjs/cache-manager`:

| Cache Key Pattern | TTL | Purpose |
|---|---|---|
| `adherence:{id}:daily:{date}` | 5 min | Daily adherence % |
| `adherence:{id}:weekly:{date}` | 5 min | Weekly adherence report |
| `adherence:{id}:monthly:{date}` | 5 min | Monthly trend data |
| User session data | 5 min (configurable) | Reduce DB lookups |

Cache failures are silent — the service falls back to PostgreSQL without throwing errors, ensuring resilience.

### 7.2 Database Query Optimization

- All foreign keys have explicit `@@index` declarations in Prisma schema.
- Composite indexes on the most frequently queried patterns (e.g., `patientId + scheduledTime` for dose lookups).
- Prisma's `fullTextSearch` preview feature is enabled for medication name searching.
- Cascade deletes are defined at the ORM level to keep the database consistent without orphaned records.

### 7.3 Response Compression

`compression` middleware (gzip) is applied globally on the main backend, significantly reducing payload size for large adherence history and prescription list responses.

### 7.4 Background Processing

- **Bull queues** (backed by Redis) handle asynchronous tasks: email sending, large batch dose generation, notification broadcasting.
- **Cron jobs** (`@nestjs/schedule`) run on a schedule for: missed-dose detection, subscription expiry checks, alert threshold evaluation.
- This prevents long-running operations from blocking the HTTP response cycle.

### 7.5 Flutter Performance

- `Provider` + `ChangeNotifier` provides fine-grained widget rebuilds — only the parts of the UI that depend on changed data rebuild.
- Local SQLite (`sqflite`) for offline data avoids network round trips for frequently accessed data (today's doses, cached prescriptions).
- `fl_chart` renders charts from pre-aggregated data structures, avoiding in-widget computation.

---

## 8. Offline-First Architecture

This is one of the most technically significant aspects of Das Tern. Cambodia has areas with unreliable internet connectivity, so the app must function fully offline for core features.

### 8.1 Local Data Layer

`DatabaseService` (singleton) manages a local SQLite database on the device containing:
- Active prescription schedules (synced from server on every connection)
- Today's and upcoming `DoseEvent` records
- A **sync queue** table: `{ id, action, endpoint, payload, created_at }`

### 8.2 Sync Queue Pattern

All mutations performed offline (mark dose taken, mark dose skipped) are:
1. Applied immediately to the local SQLite state (optimistic update)
2. Written to the sync queue table

When `SyncService` detects connectivity is restored:
```dart
// SyncService.syncAll()
1. Read all pending items from sync queue (ordered by created_at)
2. For each item:
   a. POST/PATCH to the backend endpoint
   b. On success: remove from sync queue
   c. On conflict: apply server-side resolution
3. Pull fresh data from server to overwrite stale local state
4. notifyListeners() to trigger UI refresh
```

### 8.3 Local Notification Scheduling

When prescriptions are synced, `NotificationService` schedules local notifications using `flutter_local_notifications`:

```dart
// For each DoseEvent
await notificationsPlugin.zonedSchedule(
  doseEvent.id.hashCode,
  'Time to take ${medication.name}',
  body,
  tz.TZDateTime.from(doseEvent.scheduledTime, tz.local),
  NotificationDetails(...),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
)
```

`exactAllowWhileIdle` ensures the notification fires even when the device is in Doze mode (Android battery optimization). This guarantees reminders fire offline at the correct local time using the `timezone` package for DST-aware scheduling.

---

## 9. Payment Flow (Bakong KHQR)

### 9.1 KHQR Technical Specification

KHQR follows the **EMV Merchant QR Code** specification (ISO 20022). The QR string is a concatenation of TLV fields:

```
Tag(2) + Length(2, zero-padded) + Value
Example: "5413" + "USD" → "5403USD" (Tag 54, Length 3, Value USD)
```

The final field is always a **CRC-16 checksum** (Tag 63) computed over all preceding fields using the CRC-CCITT (0xFFFF) polynomial.

### 9.2 Payment State Machine

```
PENDING ──payment received──► COMPLETED
PENDING ──timeout/failure──►  FAILED
PENDING ──user cancel──────►  CANCELLED
COMPLETED ──refund request──► REFUNDED
```

Every state transition creates a `PaymentStatusHistory` record with `oldStatus`, `newStatus`, `timestamp`, and optional `details` JSON.

### 9.3 Inter-Service Security

The main backend and Bakong service communicate using:
- **API Key authentication** in request headers (`X-API-Key`)
- Request payload includes a **HMAC-SHA256 signature** for tamper detection
- The Bakong service only accepts callbacks from the main backend's whitelisted IP range
- All inter-service communication is over HTTPS

---

## 10. API Design & Communication

### 10.1 RESTful API Structure

```
/api/v1/auth/...
/api/v1/users/...
/api/v1/connections/...
/api/v1/prescriptions/...
/api/v1/medications/...
/api/v1/doses/...
/api/v1/adherence/...
/api/v1/notifications/...
/api/v1/subscriptions/...
/api/v1/payments/...
/api/v1/doctor-dashboard/...
/api/v1/health-monitoring/...
/api/v1/ocr/...
/api/v1/batch-medication/...
/api/v1/audit/...
```

### 10.2 Standard Response Shape

All endpoints return a consistent JSON envelope:

```json
{
  "success": true,
  "data": { ... },
  "message": "Operation completed",
  "timestamp": "2026-02-18T10:00:00Z"
}
```

Error responses:
```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": ["field: error description"]
}
```

### 10.3 Flutter ↔ Backend Contract

Flutter services use `http` package with `FlutterSecureStorage` for token management:
- `Authorization: Bearer <accessToken>` on every authenticated request
- Auto-refresh: if a 401 is received, the `AuthProvider` attempts a token refresh before replaying the original request
- Base URL is configured via `.env` (`API_BASE_URL`) injected at build time via `flutter_dotenv`

---

## 11. Infrastructure & Deployment

### 11.1 Docker Services (Main Backend VPS)

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:17
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Named volume for persistence
    environment:
      POSTGRES_DB: dastern
      POSTGRES_USER: ...
      POSTGRES_PASSWORD: ...

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data                          # Persistent Redis AOF
```

Only PostgreSQL and Redis run inside Docker. The NestJS backend runs as a Node.js process (or in a separate container) and connects to these Docker services.

### 11.2 Bakong Service VPS (Separate)

The Bakong payment service runs on a separate VPS with:
- Its own PostgreSQL instance (Docker or native)
- Its own Redis instance
- No network access to the main backend's database
- Inbound: webhook from Bakong NBC, API calls from main backend
- Outbound: API calls to Bakong NBC, webhook callbacks to main backend

### 11.3 OCR Service

The OCR service runs as a standalone FastAPI/Uvicorn process. Model loading (PaddleOCR) happens once at startup via the `lifespan` context manager and is held in memory for the duration of the process lifetime, avoiding per-request model loading overhead.

### 11.4 Environment Configuration

All services use `.env` files for environment-specific configuration. Key variables:

**Main Backend:**
```
DATABASE_URL=postgresql://...
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=...
JWT_SECRET=...
JWT_REFRESH_SECRET=...
GOOGLE_CLIENT_ID=...
ALLOWED_ORIGINS=https://app.dastern.com
BAKONG_SERVICE_URL=https://payment.dastern.com
BAKONG_API_KEY=...
```

**Bakong Service:**
```
DATABASE_URL=postgresql://...
BAKONG_MERCHANT_ID=...
BAKONG_PHONE_NUMBER=...
MAIN_BACKEND_URL=...
MAIN_BACKEND_API_KEY=...
```

---

## 12. Cross-Cutting Concerns

### 12.1 Logging

- **Backend:** Uses NestJS built-in logger with structured output. Winston is available for file-based structured JSON logging.
- **Bakong Service:** Winston with separate log files (`logs/`) for payment events, errors, and access logs. Structured JSON format enables log aggregation.
- **OCR Service:** Python standard `logging` module, output to stdout for container log collection.
- **Flutter:** `LoggerService` singleton with severity levels (debug, info, success, warning, error) and structured metadata. Errors are surfaced to `FlutterError.onError` for crash reporting integration.

### 12.2 Error Handling

- NestJS exception filters provide consistent HTTP error responses.
- Bakong service retry utility (`retry.ts`) implements exponential backoff for Bakong API calls.
- Flutter uses `try/catch` throughout providers with graceful UI error states (no raw exception surfaces to users).
- OCR pipeline catches per-stage failures, returning partial results with extraction warnings rather than crashing entirely.

### 12.3 Internationalization

The platform is built from the ground up for bilingual Khmer/English operation:
- Flutter: ARB-based localization, instant language switching via `LocaleProvider`, all strings in `lib/l10n/`
- Backend: User language preference stored in the `User` model (`language: Language @default(KHMER)`)
- Database: Medications store both `medicineName` (English) and `medicineNameKhmer` fields
- OCR: Tesseract configured with `khm+eng` language pack for mixed-language prescriptions

### 12.4 Testing Strategy

| Layer | Tools |
|---|---|
| Backend unit tests | Jest (`@nestjs/testing`) |
| Backend E2E tests | Jest + Supertest |
| Flutter widget tests | `flutter_test` |
| Flutter integration tests | `integration_test` package |
| OCR pipeline tests | pytest + test prescription images |
| API contract tests | Shell scripts (`test-api.sh`) |

### 12.5 Code Quality

- **Backend:** ESLint + Prettier, TypeScript strict mode
- **Flutter:** `flutter_lints` (strict), `flutter analyze` must show 0 issues before any commit
- **OCR:** pyproject.toml with `ruff` or similar linters configured

---

## Summary

Das Tern is a production-grade, full-stack medication management platform purpose-built for the Cambodian healthcare context. Its most technically challenging characteristics are:

1. **Offline-first mobile design** with local SQLite, sync queues, and scheduled local notifications that fire regardless of connectivity.
2. **Strong data ownership model** enforced at both the API (permission guards) and database (audit logs) levels.
3. **Isolated payment architecture** keeping medical and payment data in entirely separate databases on separate servers.
4. **Bilingual OCR pipeline** combining PaddleOCR (Khmer-capable deep learning) with Tesseract for robust prescription scanning.
5. **Comprehensive security posture** with bcrypt hashing, JWT dual-token auth, account lockout, Helmet headers, strict CORS, rate limiting, and full audit logging.
