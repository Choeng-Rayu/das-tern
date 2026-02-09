## **Implementation Plan - Das Tern Mobile App MVP**

### **Problem Statement**
Implement the MVP for Das Tern medication management mobile app focusing on:
- Patient can manually create medications
- System generates reminders (online + offline)
- Patient can mark medications as taken/done
- Multi-language support (English/Khmer)
- Offline-first architecture with backend sync

### **Requirements**
Based on user responses:
1. User Journey: Patient creates their own medication manually (no doctor involvement in MVP)
2. Local Storage: SQLite (sqflite) for medication data and dose events
3. State Management: Provider for app state management
4. Reminder System: Local notifications + Backend sync (production-ready)
5. Localization: Use existing ARB files, add missing keys as needed

### **Background**
- Existing file structure is well-organized with clear separation (models, services, ui)
- Localization files (app_en.arb, app_km.arb) already exist with basic translations
- Theme system structure is defined but not implemented
- Backend API is being developed separately (assume REST endpoints exist)
- Figma designs provide complete UI specifications for patient dashboard and medication flows

### **Proposed Solution**

Architecture Overview:
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                   │
│  (Screens + Widgets + Theme + Localization)             │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                  State Management Layer                 │
│              (Provider - App State)                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    Service Layer                        │
│  (API Service | Local DB Service | Notification Service)│
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                     Data Layer                          │
│         (SQLite DB ←→ Backend API Sync)                 │
└─────────────────────────────────────────────────────────┘


Key Technical Decisions:
- **Offline-First**: All data stored locally first, synced to backend when online
- **Reminder Strategy**: Local notifications scheduled from SQLite data, backend tracks sync state
- **Minimal Code**: Focus only on MVP features, no premature optimization

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


### **Task Breakdown**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 1: Project Setup & Dependencies**

Objective: Configure Flutter project with required dependencies for MVP

Implementation:
- Add dependencies to pubspec.yaml:
  - provider: ^6.1.1 (state management)
  - sqflite: ^2.3.0 (local database)
  - path_provider: ^2.1.1 (database path)
  - shared_preferences: ^2.2.2 (simple key-value storage)
  - flutter_local_notifications: ^16.3.0 (local reminders)
  - http: ^1.1.2 (API calls)
  - intl: ^0.18.1 (date formatting, already in project)
  - connectivity_plus: ^5.0.2 (network status)
- Configure localization in pubspec.yaml (already configured, verify)
- Run flutter pub get

Test Requirements:
- Verify all dependencies resolve without conflicts
- Run flutter doctor to ensure environment is ready

Demo: App builds successfully with all dependencies installed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 2: Core Models & Enums**

Objective: Create data models for medications, dose events, and enums

Implementation:
- Create lib/models/enums_model/medication_status.dart:
  - Enum: Draft, Active, Paused, Inactive
- Create lib/models/enums_model/dose_status.dart:
  - Enum: Due, Taken, TakenLate, Missed, Skipped
- Create lib/models/enums_model/medication_type.dart:
  - Enum: Regular, PRN
- Create lib/models/medication_model/medication.dart:
  - Fields: id, name, dosage, form, instructions, type, status, frequency, reminderTimes, createdAt, updatedAt
  - Methods: toMap(), fromMap(), toJson(), fromJson()
- Create lib/models/dose_event_model/dose_event.dart:
  - Fields: id, medicationId, scheduledTime, takenTime, status, notes
  - Methods: toMap(), fromMap()

Test Requirements:
- Unit tests for model serialization/deserialization
- Verify JSON conversion works correctly

Demo: Models can be instantiated and converted to/from JSON and Map

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 3: Local Database Service**

Objective: Implement SQLite database for offline storage

Implementation:
- Create lib/services/database_service.dart:
  - Initialize SQLite database with tables: medications, dose_events, sync_queue
  - CRUD methods for medications: createMedication(), getMedications(), updateMedication(), deleteMedication()
  - CRUD methods for dose events: createDoseEvent(), getDoseEvents(), updateDoseEvent()
  - Query methods: getMedicationsByStatus(), getDoseEventsByDate(), getPendingDoseEvents()
  - Sync queue methods: addToSyncQueue(), getSyncQueue(), removeSyncedItem()
- Database schema:
 
sql
  medications: id, name, dosage, form, instructions, type, status, frequency, reminder_times, created_at, updated_at, synced
  dose_events: id, medication_id, scheduled_time, taken_time, status, notes, synced
  sync_queue: id, action, table_name, record_id, data, created_at
  


Test Requirements:
- Unit tests for all CRUD operations
- Test database initialization and migration

Demo: Can create, read, update medications and dose events in local database

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 4: Theme System Implementation**

Objective: Implement light/dark theme switching with role-based colors

Implementation:
- Implement lib/ui/theme/light_mode.dart:
  - Define ThemeData with patient color scheme (Blue primary, Orange secondary)
  - Typography, card styles, button styles
- Implement lib/ui/theme/dark_mode.dart:
  - Define dark ThemeData with adjusted colors
- Implement lib/ui/theme/main_theme.dart:
  - ThemeProvider class extending ChangeNotifier
  - Methods: toggleTheme(), loadThemePreference(), saveThemePreference()
  - Use SharedPreferences to persist theme choice
- Update lib/main.dart:
  - Wrap app with ChangeNotifierProvider<ThemeProvider>
  - Configure MaterialApp with theme, darkTheme, themeMode

Test Requirements:
- Widget tests for theme switching
- Verify theme persists across app restarts

Demo: App displays with light theme by default, can toggle to dark theme in settings (placeholder settings screen)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 5: Localization Setup & Missing Keys**

Objective: Ensure localization works and add MVP-specific translation keys

Implementation:
- Review existing lib/l10n/app_en.arb and lib/l10n/app_km.arb
- Add missing keys for MVP features:
  - Medication creation: createMedication, medicationName, dosage, frequency, reminderTime, save, cancel
  - Dashboard: todaySchedule, daytime, night, pending, completed, markAsTaken
  - Status messages: medicationCreated, reminderSet, markedAsTaken
- Run flutter gen-l10n to regenerate localization classes
- Create lib/services/localization_service.dart:
  - LocaleProvider class extending ChangeNotifier
  - Methods: changeLocale(), loadLocalePreference(), saveLocalePreference()
- Update lib/main.dart:
  - Add LocaleProvider to providers
  - Configure MaterialApp with locale, localizationsDelegates, supportedLocales

Test Requirements:
- Verify all new keys exist in both ARB files
- Test language switching between English and Khmer

Demo: App displays in English by default, can switch to Khmer, all MVP screens show translated text

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 6: API Service & Sync Logic**

Objective: Implement backend API communication and offline sync

Implementation:
- Create lib/services/api_service.dart:
  - Base API client with error handling
  - Methods: createMedication(), updateMedication(), syncDoseEvents(), getMedications()
  - Handle authentication headers (assume token stored in SharedPreferences)
- Create lib/services/sync_service.dart:
  - SyncService class with connectivity monitoring
  - Method: syncPendingChanges() - processes sync queue
  - Method: syncMedications() - pulls latest from backend
  - Method: syncDoseEvents() - pushes local changes to backend
  - Auto-sync when connectivity restored
- Use connectivity_plus to detect online/offline state

Test Requirements:
- Mock API tests for all endpoints
- Test sync queue processing
- Test offline → online transition

Demo: Can create medication offline, see it sync to backend when online (mock backend responses)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 7: Notification Service**

Objective: Implement local notifications for medication reminders

Implementation:
- Create lib/services/notification_service.dart:
  - Initialize flutter_local_notifications
  - Configure Android and iOS notification channels
  - Method: scheduleReminder(DoseEvent) - schedule notification for specific dose
  - Method: scheduleMedicationReminders(Medication) - schedule all reminders for a medication
  - Method: cancelReminder(int notificationId)
  - Method: cancelAllReminders()
  - Handle notification tap → navigate to medication detail
- Generate notification IDs from dose event IDs
- Schedule notifications using exact alarm (Android 12+)

Test Requirements:
- Test notification scheduling
- Test notification cancellation
- Verify notifications fire at correct times (use test times)

Demo: Create medication with reminder time, receive local notification at scheduled time

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 8: Medication State Management**

Objective: Implement Provider-based state management for medications

Implementation:
- Create lib/services/medication_provider.dart:
  - MedicationProvider class extending ChangeNotifier
  - Properties: List<Medication> medications, bool isLoading, String? error
  - Methods:
    - loadMedications() - fetch from local DB
    - createMedication(Medication) - save to DB, schedule reminders, add to sync queue
    - updateMedicationStatus(id, status) - update status, reschedule reminders if needed
    - getMedicationsByTimeGroup(String timeGroup) - filter by daytime/night
- Create lib/services/dose_event_provider.dart:
  - DoseEventProvider class extending ChangeNotifier
  - Properties: List<DoseEvent> todayDoseEvents
  - Methods:
    - loadTodayDoseEvents() - fetch today's doses
    - markAsTaken(DoseEvent) - update status, save to DB, add to sync queue
    - getDoseEventsByTimeGroup(String timeGroup)

Test Requirements:
- Unit tests for all provider methods
- Test state updates trigger UI rebuilds

Demo: Provider can load medications, create new medication, update dose event status

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 9: Reusable UI Widgets**

Objective: Create reusable widgets for MVP screens

Implementation:
- Create lib/ui/widgets/medication_card.dart:
  - Display medication info: image, name, dosage, quantity, status
  - Props: Medication medication, VoidCallback onTap, VoidCallback onStatusToggle
  - Show status indicator (checkbox for pending, checkmark for done)
- Create lib/ui/widgets/time_group_section.dart:
  - Section header with time group label and color
  - Props: String label, Color color, List<Widget> children
- Create lib/ui/widgets/custom_button.dart:
  - Primary and secondary button styles
  - Props: String text, VoidCallback onPressed, bool isPrimary
- Create lib/ui/widgets/custom_text_field.dart:
  - Styled text input with label and validation
  - Props: String label, TextEditingController controller, String? Function(String?)? validator

Test Requirements:
- Widget tests for each component
- Test different states (loading, error, success)

Demo: Widgets render correctly with sample data, respond to interactions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 10: Create Medication Screen**

Objective: Implement medication creation form

Implementation:
- Create lib/ui/screens/patient_ui/create_medication_screen.dart:
  - Form fields: medication name, dosage, form (dropdown), instructions, type (Regular/PRN)
  - Frequency selector (times per day)
  - Reminder time picker(s) - multiple times for multiple doses
  - Save button → validate → create medication → schedule reminders → navigate back
  - Use AppLocalizations.of(context) for all text
  - Use Theme.of(context) for colors
  - Form validation: required fields, valid dosage format
- Integrate with MedicationProvider:
  - Call provider.createMedication() on save
  - Show loading indicator during save
  - Show success/error messages

Test Requirements:
- Widget tests for form validation
- Integration test for complete medication creation flow

Demo: Can fill form, create medication, see it saved to local DB, notification scheduled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 11: Patient Dashboard Screen**

Objective: Implement main patient dashboard with medication schedule

Implementation:
- Create lib/ui/screens/patient_ui/patient_dashboard_screen.dart:
  - Header: greeting, progress bar (taken/total), notification bell icon
  - Two time group sections: "ពេលថ្ងៃ" (Daytime - Blue), "ពេលយប់" (Night - Purple)
  - Each section lists medication cards using MedicationCard widget
  - Floating action button → navigate to create medication screen
  - Pull-to-refresh to reload medications
  - Use Consumer<DoseEventProvider> to display today's dose events
  - Calculate progress: completed doses / total doses
- Filter dose events by time group:
  - Daytime: 6:00 AM - 5:59 PM
  - Night: 6:00 PM - 5:59 AM
- Tap medication card → navigate to detail screen (Task 12)
- Tap status checkbox → mark as taken

Test Requirements:
- Widget tests for dashboard rendering
- Test medication filtering by time group
- Test progress calculation

Demo: Dashboard displays medications grouped by time, shows progress, can mark as taken

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 12: Medication Detail Screen**

Objective: Display detailed medication information

Implementation:
- Create lib/ui/screens/patient_ui/medication_detail_screen.dart:
  - Header: back button, medication name as title
  - Display fields:
    - Medication name + dosage (title)
    - Frequency (e.g., "3ដង/១ថ្ងៃ")
    - Timing (e.g., "បន្ទាប់ពីអាហារ" - after meals)
    - Recommended reminder times (list)
  - "កែប្រែការរុំលឹកពេលវេលា" button → edit reminder times (future task, show placeholder)
  - Analysis section (placeholder for future)
  - Use AppLocalizations for all labels
- Receive Medication object via navigation arguments

Test Requirements:
- Widget test for detail screen rendering
- Test navigation with medication data

Demo: Tap medication card on dashboard → see full details on detail screen

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 13: Bottom Navigation**

Objective: Implement patient bottom navigation bar

Implementation:
- Create lib/ui/widgets/patient_bottom_nav.dart:
  - 5 tabs based on Figma design:
    1. Home (ទំព័រដើម) - Dashboard
    2. Analysis (ការវិភាគថ្នាំ) - Placeholder
    3. Scan (center FAB) - Placeholder
    4. Family (មុខងារគ្រួសារ) - Placeholder
    5. Settings (ការកំណត់) - Placeholder
  - Only Home tab functional in MVP
  - Use icons from Figma design
  - Active tab highlighted with primary color
- Create lib/ui/screens/patient_ui/patient_main_screen.dart:
  - Scaffold with bottom navigation
  - Switch between screens based on selected tab
  - For MVP, only dashboard screen implemented, others show "Coming Soon"

Test Requirements:
- Widget test for navigation bar rendering
- Test tab selection changes screen

Demo: Bottom navigation displays, Home tab shows dashboard, other tabs show placeholder

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 14: Settings Screen (Theme & Language)**

Objective: Implement basic settings for theme and language switching

Implementation:
- Create lib/ui/screens/patient_ui/settings_screen.dart:
  - List of settings options:
    - Language selector (English/Khmer) - functional
    - Theme toggle (Light/Dark) - functional
    - Other options (placeholders): Profile, Notifications, Security, About, Logout
  - Language selector:
    - Use Consumer<LocaleProvider>
    - Dropdown or radio buttons for English/Khmer
    - Call provider.changeLocale() on selection
  - Theme toggle:
    - Use Consumer<ThemeProvider>
    - Switch widget for Light/Dark
    - Call provider.toggleTheme() on toggle
  - Use AppLocalizations for all text

Test Requirements:
- Widget test for settings screen
- Test language change updates UI
- Test theme change updates colors

Demo: Can switch language and theme from settings, changes persist across app restarts

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 15: Reminder Generation Logic**

Objective: Implement dose event generation when medication is activated

Implementation:
- Create lib/services/reminder_generator_service.dart:
  - Method: generateDoseEvents(Medication medication, int daysAhead):
    - Calculate dose times based on frequency and reminder times
    - Generate DoseEvent objects for next N days (default 7 days)
    - Save to local database
    - Schedule local notifications for each dose event
  - Handle different frequencies: 1x, 2x, 3x per day
  - For PRN medications: use default Cambodia timezone presets if no times specified
  - Return list of generated dose events
- Integrate into MedicationProvider.createMedication():
  - After saving medication, call generateDoseEvents()
  - Update medication status to Active

Test Requirements:
- Unit tests for dose event generation logic
- Test different frequencies generate correct number of events
- Test PRN default times

Demo: Create medication → dose events generated for next 7 days → notifications scheduled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 16: Offline Sync Queue Processing**

Objective: Implement background sync when app comes online

Implementation:
- Update lib/services/sync_service.dart:
  - Listen to connectivity changes using connectivity_plus
  - When online:
    - Process sync queue in order (FIFO)
    - For each queued item: call appropriate API endpoint
    - On success: remove from queue, update synced flag in local DB
    - On failure: keep in queue, retry with exponential backoff
  - Method: processSyncQueue() - main sync logic
  - Method: retrySyncItem(SyncQueueItem) - retry failed sync
- Add sync status indicator to dashboard:
  - Show "Syncing..." when sync in progress
  - Show "Offline" when no connectivity
  - Show checkmark when synced

Test Requirements:
- Test sync queue processing with mock API
- Test retry logic on API failure
- Test offline → online transition triggers sync

Demo: Create medication offline → go online → see sync indicator → medication synced to backend

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 17: Mark as Taken Flow**

Objective: Complete the mark-as-taken functionality with sync

Implementation:
- Update lib/services/dose_event_provider.dart:
  - Enhance markAsTaken(DoseEvent):
    - Update dose event status to Taken or TakenLate based on time window
    - Set takenTime to current timestamp
    - Save to local database
    - Add to sync queue
    - Cancel scheduled notification for this dose
    - Trigger sync if online
  - Add time window logic:
    - On time: within ±30 minutes of scheduled time
    - Late: after 30 minutes but before next dose
    - Missed: not taken before next dose (handled by background task)
- Update MedicationCard widget:
  - Checkbox tap calls provider.markAsTaken(doseEvent)
  - Show loading indicator during save
  - Animate status change (checkbox → checkmark)
  - Show "រួចរាល់" (done) label when completed

Test Requirements:
- Test mark as taken updates database
- Test time window logic (on time vs late)
- Test notification cancellation
- Test sync queue addition

Demo: Tap medication checkbox → status updates to done → notification cancelled → syncs to backend when online

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 18: App Initialization & Main Entry Point**

Objective: Wire everything together in main.dart

Implementation:
- Update lib/main.dart:
  - Initialize services in main():
    - DatabaseService.instance.initialize()
    - NotificationService.instance.initialize()
  - Setup MultiProvider with all providers:
    - ThemeProvider
    - LocaleProvider
    - MedicationProvider
    - DoseEventProvider
  - Configure MaterialApp:
    - Theme from ThemeProvider
    - Locale from LocaleProvider
    - Localization delegates
    - Home: PatientMainScreen
  - Load initial data:
    - Load theme preference
    - Load locale preference
    - Load medications
    - Load today's dose events
  - Setup connectivity listener for auto-sync

Test Requirements:
- Integration test for app initialization
- Test all providers are accessible
- Test initial data loads correctly

Demo: App launches → loads theme/locale preferences → displays dashboard with medications → reminders work → sync works

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 19: Error Handling & Loading States**

Objective: Add proper error handling and loading indicators

Implementation:
- Update all providers to include error states:
  - Add String? errorMessage property
  - Add bool isLoading property
  - Wrap async operations in try-catch
  - Set error message on failure
  - Clear error on success
- Update all screens to show loading/error states:
  - Show CircularProgressIndicator when isLoading
  - Show error message with retry button when errorMessage != null
  - Use SnackBar for transient messages (success/error)
- Create lib/ui/widgets/error_widget.dart:
  - Display error message with icon
  - Retry button
  - Props: String message, VoidCallback onRetry
- Create lib/ui/widgets/loading_widget.dart:
  - Centered loading indicator with optional message

Test Requirements:
- Test error states display correctly
- Test loading states display correctly
- Test retry functionality

Demo: Simulate API error → see error message → tap retry → see loading → see success

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


#### **Task 20: MVP Testing & Polish**

Objective: End-to-end testing and final polish for MVP release

Implementation:
- Write integration tests:
  - Complete medication creation flow
  - Dashboard display and interaction
  - Mark as taken flow
  - Offline → online sync flow
  - Language switching
  - Theme switching
- Manual testing checklist:
  - [ ] Create medication with all fields
  - [ ] See medication on dashboard in correct time group
  - [ ] Receive notification at scheduled time
  - [ ] Mark medication as taken
  - [ ] See progress bar update
  - [ ] Create medication offline
  - [ ] Go online and verify sync
  - [ ] Switch language, verify all text translates
  - [ ] Switch theme, verify colors change
  - [ ] Restart app, verify data persists
- Polish:
  - Add loading animations
  - Smooth transitions between screens
  - Haptic feedback on button taps
  - Accessibility labels for screen readers
  - Handle edge cases (empty states, no medications)
- Create empty state widget for dashboard when no medications

Test Requirements:
- All integration tests pass
- Manual testing checklist completed
- No critical bugs

Demo: Complete user journey: Launch app → Create medication → Receive reminder → Mark as taken → See updated dashboard → Works offline → Syncs when online → Language/theme switching works

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
