# Requirements Document: Das Tern Backend API

## Introduction

The Das Tern Backend API provides the server-side infrastructure for a patient-centered medication management platform. The API supports three user roles (Patient, Doctor, Family/Caregiver), manages prescriptions with version control, handles offline-first synchronization, enforces subscription-based storage quotas, and maintains comprehensive audit trails. The system must support both online and offline client operations, with Cambodia timezone as the default.

## Glossary

- **Patient**: Primary user and owner of all medical data
- **Doctor**: Healthcare provider who can create and modify prescriptions with patient permission
- **Family_Member**: Caregiver who receives alerts and can view patient data with permission
- **Prescription**: Medication schedule with lifecycle states (Draft, Active, Paused, Inactive)
- **DoseEvent**: Individual scheduled medication dose with tracking status
- **Medication_Schedule**: Daily medication plan grouped by time periods (Daytime, Night)
- **Meal_Time_Preference**: User's typical meal times used for calculating reminder times
- **Adherence_Percentage**: Ratio of taken doses to total scheduled doses over a time period
- **Connection**: Bidirectional relationship between users requiring mutual acceptance
- **Permission_Level**: Access control enum (NOT_ALLOWED, REQUEST, SELECTED, ALLOWED)
- **Subscription_Tier**: Plan level (FREEMIUM, PREMIUM, FAMILY_PREMIUM)
- **Audit_Log**: Immutable record of all system actions for transparency
- **Sync_Queue**: Collection of offline actions pending synchronization
- **Cambodia_Time**: Asia/Phnom_Penh timezone (UTC+7), system default
- **PRN**: Pro Re Nata (as needed) medication without fixed schedule
- **Storage_Quota**: Maximum data storage per subscription tier (5GB or 20GB)
- **API**: The Das Tern Backend API system
- **Database**: PostgreSQL database storing all persistent data

## Requirements

### Requirement 1: User Authentication and Authorization

**User Story:** As a user (Patient, Doctor, or Family Member), I want to securely authenticate and access only the data I'm authorized to view, so that my privacy and security are protected.

#### Acceptance Criteria

1. WHEN a user registers with valid credentials, THE API SHALL create a new user account with the specified role (Patient, Doctor, or Family_Member)
2. WHEN a user provides valid credentials (phone number or email with password), THE API SHALL issue a JWT token containing user ID, role, subscription tier, and language preference
3. WHEN a user provides an expired or invalid JWT token, THE API SHALL reject the request and return an authentication error with Khmer and English messages
4. THE API SHALL enforce role-based access control on all protected endpoints
5. WHEN a user changes their password, THE API SHALL invalidate all existing JWT tokens for that user
6. WHEN a user fails authentication 5 consecutive times, THE API SHALL lock the account for 15 minutes
7. THE API SHALL accept phone numbers in Cambodia format (+855 prefix) or email addresses as login identifiers

### Requirement 2: User Profile Management

**User Story:** As a user, I want to manage my profile settings including language preference and theme, so that the application matches my preferences.

#### Acceptance Criteria

1. THE API SHALL store user preferences including language (Khmer or English) and theme (Light or Dark)
2. WHEN a user updates their profile, THE API SHALL validate the changes and persist them to the Database
3. WHEN a user requests their profile, THE API SHALL return all profile data including subscription tier, storage usage, and daily medication progress
4. THE API SHALL calculate and return current storage usage as a percentage of the user's quota
5. FOR Patient users, THE API SHALL return a greeting message with the user's name and daily medication completion percentage
6. FOR Doctor users, THE API SHALL return professional details including hospital/clinic name and specialty

### Requirement 3: Doctor-Patient Connection Management

**User Story:** As a Patient or Doctor, I want to establish connections with mutual acceptance and patient-controlled permissions, so that I can collaborate on medication management while maintaining privacy control.

#### Acceptance Criteria

1. WHEN a Doctor or Patient initiates a connection request, THE API SHALL create a pending connection record with status "PENDING"
2. WHEN the recipient accepts a connection request, THE API SHALL update the connection status to "ACCEPTED" and prompt the Patient to set permission level
3. WHEN a Patient sets permission level for a Doctor connection, THE API SHALL store the permission (NOT_ALLOWED, REQUEST, SELECTED, or ALLOWED) with default value ALLOWED
4. WHEN a Doctor attempts to access Patient data, THE API SHALL enforce the permission level set by the Patient
5. WHEN either party revokes a connection, THE API SHALL update the connection status to "REVOKED" and immediately block all access
6. THE API SHALL record all connection state changes in the Audit_Log

### Requirement 4: Family-Patient Connection Management

**User Story:** As a Patient, I want to connect with Family Members who can support my medication adherence, so that I receive help when I miss doses.

#### Acceptance Criteria

1. WHEN a Patient invites a Family_Member, THE API SHALL create a connection invitation with a unique token
2. WHEN a Family_Member accepts an invitation, THE API SHALL create a bidirectional connection with mutual view permissions
3. WHEN a Patient revokes Family_Member access, THE API SHALL immediately terminate the connection and block all access
4. THE API SHALL record all Family connection changes in the Audit_Log

### Requirement 5: Prescription Creation and Lifecycle Management

**User Story:** As a Doctor, I want to create and manage prescriptions for my patients with proper version control, so that medication changes are tracked and patients follow the correct treatment plan.

#### Acceptance Criteria

1. WHEN a Doctor creates a prescription, THE API SHALL validate Doctor-Patient connection and permission level before allowing creation
2. THE API SHALL support prescription status transitions: Draft → Active → Paused → Inactive
3. WHEN a prescription status changes to Active, THE API SHALL generate DoseEvent records based on the medication schedule
4. WHEN a Doctor modifies an Active prescription, THE API SHALL create a new version and preserve the previous version in history
5. WHEN a Doctor marks a prescription change as urgent, THE API SHALL auto-apply the change and notify the Patient immediately
6. THE API SHALL record all prescription changes including version number, timestamp, author, and reason in the Audit_Log

### Requirement 6: Dose Event Tracking

**User Story:** As a Patient, I want to record when I take my medication, so that my adherence history is accurate and my healthcare team can monitor my progress.

#### Acceptance Criteria

1. WHEN a DoseEvent is created, THE API SHALL set initial status to "DUE" with scheduled time in Cambodia_Time
2. WHEN a Patient marks a dose as taken within the allowed time window, THE API SHALL update status to "TAKEN_ON_TIME"
3. WHEN a Patient marks a dose as taken after the allowed window but before cutoff, THE API SHALL update status to "TAKEN_LATE"
4. WHEN a DoseEvent passes the cutoff time without being marked taken, THE API SHALL update status to "MISSED"
5. WHEN a Patient skips a dose with a reason, THE API SHALL update status to "SKIPPED" and store the reason
6. THE API SHALL record all dose status changes in the Audit_Log with timestamp and user ID

### Requirement 7: Offline Synchronization

**User Story:** As a Patient, I want my offline actions to sync automatically when I reconnect, so that my medication records remain accurate even when I don't have internet access.

#### Acceptance Criteria

1. WHEN a client submits a batch of offline actions, THE API SHALL validate each action's timestamp and user authorization
2. WHEN processing offline dose events, THE API SHALL apply time-window logic based on the original scheduled time and action timestamp
3. WHEN offline actions conflict with server state, THE API SHALL apply conflict resolution rules (client timestamp wins for dose events)
4. WHEN sync completes successfully, THE API SHALL return a summary of applied changes and any conflicts
5. THE API SHALL record all synced offline actions in the Audit_Log with both action timestamp and sync timestamp

### Requirement 8: Missed Dose Notifications

**User Story:** As a Family Member, I want to receive notifications when my connected Patient misses a dose, so that I can provide timely support and reminders.

#### Acceptance Criteria

1. WHEN a DoseEvent status changes to "MISSED", THE API SHALL identify all connected Family_Members with notification permissions
2. WHEN a Patient is online and misses a dose, THE API SHALL send immediate notifications to connected Family_Members
3. WHEN a Patient is offline and misses a dose, THE API SHALL send notifications to Family_Members after the next successful sync
4. WHEN sending delayed missed-dose notifications, THE API SHALL include a timestamp indicating when the dose was actually missed
5. THE API SHALL record all notification deliveries in the Audit_Log

### Requirement 9: PRN (As Needed) Medication Support

**User Story:** As a Patient, I want to manage PRN medications with flexible scheduling, so that I can track as-needed medications without strict schedules.

#### Acceptance Criteria

1. WHEN a Patient creates a PRN prescription without specified times, THE API SHALL assign default reminder times using Cambodia_Time (morning, noon, evening, night)
2. WHEN a Patient specifies custom PRN reminder times, THE API SHALL use those times instead of defaults
3. THE API SHALL allow manual dose recording for PRN medications without requiring a scheduled DoseEvent
4. WHEN a Patient records a PRN dose, THE API SHALL create a DoseEvent with status "TAKEN_ON_TIME" and current timestamp

### Requirement 10: Audit Logging

**User Story:** As a Patient, I want a complete audit trail of all actions on my data, so that I can trust the system and verify who accessed or modified my information.

#### Acceptance Criteria

1. THE API SHALL create an Audit_Log entry for every connection request, acceptance, and revocation
2. THE API SHALL create an Audit_Log entry for every permission level change
3. THE API SHALL create an Audit_Log entry for every prescription creation, modification, and status change
4. THE API SHALL create an Audit_Log entry for every dose event status change
5. THE API SHALL create an Audit_Log entry for every data access by Doctor or Family_Member (when policy requires logging)
6. THE API SHALL create an Audit_Log entry for every notification sent
7. WHEN a Patient requests their audit log, THE API SHALL return all entries related to their data in reverse chronological order
8. THE API SHALL ensure Audit_Log entries are immutable and include timestamp, actor user ID, action type, and affected resource

### Requirement 11: Subscription Management

**User Story:** As a user, I want to subscribe to a plan that matches my needs, so that I can access appropriate features and storage capacity.

#### Acceptance Criteria

1. THE API SHALL support three subscription tiers: FREEMIUM (5GB), PREMIUM (20GB, $0.50/month), and FAMILY_PREMIUM (20GB, $1/month)
2. WHEN a user registers, THE API SHALL assign FREEMIUM tier by default
3. WHEN a user upgrades to PREMIUM or FAMILY_PREMIUM, THE API SHALL immediately unlock all features and increase storage quota
4. WHEN a user attempts to store data exceeding their quota, THE API SHALL reject the request and return a quota exceeded error
5. WHEN a FAMILY_PREMIUM subscriber adds a family member, THE API SHALL verify total member count does not exceed 3
6. WHEN a FAMILY_PREMIUM subscription is active, THE API SHALL grant PREMIUM benefits to all connected family members
7. THE API SHALL record all subscription changes in the Audit_Log

### Requirement 12: Storage Quota Enforcement

**User Story:** As a system administrator, I want to enforce storage quotas per subscription tier, so that system resources are managed fairly and users are incentivized to upgrade when needed.

#### Acceptance Criteria

1. THE API SHALL track storage usage for each user including prescription data, dose events, and audit logs
2. WHEN a user uploads or creates data, THE API SHALL calculate the storage impact and verify it does not exceed the user's quota
3. WHEN a user exceeds their storage quota, THE API SHALL prevent new data creation and return a quota exceeded error with current usage details
4. WHEN a user upgrades their subscription, THE API SHALL immediately apply the new storage quota
5. THE API SHALL provide an endpoint to query current storage usage and remaining quota

### Requirement 13: Real-Time Notifications

**User Story:** As a user, I want to receive real-time notifications for important events, so that I can respond promptly to medication reminders and connection requests.

#### Acceptance Criteria

1. THE API SHALL support WebSocket or Server-Sent Events for real-time notification delivery
2. WHEN a user is connected via WebSocket, THE API SHALL deliver notifications immediately without polling
3. WHEN a user is offline, THE API SHALL queue notifications for delivery upon reconnection
4. THE API SHALL support notification types: connection requests, prescription updates, missed dose alerts, and urgent changes
5. WHEN a notification is delivered, THE API SHALL record the delivery in the Audit_Log

### Requirement 14: Multi-Language Support

**User Story:** As a user, I want the API to support my preferred language (Khmer or English), so that error messages and system communications are in my language.

#### Acceptance Criteria

1. THE API SHALL accept a language preference header (Accept-Language) on all requests
2. WHEN returning error messages, THE API SHALL provide translations in Khmer and English based on user preference
3. THE API SHALL store user language preference in the user profile
4. WHEN sending notifications, THE API SHALL use the recipient's preferred language

### Requirement 15: Cambodia Timezone Default

**User Story:** As a user in Cambodia, I want all times to default to Cambodia timezone, so that medication schedules align with my local time.

#### Acceptance Criteria

1. THE API SHALL use Cambodia_Time (Asia/Phnom_Penh, UTC+7) as the default timezone for all timestamp operations
2. WHEN creating DoseEvent records, THE API SHALL store scheduled times in Cambodia_Time unless explicitly overridden
3. WHEN calculating time windows for adherence classification, THE API SHALL use Cambodia_Time
4. THE API SHALL accept and return timestamps in ISO 8601 format with timezone information

### Requirement 16: Data Privacy and Access Control

**User Story:** As a Patient, I want complete control over who can access my medical data, so that my privacy is protected and I can trust the system.

#### Acceptance Criteria

1. THE API SHALL enforce that only the Patient can view their own data by default
2. WHEN a Doctor requests access to Patient data, THE API SHALL verify an accepted connection exists and permission level allows access
3. WHEN permission level is REQUEST, THE API SHALL require explicit Patient approval for each access attempt
4. WHEN permission level is SELECTED, THE API SHALL restrict Doctor access to only explicitly selected prescriptions or time ranges
5. WHEN permission level is NOT_ALLOWED, THE API SHALL deny all Doctor access requests
6. THE API SHALL log all data access attempts in the Audit_Log regardless of success or failure

### Requirement 17: Prescription Version History

**User Story:** As a Patient, I want to view the complete history of prescription changes, so that I understand how my treatment plan has evolved over time.

#### Acceptance Criteria

1. THE API SHALL maintain all prescription versions with version numbers starting at 1
2. WHEN a prescription is modified, THE API SHALL increment the version number and preserve the previous version
3. WHEN a Patient requests prescription history, THE API SHALL return all versions in reverse chronological order
4. THE API SHALL include metadata for each version: version number, author, timestamp, change reason, and urgent flag
5. THE API SHALL support querying a specific prescription version by version number

### Requirement 18: Database Schema and Relationships

**User Story:** As a system architect, I want a well-designed relational database schema, so that data integrity is maintained and queries are efficient.

#### Acceptance Criteria

1. THE Database SHALL enforce foreign key constraints for all relationships (User-Connection, User-Prescription, Prescription-DoseEvent)
2. THE Database SHALL use indexes on frequently queried fields (user_id, prescription_id, scheduled_time, status)
3. THE Database SHALL enforce unique constraints on connection pairs to prevent duplicate connections
4. THE Database SHALL use appropriate data types for all fields (TIMESTAMP WITH TIME ZONE for times, ENUM for status fields)
5. THE Database SHALL support cascading deletes where appropriate (deleting prescription deletes associated dose events)

### Requirement 19: API Error Handling and Validation

**User Story:** As a client developer, I want clear and consistent error responses, so that I can handle errors appropriately in the mobile app.

#### Acceptance Criteria

1. WHEN validation fails, THE API SHALL return HTTP 400 with detailed field-level error messages
2. WHEN authentication fails, THE API SHALL return HTTP 401 with an appropriate error code
3. WHEN authorization fails, THE API SHALL return HTTP 403 with details about the permission requirement
4. WHEN a resource is not found, THE API SHALL return HTTP 404 with the resource type and ID
5. WHEN a server error occurs, THE API SHALL return HTTP 500 and log the error details for debugging
6. THE API SHALL return all errors in a consistent JSON format with error code, message, and optional details

### Requirement 21: Patient Registration Data

**User Story:** As a new patient, I want to register with my personal information, so that I can create an account and start managing my medications.

#### Acceptance Criteria

1. THE API SHALL accept patient registration with fields: lastName, firstName, gender, dateOfBirth, idCardNumber, phoneNumber, password, and pinCode
2. WHEN a patient registers, THE API SHALL validate that the phone number starts with +855 (Cambodia country code)
3. WHEN a patient registers, THE API SHALL validate that the password is at least 6 characters long
4. WHEN a patient registers, THE API SHALL validate that the pinCode is exactly 4 digits
5. WHEN a patient registers, THE API SHALL validate that the age (calculated from dateOfBirth) is at least 13 years
6. WHEN a patient submits registration, THE API SHALL send a 4-digit OTP via SMS to the provided phone number
7. WHEN a patient verifies the OTP within 5 minutes, THE API SHALL create the account and assign FREEMIUM subscription tier
8. WHEN a phone number is already registered, THE API SHALL return an error indicating the phone number is taken
9. THE API SHALL support OTP resend with a 60-second cooldown between requests
10. WHEN OTP verification fails 5 times, THE API SHALL lock the registration attempt for 15 minutes

### Requirement 22: Doctor Registration and Verification

**User Story:** As a doctor, I want to register with my professional credentials and license information, so that I can prescribe medications to patients after verification.

#### Acceptance Criteria

1. THE API SHALL accept doctor registration with fields: fullName, phoneNumber, hospitalClinic, specialty, licenseNumber, licensePhoto, and password
2. WHEN a doctor registers, THE API SHALL set the account status to "PENDING_VERIFICATION"
3. WHEN a doctor registers, THE API SHALL store the uploaded license photo securely
4. WHEN a doctor account is pending verification, THE API SHALL prevent login and return a "verification pending" message
5. WHEN an admin approves a doctor account, THE API SHALL update status to "VERIFIED" and send a notification to the doctor
6. WHEN an admin rejects a doctor account, THE API SHALL update status to "REJECTED" and send a notification with reason
7. THE API SHALL support specialty values: General Practice, Internal Medicine, Cardiology, Endocrinology, and Other
8. THE API SHALL enforce that only verified doctors can create prescriptions or connect with patients

### Requirement 23: Medication Schedule Display

**User Story:** As a patient, I want to view my daily medication schedule organized by time periods, so that I know which medications to take and when.

#### Acceptance Criteria

1. THE API SHALL return medication schedules grouped by time periods: Daytime (ពេលថ្ងៃ) and Night (ពេលយប់)
2. FOR each medication in the schedule, THE API SHALL return: medication name (Khmer and English), dosage, quantity, image URL, status, and scheduled time
3. THE API SHALL calculate and return daily progress as a percentage (completed doses / total scheduled doses)
4. WHEN a patient marks a medication as taken, THE API SHALL update the dose status and recalculate daily progress
5. THE API SHALL return medication detail including: frequency, timing (before/after meals), and recommended reminder time
6. THE API SHALL support editing reminder times for individual medications

### Requirement 24: Onboarding Survey for Meal Times

**User Story:** As a new patient, I want to provide my typical meal times during onboarding, so that the system can recommend appropriate medication reminder times.

#### Acceptance Criteria

1. THE API SHALL accept onboarding survey responses for three meal periods: morning, afternoon, and night
2. FOR each meal period, THE API SHALL accept a time range selection (e.g., "6-7AM", "7-8AM", "8-9AM", "9-10AM")
3. WHEN a patient completes the onboarding survey, THE API SHALL calculate recommended reminder times for "after meals" medications
4. THE API SHALL store meal time preferences in the user profile
5. WHEN generating medication schedules, THE API SHALL use meal time preferences to set default reminder times for medications marked "after meals"

### Requirement 25: Doctor Prescription Creation

**User Story:** As a doctor, I want to create prescriptions with a medication grid showing dosages for different time periods, so that patients receive clear medication schedules.

#### Acceptance Criteria

1. THE API SHALL accept prescription creation with patient information: name, gender, age, symptoms (in Khmer)
2. THE API SHALL accept a medication table with columns: row number, medicine name, morning dosage, daytime dosage, night dosage
3. FOR each dosage cell, THE API SHALL accept before-meal or after-meal indicators
4. WHEN a doctor creates a prescription, THE API SHALL validate that a verified connection exists with the patient
5. WHEN a prescription is created, THE API SHALL send a notification to the patient for review
6. THE API SHALL support prescription actions: Confirm (patient accepts), Retake (patient requests revision), Add Medicine (add rows)
7. WHEN a patient confirms a prescription, THE API SHALL activate it and generate the medication schedule

### Requirement 26: Doctor Patient Monitoring

**User Story:** As a doctor, I want to view my patient list with adherence percentages, so that I can identify patients who need attention.

#### Acceptance Criteria

1. THE API SHALL return a list of connected patients for a doctor with: patient name, gender, age, phone number, current symptoms, and adherence percentage
2. THE API SHALL calculate adherence percentage as (taken doses / total scheduled doses) over a configurable time period (default 30 days)
3. THE API SHALL support color-coded adherence levels: Green (>= 80%), Yellow (50-79%), Red (< 50%)
4. WHEN a doctor requests patient details, THE API SHALL return the current prescription list and medication schedule grouped by time periods
5. THE API SHALL return prescription history showing all versions with timestamps and change reasons

### Requirement 27: API Performance and Scalability

**User Story:** As a user, I want the API to respond quickly even as the platform grows, so that my experience remains smooth and responsive.

#### Acceptance Criteria

1. THE API SHALL respond to authentication requests within 200ms for 95% of requests
2. THE API SHALL respond to data retrieval requests within 500ms for 95% of requests
3. THE API SHALL support pagination for list endpoints with configurable page size (default 50, max 100)
4. THE API SHALL implement rate limiting to prevent abuse (100 requests per minute per user)
5. WHEN rate limit is exceeded, THE API SHALL return HTTP 429 with retry-after header

**User Story:** As a user, I want the API to respond quickly even as the platform grows, so that my experience remains smooth and responsive.

#### Acceptance Criteria

1. THE API SHALL respond to authentication requests within 200ms for 95% of requests
2. THE API SHALL respond to data retrieval requests within 500ms for 95% of requests
3. THE API SHALL support pagination for list endpoints with configurable page size (default 50, max 100)
4. THE API SHALL implement rate limiting to prevent abuse (100 requests per minute per user)
5. WHEN rate limit is exceeded, THE API SHALL return HTTP 429 with retry-after header


### Requirement 28: Medication Schedule Time Grouping

**User Story:** As a patient, I want my medication schedule grouped by time periods (Daytime and Night), so that I can easily see which medications to take at different times of day.

#### Acceptance Criteria

1. THE API SHALL group medications into two time periods: Daytime (ពេលថ្ងៃ) and Night (ពេលយប់)
2. WHEN returning medication schedules, THE API SHALL include time period grouping with appropriate color codes (Blue #2D5BFF for Daytime, Purple #6B4AA3 for Night)
3. THE API SHALL calculate and return daily progress as a percentage of completed doses
4. THE API SHALL support querying schedules by date with optional groupBy parameter
5. WHEN a patient marks a dose as taken, THE API SHALL recalculate and return updated daily progress

### Requirement 29: Medication Detail Information

**User Story:** As a patient, I want to view detailed information about each medication, so that I understand when and how to take it.

#### Acceptance Criteria

1. THE API SHALL return medication details including: name (Khmer and English), dosage, quantity, frequency, timing (before/after meals), and recommended reminder time
2. THE API SHALL support updating reminder times for individual medications
3. THE API SHALL return medication images when available
4. THE API SHALL include before-meal or after-meal indicators for each dosage
5. THE API SHALL calculate recommended reminder times based on meal time preferences

### Requirement 30: Prescription Grid Format

**User Story:** As a doctor, I want to create prescriptions using a grid format with time periods, so that I can clearly specify when patients should take each medication.

#### Acceptance Criteria

1. THE API SHALL accept prescription creation with a medication grid containing columns: row number (ល.រ), medicine name (ឈ្មោះឱសថ), morning (ពេលព្រឹក), daytime (ពេលថ្ងៃ), night (ពេលយប់)
2. FOR each time period cell, THE API SHALL accept dosage amount and before/after meal indicator
3. THE API SHALL validate that at least one time period has a dosage for each medication
4. THE API SHALL store medication grid data in a structured format for easy retrieval
5. WHEN generating dose events, THE API SHALL use the grid data to create appropriate schedules

### Requirement 31: Patient Prescription Actions

**User Story:** As a patient, I want to review prescriptions sent by my doctor and take actions (Confirm, Retake, Add Medicine), so that I can ensure my medication plan is correct.

#### Acceptance Criteria

1. THE API SHALL support three prescription actions: Confirm, Retake, and Add Medicine
2. WHEN a patient confirms a prescription, THE API SHALL activate it and generate the medication schedule
3. WHEN a patient requests a retake, THE API SHALL notify the doctor and mark the prescription as requiring revision
4. WHEN a patient adds medicine, THE API SHALL allow adding new rows to the medication grid
5. THE API SHALL record all prescription actions in the audit log

### Requirement 32: Urgent Prescription Reason Requirement

**User Story:** As a doctor, I want to provide a reason when making urgent prescription changes, so that patients understand why the change was necessary.

#### Acceptance Criteria

1. WHEN a doctor marks a prescription update as urgent, THE API SHALL require a reason field
2. THE API SHALL reject urgent updates without a reason with appropriate error message
3. THE API SHALL store the urgent reason in the prescription version history
4. WHEN notifying patients of urgent changes, THE API SHALL include the reason in the notification
5. THE API SHALL display the urgent reason in the audit log and prescription history

### Requirement 33: Doctor Patient List with Adherence Monitoring

**User Story:** As a doctor, I want to view my patient list with adherence indicators, so that I can identify patients who need attention.

#### Acceptance Criteria

1. THE API SHALL return a patient list for doctors including: name, gender, age, phone number, current symptoms, and adherence percentage
2. THE API SHALL calculate adherence percentage over a configurable time period (default 30 days)
3. THE API SHALL support color-coded adherence levels: Green (>= 80%), Yellow (50-79%), Red (< 50%)
4. THE API SHALL support sorting patient list by adherence percentage
5. THE API SHALL support pagination for large patient lists

### Requirement 34: Medication Image Support

**User Story:** As a patient, I want to see images of my medications, so that I can easily identify which medicine to take.

#### Acceptance Criteria

1. THE API SHALL support uploading medication images during prescription creation
2. THE API SHALL store medication images in S3 or compatible object storage
3. THE API SHALL return image URLs in medication schedule and detail responses
4. THE API SHALL support image formats: JPEG, PNG, WebP
5. THE API SHALL enforce maximum image size of 5MB per medication image

### Requirement 35: Khmer Language Support

**User Story:** As a Cambodian user, I want the API to support Khmer language for medication names and instructions, so that I can understand my medication plan in my native language.

#### Acceptance Criteria

1. THE API SHALL store medication names in both Khmer and English
2. THE API SHALL support Khmer text for symptoms, instructions, and notes
3. THE API SHALL return localized field names based on user language preference
4. THE API SHALL validate Khmer Unicode text input correctly
5. THE API SHALL support searching medications by Khmer or English names

### Requirement 36: Connection Invitation System

**User Story:** As a patient, I want to invite family members using phone/email/QR code, so that they can support my medication adherence.

#### Acceptance Criteria

1. THE API SHALL support generating connection invitations with unique tokens
2. THE API SHALL support invitation methods: phone number, email, and QR code
3. WHEN a family member accepts an invitation, THE API SHALL create a bidirectional connection
4. THE API SHALL expire invitation tokens after 7 days
5. THE API SHALL record all invitation activities in the audit log

### Requirement 37: Delayed Missed Dose Notifications

**User Story:** As a family member, I want to receive missed dose notifications even when the patient was offline, so that I can still provide support.

#### Acceptance Criteria

1. WHEN a patient misses a dose while offline, THE API SHALL queue the notification for delivery
2. WHEN the patient comes online and syncs, THE API SHALL send delayed notifications to family members
3. THE API SHALL include a timestamp indicating when the dose was actually missed
4. THE API SHALL clearly indicate in the notification that it was sent after reconnection
5. THE API SHALL record all delayed notifications in the audit log

### Requirement 38: Prescription Retake Workflow

**User Story:** As a patient, I want to request prescription retakes when I need clarification or changes, so that my doctor can revise the prescription.

#### Acceptance Criteria

1. THE API SHALL support prescription retake requests with a required reason field
2. WHEN a patient requests a retake, THE API SHALL notify the doctor immediately
3. THE API SHALL mark the prescription status as "pending_revision"
4. THE API SHALL prevent prescription activation until the doctor provides a revised version
5. THE API SHALL record retake requests in the audit log with patient reason

### Requirement 39: Medication Frequency and Timing

**User Story:** As a patient, I want to see medication frequency and timing information, so that I know how often and when to take each medication.

#### Acceptance Criteria

1. THE API SHALL store and return medication frequency (e.g., "3ដង/១ថ្ងៃ" - 3 times per day)
2. THE API SHALL store and return timing information (before meals "មុនអាហារ" or after meals "បន្ទាប់ពីអាហារ")
3. THE API SHALL calculate frequency based on the number of time periods with dosages
4. THE API SHALL support custom frequency values for PRN medications
5. THE API SHALL include frequency and timing in medication detail responses

### Requirement 40: Doctor Prescription History

**User Story:** As a doctor, I want to view my prescription history, so that I can track what I have prescribed to each patient.

#### Acceptance Criteria

1. THE API SHALL provide an endpoint to retrieve doctor's prescription history
2. THE API SHALL support filtering prescription history by patient
3. THE API SHALL support pagination for large prescription histories
4. THE API SHALL return prescription metadata: patient name, date, status, and version count
5. THE API SHALL support sorting by date (newest first by default)
