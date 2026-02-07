# Header UI - DasTern

> **Source**: Figma file `zdfPXv7BbGNKPfBPAAwg5p` — Page: 01. Getting Started

## Overview

Global header component displayed at the top of all screens. Features a personalized greeting, app branding, medication progress indicator, and notification system.

---

## Header Layout (Patient)

```
┌─────────────────────────────────────────────────────────┐
│  [Logo] ដាស់តឿន            [Progress Bar]  [🔔] [1]    │
│  សួស្តី​ [Username] !                                    │
├─────────────────────────────────────────────────────────┤
│  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ (separator/progress line)  │
└─────────────────────────────────────────────────────────┘
```

### Header Layout (Doctor)

```
┌─────────────────────────────────────────────────────────┐
│  [Logo] ដាស់តឿន  |  វេជ្ជបណ្ឌិត    [Progress Bar] [🔔][1] │
│  សួស្តី​ វេជ្ជបណ្ឌិត [Name] !                              │
├─────────────────────────────────────────────────────────┤
│  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ (separator/progress line)  │
└─────────────────────────────────────────────────────────┘
```

---

## Components

| Element | Description | Action |
|---------|-------------|--------|
| **Logo** | DasTern app icon (pill/capsule icon) | → Home |
| **App Name** | ដាស់តឿន (Khmer) | → Home |
| **Greeting** | សួស្តី​ [Username] ! (Hello [Name]!) | Display only |
| **Progress Bar** | Horizontal bar showing daily medication progress | Display only |
| **Notification Bell** | 🔔 with numeric badge | → Notifications list |
| **Doctor Badge** | "វេជ្ជបណ្ឌិត" label (Doctor role only) | Display only |

---

## User Stories

### US-HDR-001: Personalized Greeting
**As a** patient
**I want** to see "សួស្តី​ [my name] !" when I open the app
**So that** the experience feels personal and welcoming

### US-HDR-002: Medication Progress Indicator
**As a** patient
**I want** a progress bar showing how many medications I've taken today
**So that** I can quickly see my daily adherence at a glance

### US-HDR-003: Notification Badge
**As a** user
**I want** to see a red badge with the count of unread notifications
**So that** I know when there are missed-dose alerts, prescription updates, or family requests

### US-HDR-004: Doctor Role Identification
**As a** doctor
**I want** my header to display "វេជ្ជបណ្ឌិត" (Doctor)
**So that** the interface clearly reflects my role

---

## Visual Specifications

### Styling

| Property | Value |
|----------|-------|
| Background | Dark Blue (#1A2744) |
| Height | ~80px (including greeting line) |
| Logo Size | 32px |
| App Name Font | 18px Bold, White |
| Greeting Font | 14px Regular, White |
| Icon Size | 24px |

### Notification Badge

| Property | Value |
|----------|-------|
| Badge Background | Red (#E53935) |
| Badge Size | 16px circle |
| Badge Text | White, 10px Bold |
| Position | Top-right of bell icon |

### Progress Bar

| Property | Value |
|----------|-------|
| Height | 3px |
| Background (track) | rgba(255,255,255,0.2) |
| Fill Color | Primary Blue (#2D5BFF) or Success Green (#4CAF50) |
| Position | Bottom edge of header area |

---

## Acceptance Criteria

- [ ] Logo displays and taps navigate to home
- [ ] App name "ដាស់តឿន" displayed in Khmer
- [ ] Personalized greeting "សួស្តី​ [Name] !" visible
- [ ] Progress bar reflects daily medication completion percentage
- [ ] Notification bell with numeric badge count
- [ ] Doctor variant includes "វេជ្ជបណ្ឌិត" role label
- [ ] Header persists across all main screens (not on auth screens)

---

## Integration Points

- **Related**: [Footer / Bottom Navigation](../footer_ui/footer_requirement_ui.md) | [Patient Dashboard](../patient_dashboard_ui/README.md) | [Doctor Dashboard](../doctor_dashboard_ui/README.md)
- **Flow**: [Reminder Flow](../../flows/reminder_flow/README.md)
