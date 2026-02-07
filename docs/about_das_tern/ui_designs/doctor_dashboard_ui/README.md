# Doctor Dashboard UI - DasTern

## Figma Source

- **File**: [DasTern (ដាស់តឿន)](https://www.figma.com/design/zdfPXv7BbGNKPfBPAAwg5p)
- **File Key**: `zdfPXv7BbGNKPfBPAAwg5p`
- **Node IDs**:
  - `822:542` -- Doctor Prescription (Create prescription form)
  - `811:515` -- Prescription for Patient (Patient-facing prescription view)
  - `790:316` -- Doctor Dashboard (Write Prescription with medication grid)

---

## Overview

The doctor dashboard provides tools for patient monitoring, prescription management, and medication adherence analytics. Doctors can view their patient list with real-time adherence data, create and send prescriptions, review prescription history, and receive alerts when patients miss doses.

---

## Patient List and Adherence

Each patient is displayed as a card showing:

- Patient name, gender, age, phone number
- Current symptoms
- Adherence percentage bar

### Adherence Color Codes

| Adherence Range | Color | Status |
|-----------------|-------|--------|
| 80% and above | Green (`#4CAF50`) | Good adherence |
| 50% to 79% | Yellow/Warning | Moderate adherence |
| Below 50% | Red (`#E53935`) | Poor adherence |

Doctors can tap a patient card to view the full patient detail screen, including current prescription list and medication schedule (ពេលព្រឹក / ពេលថ្ងៃ / ពេលយប់).

---

## Prescription Creation Form (Node `822:542`)

This screen allows doctors to create a new prescription for a patient.

### Patient Information Fields

| Field | Khmer Label | Description |
|-------|-------------|-------------|
| Name | ឈ្មោះ | Patient full name |
| Gender | ភេទ | Patient gender |
| Age | អាយុ | Patient age |
| Symptoms | រោគសញ្ញា | Current symptoms in Khmer |

### Medication Table

Each medication entry (ថ្នាំទី 1, ថ្នាំទី 2, etc.) includes:

- Medication name
- Quantity
- Frequency
- Duration
- Medication image

### Medication Grid Columns

| Column | Khmer Label | Description |
|--------|-------------|-------------|
| Row number | ល.រ | Sequential row number |
| Medicine Name | ឈ្មោះឱសថ | Name of the medicine |
| Morning | ពេលព្រឹក | Dosage for morning |
| Daytime | ពេលថ្ងៃ | Dosage for daytime |
| Night | ពេលយប់ | Dosage for night |

### Before/After Meal Indicators

Each time-period cell supports before-meal or after-meal (បន្ទាប់ពីអាហារ) indicators so the patient knows when to take each dose relative to meals.

---

## Prescription for Patient View (Node `811:515`)

This is the patient-facing prescription view that the patient sees after the doctor sends the prescription.

### Content

- **Doctor name**: Displayed at the top
- **Date**: Prescription date
- **Diagnosis**: List of diagnosed conditions
- **Medication table**: Grid layout with the following columns:

| Column | Khmer Label |
|--------|-------------|
| Row number | ល.រ |
| Medicine Name | ឈ្មោះឱសថ |
| Morning analysis | ពេលព្រឹក |
| Daytime analysis | ពេលថ្ងៃ |
| Night analysis | ពេលយប់ |

### Actions

- **Confirm**: Patient confirms and accepts the prescription
- **Retake**: Request the doctor to redo the prescription
- **Add Medicine** (បន្ថែមថ្នាំ): Add additional medication entries

---

## Urgent Prescription Update

When a doctor needs to modify an active prescription urgently:

1. **Required reason**: The doctor must provide a reason for the update before submitting.
2. **Auto-apply**: The updated prescription is applied to the patient's schedule immediately.
3. **Notification**: The patient receives a notification about the prescription change.
4. **Audit trail**: All changes are logged with timestamp, doctor ID, and reason for the update.

---

## Doctor Bottom Navigation

The doctor variant of the bottom navigation has 5 tabs:

| Position | Label (Khmer) | Function |
|----------|---------------|----------|
| 1 | ទំព័រដើម | Home / Dashboard |
| 2 | តាមដានអ្នកជំងឺ | Monitor Patients |
| 3 (Center FAB) | បង្កើតវេជ្ជបញ្ជា | Create Prescription (raised center button) |
| 4 | ប្រវិត្តវេជ្ជបញ្ជារ | Prescription History |
| 5 | ការកំណត់ | Settings |

The center FAB (បង្កើតវេជ្ជបញ្ជា) is a raised floating action button (75x57px) that opens the prescription creation form.

---

## User Stories

### US-DOC-001: View Patient List with Adherence

As a doctor, I want to see a list of my patients with their medication adherence percentages so that I can identify patients who need attention.

### US-DOC-002: Create Prescription

As a doctor, I want to create a prescription with patient info (name, gender, age, symptoms) and a medication grid table (ល.រ, ឈ្មោះឱសថ, ពេលព្រឹក, ពេលថ្ងៃ, ពេលយប់) so that I can prescribe medicines with clear dosage schedules.

### US-DOC-003: Send Prescription to Patient

As a doctor, I want to send a completed prescription to a patient so that the patient can review, confirm, or request a retake.

### US-DOC-004: View Prescription History

As a doctor, I want to view my past prescriptions (ប្រវិត្តវេជ្ជបញ្ជារ) so that I can track what I have prescribed to each patient.

### US-DOC-005: Update Prescription Urgently

As a doctor, I want to urgently update an active prescription with a required reason so that the patient receives the corrected medication schedule immediately.

### US-DOC-006: Monitor Patient Adherence

As a doctor, I want to monitor patient adherence with color-coded indicators (Green >= 80%, Yellow 50-79%, Red < 50%) so that I can intervene when a patient is not following the prescription.

---

## Acceptance Criteria

- [ ] Patient list displays each patient with name, symptoms, and adherence percentage bar
- [ ] Adherence bars use correct color coding: Green >= 80%, Yellow 50-79%, Red < 50%
- [ ] Prescription creation form includes patient info fields (ឈ្មោះ, ភេទ, អាយុ, រោគសញ្ញា)
- [ ] Medication grid table renders columns: ល.រ, ឈ្មោះឱសថ, ពេលព្រឹក, ពេលថ្ងៃ, ពេលយប់
- [ ] Before/after meal indicators display correctly for each dosage cell
- [ ] Patient prescription view shows doctor name, date, diagnosis, and medication table
- [ ] Confirm and retake actions work on the patient prescription view
- [ ] Add medicine (បន្ថែមថ្នាំ) button adds a new row to the medication table
- [ ] Urgent prescription update requires a reason before submission
- [ ] Urgent update triggers auto-apply, patient notification, and audit trail logging
- [ ] Doctor bottom navigation shows 5 tabs with correct Khmer labels
- [ ] Center FAB (បង្កើតវេជ្ជបញ្ជា) opens the prescription creation form

---

## Integration Points

- **Header (Doctor Variant)**: Uses the shared header component with doctor-specific greeting (សួស្តី [Doctor Name] !) and notification bell. See [header_ui/README.md](../header_ui/README.md).
- **Footer (Doctor Variant)**: Uses the doctor bottom navigation (ទំព័រដើម, តាមដានអ្នកជំងឺ, បង្កើតវេជ្ជបញ្ជា, ប្រវិត្តវេជ្ជបញ្ជារ, ការកំណត់). See [footer_ui/README.md](../footer_ui/README.md).
- **Doctor Send Prescription Flow**: Prescription creation and delivery workflow. See [flows/doctor_send_prescriptoin_to_patient_flow/](../../flows/doctor_send_prescriptoin_to_patient_flow/).
- **Business Logic**: Adherence calculation, prescription validation, and urgent update rules. See [business_logic/](../../business_logic/).

---

*Last Updated: February 7, 2026*
