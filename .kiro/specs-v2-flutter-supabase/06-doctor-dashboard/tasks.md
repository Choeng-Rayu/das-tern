# Tasks: Doctor Dashboard

## Phase 1 — SQL views and functions (1 day)

- [ ] **1.1** Create `doctor_patient_summary` view (with RLS via underlying tables).
- [ ] **1.2** Create `doctor_critical_alerts()` function.
- [ ] **1.3** Add Drift tables: `DoctorNotes` (write-through), and read-only view mirror for `doctor_patient_summary`.
- [ ] **1.4** pgtap tests: alerts return correct rows; cross-doctor leakage zero.

## Phase 2 — Repositories and use cases (1 day)

- [ ] **2.1** `DoctorPatientRepository.search/list`.
- [ ] **2.2** `DoctorNoteRepository.watch/add/edit/delete`.
- [ ] **2.3** `DoctorAlertRepository.list/acknowledge`.
- [ ] **2.4** Riverpod providers for each.

## Phase 3 — Doctor home (1 day)

- [ ] **3.1** `DoctorHomePage` with summary metrics, alerts section, recent activity.
- [ ] **3.2** `SummaryRow` widget showing totals.
- [ ] **3.3** `CriticalAlertCard` with deep-link to patient detail.
- [ ] **3.4** Auto-refresh on app foreground.

## Phase 4 — Patient list (1 day)

- [ ] **4.1** `PatientListPage` with search, filter chips, sort header.
- [ ] **4.2** `PatientRow` widget with color-coded adherence indicator + role-aware shape icon.
- [ ] **4.3** Pull-to-refresh + paginated infinite scroll.

## Phase 5 — Patient detail (1.5 days)

- [ ] **5.1** `PatientDetailPage` with tab bar (Overview / Adherence / Notes / History).
- [ ] **5.2** Adherence chart using `fl_chart` (or similar) over 30 days.
- [ ] **5.3** Prescription versions list with diff view.
- [ ] **5.4** "Edit prescription" entry point gated by permission level.
- [ ] **5.5** Today's dose events table.

## Phase 6 — Notes CRUD (1 day)

- [ ] **6.1** `NotesTab` with list + add/edit/delete.
- [ ] **6.2** `NoteEditor` with markdown-lite formatting (bold, italic, list).
- [ ] **6.3** Optimistic UI: insert before server confirms.
- [ ] **6.4** RLS test: another doctor cannot read.

## Phase 7 — Connection management (0.5 day)

- [ ] **7.1** Notification inbox showing pending requests from patients (incoming via QR-scan + approval, per ADDENDUM-001).
- [ ] **7.2** Accept / decline actions wired to RPC.
- [ ] **7.3** Disconnect action with confirmation.
- [ ] **7.4** "Show QR" / "Scan QR" entry points on doctor home (delegated to `05-family-doctor-connections`).

## Phase 8 — Realtime (0.5 day)

- [ ] **8.1** `DoctorRealtimeListener` subscribes to dose_events, prescriptions, connections.
- [ ] **8.2** Invalidates Riverpod providers on relevant changes.

## Phase 9 — Performance + a11y (1 day)

- [ ] **9.1** Adherence cache reuse from `04-reminder-adherence`.
- [ ] **9.2** Debounced search.
- [ ] **9.3** Tap targets, contrast, semantic labels audit.

## Phase 10 — Tests and sign-off

- [ ] **10.1** Unit + widget tests.
- [ ] **10.2** Integration: doctor sign-in → home → patient detail → add note → see in list.
- [ ] **10.3** Demo: critical alerts surface in real-time as a patient misses doses.
- [ ] **10.4** Demo: doctor with REQUEST permission sees summary; with ALLOWED can author.
