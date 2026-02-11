# Requirements Document: Doctor Dashboard

## Introduction

The Doctor Dashboard is a core feature of the DasTern healthcare medication management platform that enables doctors to monitor patient medication adherence, create and send prescriptions, manage secure doctor-patient connections, and intervene early when adherence drops. The system follows a supervision model where doctors guide and recommend while patients own execution and confirmation of their medication regimens.

## Glossary

- **Doctor**: A healthcare professional user with privileges to supervise patients, create prescriptions, and monitor adherence
- **Patient**: A user who receives prescriptions, confirms medications, and tracks their own adherence
- **Connection**: A secure, bidirectional relationship between a doctor and patient that enables supervision
- **Prescription**: A structured medical document created by a doctor containing medication instructions
- **Medicine**: An individual medication item within a prescription with specific dosage and schedule
- **Adherence**: The percentage of prescribed medication doses taken on time by a patient
- **Adherence_Indicator**: A visual status showing adherence level (Green: >90%, Yellow: 70-90%, Red: <70%)
- **Dashboard**: The doctor's home view showing overview metrics and alerts
- **Doctor_Note**: A private, time-stamped observation recorded by a doctor about a patient
- **Connection_Request**: A patient-initiated request for doctor supervision
- **Prescription_Status**: The state of a prescription (Pending, Active, Completed, Cancelled)
- **Audit_Trail**: An immutable log of all actions performed in the system
- **System_Notification**: An automated message sent to users about important events

## Requirements

### Requirement 1: Patient Connection Management

**User Story:** As a doctor, I want to review and manage patient connection requests, so that I only supervise patients I explicitly accept and can maintain a manageable care load.

#### Acceptance Criteria

1. WHEN a Patient sends a connection request, THE Dashboard SHALL record the request with timestamp and patient information
2. WHEN a Doctor views pending requests, THE Dashboard SHALL display all unprocessed connection requests with patient details
3. WHEN a Doctor accepts a connection request, THE Dashboard SHALL establish a bidirectional connection and grant mutual access
4. WHEN a Doctor rejects a connection request, THE Dashboard SHALL decline the request and notify the Patient
5. WHEN a Doctor initiates disconnection from a Patient, THE Dashboard SHALL revoke access immediately and notify the Patient
6. WHEN any connection action occurs, THE Dashboard SHALL record the action in the Audit_Trail with timestamp, actor, and action type

### Requirement 2: Doctor Home Dashboard Overview

**User Story:** As a doctor, I want a quick overview of my patients' adherence and alerts, so that I can prioritize care efficiently and identify patients needing immediate attention.

#### Acceptance Criteria

1. WHEN a Doctor loads the Dashboard, THE Dashboard SHALL display the total count of connected patients
2. WHEN a Doctor loads the Dashboard, THE Dashboard SHALL display the count of patients with adherence below 70%
3. WHEN a Doctor loads the Dashboard, THE Dashboard SHALL display today's critical alerts for missed doses
4. WHEN a Doctor loads the Dashboard, THE Dashboard SHALL display a recent activity log showing the last 10 significant events
5. WHEN the Dashboard loads, THE Dashboard SHALL complete rendering within 2 seconds

### Requirement 3: Patient List Management and Filtering

**User Story:** As a doctor, I want to view and filter my patient list by adherence risk and activity, so I can focus on patients who need help first.

#### Acceptance Criteria

1. WHEN a Doctor views the patient list, THE Dashboard SHALL display each patient's name, age, active prescription count, adherence percentage, and last activity timestamp
2. WHEN a Doctor applies an adherence level filter, THE Dashboard SHALL display only patients matching the selected adherence range
3. WHEN a Doctor applies an active prescription filter, THE Dashboard SHALL display only patients with the specified prescription status
4. WHEN a Doctor applies a last active filter, THE Dashboard SHALL display only patients matching the activity timeframe
5. WHEN a Doctor sorts the patient list, THE Dashboard SHALL reorder patients by the selected column in ascending or descending order

### Requirement 4: Patient Detail View

**User Story:** As a doctor, I want to see a patient's full medication and adherence history, so I can make informed treatment decisions and track progress over time.

#### Acceptance Criteria

1. WHEN a Doctor selects a Patient, THE Dashboard SHALL display the patient's basic information including name, age, and contact details
2. WHEN a Doctor views patient details, THE Dashboard SHALL display all active prescriptions with status and dates
3. WHEN a Doctor views patient details, THE Dashboard SHALL display all medicines from active prescriptions with dosage and schedule
4. WHEN a Doctor views patient details, THE Dashboard SHALL display an adherence timeline showing daily adherence percentages for the last 30 days
5. WHEN a Doctor views patient details, THE Dashboard SHALL display all Doctor_Notes associated with that patient in chronological order

### Requirement 5: Prescription Creation and Delivery

**User Story:** As a doctor, I want to create and send prescriptions to patients, so they receive clear and structured medication instructions that they can confirm and follow.

#### Acceptance Criteria

1. WHEN a Doctor creates a Prescription, THE Dashboard SHALL require prescription title, diagnosis, start date, and at least one Medicine
2. WHEN a Doctor adds a Medicine to a Prescription, THE Dashboard SHALL require medicine name, dosage, form, frequency, schedule times, duration, and instructions
3. WHEN a Doctor submits a Prescription, THE Dashboard SHALL set the Prescription_Status to Pending and send a notification to the Patient
4. WHEN a Prescription is created, THE Dashboard SHALL record the creation in the Audit_Trail with doctor ID, patient ID, and timestamp
5. WHEN a Doctor sends a Prescription, THE Dashboard SHALL make it immediately visible to the Patient for review

### Requirement 6: Prescription Confirmation Workflow

**User Story:** As a doctor, I want patients to confirm prescriptions before activation, so that responsibility and understanding are shared and patients acknowledge their treatment plan.

#### Acceptance Criteria

1. WHEN a Prescription is created, THE Dashboard SHALL set the initial Prescription_Status to Pending
2. WHEN a Patient confirms a Prescription, THE Dashboard SHALL change the Prescription_Status to Active
3. WHEN a Prescription_Status is Active, THE Dashboard SHALL prevent the Doctor from editing the prescription content
4. WHEN a Patient rejects a Prescription, THE Dashboard SHALL notify the Doctor and allow prescription revision
5. WHEN a Prescription confirmation occurs, THE Dashboard SHALL record the confirmation in the Audit_Trail with patient ID and timestamp

### Requirement 7: Adherence Monitoring and Alerts

**User Story:** As a doctor, I want to monitor adherence trends and receive alerts for concerning patterns, so I can intervene before treatment fails and patient health deteriorates.

#### Acceptance Criteria

1. WHEN a Doctor views adherence data, THE Dashboard SHALL display daily adherence percentage calculated from taken doses versus scheduled doses
2. WHEN a Doctor views adherence data, THE Dashboard SHALL display the count of missed doses in the selected timeframe
3. WHEN a Doctor views adherence data, THE Dashboard SHALL display dose timing accuracy showing on-time versus late doses
4. WHEN a Doctor views adherence data, THE Dashboard SHALL display weekly adherence trends as a line graph
5. WHEN a Patient misses more than 2 consecutive doses, THE Dashboard SHALL generate a warning alert visible to the Doctor
6. WHEN a Patient has continuous missed doses for 3 or more days, THE Dashboard SHALL generate a critical alert visible to the Doctor
7. WHEN adherence falls below 70%, THE Dashboard SHALL display the Adherence_Indicator as red
8. WHEN adherence is between 70% and 90%, THE Dashboard SHALL display the Adherence_Indicator as yellow
9. WHEN adherence is above 90%, THE Dashboard SHALL display the Adherence_Indicator as green

### Requirement 8: Doctor Notes System

**User Story:** As a doctor, I want to record private notes about patients, so I can track observations, decisions, and clinical reasoning over time without sharing with patients.

#### Acceptance Criteria

1. WHEN a Doctor creates a Doctor_Note, THE Dashboard SHALL require note content and associate it with the current patient
2. WHEN a Doctor creates a Doctor_Note, THE Dashboard SHALL automatically timestamp the note with creation date and time
3. WHEN a Doctor edits their own Doctor_Note, THE Dashboard SHALL allow modification and update the last-modified timestamp
4. WHEN a Doctor views Doctor_Notes, THE Dashboard SHALL display only notes created by that doctor for the selected patient
5. WHEN a Patient views their own data, THE Dashboard SHALL prevent access to Doctor_Notes

### Requirement 9: System Notifications

**User Story:** As a doctor, I want patients to receive clear system notifications about prescriptions and adherence, so they don't miss important updates and stay informed about their treatment.

#### Acceptance Criteria

1. WHEN a Doctor sends a Prescription, THE Dashboard SHALL generate a System_Notification to the Patient with prescription details
2. WHEN a Patient's adherence drops below 70%, THE Dashboard SHALL generate a System_Notification to the Patient with encouragement
3. WHEN a Doctor disconnects from a Patient, THE Dashboard SHALL generate a System_Notification to the Patient with disconnection notice
4. WHEN a follow-up is due, THE Dashboard SHALL generate a System_Notification to the Patient with reminder details
5. THE Dashboard SHALL NOT provide direct chat functionality between doctors and patients

### Requirement 10: Access Control and Security

**User Story:** As a doctor, I want strict role-based access controls, so that patient data remains secure and I can only access information for patients I'm connected to.

#### Acceptance Criteria

1. WHEN a Doctor attempts to view a Patient's data, THE Dashboard SHALL verify an active connection exists before granting access
2. WHEN a Doctor attempts to edit a confirmed Prescription, THE Dashboard SHALL prevent the modification and display an error message
3. WHEN a Doctor attempts to mark a Medicine as taken, THE Dashboard SHALL prevent the action and display an error message
4. WHEN a Doctor attempts to view family-only communication, THE Dashboard SHALL prevent access and display an error message
5. WHEN any access control violation occurs, THE Dashboard SHALL log the attempt in the Audit_Trail

### Requirement 11: Audit Trail and Immutability

**User Story:** As a system administrator, I want all medical actions logged immutably, so that we maintain legal traceability and can investigate any disputes or compliance issues.

#### Acceptance Criteria

1. WHEN a connection is approved or rejected, THE Dashboard SHALL record the action in the Audit_Trail with immutable timestamp
2. WHEN a Prescription is created, THE Dashboard SHALL record the creation in the Audit_Trail with complete prescription data
3. WHEN a Doctor_Note is added or edited, THE Dashboard SHALL record the action in the Audit_Trail with note ID and content hash
4. WHEN a disconnection occurs, THE Dashboard SHALL record the action in the Audit_Trail with both user IDs and reason
5. THE Dashboard SHALL prevent deletion or modification of Audit_Trail entries after creation

### Requirement 12: Performance and Real-Time Updates

**User Story:** As a doctor, I want the dashboard to load quickly and show real-time adherence updates, so I can make timely decisions without waiting for data to refresh.

#### Acceptance Criteria

1. WHEN a Doctor loads the Dashboard, THE Dashboard SHALL complete initial rendering within 2 seconds
2. WHEN a Patient marks a dose as taken, THE Dashboard SHALL update the adherence percentage within 5 seconds
3. WHEN a Patient confirms a Prescription, THE Dashboard SHALL update the prescription status in the doctor's view within 5 seconds
4. WHEN the Dashboard displays patient lists with more than 100 patients, THE Dashboard SHALL implement pagination with 20 patients per page
5. WHEN the Dashboard loads adherence data, THE Dashboard SHALL cache frequently accessed data to improve response time
