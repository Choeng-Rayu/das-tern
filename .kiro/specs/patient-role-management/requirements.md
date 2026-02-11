# Requirements Document: Patient Role Management

## Introduction

The Patient Role Management feature is the core of the DasTern medication adherence platform, enabling patients to manage their prescriptions, track medications, receive reminders, monitor adherence, connect with doctors and family members, and manage their subscriptions. The patient is the source of truth for medication execution and owns all their medical data with consent-based sharing. The system follows an offline-first architecture with secure medical data handling, fast reminder triggering, and comprehensive adherence tracking.

This feature integrates with existing specifications: reminder-system-adherence-tracking, family-connection-missed-dose-alert, doctor-dashboard, and das-tern-backend-database.

## Glossary

- **Patient**: The primary user who owns medication schedules, receives reminders, and controls data sharing
- **Prescription**: A structured medical document containing medication instructions (manual or doctor-issued)
- **Medicine**: An individual medication item with dosage, form, frequency, schedule, and instructions
- **Dose_Event**: A recorded action for a scheduled medication dose (taken, skipped, missed)
- **Reminder**: A push notification alerting the patient to take medication at scheduled time
- **Adherence_Percentage**: Ratio of taken doses to total scheduled doses over a time period
- **Doctor_Connection**: A secure relationship allowing a doctor to create prescriptions for the patient
- **Family_Connection**: A secure relationship allowing family members to monitor adherence
- **Subscription_Tier**: Plan level determining feature access (FREEMIUM, PREMIUM, FAMILY_PREMIUM)
- **Patient_Dashboard**: The home view showing today's medications, next dose, and adherence status
- **Medicine_Archive**: Historical record of completed medications preserving full history
- **Grace_Period**: Configurable time window after scheduled dose before marking as missed
- **PRN_Medication**: "Pro Re Nata" - medications taken as needed rather than on fixed schedule
- **Offline_Mode**: Application state where data is stored locally and synced when connectivity returns
- **Backend_API**: The NestJS TypeScript backend service
- **Mobile_App**: The Flutter-based patient mobile application
- **Meal_Time_Preference**: User-configured times for morning, afternoon, and night meals


## Requirements

### Requirement 1: Manual Prescription Creation

**User Story:** As a patient, I want to manually create prescriptions with complete details, so that I can track medications that weren't prescribed by a doctor through the app.

#### Acceptance Criteria

1. WHEN a patient creates a prescription, THE Mobile_App SHALL require prescription title, start date, and at least one medicine
2. WHEN a patient creates a prescription, THE Mobile_App SHALL allow optional fields: doctor name, end date, diagnosis, and notes
3. WHEN a prescription is created, THE Backend_API SHALL set the prescription status to ACTIVE immediately
4. WHEN a prescription is created, THE Backend_API SHALL set the patient as the owner with full edit permissions
5. WHEN a prescription is created, THE Backend_API SHALL generate a unique prescription ID and timestamp
6. WHEN a prescription is created, THE Backend_API SHALL create an audit log entry with action type PRESCRIPTION_CREATE
7. THE Mobile_App SHALL validate that start date is not in the past beyond 7 days

### Requirement 2: Medicine Creation and Configuration

**User Story:** As a patient, I want to add medicines to my prescriptions with detailed scheduling information, so that I receive accurate reminders and track adherence correctly.

#### Acceptance Criteria

1. WHEN a patient adds a medicine, THE Mobile_App SHALL require medicine name, dosage amount, and form (tablet, capsule, liquid, injection, inhaler, topical)
2. WHEN a patient adds a medicine, THE Mobile_App SHALL require frequency selection: daily, every N days, specific days of week, or PRN (as needed)
3. WHEN a patient adds a medicine, THE Mobile_App SHALL require at least one schedule time for non-PRN medications
4. WHEN a patient adds a medicine, THE Mobile_App SHALL allow multiple schedule times per day (morning, daytime, night)
5. WHEN a patient adds a medicine, THE Mobile_App SHALL require duration: number of days, until date, or ongoing
6. WHEN a patient adds a medicine, THE Mobile_App SHALL allow optional instructions and notes
7. WHEN a medicine is created, THE Backend_API SHALL generate dose events for all scheduled times based on frequency and duration
8. WHEN a medicine is created, THE Backend_API SHALL trigger the Reminder_System to generate reminders for all scheduled doses
9. THE Mobile_App SHALL support dosage units: mg, ml, tablets, capsules, puffs, drops, applications

### Requirement 3: Doctor-Issued Prescription Workflow

**User Story:** As a patient, I want to receive prescriptions from my connected doctors and confirm or reject them, so that I maintain control over my medication schedule.

#### Acceptance Criteria

1. WHEN a doctor sends a prescription, THE Backend_API SHALL create the prescription with status PENDING
2. WHEN a doctor sends a prescription, THE Backend_API SHALL send a push notification to the patient with type PRESCRIPTION_UPDATE
3. WHEN a patient views a pending prescription, THE Mobile_App SHALL display all prescription details including medicines, dosages, and doctor notes
4. WHEN a patient views a pending prescription, THE Mobile_App SHALL provide "Confirm" and "Reject" buttons
5. WHEN a patient confirms a prescription, THE Backend_API SHALL change status to ACTIVE and generate dose events
6. WHEN a patient confirms a prescription, THE Backend_API SHALL trigger the Reminder_System to generate reminders
7. WHEN a patient rejects a prescription, THE Backend_API SHALL change status to REJECTED and notify the doctor
8. WHEN a prescription is confirmed, THE Backend_API SHALL create an audit log entry with action type PRESCRIPTION_CONFIRM
9. THE Mobile_App SHALL display pending prescriptions prominently on the Patient_Dashboard with a badge count

### Requirement 4: Prescription Viewing and Management

**User Story:** As a patient, I want to view all my prescriptions organized by status, so that I can easily manage my current and past medications.

#### Acceptance Criteria

1. WHEN a patient views prescriptions, THE Mobile_App SHALL display tabs for: Active, Pending, Paused, and Completed
2. WHEN displaying active prescriptions, THE Mobile_App SHALL show prescription title, doctor name, start date, and medicine count
3. WHEN displaying prescriptions, THE Mobile_App SHALL show adherence percentage for each prescription
4. WHEN a patient taps a prescription, THE Mobile_App SHALL navigate to prescription detail view showing all medicines and schedule
5. WHEN viewing prescription details, THE Mobile_App SHALL display edit button only for patient-created prescriptions
6. WHEN viewing prescription details, THE Mobile_App SHALL display pause/resume button for active prescriptions
7. THE Mobile_App SHALL sort prescriptions by start date (most recent first) within each tab


### Requirement 5: Medicine Editing Before First Dose

**User Story:** As a patient, I want to edit medicine details before taking the first dose, so that I can correct mistakes without losing my schedule.

#### Acceptance Criteria

1. WHEN a patient attempts to edit a medicine, THE Backend_API SHALL check if any dose has been taken
2. IF no doses have been taken, THEN THE Backend_API SHALL allow editing all medicine fields
3. IF any dose has been taken, THEN THE Backend_API SHALL prevent editing and display message: "Cannot edit medicine after first dose. Create a new medicine instead."
4. WHEN a medicine is edited before first dose, THE Backend_API SHALL regenerate all dose events with new schedule
5. WHEN a medicine is edited before first dose, THE Backend_API SHALL update the Reminder_System with new schedule
6. WHEN a medicine is edited, THE Backend_API SHALL create an audit log entry with action type PRESCRIPTION_UPDATE
7. THE Mobile_App SHALL display edit icon only for medicines with no recorded doses

### Requirement 6: Medicine Archiving and History Preservation

**User Story:** As a patient, I want completed medicines to be automatically archived, so that my active medication list stays clean while preserving full history.

#### Acceptance Criteria

1. WHEN a medicine's duration ends, THE Backend_API SHALL automatically change its status to ARCHIVED
2. WHEN a medicine is archived, THE Backend_API SHALL preserve all dose events and adherence data
3. WHEN a medicine is archived, THE Backend_API SHALL stop generating new dose events and reminders
4. WHEN a patient views archived medicines, THE Mobile_App SHALL display complete history including all doses taken, skipped, and missed
5. WHEN a patient views archived medicines, THE Mobile_App SHALL display final adherence percentage
6. THE Mobile_App SHALL provide a "Medicine History" section accessible from prescription details
7. THE Backend_API SHALL retain archived medicine data indefinitely unless patient explicitly deletes prescription

### Requirement 7: Patient Dashboard - Today's View

**User Story:** As a patient, I want to see today's medication schedule at a glance, so that I know what to take and when.

#### Acceptance Criteria

1. WHEN a patient opens the app, THE Mobile_App SHALL display the Patient_Dashboard as the home screen
2. WHEN displaying today's view, THE Mobile_App SHALL show all scheduled doses for the current day grouped by time period (morning, daytime, night)
3. WHEN displaying each dose, THE Mobile_App SHALL show medicine name, dosage, scheduled time, and status (due, taken, skipped, missed)
4. WHEN displaying doses, THE Mobile_App SHALL use color coding: green for taken, yellow for due, red for missed, gray for skipped
5. WHEN a dose is due, THE Mobile_App SHALL display quick action buttons: "Mark as Taken" and "Skip"
6. WHEN displaying today's view, THE Mobile_App SHALL show next upcoming dose prominently at the top
7. WHEN displaying today's view, THE Mobile_App SHALL show daily adherence percentage with visual progress indicator

### Requirement 8: Patient Dashboard - Adherence Status

**User Story:** As a patient, I want to see my adherence status and trends, so that I can monitor my progress and stay motivated.

#### Acceptance Criteria

1. WHEN displaying adherence status, THE Mobile_App SHALL show today's adherence percentage calculated as (taken_doses / total_scheduled_doses) × 100
2. WHEN displaying adherence status, THE Mobile_App SHALL show weekly adherence percentage for the last 7 days
3. WHEN displaying adherence status, THE Mobile_App SHALL show monthly adherence percentage for the last 30 days
4. WHEN displaying adherence status, THE Mobile_App SHALL use color indicators: green for ≥90%, yellow for 70-89%, red for <70%
5. WHEN displaying adherence trends, THE Mobile_App SHALL show a line graph of daily adherence for the last 7 days
6. WHEN a patient taps adherence status, THE Mobile_App SHALL navigate to detailed adherence view with weekly and monthly graphs
7. THE Mobile_App SHALL exclude PRN medications from adherence calculations

### Requirement 9: Patient Dashboard - Alerts and Notifications

**User Story:** As a patient, I want to see important alerts and notifications on my dashboard, so that I don't miss critical information.

#### Acceptance Criteria

1. WHEN there are pending prescriptions, THE Mobile_App SHALL display an alert banner: "You have N pending prescriptions to review"
2. WHEN there are missed doses today, THE Mobile_App SHALL display an alert banner: "You missed N doses today"
3. WHEN adherence drops below 70%, THE Mobile_App SHALL display an alert banner: "Your adherence is low. Need help staying on track?"
4. WHEN a family member sends a nudge, THE Mobile_App SHALL display the nudge message prominently
5. WHEN displaying alerts, THE Mobile_App SHALL provide quick action buttons to address each alert
6. THE Mobile_App SHALL display unread notification count badge on the notifications icon
7. THE Mobile_App SHALL allow dismissing non-critical alerts


### Requirement 10: Dose Recording - Mark as Taken

**User Story:** As a patient, I want to quickly mark doses as taken, so that my adherence is accurately tracked with minimal effort.

#### Acceptance Criteria

1. WHEN a patient marks a dose as taken, THE Backend_API SHALL create a Dose_Event with status TAKEN_ON_TIME if within grace period
2. WHEN a patient marks a dose as taken after grace period but within 24 hours, THE Backend_API SHALL create a Dose_Event with status TAKEN_LATE
3. WHEN a patient marks a dose as taken, THE Backend_API SHALL record the current timestamp as takenAt
4. WHEN a dose is marked as taken, THE Backend_API SHALL dismiss the active reminder notification
5. WHEN a dose is marked as taken, THE Backend_API SHALL recalculate adherence percentage immediately
6. WHEN a dose is marked as taken, THE Backend_API SHALL create an audit log entry with action type DOSE_TAKEN
7. WHEN a patient attempts to mark a dose more than 24 hours late, THE Backend_API SHALL reject the action with error message
8. THE Mobile_App SHALL provide a confirmation toast: "Dose recorded" after successful marking

### Requirement 11: Dose Recording - Skip Dose

**User Story:** As a patient, I want to skip doses with optional reasons, so that my adherence record reflects intentional decisions.

#### Acceptance Criteria

1. WHEN a patient skips a dose, THE Mobile_App SHALL display a reason selection dialog with options: "Feeling better", "Side effects", "Forgot to refill", "Doctor advised", "Other"
2. WHEN a patient selects "Other", THE Mobile_App SHALL allow entering custom text reason
3. WHEN a patient skips a dose, THE Backend_API SHALL create a Dose_Event with status SKIPPED and record the reason
4. WHEN a dose is skipped, THE Backend_API SHALL record the current timestamp
5. WHEN a dose is skipped, THE Backend_API SHALL dismiss the active reminder notification
6. WHEN a dose is skipped, THE Backend_API SHALL recalculate adherence percentage (skipped counts as non-compliant)
7. WHEN a dose is skipped, THE Backend_API SHALL create an audit log entry with action type DOSE_SKIPPED including reason
8. THE Mobile_App SHALL allow skipping reason to be optional (can skip without reason)

### Requirement 12: Reminder Interaction - Snooze

**User Story:** As a patient, I want to snooze reminders when I'm not ready to take medication immediately, so that I'm reminded again after a short delay.

#### Acceptance Criteria

1. WHEN a patient receives a reminder notification, THE Mobile_App SHALL display snooze options: 5 minutes, 10 minutes, 15 minutes
2. WHEN a patient selects a snooze duration, THE Backend_API SHALL reschedule the reminder for the selected duration from current time
3. WHEN a reminder is snoozed, THE Backend_API SHALL update reminder status to SNOOZED and record snooze timestamp
4. WHEN a snoozed reminder time arrives, THE Backend_API SHALL deliver the notification again
5. WHEN a reminder has been snoozed 3 times, THE Mobile_App SHALL not offer additional snooze options
6. WHEN a reminder is snoozed, THE Mobile_App SHALL display a toast: "Reminder snoozed for N minutes"
7. THE Mobile_App SHALL show snoozed reminders on the dashboard with countdown timer

### Requirement 13: Reminder Configuration

**User Story:** As a patient, I want to configure reminder settings for each medicine, so that reminders fit my personal schedule and preferences.

#### Acceptance Criteria

1. WHEN a patient creates or edits a medicine, THE Mobile_App SHALL allow enabling/disabling reminders
2. WHEN reminders are enabled, THE Mobile_App SHALL allow setting custom reminder times for each dose
3. WHEN reminders are enabled, THE Mobile_App SHALL allow configuring grace period: 10, 20, 30, or 60 minutes
4. WHEN reminders are enabled, THE Mobile_App SHALL allow enabling/disabling repeat reminders
5. WHEN repeat reminders are enabled, THE Mobile_App SHALL send up to 3 repeat notifications before grace period expires
6. WHEN reminder settings are updated, THE Backend_API SHALL regenerate all future reminders with new settings
7. WHEN reminders are disabled for a medicine, THE Backend_API SHALL cancel all pending reminders but continue tracking scheduled doses
8. THE Mobile_App SHALL use default grace period of 30 minutes if not configured

### Requirement 14: Doctor Connection - Search and Request

**User Story:** As a patient, I want to search for doctors and send connection requests, so that I can receive prescriptions from my healthcare providers.

#### Acceptance Criteria

1. WHEN a patient searches for doctors, THE Backend_API SHALL search by doctor name, hospital/clinic, or license number
2. WHEN displaying search results, THE Mobile_App SHALL show doctor name, specialty, hospital/clinic, and verification status
3. WHEN a patient selects a doctor, THE Mobile_App SHALL display doctor profile with full details
4. WHEN a patient sends a connection request, THE Backend_API SHALL create a Connection record with status PENDING
5. WHEN a connection request is sent, THE Backend_API SHALL send a push notification to the doctor
6. WHEN a connection request is sent, THE Backend_API SHALL create an audit log entry with action type CONNECTION_REQUEST
7. THE Mobile_App SHALL prevent sending duplicate connection requests to the same doctor
8. THE Mobile_App SHALL display pending connection requests with status indicator


### Requirement 15: Doctor Connection - Management

**User Story:** As a patient, I want to view and manage my doctor connections, so that I can control who can create prescriptions for me.

#### Acceptance Criteria

1. WHEN a patient views doctor connections, THE Mobile_App SHALL display all connected doctors with connection date and status
2. WHEN displaying doctor connections, THE Mobile_App SHALL show doctor name, specialty, hospital/clinic, and last activity timestamp
3. WHEN a patient views a doctor connection, THE Mobile_App SHALL display connection history from audit logs
4. WHEN a patient views a doctor connection, THE Mobile_App SHALL display all prescriptions created by that doctor
5. WHEN a patient revokes a doctor connection, THE Backend_API SHALL update Connection status to REVOKED
6. WHEN a doctor connection is revoked, THE Backend_API SHALL send a notification to the doctor
7. WHEN a doctor connection is revoked, THE Backend_API SHALL preserve all existing prescriptions from that doctor
8. WHEN a doctor connection is revoked, THE Backend_API SHALL create an audit log entry with action type CONNECTION_REVOKE
9. THE Mobile_App SHALL require confirmation before revoking doctor connections

### Requirement 16: Family Connection - Invitation

**User Story:** As a patient, I want to invite family members to monitor my adherence, so that I have support in taking my medications.

#### Acceptance Criteria

1. WHEN a patient invites a family member, THE Mobile_App SHALL allow selecting permission level: View Only, View + Remind, or View + Manage
2. WHEN a patient invites a family member, THE Backend_API SHALL generate a Connection_Token with 24-hour expiration
3. WHEN a token is generated, THE Mobile_App SHALL display a QR code and alphanumeric short code (8-12 characters)
4. WHEN a token is generated, THE Mobile_App SHALL provide a share button to send the code via messaging apps
5. WHEN a family member scans the QR code or enters the code, THE Backend_API SHALL validate the token
6. WHEN a token is valid, THE Backend_API SHALL create a Connection record with status PENDING
7. WHEN a connection request is created, THE Backend_API SHALL send a push notification to the patient for approval
8. THE Mobile_App SHALL display token expiration countdown timer
9. THE Mobile_App SHALL allow generating new tokens if expired

### Requirement 17: Family Connection - Approval and Management

**User Story:** As a patient, I want to approve family connection requests and manage their permissions, so that I control who can see my medication information.

#### Acceptance Criteria

1. WHEN a family member sends a connection request, THE Mobile_App SHALL display an approval dialog with family member name and requested permission level
2. WHEN approving a connection, THE Mobile_App SHALL allow adjusting the permission level before confirming
3. WHEN a patient approves a connection, THE Backend_API SHALL update Connection status to ACCEPTED
4. WHEN a patient denies a connection, THE Backend_API SHALL update Connection status to REVOKED
5. WHEN a connection is approved, THE Backend_API SHALL send a confirmation notification to the family member
6. WHEN a patient views family connections, THE Mobile_App SHALL display all connected family members with permission levels
7. WHEN a patient views a family connection, THE Mobile_App SHALL allow changing permission level
8. WHEN a patient views a family connection, THE Mobile_App SHALL allow enabling/disabling missed dose alerts for that family member
9. WHEN a patient revokes a family connection, THE Backend_API SHALL immediately remove access and notify the family member
10. THE Backend_API SHALL enforce family connection limits based on subscription tier: FREEMIUM (1), PREMIUM (5), FAMILY_PREMIUM (10)

### Requirement 18: Subscription Management - Tier Display

**User Story:** As a patient, I want to see my current subscription tier and limits, so that I understand what features are available to me.

#### Acceptance Criteria

1. WHEN a patient views subscription settings, THE Mobile_App SHALL display current subscription tier
2. WHEN displaying subscription tier, THE Mobile_App SHALL show tier name, expiration date, and renewal status
3. WHEN displaying subscription limits, THE Mobile_App SHALL show: prescription limit, medicine limit, family connection limit, and storage quota
4. WHEN displaying subscription limits, THE Mobile_App SHALL show current usage for each limit with progress bars
5. WHEN a limit is reached, THE Mobile_App SHALL display upgrade prompt with link to subscription management
6. THE Mobile_App SHALL display feature comparison table for all subscription tiers
7. THE Mobile_App SHALL highlight premium features that are locked for freemium users

### Requirement 19: Subscription Management - Tier Enforcement

**User Story:** As a system, I want to enforce subscription tier limits, so that users receive appropriate features based on their plan.

#### Acceptance Criteria

1. WHEN a FREEMIUM patient attempts to create a second prescription, THE Backend_API SHALL reject the request with error message
2. WHEN a FREEMIUM patient attempts to add a fourth medicine, THE Backend_API SHALL reject the request with error message
3. WHEN a FREEMIUM patient attempts to connect a second family member, THE Backend_API SHALL reject the request with error message
4. WHEN a patient's storage usage exceeds their quota, THE Backend_API SHALL prevent uploading new files
5. WHEN a patient upgrades subscription tier, THE Backend_API SHALL immediately apply new limits
6. WHEN a patient downgrades subscription tier, THE Backend_API SHALL allow existing data to remain but prevent adding new items beyond new limits
7. THE Backend_API SHALL check subscription limits before allowing create operations
8. THE Mobile_App SHALL display clear error messages when limits are reached with upgrade options


### Requirement 20: Offline Mode - Data Storage

**User Story:** As a patient, I want the app to work offline, so that I can track my medications even without internet connectivity.

#### Acceptance Criteria

1. WHEN the app is offline, THE Mobile_App SHALL store all dose events in local SQLite database
2. WHEN the app is offline, THE Mobile_App SHALL store all prescription and medicine changes locally
3. WHEN the app is offline, THE Mobile_App SHALL display all previously synced data from local storage
4. WHEN the app is offline, THE Mobile_App SHALL display an offline indicator in the app header
5. WHEN the app is offline, THE Mobile_App SHALL queue all mutations for sync when connectivity returns
6. WHEN the app is offline, THE Mobile_App SHALL allow marking doses as taken, skipped, or snoozed
7. WHEN the app is offline, THE Mobile_App SHALL allow creating and editing prescriptions and medicines
8. THE Mobile_App SHALL store up to 90 days of historical data locally for offline access

### Requirement 21: Offline Mode - Reminder Delivery

**User Story:** As a patient, I want to receive reminders even when offline, so that I don't miss doses due to connectivity issues.

#### Acceptance Criteria

1. WHEN the app is offline, THE Mobile_App SHALL deliver scheduled reminders using local device notifications
2. WHEN the app is offline, THE Mobile_App SHALL use locally stored reminder schedule to trigger notifications
3. WHEN the app is offline, THE Mobile_App SHALL allow snoozing reminders with local rescheduling
4. WHEN the app is offline, THE Mobile_App SHALL record all dose events locally with offline flag
5. WHEN the app is offline, THE Mobile_App SHALL queue up to 100 pending reminders locally
6. WHEN the local queue exceeds 100 reminders, THE Mobile_App SHALL prioritize nearest scheduled reminders
7. THE Mobile_App SHALL sync reminder schedule from backend every 24 hours when online

### Requirement 22: Offline Mode - Synchronization

**User Story:** As a patient, I want my offline changes to sync automatically when I'm back online, so that my data is always up to date across devices.

#### Acceptance Criteria

1. WHEN connectivity is restored, THE Mobile_App SHALL automatically sync all queued mutations to the Backend_API
2. WHEN syncing dose events, THE Backend_API SHALL validate timestamps and reject events older than 24 hours from scheduled time
3. WHEN syncing, THE Backend_API SHALL resolve conflicts by prioritizing the earliest recorded Dose_Event for a given scheduled dose
4. WHEN syncing prescription changes, THE Backend_API SHALL apply changes in chronological order based on local timestamps
5. WHEN sync completes successfully, THE Mobile_App SHALL clear local queue and update sync status
6. WHEN sync fails, THE Mobile_App SHALL retry with exponential backoff up to 3 attempts
7. WHEN sync fails after 3 attempts, THE Mobile_App SHALL display error message and provide manual retry button
8. WHEN syncing, THE Mobile_App SHALL display sync progress indicator
9. THE Backend_API SHALL create audit log entries for all synced offline actions with offline flag

### Requirement 23: Meal Time Preferences

**User Story:** As a patient, I want to configure my meal times, so that medication reminders align with my daily routine.

#### Acceptance Criteria

1. WHEN a patient configures meal times, THE Mobile_App SHALL allow setting morning meal time range (e.g., "6-7 AM")
2. WHEN a patient configures meal times, THE Mobile_App SHALL allow setting afternoon meal time range (e.g., "12-1 PM")
3. WHEN a patient configures meal times, THE Mobile_App SHALL allow setting night meal time range (e.g., "6-7 PM")
4. WHEN meal times are not configured, THE Backend_API SHALL use default Cambodia timezone presets: Morning (07:00 AM), Noon (12:00 PM), Evening (06:00 PM), Night (09:00 PM)
5. WHEN a patient updates meal times, THE Backend_API SHALL regenerate all future reminders using new meal times
6. WHEN calculating reminder times, THE Backend_API SHALL use the midpoint of the meal time range
7. WHEN a medicine specifies "before meal" timing, THE Backend_API SHALL schedule reminder 30 minutes before meal time
8. WHEN a medicine specifies "after meal" timing, THE Backend_API SHALL schedule reminder 30 minutes after meal time
9. THE Mobile_App SHALL display meal time preferences in settings with visual time picker

### Requirement 24: Multi-Language Support

**User Story:** As a patient, I want to use the app in my preferred language, so that I can understand all information clearly.

#### Acceptance Criteria

1. WHEN a patient selects language preference, THE Mobile_App SHALL support Khmer and English
2. WHEN language is changed, THE Mobile_App SHALL update all UI text immediately without restart
3. WHEN language is changed, THE Backend_API SHALL send all future notifications in the selected language
4. WHEN displaying medicine names, THE Mobile_App SHALL show both English and Khmer names if available
5. WHEN displaying dose instructions, THE Mobile_App SHALL translate standard instructions to selected language
6. WHEN a patient creates a prescription, THE Mobile_App SHALL allow entering medicine names in either language
7. THE Mobile_App SHALL use Khmer as default language for Cambodia-based users
8. THE Backend_API SHALL store language preference in User table and use it for all communications


### Requirement 25: Security - Data Access Control

**User Story:** As a patient, I want my medical data to be secure and private, so that only authorized people can access my information.

#### Acceptance Criteria

1. WHEN a patient creates data, THE Backend_API SHALL set the patient as the owner with full access rights
2. WHEN a doctor attempts to access patient data, THE Backend_API SHALL verify an active ACCEPTED connection exists
3. WHEN a family member attempts to access patient data, THE Backend_API SHALL verify an active ACCEPTED connection with appropriate permission level
4. WHEN a user attempts to access data they don't own, THE Backend_API SHALL return HTTP 403 Forbidden error
5. WHEN a connection is revoked, THE Backend_API SHALL immediately remove access for the revoked user
6. WHEN a patient deletes their account, THE Backend_API SHALL cascade delete all owned data
7. THE Backend_API SHALL log all data access attempts in audit log with user ID, resource ID, and timestamp
8. THE Backend_API SHALL encrypt sensitive data at rest in the database

### Requirement 26: Security - Authentication and Authorization

**User Story:** As a patient, I want secure authentication, so that only I can access my account.

#### Acceptance Criteria

1. WHEN a patient logs in, THE Backend_API SHALL verify credentials using bcrypt password hashing
2. WHEN a patient logs in successfully, THE Backend_API SHALL issue a JWT access token with 15-minute expiration
3. WHEN a patient logs in successfully, THE Backend_API SHALL issue a JWT refresh token with 7-day expiration
4. WHEN a patient enables "remember me", THE Backend_API SHALL extend refresh token expiration to 30 days
5. WHEN an access token expires, THE Mobile_App SHALL automatically refresh using the refresh token
6. WHEN a patient logs out, THE Backend_API SHALL invalidate all tokens for that session
7. WHEN a patient changes password, THE Backend_API SHALL invalidate all existing tokens
8. WHEN login fails 5 times, THE Backend_API SHALL lock the account for 30 minutes
9. THE Backend_API SHALL support optional 4-digit PIN code for quick app access after initial login

### Requirement 27: Security - Data Privacy and Consent

**User Story:** As a patient, I want explicit control over who can see my data, so that I maintain privacy and comply with my preferences.

#### Acceptance Criteria

1. WHEN a patient connects with a doctor or family member, THE Mobile_App SHALL display clear consent dialog explaining what data will be shared
2. WHEN a patient grants access, THE Backend_API SHALL record consent in audit log with timestamp
3. WHEN a patient revokes access, THE Backend_API SHALL immediately stop sharing data and record revocation in audit log
4. WHEN a doctor views patient data, THE Backend_API SHALL log the access in audit log with action type DATA_ACCESS
5. WHEN a family member views patient data, THE Backend_API SHALL log the access in audit log with action type DATA_ACCESS
6. WHEN a patient views audit log, THE Mobile_App SHALL display all access events with timestamps and accessor names
7. THE Mobile_App SHALL allow patients to export their complete data in JSON format
8. THE Mobile_App SHALL allow patients to request account deletion with 30-day grace period

### Requirement 28: Performance - Response Times

**User Story:** As a patient, I want the app to respond quickly, so that I can efficiently manage my medications.

#### Acceptance Criteria

1. WHEN a patient opens the app, THE Mobile_App SHALL display the Patient_Dashboard within 2 seconds
2. WHEN a patient marks a dose as taken, THE Mobile_App SHALL update the UI within 500 milliseconds
3. WHEN a patient views prescription details, THE Mobile_App SHALL load and display data within 1 second
4. WHEN a patient searches for doctors, THE Backend_API SHALL return results within 1 second
5. WHEN a reminder is triggered, THE Backend_API SHALL deliver the notification within 300 milliseconds
6. WHEN calculating adherence, THE Backend_API SHALL return results within 200 milliseconds
7. THE Backend_API SHALL cache frequently accessed data in Redis with 5-minute TTL
8. THE Mobile_App SHALL implement pagination for lists with more than 50 items

### Requirement 29: Performance - Reminder Reliability

**User Story:** As a patient, I want reminders to be delivered reliably and on time, so that I never miss a dose due to system issues.

#### Acceptance Criteria

1. WHEN a scheduled reminder time arrives, THE Backend_API SHALL trigger the notification within 300 milliseconds
2. WHEN processing reminder delivery, THE Backend_API SHALL achieve 99.9% delivery reliability
3. WHEN push notification delivery fails, THE Backend_API SHALL retry up to 3 times with exponential backoff
4. WHEN the Backend_API is unavailable, THE Mobile_App SHALL deliver reminders using local notifications
5. WHEN the reminder queue is unavailable, THE Backend_API SHALL fall back to database polling with 1-minute intervals
6. WHEN database queries timeout, THE Backend_API SHALL retry with exponential backoff up to 3 times
7. THE Backend_API SHALL process at least 10,000 reminders per minute under load
8. THE Backend_API SHALL monitor reminder delivery success rate and alert administrators if below 99%


### Requirement 30: User Experience - Confirmation Dialogs

**User Story:** As a patient, I want confirmation dialogs before destructive actions, so that I don't accidentally delete important data.

#### Acceptance Criteria

1. WHEN a patient attempts to delete a prescription, THE Mobile_App SHALL display confirmation dialog: "Delete this prescription? This will remove all medicines and dose history."
2. WHEN a patient attempts to delete a medicine, THE Mobile_App SHALL display confirmation dialog: "Delete this medicine? This will remove all scheduled doses."
3. WHEN a patient attempts to revoke a doctor connection, THE Mobile_App SHALL display confirmation dialog: "Remove connection with [Doctor Name]? They will no longer be able to send you prescriptions."
4. WHEN a patient attempts to revoke a family connection, THE Mobile_App SHALL display confirmation dialog: "Remove [Family Member Name]? They will no longer see your medication information."
5. WHEN a patient attempts to pause a prescription, THE Mobile_App SHALL display confirmation dialog: "Pause this prescription? Reminders will stop until you resume."
6. ALL confirmation dialogs SHALL provide "Cancel" and "Confirm" buttons with clear labeling
7. THE Mobile_App SHALL use destructive button styling (red) for confirm buttons on delete actions

### Requirement 31: User Experience - Conflict Warnings

**User Story:** As a patient, I want warnings about conflicting medication schedules, so that I can avoid taking multiple medicines at the exact same time.

#### Acceptance Criteria

1. WHEN a patient adds a medicine with schedule times that conflict with existing medicines, THE Mobile_App SHALL display a warning banner
2. WHEN displaying conflict warnings, THE Mobile_App SHALL show which medicines have conflicting times
3. WHEN displaying conflict warnings, THE Mobile_App SHALL allow proceeding with the conflict or adjusting times
4. WHEN multiple medicines are scheduled for the same time, THE Mobile_App SHALL group them together on the dashboard
5. WHEN displaying grouped doses, THE Mobile_App SHALL allow marking all as taken with a single action
6. THE Mobile_App SHALL define conflict as medicines scheduled within 5 minutes of each other
7. THE Mobile_App SHALL not warn about conflicts for medicines that are meant to be taken together (same prescription)

### Requirement 32: User Experience - Empty States

**User Story:** As a patient, I want helpful empty state messages, so that I know what to do when I have no data.

#### Acceptance Criteria

1. WHEN a patient has no prescriptions, THE Mobile_App SHALL display empty state: "No prescriptions yet. Add your first prescription to start tracking."
2. WHEN a patient has no active medicines today, THE Mobile_App SHALL display empty state: "No medicines scheduled for today. Enjoy your day!"
3. WHEN a patient has no doctor connections, THE Mobile_App SHALL display empty state: "Connect with your doctor to receive prescriptions directly in the app."
4. WHEN a patient has no family connections, THE Mobile_App SHALL display empty state: "Invite family members to help you stay on track with your medications."
5. WHEN a patient has no notifications, THE Mobile_App SHALL display empty state: "You're all caught up! No new notifications."
6. ALL empty states SHALL include a primary action button to add the missing item
7. ALL empty states SHALL include helpful illustrations or icons

### Requirement 33: API Endpoints - Prescription Management

**User Story:** As a backend developer, I want well-defined API endpoints for prescription management, so that the mobile app can perform all necessary operations.

#### Acceptance Criteria

1. THE Backend_API SHALL provide POST /api/prescriptions endpoint to create prescriptions
2. THE Backend_API SHALL provide GET /api/prescriptions endpoint to list prescriptions with filtering by status
3. THE Backend_API SHALL provide GET /api/prescriptions/:id endpoint to get prescription details
4. THE Backend_API SHALL provide PATCH /api/prescriptions/:id endpoint to update prescription (patient-created only)
5. THE Backend_API SHALL provide DELETE /api/prescriptions/:id endpoint to delete prescription
6. THE Backend_API SHALL provide POST /api/prescriptions/:id/confirm endpoint to confirm doctor-issued prescription
7. THE Backend_API SHALL provide POST /api/prescriptions/:id/reject endpoint to reject doctor-issued prescription
8. THE Backend_API SHALL provide POST /api/prescriptions/:id/pause endpoint to pause active prescription
9. THE Backend_API SHALL provide POST /api/prescriptions/:id/resume endpoint to resume paused prescription
10. ALL prescription endpoints SHALL require authentication and validate ownership or connection

### Requirement 34: API Endpoints - Medicine Management

**User Story:** As a backend developer, I want well-defined API endpoints for medicine management, so that the mobile app can perform all necessary operations.

#### Acceptance Criteria

1. THE Backend_API SHALL provide POST /api/prescriptions/:prescriptionId/medicines endpoint to add medicine
2. THE Backend_API SHALL provide GET /api/prescriptions/:prescriptionId/medicines endpoint to list medicines
3. THE Backend_API SHALL provide GET /api/medicines/:id endpoint to get medicine details
4. THE Backend_API SHALL provide PATCH /api/medicines/:id endpoint to update medicine (before first dose only)
5. THE Backend_API SHALL provide DELETE /api/medicines/:id endpoint to delete medicine
6. THE Backend_API SHALL provide GET /api/medicines/:id/doses endpoint to get dose events for medicine
7. THE Backend_API SHALL provide GET /api/medicines/archived endpoint to list archived medicines
8. ALL medicine endpoints SHALL require authentication and validate prescription ownership


### Requirement 35: API Endpoints - Dose Event Management

**User Story:** As a backend developer, I want well-defined API endpoints for dose event management, so that the mobile app can track medication adherence.

#### Acceptance Criteria

1. THE Backend_API SHALL provide POST /api/doses/:id/taken endpoint to mark dose as taken
2. THE Backend_API SHALL provide POST /api/doses/:id/skip endpoint to mark dose as skipped with optional reason
3. THE Backend_API SHALL provide GET /api/doses/today endpoint to get today's scheduled doses
4. THE Backend_API SHALL provide GET /api/doses/upcoming endpoint to get next upcoming dose
5. THE Backend_API SHALL provide GET /api/doses/history endpoint to get dose history with date range filtering
6. THE Backend_API SHALL provide POST /api/doses/sync endpoint to sync offline dose events
7. ALL dose endpoints SHALL require authentication and validate patient ownership

### Requirement 36: API Endpoints - Adherence Tracking

**User Story:** As a backend developer, I want well-defined API endpoints for adherence tracking, so that the mobile app can display adherence metrics.

#### Acceptance Criteria

1. THE Backend_API SHALL provide GET /api/adherence/today endpoint to get today's adherence percentage
2. THE Backend_API SHALL provide GET /api/adherence/weekly endpoint to get weekly adherence percentage
3. THE Backend_API SHALL provide GET /api/adherence/monthly endpoint to get monthly adherence percentage
4. THE Backend_API SHALL provide GET /api/adherence/trends endpoint to get daily adherence data for graphing
5. THE Backend_API SHALL provide GET /api/adherence/prescription/:id endpoint to get adherence for specific prescription
6. ALL adherence endpoints SHALL cache results in Redis with 5-minute TTL
7. ALL adherence endpoints SHALL exclude PRN medications from calculations

### Requirement 37: API Endpoints - Connection Management

**User Story:** As a backend developer, I want well-defined API endpoints for connection management, so that the mobile app can manage doctor and family connections.

#### Acceptance Criteria

1. THE Backend_API SHALL provide POST /api/connections/request endpoint to send connection request
2. THE Backend_API SHALL provide POST /api/connections/token endpoint to generate family connection token
3. THE Backend_API SHALL provide POST /api/connections/validate-token endpoint to validate connection token
4. THE Backend_API SHALL provide POST /api/connections/:id/accept endpoint to accept connection request
5. THE Backend_API SHALL provide POST /api/connections/:id/reject endpoint to reject connection request
6. THE Backend_API SHALL provide POST /api/connections/:id/revoke endpoint to revoke connection
7. THE Backend_API SHALL provide PATCH /api/connections/:id/permission endpoint to update permission level
8. THE Backend_API SHALL provide GET /api/connections/doctors endpoint to list doctor connections
9. THE Backend_API SHALL provide GET /api/connections/family endpoint to list family connections
10. THE Backend_API SHALL provide GET /api/doctors/search endpoint to search for doctors

### Requirement 38: API Endpoints - Reminder Management

**User Story:** As a backend developer, I want well-defined API endpoints for reminder management, so that the mobile app can configure and interact with reminders.

#### Acceptance Criteria

1. THE Backend_API SHALL provide POST /api/reminders/:id/snooze endpoint to snooze reminder with duration
2. THE Backend_API SHALL provide POST /api/reminders/:id/dismiss endpoint to dismiss reminder
3. THE Backend_API SHALL provide GET /api/reminders/history endpoint to get reminder history
4. THE Backend_API SHALL provide PATCH /api/medicines/:id/reminders endpoint to update reminder settings
5. THE Backend_API SHALL provide GET /api/reminders/pending endpoint to get pending reminders for offline sync
6. ALL reminder endpoints SHALL integrate with the Reminder_System from reminder-system-adherence-tracking spec

### Requirement 39: API Endpoints - User Profile and Settings

**User Story:** As a backend developer, I want well-defined API endpoints for user profile and settings, so that the mobile app can manage patient preferences.

#### Acceptance Criteria

1. THE Backend_API SHALL provide GET /api/profile endpoint to get patient profile
2. THE Backend_API SHALL provide PATCH /api/profile endpoint to update patient profile
3. THE Backend_API SHALL provide PATCH /api/settings/language endpoint to update language preference
4. THE Backend_API SHALL provide PATCH /api/settings/theme endpoint to update theme preference
5. THE Backend_API SHALL provide PATCH /api/settings/meal-times endpoint to update meal time preferences
6. THE Backend_API SHALL provide GET /api/settings/meal-times endpoint to get meal time preferences
7. THE Backend_API SHALL provide PATCH /api/settings/grace-period endpoint to update grace period
8. THE Backend_API SHALL provide GET /api/audit-log endpoint to get patient's audit log with pagination

### Requirement 40: API Endpoints - Subscription Management

**User Story:** As a backend developer, I want well-defined API endpoints for subscription management, so that the mobile app can display and manage subscriptions.

#### Acceptance Criteria

1. THE Backend_API SHALL provide GET /api/subscription endpoint to get current subscription details
2. THE Backend_API SHALL provide GET /api/subscription/limits endpoint to get subscription limits and current usage
3. THE Backend_API SHALL provide POST /api/subscription/upgrade endpoint to upgrade subscription tier
4. THE Backend_API SHALL provide POST /api/subscription/downgrade endpoint to downgrade subscription tier
5. THE Backend_API SHALL provide GET /api/subscription/features endpoint to get feature comparison for all tiers
6. ALL subscription endpoints SHALL enforce tier limits before allowing operations


### Requirement 41: Data Models - Prescription Model

**User Story:** As a backend developer, I want a well-defined prescription data model, so that prescription data is structured consistently.

#### Acceptance Criteria

1. THE Backend_API SHALL use the Prescription model from das-tern-backend-database spec with fields: id, patientId, doctorId, patientName, patientGender, patientAge, symptoms, status, currentVersion, isUrgent, urgentReason, createdAt, updatedAt
2. THE Prescription model SHALL use enum for status: DRAFT, ACTIVE, PAUSED, INACTIVE
3. THE Prescription model SHALL have foreign key patientId referencing User(id) with CASCADE delete
4. THE Prescription model SHALL have foreign key doctorId referencing User(id) with SET NULL on delete
5. THE Prescription model SHALL support version control through PrescriptionVersion table
6. THE Prescription model SHALL include computed field for medicine count
7. THE Prescription model SHALL include computed field for adherence percentage

### Requirement 42: Data Models - Medicine Model

**User Story:** As a backend developer, I want a well-defined medicine data model, so that medicine data is structured consistently.

#### Acceptance Criteria

1. THE Backend_API SHALL use the Medication model from das-tern-backend-database spec with fields: id, prescriptionId, rowNumber, medicineName, medicineNameKhmer, morningDosage, daytimeDosage, nightDosage, imageUrl, frequency, timing, createdAt, updatedAt
2. THE Medication model SHALL use JSONB for dosage fields storing: amount, unit, beforeMeal flag
3. THE Medication model SHALL have foreign key prescriptionId referencing Prescription(id) with CASCADE delete
4. THE Medication model SHALL support PRN medications with flexible timing
5. THE Medication model SHALL include computed field for total scheduled doses
6. THE Medication model SHALL include computed field for doses taken

### Requirement 43: Data Models - Dose Event Model

**User Story:** As a backend developer, I want a well-defined dose event data model, so that adherence tracking data is structured consistently.

#### Acceptance Criteria

1. THE Backend_API SHALL use the DoseEvent model from das-tern-backend-database spec with fields: id, prescriptionId, medicationId, patientId, scheduledTime, timePeriod, status, takenAt, skipReason, reminderTime, wasOffline, createdAt, updatedAt
2. THE DoseEvent model SHALL use enum for timePeriod: DAYTIME, NIGHT
3. THE DoseEvent model SHALL use enum for status: DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED
4. THE DoseEvent model SHALL have foreign keys with CASCADE delete for prescriptionId, medicationId, and patientId
5. THE DoseEvent model SHALL use TIMESTAMP WITH TIME ZONE for scheduledTime and takenAt
6. THE DoseEvent model SHALL include wasOffline flag to track offline-recorded events

### Requirement 44: Data Models - Connection Model

**User Story:** As a backend developer, I want a well-defined connection data model, so that user relationships are structured consistently.

#### Acceptance Criteria

1. THE Backend_API SHALL use the Connection model from das-tern-backend-database spec with fields: id, initiatorId, recipientId, status, permissionLevel, requestedAt, acceptedAt, revokedAt, createdAt, updatedAt
2. THE Connection model SHALL use enum for status: PENDING, ACCEPTED, REVOKED
3. THE Connection model SHALL use enum for permissionLevel: NOT_ALLOWED, REQUEST, SELECTED, ALLOWED
4. THE Connection model SHALL enforce unique constraint on (initiatorId, recipientId) pair
5. THE Connection model SHALL have foreign keys with CASCADE delete for initiatorId and recipientId
6. THE Connection model SHALL support metadata JSON field for storing alert preferences

### Requirement 45: Data Models - Audit Log Model

**User Story:** As a backend developer, I want a well-defined audit log data model, so that all actions are tracked consistently.

#### Acceptance Criteria

1. THE Backend_API SHALL use the AuditLog model from das-tern-backend-database spec with fields: id, actorId, actorRole, actionType, resourceType, resourceId, details, ipAddress, createdAt
2. THE AuditLog model SHALL use enum for actionType including: CONNECTION_REQUEST, CONNECTION_ACCEPT, CONNECTION_REVOKE, PERMISSION_CHANGE, PRESCRIPTION_CREATE, PRESCRIPTION_UPDATE, PRESCRIPTION_CONFIRM, DOSE_TAKEN, DOSE_SKIPPED, DOSE_MISSED, DATA_ACCESS, NOTIFICATION_SENT
3. THE AuditLog model SHALL use JSONB for details field storing action-specific metadata
4. THE AuditLog model SHALL be insert-only (no updates or deletes allowed)
5. THE AuditLog model SHALL have foreign key actorId with SET NULL on delete to preserve audit trail

### Requirement 46: Integration - Reminder System

**User Story:** As a backend developer, I want seamless integration with the reminder system, so that medication reminders work correctly.

#### Acceptance Criteria

1. WHEN a medicine is created, THE Backend_API SHALL call the Reminder_System to generate reminders for all scheduled doses
2. WHEN a medicine schedule is updated, THE Backend_API SHALL call the Reminder_System to regenerate reminders
3. WHEN a medicine is deleted, THE Backend_API SHALL call the Reminder_System to cancel all pending reminders
4. WHEN a dose is marked as taken or skipped, THE Backend_API SHALL call the Reminder_System to dismiss active reminders
5. WHEN a reminder is snoozed, THE Backend_API SHALL call the Reminder_System to reschedule the reminder
6. THE Backend_API SHALL use the Reminder_System endpoints defined in reminder-system-adherence-tracking spec
7. THE Backend_API SHALL handle Reminder_System failures gracefully with retry logic


### Requirement 47: Integration - Family Connection System

**User Story:** As a backend developer, I want seamless integration with the family connection system, so that family members can monitor patient adherence.

#### Acceptance Criteria

1. WHEN a patient generates a family connection token, THE Backend_API SHALL use the token generation logic from family-connection-missed-dose-alert spec
2. WHEN a family member validates a token, THE Backend_API SHALL use the token validation logic from family-connection-missed-dose-alert spec
3. WHEN a dose is marked as missed, THE Backend_API SHALL trigger missed dose alerts to family members as defined in family-connection-missed-dose-alert spec
4. WHEN a family member sends a nudge, THE Backend_API SHALL use the nudge functionality from family-connection-missed-dose-alert spec
5. THE Backend_API SHALL enforce family connection limits based on subscription tier
6. THE Backend_API SHALL respect family alert preferences stored in Connection metadata

### Requirement 48: Integration - Doctor Dashboard

**User Story:** As a backend developer, I want seamless integration with the doctor dashboard, so that doctors can monitor patient adherence.

#### Acceptance Criteria

1. WHEN a doctor views patient data, THE Backend_API SHALL provide the same data structure used by doctor-dashboard spec
2. WHEN a doctor creates a prescription, THE Backend_API SHALL follow the prescription creation workflow from doctor-dashboard spec
3. WHEN a patient confirms a doctor prescription, THE Backend_API SHALL notify the doctor as defined in doctor-dashboard spec
4. WHEN a patient's adherence changes, THE Backend_API SHALL update the doctor's view in real-time
5. THE Backend_API SHALL enforce doctor connection requirements before allowing prescription creation
6. THE Backend_API SHALL log all doctor access to patient data in audit log

### Requirement 49: Mobile UI - Patient Dashboard Screen

**User Story:** As a mobile developer, I want a well-defined patient dashboard UI, so that patients have a clear home screen.

#### Acceptance Criteria

1. THE Mobile_App SHALL display Patient_Dashboard as the home screen after login
2. THE dashboard SHALL have sections: Today's Medicines, Next Dose, Adherence Status, Alerts
3. THE dashboard SHALL use card-based layout with clear visual hierarchy
4. THE dashboard SHALL display loading skeleton while fetching data
5. THE dashboard SHALL support pull-to-refresh gesture
6. THE dashboard SHALL display offline indicator when not connected
7. THE dashboard SHALL use color coding: green for taken, yellow for due, red for missed, gray for skipped
8. THE dashboard SHALL display floating action button for quick dose marking

### Requirement 50: Mobile UI - Prescription List Screen

**User Story:** As a mobile developer, I want a well-defined prescription list UI, so that patients can easily browse their prescriptions.

#### Acceptance Criteria

1. THE Mobile_App SHALL display prescription list with tabs: Active, Pending, Paused, Completed
2. EACH prescription card SHALL display: title, doctor name, start date, medicine count, adherence percentage
3. THE prescription list SHALL support search by prescription title or doctor name
4. THE prescription list SHALL support filtering by date range
5. THE prescription list SHALL display empty state when no prescriptions exist
6. THE prescription list SHALL support swipe actions: view details, pause/resume, delete
7. THE prescription list SHALL display badge count on Pending tab

### Requirement 51: Mobile UI - Prescription Detail Screen

**User Story:** As a mobile developer, I want a well-defined prescription detail UI, so that patients can view complete prescription information.

#### Acceptance Criteria

1. THE Mobile_App SHALL display prescription detail with sections: Overview, Medicines, Schedule, History
2. THE overview section SHALL display: title, doctor name, dates, diagnosis, notes, adherence
3. THE medicines section SHALL display list of all medicines with dosage and schedule
4. THE schedule section SHALL display calendar view of all scheduled doses
5. THE history section SHALL display all dose events with timestamps and status
6. THE detail screen SHALL display edit button only for patient-created prescriptions
7. THE detail screen SHALL display pause/resume button for active prescriptions
8. THE detail screen SHALL display share button to export prescription as PDF

### Requirement 52: Mobile UI - Medicine Form Screen

**User Story:** As a mobile developer, I want a well-defined medicine form UI, so that patients can easily add and edit medicines.

#### Acceptance Criteria

1. THE Mobile_App SHALL display medicine form with sections: Basic Info, Dosage, Schedule, Duration
2. THE basic info section SHALL have fields: medicine name, form (dropdown), instructions (text area)
3. THE dosage section SHALL have fields: amount (number), unit (dropdown), before/after meal (toggle)
4. THE schedule section SHALL have fields: frequency (dropdown), schedule times (time pickers), PRN toggle
5. THE duration section SHALL have fields: duration type (dropdown), number of days or end date
6. THE form SHALL validate all required fields before allowing submission
7. THE form SHALL display error messages inline below each field
8. THE form SHALL support both Khmer and English input for medicine names


### Requirement 53: Mobile UI - Adherence Screen

**User Story:** As a mobile developer, I want a well-defined adherence UI, so that patients can visualize their medication adherence.

#### Acceptance Criteria

1. THE Mobile_App SHALL display adherence screen with tabs: Today, Week, Month
2. THE today tab SHALL display: percentage, doses taken/total, list of all today's doses with status
3. THE week tab SHALL display: weekly percentage, daily percentages, line graph of daily adherence
4. THE month tab SHALL display: monthly percentage, weekly percentages, bar graph of weekly adherence
5. THE adherence screen SHALL use color indicators: green (≥90%), yellow (70-89%), red (<70%)
6. THE adherence screen SHALL display motivational messages based on adherence level
7. THE adherence screen SHALL allow filtering by prescription
8. THE adherence screen SHALL display streak counter for consecutive days with 100% adherence

### Requirement 54: Mobile UI - Connections Screen

**User Story:** As a mobile developer, I want a well-defined connections UI, so that patients can manage their doctor and family connections.

#### Acceptance Criteria

1. THE Mobile_App SHALL display connections screen with tabs: Doctors, Family
2. THE doctors tab SHALL display list of connected doctors with specialty and hospital
3. THE family tab SHALL display list of connected family members with permission level
4. EACH connection card SHALL display: name, role, connection date, status, last activity
5. THE connections screen SHALL display pending requests with accept/reject buttons
6. THE connections screen SHALL support search by name
7. THE connections screen SHALL display floating action button to add new connection
8. THE connections screen SHALL display empty state with call-to-action when no connections exist

### Requirement 55: Mobile UI - Settings Screen

**User Story:** As a mobile developer, I want a well-defined settings UI, so that patients can configure their preferences.

#### Acceptance Criteria

1. THE Mobile_App SHALL display settings screen with sections: Profile, Preferences, Notifications, Subscription, Privacy, About
2. THE profile section SHALL allow editing: name, phone, email, date of birth, gender
3. THE preferences section SHALL allow configuring: language, theme, meal times, grace period
4. THE notifications section SHALL allow enabling/disabling: reminders, missed dose alerts, family alerts
5. THE subscription section SHALL display: current tier, limits, usage, upgrade button
6. THE privacy section SHALL allow: viewing audit log, exporting data, deleting account
7. THE about section SHALL display: app version, terms of service, privacy policy, contact support
8. THE settings screen SHALL save changes immediately without requiring save button

### Requirement 56: Mobile UI - Notification Handling

**User Story:** As a mobile developer, I want well-defined notification handling, so that patients receive and interact with notifications correctly.

#### Acceptance Criteria

1. WHEN a reminder notification is received, THE Mobile_App SHALL display notification with medicine name, dosage, and scheduled time
2. WHEN a reminder notification is tapped, THE Mobile_App SHALL navigate to today's dashboard with the dose highlighted
3. WHEN a reminder notification is displayed, THE Mobile_App SHALL provide action buttons: "Mark as Taken", "Snooze", "Skip"
4. WHEN a prescription notification is received, THE Mobile_App SHALL display notification with prescription title and doctor name
5. WHEN a prescription notification is tapped, THE Mobile_App SHALL navigate to prescription detail screen
6. WHEN a family alert notification is received, THE Mobile_App SHALL display notification with family member name and message
7. WHEN a family alert notification is tapped, THE Mobile_App SHALL navigate to the relevant dose event
8. THE Mobile_App SHALL group multiple notifications by type and display summary
9. THE Mobile_App SHALL support notification channels for different notification types
10. THE Mobile_App SHALL respect system notification settings and do-not-disturb mode

### Requirement 57: Mobile UI - Offline Indicator

**User Story:** As a mobile developer, I want a clear offline indicator, so that patients know when they're working offline.

#### Acceptance Criteria

1. WHEN the app is offline, THE Mobile_App SHALL display a banner at the top: "You're offline. Changes will sync when connected."
2. WHEN the app is syncing, THE Mobile_App SHALL display a banner: "Syncing your data..."
3. WHEN sync completes, THE Mobile_App SHALL display a toast: "All changes synced"
4. WHEN sync fails, THE Mobile_App SHALL display a banner: "Sync failed. Tap to retry."
5. THE offline indicator SHALL be dismissible but reappear on screen changes
6. THE offline indicator SHALL use distinct color (orange) to stand out
7. THE Mobile_App SHALL display sync status icon in the app header

### Requirement 58: Mobile UI - Accessibility

**User Story:** As a mobile developer, I want the app to be accessible, so that all patients can use it regardless of abilities.

#### Acceptance Criteria

1. THE Mobile_App SHALL support screen readers with appropriate labels for all interactive elements
2. THE Mobile_App SHALL ensure all touch targets meet minimum size requirements (44x44 points)
3. THE Mobile_App SHALL support dynamic text sizing based on system settings
4. THE Mobile_App SHALL provide sufficient color contrast ratios (WCAG AA standard)
5. THE Mobile_App SHALL support both light and dark themes
6. THE Mobile_App SHALL provide alternative text for all images and icons
7. THE Mobile_App SHALL support keyboard navigation for all interactive elements
8. THE Mobile_App SHALL announce important state changes to screen readers


### Requirement 59: Error Handling - User-Friendly Messages

**User Story:** As a patient, I want clear error messages, so that I understand what went wrong and how to fix it.

#### Acceptance Criteria

1. WHEN a network error occurs, THE Mobile_App SHALL display: "Connection failed. Please check your internet and try again."
2. WHEN a validation error occurs, THE Mobile_App SHALL display field-specific error messages below each field
3. WHEN a subscription limit is reached, THE Mobile_App SHALL display: "You've reached your [limit type] limit. Upgrade to continue."
4. WHEN authentication fails, THE Mobile_App SHALL display: "Invalid credentials. Please try again."
5. WHEN a server error occurs, THE Mobile_App SHALL display: "Something went wrong. Please try again later."
6. WHEN a conflict occurs, THE Mobile_App SHALL display: "This action conflicts with existing data. Please review and try again."
7. ALL error messages SHALL be translated to the user's preferred language
8. ALL error messages SHALL provide actionable next steps when possible

### Requirement 60: Error Handling - Retry Logic

**User Story:** As a patient, I want automatic retry for failed operations, so that temporary issues don't require manual intervention.

#### Acceptance Criteria

1. WHEN a network request fails, THE Mobile_App SHALL retry up to 3 times with exponential backoff
2. WHEN push notification delivery fails, THE Backend_API SHALL retry up to 3 times with exponential backoff
3. WHEN database query times out, THE Backend_API SHALL retry with exponential backoff up to 3 times
4. WHEN sync fails, THE Mobile_App SHALL retry automatically when connectivity is restored
5. WHEN retry attempts are exhausted, THE Mobile_App SHALL display error message with manual retry button
6. THE Mobile_App SHALL log all retry attempts for debugging
7. THE Mobile_App SHALL not retry operations that fail due to validation errors

### Requirement 61: Testing - Unit Test Coverage

**User Story:** As a developer, I want comprehensive unit test coverage, so that individual components work correctly.

#### Acceptance Criteria

1. THE Backend_API SHALL have unit tests for all API endpoints with minimum 80% code coverage
2. THE Backend_API SHALL have unit tests for all data models and validation logic
3. THE Backend_API SHALL have unit tests for all business logic functions
4. THE Mobile_App SHALL have unit tests for all state management logic
5. THE Mobile_App SHALL have unit tests for all data transformation functions
6. THE Mobile_App SHALL have unit tests for all validation logic
7. ALL unit tests SHALL use mocking for external dependencies
8. ALL unit tests SHALL run in under 5 minutes total

### Requirement 62: Testing - Integration Test Coverage

**User Story:** As a developer, I want integration tests, so that components work correctly together.

#### Acceptance Criteria

1. THE Backend_API SHALL have integration tests for all API endpoint workflows
2. THE Backend_API SHALL have integration tests for database operations with real database
3. THE Backend_API SHALL have integration tests for authentication and authorization flows
4. THE Backend_API SHALL have integration tests for reminder system integration
5. THE Mobile_App SHALL have integration tests for navigation flows
6. THE Mobile_App SHALL have integration tests for offline sync workflows
7. ALL integration tests SHALL use test database and test data
8. ALL integration tests SHALL clean up test data after execution

### Requirement 63: Testing - End-to-End Test Coverage

**User Story:** As a developer, I want end-to-end tests, so that critical user flows work correctly.

#### Acceptance Criteria

1. THE system SHALL have E2E tests for: user registration and login flow
2. THE system SHALL have E2E tests for: manual prescription creation flow
3. THE system SHALL have E2E tests for: doctor prescription confirmation flow
4. THE system SHALL have E2E tests for: dose marking flow (taken, skipped)
5. THE system SHALL have E2E tests for: reminder delivery and interaction flow
6. THE system SHALL have E2E tests for: doctor connection flow
7. THE system SHALL have E2E tests for: family connection flow
8. THE system SHALL have E2E tests for: offline mode and sync flow
9. ALL E2E tests SHALL run against staging environment
10. ALL E2E tests SHALL use realistic test data

### Requirement 64: Monitoring - Application Metrics

**User Story:** As a system administrator, I want application metrics, so that I can monitor system health and performance.

#### Acceptance Criteria

1. THE Backend_API SHALL track and log: request count, response time, error rate
2. THE Backend_API SHALL track and log: reminder delivery success rate
3. THE Backend_API SHALL track and log: database query performance
4. THE Backend_API SHALL track and log: cache hit/miss rates
5. THE Backend_API SHALL track and log: authentication success/failure rates
6. THE Backend_API SHALL expose metrics endpoint for monitoring tools
7. THE Backend_API SHALL alert administrators when error rate exceeds 5%
8. THE Backend_API SHALL alert administrators when reminder delivery rate drops below 99%

### Requirement 65: Monitoring - User Analytics

**User Story:** As a product manager, I want user analytics, so that I can understand how patients use the app.

#### Acceptance Criteria

1. THE Mobile_App SHALL track: daily active users, weekly active users, monthly active users
2. THE Mobile_App SHALL track: prescription creation rate, medicine addition rate
3. THE Mobile_App SHALL track: dose marking rate (taken, skipped, missed)
4. THE Mobile_App SHALL track: adherence distribution across all users
5. THE Mobile_App SHALL track: feature usage (connections, reminders, offline mode)
6. THE Mobile_App SHALL track: user retention rates
7. THE Mobile_App SHALL anonymize all analytics data
8. THE Mobile_App SHALL allow users to opt out of analytics in settings

