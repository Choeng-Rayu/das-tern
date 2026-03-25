# Implementation Plan: iOS 26 Liquid Glass Refactor (RxCam)

## Overview

Migrate RxCam to the iOS 26 Liquid Glass aesthetic with strict MVVM Clean Architecture and a fully
reusable global widget system. Delivered in six phases matching the PR dependency graph:
Phase 1 → (Phase 2 ∥ Phase 3) → Phase 4 → Phase 5 → Phase 6.

All code is Flutter/Dart. Design tokens replace every hardcoded colour, spacing, and radius value.

---

## Tasks

- [ ] 1. Phase 1 — Foundation
  - [ ] 1.1 Create `lib/core/theme/app_colors.dart` with the `AppColors` abstract final class
    - Define all colour tokens: `primary` (#009DFF), `primaryDark`, `primaryLight`, mesh tokens, glass tokens (`glassWhite`, `glassBorder`, `glassShadow`, `glassPrimary`, `glassDanger`), semantic tokens (`success`, `danger`, `warning`, `info`), and text tokens (`textPrimary`, `textSecondary`, `textTertiary`)
    - _Requirements: 1.1_

  - [ ] 1.2 Create `lib/core/theme/app_spacing.dart` with the `AppSpacing` abstract final class
    - Define spacing scale: `xs`=4, `sm`=8, `md`=16, `lg`=24, `xl`=32, `xxl`=48
    - Define iOS 26 radius tokens: `radiusSm`=12, `radiusMd`=20, `radiusLg`=28, `radiusXl`=36, `radiusFull`=100
    - _Requirements: 1.2_

  - [ ] 1.3 Create `lib/core/theme/app_text_styles.dart` with the `AppTextStyles` abstract final class
    - Define all 9 text styles using `AppColors` tokens exclusively — no inline `Color(...)` values
    - Styles: `displayLarge`, `displayMedium`, `headlineLarge`, `headlineMedium`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelSmall`
    - _Requirements: 1.3_

  - [ ] 1.4 Create `lib/core/theme/app_theme.dart` with the `AppTheme` abstract final class
    - Implement `AppTheme.dark` returning a `ThemeData` with `scaffoldBackgroundColor: AppColors.meshDeep` and transparent `AppBarTheme`
    - Map `AppTextStyles` entries to the `TextTheme`
    - _Requirements: 1.4_

  - [ ] 1.5 Create `lib/core/router/app_router.dart` with `AppRoutes` constants and `AppRouter` class
    - Define all 11 named route constants in `AppRoutes`
    - Implement `AppRouter.navigatorKey` as `GlobalKey<NavigatorState>`
    - Implement `onGenerateRoute` using a `switch` on `settings.name` with `_slideRoute` helper (340 ms `easeOutCubic` `SlideTransition` from `Offset(1,0)`)
    - Implement static `push`, `pop`, and `pushReplacement` methods delegating to `navigatorKey.currentState`
    - Fall back to `HomeView` for unknown routes
    - _Requirements: 13.1–13.5_

  - [ ] 1.6 Create `lib/app.dart` with `RxCamApp` widget
    - Instantiate services: `AuthService`, `PrescriptionService`, `DoseService`, `OcrService`, `NotificationService`, `ConnectionService`
    - Instantiate repositories: `AuthRepository`, `PrescriptionRepository`, `DoseRepository`, `NotificationRepository`, `ConnectionRepository`
    - Instantiate use cases: `GenerateScheduleUseCase()`, `ProcessOcrResultUseCase(ocrService)`
    - Wire `MultiProvider` with `Provider.value` for repositories and `ChangeNotifierProvider` for ViewModels: `HomeViewModel(prescriptionRepo, doseRepo)`, `PrescriptionListViewModel`, `MedicationListViewModel(prescriptionRepo)`, `ScanViewModel(processOcr)`, `ReminderScheduleViewModel(doseRepo, generateSchedule)`, `FamilyViewModel(connectionRepo)`, `SettingsViewModel(authRepo)`
    - Wire `MaterialApp` with `AppTheme.dark`, `AppRouter.navigatorKey`, `AppRouter.onGenerateRoute`, and `initialRoute: AppRoutes.home`
    - _Requirements: 3.9_

  - [ ] 1.7 Checkpoint — Phase 1 quality gate
    - Ensure `flutter analyze` reports zero issues. Ask the user if questions arise.

- [ ] 2. Phase 2 — Global Widget System
  - [ ] 2.1 Create `lib/core/widgets/app_glass_panel.dart`
    - Implement `AppGlassPanel` as a `StatelessWidget` accepting `child`, `borderRadius` (default `AppSpacing.radiusLg`), `tint`, `blurRadius` (default 20), `opacity` (default 1.0), and `padding`
    - Widget tree: `Opacity` → `DecoratedBox` (shadow) → `ClipRRect` → `BackdropFilter` → `DecoratedBox` (gradient + specular border) → `Padding` → `child`
    - Apply tint at 18% opacity (top-left) and 6% opacity (bottom-right); default tint to `Colors.white`
    - Specular border: `Border(top: BorderSide(color: AppColors.glassBorder, width: 0.8))`
    - Shadow: `BoxShadow(color: AppColors.glassShadow, blurRadius: 32, offset: Offset(0, 8))`
    - _Requirements: 2.1–2.5, 4.1–4.6_

  - [ ]* 2.2 Write property tests for `AppGlassPanel` (Properties 1–4)
    - **Property 1: Single BackdropFilter invariant** — for any valid parameter combination, widget tree contains exactly one `BackdropFilter` node
    - **Property 2: Tint opacity stops** — for any `Color` tint, gradient uses 18% and 6% opacity stops
    - **Property 3: Opacity propagation** — for any `opacity` in [0.0, 1.0], `Opacity` widget uses that exact value
    - **Property 4: BorderRadius clipping** — for any `borderRadius` in [24.0, 36.0], `ClipRRect` uses that exact radius
    - **Validates: Requirements 4.2–4.6, 2.4–2.5, 33.6**

  - [ ] 2.3 Create `lib/core/widgets/app_mesh_background.dart`
    - Implement `AppMeshBackground` as a `StatefulWidget` accepting `child`
    - Create two `AnimationController` instances: `_ctrl1` (9 s) and `_ctrl2` (13 s), both `repeat(reverse: true)`
    - Render three orbs via `AnimatedBuilder` + `CustomPaint`: orb1 (`primary`, opacity 0.30), orb2 (`primaryDark`, opacity 0.22), orb3 (`primaryLight`, opacity 0.16)
    - Orb positions driven by `Tween<Offset>` on each controller
    - Base background: `AppColors.meshDeep`
    - Render `child` as the topmost element in the `Stack`
    - Dispose both controllers in `dispose()`
    - _Requirements: 2.6–2.7, 5.1–5.6_

  - [ ]* 2.4 Write property test for `AppMeshBackground` (Property 5)
    - **Property 5: Child rendered above orbs** — for any child widget, child is the topmost element in the Stack above all orb layers
    - **Validates: Requirements 5.6**

  - [ ] 2.5 Create `lib/core/widgets/app_header.dart`
    - Implement `AppHeader` as a `StatelessWidget` implementing `PreferredSizeWidget`
    - `preferredSize`: `Size.fromHeight(kToolbarHeight + 16)`
    - Widget tree: `ClipRect` → `BackdropFilter` (blur 20/20) → `DecoratedBox` (bottom border `glassBorder` 0.5 px, fill `glassWhite`) → `SafeArea` → `Row`
    - Render `CupertinoIcons.chevron_left` in `AppColors.primary` when `showBackButton` is true; tap calls `AppRouter.pop()`
    - Render `subtitle` below title using `AppTextStyles.bodyMedium` with `TextOverflow.ellipsis` when provided
    - Render `actions` at trailing end when provided
    - _Requirements: 7.1–7.6_

  - [ ] 2.6 Create `lib/core/widgets/app_bottom_nav.dart`
    - Implement `AppBottomNav` as a `StatelessWidget` accepting `currentIndex` and `onTap`
    - Define the 5-tab configuration with `CupertinoIcons` pairs, labels, and route strings
    - Widget tree: `Padding` (bottom: `MediaQuery.padding.bottom + 12`) → `ClipRRect(radiusFull)` → `BackdropFilter` → `DecoratedBox` (glass gradient + border) → `Row` of `GestureDetector` + `AnimatedContainer` (260 ms `easeOutCubic`)
    - Selected tab: filled icon in `AppColors.primary` + `AnimatedOpacity` label; unselected: outline icon in `AppColors.textTertiary`
    - Tap calls `onTap(i)` which triggers `AppRouter.push(route)`
    - _Requirements: 2.9, 8.1–8.8_

  - [ ]* 2.7 Write property tests for `AppBottomNav` (Properties 8–10)
    - **Property 8: Exactly one tab highlighted** — for any `currentIndex` in [0, 4], exactly one tab is in selected state
    - **Property 9: Selected tab shows label, unselected shows icon only** — for any index N, tab N shows filled icon + label; all others show outline icon only
    - **Property 10: Tap calls correct route** — for any tab index N, tapping invokes `AppRouter.push` with the route for tab N
    - **Validates: Requirements 8.3, 8.4, 8.6, 8.8, 33.3**

  - [ ] 2.8 Create `lib/core/widgets/app_scaffold.dart`
    - Implement `AppScaffold` as a `StatelessWidget` accepting `title`, `body`, `currentNavIndex`, `showBackButton`, `subtitle`, `headerActions`, `floatingActionButton`, `scrollController`
    - Wrap body in `AppMeshBackground`; support `_ParallaxBody` when `scrollController` is provided
    - Set `extendBody: true` and `extendBodyBehindAppBar: true` on the underlying `Scaffold`
    - Render `AppHeader` as `appBar`; render `AppBottomNav` only when `currentNavIndex` is non-null
    - _Requirements: 6.1–6.7_

  - [ ]* 2.9 Write property tests for `AppScaffold` (Properties 6–7)
    - **Property 6: Body always wrapped in AppMeshBackground** — for any body widget, `AppMeshBackground` is an ancestor of the body
    - **Property 7: Bottom nav presence matches currentNavIndex** — for any index in [0,4] renders `AppBottomNav`; for null renders none
    - **Validates: Requirements 6.1, 6.3, 6.4**

  - [ ] 2.10 Create `lib/core/widgets/app_button.dart`
    - Implement `AppButtonVariant` enum: `primary`, `secondary`, `destructive`, `ghost`
    - Implement `AppButton` as a `StatefulWidget` accepting `label`, `onPressed`, `variant`, `isLoading`, `isFullWidth`, `icon`
    - Spring animation: `AnimationController(duration: 160ms)` + `CurvedAnimation(Curves.easeOutBack)`, scale 1.0→0.94 on `onTapDown`, reversed on `onTapUp`/`onTapCancel`
    - Widget tree: `Opacity` (0.5 when disabled) → `GestureDetector` → `AnimatedBuilder` → `Transform.scale` → `AppGlassPanel(tint: variantTint, borderRadius: radiusFull)` → `Row` (icon at 18 dp + label or `CircularProgressIndicator`)
    - Variant tint/colour mapping per design doc
    - _Requirements: 2.8, 9.1–9.9_

  - [ ]* 2.11 Write property tests for `AppButton` (Properties 11–12)
    - **Property 11: Spring scale animation on all variants** — for any variant, `onTapDown` reaches scale 0.94; `onTapUp`/`onTapCancel` returns to 1.0
    - **Property 12: Icon rendered at 18dp for any IconData** — for any `IconData`, icon is rendered at exactly 18 logical pixels
    - **Validates: Requirements 9.6, 9.8, 2.8, 33.2**

  - [ ] 2.12 Create `lib/core/widgets/app_text_field.dart`
    - Implement `AppTextField` as a `StatelessWidget` accepting `label`, `controller`, `prefix`, `suffix`, `validator`, `keyboardType`, `obscureText`, `maxLines`, `onChanged`
    - Widget tree: `Column` → `Text(label.toUpperCase(), style: labelSmall)` + `ClipRRect(radiusMd)` → `BackdropFilter(blur 16/16)` → `DecoratedBox(glassWhite)` → `TextFormField`
    - Border states: enabled `glassBorder` 0.8 px, focused `primary` 1.5 px, error `danger` 1.0 px
    - _Requirements: 10.1–10.6_

  - [ ]* 2.13 Write property test for `AppTextField` (Property 13)
    - **Property 13: Label uppercased for any string** — for any non-empty label string, rendered text is the uppercase version
    - **Validates: Requirements 10.2**

  - [ ] 2.14 Create `lib/core/widgets/app_card.dart`
    - Implement `AppCard` as a `StatelessWidget` accepting `child`, `onTap`, `padding`
    - Wrap `AppGlassPanel(padding: padding ?? AppSpacing.md)` in `GestureDetector` when `onTap` is provided
    - _Requirements: 11.1–11.2_

  - [ ] 2.15 Create `lib/core/widgets/app_badge.dart`
    - Implement `AppBadgeVariant` enum: `active`, `pending`, `completed`, `flagged`, `info`
    - Implement `AppBadge` as a `StatelessWidget` accepting `label` and `variant`
    - Render `label.toUpperCase()` in `AppTextStyles.labelSmall` with variant colour; background at 15% opacity of variant colour
    - Variant → colour mapping per design doc
    - _Requirements: 11.3–11.6_

  - [ ]* 2.16 Write property test for `AppBadge` (Property 14)
    - **Property 14: Label uppercased and background at 15% opacity for any string and variant** — for any label and variant, text is uppercase and background uses `variantColor.withOpacity(0.15)`
    - **Validates: Requirements 11.6**

  - [ ] 2.17 Create `lib/core/widgets/app_avatar.dart`
    - Implement `AppAvatar` as a `StatelessWidget` accepting `imageUrl`, `initials`, `radius` (default 24)
    - Render `CircleAvatar` inside a `Container` with circular `glassBorder` ring (1.5 px) and glass gradient
    - _Requirements: 11.7_

  - [ ] 2.18 Create `lib/core/widgets/app_loading_view.dart`, `app_error_view.dart`, `app_empty_view.dart`
    - `AppLoadingView`: centred `CircularProgressIndicator(color: AppColors.primary)` + optional message in `AppTextStyles.bodyMedium`
    - `AppErrorView`: centred `Icons.error_outline` at 48 dp in `AppColors.danger` + message + optional `AppButton('Retry', onPressed: onRetry)`
    - `AppEmptyView`: centred icon (default `Icons.inbox_outlined`) at 48 dp in `AppColors.textTertiary` + message
    - _Requirements: 12.1–12.4_

  - [ ] 2.19 Checkpoint — Phase 2 quality gate
    - Ensure all widget tests pass and `flutter analyze` reports zero issues. Ask the user if questions arise.

- [ ] 3. Phase 3 — Data Layer
  - [ ] 3.1 Create data model files in `lib/data/models/`
    - `medication.dart`: `MedicineType` enum (PO/ORAL/INJECTION/TOPICAL/OTHER), `MedicineUnit` enum (TABLET/CAPSULE/ML/MG/DROP/OTHER), `DosageSlot` class (amount, beforeMeal, time?), `Medication` class with all backend fields: `id`, `prescriptionId`, `rowNumber`, `medicineName`, `medicineNameKhmer?`, `medicineType`, `unit`, `dosageAmount`, `frequency?`, `duration?`, `morningDosage?`, `afternoonDosage?`, `eveningDosage?`, `nightDosage?`, `timing?`, `isPRN`, `beforeMeal`, `description?`, `additionalNote?`, `imageUrl?`, `fromJson`, `toJson`, `copyWith`
    - `prescription.dart`: `PrescriptionStatus` enum (DRAFT/ACTIVE/PAUSED/INACTIVE) + `Prescription` class with backend fields: `id`, `patientId`, `patientName`, `patientGender`, `patientAge`, `symptoms`, `status`, `createdAt`, `doctorId?`, `diagnosis?`, `clinicalNote?`, `followUpDate?`, `startDate?`, `endDate?`, `isUrgent`, `urgentReason?`, `currentVersion`, `medications`, `ocrMetadata?`, `fromJson`, `toJson`
    - `dose_event.dart`: `TimePeriod` enum (MORNING/AFTERNOON/EVENING/NIGHT), `DoseEventStatus` enum (DUE/TAKEN_ON_TIME/TAKEN_LATE/MISSED/SKIPPED), `DoseEvent` class with `id`, `prescriptionId`, `medicationId`, `patientId`, `scheduledTime`, `timePeriod`, `status`, `reminderTime?`, `takenAt?`, `skipReason?`, `wasOffline`, `fromJson`, `toJson`
    - `schedule_slot.dart`: `ScheduleSlot` with `timePeriod` (TimePeriod), `displayTime`, `doseEvents` (List<DoseEvent>), `fromJson`, `toJson`
    - `user.dart`: `UserRole` enum (PATIENT/DOCTOR/FAMILY_MEMBER), `User` with `id`, `role`, `firstName?`, `lastName?`, `fullName?`, `email?`, `phoneNumber?`, `profilePictureUrl?`, `specialty?`, `subscriptionTier?`, `dailyProgress?`, `displayName` getter, `fromJson`, `toJson`
    - Repository is the only layer that constructs domain models from raw JSON maps
    - _Requirements: 14.1–14.6, 19.1–19.2_

  - [ ]* 3.2 Write property-based serialisation tests for `Medication` (Property 29 — Medication)
    - **Property 29a: Medication round-trip** — for any valid `Medication`, `Medication.fromJson(m.toJson())` produces an equivalent object
    - **Property 30a: toJson produces JSON-primitive values only** — no DateTime, no non-serialisable types
    - Use `fast_check` with `arbitraryMedication()`, 200 iterations
    - **Validates: Requirements 19.3, 30.1, 30.5**

  - [ ]* 3.3 Write property-based serialisation tests for `Prescription` (Property 29 — Prescription)
    - **Property 29c: Prescription round-trip** — for any valid `Prescription`, `Prescription.fromJson(p.toJson())` produces an equivalent object
    - Use `fast_check`, 200 iterations
    - **Validates: Requirements 30.3**

  - [ ]* 3.4 Write property-based serialisation tests for `ScheduleSlot` (Property 29 — ScheduleSlot)
    - **Property 29d: ScheduleSlot round-trip** — for any valid `ScheduleSlot`, `ScheduleSlot.fromJson(s.toJson())` produces an equivalent object
    - Use `fast_check`, 200 iterations
    - **Validates: Requirements 30.4**

  - [ ] 3.5 Create service files in `lib/data/services/`
    - `auth_service.dart`: `AuthService` with `login(identifier, password)` → `POST /auth/login`, `getCurrentUser()` → `GET /users/me`
    - `prescription_service.dart`: `PrescriptionService` with `fetchPrescriptions({status?})` → `GET /prescriptions?status=`, `fetchById(id)` → `GET /prescriptions/:id`, `createPatientPrescription(dto)` → `POST /prescriptions/patient`, `confirmPrescription(id)` → `POST /prescriptions/:id/confirm`, `deletePrescription(id)` → `DELETE /prescriptions/:id`
    - `dose_service.dart`: `DoseService` with `getSchedule({date?, groupBy?})` → `GET /doses/schedule`, `getTodaysDoses()` → `GET /doses/today`, `markTaken(id, {takenAt?, offline?})` → `PATCH /doses/:id/taken`, `skip(id, {reason?})` → `PATCH /doses/:id/skipped`
    - `ocr_service.dart`: `OcrService` with `extractOnly(fileBytes, filename, mimeType)` → `POST /ocr/extract` (multipart), `scanAndSave(fileBytes, filename, mimeType)` → `POST /ocr/scan` (multipart)
    - `notification_service.dart`: `NotificationService` with `fetchAll({unreadOnly?})` → `GET /notifications`, `markRead(id)` → `PATCH /notifications/:id/read`
    - `connection_service.dart`: `ConnectionService` with `getFamilyMembers()` → `GET /connections/family`, `getCaregivers()` → `GET /connections/caregivers`
    - Non-200 responses throw `Exception('HTTP $statusCode: $message')`; services hold zero mutable state
    - _Requirements: 15.1–15.5_

  - [ ] 3.6 Create `lib/data/repositories/prescription_repository.dart`
    - Implement `_CacheEntry<T>` helper with `isValid` (5-min TTL)
    - Implement `PrescriptionRepository` with `_cache`, `_byIdCache`, `getPrescriptions({forceRefresh, status?})`, `getById`, `createPatientPrescription(dto)`, and private `_fromMap`
    - `_fromMap` uses camelCase field names matching NestJS JSON: `patientId`, `patientName`, `patientGender`, `patientAge`, `symptoms`, `createdAt`, `isUrgent`, `currentVersion`, `ocrMetadata`
    - Cache-hit path: return cached data without calling service
    - Stale-cache fallback: return stale data when service throws and cache exists
    - Rethrow when service throws and no cache exists
    - _Requirements: 16.1–16.7_

  - [ ] 3.7 Create remaining repository files in `lib/data/repositories/`
    - `dose_repository.dart`: `DoseRepository` with `getSchedule({date?})` → returns `List<DoseEvent>`, `getTodaysDoses()` → returns `List<DoseEvent>`, `markTaken(id, {takenAt?, offline?})`, `skip(id, {reason?})`; follows same 5-min TTL cache pattern
    - `auth_repository.dart`: `AuthRepository` with `login(identifier, password)`, `getCurrentUser()` → returns `User`, `logout()` (clears local JWT)
    - `notification_repository.dart`: `NotificationRepository` with `fetchAll({unreadOnly?})`, `markRead(id)`
    - `connection_repository.dart`: `ConnectionRepository` with `getFamilyMembers()` → `GET /connections/family`, `getCaregivers()` → `GET /connections/caregivers`; returns `List<User>`
    - _Requirements: 16.1–16.6_

  - [ ]* 3.8 Write repository cache unit tests for `PrescriptionRepository` (Properties 30–31)
    - **Property 31: Cache length never exceeds last fetch count** — after successful fetch, cache length ≤ service response length
    - Unit tests: cache-hit avoids service call, `forceRefresh: true` always calls service, stale-cache fallback on service error, rethrow when no cache
    - **Validates: Requirements 16.2–16.7, 31.1–31.5**

  - [ ] 3.9 Checkpoint — Phase 3 quality gate
    - Ensure all serialisation PBTs and repository tests pass. Ask the user if questions arise.

- [ ] 4. Phase 4 — Domain Use Cases
  - [ ] 4.1 Create `lib/domain/models/ocr_result.dart`
    - Implement `OcrResult` with `medications`, `detectedLanguage`, `confidence`, `aiStatus`, `needsReview`, `patientName?`, `doctorName?`, `fromJson`, `toJson`
    - `aiStatus`: `'ok' | 'not_responded'`; `needsReview`: bool from `extraction_summary.needs_review`
    - _Requirements: 18.1, 19.2_

  - [ ]* 4.2 Write property-based serialisation test for `OcrResult` (Property 29 — OcrResult)
    - **Property 29b: OcrResult round-trip** — for any valid `OcrResult`, `OcrResult.fromJson(r.toJson())` produces an equivalent object with same `detectedLanguage`, `confidence`, `aiStatus`, `needsReview`, `patientName`, `doctorName`, and equivalent `medications` list
    - **Property 30b: toJson produces JSON-primitive values only**
    - Use `fast_check`, 200 iterations
    - **Validates: Requirements 19.4, 30.2, 30.5**

  - [ ] 4.3 Create `lib/domain/use_cases/generate_schedule_use_case.dart`
    - Implement `GenerateScheduleUseCase` with `execute(List<DoseEvent> doseEvents) → List<ScheduleSlot>`
    - Slot bucketing algorithm: build `{MORNING, AFTERNOON, EVENING, NIGHT}` buckets from `doseEvent.timePeriod`; emit `ScheduleSlot` only for non-empty buckets; return empty list for empty input
    - Display times: MORNING→'08:00 AM', AFTERNOON→'12:00 PM', EVENING→'06:00 PM', NIGHT→'09:00 PM'
    - Pure function — no side effects; does NOT compute schedules from medications
    - _Requirements: 17.1–17.10_

  - [ ]* 4.4 Write property-based tests for `GenerateScheduleUseCase` (Properties 18–23)
    - **Property 18: No dose event loss** — total dose events across all slots equals input length (200 iterations)
    - **Property 19: No duplication across slots** — each dose event appears in exactly one slot (200 iterations)
    - **Property 20: Idempotence** — calling `execute` twice with same input returns equivalent results (200 iterations)
    - **Property 21: Correct displayTime per timePeriod** — for any list with single timePeriod, returned slot has correct `displayTime` (200 iterations)
    - **Property 22: At most four slots** — result length ≤ 4 for any input (200 iterations)
    - **Property 23: Only non-empty slots returned** — every slot in result has at least one dose event (200 iterations)
    - Use `fast_check` with `arbitraryDoseEvent()` and `fc.Parameters(numRuns: 200)`
    - **Validates: Requirements 17.1–17.10, 28.1–28.5**

  - [ ] 4.5 Create `lib/domain/use_cases/process_ocr_result_use_case.dart`
    - Implement `ProcessOcrResultUseCase(OcrService _ocrService)` with `execute(List<int> fileBytes, String filename, String mimeType) → Future<OcrResult>`
    - Calls `_ocrService.extractOnly(fileBytes, filename, mimeType)` → `POST /ocr/extract` (server-side OCR)
    - Maps server response: `extraction_summary.confidence_score` → `confidence`, `extraction_summary.needs_review` → `needsReview`, `ai_status` → `aiStatus`
    - Language detection from OCR response text: Khmer chars U+1780–U+17FF → 'KH'; French keywords → 'FR'; else → 'EN'
    - Patient/doctor names: prefer AI-enhanced values (`ai_enhanced.patient.name`, `ai_enhanced.prescriber_name`) over raw OCR fields
    - Never throws — returns empty `OcrResult` with `confidence == 0.0` if server returns no medications
    - _Requirements: 18.1–18.11_

  - [ ]* 4.6 Write property-based tests for `ProcessOcrResultUseCase` (Properties 24–28)
    - **Property 24: Language detection correctness** — Khmer text → 'KH', French keywords → 'FR', other → 'EN' (200 iterations)
    - **Property 25: Language detection idempotence** — same text always returns same `detectedLanguage` (200 iterations)
    - **Property 26: Confidence in valid range [0.0, 1.0]** — for any server response (200 iterations)
    - **Property 27: Extracted medications have non-empty medicineName** — for any server response with medications (200 iterations)
    - **Property 28: Server response with medications yields confidence > 0.0** — for any response containing ≥1 medication (200 iterations)
    - Use `fast_check` with mock `OcrService` returning arbitrary responses, `fc.Parameters(numRuns: 200)`
    - **Validates: Requirements 18.2–18.11, 29.1–29.5**

  - [ ] 4.7 Checkpoint — Phase 4 quality gate
    - Ensure all domain use case PBTs pass and `flutter analyze` reports zero issues. Ask the user if questions arise.

- [ ] 5. Phase 5 — UI Screens
  - [ ] 5.1 Create `lib/ui/shared/base_view_model.dart`
    - Implement `BaseViewModel extends ChangeNotifier` with `_isLoading`, `_hasError`, `_errorMessage` fields and their getters
    - Implement `_run(Future<void> Function() action)` pattern: guard against concurrent calls (`if (_isLoading) return`), set `isLoading=true`/`hasError=false`, call `notifyListeners()`, catch exceptions into `_hasError`/`_errorMessage`, always set `isLoading=false` in `finally`
    - _Requirements: 3.3, 3.8, 32.3–32.5_

  - [ ] 5.2 Create `lib/ui/home/home_view_model.dart` and `home_view.dart`
    - `HomeViewModel extends BaseViewModel`: inject `PrescriptionRepository` and `DoseRepository`; expose `prescriptions`, `todaysDoses`, `isEmpty` getters; `load()` fetches both concurrently via `Future.wait([_prescriptionRepo.getPrescriptions(status:'ACTIVE'), _doseRepo.getTodaysDoses()])`
    - `HomeView`: `AppScaffold(title:'Home', currentNavIndex:0)` → `Consumer<HomeViewModel>` → `AppLoadingView` / `AppErrorView(onRetry: vm.load)` / `AppEmptyView` / `ListView` with `AppCard` + `AppBadge`
    - _Requirements: 20.1–20.9_

  - [ ]* 5.3 Write ViewModel state machine tests for `HomeViewModel` (Properties 15–17)
    - **Property 15: Mutual exclusion invariant** — `isLoading` and `hasError` never both true; `isLoading` and `isEmpty` never both true (100 iterations)
    - **Property 16: Exception always caught** — for any exception thrown by repository, after `load()` completes: `hasError=true`, `isLoading=false`, `errorMessage` non-empty (100 iterations)
    - **Property 17: Eventual termination** — for any sequence of `load()` calls, ViewModel eventually reaches `isLoading=false` (100 iterations)
    - **Validates: Requirements 3.8, 12.5, 12.6, 32.1–32.6**

  - [ ] 5.4 Create `lib/ui/prescriptions/prescription_list_view_model.dart` and `prescription_list_view.dart`
    - `PrescriptionListViewModel`: inject `PrescriptionRepository`; expose `prescriptions`, `isLoading`, `hasError`, `errorMessage`; `load()` fetches prescriptions; `onTapPrescription(id)` calls `AppRouter.push(AppRoutes.prescriptionDetail, arguments: id)`
    - `PrescriptionListView`: `AppScaffold(currentNavIndex:0)` → `Consumer` → loading/error/empty/list states; list items use `AppCard` + `AppBadge`
    - _Requirements: 21.1–21.3_

  - [ ] 5.5 Create `lib/ui/prescriptions/prescription_detail_view_model.dart` and `prescription_detail_view.dart`
    - `PrescriptionDetailViewModel`: inject `PrescriptionRepository` and prescription `id`; expose `prescription` getter; `load()` calls `_repo.getById(_id)`
    - `PrescriptionDetailView`: `AppScaffold(showBackButton:true)` → `Consumer` → loading/error/detail content using `AppCard` widgets
    - _Requirements: 21.4–21.5_

  - [ ] 5.6 Create `lib/ui/prescriptions/create_prescription_view_model.dart` and `create_prescription_view.dart`
    - `CreatePrescriptionViewModel`: `TextEditingController` fields for `title` (required), `startDate` (required), `doctorName?`, `diagnosis?`, `notes?`; `medicines` list of `Map<String, dynamic>` matching `PatientMedicationDto`; `_validate()` checks title, startDate, and non-empty medicines; `onSave()` builds `CreatePatientPrescriptionDto`-shaped map and calls `_repo.createPatientPrescription(dto)` then `AppRouter.pushReplacement(AppRoutes.prescriptions)`
    - `CreatePrescriptionView`: `AppScaffold(showBackButton:true)` → all form fields using `AppTextField`; medicine list with add/remove; submit via `AppButton`
    - _Requirements: 21.6–21.9_

  - [ ] 5.7 Create `lib/ui/medications/medication_list_view_model.dart` and `medication_list_view.dart`
    - `MedicationListViewModel`: inject `PrescriptionRepository`; expose `medications`, `isLoading`, `hasError`, `errorMessage`; `load()` fetches ACTIVE prescriptions then flattens their `medications` lists (no standalone medication API exists)
    - `MedicationListView`: `AppScaffold(currentNavIndex:1)` → `Consumer` → loading/error/empty/list states with `AppCard`
    - _Requirements: 22.1–22.3_

  - [ ] 5.8 Create `lib/ui/medications/add_medication_view_model.dart` and `add_medication_view.dart`
    - `AddMedicationViewModel`: inject `PrescriptionRepository`; `TextEditingController` fields for `title`, `startDate`, `medicineName`, `dosageAmount`, `dosageUnit`, `form`, `frequency`; `durationDays` int?; `beforeMeal` bool; `onSave()` validates required fields, builds `CreatePatientPrescriptionDto`-shaped map with single medicine entry, calls `_prescriptionRepo.createPatientPrescription(dto)`, then `AppRouter.pop()`
    - `AddMedicationView`: `AppScaffold(showBackButton:true)` → all form fields using `AppTextField` + beforeMeal toggle; submit via `AppButton`
    - _Requirements: 22.4–22.7_

  - [ ] 5.9 Create `lib/ui/scan/scan_view_model.dart` and `scan_view.dart`
    - `ScanState` enum: `idle`, `scanning`, `processing`, `success`, `error`
    - `ScanViewModel`: inject `ProcessOcrResultUseCase`; expose `scanState`, `progress`, `lastResult`; `onImageCaptured(fileBytes, filename, mimeType)` transitions `processing→success` and calls `_processOcrUseCase.execute(fileBytes, filename, mimeType)` (async server call to `POST /ocr/extract`), then navigates to `/scan/review`; `onRetry()` resets to `idle`
    - `ScanView`: `AppScaffold(showBackButton:true, currentNavIndex:2)` → `Stack` with `CameraPreview`, `CustomPaint(ScanBracketPainter)` in `AppColors.primary`, and `AppGlassPanel` progress overlay when processing
    - _Requirements: 23.1–23.7_

  - [ ] 5.10 Create `lib/ui/scan/ocr_review_view_model.dart` and `ocr_review_view.dart`
    - `OcrReviewViewModel`: inject `PrescriptionRepository` and `OcrResult`; expose `medications` (editable list), `detectedLanguage`, `confidence`; `updateMedication(index, updated)` mutates list and calls `notifyListeners()`; `onConfirm()` builds `CreatePatientPrescriptionDto`-shaped map (including `ocrMetadata` with confidence/language/aiStatus/needsReview) and calls `_repo.createPatientPrescription(dto)`, then navigates to `/prescriptions`
    - `OcrReviewView`: `AppScaffold(showBackButton:true)` → editable medication list using `AppTextField` + `AppBadge` for detected language and confidence
    - _Requirements: 23.8–23.11_

  - [ ] 5.11 Create `lib/ui/reminders/reminder_schedule_view_model.dart` and `reminder_schedule_view.dart`
    - `ReminderScheduleViewModel`: inject `DoseRepository` and `GenerateScheduleUseCase`; expose `slots`, `isLoading`, `hasError`, `errorMessage`; `load()` calls `_doseRepo.getSchedule()` then `_useCase.execute(doseEvents)` to group by timePeriod
    - `ReminderScheduleView`: `AppScaffold(currentNavIndex:0)` → `Consumer` → loading/error/empty states; each `ScheduleSlot` rendered as `AppCard` showing `displayTime` and dose event medicine names with `AppBadge` for status
    - _Requirements: 24.1–24.6_

  - [ ] 5.12 Create `lib/ui/family/family_view_model.dart` and `family_view.dart`
    - `FamilyViewModel`: inject `ConnectionRepository`; expose `familyMembers`, `isLoading`, `hasError`, `errorMessage`; `load()` calls `_connectionRepo.getFamilyMembers()` → `GET /connections/family`
    - `FamilyView`: `AppScaffold(currentNavIndex:3)` → `Consumer` → loading/error/empty states; each member rendered with `AppAvatar` + `AppCard`
    - _Requirements: 25.1–25.5_

  - [ ] 5.13 Create `lib/ui/settings/settings_view_model.dart` and `settings_view.dart`
    - `SettingsViewModel`: inject `AuthRepository`; expose `currentUser`, `isLoading`, `hasError`, `errorMessage`; `load()` calls `_authRepo.getCurrentUser()`; `onLogout()` calls `_authRepo.logout()` then `AppRouter.pushReplacement(AppRoutes.home)`
    - `SettingsView`: `AppScaffold(currentNavIndex:4)` → `Consumer` → user profile with `AppAvatar` + `AppCard` widgets
    - _Requirements: 26.1–26.5_

  - [ ]* 5.14 Write ViewModel state machine tests for remaining ViewModels (Properties 15–17)
    - Apply the same mutual exclusion, error handling, and eventual termination property tests to `PrescriptionListViewModel`, `MedicationListViewModel`, `ScanViewModel`, `ReminderScheduleViewModel`, `FamilyViewModel`, and `SettingsViewModel`
    - One test file per ViewModel under `test/ui/`
    - **Validates: Requirements 32.1–32.6**

  - [ ] 5.15 Checkpoint — Phase 5 quality gate
    - Ensure all ViewModel tests pass and `flutter analyze` reports zero issues. Ask the user if questions arise.

- [ ] 6. Phase 6 — Cleanup & QA
  - [ ] 6.1 Remove all raw `Scaffold(` usages from `lib/ui/`
    - Replace every `Scaffold(` with `AppScaffold(` in all view files
    - Verify zero `Scaffold(` hits via `grep -r 'Scaffold(' lib/ui/`
    - _Requirements: 6.7, 27.3_

  - [ ] 6.2 Remove all `ElevatedButton(` usages from `lib/ui/`
    - Replace every `ElevatedButton(` with `AppButton(` in all view files
    - Verify zero `ElevatedButton(` hits via `grep -r 'ElevatedButton(' lib/ui/`
    - _Requirements: 9.9, 27.4_

  - [ ] 6.3 Remove all raw `TextField(` and `TextFormField(` usages from `lib/ui/`
    - Replace every `TextField(` and `TextFormField(` with `AppTextField(` in all view files
    - Verify zero hits via `grep -r 'TextField\|TextFormField' lib/ui/`
    - _Requirements: 10.6, 27.5_

  - [ ] 6.4 Remove all hardcoded `Colors.` and inline `Color(0x...)` literals from `lib/ui/`
    - Replace every `Colors.*` reference with the appropriate `AppColors.*` token
    - Replace every inline `Color(0x...)` literal with the appropriate `AppColors.*` token
    - Verify zero hits via `grep -r 'Colors\.\|Color(0x' lib/ui/`
    - _Requirements: 1.5–1.6, 27.6–27.7_

  - [ ] 6.5 Remove all `Navigator.push(MaterialPageRoute(...))` calls from `lib/ui/`
    - Replace with `AppRouter.push(AppRoutes.*)` calls
    - Verify zero hits via `grep -r 'Navigator.push\|MaterialPageRoute' lib/ui/`
    - _Requirements: 27.8_

  - [ ] 6.6 Remove all direct `BackdropFilter(` usages from `lib/ui/`
    - Replace with `AppGlassPanel(` compositions
    - Verify zero hits via `grep -r 'BackdropFilter(' lib/ui/`
    - _Requirements: 27.9_

  - [ ] 6.7 Remove all `setState()` data-fetching calls from `*_view.dart` files
    - Ensure all data state is managed exclusively in ViewModels via `_run()` + `Consumer`
    - Verify zero `setState(() { ... fetch` patterns in view files
    - _Requirements: 27.10_

  - [ ] 6.8 Final checkpoint — full test suite and static analysis
    - Run `flutter analyze` — must report zero issues
    - Run `flutter test` — must pass with zero failures
    - Ensure all 31 properties are covered by passing tests
    - Ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Phases 2 and 3 can be developed in parallel after Phase 1 merges
- Each task references specific requirements for traceability
- Property tests use `fast_check` with `fc.Parameters(numRuns: 200)` for domain use cases and serialisation, and `numRuns: 100` for widget and ViewModel properties
- The `_run()` guard in `BaseViewModel` prevents concurrent loads (Requirement 32.5)
- All 13 global widgets must be used exclusively in `lib/ui/` — no raw Material equivalents
