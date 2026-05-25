# Requirements: Prescription & Medication Management

## Introduction

This spec covers the patient and doctor flows for creating, editing, versioning, and lifecycle-managing prescriptions and their medications. It directly supports the v1 patient-role-management and doctor-dashboard requirements but expresses every mutation as an RLS-protected Supabase operation issued from the Flutter app.

## Glossary

- **Prescription** — A `prescriptions` row owned by a patient, optionally authored by a connected doctor.
- **Medication** — A `medications` row child of a prescription.
- **Version** — An immutable snapshot in `prescription_versions` capturing the medications JSON at a point in time.
- **Urgent_Apply** — A doctor-initiated change marked `is_urgent = true` that is applied immediately and notified to the patient.
- **Lifecycle** — `DRAFT → ACTIVE → PAUSED → INACTIVE` (no skipped states; only forward unless explicitly retake).
- **Edit_Lock** — A medication becomes read-only once the first dose has been recorded; future edits create a new version.

## Requirements

### Requirement 1: Patient creates a manual prescription

**User Story:** As a patient, I want to create a prescription with one or more medications, so that I can track medication that wasn't issued through a connected doctor.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Create prescription" entry point on the patient home screen.
2. WHEN the patient submits the prescription form, THE Flutter_App SHALL `INSERT` a `prescriptions` row with `patient_id = auth.uid()`, `doctor_id = NULL`, `status = 'ACTIVE'`, `current_version = 1`, with patient name/age/gender pulled from `profiles`.
3. THE Flutter_App SHALL allow adding 1..N medications in the same flow before navigating away.
4. WHEN medications are submitted, THE Flutter_App SHALL `INSERT` `medications` rows with `prescription_id` linked.
5. WHEN the prescription is created with at least one medication, THE Flutter_App SHALL `INSERT` a `prescription_versions` row with `version_number = 1` and `medications_snapshot` containing the JSON of all medications.
6. WHEN the prescription becomes ACTIVE, THE Flutter_App SHALL generate the next 30 days of `dose_events` locally and queue the `INSERT`s in the outbox.
7. WHEN offline, THE Flutter_App SHALL allow the full creation flow with all writes queued.

### Requirement 2: Doctor creates a prescription for a connected patient

**User Story:** As a doctor, I want to create a prescription for a patient I'm connected to, so that they receive my treatment plan.

#### Acceptance Criteria

1. THE Flutter_App SHALL list patients connected to the doctor with `permission_level = 'ALLOWED'`.
2. WHEN the doctor selects a patient, THE Flutter_App SHALL allow a "New prescription" creation with the patient's identity pre-filled.
3. WHEN the doctor submits, THE Flutter_App SHALL `INSERT` a `prescriptions` row with `patient_id = <patient>`, `doctor_id = auth.uid()`, `status = 'DRAFT'`, `is_urgent = false`.
4. THE Flutter_App SHALL allow the doctor to mark the prescription urgent at submission time, in which case `status = 'ACTIVE'` and `is_urgent = true`, `urgent_reason = <text>`.
5. RLS SHALL allow the doctor's INSERT only when the connection is ACCEPTED and `permission_level = 'ALLOWED'`.
6. WHEN a doctor-authored prescription is created (non-urgent), THE Postgres trigger SHALL emit a `notifications` row to the patient with type `PRESCRIPTION_UPDATE`.

### Requirement 3: Patient confirms a doctor-issued prescription

**User Story:** As a patient, I want to review and confirm a doctor's prescription before it becomes active, so that I have a chance to question it.

#### Acceptance Criteria

1. THE Flutter_App SHALL display draft prescriptions from doctors prominently with a badge.
2. WHEN the patient confirms, THE Flutter_App SHALL `UPDATE prescriptions SET status = 'ACTIVE'` and audit-log `PRESCRIPTION_CONFIRM`.
3. WHEN the prescription becomes ACTIVE, THE Flutter_App SHALL generate `dose_events` for the next 30 days and schedule local notifications.
4. WHEN the patient rejects, THE Flutter_App SHALL `UPDATE prescriptions SET status = 'INACTIVE'` with audit reason; the doctor receives a notification.

### Requirement 4: Versioning on edits

**User Story:** As a patient or doctor, I want my edits to create a new version rather than overwriting history, so that I can audit what changed.

#### Acceptance Criteria

1. WHEN a medication's any field changes after the first dose has been recorded, THE Flutter_App SHALL `INSERT` a new `prescription_versions` row with `version_number = current_version + 1` and the full medications snapshot.
2. THE Flutter_App SHALL `UPDATE prescriptions SET current_version = current_version + 1`.
3. THE Flutter_App SHALL preserve all past `dose_events`; only the future `DUE` dose events are regenerated for changed medications.
4. WHEN the patient is the editor AND no doses have been recorded for the affected medication, THE Flutter_App SHALL allow in-place edits without bumping version (efficiency for early correction).
5. THE Flutter_App SHALL show a version history view per prescription, listing each version with author, timestamp, and a diff summary.

### Requirement 5: Urgent doctor changes auto-apply

**User Story:** As a doctor, I want to apply urgent changes immediately, so that patient safety is protected.

#### Acceptance Criteria

1. THE Flutter_App SHALL allow the doctor to mark an edit as urgent.
2. WHEN urgent, THE Flutter_App SHALL bypass patient confirmation, bump version, regenerate future dose events, set `is_urgent = true`, and write `urgent_reason`.
3. THE Postgres function SHALL emit a notification to the patient with type `URGENT_PRESCRIPTION_CHANGE`.
4. THE Flutter_App SHALL log `PRESCRIPTION_UPDATE` audit with `details.is_urgent = true`.
5. THE Flutter_App SHALL display urgent changes in the patient's history with a distinct red flag and the reason.

### Requirement 6: Pause / resume / stop lifecycle

**User Story:** As a patient, I want to pause my prescription temporarily, so that I don't get reminders during treatment breaks.

#### Acceptance Criteria

1. WHEN the patient pauses, THE Flutter_App SHALL `UPDATE prescriptions SET status = 'PAUSED'`.
2. WHEN paused, THE Flutter_App SHALL cancel all future local notifications scheduled for that prescription.
3. WHEN the patient resumes, THE Flutter_App SHALL `UPDATE status = 'ACTIVE'`, regenerate the next 30 days of dose events from "now", and reschedule local notifications.
4. WHEN the patient stops permanently, THE Flutter_App SHALL `UPDATE status = 'INACTIVE'` and cancel future notifications.
5. THE Flutter_App SHALL prevent editing medications on PAUSED or INACTIVE prescriptions; the user must resume or take/retake to edit.

### Requirement 7: Medication add / remove / replace

**User Story:** As a patient, I want to add or remove individual medications without affecting the prescription, so that I can adapt to changes my doctor recommends.

#### Acceptance Criteria

1. WHEN a medication is added to an ACTIVE prescription, THE Flutter_App SHALL bump the prescription version and regenerate dose events for the new medication only.
2. WHEN a medication is removed (soft delete: medication is archived, not destroyed), THE Flutter_App SHALL cancel its future dose events while preserving past ones for adherence history.
3. WHEN a medication is replaced (different drug, same slot), THE Flutter_App SHALL treat it as a remove + add and log both actions.

### Requirement 8: Schedule generation rules

**User Story:** As a developer, I want a deterministic algorithm for turning medications into dose events, so that the Flutter app and Edge Functions agree.

#### Acceptance Criteria

1. WHEN a medication is non-PRN AND has at least one of `morning_dosage`, `afternoon_dosage`, `evening_dosage`, `night_dosage`, THE Flutter_App SHALL generate a `dose_events` row for each day in the upcoming 30 days at the time defined by the patient's `meal_time_preferences` (or default presets).
2. THE Flutter_App SHALL set `time_period` according to which dosage slot was used (`MORNING/AFTERNOON/EVENING/NIGHT`).
3. THE Flutter_App SHALL set `scheduled_time` in UTC corresponding to the patient's `timezone`.
4. WHEN a medication has `before_meal = true`, THE Flutter_App SHALL schedule the dose event 30 minutes before the meal time.
5. WHEN a medication is PRN, THE Flutter_App SHALL NOT generate any dose events; the patient logs them on demand via "Take now".
6. THE Flutter_App SHALL roll the 30-day window forward each time the app opens (idempotent: only insert future events that don't already exist).

### Requirement 9: PRN medications

**User Story:** As a patient, I want to log a PRN ("as needed") dose any time, so that my adherence record reflects ad-hoc usage.

#### Acceptance Criteria

1. THE Flutter_App SHALL display a "Take now" button on PRN medications.
2. WHEN tapped, THE Flutter_App SHALL `INSERT` a `dose_events` row with `scheduled_time = now()`, `status = 'TAKEN_ON_TIME'`, `time_period` derived from current time of day.
3. THE Flutter_App SHALL exclude PRN medications from adherence percentage calculations (already enforced by `get_adherence` SQL).

### Requirement 10: Subscription tier limits

**User Story:** As a freemium user, I want to know when I hit my plan's prescription/medication limits, so that I can decide to upgrade.

#### Acceptance Criteria

1. THE Postgres `INSERT` policy on `prescriptions` SHALL include a check that for `FREEMIUM` tier, `count(*) where patient_id = auth.uid() and status in ('DRAFT','ACTIVE','PAUSED') < 1` (i.e., max 1 active+pending prescription).
2. THE Postgres `INSERT` policy on `medications` SHALL include a check that for `FREEMIUM` tier, the parent prescription has < 3 medications.
3. THE Flutter_App SHALL display a friendly "Upgrade to Premium" prompt when an attempted insert is denied due to tier limit.
4. WHEN a user upgrades, the Postgres function called by the billing webhook SHALL refresh the subscription tier; subsequent inserts succeed.

### Requirement 11: Prescription image attachment (OCR source)

**User Story:** As a patient, I want to attach a photo of my paper prescription to its digital record, so that I have proof and reference.

#### Acceptance Criteria

1. THE Flutter_App SHALL allow uploading 0..N images per prescription to the `prescription-images` bucket at path `<patient_id>/<prescription_id>/<uuid>.jpg`.
2. THE Flutter_App SHALL store the relative path in `prescriptions.ocr_metadata.images` JSON array.
3. THE Flutter_App SHALL display thumbnails on the prescription detail screen with tap-to-view.
4. WHEN the source is OCR (see `07-ocr-prescription-scanning`), THE Flutter_App SHALL also store `ocr_metadata.confidence`, `ocr_metadata.engine`, `ocr_metadata.raw_text`.

### Requirement 12: Search and filter

**User Story:** As a patient or doctor, I want to find a prescription quickly in my history, so that I don't waste time scrolling.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide search by medication name (English or Khmer), doctor name, or date range.
2. THE Flutter_App SHALL provide status filter chips: ACTIVE, PAUSED, INACTIVE, ALL.
3. THE Flutter_App SHALL paginate results in pages of 20 (cursor by `created_at`).
4. THE Flutter_App SHALL persist last filter preferences locally.
