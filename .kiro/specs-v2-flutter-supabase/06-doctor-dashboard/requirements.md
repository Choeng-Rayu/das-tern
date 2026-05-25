# Requirements: Doctor Dashboard

## Introduction

This spec defines the doctor-facing UX for monitoring connected patients, authoring prescriptions, recording private notes, and acting on adherence alerts. All data access is gated by the same RLS-protected `connections` table; the dashboard is a read-mostly view with prescription authoring delegated to spec `03-prescription-medication`.

## Glossary

- **Doctor_Home** — Top-level dashboard with summary metrics and alerts.
- **Patient_List** — Filterable list of connected patients.
- **Patient_Detail** — Per-patient view with prescriptions, adherence, and notes.
- **Doctor_Note** — A private `doctor_notes` row visible only to the authoring doctor.
- **Adherence_Indicator** — Color badge: green ≥90%, yellow 70-89%, red <70%.
- **Critical_Alert** — A surfaced notification when a patient has 3+ consecutive missed doses or a single urgent adverse event.

## Requirements

### Requirement 1: Doctor home dashboard

**User Story:** As a doctor, I want a dashboard summarizing my patients, so that I can prioritize care.

#### Acceptance Criteria

1. WHEN the doctor opens the app, THE Flutter_App SHALL show: total connected patients, count below 70% adherence, today's critical alerts, recent activity log (last 10).
2. THE Flutter_App SHALL render the dashboard in <2 seconds on a 4G connection.
3. THE Flutter_App SHALL refresh metrics on app foreground and on Realtime connection updates.

### Requirement 2: Patient list with filters

**User Story:** As a doctor, I want to filter and sort my patients, so that I can find specific cases quickly.

#### Acceptance Criteria

1. THE Flutter_App SHALL show patient name, age, active prescription count, today's adherence, last activity timestamp.
2. THE Flutter_App SHALL provide filters: adherence band (green/yellow/red/all), prescription status, last-active window (today, 7d, 30d).
3. THE Flutter_App SHALL provide sort columns: name, adherence, last activity.
4. THE Flutter_App SHALL paginate at 20 patients per page using cursor pagination on `last_activity_at`.

### Requirement 3: Patient detail view (read)

**User Story:** As a doctor, I want a comprehensive view of a patient's medical state, so that I can make informed decisions.

#### Acceptance Criteria

1. THE Flutter_App SHALL display patient basic info, all active and paused prescriptions, all medications, last 30 days adherence timeline (chart), and the doctor's own private notes.
2. THE Flutter_App SHALL show prescription versions with diff highlighting.
3. THE Flutter_App SHALL show today's dose events with status badges.
4. THE Flutter_App SHALL hide content the doctor's permission level doesn't permit (e.g., `permission_level = 'REQUEST'` shows only summary, no detail; doctor must request access to see specific data).

### Requirement 4: Prescription authoring

**User Story:** As a doctor, I want to create and edit prescriptions for connected patients with `permission_level = 'ALLOWED'`, so that I can drive treatment.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide "New prescription" and "Edit prescription" entry points from patient detail.
2. THE Flutter_App SHALL set `is_urgent = true` on a doctor-toggled urgent action with required `urgent_reason`.
3. THE Flutter_App SHALL prevent edits to a prescription that has been confirmed by the patient (status `ACTIVE`) by spawning a new version (per `03-prescription-medication`).
4. THE Flutter_App SHALL block authoring when `permission_level <> 'ALLOWED'` and prompt the patient to grant.

### Requirement 5: Doctor notes

**User Story:** As a doctor, I want to record private observations, so that I can track clinical reasoning over time.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Notes" tab in patient detail.
2. THE Flutter_App SHALL allow creating, editing, and deleting notes authored by the current doctor.
3. THE Flutter_App SHALL display notes chronologically with last-modified timestamps.
4. THE doctor_notes RLS policy SHALL ensure other doctors and the patient never see these.
5. THE Flutter_App SHALL sync notes via Drift + outbox.

### Requirement 6: Adherence alerts

**User Story:** As a doctor, I want alerts for patients whose adherence is failing, so that I can intervene.

#### Acceptance Criteria

1. THE Postgres view SHALL flag patients with ≥3 consecutive missed doses or adherence <70% over 7 days.
2. THE Flutter_App SHALL show a "Critical alerts" section on the home dashboard listing these patients.
3. WHEN tapping an alert, THE Flutter_App SHALL navigate to the patient detail with the missed dose period highlighted.
4. THE Flutter_App SHALL allow dismissing alerts that have been acknowledged (stored as a flag in `notifications.data.acknowledged`).

### Requirement 7: Realtime updates

**User Story:** As a doctor, I want my dashboard to update live as patients confirm doses, so that I see fresh data.

#### Acceptance Criteria

1. THE Flutter_App SHALL subscribe to Realtime channels: `dose_events`, `prescriptions`, `connections` (filtered by RLS).
2. THE Flutter_App SHALL update individual patient cards within 5 seconds of a remote change.
3. THE Flutter_App SHALL handle channel disconnects with reconnect-with-backoff up to 60s.

### Requirement 8: Connection management entry from doctor side

**User Story:** As a doctor, I want to add new patients via QR (scan or show), manage incoming requests, and revoke connections, so that I keep my caseload manageable.

#### Acceptance Criteria

1. THE Flutter_App SHALL show "Show QR to a patient" and "Scan a patient's QR" actions on the doctor home (per `05-family-doctor-connections`). The doctor SHALL NOT have a search-by-name feature for finding patients (ADDENDUM-001).
2. THE Flutter_App SHALL show pending connection requests (from patients who scanned the doctor's QR) in a notifications inbox.
3. THE Flutter_App SHALL allow accepting or declining each.
4. THE Flutter_App SHALL allow disconnecting from a patient with confirmation; the patient receives a notification.

### Requirement 9: Performance

**User Story:** As a doctor with many patients, I want the app to remain responsive, so that I don't waste time waiting.

#### Acceptance Criteria

1. THE Flutter_App SHALL paginate patient list at 20 per page.
2. THE Flutter_App SHALL cache `get_adherence` results in Drift for 5 minutes per patient.
3. THE Flutter_App SHALL debounce search inputs at 300 ms.
4. THE Flutter_App SHALL pre-warm the Drift mirror for the doctor's own role on sign-in (only their own notes; patient data fetched on demand).

### Requirement 10: Accessibility & localization

**User Story:** As a doctor in Cambodia, I want the dashboard in Khmer or English, so that I can read it comfortably.

#### Acceptance Criteria

1. THE Flutter_App SHALL apply the language preference saved in the doctor's `profiles.language`.
2. THE Flutter_App SHALL meet WCAG AA contrast.
3. THE Flutter_App SHALL support screen readers for all interactive elements.
4. THE Flutter_App SHALL ensure tap targets ≥ 44x44.
