# Business Logic – Manual Prescription Platform

This document defines the core rules and behaviors of the platform: prescriptions, dose tracking, reminders (online/offline), connections/permissions, audit history, and monetization.

---

## 1. Roles and Ownership

### Three Main User Roles

| Role | Description |
|------|-------------|
| **Patient** | Primary user who owns all medical data |
| **Family/Caregiver** | Uses the same app, can be connected to patient |
| **Doctor** | Healthcare provider connected to patients |

### Ownership Rule

> [!IMPORTANT]
> The **patient is always the owner** of their medical data. All viewing or actions by Family or Doctor must be allowed by patient permission settings.

**User Story:**
- As a patient, I own my prescription and dose records, so I can control who can access my data.

---

## 2. Patient ↔ Doctor Connection Policy (Two-way Accept)

Connection can be initiated by either side, but **MUST be accepted by the other**.

### Case A: Doctor Initiates Connection

1. Doctor sends connection request to patient
2. Patient must accept
3. After patient accepts, patient chooses permission level for doctor

### Case B: Patient Initiates Connection

1. Patient sends connection request to doctor
2. Doctor must accept
3. After doctor accepts, patient chooses permission level for doctor

> [!NOTE]
> Even if the doctor accepts, the patient remains the owner and controls permission level.

### Permission Enum for Doctor Access

| Permission | Description |
|------------|-------------|
| `NOT_ALLOWED` | Doctor has no access |
| `REQUEST` | Doctor must request access each time or for a specific type of access (policy-based) |
| `SELECTED` | Doctor has access only to selected items (e.g., selected prescriptions or time range) |
| `ALLOWED` | Doctor has access according to allowed scope (default view/history/report level) |

### Default Permission Behavior

When connection is confirmed, the system shows a permission popup:
- If user clicks **"OK"** without changing anything:
  - **Default = Doctor can view patient history and data report**

### User Stories

- As a doctor, I can request to connect to a patient, so I can monitor adherence once the patient accepts.
- As a patient, I can connect to a doctor, so my doctor can help manage my medication plan.
- As a patient, I can set doctor permission to NOT_ALLOWED/REQUEST/SELECTED/ALLOWED, so I stay in control of my privacy.

### Acceptance Criteria

- [ ] A doctor cannot view patient data without an accepted connection
- [ ] After connection, doctor access is controlled by the patient permission enum
- [ ] Default permission applies only when user clicks OK without selecting custom permissions

---

## 3. Patient ↔ Family Connection Advantages

Family members also use the same app. After connection:

- Family receives **missed-dose alerts** based on patient reminder/escalation rules
- Both sides can share view history records of each other after connection (**mutual view**), but still controlled by permission rules

> [!IMPORTANT]
> - Patient can revoke family access anytime
> - All actions from family are audit logged

### User Stories

- As a patient, I connect my family so they can remind me when I miss medication.
- As a family member, I receive alerts so I can support the patient to take medicine on time.
- As a patient, I can revoke family access anytime so I can protect my privacy.

### Acceptance Criteria

- [ ] If patient misses medication (based on missed rule), family gets notified when online or later when sync occurs
- [ ] Connection allows viewing history records depending on permission settings
- [ ] Revoking permission removes access immediately

---

## 4. Prescription Lifecycle

### Prescription Status

| Status | Description |
|--------|-------------|
| `Draft` | Saved but not active, no schedule/reminders |
| `Active` | Schedule generated, reminders enabled |
| `Paused` | Temporary stop, history remains |
| `Inactive/Stopped` | Ended, history remains |

### Versioning Rule

> [!IMPORTANT]
> **No destructive edits.** Doctor modifications create a new version and keep the old version in history. All changes recorded in audit log.

### Urgent Change Rule

- Doctor can auto-apply changes (urgent)
- Even if auto-applied, it **must still appear in patient history and audit logs**

### User Stories

- As a doctor, I can urgently change a prescription and auto-apply it, so the patient immediately follows the new schedule.
- As a patient, I can see urgent changes in history, so I know what changed and why.

### Acceptance Criteria

- [ ] Auto-applied changes create a new version
- [ ] History shows: who changed, what changed, when, and reason
- [ ] Patient is notified even when auto-applied

---

## 5. Dose Event States and Adherence Classification

### DoseEvent Status

| Status | Description |
|--------|-------------|
| `Due` | Medication is scheduled and waiting |
| `Taken (On time)` | Taken within allowed window |
| `Taken (Late)` | Taken after window but before cutoff |
| `Missed` | Past cutoff without taken |
| `Skipped` | (Optional) Skipped with reason |

### Time-Window Logic

```
[Dose Time] ────────────────────────────────────────────►
            │◄── Allowed Window ──►│◄── Late Period ──►│
            │                      │                   │
            ▼                      ▼                   ▼
        Taken (On time)       Taken (Late)          Missed
```

**User Story:**
- As a patient, I can mark taken, so my adherence record is accurate.

---

## 6. Reminder Logic (Online + Offline)

> [!WARNING]
> Reminder **must work in both online and offline states**.

### A) Reminder Creation Behavior

When prescription becomes Active:
1. Generate DoseEvents (schedule)
2. Store schedule in:
   - Backend database
   - Local storage on device

This ensures offline reminders can still fire even without internet.

**User Story:**
- As a patient, I still receive reminders even when offline, so I don't miss medication.

### B) Offline Reminder Delivery

- Phone uses local schedule to send notification to patient
- If patient taps "Taken" while offline:
  - Store the action in local storage queue (pending sync)
- When device comes online:
  - Sync the queued actions to backend
  - Backend updates DoseEvent records and audit log

**User Story:**
- As a patient, I can mark taken offline and it will sync later, so my records stay correct.

### C) Offline Missed-Dose Handling & Family Notification

**Problem:** Offline device can detect missed dose locally, but cannot notify family immediately.

**Rule:**
1. If missed happens offline → Store missed state locally
2. When online → System syncs and THEN sends missed alert to connected family automatically

> [!NOTE]
> Late family alert must clearly say it was sent after reconnect/sync.

### User Stories

- As a family member, I still get notified about missed doses even if the patient was offline, so I can follow up.
- As a patient, I understand late alerts happen after reconnect, so I don't get confused.

### Acceptance Criteria

- [ ] Offline patient reminders still fire on time (local notifications)
- [ ] Offline taken actions sync when online and update backend
- [ ] Offline missed alerts are delivered to family after online sync (late but guaranteed)

---

## 7. PRN (As Needed) Behavior

PRN = "as needed" medication.

### Default Behavior

- System uses **Cambodia time** as the default timezone
- User should input reminder time(s)
- If user does not input reminder time(s):
  - System automatically uses default reminder times (Cambodia timezone presets)
  - Example presets: morning/noon/evening/night

### User Stories

- As a patient, I can set PRN reminder times, so reminders match my real usage.
- As a patient, if I skip setting times, the app uses default Cambodia-time presets so I still get reminders.

### Acceptance Criteria

- [ ] PRN supports manual "Taken" without strict schedule if configured
- [ ] If no PRN times entered, app auto-assigns default times using Cambodia timezone

---

## 8. Audit Logs

AuditLog must record:

| Event Type | Description |
|------------|-------------|
| Connection requests | Requests and acceptances |
| Permission changes | Enum changes |
| Access logs | Who viewed what (based on policy) |
| Prescription changes | Creation and version changes |
| Urgent updates | Auto-apply changes |
| Reminders | Sent notifications (including offline-late) |
| Dose events | Taken/missed events and sync time |

**User Story:**
- As a patient, I can audit who accessed or changed my data, so I trust the system.

---

## 9. Monetization Business Model

### Subscription Roles

| Plan | Price | Storage | Features |
|------|-------|---------|----------|
| **FREEMIUM** | Free | 5GB | MVP: Create medication (manual), generate reminders, store records |
| **PREMIUM** | $0.50/month | 20GB | All features enabled |
| **FAMILY_PREMIUM** | $1/month | 20GB | Premium + Family plan (up to 3 members total) |

### FREEMIUM

**User Story:**
- As a freemium user, I can manage my prescriptions and reminders, so I can use the core app for free.

### PREMIUM

**User Story:**
- As a premium user, I pay monthly so I can use all features and get more storage.

### FAMILY_PREMIUM

- Includes premium benefits
- Family plan: up to 3 members total (including the payer)
- All members become premium users

**User Story:**
- As a patient, I pay for a family plan so my family members can also use premium features to support me.

### Acceptance Criteria

- [ ] Plan determines available features + storage enforcement
- [ ] Family plan cannot exceed 3 members total
- [ ] Upgrading plan unlocks feature access immediately after payment confirmation
