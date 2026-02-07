# Footer / Bottom Navigation UI - DasTern

> **Source**: Figma file `zdfPXv7BbGNKPfBPAAwg5p` — Page: 01. Getting Started

## Overview

Bottom navigation bar with **5 positions** including a **raised center FAB (Floating Action Button)** for the primary action. Two variants exist for Patient and Doctor roles.

---

## Patient Bottom Navigation

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  [🏠]        [💊]        [📷]        [👨‍👩‍👧]        [⚙️]      │
│  ទំព័រដើម   ការវិភាគថ្នាំ   ស្កេនវេជ្ជបញ្ជា  មុខងារគ្រួសារ   ការកំណត់    │
│  (Home)  (Med Analysis) (Scan Rx)  (Family)   (Settings)   │
│                          ▲                                  │
│                     [Raised FAB]                            │
└─────────────────────────────────────────────────────────────┘
```

### Patient Tab Definitions

| Position | Icon | Label (Khmer) | Label (English) | Target Screen |
|----------|------|---------------|-----------------|---------------|
| 1 | 🏠 | ទំព័រដើម | Home | Patient Dashboard / Medicine Schedule |
| 2 | 💊 | ការវិភាគថ្នាំ | Medicine Analysis | Medication analysis view |
| **3 (Center FAB)** | 📷 | **ស្កេនវេជ្ជបញ្ជា** | **Scan Prescription** | Camera/QR scanner for prescription import |
| 4 | 👨‍👩‍👧 | មុខងារគ្រួសារ | Family Function | Family connections & alerts |
| 5 | ⚙️ | ការកំណត់ | Settings | App settings & profile |

---

## Doctor Bottom Navigation

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  [🏠]        [👥]        [📝]        [📋]        [⚙️]      │
│  ទំព័រដើម  តាមដានអ្នកជំងឺ បង្កើតវេជ្ជបញ្ជា ប្រវិត្តវេជ្ជបញ្ជារ  ការកំណត់    │
│  (Home)  (Monitor)   (Create Rx) (Rx History) (Settings)   │
│                          ▲                                  │
│                     [Raised FAB]                            │
└─────────────────────────────────────────────────────────────┘
```

### Doctor Tab Definitions

| Position | Icon | Label (Khmer) | Label (English) | Target Screen |
|----------|------|---------------|-----------------|---------------|
| 1 | 🏠 | ទំព័រដើម | Home | Doctor Dashboard |
| 2 | 👥 | តាមដានអ្នកជំងឺ | Monitor Patients | Patient list + adherence monitoring |
| **3 (Center FAB)** | 📝 | **បង្កើតវេជ្ជបញ្ជា** | **Create Prescription** | Prescription creation form |
| 4 | 📋 | ប្រវិត្តវេជ្ជបញ្ជារ | Prescription History | Past prescriptions list |
| 5 | ⚙️ | ការកំណត់ | Settings | App settings & profile |

---

## User Stories

### US-NAV-001: Patient Bottom Navigation
**As a** patient
**I want** a persistent bottom navigation bar with 5 tabs
**So that** I can quickly switch between Home, Medicine Analysis, Scan, Family, and Settings

### US-NAV-002: Scan Prescription via Center FAB
**As a** patient
**I want** a prominent raised center "Scan Prescription" button
**So that** I can quickly scan and import a doctor's prescription using my camera

### US-NAV-003: Doctor Role-Specific Navigation
**As a** doctor
**I want** a bottom navigation tailored to my workflow (Monitor Patients, Create Rx, Rx History)
**So that** I can efficiently manage prescriptions and monitor patient adherence

### US-NAV-004: Active Tab Visual Feedback
**As a** user
**I want** the active tab to be highlighted in blue
**So that** I always know which section I'm currently viewing

### US-NAV-005: Badge Notifications
**As a** family member
**I want** to see a notification badge on the Family tab
**So that** I know there are missed-dose alerts requiring my attention

---

## Visual Specifications

### Styling

| Property | Value |
|----------|-------|
| Background | White (#FFFFFF) |
| Height | 50px |
| Shadow | 0 -2px 4px rgba(0,0,0,0.05) |
| Icon Size | 20-25px |
| Label Size | ~12px (Khmer text) |
| Safe Area | Respect bottom inset (iOS) |

### Center FAB (Scan / Create)

| Property | Value |
|----------|-------|
| Width | 75px |
| Height | 57px |
| Position | Raised -7px above nav bar |
| Background | White with subtle shadow |
| Icon Size | 30px |
| Label | Below icon, within FAB area |

### Tab States

| State | Icon Color | Label Color |
|-------|-----------|-------------|
| **Inactive** | Gray (#9E9E9E) | Gray (#9E9E9E) |
| **Active** | Primary Blue (#2D5BFF) | Primary Blue (#2D5BFF) |

---

## Acceptance Criteria

- [ ] 5-position bottom navigation with raised center FAB
- [ ] Patient variant: Home, Med Analysis, Scan Rx, Family, Settings
- [ ] Doctor variant: Home, Monitor, Create Rx, Rx History, Settings
- [ ] Center FAB is visually raised above the nav bar
- [ ] Active tab highlighted in Primary Blue
- [ ] Khmer labels displayed correctly
- [ ] Badge notification support on Family/Monitor tabs
- [ ] Respects safe area on iOS devices
- [ ] Navigation persists across all main screens

---

## Integration Points

- **Related**: [Header UI](../header_ui/header_requirement_ui.md) | [Patient Dashboard](../patient_dashboard_ui/README.md) | [Doctor Dashboard](../doctor_dashboard_ui/README.md)
- **Flow**: [Family Connection Flow](../../flows/family_connection_flow/README.md)
