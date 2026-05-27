# Tasks: Prescription & Medication Management

## Phase 1 — Domain entities and DAOs (1 day)

- [x] **1.1** `lib/features/prescriptions/domain/prescription.dart` (freezed).
- [x] **1.2** `lib/features/prescriptions/domain/medication.dart` (freezed) + `dosage_slot.dart`.
- [x] **1.3** Drift DAOs for `Prescriptions`, `Medications`, `PrescriptionVersions`, `DoseEvents` (read methods, write methods, watch* streams).
- [x] **1.4** `PrescriptionRepository` and `MedicationRepository` interfaces + implementations (Drift first, outbox enqueue).
- [x] **1.5** Riverpod providers for repositories.

## Phase 2 — Schedule generator (0.5 day)

- [x] **2.1** `lib/features/prescriptions/data/schedule_generator.dart` per design § 3.
- [x] **2.2** Unit tests with fixed timezone + meal preferences + BID/TID/QID + before_meal=true cases.
- [x] **2.3** Idempotency test: regenerating with overlap doesn't duplicate dose events.

## Phase 3 — Patient creation flow (1.5 days)

- [x] **3.1** `CreatePrescriptionPage` — form with prescriber name, date, notes.
- [x] **3.2** `MedicationFormPage` — fields per design § 2 with bilingual labels.
- [x] **3.3** `CreatePrescription` use case end-to-end.
- [x] **3.4** Outbox round-trip test: create offline → enable network → verify rows in Supabase + Drift updated.
- [x] **3.5** Image upload widget + path management.

## Phase 4 — Lifecycle and edit flow (1 day)

- [x] **4.1** `PrescriptionDetailPage` with status badge, urgent banner, medication list.
- [x] **4.2** Pause / resume / stop actions with confirmation dialogs.
- [x] **4.3** `EditMedication` use case with version-bump rule.
- [x] **4.4** `VersionHistoryPage` showing per-version diff (compute snapshot diff in Dart).
- [ ] **4.5** Cancel and reschedule local notifications on lifecycle changes (delegated to `04-reminder-adherence`).

## Phase 5 — Doctor authoring flow (1 day)

- [x] **5.1** `DoctorPrescriptionAuthoringPage` reachable from doctor's patient detail.
- [x] **5.2** Urgent toggle with reason field.
- [x] **5.3** RLS verification: doctor with `permission_level <> 'ALLOWED'` cannot create.
- [x] **5.4** Patient-side notification handler routes to confirm/reject screen.

## Phase 6 — Confirm/reject (0.5 day)

- [x] **6.1** Notification deep-link to `PrescriptionDetailPage?focus=draft`.
- [x] **6.2** Confirm button: `status DRAFT → ACTIVE`, generate dose events, schedule notifications.
- [x] **6.3** Reject button: `status DRAFT → INACTIVE`, doctor receives notification (Postgres trigger).

## Phase 7 — Subscription gating (0.5 day)

- [x] **7.1** Add `check_freemium_limits` Postgres trigger per design § 8.
- [x] **7.2** Flutter exception handler maps `freemium_limit_*` to AppFailure.
- [x] **7.3** "Upgrade to Premium" sheet shown on freemium denial (deep-link to billing).

## Phase 8 — Search, filter, list (0.5 day)

- [x] **8.1** `PrescriptionListPage` with status chips and search field.
- [x] **8.2** Pagination via `from('prescriptions').range(from, to)`.
- [x] **8.3** Search query: `medicine_name ilike $1 or medicine_name_khmer ilike $1`.

## Phase 9 — Tests (1 day)

- [x] **9.1** Unit tests for use cases (create, edit, pause, resume).
- [x] **9.2** Widget tests for forms (validation, bilingual labels, error states).
- [x] **9.3** Integration test: full create → confirm → generate events → view in list.
- [ ] **9.4** pgtap RLS test: doctor edit allowed/denied by permission level.

## Phase 10 — Sign-off

- [x] **10.1** Demo: patient creates 1 manual prescription with 2 meds → dose events appear → list paginates.
- [x] **10.2** Demo: doctor authors prescription → patient receives notification → confirm → ACTIVE.
- [x] **10.3** Demo: edit medication after first dose → new version, history visible.
- [x] **10.4** Demo: freemium user cannot create 2nd prescription, sees upgrade CTA.
