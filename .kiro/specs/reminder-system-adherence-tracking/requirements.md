# Requirements Document: Reminder System and Adherence Tracking

## Introduction

The Reminder System and Adherence Tracking feature is the most critical component for DasTern's MVP success. This system ensures patients receive timely medication reminders, tracks their adherence behavior, and alerts family members when doses are missed. The system must be highly reliable, performant, and work seamlessly across online and offline scenarios.

## Glossary

- **Reminder_System**: The backend service responsible for generating, scheduling, and delivering medication reminders
- **Dose_Event**: A recorded action by a patient (taken, skipped, or missed) for a scheduled medication dose
- **Adherence_Calculator**: The component that computes adherence percentages based on dose events
- **Grace_Period**: The configurable time window after a scheduled reminder before marking a dose as missed
- **PRN_Medication**: "Pro Re Nata" - medications taken as needed rather than on a fixed schedule
- **Reminder_Queue**: Redis-based queue for managing scheduled reminders
- **FCM**: Firebase Cloud Messaging service for push notifications
- **Snooze_Action**: Temporary postponement of a reminder by a specified duration
- **Missed_Dose_Alert**: Notification sent to family members when a patient misses a medication dose
- **Adherence_Percentage**: Ratio of taken doses to total scheduled doses over a time period
- **Local_Notification_Service**: Mobile app component that handles offline reminder delivery

## Requirements

### Requirement 1: Automatic Reminder Generation

**User Story:** As a patient, I want reminders to be automatically created when I add medications to my schedule, so that I don't have to manually set up each reminder.

#### Acceptance Criteria

1. WHEN a medication with a schedule is created, THE Reminder_System SHALL generate reminders for all scheduled doses
2. WHEN a medication schedule is updated, THE Reminder_System SHALL regenerate reminders to reflect the new schedule
3. WHEN a medication is deleted, THE Reminder_System SHALL remove all associated pending reminders
4. WHEN calculating reminder times, THE Reminder_System SHALL use the patient's meal time preferences to determine exact notification times
5. WHERE a medication is marked as PRN, THE Reminder_System SHALL not generate automatic time-based reminders
6. WHEN a reminder is generated, THE Reminder_System SHALL store it in the database with status "pending"
7. WHEN generating reminders, THE Reminder_System SHALL create reminders for the next 30 days

### Requirement 2: Multi-Channel Reminder Delivery

**User Story:** As a patient, I want to receive medication reminders through push notifications, so that I'm notified even when the app is closed.

#### Acceptance Criteria

1. WHEN a reminder's scheduled time arrives, THE Reminder_System SHALL send a push notification via FCM to the patient's registered devices
2. WHEN sending a push notification, THE Reminder_System SHALL include medication name, dosage, and scheduled time in the notification payload
3. WHEN a push notification is sent, THE Reminder_System SHALL update the reminder status to "delivered"
4. IF push notification delivery fails, THEN THE Reminder_System SHALL retry up to 3 times with exponential backoff
5. WHEN a reminder is delivered, THE Reminder_System SHALL log the delivery timestamp
6. WHEN the patient's device is offline, THE Local_Notification_Service SHALL queue the notification for delivery when connectivity is restored
7. WHEN displaying notifications, THE Reminder_System SHALL use the patient's preferred language (Khmer or English)

### Requirement 3: Snooze Functionality

**User Story:** As a patient, I want to snooze a reminder if I'm not ready to take my medication immediately, so that I'm reminded again after a short delay.

#### Acceptance Criteria

1. WHEN a patient receives a reminder notification, THE Reminder_System SHALL provide snooze options of 5, 10, and 15 minutes
2. WHEN a patient selects a snooze duration, THE Reminder_System SHALL reschedule the reminder for the selected duration from the current time
3. WHEN a reminder is snoozed, THE Reminder_System SHALL update the reminder status to "snoozed" and record the snooze timestamp
4. WHEN a snoozed reminder's new time arrives, THE Reminder_System SHALL deliver the notification again
5. WHEN a reminder has been snoozed 3 times, THE Reminder_System SHALL not offer additional snooze options

### Requirement 4: Dose Event Recording

**User Story:** As a patient, I want to mark my doses as taken or skipped, so that my adherence is accurately tracked.

#### Acceptance Criteria

1. WHEN a patient marks a dose as taken, THE Reminder_System SHALL create a Dose_Event with status "taken" and the current timestamp
2. WHEN a patient marks a dose as skipped, THE Reminder_System SHALL create a Dose_Event with status "skipped" and the current timestamp
3. WHEN a patient marks a dose as taken, THE Reminder_System SHALL dismiss the active reminder notification
4. WHEN a Dose_Event is created, THE Reminder_System SHALL associate it with the corresponding medication and scheduled time
5. WHEN a patient marks a dose within the grace period, THE Reminder_System SHALL record it as on-time
6. WHEN a patient marks a dose after the grace period but within 24 hours, THE Reminder_System SHALL record it as late
7. WHEN a patient attempts to mark a dose more than 24 hours after the scheduled time, THE Reminder_System SHALL reject the action and return an error

### Requirement 5: Automatic Missed Dose Detection

**User Story:** As a patient, I want the system to automatically detect when I miss a dose, so that my adherence record is accurate without manual intervention.

#### Acceptance Criteria

1. WHEN the grace period expires after a scheduled reminder, THE Reminder_System SHALL check if a Dose_Event exists for that reminder
2. IF no Dose_Event exists after the grace period, THEN THE Reminder_System SHALL create a Dose_Event with status "missed"
3. WHEN a dose is marked as missed, THE Reminder_System SHALL record the scheduled time and the detection timestamp
4. WHEN a missed dose is detected, THE Reminder_System SHALL update the reminder status to "missed"
5. WHEN a missed dose is detected, THE Reminder_System SHALL trigger a Missed_Dose_Alert to the patient
6. WHEN a missed dose is detected, THE Reminder_System SHALL trigger Missed_Dose_Alerts to all connected family members

### Requirement 6: Repeat Reminders for Missed Doses

**User Story:** As a patient, I want to receive repeat reminders if I haven't responded to the initial notification, so that I don't forget to take my medication.

#### Acceptance Criteria

1. WHEN a reminder has been delivered and no Dose_Event is recorded within 10 minutes, THE Reminder_System SHALL send a repeat reminder
2. WHEN sending repeat reminders, THE Reminder_System SHALL send up to 3 repeat notifications before the grace period expires
3. WHEN a repeat reminder is sent, THE Reminder_System SHALL include text indicating this is a repeat notification
4. WHEN a patient records a Dose_Event, THE Reminder_System SHALL cancel all pending repeat reminders for that dose
5. WHERE repeat reminders are disabled in patient settings, THE Reminder_System SHALL not send repeat notifications

### Requirement 7: Real-Time Adherence Calculation

**User Story:** As a patient, I want to see my medication adherence percentage in real-time, so that I can monitor my progress and stay motivated.

#### Acceptance Criteria

1. WHEN a Dose_Event is created, THE Adherence_Calculator SHALL recalculate the patient's adherence percentage
2. WHEN calculating adherence, THE Adherence_Calculator SHALL use the formula: (taken_doses / total_scheduled_doses) × 100
3. WHEN calculating adherence, THE Adherence_Calculator SHALL exclude PRN medications from the calculation
4. WHEN calculating adherence, THE Adherence_Calculator SHALL count "taken" doses as compliant and "missed" or "skipped" as non-compliant
5. WHEN calculating adherence, THE Adherence_Calculator SHALL support daily, weekly, and monthly time periods
6. WHEN adherence is calculated, THE Adherence_Calculator SHALL cache the result in Redis with a 5-minute TTL
7. WHEN a patient queries their adherence, THE Adherence_Calculator SHALL return the cached value if available

### Requirement 8: Adherence Trend Visualization

**User Story:** As a patient, I want to view my adherence trends over time, so that I can identify patterns and improve my medication-taking behavior.

#### Acceptance Criteria

1. WHEN a patient requests adherence history, THE Adherence_Calculator SHALL return daily adherence percentages for the requested period
2. WHEN displaying adherence data, THE Reminder_System SHALL provide color-coded indicators: green for ≥90%, yellow for 70-89%, red for <70%
3. WHEN calculating trends, THE Adherence_Calculator SHALL provide weekly and monthly aggregated adherence percentages
4. WHEN a patient has no scheduled doses for a day, THE Adherence_Calculator SHALL exclude that day from trend calculations
5. WHEN adherence data is requested, THE Reminder_System SHALL return data for up to 90 days in the past

### Requirement 9: Reminder Configuration and Customization

**User Story:** As a patient, I want to customize reminder settings for each medication, so that reminders fit my personal schedule and preferences.

#### Acceptance Criteria

1. WHEN a patient updates reminder times for a medication, THE Reminder_System SHALL regenerate all future reminders with the new times
2. WHEN a patient disables reminders for a medication, THE Reminder_System SHALL cancel all pending reminders but continue tracking scheduled doses
3. WHEN a patient enables reminders for a medication, THE Reminder_System SHALL generate reminders for all future scheduled doses
4. WHEN a patient updates the grace period setting, THE Reminder_System SHALL apply the new grace period to all future reminders
5. WHERE a patient sets a custom grace period, THE Reminder_System SHALL support values of 10, 20, 30, or 60 minutes
6. WHEN a patient updates repeat reminder frequency, THE Reminder_System SHALL apply the new frequency to future reminders
7. WHEN reminder settings are updated, THE Reminder_System SHALL persist the changes to the database immediately

### Requirement 10: Offline Support and Synchronization

**User Story:** As a patient, I want reminders to work even when I'm offline, so that I don't miss doses due to connectivity issues.

#### Acceptance Criteria

1. WHEN the mobile app is offline, THE Local_Notification_Service SHALL deliver scheduled reminders using local device notifications
2. WHEN the mobile app comes online, THE Local_Notification_Service SHALL sync all Dose_Events recorded offline to the backend
3. WHEN syncing offline Dose_Events, THE Reminder_System SHALL validate timestamps and reject events older than 24 hours from scheduled time
4. WHEN the patient's device time zone changes, THE Local_Notification_Service SHALL adjust reminder times to maintain the same local time
5. WHEN syncing, THE Reminder_System SHALL resolve conflicts by prioritizing the earliest recorded Dose_Event for a given scheduled dose
6. WHEN offline, THE Local_Notification_Service SHALL queue up to 100 pending reminders locally
7. WHEN the local queue exceeds 100 reminders, THE Local_Notification_Service SHALL prioritize the nearest scheduled reminders

### Requirement 11: Family Member Missed Dose Alerts

**User Story:** As a family member, I want to receive alerts when my connected patient misses a dose, so that I can check on them and provide support.

#### Acceptance Criteria

1. WHEN a dose is marked as missed, THE Reminder_System SHALL send push notifications to all connected family members
2. WHEN sending missed dose alerts to family, THE Reminder_System SHALL include patient name, medication name, and scheduled time
3. WHEN a family member receives a missed dose alert, THE Reminder_System SHALL provide a deep link to view the patient's adherence details
4. WHERE a patient has disabled family notifications in settings, THE Reminder_System SHALL not send missed dose alerts to family members
5. WHEN multiple doses are missed in a short period, THE Reminder_System SHALL batch alerts and send a summary notification to family members
6. WHEN a missed dose alert is sent, THE Reminder_System SHALL log the notification in the patient's activity history

### Requirement 12: Performance and Reliability Requirements

**User Story:** As a system administrator, I want the reminder system to be highly reliable and performant, so that patients receive timely notifications without delays.

#### Acceptance Criteria

1. WHEN a scheduled reminder time arrives, THE Reminder_System SHALL trigger the notification within 300 milliseconds
2. WHEN processing reminder delivery, THE Reminder_System SHALL achieve 99.9% delivery reliability
3. WHEN the system is under load, THE Reminder_System SHALL process at least 10,000 reminders per minute
4. WHEN querying adherence data, THE Adherence_Calculator SHALL return results within 200 milliseconds
5. WHEN the Reminder_Queue is unavailable, THE Reminder_System SHALL fall back to database polling with 1-minute intervals
6. WHEN database queries timeout, THE Reminder_System SHALL retry with exponential backoff up to 3 times
7. WHEN Redis cache is unavailable, THE Adherence_Calculator SHALL compute adherence from the database directly

### Requirement 13: Multi-Language Notification Support

**User Story:** As a patient, I want to receive reminders in my preferred language, so that I can easily understand the notifications.

#### Acceptance Criteria

1. WHEN sending a reminder notification, THE Reminder_System SHALL use the patient's language preference setting
2. WHEN the patient's language is set to Khmer, THE Reminder_System SHALL send all notification text in Khmer
3. WHEN the patient's language is set to English, THE Reminder_System SHALL send all notification text in English
4. WHEN a patient updates their language preference, THE Reminder_System SHALL apply the new language to all future notifications immediately
5. WHERE a translation is missing for a notification template, THE Reminder_System SHALL fall back to English

### Requirement 14: Reminder History and Audit Trail

**User Story:** As a patient, I want to view my reminder history, so that I can review past notifications and dose-taking patterns.

#### Acceptance Criteria

1. WHEN a patient requests reminder history, THE Reminder_System SHALL return all reminders for the requested time period
2. WHEN displaying reminder history, THE Reminder_System SHALL include reminder time, delivery status, and associated Dose_Event
3. WHEN a reminder is delivered, snoozed, or dismissed, THE Reminder_System SHALL log the action with a timestamp
4. WHEN querying reminder history, THE Reminder_System SHALL support filtering by medication, date range, and status
5. WHEN reminder history is requested, THE Reminder_System SHALL return data for up to 90 days in the past
6. WHEN displaying history, THE Reminder_System SHALL paginate results with 50 items per page

### Requirement 15: Grace Period Configuration

**User Story:** As a patient, I want to configure how long the system waits before marking a dose as missed, so that the grace period matches my routine.

#### Acceptance Criteria

1. WHEN a patient sets a grace period, THE Reminder_System SHALL validate that the value is one of: 10, 20, 30, or 60 minutes
2. WHEN no grace period is configured, THE Reminder_System SHALL use a default value of 30 minutes
3. WHEN the grace period is updated, THE Reminder_System SHALL apply the new value to all future scheduled reminders
4. WHEN the grace period is updated, THE Reminder_System SHALL not retroactively change already-scheduled reminders
5. WHEN calculating if a dose is missed, THE Reminder_System SHALL use the grace period that was active when the reminder was scheduled
