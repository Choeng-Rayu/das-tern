# Doctor ↔ Patient Connection + Prescription Update Flow

## Goals

- Allow doctor and patient to connect with **mutual acceptance**
- Ensure **patient controls permission levels**
- Allow doctor to update prescriptions with **version history**, including urgent auto-apply

---

## Flow 1: Doctor Initiates Connection

```mermaid
sequenceDiagram
    participant D as Doctor
    participant S as System
    participant P as Patient

    D->>S: Request Connection
    S->>P: Connection Request Notification
    P->>S: Accept/Decline
    alt Accepted
        S->>P: Show Permission Popup
        P->>S: Set Permission Level
        Note over P,S: NOT_ALLOWED / REQUEST / SELECTED / ALLOWED
        alt No Selection (clicks OK)
            S->>S: Apply Default: History/Report View
        end
        S->>D: Connection Confirmed
        S->>S: Log Connection in Audit
    else Declined
        S->>D: Connection Declined
    end
```

### Steps

1. Doctor selects patient and taps **"Request Connection"**
2. Patient receives request and accepts/declines
3. If accepted:
   - Permission popup appears for patient
   - Patient sets permission enum: `NOT_ALLOWED` / `REQUEST` / `SELECTED` / `ALLOWED`
   - If patient clicks OK without selecting → Default = history/data-report view is allowed

### User Stories

- As a doctor, I can request connection so I can support patient adherence after they accept.
- As a patient, I approve or decline doctor connection so I control my privacy.

---

## Flow 2: Patient Initiates Connection

```mermaid
sequenceDiagram
    participant P as Patient
    participant S as System
    participant D as Doctor

    P->>S: Search/Select Doctor
    P->>S: Request Connection
    S->>D: Connection Request Notification
    D->>S: Accept/Decline
    alt Accepted
        S->>P: Show Permission Popup
        P->>S: Set Permission Level
        Note over P,S: Patient controls permissions even when initiating
        S->>D: Connection Confirmed
        S->>S: Log Connection in Audit
    else Declined
        S->>P: Connection Declined
    end
```

### Steps

1. Patient searches/selects doctor and taps **"Request Connection"**
2. Doctor accepts/declines
3. If accepted:
   - Patient sets permission enum for doctor
   - Default applies if patient clicks OK

### User Story

- As a patient, I connect to my doctor so my doctor can monitor adherence with my consent.

---

## Flow 3: Doctor Modifies Prescription (Normal)

```mermaid
sequenceDiagram
    participant D as Doctor
    participant S as System
    participant P as Patient

    D->>S: Open Patient Profile
    Note over D,S: Only if connected and permitted
    D->>S: Create New Prescription Version
    S->>S: Store New Version (keep old in history)
    S->>P: Notification: Prescription Updated
    P->>S: Review Changes
    P->>S: Accept Changes
    S->>S: Activate New Version
    S->>S: Regenerate Schedule
    S->>S: Log in Audit
```

### Steps

1. Doctor opens patient profile (only if connected and permitted)
2. Doctor creates new version of prescription
3. Patient is notified
4. Patient accepts change (if non-urgent policy)
5. New version becomes active, schedule regenerated

### User Stories

- As a doctor, I can update prescription so the patient follows correct treatment.
- As a patient, I approve non-urgent changes so I understand what changes.

---

## Flow 4: Doctor Modifies Prescription (Urgent Auto-Apply)

```mermaid
sequenceDiagram
    participant D as Doctor
    participant S as System
    participant P as Patient

    D->>S: Mark Update as URGENT
    D->>S: Submit Prescription Changes
    S->>S: Auto-Apply New Version Immediately
    S->>S: Store in History with Urgent Flag
    S->>P: URGENT Notification
    Note over S: Audit Log Records:<br/>• Urgent flag<br/>• Doctor ID<br/>• Timestamp<br/>• Reason<br/>• Version link
    S->>S: Regenerate Schedule
```

### Steps

1. Doctor marks update as **urgent**
2. System **auto-applies** the new version immediately
3. Patient receives urgent notification
4. History/audit log must include:
   - Urgent flag
   - Doctor
   - Timestamp
   - Reason
   - Version link

### User Stories

- As a doctor, I can urgently update prescription so the patient immediately follows the safer plan.
- As a patient, I can see urgent updates in my history so I trust the system.

---

## Permission Reference

| Permission | Access Level |
|------------|--------------|
| `NOT_ALLOWED` | No access to patient data |
| `REQUEST` | Must request access each time |
| `SELECTED` | Access to specific items only |
| `ALLOWED` | Full access to allowed scope (history/reports) |

> [!IMPORTANT]
> Even after connection, the **patient remains the owner** and can change permission levels at any time.

---

## Acceptance Criteria

- [ ] Doctor cannot view patient data without an accepted connection
- [ ] Connection requires mutual acceptance from both parties
- [ ] Patient can set and change permission levels at any time
- [ ] Prescription updates create new versions (no destructive edits)
- [ ] Urgent updates are auto-applied with full audit trail
- [ ] All connection and permission changes are logged
