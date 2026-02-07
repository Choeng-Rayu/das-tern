# Patient Dashboard UI - DasTern (ដាស់តឿន)

> **Figma Source**: File key `zdfPXv7BbGNKPfBPAAwg5p`, Page **01. Getting Started**
> **Last Updated**: February 7, 2026

---

## Overview

The Patient Dashboard is the main interface patients see after logging in. It displays the daily medication schedule organized into **two time-period groups**:

- **ពេលថ្ងៃ (Daytime)** — Blue section
- **ពេលយប់ (Night)** — Purple section

Each group shows a list of medication cards with status tracking. A header with greeting, progress bar, and notification bell is always visible at the top.

---

## Medicine Schedule Layout

The dashboard screen contains the following elements from top to bottom:

**Header area**: App logo with "ដាស់តឿន" text, a greeting "សួស្តី [Username] !", a daily progress bar, and a notification bell [bell icon] with badge count.

**Daytime section (ពេលថ្ងៃ)**: Blue-themed section header (color `#2D5BFF`). Lists medications to be taken during daytime hours. Sample medications from Figma:

- ថ្នាំបារ៉ា (Paracetamol) — 1 គ្រាប់
- អ៊ីប៊ុយប្រូហ្វេន (Ibuprofen) — 1 គ្រាប់
- ឡូរ៉ាតាឌីន (Loratadine) — 1 គ្រាប់

**Night section (ពេលយប់)**: Purple-themed section header (color `#6B4AA3`). Same medication card layout as daytime, but for nighttime doses.

**Bottom navigation**: Patient bottom nav with 5 tabs (ទំព័រដើម, ការវិភាគថ្នាំ, ស្កេនវេជ្ជបញ្ជា center FAB, មុខងារគ្រួសារ, ការកំណត់).

---

## Medication Time Groups

| Group | Khmer Label | Color | Figma Node IDs |
|-------|-------------|-------|-----------------|
| Daytime (pending) | ពេលថ្ងៃ | Blue `#2D5BFF` | `406:240` |
| Daytime (completed) | ពេលថ្ងៃ | Blue `#2D5BFF` | `406:407` |
| Night (pending) | ពេលយប់ | Purple `#6B4AA3` | `406:286` |
| Night (completed) | ពេលយប់ | Purple `#6B4AA3` | `406:346` |

---

## Medication Card Component

Each medication card displays the following elements:

| Element | Description |
|---------|-------------|
| Medication Image | Thumbnail image of the medication |
| Medication Name (Khmer) | e.g., ថ្នាំបារ៉ា, អ៊ីប៊ុយប្រូហ្វេន, ឡូរ៉ាតាឌីន |
| Dosage | e.g., 500mg, 400mg, 10mg |
| Quantity | Number of pills, e.g., 1 គ្រាប់ |
| Status Indicator | Checkbox or badge showing pending/done/missed state |
| Arrow | Right-facing arrow to navigate to medication detail screen |

---

## Card States

| State | Visual | Description |
|-------|--------|-------------|
| **Pending** | Unchecked checkbox | Medication has not been taken yet. Default state. |
| **Done (រួចរាល់)** | Green checkmark with "រួចរាល់" text | Medication has been marked as taken. Color: `#4CAF50`. |
| **Missed** | Red indicator | Medication was not taken within the scheduled window. Color: `#E53935`. |

---

## Medication Detail Screen

Tapping a medication card opens a full detail screen. The screen header shows "ថយក្រោយ" (Back) on the left and the app logo on the right, with "លម្អិត" (Detail) as the page title.

### Detail Fields

| Field | Khmer Label | Example Value |
|-------|-------------|---------------|
| Medication Name | (displayed as title) | អ៊ីប៊ុយប្រូហ្វេន 400mg |
| Frequency | ផាបញឹកញាប់ | 3ដង/១ថ្ងៃ |
| Timing | ពេលវេលា | បន្ទាប់ពីអាហារ (After meals) |
| Recommended Reminder Time | ពេលវេលារំលឹកដែលបានណែនាំ | 11:00 ថ្ងៃ (daytime) or 7:00 យប់ (night) |
| Edit Reminder Button | កែប្រែការរុំលឹកពេលវេលា | Opens reminder time editor |
| Analysis Section Title | ការវិភាគថ្នាំ | Section header for dosage info |

### Detail Screen Figma Node IDs

| Screen | Medication | Node ID |
|--------|------------|---------|
| Daytime Detail 1 | អ៊ីប៊ុយប្រូហ្វេន 400mg | `406:621` |
| Daytime Detail 2 | ឡូរ៉ាតាឌីន 10mg | `406:659` |
| Night Detail 1 | ថ្នាំបារ៉ា 500mg | `406:498` |
| Night Detail 2 | អ៊ីប៊ុយប្រូហ្វេន 400mg | `406:544` |
| Night Detail 3 | ឡូរ៉ាតាឌីន 10mg | `406:582` |

---

## Survey / Onboarding Screens

These screens appear during first-time setup to collect the patient's typical meal times. The app uses this data to calculate recommended medication reminder times.

| Screen | Figma Node ID | Khmer Question | Time Options |
|--------|---------------|----------------|--------------|
| Morning Meal Time | `229:112` | តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលព្រឹក? | 6-7AM, 7-8AM, 8-9AM, 9-10AM |
| Afternoon Meal Time | `234:187` | តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលរសៀល? | 12-1PM, 1-2PM, 2-3PM, 4-5PM |
| Night Meal Time | `242:243` | តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលយប់? | Same format as above |

Each survey screen presents a question with radio-button time range options. The patient selects one option per meal period. Responses are used to determine when "បន្ទាប់ពីអាហារ" (after meals) reminders should fire.

---

## User Stories

| ID | Story | Description |
|----|-------|-------------|
| US-DASH-001 | View medications by time group | As a patient, I want to see my medications organized by ពេលថ្ងៃ (Daytime) and ពេលយប់ (Night) so I know which medicines to take at each period. |
| US-DASH-002 | Mark medication as taken | As a patient, I want to tap a medication card to mark it as "រួចរាល់" (done) so I can track what I have already taken. |
| US-DASH-003 | View medication details | As a patient, I want to tap the arrow on a medication card to see full details (dosage, frequency, timing, reminder time) on the detail screen. |
| US-DASH-004 | Edit reminder time | As a patient, I want to tap "កែប្រែការរុំលឹកពេលវេលា" on the detail screen to adjust the reminder time for a specific medication. |
| US-DASH-005 | Complete onboarding survey | As a new patient, I want to answer meal time survey questions so the app can recommend appropriate medication reminder times. |
| US-DASH-006 | View daily progress | As a patient, I want to see a progress bar in the header that shows how many medications I have taken today out of the total scheduled. |

---

## Offline Mode Indicator

When the device has no internet connection, the dashboard displays an offline mode indicator. Medication schedules cached locally remain viewable, and any status changes (marking medications as taken) are queued and synced when connectivity is restored.

---

## Acceptance Criteria

- [ ] Dashboard displays two medication groups: ពេលថ្ងៃ (Daytime) and ពេលយប់ (Night)
- [ ] Each group uses the correct color theme (Blue `#2D5BFF` for daytime, Purple `#6B4AA3` for night)
- [ ] Medication cards show image, Khmer name, dosage, quantity, status, and navigation arrow
- [ ] Tapping a card status toggles between pending and រួចរាល់ (done)
- [ ] Tapping the arrow navigates to the medication detail screen
- [ ] Detail screen displays frequency (ផាបញឹកញាប់), timing (ពេលវេលា), and reminder time
- [ ] "កែប្រែការរុំលឹកពេលវេលា" button opens the reminder time editor
- [ ] Progress bar in header updates as medications are marked done
- [ ] Notification bell [bell icon] displays badge count for pending reminders
- [ ] Onboarding survey collects meal times for morning, afternoon, and night
- [ ] Offline mode allows viewing cached schedules and queues status changes
- [ ] All text displays correctly in Khmer script

---

## Integration Points

- **Header UI**: [../header_ui/README.md](../header_ui/README.md) — Shared header component with logo, greeting, progress bar, and notification bell
- **Footer UI**: [../footer_ui/README.md](../footer_ui/README.md) — Patient bottom navigation bar
- **Create Medication Flow**: [../../flows/create_medication_flow/README.md](../../flows/create_medication_flow/README.md) — Adding new medications to the schedule
- **Reminder Flow**: [../../flows/reminder_flow/README.md](../../flows/reminder_flow/README.md) — Notification and reminder logic
- **Business Logic**: [../../business_logic/README.md](../../business_logic/README.md) — Dashboard data management and state handling
