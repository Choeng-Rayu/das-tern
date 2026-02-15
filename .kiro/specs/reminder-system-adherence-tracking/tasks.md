# Implementation Plan: Reminder System and Adherence Tracking

## Overview

This implementation plan breaks down the Reminder System and Adherence Tracking feature into discrete, incremental coding tasks. The plan follows a bottom-up approach: database schema → backend services → API endpoints → scheduled jobs → mobile app integration. Each task builds on previous work, with property-based tests and unit tests integrated throughout to catch errors early.

## Tasks

- [ ] 1. Database Schema and Migrations
  - [ ] 1.1 Create reminders table with all required fields and indexes
    - Create Prisma schema for Reminder model with ReminderStatus enum
    - Add indexes on (patient_id, scheduled_time), (status, scheduled_time), (medication_id)
    - _Requirements: 1.1, 1.6, 1.7_
  
  - [ ] 1.2 Extend users table with reminder settings
    - Add grace_period_minutes (default 30), repeat_reminders_enabled (default true), repeat_interval_minutes (default 10)
    - _Requirements: 9.4, 9.5, 9.6, 15.1, 15.2_
  
  - [ ] 1.3 Extend medications table with reminder configuration
    - Add reminders_enabled (default true) and custom_times (JSONB)
    - _Requirements: 9.2, 9.3_
  
  - [ ] 1.4 Extend dose_events table with reminder relationship
    - Add reminder_id foreign key (nullable, unique)
    - _Requirements: 4.4, 5.2_
  
  - [ ] 1.5 Run database migrations and verify schema
    - Execute Prisma migrations
    - Verify all tables, columns, and indexes are created
    - _Requirements: All database-related requirements_

- [ ] 2. Backend Core Services - Reminder Generation
  - [ ] 2.1 Implement ReminderGeneratorService
    - Create service class with generateRemindersForPrescription method
    - Implement calculateReminderTime based on meal preferences and dosage timing
    - Generate reminders for next 30 days with status PENDING
    - Skip PRN medications
    - _Requirements: 1.1, 1.4, 1.5, 1.6, 1.7_
  
  - [ ]* 2.2 Write property test for reminder generation completeness
    - **Property 1: Reminder Generation Completeness**
    - **Validates: Requirements 1.1, 1.6, 1.7**
  
  - [ ]* 2.3 Write property test for PRN medication exclusion
    - **Property 5: PRN Medication Exclusion**
    - **Validates: Requirements 1.5**
  
  - [ ]* 2.4 Write property test for meal-based time calculation
    - **Property 4: Meal-Based Reminder Time Calculation**
    - **Validates: Requirements 1.4**
  
  - [ ] 2.5 Implement reminder regeneration logic
    - Add regenerateRemindersForMedication method
    - Delete existing pending reminders and generate new ones
    - _Requirements: 1.2, 9.1_
  
  - [ ]* 2.6 Write property test for reminder regeneration
    - **Property 2: Reminder Regeneration on Schedule Update**
    - **Validates: Requirements 1.2, 9.1**
  
  - [ ] 2.7 Implement reminder deletion logic
    - Add deleteRemindersForPrescription method
    - Remove all pending reminders for a medication
    - _Requirements: 1.3_
  
  - [ ]* 2.8 Write property test for reminder cleanup
    - **Property 3: Reminder Cleanup on Medication Deletion**
    - **Validates: Requirements 1.3**


- [ ] 3. Backend Core Services - Redis Queue Management
  - [ ] 3.1 Implement Redis queue operations for reminders
    - Create RedisQueueService with methods to add, fetch, and remove reminders from sorted set
    - Use sorted set with score = scheduledTime.getTime()
    - Implement fetchDueReminders to get reminders due in next minute
    - _Requirements: 2.1_
  
  - [ ] 3.2 Implement FCM notification service
    - Create FCMService with sendNotification method
    - Build notification payload with medication name, dosage, scheduled time
    - Handle FCM token retrieval from Redis
    - Implement retry logic with exponential backoff (3 attempts)
    - _Requirements: 2.1, 2.2, 2.4_
  
  - [ ]* 3.3 Write property test for notification payload completeness
    - **Property 7: Notification Payload Completeness**
    - **Validates: Requirements 2.2**
  
  - [ ]* 3.4 Write property test for delivery retry logic
    - **Property 9: Delivery Retry with Exponential Backoff**
    - **Validates: Requirements 2.4**
  
  - [ ] 3.5 Implement notification localization
    - Add i18n support for notification messages
    - Support Khmer and English with fallback to English
    - _Requirements: 2.7, 13.1, 13.2, 13.3, 13.5_
  
  - [ ]* 3.6 Write property test for language preference enforcement
    - **Property 11: Language Preference Enforcement**
    - **Validates: Requirements 2.7, 13.1, 13.2, 13.3, 13.5**

- [ ] 4. Backend Scheduled Jobs - Reminder Delivery
  - [ ] 4.1 Implement ReminderSchedulerJob
    - Create scheduled job with @Cron('* * * * *') decorator (runs every minute)
    - Fetch due reminders from Redis queue
    - Update status to DELIVERING, send via FCM, update to DELIVERED
    - Handle failures and mark as FAILED after retries
    - Log deliveredAt timestamp
    - _Requirements: 2.1, 2.3, 2.5_
  
  - [ ]* 4.2 Write property test for delivery status update
    - **Property 8: Delivery Status Update**
    - **Validates: Requirements 2.3, 2.5**
  
  - [ ]* 4.3 Write unit tests for reminder scheduler job
    - Test successful delivery flow
    - Test failure and retry flow
    - Test status transitions
    - _Requirements: 2.1, 2.3, 2.4, 2.5_
  
  - [ ] 4.4 Implement repeat reminder logic
    - Schedule repeat reminders 10 minutes after delivery if no DoseEvent recorded
    - Limit to 3 repeat reminders
    - Add repeat indicator to notification text
    - Respect repeat_reminders_enabled setting
    - _Requirements: 6.1, 6.2, 6.3, 6.5_
  
  - [ ]* 4.5 Write property test for repeat reminder timing
    - **Property 25: Repeat Reminder Timing**
    - **Validates: Requirements 6.1, 6.2**
  
  - [ ]* 4.6 Write property test for repeat reminder cancellation
    - **Property 27: Repeat Reminder Cancellation**
    - **Validates: Requirements 6.4**

- [ ] 5. Backend Scheduled Jobs - Missed Dose Detection
  - [ ] 5.1 Implement MissedDoseDetectionJob
    - Create scheduled job with @Cron('*/5 * * * *') decorator (runs every 5 minutes)
    - Query for reminders where status = DELIVERED and scheduledTime + grace_period < NOW() and no DoseEvent
    - Create DoseEvent with status MISSED
    - Update Reminder status to MISSED
    - _Requirements: 5.1, 5.2, 5.4_
  
  - [ ]* 5.2 Write property test for missed dose detection
    - **Property 18: Missed Dose Detection**
    - **Validates: Requirements 5.1, 5.2, 5.4**
  
  - [ ]* 5.3 Write property test for missed dose timestamp recording
    - **Property 19: Missed Dose Timestamp Recording**
    - **Validates: Requirements 5.3**
  
  - [ ] 5.2 Implement patient missed dose notification
    - Create notification with type MISSED_DOSE_ALERT for patient
    - Include medication name and scheduled time
    - _Requirements: 5.5, 11.1_
  
  - [ ]* 5.5 Write property test for patient missed dose alert
    - **Property 20: Patient Missed Dose Alert**
    - **Validates: Requirements 5.5**
  
  - [ ] 5.6 Implement family member missed dose alerts
    - Query family connections with status ACCEPTED, role FAMILY_MEMBER, alertsEnabled true
    - Create MISSED_DOSE_ALERT notifications for each family member
    - Include patient name, medication name, scheduled time, deep link
    - Implement batching for multiple missed doses within 1 hour
    - Log in AuditLog
    - _Requirements: 5.6, 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_
  
  - [ ]* 5.7 Write property test for family member alerts
    - **Property 21: Family Member Missed Dose Alerts**
    - **Validates: Requirements 5.6, 11.1, 11.4**
  
  - [ ]* 5.8 Write property test for family alert content
    - **Property 22: Family Alert Content**
    - **Validates: Requirements 11.2, 11.3**
  
  - [ ]* 5.9 Write unit tests for missed dose detection job
    - Test detection after grace period
    - Test no detection within grace period
    - Test family alert filtering by alertsEnabled
    - Test batched alerts
    - _Requirements: 5.1, 5.2, 5.6, 11.4, 11.5_

- [ ] 6. Checkpoint - Ensure core reminder system works
  - Ensure all tests pass, ask the user if questions arise.


- [ ] 7. Backend Core Services - Adherence Calculation
  - [ ] 7.1 Implement AdherenceCalculatorService
    - Create service with calculateAdherence method supporting daily, weekly, monthly periods
    - Implement formula: (TAKEN_ON_TIME + TAKEN_LATE) / (total non-PRN scheduled doses) × 100
    - Exclude PRN medications from calculation
    - Determine color code: GREEN (≥90%), YELLOW (70-89%), RED (<70%)
    - _Requirements: 7.2, 7.3, 7.4, 7.5, 8.2_
  
  - [ ]* 7.2 Write property test for adherence calculation formula
    - **Property 30: Adherence Calculation Formula**
    - **Validates: Requirements 7.2, 7.3, 7.4**
  
  - [ ]* 7.3 Write property test for adherence color coding
    - **Property 33: Adherence Color Coding**
    - **Validates: Requirements 8.2**
  
  - [ ] 7.4 Implement adherence caching with Redis
    - Cache results with key: adherence:{patientId}:{period}:{date}
    - Set TTL to 5 minutes
    - Return cached value if available
    - Implement invalidateCache method
    - _Requirements: 7.6, 7.7_
  
  - [ ]* 7.5 Write property test for adherence caching
    - **Property 32: Adherence Caching**
    - **Validates: Requirements 7.6, 7.7**
  
  - [ ] 7.6 Implement calculateDailyProgress method
    - Calculate progress for a specific date
    - Return percentage, taken count, total count
    - _Requirements: 7.1_
  
  - [ ] 7.7 Implement getAdherenceTrend method
    - Return daily adherence percentages for date range (up to 90 days)
    - Provide weekly and monthly aggregations
    - Exclude days with no scheduled doses
    - _Requirements: 8.1, 8.3, 8.4, 8.5_
  
  - [ ]* 7.8 Write property test for adherence trend retrieval
    - **Property 34: Adherence History Retrieval**
    - **Validates: Requirements 8.1, 8.5**
  
  - [ ]* 7.9 Write property test for zero-dose day exclusion
    - **Property 36: Zero-Dose Day Exclusion**
    - **Validates: Requirements 8.4**
  
  - [ ]* 7.10 Write unit tests for adherence calculator
    - Test 100% adherence (all taken)
    - Test 0% adherence (all missed)
    - Test mixed adherence
    - Test PRN exclusion
    - Test color code boundaries
    - _Requirements: 7.2, 7.3, 7.4, 8.2_

- [ ] 8. Backend Core Services - Dose Event Recording
  - [ ] 8.1 Implement DoseEventService
    - Create markDoseTaken method
    - Validate dose exists and belongs to patient
    - Check time window (within 24 hours of scheduled time)
    - Determine status: TAKEN_ON_TIME (within grace period) or TAKEN_LATE (after grace period)
    - Create DoseEvent record
    - Update Reminder status to COMPLETED
    - Dismiss notification
    - Invalidate adherence cache
    - _Requirements: 4.1, 4.3, 4.4, 4.5, 4.6, 4.7, 7.1_
  
  - [ ]* 8.2 Write property test for dose event creation
    - **Property 15: Dose Event Creation**
    - **Validates: Requirements 4.1, 4.2, 4.4**
  
  - [ ]* 8.3 Write property test for timing classification
    - **Property 17: Timing Classification**
    - **Validates: Requirements 4.5, 4.6, 4.7**
  
  - [ ] 8.4 Implement markDoseSkipped method
    - Create DoseEvent with status SKIPPED
    - Update Reminder status to COMPLETED
    - Invalidate adherence cache
    - _Requirements: 4.2, 4.4_
  
  - [ ]* 8.5 Write unit tests for dose event service
    - Test marking taken within grace period
    - Test marking taken after grace period
    - Test rejection beyond 24 hours
    - Test marking skipped
    - Test adherence cache invalidation
    - _Requirements: 4.1, 4.2, 4.5, 4.6, 4.7, 7.1_

- [ ] 9. Backend Core Services - Snooze Handler
  - [ ] 9.1 Implement SnoozeHandlerService
    - Create snoozeReminder method with duration validation (5, 10, 15 minutes)
    - Check snooze limit (max 3 snoozes)
    - Update Reminder: status = SNOOZED, snoozedUntil = NOW() + duration, snoozeCount++
    - Add to Redis queue with new scheduled time
    - _Requirements: 3.1, 3.2, 3.3, 3.5_
  
  - [ ]* 9.2 Write property test for snooze rescheduling
    - **Property 13: Snooze Rescheduling**
    - **Validates: Requirements 3.2, 3.3**
  
  - [ ]* 9.3 Write property test for snooze options availability
    - **Property 12: Snooze Options Availability**
    - **Validates: Requirements 3.1, 3.5**
  
  - [ ] 9.4 Implement processSnoozedReminders in scheduler job
    - Fetch snoozed reminders where snoozedUntil <= NOW()
    - Redeliver notification
    - _Requirements: 3.4_
  
  - [ ]* 9.5 Write property test for snoozed reminder redelivery
    - **Property 14: Snoozed Reminder Redelivery**
    - **Validates: Requirements 3.4**

- [ ] 10. Backend Core Services - Reminder Configuration
  - [ ] 10.1 Implement ReminderConfigurationService
    - Create updateReminderTime method
    - Regenerate future reminders with new times
    - _Requirements: 9.1_
  
  - [ ] 10.2 Implement toggleReminders method
    - If disabled: Cancel pending reminders but keep tracking doses
    - If enabled: Generate reminders for future doses
    - _Requirements: 9.2, 9.3_
  
  - [ ]* 10.3 Write property test for reminder disabling behavior
    - **Property 37: Reminder Disabling Behavior**
    - **Validates: Requirements 9.2**
  
  - [ ]* 10.4 Write property test for reminder enabling behavior
    - **Property 38: Reminder Enabling Behavior**
    - **Validates: Requirements 9.3**
  
  - [ ] 10.5 Implement updateGracePeriod method
    - Validate value is 10, 20, 30, or 60 minutes
    - Update user record
    - Apply to future reminders only (not retroactive)
    - _Requirements: 9.4, 9.5, 15.1, 15.2, 15.3, 15.4_
  
  - [ ]* 10.6 Write property test for grace period update application
    - **Property 39: Grace Period Update Application**
    - **Validates: Requirements 9.4, 15.3, 15.4**
  
  - [ ]* 10.7 Write property test for grace period validation
    - **Property 40: Grace Period Validation**
    - **Validates: Requirements 9.5, 15.1, 15.2**
  
  - [ ] 10.8 Implement updateRepeatFrequency method
    - Update user settings
    - Apply to future reminders
    - _Requirements: 9.6_
  
  - [ ] 10.9 Implement getReminderSettings method
    - Return all reminder settings for patient
    - _Requirements: 9.7_


- [ ] 11. Backend API Endpoints - Reminder Management
  - [ ] 11.1 Implement POST /api/reminders/generate/:prescriptionId
    - Call ReminderGeneratorService.generateRemindersForPrescription
    - Return generated reminders and count
    - _Requirements: 1.1_
  
  - [ ] 11.2 Implement GET /api/reminders/upcoming
    - Query reminders for patient with status PENDING or DELIVERED
    - Support query params: days (default 7), limit (default 50)
    - Return sorted by scheduledTime
    - _Requirements: 14.1_
  
  - [ ] 11.3 Implement POST /api/reminders/:reminderId/snooze
    - Call SnoozeHandlerService.snoozeReminder
    - Validate duration (5, 10, 15 minutes)
    - Return updated reminder and new scheduled time
    - _Requirements: 3.1, 3.2_
  
  - [ ] 11.4 Implement GET /api/reminders/history
    - Query reminders with filters: startDate, endDate, status, medication
    - Include reminder time, delivery status, associated DoseEvent
    - Support pagination (50 items per page)
    - Limit to 90 days in the past
    - _Requirements: 14.1, 14.2, 14.4, 14.5, 14.6_
  
  - [ ]* 11.5 Write property test for reminder history filtering
    - **Property 56: Reminder History Filtering**
    - **Validates: Requirements 14.4**
  
  - [ ] 11.6 Implement PATCH /api/reminders/settings
    - Update grace period, repeat reminders enabled, repeat interval
    - Validate grace period values
    - Persist changes immediately
    - _Requirements: 9.4, 9.5, 9.6, 9.7_
  
  - [ ] 11.7 Implement PATCH /api/reminders/medications/:medicationId/time
    - Update custom reminder time for medication
    - Regenerate future reminders
    - _Requirements: 9.1_
  
  - [ ] 11.8 Implement PATCH /api/reminders/medications/:medicationId/toggle
    - Toggle reminders enabled/disabled for medication
    - Call ReminderConfigurationService.toggleReminders
    - _Requirements: 9.2, 9.3_

- [ ] 12. Backend API Endpoints - Adherence
  - [ ] 12.1 Implement GET /api/adherence
    - Call AdherenceCalculatorService.calculateAdherence
    - Support query params: period (daily/weekly/monthly), date
    - Return adherence percentage, counts, color code
    - _Requirements: 7.1, 7.2, 7.5_
  
  - [ ] 12.2 Implement GET /api/adherence/trend
    - Call AdherenceCalculatorService.getAdherenceTrend
    - Support query params: startDate, endDate (max 90 days)
    - Return daily adherence data with aggregations
    - _Requirements: 8.1, 8.3, 8.5_
  
  - [ ] 12.3 Implement GET /api/adherence/daily-progress
    - Call AdherenceCalculatorService.calculateDailyProgress
    - Support query param: date (default today)
    - Return progress percentage, taken count, total count
    - _Requirements: 7.1_

- [ ] 13. Backend API Endpoints - Dose Events (Extended)
  - [ ] 13.1 Extend POST /api/doses/:doseId/mark-taken
    - Add support for reminderId in request body
    - Call DoseEventService.markDoseTaken
    - Return dose, daily progress, adherence percentage
    - _Requirements: 4.1, 4.5, 4.6, 4.7, 7.1_
  
  - [ ] 13.2 Implement POST /api/doses/sync
    - Accept array of offline dose events
    - Validate timestamps (within 24 hours)
    - Resolve conflicts (prioritize earliest timestamp)
    - Return sync result with synced count, failed count, conflicts
    - _Requirements: 10.2, 10.3, 10.5_
  
  - [ ]* 13.3 Write property test for offline sync validation
    - **Property 44: Offline Sync Validation**
    - **Validates: Requirements 10.3**
  
  - [ ]* 13.4 Write property test for sync conflict resolution
    - **Property 46: Sync Conflict Resolution**
    - **Validates: Requirements 10.5**

- [ ] 14. Backend Error Handling and Validation
  - [ ] 14.1 Implement error handlers for all reminder endpoints
    - Handle PRESCRIPTION_NOT_FOUND, MEDICATION_NOT_FOUND, INVALID_SCHEDULE
    - Handle FCM_TOKEN_NOT_FOUND, FCM_DELIVERY_FAILED
    - Handle REMINDER_NOT_FOUND, DOSE_ALREADY_RECORDED, TIME_WINDOW_EXCEEDED
    - Handle INVALID_GRACE_PERIOD, INVALID_TIME_FORMAT
    - Return appropriate HTTP status codes and error messages
    - _Requirements: All error handling requirements_
  
  - [ ] 14.2 Implement input validation with Zod schemas
    - Validate reminder generation requests
    - Validate snooze duration
    - Validate grace period values
    - Validate time formats
    - Validate date ranges
    - _Requirements: 9.5, 15.1_
  
  - [ ]* 14.3 Write unit tests for error handling
    - Test all error scenarios
    - Test validation failures
    - Test error response formats
    - _Requirements: All error handling requirements_

- [ ] 15. Checkpoint - Ensure backend is complete
  - Ensure all tests pass, ask the user if questions arise.


- [ ] 16. Mobile App - FCM Integration
  - [ ] 16.1 Set up Firebase Cloud Messaging
    - Add firebase_messaging dependency
    - Configure Firebase for iOS and Android
    - Request notification permissions
    - _Requirements: 2.1_
  
  - [ ] 16.2 Implement FCMHandler service
    - Initialize FCM and get device token
    - Register token with backend on app launch
    - Handle foreground messages
    - Handle background messages
    - Handle notification tap and deep linking
    - _Requirements: 2.1, 11.3_
  
  - [ ] 16.3 Implement notification action handlers
    - Handle "Mark Taken" action
    - Handle "Snooze" action with duration selection
    - Handle "Dismiss" action
    - _Requirements: 3.1, 4.1_
  
  - [ ]* 16.4 Write unit tests for FCM handler
    - Test token registration
    - Test foreground message handling
    - Test background message handling
    - Test notification tap handling
    - _Requirements: 2.1_

- [ ] 17. Mobile App - Local Notification Service
  - [ ] 17.1 Set up flutter_local_notifications
    - Add flutter_local_notifications dependency
    - Configure notification channels for Android
    - Configure notification categories for iOS
    - Request exact alarm permission (Android 12+)
    - _Requirements: 10.1_
  
  - [ ] 17.2 Implement LocalNotificationService
    - Create scheduleReminder method
    - Create cancelReminder method
    - Create cancelAllReminders method
    - Handle notification tap with payload
    - _Requirements: 10.1_
  
  - [ ] 17.3 Implement offline reminder queueing
    - Store up to 100 pending reminders in SQLite
    - Prioritize nearest scheduled reminders when queue is full
    - Sync with server every hour
    - _Requirements: 10.6, 10.7_
  
  - [ ]* 17.4 Write property test for local queue capacity
    - **Property 47: Local Queue Capacity**
    - **Validates: Requirements 10.6, 10.7**
  
  - [ ] 17.5 Implement timezone handling
    - Detect timezone changes
    - Adjust reminder times to maintain local time
    - _Requirements: 10.4_
  
  - [ ]* 17.6 Write property test for timezone adjustment
    - **Property 45: Timezone Adjustment**
    - **Validates: Requirements 10.4**

- [ ] 18. Mobile App - Offline Queue Manager
  - [ ] 18.1 Implement OfflineQueueManager
    - Create queueDoseEvent method to store events in SQLite
    - Create getPendingEvents method
    - Create syncPendingEvents method
    - Monitor connectivity with connectivity_plus
    - Auto-sync when connectivity is restored
    - _Requirements: 10.2_
  
  - [ ]* 18.2 Write property test for offline dose event sync
    - **Property 43: Offline Dose Event Sync**
    - **Validates: Requirements 10.2**
  
  - [ ] 18.3 Implement sync retry logic
    - Retry failed syncs with exponential backoff
    - Display sync status in UI
    - Provide manual sync option
    - _Requirements: 10.2_
  
  - [ ]* 18.4 Write unit tests for offline queue manager
    - Test queueing events
    - Test sync on connectivity restore
    - Test retry logic
    - Test conflict resolution
    - _Requirements: 10.2, 10.5_

- [ ] 19. Mobile App - Reminder UI Components
  - [ ] 19.1 Create ReminderCard widget
    - Display medication name, dosage, scheduled time
    - Show status indicator (due, taken, missed, snoozed)
    - Add action buttons: Mark Taken, Snooze, Skip
    - Display medication image thumbnail
    - _Requirements: 4.1, 4.2, 3.1_
  
  - [ ] 19.2 Create ReminderListScreen
    - Display upcoming reminders grouped by time period
    - Support pull-to-refresh
    - Handle empty state
    - Navigate to medication details on tap
    - _Requirements: 14.1_
  
  - [ ] 19.3 Create SnoozeDialog widget
    - Display snooze options: 5, 10, 15 minutes
    - Disable snooze after 3 snoozes
    - Call snooze API endpoint
    - _Requirements: 3.1, 3.5_
  
  - [ ] 19.4 Create MissedDoseAlert widget
    - Display prominent alert banner
    - Show medication details
    - Add "Mark as Taken" button (if within 24 hours)
    - Add "I'll take it later" button
    - _Requirements: 5.5, 4.7_
  
  - [ ]* 19.5 Write widget tests for reminder UI components
    - Test ReminderCard rendering
    - Test action button interactions
    - Test SnoozeDialog behavior
    - Test MissedDoseAlert display
    - _Requirements: 3.1, 4.1, 4.2, 5.5_

- [ ] 20. Mobile App - Adherence UI Components
  - [ ] 20.1 Create AdherenceCard widget
    - Display adherence percentage with color coding
    - Show taken count / total count
    - Display period selector (daily, weekly, monthly)
    - _Requirements: 7.5, 8.2_
  
  - [ ] 20.2 Create AdherenceChart widget
    - Implement line chart with fl_chart package
    - Display daily adherence trend
    - Color-code by adherence level
    - Add interactive tooltips
    - Add date range selector
    - _Requirements: 8.1, 8.2, 8.3_
  
  - [ ] 20.3 Create AdherenceHistoryScreen
    - Display adherence chart
    - Show daily progress list
    - Support filtering by date range
    - Handle empty state
    - _Requirements: 8.1, 8.5_
  
  - [ ]* 20.4 Write widget tests for adherence UI components
    - Test AdherenceCard rendering
    - Test color coding
    - Test chart display
    - Test period selection
    - _Requirements: 7.5, 8.2_

- [ ] 21. Mobile App - Settings and Configuration
  - [ ] 21.1 Create ReminderSettingsScreen
    - Display grace period selector (10, 20, 30, 60 minutes)
    - Display repeat reminders toggle
    - Display repeat interval selector
    - Call settings API endpoint on change
    - _Requirements: 9.4, 9.5, 9.6_
  
  - [ ] 21.2 Create MedicationReminderSettings widget
    - Display reminders enabled toggle per medication
    - Display custom time pickers for morning/daytime/night
    - Call medication settings API endpoints
    - _Requirements: 9.1, 9.2, 9.3_
  
  - [ ]* 21.3 Write widget tests for settings screens
    - Test grace period selection
    - Test repeat reminders toggle
    - Test medication reminder toggle
    - Test custom time selection
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_


- [ ] 22. Mobile App - API Integration
  - [ ] 22.1 Create ReminderApiService
    - Implement getUpcomingReminders method
    - Implement snoozeReminder method
    - Implement getReminderHistory method
    - Implement updateReminderSettings method
    - Implement updateMedicationReminderTime method
    - Implement toggleMedicationReminders method
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.6, 14.1_
  
  - [ ] 22.2 Create AdherenceApiService
    - Implement getAdherence method
    - Implement getAdherenceTrend method
    - Implement getDailyProgress method
    - _Requirements: 7.1, 7.5, 8.1_
  
  - [ ] 22.3 Create DoseEventApiService (extend existing)
    - Extend markDoseTaken to include reminderId
    - Implement syncOfflineDoseEvents method
    - _Requirements: 4.1, 10.2_
  
  - [ ]* 22.4 Write integration tests for API services
    - Test API calls with mock responses
    - Test error handling
    - Test offline queueing
    - _Requirements: All API-related requirements_

- [ ] 23. Mobile App - State Management
  - [ ] 23.1 Create ReminderProvider (or Bloc/Cubit)
    - Manage reminder list state
    - Handle reminder actions (snooze, mark taken, skip)
    - Handle real-time updates from FCM
    - _Requirements: 3.1, 4.1, 4.2_
  
  - [ ] 23.2 Create AdherenceProvider (or Bloc/Cubit)
    - Manage adherence data state
    - Handle period selection
    - Handle date range selection
    - Cache adherence data locally
    - _Requirements: 7.1, 7.5, 8.1_
  
  - [ ] 23.3 Create OfflineSyncProvider (or Bloc/Cubit)
    - Manage offline queue state
    - Handle sync status
    - Display sync progress
    - _Requirements: 10.2_
  
  - [ ]* 23.4 Write unit tests for state management
    - Test state transitions
    - Test action handling
    - Test error states
    - _Requirements: All state management requirements_

- [ ] 24. Mobile App - Localization
  - [ ] 24.1 Add reminder notification strings to i18n
    - Add Khmer translations for all notification messages
    - Add English translations
    - Add reminder action labels
    - Add adherence UI labels
    - _Requirements: 2.7, 13.1, 13.2, 13.3_
  
  - [ ] 24.2 Implement language preference sync
    - Sync language preference with backend
    - Apply language to notifications immediately on change
    - _Requirements: 13.4_
  
  - [ ]* 24.3 Write tests for localization
    - Test Khmer translations
    - Test English translations
    - Test fallback behavior
    - _Requirements: 2.7, 13.1, 13.2, 13.3, 13.5_

- [ ] 25. Integration and Wiring
  - [ ] 25.1 Wire reminder generation to prescription confirmation
    - Call ReminderGeneratorService when prescription is confirmed
    - Display success message with reminder count
    - _Requirements: 1.1_
  
  - [ ] 25.2 Wire adherence calculation to dose event creation
    - Trigger adherence recalculation when dose is marked
    - Update UI with new adherence percentage
    - _Requirements: 7.1_
  
  - [ ] 25.3 Wire missed dose alerts to family member notifications
    - Ensure family members receive push notifications
    - Handle deep linking to patient adherence details
    - _Requirements: 5.6, 11.3_
  
  - [ ] 25.4 Wire offline sync to app lifecycle
    - Trigger sync on app foreground
    - Trigger sync on connectivity restore
    - Display sync status in UI
    - _Requirements: 10.2_
  
  - [ ] 25.5 Wire reminder settings to user preferences
    - Load settings on app launch
    - Persist settings changes immediately
    - Apply settings to future reminders
    - _Requirements: 9.4, 9.6, 9.7_

- [ ] 26. Performance Optimization
  - [ ] 26.1 Implement database indexes
    - Verify indexes on (patient_id, scheduled_time)
    - Verify indexes on (status, scheduled_time)
    - Verify indexes on (medication_id)
    - _Requirements: 12.1, 12.4_
  
  - [ ] 26.2 Implement Redis caching for adherence
    - Verify cache TTL is 5 minutes
    - Verify cache invalidation on dose event creation
    - _Requirements: 7.6, 7.7_
  
  - [ ] 26.3 Implement batch processing for missed doses
    - Process in chunks of 100
    - Batch FCM notifications
    - _Requirements: 12.3_
  
  - [ ] 26.4 Optimize mobile app performance
    - Implement pagination for reminder history
    - Lazy load adherence chart data
    - Cache API responses locally
    - _Requirements: 14.6_

- [ ] 27. Monitoring and Logging
  - [ ] 27.1 Add logging for reminder lifecycle
    - Log reminder generation
    - Log delivery attempts and results
    - Log missed dose detection
    - Log adherence calculations
    - _Requirements: 2.5, 14.3_
  
  - [ ] 27.2 Add metrics tracking
    - Track reminder delivery success rate
    - Track average delivery latency
    - Track adherence calculation performance
    - Track offline sync success rate
    - _Requirements: 12.1, 12.4_
  
  - [ ] 27.3 Set up alerts for critical failures
    - Alert on delivery success rate < 99%
    - Alert on average latency > 500ms
    - Alert on Redis queue depth > 10,000
    - _Requirements: 12.1_

- [ ] 28. Final Testing and Validation
  - [ ]* 28.1 Run all property-based tests
    - Verify all 58 properties pass with 100+ iterations
    - Fix any failures
    - _Requirements: All requirements_
  
  - [ ]* 28.2 Run all unit tests
    - Verify all unit tests pass
    - Achieve >80% code coverage
    - _Requirements: All requirements_
  
  - [ ]* 28.3 Run integration tests
    - Test end-to-end reminder flow
    - Test offline sync flow
    - Test adherence calculation flow
    - Test family alert flow
    - _Requirements: All requirements_
  
  - [ ] 28.4 Perform manual testing
    - Test on iOS and Android devices
    - Test with different timezones
    - Test with different languages (Khmer, English)
    - Test offline scenarios
    - Test with multiple medications
    - _Requirements: All requirements_

- [ ] 29. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (minimum 100 iterations each)
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end flows
- The implementation follows a bottom-up approach: database → services → API → jobs → mobile app
- Offline support is critical and integrated throughout
- Performance requirements (300ms latency, 99.9% reliability) are validated through monitoring
