# Implementation Plan: Family Connection + Missed Dose Alert

## Overview

This implementation plan covers the missing features for the Family Connection + Missed Dose Alert system. The plan builds upon the existing Connection model, notification infrastructure, and mobile app architecture. Tasks are organized to deliver features incrementally, with testing integrated throughout.

**Implementation Order:**
1. Backend foundation (token service, database migrations)
2. Mobile app QR/token flow
3. Grace period and missed dose detection
4. Caregiver alerts and nudge functionality
5. UI enhancements and polish

## Tasks

- [ ] 1. Backend: Connection Token Service and Database Setup
  - Create `connection_tokens` table migration
  - Implement ConnectionTokenService with generate, validate, consume methods
  - Add token cleanup scheduled job
  - Create API endpoints for token operations
  - _Requirements: 1.1, 1.2, 1.3, 1.6, 1.7_

  - [ ]* 1.1 Write property test for token generation uniqueness
    - **Property 1: Token Generation Uniqueness and Expiration**
    - **Validates: Requirements 1.1, 1.5**

  - [ ]* 1.2 Write property test for token structure completeness
    - **Property 2: Token Structure Completeness**
    - **Validates: Requirements 1.2, 1.7**

  - [ ]* 1.3 Write property test for token single-use enforcement
    - **Property 3: Token Single-Use Enforcement**
    - **Validates: Requirements 1.3, 1.6, 19.2**

  - [ ]* 1.4 Write property test for token expiration enforcement
    - **Property 4: Token Expiration Enforcement**
    - **Validates: Requirements 1.6, 19.1**

- [ ] 2. Backend: Grace Period and Missed Dose Detection
  - Add `grace_period_minutes` column to users table
  - Implement MissedDoseJob scheduled job (runs every 5 minutes)
  - Add logic to mark DUE doses as MISSED after grace period
  - Create patient notifications for missed doses
  - Add API endpoint for grace period configuration
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.6_

  - [ ]* 2.1 Write property test for grace period missed dose detection
    - **Property 10: Grace Period Missed Dose Detection**
    - **Validates: Requirements 10.3**

  - [ ]* 2.2 Write property test for patient missed dose notification
    - **Property 12: Patient Missed Dose Notification**
    - **Validates: Requirements 11.1**

  - [ ]* 2.3 Write unit tests for grace period edge cases
    - Test doses exactly at grace period boundary
    - Test doses within grace period
    - Test doses far past grace period
    - _Requirements: 10.3_

- [ ] 3. Backend: Caregiver Alert System
  - Extend ConnectionsService with caregiver query methods
  - Implement alert broadcasting to enabled caregivers
  - Add metadata field to connections table for alertsEnabled flag
  - Create MISSED_DOSE_ALERT notifications for caregivers
  - Add API endpoint to toggle alerts per connection
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.6, 12.7_

  - [ ]* 3.1 Write property test for caregiver alert broadcasting
    - **Property 15: Caregiver Alert Broadcasting**
    - **Validates: Requirements 12.1, 12.2, 12.6, 14.4**

  - [ ]* 3.2 Write property test for alert respect for disabled preferences
    - **Property 16: Alert Respect for Disabled Preferences**
    - **Validates: Requirements 12.6**

  - [ ]* 3.3 Write property test for missed dose notification format
    - **Property 13: Missed Dose Notification Format**
    - **Validates: Requirements 11.2, 12.3, 12.4**

- [ ] 4. Backend: Nudge Service and Rate Limiting
  - Create NudgeService with sendNudge and checkRateLimit methods
  - Store nudge counts in connection metadata JSON
  - Implement rate limiting (max 2 nudges per dose per caregiver)
  - Create FAMILY_ALERT notifications for patients
  - Create response notifications for caregivers
  - Add API endpoints for nudge operations
  - _Requirements: 13.1, 13.2, 13.3, 13.5, 13.7, 13.8_

  - [ ]* 4.1 Write property test for nudge notification creation
    - **Property 17: Nudge Notification Creation**
    - **Validates: Requirements 13.2, 13.3**

  - [ ]* 4.2 Write property test for bidirectional nudge response
    - **Property 18: Bidirectional Nudge Response**
    - **Validates: Requirements 13.5**

  - [ ]* 4.3 Write property test for nudge rate limiting
    - **Property 19: Nudge Rate Limiting**
    - **Validates: Requirements 13.7**

- [ ] 5. Backend: Subscription Limits and Connection Management
  - Implement caregiver limit enforcement based on SubscriptionTier
  - Add getCaregiverLimit method to ConnectionsService
  - Add validation before creating new connections
  - Extend connection history API with filtering
  - _Requirements: 14.1, 14.2, 14.4, 15.2, 15.4_

  - [ ]* 5.1 Write property test for subscription tier caregiver limits
    - **Property 20: Subscription Tier Caregiver Limits**
    - **Validates: Requirements 14.1**

  - [ ]* 5.2 Write property test for connection history filtering
    - **Property 21: Connection History Filtering**
    - **Validates: Requirements 15.2, 15.4**

- [ ] 6. Backend: Audit Logging and Self-Connection Prevention
  - Enhance audit logging for all connection and nudge events
  - Add self-connection validation in token consumption
  - Add comprehensive error handling for all edge cases
  - _Requirements: 10.4, 12.7, 13.8, 19.4_

  - [ ]* 6.1 Write property test for comprehensive audit logging
    - **Property 11: Comprehensive Audit Logging**
    - **Validates: Requirements 10.4, 12.7, 13.8**

  - [ ]* 6.2 Write property test for self-connection prevention
    - **Property 24: Self-Connection Prevention**
    - **Validates: Requirements 19.4**

- [ ] 7. Checkpoint - Backend APIs Complete
  - Ensure all backend tests pass
  - Verify API endpoints with Postman/Thunder Client
  - Check database migrations applied correctly
  - Confirm scheduled jobs are running
  - Ask the user if questions arise

- [ ] 8. Mobile: QR Code Generation and Token Display
  - Add `qr_flutter` package to pubspec.yaml
  - Create TokenDisplayScreen with QR code widget
  - Implement alphanumeric code display with copy functionality
  - Add expiration countdown timer
  - Implement share functionality with deep link
  - Handle expired/used token states
  - _Requirements: 1.4, 1.5, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [ ]* 8.1 Write property test for QR code generation validity
    - **Property 5: QR Code Generation Validity**
    - **Validates: Requirements 1.4, 6.3**

  - [ ]* 8.2 Write unit tests for TokenDisplayScreen
    - Test QR code rendering
    - Test code copy functionality
    - Test expired token state
    - Test share button
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 9. Mobile: QR Scanner and Code Entry
  - Add `mobile_scanner` package to pubspec.yaml
  - Create CaregiverOnboardingScreen with four tiles
  - Implement QRScannerScreen with camera overlay
  - Create CodeEntryScreen with validation
  - Implement ConnectionPreviewModal
  - Handle token validation errors
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

  - [ ]* 9.1 Write unit tests for QR scanner flow
    - Test camera permission handling
    - Test QR code extraction
    - Test validation error display
    - Test preview modal display
    - _Requirements: 6.2, 6.3, 6.6, 6.7_

- [ ] 10. Mobile: Family Connect Flow Screens
  - Create FamilyConnectIntroScreen with hero illustration
  - Create AccessLevelSelectionScreen with three options
  - Implement navigation between screens
  - Add entry points: dashboard chip, settings menu, FAB, banner
  - Wire up token generation API calls
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 4.1, 4.2_

  - [ ]* 10.1 Write property test for navigation consistency
    - **Property 6: Navigation Consistency**
    - **Validates: Requirements 2.5**

  - [ ]* 10.2 Write unit tests for family connect screens
    - Test intro screen rendering
    - Test access level selection
    - Test navigation flow
    - _Requirements: 3.1, 3.2, 4.1_

- [ ] 11. Mobile: Connection Approval Flow
  - Implement in-app approval sheet UI
  - Add permission level adjustment controls
  - Create Approve/Deny/Message buttons
  - Handle approval/denial API calls
  - Display success toast on approval
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8_

  - [ ]* 11.1 Write property test for connection state transitions
    - **Property 7: Connection State Transition - Approval**
    - **Property 8: Connection State Transition - Denial**
    - **Validates: Requirements 7.6, 7.7**

  - [ ]* 11.2 Write unit tests for approval flow
    - Test approval sheet display
    - Test permission adjustment
    - Test approval success
    - Test denial
    - _Requirements: 7.3, 7.4, 7.8_

- [ ] 12. Mobile: Family Access List and Management
  - Create FamilyAccessListScreen with connection cards
  - Display caregiver count header (X / Y)
  - Implement alert toggle switches
  - Add overflow menu with Change Permission and Remove options
  - Create CaregiverDetailScreen
  - Wire up API calls for permission changes and removal
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 12.1 Write unit tests for family access list
    - Test connection card rendering
    - Test alert toggle functionality
    - Test overflow menu actions
    - Test caregiver detail screen
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ] 13. Mobile: Caregiver Dashboard
  - Create CaregiverDashboardScreen
  - Implement patient selector dropdown
  - Display patient's medications and adherence
  - Show missed doses section
  - Add "Nudge Patient" buttons
  - Handle deep link navigation from notifications
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 12.5_

  - [ ]* 13.1 Write unit tests for caregiver dashboard
    - Test patient selector
    - Test medication list display
    - Test missed dose section
    - Test nudge button
    - Test deep link handling
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 12.5_

- [ ] 14. Mobile: Grace Period UI and Missed Dose Display
  - Add grace period countdown timer to Today_Dashboard
  - Display missed dose banner with quick actions
  - Implement "Mark as Taken" functionality for missed doses
  - Add red badge indicator for missed doses
  - Create grace period settings screen
  - _Requirements: 10.5, 10.6, 11.2, 11.3, 11.4, 11.5, 11.6_

  - [ ]* 14.1 Write property test for late dose marking time window
    - **Property 14: Late Dose Marking Time Window**
    - **Validates: Requirements 11.6**

  - [ ]* 14.2 Write unit tests for grace period UI
    - Test countdown timer display
    - Test missed dose banner
    - Test mark as taken button
    - Test red badge indicator
    - _Requirements: 10.5, 11.2, 11.3, 11.5_

- [ ] 15. Mobile: Nudge Interface
  - Implement nudge notification banner for patients
  - Add quick action buttons: "Mark as Taken", "I'll take it soon", "Dismiss"
  - Display caregiver response notifications
  - Update caregiver view with patient responses
  - Handle rate limit errors gracefully
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_

  - [ ]* 15.1 Write unit tests for nudge interface
    - Test nudge banner display
    - Test quick action buttons
    - Test response notifications
    - Test rate limit error handling
    - _Requirements: 13.3, 13.4, 13.6_

- [ ] 16. Mobile: Connection History Screen
  - Create ConnectionHistoryScreen
  - Implement filter chips (All, Requests, Approvals, Changes, Removals)
  - Add date range selector
  - Display audit log entries with pagination
  - Implement infinite scroll
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

  - [ ]* 16.1 Write unit tests for connection history
    - Test filter functionality
    - Test date range selector
    - Test entry display
    - Test pagination
    - _Requirements: 15.3, 15.4, 15.5_

- [ ] 17. Mobile: Offline Support and Sync
  - Implement offline queueing for connection requests
  - Store approval/denial actions in SQLite when offline
  - Add automatic sync on network restore
  - Display "Pending Sync" indicator
  - Implement retry logic with failure notification
  - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

  - [ ]* 17.1 Write property test for offline request queueing
    - **Property 22: Offline Request Queueing**
    - **Validates: Requirements 17.1, 17.2, 17.3**

  - [ ]* 17.2 Write property test for offline sync retry logic
    - **Property 23: Offline Sync Retry Logic**
    - **Validates: Requirements 17.5**

  - [ ]* 17.3 Write unit tests for offline support
    - Test offline queueing
    - Test sync on network restore
    - Test pending sync indicator
    - Test retry after failures
    - _Requirements: 17.1, 17.2, 17.4, 17.5_

- [ ] 18. Mobile: Notification Preferences
  - Create NotificationPreferencesScreen in settings
  - Add toggles for: Connection Requests, Missed Dose Alerts, Family Alerts, Nudges
  - Implement local persistence of preferences
  - Add API sync for preferences
  - Update notification handling to respect preferences
  - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5_

  - [ ]* 18.1 Write property test for notification preference enforcement
    - **Property 25: Notification Preference Enforcement**
    - **Validates: Requirements 20.3, 20.5**

  - [ ]* 18.2 Write property test for notification preference persistence
    - **Property 26: Notification Preference Persistence**
    - **Validates: Requirements 20.4**

  - [ ]* 18.3 Write unit tests for notification preferences
    - Test preference screen rendering
    - Test toggle functionality
    - Test local persistence
    - Test API sync
    - _Requirements: 20.1, 20.2, 20.4_

- [ ] 19. Mobile: Doctor Connection Variant
  - Add "Connect Doctor" option in settings
  - Reuse token generation flow with doctor flag
  - Create separate "Healthcare Providers" section
  - Implement clinical interface theme for doctor dashboard
  - Ensure role enforcement (DOCTOR vs FAMILY_MEMBER)
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6_

  - [ ]* 19.1 Write unit tests for doctor connection variant
    - Test doctor connection option
    - Test healthcare providers section
    - Test clinical interface theme
    - Test role enforcement
    - _Requirements: 16.1, 16.2, 16.3, 16.4_

- [ ] 20. Localization and Accessibility
  - Add Khmer translations for all new strings
  - Ensure all screens support light and dark themes
  - Add screen reader labels for all interactive elements
  - Verify touch target sizes (44x44 points minimum)
  - Test QR code visibility in both themes
  - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5_

  - [ ]* 20.1 Write unit tests for localization
    - Test Khmer translations
    - Test language switching
    - Test theme switching
    - _Requirements: 18.1, 18.2, 18.3_

- [ ] 21. Error Handling and Edge Cases
  - Implement all backend error responses
  - Add mobile error handling for network failures
  - Display appropriate error messages for token errors
  - Handle camera permission errors
  - Add validation error displays
  - Test subscription limit error handling
  - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6_

  - [ ]* 21.1 Write unit tests for error handling
    - Test expired token error
    - Test used token error
    - Test network error
    - Test self-connection error
    - Test subscription limit error
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.6_

- [ ] 22. Final Checkpoint - Integration Testing
  - Test complete family connection flow end-to-end
  - Test missed dose detection and alert flow
  - Test nudge functionality with multiple caregivers
  - Test offline sync scenarios
  - Verify all property tests pass
  - Verify all unit tests pass
  - Test with both Khmer and English languages
  - Test in both light and dark themes
  - Ask the user if questions arise

- [ ] 23. Documentation and Deployment Preparation
  - Update API documentation with new endpoints
  - Create user guide for family connections
  - Document scheduled job configuration
  - Prepare database migration scripts
  - Create deployment checklist
  - Set up monitoring for missed dose job
  - Configure feature flags for gradual rollout

## Notes

- Tasks marked with `*` are optional property-based and unit tests that can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples, UI rendering, and edge cases
- Backend tasks should be completed before mobile tasks to ensure API availability
- Offline support should be tested thoroughly as it's critical for medication adherence
- Localization and accessibility are non-negotiable for production release

## Testing Summary

**Total Property Tests:** 26 properties covering:
- Token lifecycle and validation
- Connection state transitions
- Notification creation and distribution
- Grace period and missed dose detection
- Nudge rate limiting
- Subscription limits
- Offline sync behavior
- Notification preferences

**Total Unit Tests:** ~50+ unit tests covering:
- UI screen rendering
- Navigation flows
- Error handling
- Edge cases
- Integration points

**Test Configuration:**
- Backend: Use `fast-check` library with 100 iterations per property
- Mobile: Use Flutter `test` package with custom generators
- All tests must reference their design document property number
- CI/CD should run all tests before deployment


done but not yet test