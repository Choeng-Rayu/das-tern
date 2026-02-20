# Das Tern — Flutter Mobile Frontend

**Das Tern** (ដាស ទឺន) is a medication management platform for Cambodia. This document is a detailed implementation report of the Flutter mobile client (`das_tern_mcp`).

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Directory Structure](#3-directory-structure)
4. [Application Entry Point](#4-application-entry-point)
5. [Routing](#5-routing)
6. [State Management — Providers](#6-state-management--providers)
7. [Services Layer](#7-services-layer)
8. [UI Architecture](#8-ui-architecture)
   - [Theme System](#81-theme-system)
   - [Common Widget Library](#82-common-widget-library)
   - [Screen Catalogue](#83-screen-catalogue)
9. [Feature Modules](#9-feature-modules)
   - [Authentication](#91-authentication)
   - [Patient Dashboard](#92-patient-dashboard)
   - [Doctor Dashboard](#93-doctor-dashboard)
   - [Prescription & Medication](#94-prescription--medication)
   - [Health Monitoring & Vitals](#95-health-monitoring--vitals)
   - [Family / Caregiver Access](#96-family--caregiver-access)
   - [Bakong Payment Integration](#97-bakong-payment-integration)
   - [Subscription & Plans](#98-subscription--plans)
   - [Notifications](#99-notifications)
10. [Offline Support](#10-offline-support)
11. [Localization (EN / KM)](#11-localization-en--km)
12. [Security](#12-security)
13. [Models](#13-models)
14. [Runtime Configuration](#14-runtime-configuration)
15. [Code Quality Rules](#15-code-quality-rules)

---

## 1. Project Overview

| Property | Value |
|---|---|
| App name | Das Tern |
| Package | `das_tern_mcp` |
| Flutter SDK | `^3.10.7` |
| Version | `1.0.0+1` |
| Target platforms | Android, iOS |
| Backend | NestJS REST API at `/api/v1` |
| Languages supported | English (`en`), Khmer (`km`) |

The app serves two user roles sourced from the backend:

- **PATIENT** — manages own medications, tracks adherence, views vitals, grants caregiver access.
- **DOCTOR** — monitors patients, creates prescriptions, views patient details and adherence analytics.

---

## 2. Tech Stack & Dependencies

### Core

| Package | Purpose |
|---|---|
| `flutter` + `flutter_localizations` | Framework + i18n base |
| `provider ^6.1.1` | State management (ChangeNotifier pattern) |
| `http ^1.1.2` + `http_parser ^4.0.2` | HTTP REST client |
| `flutter_secure_storage ^9.2.4` | Encrypted token storage (Android EncryptedSharedPreferences / iOS Keychain) |
| `flutter_dotenv ^5.1.0` | `.env` runtime configuration |
| `intl ^0.20.2` | Date/number formatting + ARB localizations |

### Offline / Local Storage

| Package | Purpose |
|---|---|
| `sqflite ^2.3.0` | Local SQLite database (dose cache, sync queue, prescriptions) |
| `path_provider ^2.1.1` + `path ^1.9.0` | File-system path resolution |
| `shared_preferences ^2.2.2` | Lightweight key-value storage (theme, locale prefs) |
| `connectivity_plus ^5.0.2` | Network state monitoring |

### UI & Media

| Package | Purpose |
|---|---|
| `cupertino_icons ^1.0.8` | iOS-style icon set |
| `fl_chart ^0.69.0` | Line/bar charts for adherence and vitals trends |
| `qr_flutter ^4.1.0` | QR code rendering (payment QR display) |
| `mobile_scanner ^5.1.1` | Camera-based QR code scanner |
| `image_picker ^1.0.7` | Camera / gallery access for OCR prescription scanning |
| `share_plus ^9.0.0` | Native share sheet |

### Notifications & Auth

| Package | Purpose |
|---|---|
| `flutter_local_notifications ^17.2.3` + `timezone ^0.9.4` | Scheduled local dose reminders |
| `google_sign_in ^6.2.1` | Google OAuth login |

---

## 3. Directory Structure

```
lib/
├── main.dart                  # App entry point, provider wiring, MaterialApp
├── l10n/                      # Localization ARB files + generated delegates
│   ├── app_en.arb             # English strings (~870 keys)
│   ├── app_km.arb             # Khmer strings (full translation)
│   ├── app_localizations.dart # Generated delegate base class
│   ├── app_localizations_en.dart
│   └── app_localizations_km.dart
├── models/                    # Dart data models (fromJson / toJson)
│   ├── batch_model/
│   ├── connection_model/
│   ├── country_model.dart
│   ├── doctor_dashboard_model/
│   ├── doctor_model/
│   ├── dose_event_model/
│   ├── enums_model/           # MedicationType, DoseStatus, etc.
│   ├── health_model/          # HealthVital, VitalThreshold, HealthAlert
│   ├── medication_model/
│   ├── notification_model/
│   ├── patient_model/
│   ├── prescription_model/
│   ├── user_model/
│   └── users_models/
├── providers/                 # ChangeNotifier state providers
│   ├── auth_provider.dart
│   ├── adherence_provider.dart
│   ├── batch_provider.dart
│   ├── connection_provider.dart
│   ├── doctor_dashboard_provider.dart
│   ├── dose_provider.dart
│   ├── health_monitoring_provider.dart
│   ├── locale_provider.dart
│   ├── notification_provider.dart
│   ├── prescription_provider.dart
│   └── subscription_provider.dart
├── services/                  # Infrastructure services (singletons)
│   ├── api_service.dart       # HTTP client, 1479 lines, full API coverage
│   ├── database_service.dart  # SQLite helper, 592 lines
│   ├── notification_service.dart
│   ├── sync_service.dart      # Offline sync queue processor
│   └── logger_service.dart    # Structured logging
└── ui/
    ├── theme/
    │   ├── app_colors.dart
    │   ├── app_spacing.dart
    │   ├── app_typography.dart
    │   ├── dark_theme.dart
    │   ├── light_theme.dart
    │   └── theme_provider.dart
    ├── widgets/               # Reusable shared widgets
    │   ├── common_widgets.dart        # 548-line base widget library
    │   ├── auth_widgets.dart
    │   ├── language_switcher.dart
    │   ├── medicine_form_widget.dart
    │   └── telegram_phone_field.dart
    └── screens/
        ├── splash_screen.dart
        ├── prescription_detail_screen.dart
        ├── auth/                      # 7 auth screens
        ├── patient/                   # 22 patient screens
        ├── doctor/                    # 10 doctor screens
        └── family_ui/                 # 10 caregiver screens
utils/
├── api_constants.dart         # Network endpoints & timeouts
└── app_router.dart            # Centralized named-route map (~85 routes)
```

---

## 4. Application Entry Point

`lib/main.dart` performs the following sequence on startup:

1. Binds Flutter engine (`WidgetsFlutterBinding.ensureInitialized`).
2. Loads `.env` via `flutter_dotenv` (contains `API_BASE_URL`, `GOOGLE_CLIENT_ID`).
3. Initialises `NotificationService` (registers notification channels, restores scheduled alarms).
4. Starts `SyncService.startListening()` (subscribes to connectivity stream).
5. Builds `DasTernApp` wrapped in `MultiProvider` with all 12 providers.
6. `MaterialApp` is configured with:
   - `lightTheme` / `darkTheme` driven by `ThemeProvider`
   - `locale` driven by `LocaleProvider`
   - `AppLocalizations.delegate` + Flutter material/cupertino delegates
   - Named-route generation via `AppRouter.generateRoute`

---

## 5. Routing

All routes are declared as `static const String` constants in `AppRouter` and dispatched through `onGenerateRoute`. There are **~36 named routes** grouped into:

| Group | Example Routes |
|---|---|
| Core | `/` (splash), `/login`, `/register-role` |
| Auth | `/register/patient`, `/register/doctor`, `/otp-verification`, `/forgot-password`, `/reset-password` |
| Patient shell | `/patient` |
| Doctor shell | `/doctor`, `/doctor/patient-detail` |
| Family | `/family/connect`, `/family/access-level`, `/family/token-display`, `/family/scan`, `/family/enter-code`, `/family/preview`, `/family/access-list`, `/family/caregiver-dashboard`, `/family/grace-period`, `/family/history` |
| Subscription / Payment | `/subscription/upgrade`, `/subscription/payment-method`, `/subscription/bakong-payment`, `/subscription/qr-code`, `/subscription/success` |
| Prescriptions | `/doctor/create-prescription`, `/patient/create-medicine`, `/patient/medication-choice`, `/patient/create-batch`, `/patient/batch-detail`, `/patient/ocr-preview`, `/prescription/detail` |
| Vitals | `/patient/vitals/record`, `/patient/vitals/trend`, `/patient/vitals/thresholds`, `/patient/emergency` |

---

## 6. State Management — Providers

All providers extend `ChangeNotifier` and are registered in `MultiProvider` at the root. Each provider is a thin command layer: it calls `ApiService` (or `DatabaseService` for offline data), updates internal state, and calls `notifyListeners()`.

| Provider | Responsibility |
|---|---|
| `AuthProvider` | Login (email/phone + Google OAuth), register, OTP, token refresh, profile load, logout |
| `DoseProvider` | Today's dose events, mark taken/missed/skipped, offline queue |
| `PrescriptionProvider` | CRUD prescriptions, offline cache via SQLite, active-count computed property |
| `AdherenceProvider` | Today / weekly / monthly / trend statistics from `/api/v1/adherence/*` |
| `HealthMonitoringProvider` | Vitals fetch, vital trends, thresholds, health alerts |
| `ConnectionProvider` | Doctor–patient connections, caregiver token generation, nudges, access levels |
| `DoctorDashboardProvider` | Dashboard stats, patient list, patient detail |
| `BatchProvider` | Medicine batches (create, update, mark empty) |
| `NotificationProvider` | In-app notifications fetch & mark-read |
| `SubscriptionProvider` | Subscription plan details, Bakong payment initiation |
| `ThemeProvider` | Light/dark mode with `SharedPreferences` persistence |
| `LocaleProvider` | `en` / `km` locale with `SharedPreferences` persistence |

---

## 7. Services Layer

### 7.1 `ApiService` (1 479 lines)

Singleton HTTP client for all calls to the NestJS backend at `$API_BASE_URL/api/v1`.

Key features:
- **Auto token refresh**: on any `401` response it silently calls `/auth/refresh`, retries the original request, and saves new tokens.
- **Encrypted storage**: access and refresh tokens stored via `flutter_secure_storage` using Android EncryptedSharedPreferences and iOS Keychain.
- **HTTPS enforcement**: `assert` in `baseUrl` getter that rejects non-HTTPS URLs in release mode.
- **Request logging**: every request/response logged through `LoggerService`.
- API coverage: auth, users, prescriptions, doses, adherence, vitals, health alerts, connections, doctor dashboard, batches, OCR, notifications, subscriptions, payments.

### 7.2 `DatabaseService` (592 lines)

Local SQLite database (`das_tern.db`, schema version 3) with the following tables:

| Table | Purpose |
|---|---|
| `dose_events` | Cached dose schedule for offline viewing and local reminder scheduling |
| `sync_queue` | Pending mutations (mark-taken, etc.) to replay when connectivity returns |
| `prescriptions` | Cached prescription payloads for offline access |
| `medications` | Cached medication list |
| `vital_signs` | Cached vital readings |
| `notifications` | Cached notification list |

### 7.3 `SyncService`

Monitors `ConnectivityResult` via `connectivity_plus`. When the device transitions from offline → online it drains the `sync_queue` table, replaying each action against the API with retry logic. Exposes `isOnline`, `isSyncing`, and `pendingCount` to the UI via `ChangeNotifier`.

### 7.4 `NotificationService`

Wraps `flutter_local_notifications`. Initialises Android (`@drawable/ic_notification`) and iOS notification channels on startup. Provides `scheduleReminder(doseEvent)` and `cancelReminder(id)` used by `DoseProvider` when prescriptions change.

### 7.5 `LoggerService`

Structured singleton logger with levels: `debug`, `info`, `success`, `warning`, `error`, `stateChange`. Output is coloured and tagged with a component name for easy filtering in device logs.

---

## 8. UI Architecture

### 8.1 Theme System

The theme system follows a **design-token** approach:

```
AppColors        → colour palette (primary, status, neutral, dark variants)
AppSpacing       → spacing scale (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48)
AppTypography    → named text styles (h1–h3, body, bodySmall, caption, button, *OnDark variants)
AppRadius        → border-radius tokens
light_theme.dart → full Material ThemeData (light)
dark_theme.dart  → full Material ThemeData (dark)
ThemeProvider    → ThemeMode enum, persisted in SharedPreferences
```

Key design tokens:

| Token | Value |
|---|---|
| `primaryBlue` | `#2D5BFF` |
| `darkBlue` | `#1A2744` |
| `alertRed` | `#E53935` |
| `successGreen` | `#4CAF50` |
| `morningYellow` | `#FFC107` |
| `afternoonOrange` | `#FF6B35` |
| `nightPurple` | `#6B4AA3` |
| `darkPrimary` (dark mode) | `#5C7CFF` |

### 8.2 Common Widget Library

`lib/ui/widgets/common_widgets.dart` (548 lines) provides the base reusable components:

| Widget | Description |
|---|---|
| `PrimaryButton` | Full-width 48 dp button; supports `isLoading` spinner, `isOutlined` variant, optional leading `icon` |
| `AppCard` | Material card with `InkWell` tap ripple and standard radius |
| `StatusBadge` | Coloured pill badge for prescription/connection/adherence statuses |
| `AppBottomNavBar` | Custom bottom navigation bar using `AppNavItem`; active/inactive icon pair |
| `AppNavItem` | Data class holding `icon`, `activeIcon`, `label` for nav bar items |
| `LoadingWidget` | Centred `CircularProgressIndicator` |
| `ErrorWidget` | Error message card with optional retry callback |
| `EmptyStateWidget` | Illustrative empty-state with icon, title, and subtitle |

Additional widget files:
- **`auth_widgets.dart`** — branded form fields, OTP input boxes, social sign-in buttons.
- **`medicine_form_widget.dart`** — reusable dosage / frequency / time-period form sections shared by patient and doctor prescription flows.
- **`telegram_phone_field.dart`** — country-code picker + phone number field matching Telegram UX pattern.
- **`language_switcher.dart`** — EN/KM toggle integrated into settings screens.

### 8.3 Screen Catalogue

#### Auth Screens (`lib/ui/screens/auth/`)

| Screen | Route | Description |
|---|---|---|
| `SplashScreen` | `/` | Logo + auth-state check, redirects to `/login` or role shell |
| `LoginScreen` | `/login` | Email/phone + password, Google OAuth button |
| `RegisterRoleScreen` | `/register-role` | Role selector (Patient / Doctor) |
| `RegisterPatientScreen` | `/register/patient` | 2-step patient registration form |
| `RegisterDoctorScreen` | `/register/doctor` | 2-step doctor registration with professional info |
| `OtpVerificationScreen` | `/otp-verification` | 6-digit OTP input with resend timer |
| `ForgotPasswordScreen` | `/forgot-password` | Phone/email input → OTP trigger |
| `ResetPasswordScreen` | `/reset-password` | New password + confirm |

#### Patient Screens (`lib/ui/screens/patient/`)

| Screen | Route | Description |
|---|---|---|
| `PatientShell` | `/patient` | 5-tab `IndexedStack` shell (Home, Medications, Scan, Family, Settings) |
| `PatientHomeTab` | — | Today's doses dashboard, adherence ring, urgent actions |
| `PatientMedicationsTab` | — | Medication list with batch tracking |
| `PatientScanTab` | — | Camera scanner for QR prescription import |
| `PatientFamilyTab` | — | Family connection management |
| `PatientSettingsTab` | — | Theme, language, profile, logout |
| `PatientNotificationsTab` | — | In-app notification feed |
| `PatientHistoryTab` | — | Past dose and prescription history |
| `PatientProfileTab` | — | Profile view/edit |
| `RecordVitalScreen` | `/patient/vitals/record` | Record blood pressure, glucose, weight, temperature, O₂ |
| `VitalTrendScreen` | `/patient/vitals/trend` | `fl_chart` line chart with date-range filter |
| `VitalThresholdsScreen` | `/patient/vitals/thresholds` | Set personal alert thresholds per vital type |
| `EmergencyScreen` | `/patient/emergency` | Emergency contact list + SOS actions |
| `CreatePatientMedicineScreen` | `/patient/create-medicine` | Self-add medication form |
| `MedicationChoiceScreen` | `/patient/medication-choice` | Choose between OCR scan or manual entry |
| `OcrPreviewScreen` | `/patient/ocr-preview` | Preview OCR-extracted prescription text before saving |
| `CreateBatchScreen` | `/patient/create-batch` | Add medicine purchase batch (quantity, expiry) |
| `BatchDetailScreen` | `/patient/batch-detail` | Batch info, usage history |
| `UpgradePlanScreen` | `/subscription/upgrade` | Subscription plan comparison cards |
| `PaymentMethodScreen` | `/subscription/payment-method` | Select payment method (Bakong / other) |
| `BakongPaymentScreen` | `/subscription/bakong-payment` | Enter Bakong account details |
| `PaymentQrScreen` | `/subscription/qr-code` | Display Bakong QR code, poll for payment |
| `PaymentSuccessScreen` | `/subscription/success` | Success confirmation, navigate home |

#### Doctor Screens (`lib/ui/screens/doctor/`)

| Screen | Route | Description |
|---|---|---|
| `DoctorShell` | `/doctor` | 5-tab shell (Home, Patients, Prescriptions, History, Settings) |
| `DoctorHomeTab` | — | Dashboard stats, quick-action buttons, recent patient alerts |
| `DoctorPatientsTab` | — | Patient list with search and filter |
| `DoctorPrescriptionsTab` | — | Active prescriptions list |
| `DoctorPrescriptionHistoryTab` | — | All historical prescriptions with status filter |
| `DoctorProfileTab` | — | Doctor profile |
| `DoctorSettingsTab` | — | Theme, language, logout |
| `DoctorNotificationsTab` | — | Notification feed |
| `PatientDetailScreen` | `/doctor/patient-detail` | Full patient view: vitals, doses, adherence charts |
| `CreatePrescriptionScreen` | `/doctor/create-prescription` | Multi-medication prescription builder |

#### Family / Caregiver Screens (`lib/ui/screens/family_ui/`)

| Screen | Route | Description |
|---|---|---|
| `FamilyConnectIntroScreen` | `/family/connect` | Intro + role chooser (generate token vs scan) |
| `AccessLevelSelectionScreen` | `/family/access-level` | Set read-only vs full-access |
| `TokenDisplayScreen` | `/family/token-display` | Show generated 6-char token + QR code |
| `QrScannerScreen` | `/family/scan` | Camera scanner to connect via caregiver QR |
| `CodeEntryScreen` | `/family/enter-code` | Manual token entry fallback |
| `ConnectionPreviewScreen` | `/family/preview` | Preview connection details before confirming |
| `FamilyAccessListScreen` | `/family/access-list` | Manage all active caregiver connections |
| `CaregiverDashboardScreen` | `/family/caregiver-dashboard` | Caregiver view of patient doses and vitals |
| `GracePeriodSettingsScreen` | `/family/grace-period` | Configure confirmation grace window |
| `ConnectionHistoryScreen` | `/family/history` | Past and revoked connections |

---

## 9. Feature Modules

### 9.1 Authentication

- Email/phone + password login via `POST /auth/login`.
- Google OAuth via `google_sign_in` → `POST /auth/google`.
- Phone-based OTP verification: `POST /auth/send-otp` → `POST /auth/verify-otp`.
- Automatic JWT refresh: `401` interceptor in `ApiService` calls `POST /auth/refresh`.
- Tokens stored in encrypted storage (`accessToken`, `refreshToken`).
- Role-based redirect: `DOCTOR` → `DoctorShell`, `PATIENT` → `PatientShell`.

### 9.2 Patient Dashboard

- Today's dose list fetched from `GET /doses/today`.
- Dose actions: **Take** (`POST /doses/:id/take`), **Skip** (`POST /doses/:id/skip`), **Missed** (`POST /doses/:id/missed`).
- When offline, actions are stored in the `sync_queue` SQLite table and replayed on reconnection.
- Adherence ring widget showing percentage taken vs total for the day.
- Weekly bar chart using `fl_chart` sourced from `AdherenceProvider`.

### 9.3 Doctor Dashboard

- Summary stats: total patients, active prescriptions, pending connections, today's alerts.
- Patient search and management via `ConnectionProvider` + `DoctorDashboardProvider`.
- `PatientDetailScreen` shows: vitals chart, dose adherence, active prescriptions, and dose history for the selected patient.

### 9.4 Prescription & Medication

**Doctor flow:**
- `CreatePrescriptionScreen` — builds a multi-medication prescription with dosage, frequency, time-period (morning/afternoon/night), start/end dates, and instructions.
- Submitted via `POST /prescriptions`.

**Patient flow:**
- `MedicationChoiceScreen` → OCR camera scan (`image_picker`) OR manual entry.
- OCR image uploaded to `POST /prescriptions/ocr`; result displayed in `OcrPreviewScreen` for editing before saving.
- `CreatePatientMedicineScreen` — manual self-managed medication form.
- `CreateBatchScreen` / `BatchDetailScreen` — track physical medicine purchase batches for stock management.

### 9.5 Health Monitoring & Vitals

- Supported vital types: **Blood Pressure** (systolic/diastolic), **Blood Glucose**, **Weight**, **Temperature**, **Blood Oxygen (SpO₂)**.
- `RecordVitalScreen` — input form with unit labels and validation.
- `VitalTrendScreen` — date-range selectable `fl_chart` line chart per vital type.
- `VitalThresholdsScreen` — personal min/max thresholds; server generates `HealthAlert` when a reading breaches thresholds.
- `EmergencyScreen` — emergency contact list with phone-call deep-link.

### 9.6 Family / Caregiver Access

Patients can grant limited access to family members or caregivers:

1. Patient selects access level (read-only or full access) and generates a 6-character token + QR code via `POST /connections/token`.
2. Caregiver scans the QR or enters the code to connect via `POST /connections/connect-by-token`.
3. A `ConnectionPreviewScreen` shows the patient's name and access level before confirmation.
4. Once connected, caregivers see a `CaregiverDashboardScreen` showing the patient's today dose list and latest vitals.
5. `GracePeriodSettingsScreen` lets the patient configure a window before access expires.
6. Patient can revoke any connection from `FamilyAccessListScreen` via `DELETE /connections/:id`.

### 9.7 Bakong Payment Integration

Full in-app Bakong QR payment flow:

1. `UpgradePlanScreen` — compare subscription tiers and select plan.
2. `PaymentMethodScreen` — choose payment method (Bakong selected).
3. `BakongPaymentScreen` — enter Bakong account number, trigger `POST /subscriptions/bakong-initiate`.
4. Backend calls `bakong_service` (separate VPS) which generates a QR code.
5. `PaymentQrScreen` — renders QR via `qr_flutter`, polls `GET /subscriptions/payment-status/:txId` every 3 seconds.
6. On confirmed payment: navigates to `PaymentSuccessScreen` with plan details.

### 9.8 Subscription & Plans

`SubscriptionProvider` manages:
- `GET /subscriptions/plans` — fetch plan list.
- `GET /subscriptions/my-subscription` — current subscription state.
- Plan features and limits displayed in `UpgradePlanScreen` comparison cards.

### 9.9 Notifications

- `NotificationProvider` fetches in-app notifications from `GET /notifications`.
- Mark single/all-read via `PATCH /notifications/:id/read` and `PATCH /notifications/read-all`.
- `NotificationService` schedules local push reminders using `flutter_local_notifications`.
- Reminders are scheduled per dose event and cancelled when prescriptions are deactivated.

---

## 10. Offline Support

The app implements a full offline-first architecture:

| Layer | Mechanism |
|---|---|
| Connectivity detection | `connectivity_plus` stream in `SyncService` |
| Dose reading offline | `dose_events` SQLite table populated on fetch |
| Prescription reading offline | `prescriptions` SQLite table populated on fetch |
| Mutations offline | Written to `sync_queue` table with action, endpoint, method, body |
| Sync on reconnect | `SyncService.syncAll()` drains queue, replays mutations, refreshes data |
| User feedback | `SyncService.pendingCount` surfaced as a badge in the UI |

The `PrescriptionProvider` and `DoseProvider` always attempt the API first; on failure (or when `isOnline == false`) they fall through to the SQLite cache.

---

## 11. Localization (EN / KM)

The app fully supports **English** and **Khmer** via Flutter's `gen-l10n` system.

```
l10n.yaml              → configuration (arb-dir: lib/l10n, output-class: AppLocalizations)
lib/l10n/app_en.arb   → ~870 English string keys
lib/l10n/app_km.arb   → full Khmer translation of all keys
```

Strings are accessed as `AppLocalizations.of(context)!.someKey` throughout all screens and widgets. The `LocaleProvider` persists the user's choice in `SharedPreferences` and is consumed by `MaterialApp.locale`.

The `LanguageSwitcher` widget (`lib/ui/widgets/language_switcher.dart`) is embedded in both the patient and doctor settings tabs.

---

## 12. Security

| Concern | Implementation |
|---|---|
| Token storage | `flutter_secure_storage`: Android EncryptedSharedPreferences, iOS Keychain |
| HTTPS enforcement | `ApiService.baseUrl` asserts `https://` in release mode |
| JWT auto-refresh | Silent retry on `401` without user disruption |
| Google OAuth | `serverClientId` only loaded from `.env`, never hardcoded |
| Sensitive config | All secrets in `.env` (excluded from version control via `.gitignore`) |
| Android | `encryptedSharedPreferences: true` for secure storage |
| iOS | `KeychainAccessibility.first_unlock` for background token access |

---

## 13. Models

All models are plain Dart classes with `fromJson` factory constructors and `toJson` methods. Key model groups:

| Directory | Models |
|---|---|
| `prescription_model/` | `Prescription`, `PrescriptionMedication` |
| `dose_event_model/` | `DoseEvent` with `DoseStatus` enum |
| `health_model/` | `HealthVital`, `VitalThreshold`, `HealthAlert` |
| `connection_model/` | `Connection` with `ConnectionStatus` enum |
| `medication_model/` | `Medication`, `MedicationBatch` |
| `user_model/` | `UserModel` with role, profile fields |
| `doctor_model/` | `DoctorModel` with specialty, license fields |
| `patient_model/` | `PatientModel` with health info |
| `doctor_dashboard_model/` | Dashboard stats aggregation model |
| `notification_model/` | `NotificationModel` |
| `batch_model/` | `MedicineBatch` with expiry and quantity |
| `enums_model/` | `MedicationType`, `TimePeriod`, `DoseStatus`, etc. |
| `country_model.dart` | Country code list for phone fields |

---

## 14. Runtime Configuration

The app loads `.env` at startup:

| Variable | Description |
|---|---|
| `API_BASE_URL` | Full backend URL e.g. `http://192.168.0.10:3001/api/v1` |
| `GOOGLE_CLIENT_ID` | Google OAuth Web Client ID for `google_sign_in` |

For physical device testing, update `ApiConstants.hostIpAddress` in `lib/utils/api_constants.dart` to your machine's LAN IP. The constant `USE_ANDROID_EMULATOR=true` can be set via `--dart-define` to switch to the emulator host `10.0.2.2`.

---

## 15. Code Quality Rules

Per the project architecture rules, all Flutter code must satisfy these criteria before being considered complete:

```bash
# Step 1 — Must show 0 issues before any testing
flutter analyze

# Step 2 — Stricter pass (no info-level warnings either)
flutter analyze --no-fatal-infos

# Step 3 — Run widget/unit tests
flutter test
```

All widgets are designed following the **scalability-first** principle:
- Base widgets with maximum configurability via constructor parameters.
- Specialised widgets that compose or extend base widgets.
- No hardcoded string literals — all text goes through `AppLocalizations`.
- No hardcoded colour/spacing values — all use `AppColors`, `AppSpacing`, `AppTypography` tokens.
- Common widgets live in `lib/ui/widgets/common_widgets.dart`.
- Feature-specific widgets are co-located with their feature screens.
