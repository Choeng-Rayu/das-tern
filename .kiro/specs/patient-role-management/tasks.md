# Implementation Plan: Patient Role Management

## Overview

This implementation plan breaks down the patient-role-management feature into discrete, actionable tasks. The feature provides comprehensive medication management for patients including prescription management, dose tracking, adherence monitoring, connections with doctors and family members, and subscription management. The implementation follows an offline-first architecture with seamless integration to existing reminder-system, family-connection, and doctor-dashboard specifications.

## Tasks

- [ ] 1. Backend - Prescription Service Implementation
  - [ ] 1.1 Implement PrescriptionService with CRUD operations
    - Create createPrescription() method for patient-created prescriptions
    - Create getPrescriptions() with filtering by status, date range, pagination
    - Create getPrescriptionById() with medicine details and adherence
    - Create updatePrescription() with ownership validation
    - Create deletePrescription() with cascade delete
    - Create confirmPrescription() for doctor prescriptions (PENDING → ACTIVE)
    - Create rejectPrescription() for doctor prescriptions
    - Create pausePrescription() and resumePrescription() methods
    - _Requirements: 1.1, 1.3, 1.4, 1.5, 1.6, 3.1, 3.5, 3.6, 3.7, 4.1, 4.2, 4.3_
  
  - [ ]* 1.2 Write property test for prescription creation validation
    - **Property 1: Prescription Creation Validation**
    - **Validates: Requirements 1.1**
  
  - [ ]* 1.3 Write property test for prescription status and ownership
    - **Property 2: Patient-Created Prescription Status**
    - **Property 3: Prescription Ownership**
    - **Validates: Requirements 1.3, 1.4**
  
  - [ ]* 1.4 Write property test for prescription audit logging
    - **Property 5: Prescription Audit Logging**
    - **Validates: Requirements 1.6**

- [ ] 2. Backend - Medicine Service Implementation
  - [ ] 2.1 Implement MedicineService with CRUD operations
    - Create addMedicine() method with validation
    - Create getMedicines() for prescription
    - Create getMedicineById() with dose event details
    - Create updateMedicine() with edit precondition check
    - Create deleteMedicine() with cascade delete
    - Create getArchivedMedicines() method
    - Create canEditMedicine() helper to check if doses taken
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2_
  
  - [ ]* 2.2 Write property test for medicine creation validation
    - **Property 7: Medicine Creation Validation**
    - **Validates: Requirements 2.1**
  
  - [ ]* 2.3 Write property test for medicine edit preconditions
    - **Property 12: Medicine Edit Precondition Check**
    - **Property 13: Medicine Edit Permission**
    - **Validates: Requirements 5.1, 5.2, 5.3**

- [ ] 3. Backend - Dose Service Implementation
  - [ ] 3.1 Implement DoseService for dose event management
    - Create generateDoseEvents() based on medicine schedule
    - Create regenerateDoseEvents() for schedule updates
    - Create getTodaysDoses() with filtering
    - Create getUpcomingDose() method
    - Create getDoseHistory() with pagination
    - Create markDoseAsTaken() with timing classification
    - Create skipDose() with reason recording
    - Create syncOfflineDoses() with conflict resolution
    - _Requirements: 2.7, 2.8, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 11.1, 11.2, 22.1, 22.2, 22.3_
  
  - [ ]* 3.2 Write property test for dose event generation
    - **Property 8: Dose Event Generation Completeness**
    - **Validates: Requirements 2.7**
  
  - [ ]* 3.3 Write property test for dose timing classification
    - **Property 16: Dose Timing Classification**
    - **Validates: Requirements 10.1, 10.2, 10.7**
  
  - [ ]* 3.4 Write property test for offline sync validation
    - **Property 31: Offline Sync Validation**
    - **Property 32: Sync Conflict Resolution**
    - **Validates: Requirements 22.2, 22.3**

- [ ] 4. Backend - Integration with Reminder System
  - [ ] 4.1 Integrate with ReminderGeneratorService
    - Call generateRemindersForPrescription() when prescription confirmed
    - Call regenerateRemindersForMedication() when medicine updated
    - Call deleteRemindersForPrescription() when prescription deleted
    - Handle reminder generation failures gracefully
    - _Requirements: 2.8, 46.1, 46.2, 46.3_
  
  - [ ] 4.2 Integrate with AdherenceCalculatorService
    - Call calculateAdherence() for adherence queries
    - Call invalidateCache() after dose event creation
    - Use cached results when available
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 10.5, 10.6_
  
  - [ ]* 4.3 Write property test for reminder generation trigger
    - **Property 9: Reminder Generation Trigger**
    - **Property 41: Reminder System Integration Completeness**
    - **Validates: Requirements 2.8, 46.1, 46.2, 46.3**
  
  - [ ]* 4.4 Write property test for adherence calculation
    - **Property 15: Adherence Calculation Formula**
    - **Validates: Requirements 8.1, 8.2, 8.3, 8.4**

- [ ] 5. Backend - Connection Service Extension
  - [ ] 5.1 Extend ConnectionService for patient role
    - Implement searchDoctors() with filters
    - Implement getDoctorConnections() method
    - Implement getFamilyConnections() method
    - Implement getConnectionHistory() from audit logs
    - Implement validateCaregiverLimit() based on subscription
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 15.1, 15.2, 15.3, 17.10_
  
  - [ ]* 5.2 Write property test for doctor search correctness
    - **Property 23: Doctor Search Correctness**
    - **Validates: Requirements 14.1, 14.2**
  
  - [ ]* 5.3 Write property test for connection state transitions
    - **Property 25: Connection State Transitions**
    - **Validates: Requirements 15.5, 15.6, 15.7**

- [ ] 6. Backend - Subscription Service Extension
  - [ ] 6.1 Extend SubscriptionService for limit enforcement
    - Implement checkPrescriptionLimit() method
    - Implement checkMedicineLimit() method
    - Implement checkFamilyConnectionLimit() method
    - Implement checkStorageLimit() method
    - Implement getCurrentLimits() with usage counts
    - Define tier limits: FREEMIUM (1 prescription, 3 medicines, 1 family), PREMIUM (unlimited, 5 family), FAMILY_PREMIUM (unlimited, 10 family)
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7, 19.8_
  
  - [ ]* 6.2 Write property test for subscription limit enforcement
    - **Property 28: Subscription Limit Enforcement**
    - **Validates: Requirements 19.1, 19.2, 19.3, 19.7**

- [ ] 7. Backend - API Route Handlers
  - [ ] 7.1 Implement prescription API routes
    - POST /api/prescriptions - Create prescription
    - GET /api/prescriptions - List with filters
    - GET /api/prescriptions/:id - Get details
    - PATCH /api/prescriptions/:id - Update
    - DELETE /api/prescriptions/:id - Delete
    - POST /api/prescriptions/:id/confirm - Confirm
    - POST /api/prescriptions/:id/reject - Reject
    - POST /api/prescriptions/:id/pause - Pause
    - POST /api/prescriptions/:id/resume - Resume
    - _Requirements: 33.1, 33.2, 33.3, 33.4, 33.5, 33.6, 33.7, 33.8, 33.9_
  
  - [ ] 7.2 Implement medicine API routes
    - POST /api/prescriptions/:prescriptionId/medicines - Add medicine
    - GET /api/prescriptions/:prescriptionId/medicines - List medicines
    - GET /api/medicines/:id - Get details
    - PATCH /api/medicines/:id - Update
    - DELETE /api/medicines/:id - Delete
    - GET /api/medicines/archived - List archived
    - _Requirements: 34.1, 34.2, 34.3, 34.4, 34.5, 34.7_
  
  - [ ] 7.3 Implement dose event API routes
    - POST /api/doses/:id/taken - Mark as taken
    - POST /api/doses/:id/skip - Skip dose
    - GET /api/doses/today - Today's doses
    - GET /api/doses/upcoming - Next dose
    - GET /api/doses/history - Dose history
    - POST /api/doses/sync - Sync offline doses
    - _Requirements: 35.1, 35.2, 35.3, 35.4, 35.5, 35.6_
  
  - [ ] 7.4 Implement connection API routes
    - POST /api/connections/request - Send request
    - POST /api/connections/:id/accept - Accept
    - POST /api/connections/:id/reject - Reject
    - POST /api/connections/:id/revoke - Revoke
    - PATCH /api/connections/:id/permission - Update permission
    - GET /api/connections/doctors - List doctors
    - GET /api/connections/family - List family
    - GET /api/doctors/search - Search doctors
    - _Requirements: 37.1, 37.4, 37.5, 37.6, 37.7, 37.8, 37.9, 37.10_
  
  - [ ] 7.5 Implement subscription API routes
    - GET /api/subscription - Get details
    - GET /api/subscription/limits - Get limits and usage
    - POST /api/subscription/upgrade - Upgrade tier
    - POST /api/subscription/downgrade - Downgrade tier
    - _Requirements: 40.1, 40.2, 40.3, 40.4_

- [ ] 8. Backend - Validation Schemas
  - [ ] 8.1 Create Zod validation schemas
    - Create prescriptionCreateSchema
    - Create medicineCreateSchema
    - Create doseMarkTakenSchema
    - Create doseSkipSchema
    - Create syncDosesSchema
    - Create connectionRequestSchema
    - Validate dates, dosages, enums, UUIDs
    - _Requirements: 1.1, 1.7, 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [ ]* 8.2 Write unit tests for validation schemas
    - Test required field validation
    - Test date format validation
    - Test enum validation
    - Test boundary conditions

- [ ] 9. Checkpoint - Backend Core Complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Mobile - State Management Setup
  - [ ] 10.1 Create Riverpod providers
    - Create prescriptionProvider for prescription state
    - Create doseProvider for dose events
    - Create adherenceProvider for adherence data
    - Create syncStateProvider for sync status
    - Create connectionProvider for connections
    - Create subscriptionProvider for subscription data
    - _Requirements: 49.1, 49.2, 49.3, 49.4_
  
  - [ ] 10.2 Create state notifier classes
    - Create PrescriptionNotifier with CRUD methods
    - Create DoseNotifier with marking methods
    - Create SyncNotifier with sync logic
    - Create ConnectionNotifier with connection management
    - Handle loading, error, and success states

- [ ] 11. Mobile - Local Database Setup
  - [ ] 11.1 Create SQLite database schema
    - Create prescriptions table
    - Create medicines table
    - Create dose_events table
    - Create sync_queue table
    - Create local_reminders table
    - Add indexes for performance
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5_
  
  - [ ] 11.2 Create database helper classes
    - Create PrescriptionDao for prescription operations
    - Create MedicineDao for medicine operations
    - Create DoseEventDao for dose event operations
    - Create SyncQueueDao for sync queue operations
    - Implement CRUD methods for each DAO

- [ ] 12. Mobile - Repository Pattern Implementation
  - [ ] 12.1 Create repository interfaces
    - Create PrescriptionRepository interface
    - Create MedicineRepository interface
    - Create DoseRepository interface
    - Create ConnectionRepository interface
    - Create SubscriptionRepository interface
  
  - [ ] 12.2 Implement repositories with offline-first logic
    - Implement PrescriptionRepositoryImpl
    - Implement MedicineRepositoryImpl
    - Implement DoseRepositoryImpl
    - Check connectivity before API calls
    - Fall back to local database when offline
    - Queue operations for sync when offline
    - _Requirements: 20.1, 20.2, 20.6, 20.7_
  
  - [ ]* 12.3 Write unit tests for repository offline logic
    - Test online mode behavior
    - Test offline mode behavior
    - Test sync queue creation

- [ ] 13. Mobile - Offline Sync Engine
  - [ ] 13.1 Implement OfflineSyncEngine
    - Monitor connectivity using connectivity_plus
    - Auto-sync when connectivity restored
    - Process sync queue in chronological order
    - Implement retry logic with exponential backoff
    - Handle sync conflicts
    - Batch operations for efficiency
    - _Requirements: 22.1, 22.2, 22.3, 22.4, 22.5, 22.6, 22.7, 22.8, 22.9_
  
  - [ ]* 13.2 Write property test for offline data queueing
    - **Property 29: Offline Data Queueing**
    - **Validates: Requirements 20.1, 20.2, 20.6**
  
  - [ ]* 13.3 Write unit tests for sync conflict resolution
    - Test earliest timestamp wins
    - Test server state priority
    - Test sync result reporting

- [ ] 14. Mobile - Local Notification Service
  - [ ] 14.1 Implement LocalNotificationService
    - Use flutter_local_notifications package
    - Schedule notifications using exact alarm
    - Store up to 100 pending reminders locally
    - Sync with server every hour when online
    - Handle notification actions: Mark Taken, Snooze, Dismiss
    - Use notification channels for different types
    - _Requirements: 21.1, 21.2, 21.3, 21.4, 21.5, 21.6_
  
  - [ ]* 14.2 Write property test for offline reminder delivery
    - **Property 30: Offline Reminder Delivery**
    - **Validates: Requirements 21.1, 21.2**

- [ ] 15. Mobile - Patient Dashboard Screen
  - [ ] 15.1 Create PatientDashboardScreen widget
    - Display today's medicines grouped by time period
    - Show next upcoming dose prominently
    - Display daily adherence percentage with progress indicator
    - Show alerts for pending prescriptions, missed doses
    - Implement pull-to-refresh
    - Display offline indicator when not connected
    - Add floating action button for quick dose marking
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 9.1, 9.2, 9.3, 9.4, 9.5_
  
  - [ ] 15.2 Create DoseCard widget
    - Display medicine name, dosage, scheduled time
    - Show status indicator with color coding
    - Add quick action buttons: Mark as Taken, Skip
    - Handle tap to show details
    - _Requirements: 7.3, 7.4_
  
  - [ ] 15.3 Create AdherenceWidget
    - Display percentage with color indicator
    - Show progress bar
    - Display doses taken/total
    - Tap to navigate to detailed adherence view
    - _Requirements: 7.7, 8.1, 8.2, 8.3, 8.4_

- [ ] 16. Mobile - Prescription Management Screens
  - [ ] 16.1 Create PrescriptionListScreen
    - Display tabs: Active, Pending, Paused, Completed
    - Show prescription cards with title, doctor, dates, adherence
    - Implement search by title or doctor name
    - Support swipe actions: view, pause/resume, delete
    - Display badge count on Pending tab
    - Show empty state when no prescriptions
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 32.1_
  
  - [ ] 16.2 Create PrescriptionDetailScreen
    - Display sections: Overview, Medicines, Schedule, History
    - Show prescription details with adherence
    - List all medicines with dosage and schedule
    - Display calendar view of scheduled doses
    - Show dose event history
    - Add edit button for patient-created prescriptions
    - Add pause/resume button
    - _Requirements: 4.4, 4.5, 4.6, 4.7_
  
  - [ ] 16.3 Create PrescriptionFormScreen
    - Create form with sections: Basic Info, Medicines
    - Add fields: title, doctor name, dates, diagnosis, notes
    - Implement medicine list with add/remove
    - Validate required fields
    - Show inline error messages
    - Support both Khmer and English input
    - _Requirements: 1.1, 1.2, 1.7_

- [ ] 17. Mobile - Medicine Management Screens
  - [ ] 17.1 Create MedicineFormScreen
    - Create form with sections: Basic Info, Dosage, Schedule, Duration
    - Add fields: name, form, dosage, frequency, schedule times
    - Implement time pickers for schedule
    - Add PRN toggle
    - Validate all required fields
    - Show inline error messages
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_
  
  - [ ] 17.2 Create MedicineDetailScreen
    - Display medicine details
    - Show schedule and dose history
    - Add edit button (only if no doses taken)
    - Add delete button with confirmation
    - _Requirements: 5.1, 5.2, 5.3, 5.7_

- [ ] 18. Mobile - Adherence Screens
  - [ ] 18.1 Create AdherenceScreen
    - Display tabs: Today, Week, Month
    - Show percentage with color indicator
    - Display line graph for weekly trend
    - Display bar graph for monthly trend
    - Show motivational messages based on adherence
    - Display streak counter
    - Allow filtering by prescription
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 19. Mobile - Connection Management Screens
  - [ ] 19.1 Create ConnectionsScreen
    - Display tabs: Doctors, Family
    - Show connection cards with name, role, status
    - Display pending requests with accept/reject buttons
    - Support search by name
    - Add floating action button to add connection
    - Show empty state with call-to-action
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 32.3, 32.4_
  
  - [ ] 19.2 Create DoctorSearchScreen
    - Implement search bar
    - Display search results with doctor details
    - Show verification status
    - Add "Send Request" button
    - _Requirements: 14.1, 14.2, 14.3_
  
  - [ ] 19.3 Integrate family connection screens from family-connection spec
    - Reuse FamilyConnectIntroScreen
    - Reuse TokenDisplayScreen
    - Reuse CaregiverOnboardingScreen
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 16.7, 16.8, 16.9_

- [ ] 20. Mobile - Settings and Profile Screens
  - [ ] 20.1 Create SettingsScreen
    - Display sections: Profile, Preferences, Notifications, Subscription, Privacy
    - Allow editing profile fields
    - Add language toggle (Khmer/English)
    - Add theme toggle (Light/Dark)
    - Configure meal time preferences
    - Configure grace period
    - Display subscription tier and limits
    - Add upgrade button
    - _Requirements: 23.1, 23.2, 23.3, 23.4, 23.5, 23.6, 23.9, 24.1, 24.2_
  
  - [ ] 20.2 Create SubscriptionScreen
    - Display current tier with limits
    - Show usage progress bars
    - Display feature comparison table
    - Add upgrade/downgrade buttons
    - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5, 18.6, 18.7_

- [ ] 21. Mobile - Notification Handling
  - [ ] 21.1 Implement FCM notification handling
    - Initialize FCM on app launch
    - Register device token with backend
    - Handle foreground messages
    - Handle background messages
    - Handle notification taps with deep linking
    - Display local notification when app is in foreground
    - Update badge count
    - _Requirements: 56.1, 56.2, 56.3, 56.4, 56.5, 56.6, 56.7_
  
  - [ ] 21.2 Implement notification action handlers
    - Handle "Mark as Taken" action
    - Handle "Snooze" action
    - Handle "Skip" action
    - Navigate to appropriate screen on tap
    - _Requirements: 56.3, 56.7_

- [ ] 22. Mobile - Error Handling and UI Polish
  - [ ] 22.1 Implement error handling
    - Display user-friendly error messages
    - Show retry buttons for network errors
    - Display offline indicator
    - Show sync status
    - Translate error messages to user's language
    - _Requirements: 59.1, 59.2, 59.3, 59.4, 59.5, 59.6, 59.7, 59.8_
  
  - [ ] 22.2 Implement confirmation dialogs
    - Add confirmation for delete prescription
    - Add confirmation for delete medicine
    - Add confirmation for revoke doctor connection
    - Add confirmation for revoke family connection
    - Add confirmation for pause prescription
    - Use destructive button styling for delete actions
    - _Requirements: 30.1, 30.2, 30.3, 30.4, 30.5, 30.6, 30.7_
  
  - [ ] 22.3 Implement empty states
    - Add empty state for no prescriptions
    - Add empty state for no medicines today
    - Add empty state for no doctor connections
    - Add empty state for no family connections
    - Add empty state for no notifications
    - Include helpful illustrations and action buttons
    - _Requirements: 32.1, 32.2, 32.3, 32.4, 32.5, 32.6, 32.7_

- [ ] 23. Mobile - Accessibility Implementation
  - [ ] 23.1 Implement accessibility features
    - Add semantic labels for screen readers
    - Ensure minimum touch target sizes (44x44)
    - Support dynamic text sizing
    - Ensure sufficient color contrast (WCAG AA)
    - Support both light and dark themes
    - Add alternative text for images
    - Support keyboard navigation
    - Announce state changes to screen readers
    - _Requirements: 58.1, 58.2, 58.3, 58.4, 58.5, 58.6, 58.7, 58.8_

- [ ] 24. Checkpoint - Mobile Core Complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 25. Integration Testing
  - [ ]* 25.1 Write integration tests for prescription workflow
    - Test manual prescription creation flow
    - Test doctor prescription confirmation flow
    - Test prescription editing and deletion
    - Test prescription pause and resume
  
  - [ ]* 25.2 Write integration tests for dose tracking workflow
    - Test marking dose as taken (on-time and late)
    - Test skipping dose with reason
    - Test offline dose recording and sync
    - Test adherence calculation after dose events
  
  - [ ]* 25.3 Write integration tests for connection workflow
    - Test doctor search and connection request
    - Test family connection with token
    - Test connection approval and rejection
    - Test connection revocation
  
  - [ ]* 25.4 Write integration tests for offline sync
    - Test offline prescription creation and sync
    - Test offline dose marking and sync
    - Test sync conflict resolution
    - Test sync retry logic

- [ ] 26. End-to-End Testing
  - [ ]* 26.1 Write E2E test for complete prescription flow
    - Create prescription with medicines
    - View prescription on dashboard
    - Mark doses as taken
    - View adherence
  
  - [ ]* 26.2 Write E2E test for doctor prescription flow
    - Doctor creates prescription
    - Patient receives notification
    - Patient confirms prescription
    - Reminders are generated
    - Patient marks doses
  
  - [ ]* 26.3 Write E2E test for offline mode
    - Go offline
    - Create prescription
    - Mark doses
    - Go online
    - Verify sync completes

- [ ] 27. Final Checkpoint - All Tests Pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Integration tests validate component interactions
- E2E tests validate complete user workflows
- Backend uses TypeScript with NestJS
- Mobile uses Dart with Flutter
- Offline-first architecture is critical for reliability
- Integration with existing specs (reminder-system, family-connection, doctor-dashboard) is essential
