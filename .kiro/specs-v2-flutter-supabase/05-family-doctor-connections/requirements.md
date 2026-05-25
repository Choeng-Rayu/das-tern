# Requirements: Connections (Patient↔Patient and Doctor↔Patient)

> **Updated by ADDENDUM-001 (2026-05-25):** Connections are QR-scan only. There are two relationship kinds: Patient↔Patient (mutual peer / family) and Doctor↔Patient (asymmetric clinical). Doctor search and manual code entry are removed.

## Introduction

This spec defines how users link their accounts in Das Tern v2:

- A **Patient** can connect to another **Patient** to mutually share adherence visibility and missed-dose alerts (this is the relationship that v1 called "family").
- A **Patient** and a **Doctor** can connect so the doctor can author prescriptions for the patient (subject to the patient's permission level).

All connections start with one user **generating a QR code** in the app and the other user **scanning** it on their device. The QR payload carries the generator's role so the scanning UI knows what relationship it is establishing.

## Glossary

- **Connection** — A `connections` row linking two profiles. The roles of the two profiles determine the kind: Patient↔Patient, Doctor↔Patient, or invalid.
- **QR_Token** — A short, one-time-use, time-limited token embedded in the QR code's deep link.
- **Role_Aware_QR** — A QR whose payload includes the generator's role so the scanner adapts UX to the resulting relationship.
- **Peer_Patient_Connection** — A Patient↔Patient connection. Mutual visibility and alerts.
- **Clinical_Connection** — A Doctor↔Patient connection. Asymmetric: doctor authors prescriptions; patient owns the data.
- **Permission_Level** — Existing enum on `connections.permission_level`. For peer connections, only `ALLOWED` (active) and `NOT_ALLOWED` (paused) are used in MVP. For clinical connections, all four values apply (`NOT_ALLOWED`, `REQUEST`, `SELECTED`, `ALLOWED`).
- **Connection_Limit** — Subscription-tier-based maximum number of accepted **peer** connections (Patient↔Patient) per Patient. Doctor connections are unlimited.

## Requirements

### Requirement 1: QR generation by either side

**User Story:** As a Patient or Doctor, I want to generate a QR code in the app, so that the person I'm in front of can scan it and request a connection.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Show my connect QR" entry point reachable from settings and from a top-level dashboard action.
2. WHEN the user taps it, THE Flutter_App SHALL `INSERT` a `connection_tokens` row with `patient_id = auth.uid()` (the generator's id, regardless of their role), a 10-character alphanumeric `token`, `expires_at = now() + 1 hour`, `intended_role = <generator's role from profiles>`.
3. THE Flutter_App SHALL display a full-screen QR code encoding the deep link:
   ```
   dastern://connect?token=<token>&role=<PATIENT|DOCTOR>&v=1
   ```
4. THE Flutter_App SHALL show a countdown of remaining validity time and a "Regenerate" button.
5. THE Flutter_App SHALL render the generator's name and role above the QR (e.g., "Dr. Sok — DOCTOR" or "Sopheaktra — PATIENT") so the other person can verify before scanning.
6. THE Flutter_App SHALL NOT support manual short-code entry as an alternative; QR scanning is the only consumption path.
7. THE Postgres scheduled job SHALL purge `connection_tokens` older than 24 hours.

### Requirement 2: QR scan to consume token

**User Story:** As a user with the camera open, I want to scan another person's QR code, so that we connect.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Scan QR to connect" entry point reachable from settings and from a top-level dashboard action.
2. THE Flutter_App SHALL open the camera with a framing overlay; on detection of a Das Tern QR, it SHALL extract `token` and `role` from the deep link.
3. WHEN scanned, THE Flutter_App SHALL call the SQL function `consume_connection_token(p_token)` (defined in `01-supabase-data-layer`).
4. WHEN the function succeeds, THE Flutter_App SHALL fetch the resulting `connections` row and identify the generator's role from `intended_role`. If the generator is a Doctor and the scanner is a Patient, the relationship is **Clinical_Connection**. If both are Patients, it is **Peer_Patient_Connection**. If both are Doctors, the request is rejected (no Doctor↔Doctor in MVP).
5. WHEN the role combination is valid, THE Flutter_App SHALL show a confirmation sheet describing what will be shared, then route to a "Waiting for approval" screen until the generator approves.
6. WHEN the role combination is invalid (Doctor↔Doctor, or self), THE Flutter_App SHALL show a localized error and stop.
7. THE Flutter_App SHALL gracefully handle: token not found, expired, already used, network offline (queue for sync).

### Requirement 3: Role-aware QR payload

**User Story:** As a developer, I want the QR to include the generator's role, so that the scanner can render the correct UX before any server round-trip.

#### Acceptance Criteria

1. THE QR payload SHALL be a deep link of the form `dastern://connect?token=<10char>&role=<PATIENT|DOCTOR>&v=1`.
2. THE `role` query parameter SHALL be informational only — the canonical truth is `connection_tokens.intended_role`. The Flutter_App MUST re-verify role server-side before acting.
3. THE QR SHALL be encoded with error correction level Q (25%) to tolerate camera blur.
4. THE QR SHALL NOT include any PII; only the token + role.

### Requirement 4: Approval by the generator

**User Story:** As the generator, I want to approve every incoming scan, so that I control who actually connects.

#### Acceptance Criteria

1. WHEN a token is consumed, THE `consume_connection_token` SQL function SHALL `INSERT` a `connections` row with `initiator_id = scanner`, `recipient_id = generator`, `status = 'PENDING'`.
2. THE Postgres trigger SHALL emit a `notifications` row to the generator with type `CONNECTION_REQUEST`, including the scanner's name, role, and any introductory metadata.
3. THE Flutter_App SHALL show pending requests on the home dashboard for the generator.
4. WHEN the generator approves, THE Flutter_App SHALL call `accept_connection(connection_id, permission)` SQL function. For peer connections, `permission` defaults to `ALLOWED`; for clinical connections, the patient (always the generator OR the recipient depending on who scanned) chooses from the existing four levels.
5. WHEN the generator rejects, THE Flutter_App SHALL `UPDATE connections SET status = 'REVOKED', revoked_at = now()`.
6. WHEN the generator approves, the scanner SHALL receive a "Connected" notification.

### Requirement 5: Patient↔Patient mutual tracking

**User Story:** As a Patient connected to another Patient, I want to see their adherence and get alerted when they miss a dose, and they should see and be alerted on me.

#### Acceptance Criteria

1. WHEN two Patient profiles establish an ACCEPTED Peer_Patient_Connection with `permission_level = 'ALLOWED'`, THE RLS policies SHALL grant each one read access to the other's `prescriptions`, `medications`, `dose_events`, and `notifications` (the latter only to those targeting the connected pair).
2. WHEN Patient A misses a dose (status transitions `DUE → MISSED`), THE Postgres trigger SHALL emit a `notifications` row of type `FAMILY_ALERT` to **every Patient B** with an ACCEPTED Peer_Patient_Connection to A and `permission_level <> 'NOT_ALLOWED'`.
3. THE alert SHALL include Patient A's name, the medication name, the scheduled time, and a deep link.
4. WHEN Patient B taps the alert, THE Flutter_App SHALL navigate to a read-only view of Patient A's today schedule with the missed dose highlighted.
5. WHEN Patient A subsequently marks the dose as TAKEN_LATE, THE Postgres trigger SHALL emit `DOSE_CONFIRMED` notifications back to Patient B(s).
6. THE behaviour SHALL be symmetrical: if B misses, A is alerted with the same logic.
7. THE Flutter_App in Patient B SHALL provide a "Send a check-in" action on the missed-dose card that creates a notification to A asking if they're OK; rate-limited to 2 per dose event per peer.
8. THE Patient↔Patient connection SHALL **not** allow either side to create or modify the other's prescriptions, medications, or dose events; only read.

### Requirement 6: Doctor↔Patient asymmetric flow

**User Story:** As a Doctor connected to a Patient, I want to author prescriptions for them, and have the patient approve.

#### Acceptance Criteria

1. WHEN a Doctor↔Patient connection is ACCEPTED with `permission_level = 'ALLOWED'`, THE Doctor SHALL be able to read all of the patient's prescriptions, medications, dose events, and adherence (per existing RLS).
2. THE Doctor SHALL be able to `INSERT` new `prescriptions` and `medications` rows with `doctor_id = auth.uid()` and `patient_id = <the connected patient>`. The new prescription SHALL have `status = 'DRAFT'` (or `'ACTIVE'` if `is_urgent = true`).
3. THE Postgres trigger SHALL emit a `PRESCRIPTION_UPDATE` (or `URGENT_PRESCRIPTION_CHANGE`) notification to the patient.
4. THE Patient SHALL see the pending prescription on their home and approve or reject it (per `03-prescription-medication`).
5. WHEN the patient approves, THE prescription SHALL also become readable by the patient's Peer-Patients (their connected family Patients) so they can support adherence.
6. THE Doctor SHALL **not** see the patient's other Peer_Patient connections or their data.
7. THE Patient remains the sole owner of all data; the doctor cannot delete prescriptions; the doctor's edits create new versions per existing rules.

### Requirement 7: Permission levels

**User Story:** As the data owner (always a patient), I want explicit permission levels for who can access what.

#### Acceptance Criteria

1. FOR Doctor↔Patient connections, the four levels (`NOT_ALLOWED / REQUEST / SELECTED / ALLOWED`) work as before. Patient is always the one who sets the level.
2. FOR Patient↔Patient (peer) connections, MVP uses only two effective values:
   - `ALLOWED` (active, mutual visibility)
   - `NOT_ALLOWED` (paused, hides each from the other)
3. THE Flutter_App SHALL surface a simple "Mute" toggle on a peer connection that maps to switching between `ALLOWED` and `NOT_ALLOWED`.
4. THE Flutter_App SHALL preserve the option to revoke (delete the relationship by setting `status = 'REVOKED'`) for peer connections too.
5. WHEN either side mutes a peer connection, **both** sides lose visibility (mutual symmetry); audited as `PERMISSION_CHANGE` with actor recorded.

### Requirement 8: Connection limits

**User Story:** As a freemium user, I want to know my peer-connection limit and how to extend it.

#### Acceptance Criteria

1. THE limits apply only to **peer** Patient↔Patient connections: `FREEMIUM = 1`, `PREMIUM = 5`, `FAMILY_PREMIUM = 10`.
2. Doctor↔Patient connections have **no per-tier limit**; both Patient and Doctor accounts can connect to as many as they need.
3. THE Postgres trigger SHALL count only ACCEPTED peer connections when checking the limit (cf. existing `check_connection_limits` updated to filter on `peer` kind).
4. WHEN exceeded, THE Flutter_App SHALL show a localized "Upgrade for more peer connections" prompt that deep-links to billing.

### Requirement 9: Family Access List + Connections screen

**User Story:** As a user, I want one screen to see all my connections, so that I can manage them.

#### Acceptance Criteria

1. THE Flutter_App SHALL show a "My connections" screen with two sections:
   - **My peers** (Patient↔Patient): each card shows the peer's name, photo, last activity, mute toggle, "Remove" action.
   - **Healthcare providers** (Doctor↔Patient): each card shows the doctor's name, hospital/clinic, specialty, current permission level chip, "Change permission" and "Remove" actions.
2. THE Flutter_App SHALL show the tier-aware peer-count chip ("2 / 5 peers").
3. THE Flutter_App SHALL provide deep-links: peer card → peer detail with their today schedule (read-only); provider card → connection detail (audit history, permission control).

### Requirement 10: Caregiver perspective for the peer-patient

**User Story:** As Patient B (acting as a "family caregiver" to Patient A), I want a simple view of A's adherence when I tap their card, so that I can support them.

#### Acceptance Criteria

1. WHEN Patient B taps a peer card, THE Flutter_App SHALL navigate to a read-only `PeerOverviewPage` showing: today's schedule, current adherence percentage, recent missed-dose history (last 14 days), and a "Send check-in" button.
2. THE page SHALL hide doctor's private notes (already enforced by RLS on `doctor_notes`).
3. THE page SHALL display a banner at the top noting the view is read-only.

### Requirement 11: Connection history and audit

**User Story:** As a user, I want a chronological log of connection events, so that I have audit trail.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a `ConnectionHistoryPage` listing `audit_logs` rows with action types `CONNECTION_REQUEST`, `CONNECTION_ACCEPT`, `CONNECTION_REVOKE`, `PERMISSION_CHANGE`.
2. THE list SHALL include both peer and clinical connection events.
3. Filters: by counterparty, by date range, by action type.

### Requirement 12: Realtime updates

**User Story:** As a connected user, I want my dashboard to update live, so that mutes and revokes take effect immediately.

#### Acceptance Criteria

1. THE Flutter_App SHALL subscribe to `connections` Realtime changes for any row touching the current user.
2. WHEN a row's `permission_level` becomes `NOT_ALLOWED` or `status` becomes `REVOKED`, THE Flutter_App SHALL purge cached counterparty data from Drift and refresh dashboards within 5 seconds.
3. WHEN a peer connection becomes ACCEPTED, both sides' Drift mirrors SHALL bootstrap the counterparty's read-permitted dataset.

### Requirement 13: Offline behaviour

**User Story:** As a user with intermittent connectivity, I want connection actions to queue.

#### Acceptance Criteria

1. THE Flutter_App SHALL queue `consume_connection_token`, `accept_connection`, `UPDATE connections` ops via the outbox.
2. THE Flutter_App SHALL show a "Pending sync" indicator on cards in the meantime.
3. WHEN a queued op fails on sync (token expired between scan and replay), THE Flutter_App SHALL surface the specific error and offer retry / regenerate.

### Requirement 14: Removed in v2

**User Story:** As a stakeholder, I want the spec set explicit about what was removed compared to v1.

#### Acceptance Criteria

1. v2 MVP SHALL NOT support a doctor search-by-name flow.
2. v2 MVP SHALL NOT support manual short-code entry as an alternative to QR scanning.
3. v2 MVP SHALL NOT support a separate FAMILY_MEMBER role.
4. The schema artifacts to support these (search ranks on doctor name, manual entry input, distinct family role) are absent or repurposed.
