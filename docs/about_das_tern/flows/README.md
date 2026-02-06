# Application Flows

This directory contains detailed flow documentation for the DasTern medication management platform.

## Flow Categories

### 1. [Create Medication Flow](./create_medication_flow/README.md)
How patients and doctors create new prescriptions and set up medication schedules.

### 2. [Doctor-Patient Prescription Flow](./doctor_send_prescriptoin_to_patient_flow/README.md)
Connection establishment between doctors and patients, including:
- Doctor-initiated connection
- Patient-initiated connection
- Normal prescription modifications
- Urgent auto-apply prescription updates

### 3. [Family Connection Flow](./family_connection_flow/README.md)
How patients connect with family members for medication adherence support:
- Connection invitation and acceptance
- Missed-dose alert notifications
- Shared history viewing

### 4. [Reminder Flow](./reminder_flow/README.md)
The complete reminder system covering:
- Online and offline reminder delivery
- Notification triggers and escalation
- Sync mechanisms for offline actions

## Core Principles

All flows adhere to these principles:

1. **Patient Ownership** - Patient always owns their data
2. **Mutual Consent** - All connections require two-way acceptance
3. **Offline Support** - Critical features work without internet
4. **Audit Trail** - All actions are logged for transparency
