# Footer / Bottom Navigation UI - DasTern

## Overview

Bottom navigation bar with 4 tabs for main app sections.

---

## Navigation Layout

```
┌─────────────────────────────────────────────────────────┐
│  [🏠]        [💊]        [👨‍👩‍👧]        [⚙️]              │
│  ទំព័រដើម       ថ្នាំ         គ្រួសារ       ការកំណត់            │
│  (Home)    (Medicine)  (Family)   (Settings)           │
└─────────────────────────────────────────────────────────┘
```

---

## Tabs

| Tab | Icon | Label (Khmer) | Label (English) | Screen |
|-----|------|---------------|-----------------|--------|
| 1 | 🏠 | ទំព័រដើម | Home | Dashboard overview |
| 2 | 💊 | ថ្នាំ | Medicine | Medication schedule |
| 3 | 👨‍👩‍👧 | គ្រួសារ | Family | Family connections |
| 4 | ⚙️ | ការកំណត់ | Settings | App settings |

---

## States

### Inactive Tab
| Property | Value |
|----------|-------|
| Icon Color | Gray (`#9E9E9E`) |
| Label Color | Gray (`#9E9E9E`) |

### Active Tab
| Property | Value |
|----------|-------|
| Icon Color | Primary Blue (`#2D5BFF`) |
| Label Color | Primary Blue (`#2D5BFF`) |
| Indicator | Blue dot or underline |

---

## Visual

```
Inactive:    Active:
   ⚪           🔵
   ○            ●
  Gray        Blue
```

---

## Styling

| Property | Value |
|----------|-------|
| Background | White |
| Height | 64px |
| Shadow | 0 -2px 4px rgba(0,0,0,0.05) |
| Icon Size | 24px |
| Label Size | 12px |
| Safe Area | Respect bottom inset (iOS) |

---

## Doctor Variation

For doctor users, the tabs change:

| Tab | Icon | Label (Khmer) | Screen |
|-----|------|---------------|--------|
| 1 | 🏠 | ទំព័រដើម | Doctor Dashboard |
| 2 | 👥 | អ្នកជំងឺ | Patient List |
| 3 | 📝 | វេជ្ជបញ្ជា | Prescriptions |
| 4 | ⚙️ | ការកំណត់ | Settings |

---

## Badge Notifications

Family tab can show badge for alerts:

```
     [👨‍👩‍👧]
      [2]  ← Red badge for missed dose alerts
```

---

## Acceptance Criteria

- [ ] 4-tab navigation bar at bottom
- [ ] Active tab highlighted in blue
- [ ] Khmer labels displayed
- [ ] Badge support for notifications
- [ ] Respects safe area on iOS
- [ ] Doctor users see different tabs
