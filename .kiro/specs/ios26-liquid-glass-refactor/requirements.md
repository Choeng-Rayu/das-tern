# Requirements Document

## Introduction

RxCam is a Flutter-based prescription and medication management app targeting Cambodian healthcare users.
This refactor migrates the existing codebase to the iOS 26 Liquid Glass aesthetic and adopts a strict
MVVM Clean Architecture with a fully reusable global widget system. The primary brand colour is `#009DFF`.

The refactor is structured in six phases: Foundation (theme + router + DI), Global Widget System,
Data Layer, Domain Use Cases, UI Screens, and Cleanup & QA. Every screen must use the global widget
system exclusively — no raw Material widgets, hardcoded colours, or inline styles are permitted in
the `ui/` layer.

---

## Glossary

- **App**: The RxCam Flutter application.
- **AppScaffold**: The global screen-wrapper widget that composes AppMeshBackground, AppHeader, and AppBottomNav.
- **AppGlassPanel**: The foundation glass widget built on BackdropFilter that all glass surfaces extend.
- **AppMeshBackground**: The animated three-orb radial-gradient background widget.
- **AppHeader**: The iOS 26 glass navigation bar implementing PreferredSizeWidget.
- **AppBottomNav**: The shrinking glass tab bar with five navigation tabs.
- **AppButton**: The glass button widget supporting four variants (primary, secondary, destructive, ghost).
- **AppTextField**: The glass input field widget with BackdropFilter blur.
- **AppCard**: The glass card container widget wrapping AppGlassPanel.
- **AppBadge**: The status pill badge widget with five variants (active, pending, completed, flagged, info).
- **AppAvatar**: The profile avatar widget with a glass ring border.
- **AppLoadingView**: The full-screen loading state widget.
- **AppErrorView**: The full-screen error state widget with optional retry action.
- **AppEmptyView**: The full-screen empty state widget.
- **ViewModel**: A ChangeNotifier subclass that holds async state and exposes command methods to the View.
- **Repository**: The single source of truth for a data domain; handles caching, error handling, and domain model creation.
- **Service**: A stateless class that wraps exactly one external API endpoint and returns raw DTOs.
- **UseCase**: A domain-layer class that encapsulates a single business rule or transformation.
- **GenerateScheduleUseCase**: The use case that groups Medication objects into morning/afternoon/evening/night ScheduleSlot buckets.
- **ProcessOcrResultUseCase**: The use case that extracts structured Medication objects from raw OCR text and detects the script language.
- **OcrResult**: The output model of ProcessOcrResultUseCase containing medications, detected language, confidence, and optional patient/doctor names.
- **ScheduleSlot**: A domain model grouping a list of Medication objects under a named time slot with a display time string.
- **Medication**: A domain model representing a single medication with name, dosage, frequency, and duration.
- **Prescription**: A domain model representing a scanned or manually created prescription.
- **Liquid Glass**: The iOS 26 visual design language using BackdropFilter blur, specular borders, spring physics, and animated mesh backgrounds.
- **Design Token**: A named constant in `core/theme/` (colour, spacing, radius, text style) that must be referenced instead of hardcoded values.
- **AppColors**: The design token class defining all colour constants including the `#009DFF` primary brand colour.
- **AppSpacing**: The design token class defining spacing scale and iOS 26 superellipse border-radius constants.
- **AppTextStyles**: The design token class defining the full typography scale.
- **AppRouter**: The named-route router with iOS-style slide transitions and a GlobalKey<NavigatorState> for ViewModel navigation.
- **DI**: Dependency injection via the `provider` package (^6.1.2) using MultiProvider in `app.dart`.
- **OCR**: Optical Character Recognition — the process of extracting text from a camera image of a prescription.
- **Khmer**: The script used in the Cambodian language (Unicode range U+1780–U+17FF).

---

## Requirements


### Requirement 1: Design Token System

**User Story:** As a developer, I want all colours, spacing, typography, and glass values defined once
in `core/theme/`, so that I can reference tokens everywhere and never hardcode visual values.

#### Acceptance Criteria

1. THE App SHALL define all colour constants in `lib/core/theme/app_colors.dart`, including the primary brand colour `#009DFF` as `AppColors.primary`.
2. THE App SHALL define spacing constants and iOS 26 superellipse border-radius tokens in `lib/core/theme/app_spacing.dart` with radius values of 12, 20, 28, 36, and 100 dp.
3. THE App SHALL define the full typography scale in `lib/core/theme/app_text_styles.dart` using `AppColors` colour tokens exclusively — no inline `Color(...)` values.
4. THE App SHALL define a dark `ThemeData` in `lib/core/theme/app_theme.dart` that sets `scaffoldBackgroundColor` to `AppColors.meshDeep` and configures a transparent `AppBarTheme`.
5. WHEN `flutter analyze` is executed, THE App SHALL report zero issues related to hardcoded colour or spacing values in any file under `lib/ui/`.
6. IF a file under `lib/ui/` references `Colors.` or an inline `Color(0x...)` literal, THEN THE App SHALL fail the `flutter analyze` lint check.


### Requirement 2: iOS 26 Liquid Glass Principles

**User Story:** As a user, I want the app to feel like a native iOS 26 application with fluid glass
surfaces, spring animations, and a living mesh background, so that the experience is visually
cohesive and premium.

#### Acceptance Criteria

1. THE AppGlassPanel SHALL apply `BackdropFilter` with `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` as the glass blur layer (Principle 1).
2. THE AppGlassPanel SHALL render a specular top-edge border using `AppColors.glassBorder` at `0.8` logical pixels width (Principle 3).
3. THE AppGlassPanel SHALL render a floating shadow using `AppColors.glassShadow` with `blurRadius: 32` and `offset: Offset(0, 8)` (Principle 3).
4. THE AppGlassPanel SHALL accept an optional `tint` colour parameter that tints the frosted gradient overlay (Principle 6).
5. THE AppGlassPanel SHALL use a `borderRadius` of at least 24 dp by default, configurable up to 36 dp (Principle 7).
6. THE AppMeshBackground SHALL animate three radial-gradient orbs using `AnimationController` instances with durations of 9 seconds and 13 seconds respectively (Principle 8).
7. THE AppMeshBackground SHALL use `AppColors.primary` (`#009DFF`), `AppColors.primaryDark`, and `AppColors.primaryLight` as the three orb colours (Principle 8).
8. THE AppButton SHALL apply a spring-physics scale animation from `1.0` to `0.94` on press using `AnimationController` with a 160 ms duration (Principle 4).
9. THE AppBottomNav SHALL animate the selected tab item to expand horizontally and display the label text, collapsing all unselected tabs to icon-only (Principle 2).
10. WHEN a screen is scrolled, THE AppScaffold SHALL support parallax depth via `Transform.translate` on glass layers driven by scroll offset (Principle 5).


### Requirement 3: MVVM Clean Architecture

**User Story:** As a developer, I want a strict four-layer architecture (View, ViewModel, Repository,
Service), so that each layer has a single responsibility and the codebase is testable and maintainable.

#### Acceptance Criteria

1. THE App SHALL organise source files into `lib/core/`, `lib/data/`, `lib/domain/`, and `lib/ui/` directories matching the defined folder structure.
2. WHEN a user interaction occurs, THE View SHALL call a ViewModel command method and SHALL NOT contain business logic, data transformation, or direct API calls.
3. THE ViewModel SHALL extend `ChangeNotifier` and SHALL expose `isLoading`, `hasError`, `errorMessage`, and data getter properties to the View.
4. THE ViewModel SHALL call Repository methods exclusively — it SHALL NOT import or call Service classes directly.
5. THE Repository SHALL be the sole location where raw JSON DTOs are transformed into domain model objects.
6. THE Service SHALL be stateless, SHALL wrap exactly one external API endpoint, and SHALL return raw DTOs without creating domain models.
7. WHEN a ViewModel needs to navigate, THE ViewModel SHALL use `AppRouter.push()` or `AppRouter.pop()` via the `GlobalKey<NavigatorState>` — it SHALL NOT import `BuildContext`.
8. IF a ViewModel method throws an exception, THEN THE ViewModel SHALL catch the exception, set `_errorMessage`, and call `notifyListeners()` without propagating the exception to the View.
9. THE App SHALL use the `provider` package (^6.1.2) with `MultiProvider` in `app.dart` to inject all Repositories and ViewModels.
10. WHEN `flutter analyze` is executed, THE App SHALL report zero issues across all layers.


### Requirement 4: AppGlassPanel Widget

**User Story:** As a developer, I want a single reusable glass surface widget, so that I never
manually compose `BackdropFilter`, gradients, and borders in individual screens.

#### Acceptance Criteria

1. THE AppGlassPanel SHALL accept `child`, `borderRadius`, `tint`, `blurRadius`, `opacity`, and `padding` parameters.
2. THE AppGlassPanel SHALL clip its content to the specified `borderRadius` using `ClipRRect`.
3. WHEN `tint` is provided, THE AppGlassPanel SHALL apply the tint colour at 18% opacity on the top-left gradient stop and 6% opacity on the bottom-right stop.
4. WHEN `tint` is not provided, THE AppGlassPanel SHALL default to white at the same opacity stops.
5. THE AppGlassPanel SHALL wrap the entire panel in an `Opacity` widget driven by the `opacity` parameter.
6. FOR ALL valid `AppGlassPanel` configurations, the widget tree SHALL always contain exactly one `BackdropFilter` node (invariant).


### Requirement 5: AppMeshBackground Widget

**User Story:** As a user, I want a living animated background on every screen, so that the app
feels dynamic and visually alive rather than static.

#### Acceptance Criteria

1. THE AppMeshBackground SHALL render three animated orbs using `RadialGradient` circles positioned behind all screen content.
2. THE AppMeshBackground SHALL use two `AnimationController` instances with `repeat(reverse: true)` — one at 9 seconds and one at 13 seconds.
3. WHEN the widget is disposed, THE AppMeshBackground SHALL dispose both `AnimationController` instances to prevent memory leaks.
4. THE AppMeshBackground SHALL use `AppColors.meshDeep` as the base background colour.
5. THE AppMeshBackground SHALL render orb 1 at opacity 0.30, orb 2 at opacity 0.22, and orb 3 at opacity 0.16.
6. THE AppMeshBackground SHALL accept a `child` widget and render it above all orb layers in the `Stack`.


### Requirement 6: AppScaffold Widget

**User Story:** As a developer, I want a single screen-wrapper widget, so that every screen
automatically gets the mesh background, glass header, and optional bottom navigation without
duplicating scaffold setup.

#### Acceptance Criteria

1. THE AppScaffold SHALL wrap the `body` in `AppMeshBackground` on every screen.
2. THE AppScaffold SHALL render `AppHeader` as the `appBar` with `PreferredSizeWidget` sizing.
3. WHEN `currentNavIndex` is provided, THE AppScaffold SHALL render `AppBottomNav` as the `bottomNavigationBar`.
4. WHEN `currentNavIndex` is null, THE AppScaffold SHALL render no bottom navigation bar.
5. THE AppScaffold SHALL set `extendBody: true` and `extendBodyBehindAppBar: true` on the underlying `Scaffold` so glass panels can bleed under the header and tab bar.
6. THE AppScaffold SHALL accept `showBackButton`, `headerActions`, `subtitle`, and `floatingActionButton` parameters and pass them to the appropriate child widgets.
7. WHEN `flutter analyze` is executed, THE App SHALL report zero raw `Scaffold(` usages in any file under `lib/ui/`.


### Requirement 7: AppHeader Widget

**User Story:** As a user, I want a glass navigation bar at the top of every screen, so that the
header feels part of the iOS 26 Liquid Glass design language.

#### Acceptance Criteria

1. THE AppHeader SHALL implement `PreferredSizeWidget` with a `preferredSize` of `Size.fromHeight(kToolbarHeight + 16)`.
2. THE AppHeader SHALL apply `BackdropFilter` with `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` behind the header content.
3. THE AppHeader SHALL render a bottom border using `AppColors.glassBorder` at 0.5 logical pixels.
4. WHEN `showBackButton` is true, THE AppHeader SHALL render a `CupertinoIcons.chevron_left` icon in `AppColors.primary` that calls `AppRouter.pop()` on tap.
5. WHEN `subtitle` is provided, THE AppHeader SHALL render it below the title using `AppTextStyles.bodyMedium` with `TextOverflow.ellipsis`.
6. WHEN `actions` are provided, THE AppHeader SHALL render them at the trailing end of the header row.


### Requirement 8: AppBottomNav Widget

**User Story:** As a user, I want a floating glass tab bar with five navigation tabs, so that I can
switch between Home, Medication, Scan, Family, and Settings with clear visual feedback.

#### Acceptance Criteria

1. THE AppBottomNav SHALL render exactly five tabs: Home, Medication, Scan, Family, and Settings.
2. THE AppBottomNav SHALL apply `BackdropFilter` blur and a glass gradient matching `AppColors.glassWhite` and `AppColors.glassBorder`.
3. WHEN a tab is selected, THE AppBottomNav SHALL animate the tab item to show the label text alongside the filled icon using `AppColors.primary`.
4. WHEN a tab is not selected, THE AppBottomNav SHALL show only the outline icon in `AppColors.textTertiary`.
5. THE AppBottomNav SHALL use `AnimatedContainer` with a 260 ms `easeOutCubic` curve for the expand/collapse animation.
6. WHEN a tab is tapped, THE AppBottomNav SHALL call `AppRouter.push()` with the corresponding named route.
7. THE AppBottomNav SHALL float above the screen content with bottom padding equal to `MediaQuery.padding.bottom + 12` dp.
8. FOR ALL tab indices 0–4, the selected tab SHALL highlight exactly one tab at a time (invariant).


### Requirement 9: AppButton Widget

**User Story:** As a developer, I want a single glass button widget with four variants, so that
every interactive button in the app has consistent spring-physics feedback and glass styling.

#### Acceptance Criteria

1. THE AppButton SHALL support four variants: `primary`, `secondary`, `destructive`, and `ghost`.
2. WHEN the `primary` variant is used, THE AppButton SHALL apply `AppColors.glassPrimary` as the tint and `AppColors.primary` as the label colour.
3. WHEN the `destructive` variant is used, THE AppButton SHALL apply `AppColors.glassDanger` as the tint and `AppColors.danger` as the label colour.
4. WHEN `isLoading` is true, THE AppButton SHALL replace the label with a `CircularProgressIndicator` and disable the `onPressed` callback.
5. WHEN `onPressed` is null, THE AppButton SHALL render at 50% opacity to indicate a disabled state.
6. THE AppButton SHALL apply a spring-physics scale animation from `1.0` to `0.94` on `onTapDown` and reverse on `onTapUp` or `onTapCancel`.
7. WHEN `isFullWidth` is true, THE AppButton SHALL expand to fill the available horizontal space.
8. WHEN `icon` is provided, THE AppButton SHALL render the icon at 18 dp to the left of the label text.
9. WHEN `flutter analyze` is executed, THE App SHALL report zero `ElevatedButton(` usages in any file under `lib/ui/`.


### Requirement 10: AppTextField Widget

**User Story:** As a developer, I want a single glass input field widget, so that every form field
in the app has consistent blur, border, and focus styling without per-screen `InputDecoration` setup.

#### Acceptance Criteria

1. THE AppTextField SHALL apply `BackdropFilter` with `ImageFilter.blur(sigmaX: 16, sigmaY: 16)` behind the input area.
2. THE AppTextField SHALL render the `label` in uppercase using `AppTextStyles.labelSmall` above the input field.
3. THE AppTextField SHALL use `AppColors.glassBorder` at 0.8 px for the enabled border and `AppColors.primary` at 1.5 px for the focused border.
4. THE AppTextField SHALL use `AppColors.danger` at 1.0 px for the error border state.
5. THE AppTextField SHALL accept `prefix`, `suffix`, `validator`, `keyboardType`, `obscureText`, and `maxLines` parameters.
6. WHEN `flutter analyze` is executed, THE App SHALL report zero raw `TextField(` or `TextFormField(` usages in any file under `lib/ui/`.


### Requirement 11: AppCard, AppBadge, AppAvatar Widgets

**User Story:** As a developer, I want reusable card, badge, and avatar widgets, so that list items
and status indicators are visually consistent across all screens.

#### Acceptance Criteria

1. THE AppCard SHALL wrap `AppGlassPanel` with a default padding of `AppSpacing.md` and accept an optional `onTap` callback.
2. WHEN `onTap` is provided, THE AppCard SHALL wrap the panel in a `GestureDetector`.
3. THE AppBadge SHALL support five variants: `active`, `pending`, `completed`, `flagged`, and `info`.
4. WHEN the `active` variant is used, THE AppBadge SHALL use `AppColors.success` as the badge colour.
5. WHEN the `flagged` variant is used, THE AppBadge SHALL use `AppColors.danger` as the badge colour.
6. THE AppBadge SHALL render the label in uppercase using `AppTextStyles.labelSmall` with a semi-transparent background at 15% opacity of the badge colour.
7. THE AppAvatar SHALL render a circular profile image or initials with a glass ring border using `AppColors.glassBorder`.


### Requirement 12: AppLoadingView, AppErrorView, AppEmptyView Widgets

**User Story:** As a user, I want consistent full-screen feedback states for loading, errors, and
empty data, so that I always understand the current state of the app.

#### Acceptance Criteria

1. THE AppLoadingView SHALL render a centred `CircularProgressIndicator` in `AppColors.primary` with an optional message in `AppTextStyles.bodyMedium`.
2. THE AppErrorView SHALL render a centred `Icons.error_outline` icon in `AppColors.danger` at 48 dp, a message, and an optional retry `AppButton`.
3. THE AppEmptyView SHALL render a centred icon (defaulting to `Icons.inbox_outlined`) in `AppColors.textTertiary` at 48 dp and a message.
4. WHEN `onRetry` is provided to `AppErrorView`, THE AppErrorView SHALL render an `AppButton` labelled "Retry" that calls `onRetry` on press.
5. FOR ALL ViewModel states where `isLoading` is true, THE View SHALL render `AppLoadingView` and SHALL NOT render data content simultaneously (invariant).
6. FOR ALL ViewModel states where `hasError` is true and `isLoading` is false, THE View SHALL render `AppErrorView` and SHALL NOT render data content simultaneously (invariant).


### Requirement 13: AppRouter

**User Story:** As a developer, I want a centralised named-route router with iOS-style slide
transitions, so that navigation is consistent and ViewModels can navigate without holding a
`BuildContext`.

#### Acceptance Criteria

1. THE AppRouter SHALL define named route constants for all screens: `/`, `/scan`, `/scan/review`, `/prescriptions`, `/prescriptions/detail`, `/prescriptions/create`, `/medications`, `/medications/add`, `/reminders`, `/family`, and `/settings`.
2. THE AppRouter SHALL use `PageRouteBuilder` with a `SlideTransition` from `Offset(1.0, 0.0)` to `Offset.zero` using `Curves.easeOutCubic` at 340 ms duration.
3. THE AppRouter SHALL expose a `GlobalKey<NavigatorState>` as `navigatorKey` for use in `MaterialApp`.
4. THE AppRouter SHALL expose static `push(String route)`, `pop()`, and `pushReplacement(String route)` methods that delegate to `navigatorKey.currentState`.
5. WHEN an unknown route is requested, THE AppRouter SHALL fall back to rendering `HomeView`.


### Requirement 14: Data Layer — Models

**User Story:** As a developer, I want strongly-typed domain models for User, Medication,
Prescription, Reminder, and ScheduleSlot, so that the UI layer never works with raw Maps or JSON.

#### Acceptance Criteria

1. THE App SHALL define a `Medication` model with fields: `id`, `name`, `dosage`, `frequency` (one of `morning`, `afternoon`, `evening`, `night`), `durationDays`, and optional `notes`.
2. THE App SHALL define a `Prescription` model with fields: `id`, `patientName`, `doctorName`, `medications`, `date`, `language` (one of `KH`, `EN`, `FR`), `status` (`PrescriptionStatus` enum), and optional `ocrConfidence`.
3. THE App SHALL define a `ScheduleSlot` model with fields: `time` (slot name), `displayTime` (formatted string), and `medications` (list of `Medication`).
4. THE App SHALL define a `Reminder` model with fields sufficient to represent a scheduled medication reminder.
5. THE App SHALL define a `User` model with fields sufficient to represent an authenticated user profile.
6. THE Repository SHALL be the only layer that constructs domain model instances from raw JSON maps.


### Requirement 15: Data Layer — Services

**User Story:** As a developer, I want stateless service classes that wrap individual API endpoints,
so that HTTP concerns are isolated and repositories can be tested with mock services.

#### Acceptance Criteria

1. THE App SHALL provide `AuthService`, `MedicationService`, `PrescriptionService`, `ReminderService`, and `NotificationService` classes.
2. THE PrescriptionService SHALL expose `fetchPrescriptions({int page, int limit})` and `fetchById(String id)` methods returning raw `Map<String, dynamic>` data.
3. WHEN an HTTP response has a non-200 status code, THE Service SHALL throw an `Exception` with a descriptive message including the status code.
4. THE Service SHALL hold zero mutable state — all methods SHALL be pure async functions.
5. THE Service SHALL perform minimal JSON decoding to raw DTOs only — it SHALL NOT create domain model instances.


### Requirement 16: Data Layer — Repositories

**User Story:** As a developer, I want repository classes that cache data and handle errors, so that
the app remains usable on slow or intermittent connections.

#### Acceptance Criteria

1. THE App SHALL provide `AuthRepository`, `MedicationRepository`, `PrescriptionRepository`, and `ReminderRepository` classes.
2. THE PrescriptionRepository SHALL maintain an in-memory cache with a 5-minute TTL.
3. WHEN the cache is valid and `forceRefresh` is false, THE PrescriptionRepository SHALL return cached data without calling the Service.
4. WHEN the Service throws an exception and a stale cache exists, THE PrescriptionRepository SHALL return the stale cache rather than propagating the exception.
5. WHEN the Service throws an exception and no cache exists, THE PrescriptionRepository SHALL rethrow the exception.
6. THE Repository SHALL transform raw DTOs into domain models using a private `_fromMap` method.
7. FOR ALL Repository `getById` calls, IF the item exists in the cache, THEN THE Repository SHALL return the cached item without a network call (round-trip property: cache-hit avoids network).


### Requirement 17: GenerateScheduleUseCase

**User Story:** As a user, I want my medications automatically grouped into morning, afternoon,
evening, and night slots, so that I can see my daily schedule at a glance on the reminder screen.

#### Acceptance Criteria

1. WHEN `GenerateScheduleUseCase.execute` is called with a list of `Medication` objects, THE GenerateScheduleUseCase SHALL return a list of `ScheduleSlot` objects containing only non-empty slots.
2. THE GenerateScheduleUseCase SHALL group medications with `frequency == 'morning'` into a slot with `displayTime == '08:00 AM'`.
3. THE GenerateScheduleUseCase SHALL group medications with `frequency == 'afternoon'` into a slot with `displayTime == '12:00 PM'`.
4. THE GenerateScheduleUseCase SHALL group medications with `frequency == 'evening'` into a slot with `displayTime == '06:00 PM'`.
5. THE GenerateScheduleUseCase SHALL group medications with `frequency == 'night'` into a slot with `displayTime == '09:00 PM'`.
6. WHEN a medication has an unrecognised `frequency` value, THE GenerateScheduleUseCase SHALL assign it to the `morning` slot as a default.
7. WHEN called with an empty medication list, THE GenerateScheduleUseCase SHALL return an empty list.
8. FOR ALL valid medication lists, the total count of medications across all returned `ScheduleSlot` objects SHALL equal the count of input medications (invariant: no medications are lost or duplicated).
9. FOR ALL valid medication lists, each medication SHALL appear in exactly one `ScheduleSlot` (invariant: no duplicates across slots).
10. FOR ALL valid medication lists, calling `execute` twice with the same input SHALL return equivalent slot groupings (idempotence).


### Requirement 18: ProcessOcrResultUseCase

**User Story:** As a user, I want the app to automatically extract medication names, dosages, and
patient details from a scanned prescription image, so that I don't have to type them manually.

#### Acceptance Criteria

1. WHEN `ProcessOcrResultUseCase.execute` is called with raw OCR text, THE ProcessOcrResultUseCase SHALL return an `OcrResult` containing a list of `Medication` objects, a detected language code, and a confidence score.
2. WHEN the input text contains Khmer Unicode characters in the range U+1780–U+17FF, THE ProcessOcrResultUseCase SHALL set `detectedLanguage` to `'KH'`.
3. WHEN the input text contains French medical keywords (e.g. `comprimé`, `ordonnance`, `posologie`) and no Khmer characters, THE ProcessOcrResultUseCase SHALL set `detectedLanguage` to `'FR'`.
4. WHEN the input text contains neither Khmer characters nor French keywords, THE ProcessOcrResultUseCase SHALL set `detectedLanguage` to `'EN'`.
5. WHEN the input text contains a pattern matching `DrugName Dosage` (e.g. `Amoxicillin 500mg`), THE ProcessOcrResultUseCase SHALL extract a `Medication` with the corresponding `name` and `dosage` fields.
6. WHEN the input text contains a patient name pattern (e.g. `Patient: Name`), THE ProcessOcrResultUseCase SHALL set `OcrResult.patientName` to the extracted name.
7. WHEN the input text contains a doctor name pattern (e.g. `Dr. Name`), THE ProcessOcrResultUseCase SHALL set `OcrResult.doctorName` to the extracted name.
8. WHEN no medications are extracted from the input text, THE ProcessOcrResultUseCase SHALL set `OcrResult.confidence` to `0.0`.
9. WHEN at least one medication is extracted, THE ProcessOcrResultUseCase SHALL set `OcrResult.confidence` to a value greater than `0.0`.
10. FOR ALL input texts, the language detection SHALL be deterministic — calling `execute` twice with the same text SHALL return the same `detectedLanguage` (idempotence).
11. FOR ALL extracted `Medication` objects, the `name` field SHALL be non-empty and the `dosage` field SHALL be non-empty (invariant: no empty medication fields).


### Requirement 19: OCR Result Serialisation (Round-Trip)

**User Story:** As a developer, I want `OcrResult` and `Medication` objects to serialise and
deserialise correctly, so that scan results can be persisted and restored without data loss.

#### Acceptance Criteria

1. THE App SHALL provide `toJson()` and `fromJson()` methods on the `Medication` model.
2. THE App SHALL provide `toJson()` and `fromJson()` methods on the `OcrResult` model.
3. FOR ALL valid `Medication` objects, `Medication.fromJson(medication.toJson())` SHALL produce an equivalent object (round-trip property).
4. FOR ALL valid `OcrResult` objects, `OcrResult.fromJson(ocrResult.toJson())` SHALL produce an equivalent object with the same `detectedLanguage`, `confidence`, `patientName`, `doctorName`, and equivalent `medications` list (round-trip property).
5. WHEN `fromJson` receives a JSON map with a missing optional field, THE App SHALL use the field's default value rather than throwing an exception.


### Requirement 20: HomeView and HomeViewModel

**User Story:** As a user, I want a home screen that shows a summary of my prescriptions and
upcoming medications, so that I can quickly see what I need to take today.

#### Acceptance Criteria

1. THE HomeView SHALL use `AppScaffold` with `currentNavIndex: 0` and SHALL NOT use a raw `Scaffold`.
2. THE HomeViewModel SHALL expose `isLoading`, `hasError`, `errorMessage`, `prescriptions`, and `medications` getters.
3. WHEN `HomeViewModel.load()` is called, THE HomeViewModel SHALL fetch prescriptions from `PrescriptionRepository` and medications from `MedicationRepository` concurrently.
4. WHEN `HomeViewModel.load()` completes successfully, THE HomeViewModel SHALL set `isLoading` to false and `hasError` to false.
5. WHEN `HomeViewModel.load()` throws an exception, THE HomeViewModel SHALL set `hasError` to true and populate `errorMessage`.
6. THE HomeView SHALL render `AppLoadingView` while `isLoading` is true.
7. THE HomeView SHALL render `AppErrorView` with a retry callback when `hasError` is true.
8. THE HomeView SHALL render `AppEmptyView` when both prescription and medication lists are empty.
9. THE HomeView SHALL display prescription cards using `AppCard` and status badges using `AppBadge`.


### Requirement 21: Prescription Screens (List, Detail, Create)

**User Story:** As a user, I want to view, browse, and create prescriptions, so that I can manage
my medical records within the app.

#### Acceptance Criteria

1. THE PrescriptionListView SHALL use `AppScaffold` with `currentNavIndex: 0` and display prescriptions in a scrollable list of `AppCard` widgets.
2. THE PrescriptionListViewModel SHALL expose `prescriptions`, `isLoading`, `hasError`, and `errorMessage` getters.
3. WHEN a prescription card is tapped, THE PrescriptionListViewModel SHALL navigate to `/prescriptions/detail` passing the prescription ID as an argument.
4. THE PrescriptionDetailView SHALL use `AppScaffold` with `showBackButton: true` and display full prescription details.
5. THE PrescriptionDetailViewModel SHALL load the prescription by ID from `PrescriptionRepository` and expose it as a getter.
6. THE CreatePrescriptionView SHALL use `AppScaffold` with `showBackButton: true` and render all form fields using `AppTextField`.
7. THE CreatePrescriptionViewModel SHALL validate all required fields before submitting and SHALL expose a `validationErrors` map.
8. WHEN `CreatePrescriptionViewModel.onSave()` is called with valid data, THE CreatePrescriptionViewModel SHALL call `PrescriptionRepository` to persist the prescription and navigate back on success.
9. WHEN `CreatePrescriptionViewModel.onSave()` is called with invalid data, THE CreatePrescriptionViewModel SHALL set `hasError` to true with a descriptive `errorMessage` and SHALL NOT navigate.


### Requirement 22: Medication Screens (List, Add)

**User Story:** As a user, I want to view my medication list and add new medications, so that I can
keep my medication records up to date.

#### Acceptance Criteria

1. THE MedicationListView SHALL use `AppScaffold` with `currentNavIndex: 1` and display medications in a scrollable list of `AppCard` widgets.
2. THE MedicationListViewModel SHALL expose `medications`, `isLoading`, `hasError`, and `errorMessage` getters.
3. WHEN `MedicationListViewModel.load()` is called, THE MedicationListViewModel SHALL fetch medications from `MedicationRepository`.
4. THE AddMedicationView SHALL use `AppScaffold` with `showBackButton: true` and render all form fields using `AppTextField`.
5. THE AddMedicationViewModel SHALL validate that `name`, `dosage`, `frequency`, and `durationDays` are non-empty before saving.
6. WHEN `AddMedicationViewModel.onSave()` is called with valid data, THE AddMedicationViewModel SHALL persist the medication and navigate back.
7. WHEN `AddMedicationViewModel.onSave()` is called with invalid data, THE AddMedicationViewModel SHALL set `hasError` to true and SHALL NOT navigate.


### Requirement 23: Scan Screen and OCR Review Screen

**User Story:** As a user, I want to scan a prescription with my camera and review the extracted
medications before saving, so that I can quickly digitise paper prescriptions accurately.

#### Acceptance Criteria

1. THE ScanView SHALL use `AppScaffold` with `showBackButton: true` and `currentNavIndex: 2`.
2. THE ScanViewModel SHALL expose a `ScanState` enum with values: `idle`, `scanning`, `processing`, `success`, and `error`.
3. WHEN `ScanViewModel.onScanTapped()` is called, THE ScanViewModel SHALL transition through `scanning` → `processing` → `success` states and navigate to `/scan/review` on success.
4. THE ScanViewModel SHALL expose a `progress` value between `0.0` and `1.0` during the `scanning` and `processing` states.
5. THE ScanView SHALL render a progress overlay using `AppGlassPanel` showing the `progress` value and a "Detecting Khmer + French + English…" label while `isScanning` is true.
6. THE ScanView SHALL render scan-bracket corner markers using `CustomPainter` in `AppColors.primary`.
7. WHEN `ScanViewModel.onRetry()` is called, THE ScanViewModel SHALL reset to `ScanState.idle` and clear `errorMessage`.
8. THE OcrReviewView SHALL use `AppScaffold` with `showBackButton: true` and display the `OcrResult` from `ScanViewModel.lastResult`.
9. THE OcrReviewViewModel SHALL allow the user to edit extracted medication fields before saving.
10. WHEN `OcrReviewViewModel.onConfirm()` is called, THE OcrReviewViewModel SHALL save the prescription via `PrescriptionRepository` and navigate to `/prescriptions`.
11. THE OcrReviewView SHALL display the detected language badge (`KH`, `FR`, or `EN`) using `AppBadge`.


### Requirement 24: ReminderScheduleView and ReminderScheduleViewModel

**User Story:** As a user, I want to see my daily medication schedule grouped by time of day, so
that I know exactly when to take each medication.

#### Acceptance Criteria

1. THE ReminderScheduleView SHALL use `AppScaffold` with `currentNavIndex: 0` (accessible from Home) and display `ScheduleSlot` groups.
2. THE ReminderScheduleViewModel SHALL call `GenerateScheduleUseCase.execute` with the current medication list to produce `ScheduleSlot` objects.
3. THE ReminderScheduleViewModel SHALL expose `slots`, `isLoading`, `hasError`, and `errorMessage` getters.
4. WHEN `ReminderScheduleViewModel.load()` is called, THE ReminderScheduleViewModel SHALL fetch medications from `MedicationRepository` and pass them to `GenerateScheduleUseCase`.
5. THE ReminderScheduleView SHALL render each `ScheduleSlot` as an `AppCard` showing the `displayTime` and a list of medication names.
6. WHEN the medication list is empty, THE ReminderScheduleView SHALL render `AppEmptyView` with a message indicating no medications are scheduled.


### Requirement 25: FamilyView and FamilyViewModel

**User Story:** As a user, I want to view and manage family member profiles, so that I can track
medications for multiple people in my household.

#### Acceptance Criteria

1. THE FamilyView SHALL use `AppScaffold` with `currentNavIndex: 3`.
2. THE FamilyViewModel SHALL expose `familyMembers`, `isLoading`, `hasError`, and `errorMessage` getters.
3. WHEN `FamilyViewModel.load()` is called, THE FamilyViewModel SHALL fetch family member data from `AuthRepository`.
4. THE FamilyView SHALL render each family member using `AppAvatar` and `AppCard`.
5. WHEN the family member list is empty, THE FamilyView SHALL render `AppEmptyView` with an invitation to add a family member.


### Requirement 26: SettingsView and SettingsViewModel

**User Story:** As a user, I want a settings screen where I can manage my profile and app
preferences, so that I can personalise the app to my needs.

#### Acceptance Criteria

1. THE SettingsView SHALL use `AppScaffold` with `currentNavIndex: 4`.
2. THE SettingsViewModel SHALL expose `currentUser`, `isLoading`, `hasError`, and `errorMessage` getters.
3. WHEN `SettingsViewModel.load()` is called, THE SettingsViewModel SHALL fetch the current user profile from `AuthRepository`.
4. THE SettingsView SHALL render the user profile using `AppAvatar` and display user details in `AppCard` widgets.
5. WHEN `SettingsViewModel.onLogout()` is called, THE SettingsViewModel SHALL call `AuthRepository` to clear the session and navigate to the login route.


### Requirement 27: Cleanup and Anti-Pattern Elimination

**User Story:** As a developer, I want all legacy Material widget usages and hardcoded values
removed from the `ui/` layer, so that the codebase is fully consistent with the new design system.

#### Acceptance Criteria

1. WHEN `flutter analyze` is executed, THE App SHALL report zero issues.
2. WHEN `flutter test` is executed, THE App SHALL pass with zero test failures.
3. THE App SHALL contain zero usages of raw `Scaffold(` in any file under `lib/ui/`.
4. THE App SHALL contain zero usages of `ElevatedButton(` in any file under `lib/ui/`.
5. THE App SHALL contain zero usages of raw `TextField(` or `TextFormField(` in any file under `lib/ui/`.
6. THE App SHALL contain zero hardcoded `Colors.` references in any file under `lib/ui/`.
7. THE App SHALL contain zero inline `Color(0x...)` literals in any file under `lib/ui/`.
8. THE App SHALL contain zero `Navigator.push(MaterialPageRoute(...))` calls in any file under `lib/ui/`.
9. THE App SHALL contain zero `BackdropFilter` usages in any file under `lib/ui/` — all glass surfaces SHALL use `AppGlassPanel`.
10. THE App SHALL contain zero `setState()` calls used for data fetching in any `*_view.dart` file — data state SHALL be managed exclusively in ViewModels.


### Requirement 28: Property-Based Testing — GenerateScheduleUseCase

**User Story:** As a developer, I want property-based tests for `GenerateScheduleUseCase`, so that
correctness is verified across arbitrary medication lists, not just hand-picked examples.

#### Acceptance Criteria

1. THE App SHALL include a property-based test that verifies: for any list of `Medication` objects with valid `frequency` values, the total medication count across all returned `ScheduleSlot` objects equals the input list length (no-loss invariant).
2. THE App SHALL include a property-based test that verifies: for any list of `Medication` objects, each medication appears in exactly one slot (no-duplication invariant).
3. THE App SHALL include a property-based test that verifies: calling `execute` twice with the same input produces equivalent results (idempotence).
4. THE App SHALL include a property-based test that verifies: for any list containing only `morning` medications, the result contains exactly one slot with `time == 'morning'` (metamorphic property).
5. THE App SHALL include a property-based test that verifies: for any list containing medications across all four frequencies, the result contains at most four slots (metamorphic property: `result.length <= 4`).


### Requirement 29: Property-Based Testing — ProcessOcrResultUseCase

**User Story:** As a developer, I want property-based tests for `ProcessOcrResultUseCase`, so that
language detection and medication extraction are verified across diverse text inputs.

#### Acceptance Criteria

1. THE App SHALL include a property-based test that verifies: for any input text containing at least one Khmer character (U+1780–U+17FF), `detectedLanguage` is always `'KH'` (invariant).
2. THE App SHALL include a property-based test that verifies: for any input text, `confidence` is always in the range `[0.0, 1.0]` (invariant).
3. THE App SHALL include a property-based test that verifies: for any input text, calling `execute` twice returns the same `detectedLanguage` (idempotence).
4. THE App SHALL include a property-based test that verifies: for any input text, all extracted `Medication` objects have non-empty `name` and `dosage` fields (invariant).
5. THE App SHALL include a property-based test that verifies: for any empty string input, `execute` returns an `OcrResult` with an empty `medications` list and `confidence == 0.0` (edge case).


### Requirement 30: Property-Based Testing — Serialisation Round-Trip

**User Story:** As a developer, I want property-based round-trip tests for all serialisable models,
so that JSON persistence is verified to be lossless across arbitrary model instances.

#### Acceptance Criteria

1. THE App SHALL include a property-based test that verifies: for any valid `Medication` object, `Medication.fromJson(medication.toJson())` produces an equivalent object (round-trip property).
2. THE App SHALL include a property-based test that verifies: for any valid `OcrResult` object, `OcrResult.fromJson(ocrResult.toJson())` produces an equivalent object (round-trip property).
3. THE App SHALL include a property-based test that verifies: for any valid `Prescription` object, `Prescription.fromJson(prescription.toJson())` produces an equivalent object (round-trip property).
4. THE App SHALL include a property-based test that verifies: for any valid `ScheduleSlot` object, `ScheduleSlot.fromJson(slot.toJson())` produces an equivalent object (round-trip property).
5. THE App SHALL include a property-based test that verifies: `toJson()` on any model produces a `Map<String, dynamic>` where all values are JSON-primitive types (no `DateTime` objects, no nested non-serialisable types).


### Requirement 31: Repository Cache Correctness

**User Story:** As a developer, I want property-based tests for repository caching behaviour, so
that cache hits, misses, and staleness are verified to be correct under all conditions.

#### Acceptance Criteria

1. THE App SHALL include a test that verifies: after a successful `getPrescriptions()` call, a second call within the TTL window returns the same list without calling the Service (cache-hit invariant).
2. THE App SHALL include a test that verifies: after a `getPrescriptions(forceRefresh: true)` call, the Service is always called regardless of cache state (force-refresh invariant).
3. THE App SHALL include a test that verifies: when the Service throws and a cache exists, `getPrescriptions()` returns the cached list (stale-cache fallback).
4. THE App SHALL include a test that verifies: `getById(id)` for an ID present in the cache does not call the Service (cache-hit round-trip).
5. FOR ALL Repository instances, the cache SHALL never return a list with more items than were fetched from the Service in the most recent successful call (metamorphic property: `cache.length <= lastFetchedCount`).


### Requirement 32: ViewModel State Machine Correctness

**User Story:** As a developer, I want tests that verify ViewModel state transitions are correct,
so that the UI never shows contradictory states like loading and error simultaneously.

#### Acceptance Criteria

1. FOR ALL ViewModels, `isLoading` and `hasError` SHALL NOT both be true at the same time (mutual exclusion invariant).
2. FOR ALL ViewModels, `isLoading` and `isEmpty` SHALL NOT both be true at the same time (mutual exclusion invariant).
3. WHEN a ViewModel `load()` method is called, THE ViewModel SHALL set `isLoading` to true before any async operation begins.
4. WHEN a ViewModel `load()` method completes (success or failure), THE ViewModel SHALL set `isLoading` to false.
5. THE App SHALL include a test that verifies: calling `load()` on a ViewModel that is already loading does not start a second concurrent fetch (idempotence under concurrent calls).
6. THE App SHALL include a property-based test that verifies: for any sequence of `load()` and `refresh()` calls, the ViewModel always ends in a non-loading state (eventual termination property).


### Requirement 33: Widget System Completeness and Consistency

**User Story:** As a developer, I want widget tests that verify all 13 global widgets render
correctly and consistently, so that the design system is reliable across the whole app.

#### Acceptance Criteria

1. THE App SHALL include widget tests for all 13 global widgets: `AppGlassPanel`, `AppMeshBackground`, `AppScaffold`, `AppHeader`, `AppBottomNav`, `AppButton`, `AppTextField`, `AppCard`, `AppBadge`, `AppAvatar`, `AppLoadingView`, `AppErrorView`, and `AppEmptyView`.
2. THE AppButton widget test SHALL verify that the scale animation reaches `0.94` on press and returns to `1.0` on release.
3. THE AppBottomNav widget test SHALL verify that tapping tab index `N` highlights exactly tab `N` and no other tab.
4. THE AppBadge widget test SHALL verify that each of the five variants renders with the correct colour token.
5. THE AppErrorView widget test SHALL verify that the retry button is rendered when `onRetry` is provided and is absent when `onRetry` is null.
6. THE AppGlassPanel widget test SHALL verify that exactly one `BackdropFilter` widget exists in the subtree for any valid configuration.


### Requirement 34: Phased Delivery and PR Gates

**User Story:** As a developer, I want the refactor delivered in six discrete phases with clear
quality gates, so that each phase can be reviewed and merged independently without regressions.

#### Acceptance Criteria

1. THE App SHALL deliver Phase 1 (Foundation) as a standalone PR containing only `core/theme/`, `core/router/`, and `app.dart` changes.
2. THE App SHALL deliver Phase 2 (Global Widget System) as a standalone PR containing only `core/widgets/` additions.
3. THE App SHALL deliver Phase 3 (Data Layer) as a standalone PR containing only `data/` additions.
4. THE App SHALL deliver Phase 4 (Domain Use Cases) as a standalone PR containing only `domain/` additions.
5. THE App SHALL deliver Phase 5 (UI Screens) as a standalone PR containing only `ui/` additions and ViewModel wiring.
6. THE App SHALL deliver Phase 6 (Cleanup & QA) as a standalone PR that removes all legacy widget usages and passes all acceptance checks.
7. WHEN each phase PR is submitted, `flutter analyze` SHALL return zero issues before the PR is merged.
8. WHEN each phase PR is submitted, `flutter test` SHALL pass with zero failures before the PR is merged.

