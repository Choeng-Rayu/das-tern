# DAS TERN MCP - Refactoring Plan

## Overview

**App:** DAS TERN MCP (Medication Companion App)
**Current State:** 144 Dart files, Provider-based state management, offline-first design
**Target Architecture:** MVVM + Layered Clean Architecture (as per `flutter-clean-architecture-guide.md`)
**Approach:** Feature-by-feature migration, one phase at a time, always keeping the app runnable

---

## Target Folder Structure

```
lib/
  main.dart
  main_dev.dart                    # Dev entry point (if needed)
  config/
    env_config.dart                # Environment-based config (replaces dev_config + api_constants)
    app_config.dart                # App-wide constants
  routing/
    app_router.dart                # go_router setup with route guards
    route_names.dart               # Named route constants
  di/
    service_locator.dart           # Dependency injection setup (Provider or get_it)
  domain/
    models/
      user.dart                    # User, Patient, Doctor (immutable)
      prescription.dart            # Prescription, PrescriptionMedication
      medication.dart              # Medication
      dose_event.dart              # DoseEvent
      medication_batch.dart        # MedicationBatch, BatchMedication
      connection.dart              # Connection, ConnectionRequest, ConnectionToken
      health_vital.dart            # HealthVital, HealthAlert, VitalThreshold
      notification.dart            # AppNotification
      subscription.dart            # Subscription models
      doctor_dashboard.dart        # Dashboard-specific models
      country.dart                 # Country
    enums/
      user_enums.dart              # UserRole, Gender, AccountStatus
      medication_enums.dart        # MedicationType, MedicineType, MedicineUnit, MedicationStatus
      dose_enums.dart              # DoseStatus (single source of truth)
      connection_enums.dart        # ConnectionStatus, PermissionLevel
      prescription_enums.dart      # PrescriptionStatus
      health_enums.dart            # VitalType, AlertSeverity
      subscription_enums.dart      # SubscriptionTier
      notification_enums.dart      # NotificationType
  data/
    services/
      api/
        api_client.dart            # Base HTTP client with token refresh
        auth_api_service.dart      # Auth endpoints
        prescription_api_service.dart
        dose_api_service.dart
        connection_api_service.dart
        health_api_service.dart
        notification_api_service.dart
        subscription_api_service.dart
        doctor_api_service.dart
        batch_api_service.dart
      local/
        database_service.dart      # SQLite operations
        secure_storage_service.dart # Token/secure data storage
        shared_prefs_service.dart   # Preferences
      notification_service.dart    # Local notification scheduling
      sync_service.dart            # Offline sync via api_client (not raw http)
      logger_service.dart          # Logging
    repositories/
      auth_repository.dart
      prescription_repository.dart
      dose_repository.dart
      connection_repository.dart
      health_repository.dart
      notification_repository.dart
      subscription_repository.dart
      doctor_dashboard_repository.dart
      batch_repository.dart
      user_repository.dart
  ui/
    core/
      theme/
        app_colors.dart
        app_spacing.dart
        app_typography.dart
        light_theme.dart
        dark_theme.dart
        theme_provider.dart
      widgets/
        primary_button.dart
        app_card.dart
        status_badge.dart
        stat_card.dart
        section_group.dart
        app_header.dart
        bottom_nav_bar.dart
        adherence_progress_bar.dart
        language_switcher.dart
        phone_field.dart
        medication_grid_table.dart
        medicine_form_widget.dart
        ocr_info_section.dart
      l10n/                        # Keep auto-generated localization files
        app_localizations.dart
        app_localizations_en.dart
        app_localizations_km.dart
    features/
      auth/
        view_models/
          login_view_model.dart
          register_view_model.dart
          otp_view_model.dart
          forgot_password_view_model.dart
        widgets/
          auth_widgets.dart        # AuthGradientScaffold, AuthHeader, etc.
        views/
          welcome_view.dart
          login_view.dart
          register_role_view.dart
          register_patient_view.dart
          register_doctor_view.dart
          otp_verification_view.dart
          forgot_password_view.dart
          reset_password_view.dart
      splash/
        views/
          splash_view.dart
      patient/
        view_models/
          patient_home_view_model.dart
          dose_view_model.dart
          prescription_view_model.dart
          adherence_view_model.dart
          batch_view_model.dart
          health_view_model.dart
          patient_settings_view_model.dart
          subscription_view_model.dart
        views/
          patient_shell_view.dart
          patient_home_tab.dart
          patient_medications_tab.dart
          patient_scan_tab.dart
          patient_family_tab.dart
          patient_settings_tab.dart
        widgets/
          patient_header.dart
          dose_schedule_card.dart
          # etc.
        screens/                   # Complex multi-step screens
          create_prescription_wizard/
            wizard_view.dart
            steps/
              step1_info.dart
              step2_medicines.dart
              step3_review.dart
          ocr_preview/
            ocr_preview_view.dart
            widgets/
              ocr_result_card.dart
          payment/
            upgrade_plan_view.dart
            payment_method_view.dart
            payment_qr_view.dart
            payment_success_view.dart
            bakong_payment_view.dart
          batch/
            create_batch_view.dart
            batch_detail_view.dart
          health/
            record_vital_view.dart
            vital_trend_view.dart
            vital_thresholds_view.dart
          profile/
            edit_profile_view.dart
            change_password_view.dart
      doctor/
        view_models/
          doctor_dashboard_view_model.dart
          doctor_patients_view_model.dart
          doctor_prescriptions_view_model.dart
          doctor_notes_view_model.dart
          patient_detail_view_model.dart
        views/
          doctor_shell_view.dart
          doctor_home_tab.dart
          doctor_patients_tab.dart
          doctor_prescriptions_tab.dart
          doctor_notifications_tab.dart
          doctor_settings_tab.dart
          doctor_profile_tab.dart
        screens/
          create_prescription_screen.dart
          patient_detail_screen.dart
          pending_patient_list_screen.dart
        widgets/
          dashboard_stat_card.dart
          patient_list_tile.dart
      family/
        view_models/
          family_view_model.dart
          caregiver_view_model.dart
        views/
          family_connect_intro_view.dart
          access_level_selection_view.dart
          caregiver_dashboard_view.dart
          code_entry_view.dart
          connection_history_view.dart
          connection_preview_view.dart
          family_access_list_view.dart
          grace_period_settings_view.dart
          qr_scanner_view.dart
          token_display_view.dart
      notifications/
        view_models/
          notification_view_model.dart
        views/
          patient_notifications_view.dart
          doctor_notifications_view.dart
        widgets/
          connection_request_card.dart
          connection_request_sheet.dart
          notification_utils.dart
          standard_notification_card.dart
      support/
        views/
          contact_support_view.dart
          privacy_policy_view.dart
          terms_of_service_view.dart
      shared/
        views/
          prescription_detail_view.dart
```

---

## Phase 0: Cleanup & Preparation (No Architecture Changes)

> **Goal:** Remove dead code, junk code, and duplicates. Fix critical bugs. Get a clean baseline.

### Task 0.1 — Delete Dead / Empty Files
- [ ] Delete `lib/services/sync_service.dart.old` (dead code, references obsolete methods)
- [ ] Delete `lib/models/users_models/user.dart` (empty file)
- [ ] Delete `lib/models/users_models/doctor_model/doctor.dart` (empty file)
- [ ] Delete `lib/models/users_models/patient_model/patient.dart` (empty file)
- [ ] Delete empty `lib/models/users_models/` directory entirely
- [ ] Delete `lib/ui/screens/doctor/doctor_prescription_view_screen.dart` (empty)
- [ ] Delete `lib/ui/screens/doctor/patient_record_detail_screen.dart` (empty)
- [ ] Delete `lib/ui/screens/doctor/patient_record_screen.dart` (empty)
- [ ] Delete `lib/ui/screens/doctor/settings/doctor_notification_settings_screen.dart` (empty)
- [ ] Delete `lib/ui/screens/doctor/settings/doctor_personal_account_screen.dart` (empty)
- [ ] Delete `lib/ui/screens/doctor/settings/doctor_security_screen.dart` (empty)
- [ ] Remove routes in `app_router.dart` that point to deleted empty screens
- [ ] Verify app compiles and runs after deletions

### Task 0.2 — Remove Junk / Test Code from Production
- [ ] Remove `Lan` interface and `Toyota` class from `lib/models/user_model/user.dart`
- [ ] Remove or quarantine `lib/ui/screens/doctor/doctor_dashboard.dart` (standalone prototype with its own `main()` and `runApp()` — not integrated with the app)
- [ ] Verify no imports reference the removed code

### Task 0.3 — Fix Critical Data Bug
- [ ] Fix `lib/models/batch_model/medication_batch.dart`: `toJson` uses key `'medicines'` but `fromJson` reads `'medications'` — these MUST match or data is silently lost
- [ ] Verify backend API contract and align both keys to the correct one

### Task 0.4 — Remove Duplicate Patient Detail Screen
- [ ] Determine which is the active/correct screen: `lib/ui/screens/doctor/patient_detail.dart` (532 lines) vs `lib/ui/screens/doctor/patient_detail_screen.dart` (671 lines)
- [ ] Delete the unused one
- [ ] Update all routes and imports to point to the surviving file

### Task 0.5 — Security Cleanup
- [ ] Move hardcoded JWT tokens and dev user profile from `lib/core/config/dev_config.dart` to environment variables or a gitignored file
- [ ] Move hardcoded IP `192.168.0.101` from `lib/utils/api_constants.dart` to `.env` file
- [ ] Ensure `DevConfig.skipAuth` is only active in debug/dev builds (use `kDebugMode` or compile-time flag)
- [ ] Add `.env` to `.gitignore` if not already

---

## Phase 1: Unify Enums (Single Source of Truth)

> **Goal:** Eliminate all duplicate enum definitions. Create one canonical location per enum.

### Task 1.1 — Audit All Enum Usages
- [ ] Search all files for every enum usage to map which version is used where
- [ ] Document the canonical values for each enum (based on backend API contract)

### Task 1.2 — Create Unified Enum Files
- [ ] Create `lib/domain/enums/` directory
- [ ] Create `user_enums.dart` — single `UserRole` (resolve: `enums.dart` has `familyMember`, `user_model/user.dart` has `family` — pick one based on backend)
- [ ] Create `dose_enums.dart` — single `DoseStatus` (merge `DoseStatus` from `dose_status.dart` and `DoseEventStatus` from `enums.dart`)
- [ ] Create `connection_enums.dart` — single `ConnectionStatus` (resolve: `enums.dart` has 3 values, `connection_request.dart` has 4 — include `rejected` if backend supports it)
- [ ] Create `connection_enums.dart` — single `PermissionLevel` (remove duplicate from `connection_request.dart`)
- [ ] Create `medication_enums.dart` — merge `MedicationType`, `MedicineType`, `MedicineUnit`, `MedicationStatus` (remove legacy `MedicationType` if unused)
- [ ] Create `prescription_enums.dart` — single `PrescriptionStatus`
- [ ] Create `health_enums.dart` — move `VitalType`, `AlertSeverity` OUT of `medication_type.dart` into this file
- [ ] Create `subscription_enums.dart` — `SubscriptionTier`
- [ ] Create `notification_enums.dart` — `NotificationType`

### Task 1.3 — Migrate All Imports
- [ ] Update every file that imports from `enums_model/enums.dart`, `enums_model/dose_status.dart`, `enums_model/medication_status.dart`, `enums_model/medication_type.dart`, or `connection_request.dart` (for enums) to import from the new canonical files
- [ ] Delete old enum files: `lib/models/enums_model/enums.dart`, `lib/models/enums_model/dose_status.dart`, `lib/models/enums_model/medication_status.dart`, `lib/models/enums_model/medication_type.dart`
- [ ] Remove duplicate enums from `lib/models/connection_model/connection_request.dart`
- [ ] Remove duplicate `UserRole` from `lib/models/user_model/user.dart`
- [ ] Verify app compiles and all enum values match backend expectations

### Task 1.4 — Replace Magic Strings with Enums
- [ ] Replace `auth.user?['role'] == 'DOCTOR'` (and similar) in `prescription_detail_screen.dart` and other files with `UserRole.doctor` enum comparison
- [ ] Replace `DoseEvent.status` from `String` to `DoseStatus` enum
- [ ] Search for other magic role/status strings and replace with enums

---

## Phase 2: Immutable Domain Models

> **Goal:** Create clean, immutable domain model classes. Separate API DTOs from domain models.

### Task 2.1 — Add freezed Dependency
- [ ] Add `freezed`, `freezed_annotation`, `json_serializable`, and `build_runner` to `pubspec.yaml`
- [ ] Run `flutter pub get`

### Task 2.2 — Create Immutable Domain Models
For each model, create a `@freezed` class in `lib/domain/models/`:
- [ ] `user.dart` — `User`, `PatientProfile`, `DoctorProfile` (immutable, no JSON logic)
- [ ] `prescription.dart` — `Prescription`, `PrescriptionMedication` (single definition, remove duplicate)
- [ ] `medication.dart` — `Medication` (remove dual toMap/toJson, keep only domain fields)
- [ ] `dose_event.dart` — `DoseEvent` (use `DoseStatus` enum, not String)
- [ ] `medication_batch.dart` — `MedicationBatch`, `BatchMedication` (fix medicines/medications key inconsistency)
- [ ] `connection.dart` — `Connection`, `ConnectionRequest`, `ConnectionToken` (use unified enums)
- [ ] `health_vital.dart` — `HealthVital`, `HealthAlert`, `VitalThreshold`
- [ ] `notification.dart` — `AppNotification`
- [ ] `subscription.dart` — subscription-related models
- [ ] `doctor_dashboard.dart` — `DashboardOverview`, `MissedDoseAlert`, `PatientListItem`, `DoctorNote`, etc.
- [ ] `country.dart` — `Country`

### Task 2.3 — Create API DTOs (Data Layer)
- [ ] Create `lib/data/models/` directory for API-specific DTOs if JSON parsing differs significantly from domain models
- [ ] Add `.fromJson` / `.toJson` only on DTOs, not domain models
- [ ] Add mapping extensions: `DTO.toDomain()` and `DomainModel.toDto()`

### Task 2.4 — Migrate All Model Imports
- [ ] Update all files to import from `lib/domain/models/` and `lib/domain/enums/`
- [ ] Delete old model files:
  - `lib/models/user_model/user.dart`
  - `lib/models/doctor_model/doctor.dart`
  - `lib/models/patient_model/patient.dart`
  - `lib/models/dose_event_model/dose_event.dart`
  - `lib/models/medication_model/medication.dart`
  - `lib/models/batch_model/medication_batch.dart`
  - `lib/models/connection_model/` (all files)
  - `lib/models/health_model/` (all files)
  - `lib/models/notification_model/notification.dart`
  - `lib/models/prescription_model/prescription.dart`
  - `lib/models/doctor_dashboard_model/` (all files)
  - `lib/models/country_model.dart`
- [ ] Delete `lib/models/` directory entirely once empty
- [ ] Run `build_runner` to generate freezed code
- [ ] Verify app compiles

---

## Phase 3: Split Monolithic ApiService

> **Goal:** Break the ~69KB `api_service.dart` into feature-specific API services.

### Task 3.1 — Create Base API Client
- [ ] Create `lib/data/services/api/api_client.dart` with:
  - Base HTTP methods (`get`, `post`, `put`, `patch`, `delete`)
  - Automatic 401 token refresh retry (move from current `ApiService`)
  - `ApiException` class
  - Base URL configuration (from environment)
  - Request/response logging

### Task 3.2 — Extract Feature API Services
Split current `ApiService` methods into domain-specific services:
- [ ] `auth_api_service.dart` — login, register, googleSignIn, verifyOtp, forgotPassword, resetPassword, refreshToken, logout, updateProfile, changePassword
- [ ] `prescription_api_service.dart` — CRUD prescriptions, medicines
- [ ] `dose_api_service.dart` — getDoseSchedule, markDose, batchSyncDoses
- [ ] `connection_api_service.dart` — connections CRUD, tokens, nudge, search
- [ ] `health_api_service.dart` — vitals CRUD, trends, thresholds, alerts, emergency
- [ ] `notification_api_service.dart` — fetch, markRead, delete notifications
- [ ] `subscription_api_service.dart` — subscription status, payments, free trial
- [ ] `doctor_api_service.dart` — dashboard, patients, notes, adherence graph
- [ ] `batch_api_service.dart` — medication batch CRUD

### Task 3.3 — Fix SyncService to Use API Client
- [ ] Refactor `lib/services/sync_service.dart` to use `ApiClient` instead of raw `http` package
- [ ] This ensures sync operations get automatic token refresh
- [ ] Remove `import 'package:http/http.dart'` from sync_service

### Task 3.4 — Migrate All ApiService Callers
- [ ] Update every provider that calls `ApiService.xxx()` to call the appropriate feature API service
- [ ] Delete old `lib/services/api_service.dart`
- [ ] Verify all API calls work end-to-end

---

## Phase 4: Create Repository Layer

> **Goal:** Repositories become the single source of truth. They coordinate between API services and local database.

### Task 4.1 — Create Repository Classes
Each repository wraps its API service + database operations:
- [ ] `auth_repository.dart` — auth state, token management, user profile (uses `auth_api_service` + `secure_storage_service`)
- [ ] `prescription_repository.dart` — prescription CRUD with offline cache (uses `prescription_api_service` + `database_service`)
- [ ] `dose_repository.dart` — dose schedule + marking with offline queue (uses `dose_api_service` + `database_service`)
- [ ] `connection_repository.dart` — connections management (uses `connection_api_service`)
- [ ] `health_repository.dart` — vitals, thresholds, alerts with offline cache (uses `health_api_service` + `database_service`)
- [ ] `notification_repository.dart` — notifications with dedup (uses `notification_api_service`)
- [ ] `subscription_repository.dart` — subscription + payment (uses `subscription_api_service`)
- [ ] `doctor_dashboard_repository.dart` — doctor dashboard data (uses `doctor_api_service`)
- [ ] `batch_repository.dart` — medication batches with offline cache (uses `batch_api_service` + `database_service`)
- [ ] `user_repository.dart` — user preferences, locale, theme (uses `shared_prefs_service`)

### Task 4.2 — Move Business Logic from Providers to Repositories
- [ ] Move caching logic from providers into repositories
- [ ] Move error handling and retry logic into repositories
- [ ] Move offline queue management from providers into repositories
- [ ] Repositories should emit data via `Stream` or return `Future`, not `notifyListeners()`

### Task 4.3 — Refactor DatabaseService
- [ ] Keep `database_service.dart` but have repositories call it (not providers directly)
- [ ] Consider splitting into feature-specific DAOs if the file grows further

---

## Phase 5: Create ViewModels (MVVM)

> **Goal:** Replace Providers with proper ViewModels. ViewModels hold UI state and call repositories. Views become stateless.

### Task 5.1 — Auth ViewModels
- [ ] Create `login_view_model.dart` — holds email/password state, loading, error. Calls `auth_repository.login()`
- [ ] Create `register_view_model.dart` — holds form state for patient/doctor registration
- [ ] Create `otp_view_model.dart` — holds OTP state, timer, verification
- [ ] Create `forgot_password_view_model.dart` — holds email state, calls forgot/reset
- [ ] Refactor auth screens to be `StatelessWidget` watching ViewModels
- [ ] Delete `lib/providers/auth_provider.dart` once fully migrated

### Task 5.2 — Patient Feature ViewModels
- [ ] Create `patient_home_view_model.dart` — dashboard data, adherence summary, dose schedule
- [ ] Create `dose_view_model.dart` — today's doses, mark dose actions (replaces `DoseProvider`)
- [ ] Create `prescription_view_model.dart` — prescription list, create/edit (replaces `PrescriptionProvider`)
- [ ] Create `adherence_view_model.dart` — adherence stats (replaces `AdherenceProvider`)
- [ ] Create `batch_view_model.dart` — medication batches CRUD (replaces `BatchProvider`)
- [ ] Create `health_view_model.dart` — vitals, trends, thresholds (replaces `HealthMonitoringProvider`)
- [ ] Create `patient_settings_view_model.dart` — settings state
- [ ] Create `subscription_view_model.dart` — subscription state, payment flow (replaces `SubscriptionProvider`)
- [ ] Move payment polling logic (currently 180 * 5s in SubscriptionProvider) into `subscription_repository.dart`

### Task 5.3 — Doctor Feature ViewModels
- [ ] Create `doctor_dashboard_view_model.dart` — dashboard overview, graph data (replaces part of `DoctorDashboardProvider`)
- [ ] Create `doctor_patients_view_model.dart` — patient list with pagination/filtering (replaces part of `DoctorDashboardProvider`)
- [ ] Create `doctor_prescriptions_view_model.dart` — prescription management
- [ ] Create `doctor_notes_view_model.dart` — CRUD notes (replaces part of `DoctorDashboardProvider`)
- [ ] Create `patient_detail_view_model.dart` — single patient details, adherence, prescriptions

### Task 5.4 — Family & Connection ViewModels
- [ ] Create `family_view_model.dart` — family connections, token management (replaces part of `ConnectionProvider`)
- [ ] Create `caregiver_view_model.dart` — caregiver dashboard data

### Task 5.5 — Notification ViewModel
- [ ] Create `notification_view_model.dart` — notification list, mark read, delete (replaces `NotificationProvider`)

### Task 5.6 — Delete Old Providers
- [ ] Delete `lib/providers/auth_provider.dart`
- [ ] Delete `lib/providers/adherence_provider.dart`
- [ ] Delete `lib/providers/batch_provider.dart`
- [ ] Delete `lib/providers/connection_provider.dart`
- [ ] Delete `lib/providers/doctor_dashboard_provider.dart`
- [ ] Delete `lib/providers/dose_provider.dart`
- [ ] Delete `lib/providers/health_monitoring_provider.dart`
- [ ] Delete `lib/providers/notification_provider.dart`
- [ ] Delete `lib/providers/prescription_provider.dart`
- [ ] Delete `lib/providers/subscription_provider.dart`
- [ ] Keep `lib/providers/locale_provider.dart` (already clean, move to `ui/core/` later)
- [ ] Delete `lib/providers/` directory

---

## Phase 6: Dependency Injection Setup

> **Goal:** Proper DI using Provider (or get_it). Replace flat 13-provider MultiProvider.

### Task 6.1 — Create Service Locator
- [ ] Create `lib/di/service_locator.dart` that registers:
  - **Services:** `ApiClient`, all feature API services, `DatabaseService`, `SecureStorageService`, `NotificationService`, `LoggerService`
  - **Repositories:** all repositories (depend on services)
  - **ViewModels:** all view models (depend on repositories)
- [ ] Use `MultiProvider` with `ProxyProvider` for dependency chains, or use `get_it` for simpler wiring

### Task 6.2 — Refactor main.dart
- [ ] Replace the flat 13-provider `MultiProvider` with the new DI setup
- [ ] Keep it clean: `main.dart` should only initialize services and call `runApp()`
- [ ] Move `SyncService` initialization into the DI setup

---

## Phase 7: Refactor Navigation / Routing

> **Goal:** Type-safe routing with auth guards. Replace monolithic switch/case router.

### Task 7.1 — Migrate to go_router
- [ ] Add `go_router` dependency
- [ ] Create `lib/routing/app_router.dart` with `GoRouter` configuration
- [ ] Define all routes with type-safe parameters (no more `Map<String, dynamic>` args)
- [ ] Add auth redirect guard (check token validity before allowing access to protected routes)
- [ ] Add role-based guards (patient routes vs doctor routes)
- [ ] Create `lib/routing/route_names.dart` for named route constants

### Task 7.2 — Update All Navigation Calls
- [ ] Replace all `Navigator.pushNamed(context, '/route')` with `context.go('/route')` or `context.push('/route')`
- [ ] Remove old `AppRouter` class and its `generateRoute` method
- [ ] Verify all navigation flows work (auth, patient, doctor, family)

---

## Phase 8: Break Down Large Screens

> **Goal:** Decompose screens over 500 lines into smaller widgets and sub-views.

### Task 8.1 — Decompose Patient Screens
- [ ] `create_prescription_wizard_screen.dart` (1234 lines) → split into `wizard_view.dart` + separate step widgets (`step1_info.dart`, `step2_medicines.dart`, `step3_review.dart`)
- [ ] `ocr_preview_screen.dart` (1318 lines) → split into `ocr_preview_view.dart` + smaller result card widgets
- [ ] `upgrade_plan_screen.dart` (1308 lines) → split into `upgrade_plan_view.dart` + plan comparison widgets + feature list widgets
- [ ] `payment_qr_screen.dart` (752 lines) → split view and extract QR display widget
- [ ] `prescription_success_screen.dart` (501 lines) → simplify

### Task 8.2 — Decompose Doctor Screens
- [ ] `doctor_home_tab.dart` (888 lines) → split into `doctor_home_tab.dart` + separate section widgets (stats, graph, alerts, recent patients)
- [ ] `doctor_settings_tab.dart` (758 lines) → split into sections
- [ ] `patient_detail_screen.dart` (671 lines) → split into tab-specific widgets
- [ ] `create_prescription_screen.dart` (724 lines) → split form sections

### Task 8.3 — Decompose Family Screens
- [ ] `caregiver_dashboard_screen.dart` (757 lines) → split into section widgets

### Task 8.4 — Split common_widgets.dart
- [ ] `lib/ui/widgets/common_widgets.dart` contains 12+ widget classes → split each into its own file under `lib/ui/core/widgets/`
- [ ] Update all imports

---

## Phase 9: Reorganize File Structure

> **Goal:** Move all files into the target folder structure defined above.

### Task 9.1 — Create Directory Structure
- [ ] Create all directories as defined in the target structure

### Task 9.2 — Move Files
- [ ] Move theme files to `lib/ui/core/theme/`
- [ ] Move shared widgets to `lib/ui/core/widgets/`
- [ ] Move localization files to `lib/ui/core/l10n/`
- [ ] Move auth screens to `lib/ui/features/auth/views/`
- [ ] Move patient screens to `lib/ui/features/patient/views/` and `lib/ui/features/patient/screens/`
- [ ] Move doctor screens to `lib/ui/features/doctor/views/` and `lib/ui/features/doctor/screens/`
- [ ] Move family screens to `lib/ui/features/family/views/`
- [ ] Move notification screens to `lib/ui/features/notifications/views/`
- [ ] Move support screens to `lib/ui/features/support/views/`
- [ ] Move shared screens (e.g., `prescription_detail_screen.dart`) to `lib/ui/features/shared/views/`
- [ ] Move `api_constants.dart` logic into `lib/config/env_config.dart`
- [ ] Move logger service to `lib/data/services/logger_service.dart`

### Task 9.3 — Update All Imports
- [ ] Use IDE "Move File" refactoring or manually update imports across all files
- [ ] Run `dart fix --apply` to clean up imports
- [ ] Verify app compiles

### Task 9.4 — Rename Files to Match Convention
- [ ] Rename all screen files from `*_screen.dart` to `*_view.dart` (views) per naming convention
- [ ] Rename `PatientHeader` widget (used by both patient and doctor) to `AppUserHeader` or `DashboardHeader`
- [ ] Ensure all file names match their primary class name in snake_case

---

## Phase 10: Localization & Polish

> **Goal:** Fix all un-localized strings. Clean up remaining issues.

### Task 10.1 — Fix Un-localized Strings
- [ ] Search all `.dart` files for hardcoded English/Khmer strings in UI code
- [ ] Add missing keys to `app_en.arb` and `app_km.arb`
- [ ] Replace hardcoded strings with `AppLocalizations.of(context)!.keyName`
- [ ] Key files with known issues:
  - `change_password_screen.dart` — `'New password must be different from current'`
  - `edit_profile_screen.dart` — `'Tap to change photo'`
  - Various doctor screens with hardcoded Khmer text

### Task 10.2 — Make Timezone Configurable
- [ ] Move hardcoded `Asia/Phnom_Penh` in `notification_service.dart` to app config
- [ ] Detect user timezone or make it a setting

### Task 10.3 — Improve Image Upload
- [ ] Replace base64 image upload in `edit_profile_screen.dart` with multipart form upload
- [ ] This reduces payload size significantly for large images

---

## Phase 11: Testing Setup

> **Goal:** Create test infrastructure and write tests for core layers.

### Task 11.1 — Unit Tests for Repositories
- [ ] Create mock API services using `mockito` or manual fakes
- [ ] Test each repository: `auth_repository_test.dart`, `dose_repository_test.dart`, `prescription_repository_test.dart`, etc.
- [ ] Test offline caching, error handling, data mapping

### Task 11.2 — Unit Tests for ViewModels
- [ ] Create mock repositories
- [ ] Test each ViewModel: state transitions, command execution, error states
- [ ] Test `login_view_model_test.dart`, `dose_view_model_test.dart`, etc.

### Task 11.3 — Widget Tests for Views
- [ ] Test each major view renders correctly with mocked ViewModels
- [ ] Test navigation flows
- [ ] Test form validation in auth views

### Task 11.4 — Integration Tests
- [ ] Create end-to-end tests for critical flows:
  - Login flow
  - Dose marking flow
  - Prescription creation flow
  - Family connection flow

---

## Phase 12: Performance & Lint Cleanup

> **Goal:** Optimize performance per Flutter best practices. Clean lint warnings.

### Task 12.1 — Add const Constructors
- [ ] Run `dart analyze` and fix all `prefer_const_constructors` warnings
- [ ] Add `const` to all eligible widget constructors and literals

### Task 12.2 — Enable flutter_lints
- [ ] Add `flutter_lints` (or `very_good_analysis`) to `analysis_options.yaml`
- [ ] Fix all new lint warnings

### Task 12.3 — Optimize Rebuilds
- [ ] Ensure ViewModels only notify on actual state changes
- [ ] Use `Selector` or `context.select()` where only part of the ViewModel state is needed
- [ ] Verify `ListView.builder` is used for all scrollable lists (not `Column` with `List.map`)

### Task 12.4 — Profile with DevTools
- [ ] Run Flutter Performance profiler
- [ ] Identify and fix any jank (frames > 16ms)
- [ ] Check for unnecessary rebuilds using "Track Widget Rebuilds"

---

## Execution Order & Dependencies

```
Phase 0  (Cleanup)          ← Do first, no dependencies
  ↓
Phase 1  (Unify Enums)      ← Depends on Phase 0
  ↓
Phase 2  (Domain Models)    ← Depends on Phase 1 (needs unified enums)
  ↓
Phase 3  (Split ApiService) ← Can start in parallel with Phase 2
  ↓
Phase 4  (Repositories)     ← Depends on Phase 2 + 3
  ↓
Phase 5  (ViewModels)       ← Depends on Phase 4
  ↓
Phase 6  (DI Setup)         ← Depends on Phase 5
  ↓
Phase 7  (Routing)          ← Can start after Phase 5
  ↓
Phase 8  (Break Down Screens) ← Can start after Phase 5
  ↓
Phase 9  (File Structure)   ← Do after all code changes (Phase 5-8)
  ↓
Phase 10 (Localization)     ← Can run in parallel with Phase 9
  ↓
Phase 11 (Testing)          ← Depends on Phase 4-6
  ↓
Phase 12 (Performance)      ← Final phase
```

---

## Key Principles During Refactoring

1. **One phase at a time.** Complete and verify each phase before starting the next.
2. **App must always compile.** After each task, run `flutter analyze` and `flutter build` to verify.
3. **Feature-by-feature within phases.** When migrating ViewModels (Phase 5), do one feature fully (e.g., auth) before moving to the next.
4. **Git commit per task.** Each task (e.g., Task 3.2) gets its own commit for easy rollback.
5. **No new features during refactoring.** Only structural changes and bug fixes.
6. **Test as you go.** Write tests for new ViewModels and Repositories as they are created (don't wait for Phase 11).

---

## Summary of Issues Found

| Severity | Count | Category |
|----------|-------|----------|
| CRITICAL | 5 | Junk code in production, data loss bug, security concerns, dead files |
| HIGH | 7 | Monolithic files, missing DI, no route guards, magic strings |
| MEDIUM | 8 | Large screens, misplaced types, un-localized strings, inefficient uploads |
| LOW | 5 | Hardcoded data, missing barrel exports, no tests |

**Total files to refactor:** 144 Dart files
**Estimated new files:** ~80 (ViewModels, Repositories, API services, tests)
**Files to delete:** ~15 (dead code, duplicates, junk)
