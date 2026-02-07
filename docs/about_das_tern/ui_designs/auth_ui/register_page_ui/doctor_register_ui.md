# Doctor Registration UI - DasTern

> **Source**: Figma file `zdfPXv7BbGNKPfBPAAwg5p`

## Overview

Registration flow for healthcare providers with license verification. Three steps: Personal Details, License Verification, Password Setup.

---

## Step 1: Personal Details

| Field | Label (Khmer) | Label (English) | Type | Validation |
|-------|--------------|-----------------|------|------------|
| Full Name | ឈ្មោះពេញ | Full Name | Text | Required, min 2 chars |
| Phone | លេខទូរស័ព្ទ | Phone Number | Tel (+855) | Required, Cambodia format |
| Hospital/Clinic | មន្ទីរពេទ្យ / គ្លីនិក | Hospital/Clinic | Text | Required |
| Specialty | ជំនាញ | Specialty | Dropdown | Required |

### Specialty Options

| Khmer | English |
|-------|---------|
| វេជ្ជសាស្រ្តទូទៅ | General Practice |
| វេជ្ជសាស្រ្តផ្ទៃក្នុង | Internal Medicine |
| បេះដូង | Cardiology |
| អង់ដូគ្រីន | Endocrinology |
| ផ្សេងទៀត | Other |

---

## Step 2: License Verification

| Field | Label (Khmer) | Type |
|-------|--------------|------|
| License Number | លេខអាជ្ញាប័ណ្ណ | Text input |
| License Photo | រូបថតអាជ្ញាប័ណ្ណ | Image upload (camera or gallery) |

> **Note**: License verification takes 24-48 hours. Doctor account status is "pending" until verified by DasTern admin team.

---

## Step 3: Password Setup

| Field | Label (Khmer) | Validation |
|-------|--------------|------------|
| Password | ពាក្យសម្ងាត់ | Min 8 chars, 1 number |
| Confirm Password | បញ្ជាក់ពាក្យសម្ងាត់ | Must match password |

---

## User Stories

### US-DREG-001: Doctor Personal Details
**As a** doctor
**I want** to enter my professional details (name, hospital, specialty)
**So that** patients can identify my credentials when connecting

### US-DREG-002: License Verification Upload
**As a** doctor
**I want** to upload my medical license number and photo for verification
**So that** DasTern can confirm I am a legitimate healthcare provider

### US-DREG-003: Verification Pending Status
**As a** doctor who has submitted registration
**I want** to see a clear "verification pending" status
**So that** I know my account is being reviewed and when to expect access

---

## Acceptance Criteria

- [ ] Doctor-specific registration fields (hospital, specialty)
- [ ] Specialty dropdown with Khmer labels
- [ ] License number text input
- [ ] License photo upload via camera or gallery
- [ ] Verification pending notice displayed after submission
- [ ] Password setup with confirmation matching
- [ ] Phone number with +855 Cambodia country code prefix
- [ ] Back navigation between all three steps
- [ ] Multi-step progress indicator visible
- [ ] All form labels in Khmer

---

## Integration Points

- **Related**: [Login](../login_page_ui/user_login_ui.md) | [Patient Registration](patient_register_ui.md)
- **Flow**: After verification approved, doctor is directed to [Doctor Dashboard](../../doctor_dashboard_ui/README.md)
- **Business Logic**: [Business Logic](../../../business_logic/README.md) - Doctor role verification, connection policies
