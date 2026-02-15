# Requirements Document: Family Connection + Missed Dose Alert (Missing Features)

## Introduction

This document specifies the missing features for the Family Connection + Missed Dose Alert system in the Das Tern medication management platform. The platform already has a basic doctor-patient connection system implemented. This specification focuses on extending that system to support family member connections, implementing the missed dose alert workflow, caregiver nudge functionality, and enhancing the user experience with QR code generation, grace periods, and comprehensive notification handling.

**Current Implementation Status:**
- ✅ Basic Connection model (doctor-patient)
- ✅ Connection CRUD operations (create, accept, revoke)
- ✅ Permission levels enum
- ✅ Notification infrastructure
- ✅ Audit logging
- ✅ User roles (PATIENT, DOCTOR, FAMILY_MEMBER)

**Missing Features (This Spec):**
- ❌ QR code / token-based connection flow
- ❌ Family member-specific connection UI and workflows
- ❌ Grace period for missed doses
- ❌ Automatic missed dose detection
- ❌ Caregiver missed dose alerts
- ❌ Nudge functionality (caregiver → patient)
- ❌ Multiple caregiver management UI
- ❌ Connection history and audit trail UI
- ❌ Enhanced entry points for family connections
- ❌ Doctor connection variant with distinct UI

## Glossary

- **Patient**: The primary user who owns the medication schedule and receives reminders
- **Caregiver**: A family member or trusted individual who monitors the patient's medication adherence (uses FAMILY_MEMBER role)
- **Mobile_App**: The Flutter-based Das Tern mobile application (das_tern_mcp)
- **Backend_API**: The Next.js TypeScript backend service (backend_nestjs)
- **Access_Level**: Maps to existing PermissionLevel enum (NOT_ALLOWED, REQUEST, SELECTED, ALLOWED)
- **Connection_Token**: A new time-limited code or QR code used to establish patient-caregiver links
- **Missed_Dose_Alert**: A new notification type for alerting caregivers about missed doses
- **Grace_Period**: A new configurable time window after scheduled dose before marking as missed
- **Nudge**: A new gentle reminder message from caregiver to patient about missed doses
- **Today_Dashboard**: Existing patient dashboard showing medication schedule
- **Family_Access_List**: New UI component showing connected caregivers and permissions
- **Connection**: Existing model that links users (doctor-patient or patient-family)

## Requirements

### Requirement 1: QR Code and Token-Based Connection System

**User Story:** As a patient, I want to generate a QR code or short code to share with family members, so that they can easily connect to my account without manually entering complex information.

#### Acceptance Criteria

1. THE Backend_API SHALL implement a token generation endpoint that creates unique Connection_Tokens with 24-hour expiration
2. THE Connection_Token SHALL encode: patient ID, requested permission level, expiration timestamp, and one-time use flag
3. THE Backend_API SHALL provide an endpoint to validate and consume Connection_Tokens
4. THE Mobile_App SHALL generate and display QR codes from Connection_Tokens using a QR code library
5. THE Mobile_App SHALL display an alphanumeric short code (8-12 characters) alongside the QR code with copy functionality
6. WHEN a Connection_Token expires or is used, THE Backend_API SHALL mark it as invalid and prevent reuse
7. THE Backend_API SHALL store Connection_Tokens in a new database table with fields: id, patientId, token, permissionLevel, expiresAt, usedAt, createdAt

### Requirement 2: Enhanced Family Connection Entry Points

**User Story:** As a patient, I want multiple easy-to-find ways to start connecting with family members, so that I can quickly set up support when I need it.

#### Acceptance Criteria

1. THE Mobile_App SHALL add a "Need family support?" chip to the Today_Dashboard that opens the Family Connect flow
2. THE Mobile_App SHALL add a "Family & Shared Access" menu item in Profile settings with a badge showing connection count
3. THE Mobile_App SHALL display a dismissible banner on first login suggesting family connection setup
4. THE Mobile_App SHALL provide a "Connect Family" floating action button on the medications list screen
5. ALL entry points SHALL navigate to the same Family Connect flow screen

### Requirement 3: Family Connection Introduction Flow

**User Story:** As a patient, I want to understand what family connections allow before setting one up, so that I can make an informed decision.

#### Acceptance Criteria

1. THE Mobile_App SHALL create a new FamilyConnectIntroScreen with hero illustration and benefits list
2. THE intro screen SHALL display benefits: "They see your schedule", "They get notified if you miss doses", "They can send gentle reminders"
3. THE Mobile_App SHALL provide a "Generate Code" primary button and "View Existing Connections" secondary button
4. WHEN "Generate Code" is tapped, THE Mobile_App SHALL navigate to the Access Level Selection screen
5. WHEN "View Existing Connections" is tapped, THE Mobile_App SHALL navigate to the Family_Access_List screen

### Requirement 4: Access Level Selection for Family Members

**User Story:** As a patient, I want to choose what level of access my family member has, so that I maintain control over my privacy.

#### Acceptance Criteria

1. THE Mobile_App SHALL create an AccessLevelSelectionScreen with three options mapped to PermissionLevel enum
2. THE access level options SHALL be: "View Only" (REQUEST), "View + Remind" (SELECTED), "View + Manage" (ALLOWED)
3. EACH option SHALL display a clear description of what the caregiver can do
4. THE Mobile_App SHALL require selection of one option before enabling the "Continue" button
5. WHEN "Continue" is tapped, THE Mobile_App SHALL call the token generation API with the selected permission level

### Requirement 5: QR Code Display and Sharing

**User Story:** As a patient, I want to easily share my connection code with family members through QR or text, so that they can connect quickly.

#### Acceptance Criteria

1. THE Mobile_App SHALL create a TokenDisplayScreen showing a large QR code generated from the Connection_Token
2. THE screen SHALL display the short alphanumeric code below the QR with a copy-to-clipboard button
3. THE Mobile_App SHALL show token metadata: expiration countdown timer and "1 use remaining" status
4. THE Mobile_App SHALL provide a "Share" button that opens the native share sheet with the token and a deep link
5. THE Mobile_App SHALL allow dismissing the screen while keeping the token valid until expiration
6. WHEN the token expires or is used, THE Mobile_App SHALL display "Generate new code" button instead of the QR code

### Requirement 6: Caregiver QR Scanning and Code Entry

**User Story:** As a caregiver, I want to scan a QR code or enter a code manually to connect to a patient, so that I can choose the method that works best for me.

#### Acceptance Criteria

1. THE Mobile_App SHALL create a CaregiverOnboardingScreen with four tiles: "Scan QR", "Enter Code", "Search by Phone" (disabled for MVP), "Ask Later"
2. WHEN "Scan QR" is selected, THE Mobile_App SHALL activate the camera with a QR scanning overlay and framing guide
3. WHEN a QR code is scanned, THE Mobile_App SHALL extract the Connection_Token and validate it with the Backend_API
4. WHEN "Enter Code" is selected, THE Mobile_App SHALL display a text input field for manual code entry
5. WHEN a code is entered, THE Mobile_App SHALL validate it with the Backend_API
6. IF validation fails (expired/invalid), THE Mobile_App SHALL display an error banner: "Invalid or expired code. Ask patient for a new one."
7. IF validation succeeds, THE Mobile_App SHALL display a preview modal showing patient name and requested access level

### Requirement 7: Connection Request Approval Flow

**User Story:** As a patient, I want to review and approve family connection requests, so that I control who can access my medication information.

#### Acceptance Criteria

1. WHEN a caregiver sends a connection request using a valid token, THE Backend_API SHALL create a Connection record with status PENDING
2. THE Backend_API SHALL send a push notification to the patient using the existing Notification model with type CONNECTION_REQUEST
3. THE Mobile_App SHALL display an in-app approval sheet with format: "[Caregiver Name] wants [Access Level] access"
4. THE approval sheet SHALL allow the patient to adjust the permission level before approving
5. THE approval sheet SHALL provide three buttons: "Approve", "Deny", "Message First" (message feature deferred to future)
6. WHEN "Approve" is tapped, THE Backend_API SHALL update the Connection status to ACCEPTED and set acceptedAt timestamp
7. WHEN "Deny" is tapped, THE Backend_API SHALL update the Connection status to REVOKED
8. THE Mobile_App SHALL display a success toast "Family linked" upon approval

### Requirement 8: Family Access List and Management

**User Story:** As a patient, I want to see all my connected family members and manage their permissions, so that I can update or revoke access as needed.

#### Acceptance Criteria

1. THE Mobile_App SHALL create a FamilyAccessListScreen displaying all Connection records where the patient is initiator or recipient and role is FAMILY_MEMBER
2. EACH connection card SHALL display: caregiver name, access level badge, status (Active/Pending/Paused), and last alert timestamp
3. THE Mobile_App SHALL provide a toggle for each caregiver to enable/disable missed dose alerts (stored in Connection metadata JSON)
4. THE Mobile_App SHALL provide an overflow menu with options: "Change Permission", "Pause Alerts", "Remove Connection"
5. WHEN "Change Permission" is selected, THE Mobile_App SHALL call the existing updatePermission API endpoint
6. WHEN "Remove Connection" is selected, THE Mobile_App SHALL call the existing revoke API endpoint
7. THE Mobile_App SHALL display a caregiver detail page showing: permissions, alert history (from AuditLog), and connection date

### Requirement 9: Caregiver Dashboard Access

**User Story:** As a caregiver, I want to view the patient's medication schedule and adherence, so that I can monitor their health effectively.

#### Acceptance Criteria

1. THE Mobile_App SHALL create a CaregiverDashboardScreen that displays connected patients' medication data
2. THE dashboard SHALL clearly indicate viewing mode with patient name prominently displayed at the top
3. THE Mobile_App SHALL fetch prescriptions and dose events for the connected patient using existing API endpoints
4. THE dashboard SHALL display: today's medications, upcoming doses, adherence percentage, and missed dose history
5. THE Mobile_App SHALL respect the permission level: VIEW_ONLY shows read-only data, SELECTED adds nudge button, ALLOWED adds edit capabilities (future)
6. THE Mobile_App SHALL provide a "Switch Patient" dropdown if the caregiver is connected to multiple patients

### Requirement 10: Grace Period Configuration and Implementation

**User Story:** As a system, I want to wait a configurable grace period before marking doses as missed, so that patients have time to take their medication without triggering false alerts.

#### Acceptance Criteria

1. THE Backend_API SHALL add a grace_period_minutes field to the User model (default 30 minutes)
2. THE Backend_API SHALL create a scheduled job that runs every 5 minutes to check for doses past their grace period
3. WHEN a DoseEvent has status DUE and scheduledTime + grace_period_minutes < current time, THE Backend_API SHALL update status to MISSED
4. THE Backend_API SHALL create an AuditLog entry with actionType DOSE_MISSED when status changes
5. THE Mobile_App SHALL display a subtle countdown timer on the Today_Dashboard during the grace period
6. THE Mobile_App SHALL allow patients to configure their grace period in settings (10, 20, 30, 60 minutes options)

### Requirement 11: Automatic Missed Dose Detection and Patient Notification

**User Story:** As a patient, I want the system to automatically mark doses as missed and notify me, so that I'm aware of my adherence without manual tracking.

#### Acceptance Criteria

1. WHEN the grace period job marks a DoseEvent as MISSED, THE Backend_API SHALL create a Notification for the patient with type MISSED_DOSE_ALERT
2. THE notification SHALL display as a banner: "You missed a dose • Mark as taken?"
3. THE banner SHALL provide quick action buttons: "Mark as Taken" and "Dismiss"
4. WHEN "Mark as Taken" is tapped, THE Mobile_App SHALL update the DoseEvent status to TAKEN_LATE with current timestamp
5. THE Mobile_App SHALL update the Today_Dashboard to show missed doses with a distinct visual indicator (red badge)
6. THE Backend_API SHALL allow patients to manually mark missed doses as taken up to 24 hours after scheduled time

### Requirement 12: Caregiver Missed Dose Alerts

**User Story:** As a caregiver, I want to receive notifications when the patient misses a dose, so that I can check on them and provide support.

#### Acceptance Criteria

1. WHEN a DoseEvent status changes to MISSED, THE Backend_API SHALL query all ACCEPTED Connections where the patient is connected and alerts are enabled
2. FOR EACH enabled caregiver connection, THE Backend_API SHALL create a Notification with type MISSED_DOSE_ALERT
3. THE notification SHALL follow format: "[Patient Name] missed the [Time] dose of [Medication Name]"
4. THE notification SHALL include deep link data: { patientId, doseEventId, prescriptionId }
5. WHEN a caregiver taps the notification, THE Mobile_App SHALL navigate to the patient's Today_Dashboard with the missed dose highlighted
6. THE Backend_API SHALL respect the alert toggle in Connection metadata and NOT send alerts if disabled
7. THE Backend_API SHALL create an AuditLog entry for each alert sent with actionType NOTIFICATION_SENT

### Requirement 13: Caregiver Nudge Functionality

**User Story:** As a caregiver, I want to send a gentle reminder to the patient about a missed dose, so that I can encourage adherence without being intrusive.

#### Acceptance Criteria

1. THE Mobile_App SHALL display a "Nudge Patient" button on missed dose cards in the caregiver dashboard
2. WHEN "Nudge Patient" is tapped, THE Backend_API SHALL create a Notification for the patient with type FAMILY_ALERT
3. THE patient notification SHALL display as a banner: "Your family is checking on you. Did you take your medicine?"
4. THE banner SHALL provide quick actions: "Mark as Taken", "I'll take it soon", "Dismiss"
5. WHEN the patient responds, THE Backend_API SHALL create a Notification for the caregiver with the response
6. THE Mobile_App SHALL update the caregiver's view with the patient's response and timestamp (e.g., "Taken late at 9:12 AM")
7. THE Backend_API SHALL implement rate limiting: maximum 2 nudges per DoseEvent per caregiver
8. THE Backend_API SHALL create AuditLog entries for nudge sent and patient response

### Requirement 14: Multiple Caregiver Support and Limits

**User Story:** As a patient, I want to connect with multiple family members based on my subscription tier, so that several people can help monitor my adherence.

#### Acceptance Criteria

1. THE Backend_API SHALL enforce caregiver limits based on SubscriptionTier: FREEMIUM allows 1, PREMIUM allows 5, FAMILY_PREMIUM allows 10
2. WHEN the limit is reached, THE Mobile_App SHALL display: "You've reached your family connection limit. Upgrade to Premium or remove a connection to add new ones."
3. THE Mobile_App SHALL show current count and limit in the Family_Access_List header (e.g., "2 / 5 family members")
4. WHEN multiple caregivers have alerts enabled, THE Backend_API SHALL send missed dose alerts to ALL enabled caregivers
5. THE Mobile_App SHALL allow patients to prioritize caregivers (primary, secondary) for future notification ordering (deferred to future)

### Requirement 15: Connection History and Audit Trail UI

**User Story:** As a patient, I want to see a history of connection activities, so that I can track who accessed my information and when.

#### Acceptance Criteria

1. THE Mobile_App SHALL create a ConnectionHistoryScreen accessible from Family & Shared Access settings
2. THE screen SHALL fetch AuditLog entries filtered by actionType: CONNECTION_REQUEST, CONNECTION_ACCEPT, CONNECTION_REVOKE, PERMISSION_CHANGE, DATA_ACCESS
3. EACH history entry SHALL display: timestamp, caregiver name, action type, and access level
4. THE Mobile_App SHALL provide filters: by caregiver, by date range (last 7 days, 30 days, 90 days), by action type
5. THE Mobile_App SHALL implement infinite scroll pagination for history entries (20 per page)

### Requirement 16: Doctor Connection Variant

**User Story:** As a patient, I want to connect with doctors using the same flow but with a distinct interface, so that I can manage both family and doctor connections easily.

#### Acceptance Criteria

1. THE Mobile_App SHALL reuse the QR/token connection flow for doctor connections
2. THE Mobile_App SHALL provide a "Connect Doctor" option separate from "Connect Family" in settings
3. WHEN generating a token for a doctor, THE Mobile_App SHALL set a flag in the token metadata indicating doctor connection type
4. THE Mobile_App SHALL display doctor connections in a separate "Healthcare Providers" section from family connections
5. THE doctor dashboard SHALL use a clinical interface theme distinct from the family caregiver interface
6. THE Backend_API SHALL enforce that doctor connections use the DOCTOR role, family connections use FAMILY_MEMBER role

### Requirement 17: Offline Support for Connection Management

**User Story:** As a patient or caregiver, I want connection requests to queue when offline, so that I can complete the process when network is restored.

#### Acceptance Criteria

1. WHEN a caregiver sends a connection request while offline, THE Mobile_App SHALL store the request in local SQLite database
2. WHEN network connectivity is restored, THE Mobile_App SHALL automatically sync queued requests to the Backend_API
3. WHEN a patient approves/denies a request while offline, THE Mobile_App SHALL queue the response locally
4. THE Mobile_App SHALL display a "Pending Sync" indicator for queued operations
5. IF a queued request fails after 3 retry attempts, THE Mobile_App SHALL notify the user and provide manual retry option

### Requirement 18: Accessibility and Localization

**User Story:** As a patient or caregiver, I want the family connection feature to support my language and accessibility needs, so that I can use it comfortably.

#### Acceptance Criteria

1. THE Mobile_App SHALL provide all family connection screens in both Khmer and English using existing i18n infrastructure
2. THE Mobile_App SHALL support screen readers with appropriate labels for all interactive elements
3. THE Mobile_App SHALL ensure QR codes have text alternatives (the alphanumeric code)
4. THE Mobile_App SHALL support both light and dark themes for all connection screens
5. THE Mobile_App SHALL ensure all touch targets meet minimum size requirements (44x44 points)

### Requirement 19: Error Handling and Edge Cases

**User Story:** As a user, I want clear error messages when something goes wrong, so that I can resolve issues and complete the connection process.

#### Acceptance Criteria

1. WHEN a Connection_Token expires, THE Mobile_App SHALL display: "This code has expired. Please ask the patient for a new code."
2. WHEN a Connection_Token is already used, THE Mobile_App SHALL display: "This code has already been used. Please request a new code."
3. WHEN network errors occur, THE Mobile_App SHALL display: "Connection failed. Please check your internet and try again."
4. WHEN a user tries to connect to themselves, THE Backend_API SHALL return error 400: "You cannot connect to your own account"
5. WHEN a caregiver account doesn't exist, THE Mobile_App SHALL guide them to registration before completing connection
6. WHEN the subscription limit is reached, THE Mobile_App SHALL display upgrade prompt with link to subscription management

### Requirement 20: Push Notification Configuration

**User Story:** As a patient or caregiver, I want to configure which notifications I receive, so that I'm not overwhelmed with alerts.

#### Acceptance Criteria

1. THE Mobile_App SHALL add a "Notification Preferences" screen in settings
2. THE preferences SHALL include toggles for: Connection Requests, Missed Dose Alerts (patient), Family Alerts (caregiver), Nudges (patient)
3. WHEN a toggle is disabled, THE Backend_API SHALL NOT send notifications of that type to the user
4. THE Mobile_App SHALL persist notification preferences locally and sync to Backend_API
5. THE Backend_API SHALL check notification preferences before creating Notification records
