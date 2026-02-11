# Implementation Plan: Manual Prescription and Medication Creation

## Overview

This implementation plan breaks down the Manual Prescription and Medication Creation feature into discrete coding tasks. The implementation follows a backend-first approach, establishing the API endpoints and database operations before building the mobile UI. Each task builds incrementally, with property-based tests integrated alongside implementation to catch errors early.

The plan uses:
- **Backend**: TypeScript with NestJS framework, Prisma ORM, PostgreSQL database
- **Mobile**: Dart with Flutter framework, local storage with Hive/SQLite
- **Testing**: fast-check for TypeScript property tests, custom helpers for Dart property tests

## Tasks

- [ ] 1. Backend: Extend Prescription API for Patient-Created Prescriptions
  - [ ] 1.1 Create DTOs for patient prescription creation
    - Create `CreatePatientPrescriptionDto` with prescriberName, prescriptionDate, notes
    - Create `UpdatePatientPrescriptionDto` with optional fields
    - Add validation decorators (IsNotEmpty, IsDate, MaxLength)
    - _Requirements: 1.1, 1.4, 4.1_
  
  - [ ] 1.2 Extend PrescriptionsService for patient operations
    - Add `createPatientPrescription(userId, dto)` method
    - Populate patientName, patientGender, patientAge from authenticated user
    - Set doctorId to null, status to ACTIVE, symptoms to notes
    - Add `updatePatientPrescription(userId, id, dto)` method
    - Add `deletePatientPrescription(userId, id)` method with cascade
    - _Requirements: 1.5, 12.4, 13.2_
  
  - [ ]* 1.3 Write property tests for prescription service
    - **Property 2: Prescription Creation Success**
    - **Property 19: Unique Prescription Identifiers**
    - **Property 37: Update Persistence**
    - **Property 38: Cascade Deletion**
    - **Validates: Requirements 1.5, 7.1, 12.4, 13.2**
  
  - [ ] 1.4 Add prescription controller endpoints
    - Add POST /prescriptions/patient endpoint
    - Add PATCH /prescriptions/patient/:id endpoint
    - Add DELETE /prescriptions/patient/:id endpoint
    - Apply JwtAuthGuard and RolesGuard (patient only)
    - _Requirements: 1.5, 12.4, 13.2_
  
  - [ ]* 1.5 Write property tests for authentication and authorization
    - **Property 23: Authentication Enforcement**
    - **Property 24: Authorization Enforcement**
    - **Validates: Requirements 8.3, 8.4**

- [ ] 2. Backend: Implement Medication API
  - [ ] 2.1 Create DTOs for medication operations
    - Create `CreateMedicationDto` with prescriptionId, medicationName, dosage, frequency, timing, duration, notes
    - Create `UpdateMedicationDto` with optional fields
    - Add validation decorators for required fields
    - _Requirements: 2.1, 4.1_
  
  - [ ] 2.2 Create MedicationsService
    - Implement `createMedication(userId, dto)` method
    - Validate prescription ownership before creating medication
    - Calculate rowNumber as max(rowNumber) + 1 for prescription
    - Implement `updateMedication(userId, id, dto)` method
    - Implement `deleteMedication(userId, id)` method
    - Implement `findByPrescription(userId, prescriptionId)` method
    - _Requirements: 2.1, 4.5, 12.4, 13.4_
  
  - [ ]* 2.3 Write property tests for medication service
    - **Property 10: Valid Medication Creation**
    - **Property 20: Medication Foreign Key Integrity**
    - **Property 39: Selective Medication Deletion**
    - **Validates: Requirements 4.5, 7.2, 7.3, 13.4**
  
  - [ ] 2.4 Create MedicationsController
    - Add POST /medications endpoint
    - Add GET /medications?prescriptionId=:id endpoint
    - Add PATCH /medications/:id endpoint
    - Add DELETE /medications/:id endpoint
    - Apply JwtAuthGuard and RolesGuard
    - _Requirements: 2.1, 4.5, 12.4, 13.4_
  
  - [ ]* 2.5 Write property tests for medication API
    - **Property 11: Multiple Medication Association**
    - **Property 13: Summary Edit and Delete Operations**
    - **Validates: Requirements 5.3, 5.5**

- [ ] 3. Backend: Implement Validation and Business Logic
  - [ ] 3.1 Add date validation
    - Create custom validator `IsNotFutureDate` decorator
    - Apply to prescriptionDate field in DTOs
    - Return appropriate error message
    - _Requirements: 1.4_
  
  - [ ]* 3.2 Write property test for date validation
    - **Property 1: Future Date Rejection**
    - **Validates: Requirements 1.4**
  
  - [ ] 3.3 Implement pagination for prescriptions list
    - Add query parameters: page, limit to GET /prescriptions endpoint
    - Return paginated response with total count
    - Order by createdAt DESC
    - _Requirements: 7.5, 11.1_
  
  - [ ]* 3.4 Write property tests for pagination
    - **Property 22: Pagination Correctness**
    - **Property 30: Prescription List Ordering**
    - **Validates: Requirements 7.5, 11.1**
  
  - [ ] 3.5 Implement prescription with medications retrieval
    - Modify GET /prescriptions/:id to include medications
    - Use Prisma include clause for medications relation
    - _Requirements: 7.4, 11.3_
  
  - [ ]* 3.6 Write property test for prescription retrieval
    - **Property 21: Prescription with Medications Retrieval**
    - **Validates: Requirements 7.4**

- [ ] 4. Backend: Implement Audit Logging
  - [ ] 4.1 Create audit logging interceptor
    - Create AuditInterceptor that logs all prescription/medication operations
    - Log timestamp, userId, operation type, entity type, entity ID
    - Store logs in audit_logs table or logging service
    - _Requirements: 8.5_
  
  - [ ]* 4.2 Write property test for audit logging
    - **Property 25: Audit Logging**
    - **Validates: Requirements 8.5**

- [ ] 5. Checkpoint - Backend API Complete
  - Ensure all backend tests pass
  - Test API endpoints manually with Postman/Insomnia
  - Verify authentication and authorization work correctly
  - Ask the user if questions arise

- [ ] 6. Mobile: Setup Local Storage and Data Models
  - [ ] 6.1 Define local data models
    - Create LocalPrescription model with toJson/fromJson
    - Create LocalMedication model with toJson/fromJson
    - Create SyncOperation model for offline queue
    - Add isSynced flag to track sync status
    - _Requirements: 6.2_
  
  - [ ] 6.2 Setup local database
    - Configure Hive or SQLite for local storage
    - Create boxes/tables for prescriptions, medications, sync_operations
    - Implement encryption for sensitive data
    - _Requirements: 6.2, 8.1_
  
  - [ ] 6.3 Create API client service
    - Create PrescriptionApiClient with CRUD methods
    - Create MedicationApiClient with CRUD methods
    - Configure base URL and authentication headers
    - Handle HTTP errors and timeouts
    - _Requirements: 8.2_

- [ ] 7. Mobile: Implement Prescription Provider
  - [ ] 7.1 Create PrescriptionProvider with state management
    - Use Provider or Riverpod for state management
    - Implement createPrescription method (stores locally, queues sync)
    - Implement updatePrescription method
    - Implement deletePrescription method
    - Implement getPrescriptions method (from local DB)
    - _Requirements: 1.5, 12.4, 13.2_
  
  - [ ]* 7.2 Write property tests for prescription provider
    - **Property 14: Offline Creation Capability**
    - **Property 15: Offline Local Storage**
    - **Validates: Requirements 6.1, 6.2**

- [ ] 8. Mobile: Implement Medication Provider
  - [ ] 8.1 Create MedicationProvider with state management
    - Implement createMedication method (stores locally, queues sync)
    - Implement updateMedication method
    - Implement deleteMedication method
    - Implement getMedicationsByPrescription method
    - _Requirements: 4.5, 12.4, 13.4_
  
  - [ ]* 8.2 Write property tests for medication provider
    - **Property 10: Valid Medication Creation**
    - **Property 11: Multiple Medication Association**
    - **Validates: Requirements 4.5, 5.3**

- [ ] 9. Mobile: Implement Sync Service
  - [ ] 9.1 Create SyncService for offline/online synchronization
    - Detect network connectivity using connectivity_plus package
    - Implement queueOperation method to add operations to queue
    - Implement syncAll method to process queue when online
    - Implement exponential backoff retry logic
    - Handle sync conflicts (prefer local changes)
    - _Requirements: 6.3, 6.4, 6.5_
  
  - [ ]* 9.2 Write property tests for sync service
    - **Property 16: Online Sync Trigger**
    - **Property 17: Local-First Conflict Resolution**
    - **Property 18: Exponential Backoff Retry**
    - **Validates: Requirements 6.3, 6.4, 6.5**

- [ ] 10. Mobile: Implement Validation Service
  - [ ] 10.1 Create ValidationService for client-side validation
    - Implement validatePrescriberName (non-empty, max 200 chars)
    - Implement validatePrescriptionDate (not in future)
    - Implement validateMedicationName (non-empty, max 255 chars)
    - Implement validateDosage (non-empty, max 100 chars)
    - Implement validateFrequency (non-empty, max 100 chars)
    - Return ValidationResult with isValid and error message
    - _Requirements: 1.4, 4.1_
  
  - [ ]* 10.2 Write property tests for validation
    - **Property 1: Future Date Rejection**
    - **Property 8: Required Field Validation**
    - **Validates: Requirements 1.4, 4.1, 4.3, 4.4**

- [ ] 11. Mobile: Implement Prescription Form Screen
  - [ ] 11.1 Create PrescriptionFormScreen widget
    - Add TextFormField for prescriber name with validation
    - Add DatePicker for prescription date with validation
    - Add TextFormField for notes (optional)
    - Display validation errors inline
    - Handle form submission with loading state
    - _Requirements: 1.1, 1.3, 4.2_
  
  - [ ] 11.2 Implement form submission logic
    - Validate all fields on submit
    - Call PrescriptionProvider.createPrescription
    - Navigate to medication form on success
    - Show error toast on failure
    - _Requirements: 1.5, 4.3, 4.4_
  
  - [ ]* 11.3 Write widget tests for prescription form
    - Test form displays all required fields
    - Test validation errors display correctly
    - Test successful submission navigates to medication form
    - _Requirements: 1.1, 4.2_

- [ ] 12. Mobile: Implement Medication Form Screen
  - [ ] 12.1 Create MedicationFormScreen widget
    - Add TextFormField for medication name with auto-complete
    - Add TextFormField for dosage with validation
    - Add dropdown/TextFormField for frequency
    - Add TextFormField for timing (optional)
    - Add TextFormField for duration (optional)
    - Add TextFormField for notes (optional)
    - Display validation errors inline
    - _Requirements: 2.1, 2.3, 2.4, 2.5, 4.2_
  
  - [ ] 12.2 Implement auto-complete for medication names
    - Load medication database from local storage or assets
    - Filter medications based on input text
    - Support both Khmer and English search
    - Display suggestions in dropdown
    - _Requirements: 2.3, 3.3_
  
  - [ ]* 12.3 Write property tests for auto-complete
    - **Property 4: Auto-Complete Matching**
    - **Validates: Requirements 1.2, 2.3, 3.3**
  
  - [ ] 12.4 Implement form submission logic
    - Validate all required fields on submit
    - Call MedicationProvider.createMedication
    - Show "Add Another" and "Done" buttons on success
    - Navigate to summary on "Done"
    - Clear form and stay on screen for "Add Another"
    - _Requirements: 4.5, 5.1, 5.2_
  
  - [ ]* 12.5 Write widget tests for medication form
    - Test form displays all required fields
    - Test validation errors display correctly
    - Test "Add Another" clears form
    - Test "Done" navigates to summary
    - _Requirements: 2.1, 4.2, 5.1, 5.2_

- [ ] 13. Mobile: Implement Bilingual Input Support
  - [ ] 13.1 Add bilingual input handling
    - Configure TextFormField to accept Unicode characters
    - Test Khmer character input (U+1780 to U+17FF)
    - Test English ASCII input
    - Ensure no character filtering or rejection
    - _Requirements: 2.2, 3.2_
  
  - [ ]* 13.2 Write property tests for bilingual input
    - **Property 3: Bilingual Input Acceptance**
    - **Property 7: Language Round-Trip Integrity**
    - **Validates: Requirements 2.2, 3.2, 3.4, 3.5**

- [ ] 14. Mobile: Implement Prescription List Screen
  - [ ] 14.1 Create PrescriptionListScreen widget
    - Display list of prescriptions from local database
    - Show prescriber name, date, medication count for each
    - Order by date descending (most recent first)
    - Implement pull-to-refresh to trigger sync
    - _Requirements: 11.1, 11.2_
  
  - [ ] 14.2 Implement prescription list item tap
    - Navigate to prescription detail screen on tap
    - Pass prescription ID to detail screen
    - _Requirements: 11.3_
  
  - [ ]* 14.3 Write property tests for prescription list
    - **Property 30: Prescription List Ordering**
    - **Property 31: Prescription List Item Content**
    - **Validates: Requirements 11.1, 11.2**

- [ ] 15. Mobile: Implement Prescription Detail Screen
  - [ ] 15.1 Create PrescriptionDetailScreen widget
    - Display prescription details (prescriber, date, notes)
    - Display list of all medications for prescription
    - Show medication name, dosage, frequency, timing for each
    - Add edit and delete buttons for prescription
    - Add edit and delete buttons for each medication
    - _Requirements: 11.3, 11.4, 12.1, 12.2, 13.1, 13.3_
  
  - [ ] 15.2 Implement edit functionality
    - Navigate to PrescriptionFormScreen with existing data on edit
    - Navigate to MedicationFormScreen with existing data on edit
    - Pre-populate form fields with current values
    - _Requirements: 12.1, 12.2_
  
  - [ ]* 15.3 Write property tests for edit functionality
    - **Property 35: Edit Form Pre-Population**
    - **Property 36: Edit Validation Consistency**
    - **Validates: Requirements 12.1, 12.2, 12.3**
  
  - [ ] 15.4 Implement delete functionality
    - Show confirmation dialog on delete
    - Call provider delete method on confirm
    - Navigate back to list on successful deletion
    - _Requirements: 13.1, 13.2, 13.3, 13.4_
  
  - [ ]* 15.5 Write property tests for delete functionality
    - **Property 38: Cascade Deletion**
    - **Property 39: Selective Medication Deletion**
    - **Validates: Requirements 13.2, 13.4**

- [ ] 16. Mobile: Implement Search and Filter
  - [ ] 16.1 Add search functionality to prescription list
    - Add search bar to PrescriptionListScreen
    - Filter prescriptions by prescriber name or notes
    - Filter medications by medication name
    - Update list in real-time as user types
    - _Requirements: 11.5_
  
  - [ ]* 16.2 Write property tests for search
    - **Property 34: Search Result Accuracy**
    - **Validates: Requirements 11.5**

- [ ] 17. Mobile: Implement Localization (i18n)
  - [ ] 17.1 Setup localization infrastructure
    - Add flutter_localizations dependency
    - Create localization files for Khmer and English
    - Define all UI strings in both languages
    - Configure MaterialApp with localizationsDelegates
    - _Requirements: 3.1, 9.1_
  
  - [ ] 17.2 Create language selector
    - Add language selector to settings screen
    - Store language preference in local storage
    - Update app locale on language change
    - _Requirements: 9.2, 9.3, 9.4_
  
  - [ ]* 17.3 Write property tests for localization
    - **Property 26: Preference Persistence**
    - **Property 27: UI Language Reactivity**
    - **Property 9: Localized Error Messages**
    - **Validates: Requirements 9.1, 9.3, 9.4, 4.2**

- [ ] 18. Mobile: Implement Theme Support
  - [ ] 18.1 Create theme configuration
    - Define light theme with colors and styles
    - Define dark theme with colors and styles
    - Configure MaterialApp with theme and darkTheme
    - _Requirements: 10.1_
  
  - [ ] 18.2 Create theme selector
    - Add theme selector to settings screen (Light, Dark, System)
    - Store theme preference in local storage
    - Update app theme on selection
    - Listen to system theme changes for "System Default"
    - _Requirements: 10.2, 10.3, 10.4, 10.5_
  
  - [ ]* 18.3 Write property tests for theme support
    - **Property 28: UI Theme Reactivity**
    - **Property 29: System Theme Synchronization**
    - **Validates: Requirements 10.3, 10.5**

- [ ] 19. Mobile: Implement Error Handling and User Feedback
  - [ ] 19.1 Add error handling to all API calls
    - Catch network errors and show offline message
    - Catch authentication errors and redirect to login
    - Catch validation errors and display inline
    - Catch server errors and show retry option
    - _Requirements: 8.2, 8.3_
  
  - [ ] 19.2 Add loading indicators
    - Show loading spinner during API calls
    - Disable form buttons during submission
    - Show sync status indicator in app bar
    - _Requirements: 6.3_
  
  - [ ] 19.3 Add success feedback
    - Show toast message on successful creation
    - Show toast message on successful update
    - Show toast message on successful deletion
    - Show toast message on successful sync
    - _Requirements: 1.5, 4.5, 12.4, 13.2, 13.4_

- [ ] 20. Integration Testing and Bug Fixes
  - [ ] 20.1 Test complete prescription creation flow
    - Test creating prescription with single medication
    - Test creating prescription with multiple medications
    - Test offline creation and online sync
    - Test edit and delete operations
    - _Requirements: All_
  
  - [ ] 20.2 Test bilingual functionality
    - Test Khmer input and display
    - Test English input and display
    - Test language switching
    - Test mixed Khmer/English input
    - _Requirements: 2.2, 3.1, 3.2, 3.3, 9.1-9.5_
  
  - [ ] 20.3 Test theme switching
    - Test light mode appearance
    - Test dark mode appearance
    - Test system default mode
    - Test theme persistence
    - _Requirements: 10.1-10.5_
  
  - [ ] 20.4 Fix any bugs discovered during testing
    - Address validation issues
    - Fix sync conflicts
    - Resolve UI rendering issues
    - Fix localization gaps

- [ ] 21. Final Checkpoint - Feature Complete
  - Ensure all tests pass (unit, property, widget, integration)
  - Verify all requirements are implemented
  - Test on both Android and iOS devices
  - Test with real Khmer prescriptions
  - Ask the user if questions arise

## Notes

- Tasks marked with `*` are optional property-based tests that can be skipped for faster MVP
- Each task references specific requirements for traceability
- Backend tasks (1-5) should be completed before mobile tasks (6-21)
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end workflows
- The implementation uses existing Prisma models with minimal schema changes
- Offline-first architecture ensures the app works without internet connection




skip