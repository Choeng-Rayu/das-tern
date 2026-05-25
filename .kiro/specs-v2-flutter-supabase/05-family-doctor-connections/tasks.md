# Tasks: Connections (Patient↔Patient and Doctor↔Patient)

> **Updated by ADDENDUM-001 (2026-05-25):** QR-only flow. Doctor search and manual code entry removed. Mutual peer-Patient model.

## Phase 1 — SQL functions and triggers (1 day)

- [ ] **1.1** Update `consume_connection_token(...)` to reject Doctor↔Doctor scans (per design § 3).
- [ ] **1.2** Replace `is_connected_family_for(...)` with `is_connected_peer_patient_for(...)` (per design § 5). Update all RLS policies that referenced the old helper.
- [ ] **1.3** Update `tg_dose_status_change()` per design § 6 (mutual peer-Patient alerts; no FAMILY_MEMBER role check).
- [ ] **1.4** Update `check_connection_limits()` per design § 12 (count PEER connections for both sides; doctors unlimited).
- [ ] **1.5** pgtap tests for: doctor-to-doctor rejection, peer mutual visibility, peer alert symmetry, limit enforcement on both sides.

## Phase 2 — Token-issuance UI (0.5 day)

- [ ] **2.1** `GenerateConnectQrUseCase` (writes `connection_tokens` with `intended_role` from generator's `profiles.role`).
- [ ] **2.2** `ShowQrPage` displaying QR + role badge + countdown + regenerate.
- [ ] **2.3** Localized copy for both Patient and Doctor generators.

## Phase 3 — QR scanning (1 day)

- [ ] **3.1** `ScanQrPage` using `mobile_scanner` with framing overlay.
- [ ] **3.2** Deep-link parser: `dastern://connect?token=…&role=…&v=1`.
- [ ] **3.3** `ConsumeQrTokenUseCase` calling RPC.
- [ ] **3.4** Routes scanner to "Waiting for approval" or to error page.
- [ ] **3.5** Reject self-scan, expired, used, role-conflict (doctor-to-doctor) errors with localized messages.

## Phase 4 — Approval flow (0.5 day)

- [ ] **4.1** Notification deep-link to approval bottom sheet for the generator.
- [ ] **4.2** Sheet renders peer vs clinical UX based on counterparty role.
- [ ] **4.3** `AcceptConnectionUseCase` calling `accept_connection` RPC; for peer connections, hardcode `permission = 'ALLOWED'`.

## Phase 5 — Mute / revoke / change permission (0.5 day)

- [ ] **5.1** `MutePeerConnectionUseCase` toggles peer between ALLOWED and NOT_ALLOWED.
- [ ] **5.2** `RevokeConnectionUseCase` (works for both peer and clinical).
- [ ] **5.3** `ChangeDoctorPermissionUseCase` for clinical connections (4-level enum).

## Phase 6 — My Connections page (1 day)

- [ ] **6.1** `MyConnectionsPage` with two sections (peer + clinical).
- [ ] **6.2** `PeerConnectionCard` with mute toggle and "Open" button.
- [ ] **6.3** `DoctorConnectionCard` with permission chip and detail entry.
- [ ] **6.4** Tier-aware peer count chip "X / N peers".
- [ ] **6.5** SpeedDial FAB: "Show QR" / "Scan QR".

## Phase 7 — Peer overview page (1 day)

- [ ] **7.1** `PeerOverviewPage` (read-only today schedule + adherence ring).
- [ ] **7.2** Read-only banner.
- [ ] **7.3** "Send check-in" button on missed dose cards.
- [ ] **7.4** RLS verifies B can read A's dose_events when peer-connected.

## Phase 8 — Peer check-in feature (0.5 day)

- [ ] **8.1** `SendPeerCheckInUseCase` (rate-limited 5 per 24h per peer).
- [ ] **8.2** Generates a `FAMILY_ALERT` notification on the recipient.
- [ ] **8.3** Audit log entry with `kind: peer_check_in`.

## Phase 9 — Doctor side (0.5 day)

- [ ] **9.1** Confirm doctor's home patient list reads from `connections` (no search-by-name component).
- [ ] **9.2** Doctor sees only patients where ACCEPTED clinical connection exists.
- [ ] **9.3** "Show QR" / "Scan QR" entry points reachable from doctor home for adding new patients.

## Phase 10 — Realtime updates (0.5 day)

- [ ] **10.1** Subscribe to `connections` Realtime for own rows.
- [ ] **10.2** On mute or revoke, purge counterparty cache and refresh dashboards.
- [ ] **10.3** On accept, bootstrap counterparty data into Drift.

## Phase 11 — Connection history (0.5 day)

- [ ] **11.1** `ConnectionHistoryPage` filtered by relevant audit action types.
- [ ] **11.2** Filters by counterparty, date, action.
- [ ] **11.3** Pagination.

## Phase 12 — Tests (1 day)

- [ ] **12.1** Unit: QR generation entropy; deep-link round-trip; check-in rate limit.
- [ ] **12.2** Widget: My Connections page sections by role; peer overview read-only banner.
- [ ] **12.3** Integration: two simulated devices — Show QR / Scan / Approve / mutual visibility / mute / re-show.
- [ ] **12.4** pgtap: full RLS matrix for peer mutual access.

## Phase 13 — Sign-off

- [ ] **13.1** Demo: Patient A scans Patient B's QR → both approve and mutually see each other's adherence.
- [ ] **13.2** Demo: A misses a dose → B's app gets `FAMILY_ALERT` within 5s of cron tick.
- [ ] **13.3** Demo: Doctor scans Patient's QR → patient approves → doctor sees patient in dashboard, can author prescription that requires patient approval.
- [ ] **13.4** Demo: Mute peer connection → both lose visibility immediately; un-mute restores.
- [ ] **13.5** Demo: Doctor↔Doctor scan attempt → rejected with localized error.
- [ ] **13.6** Demo: freemium 2nd peer connection blocked with upgrade CTA.
