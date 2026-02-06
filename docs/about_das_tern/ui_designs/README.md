# UI Designs - DasTern (ដាស់តឿន)

This directory contains UI specifications based on the Figma designs for the DasTern medication reminder platform.

---

## Design System

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#2D5BFF` | Main actions, buttons, active navigation, headers |
| **Dark Blue** | `#1A2744` | Auth screen backgrounds |
| **Alert Red** | `#E53935` | Missed doses, urgent notifications, Family Alert |
| **Afternoon Orange** | `#FF6B35` | Afternoon medication section |
| **Night Purple** | `#6B4AA3` | Night medication section |
| **Success Green** | `#4CAF50` | Taken confirmations |
| **Neutral Gray** | `#9E9E9E` | Secondary text, borders |
| **Background** | `#F5F5F5` | Card backgrounds |

### Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| H1 (Section Header) | Sans-serif | 24px | Bold |
| H2 (Card Title) | Sans-serif | 18px | Semibold |
| Body | Sans-serif | 14px | Regular |
| Caption | Sans-serif | 12px | Regular |
| Button | Sans-serif | 16px | Semibold |

### Language Support
- **Primary**: Khmer (ភាសាខ្មែរ)
- **Secondary**: English

---

## App Structure

### Figma Pages
1. **01. Getting Started** - Main UI screens
2. **02. Foundation** - Design tokens (Border, Breakpoint, Colors, Effects)
3. **03. Components** - Reusable UI components

### Screen Categories

```
┌─────────────────────────────────────────────────────────┐
│                 DasTern App Structure                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────┐  ┌───────────────┐                  │
│  │ Register/Login│  │    Survey     │                  │
│  │ • Starting    │  │ • Morning Meal│                  │
│  │ • Sign up (2) │  │ • Afternoon   │                  │
│  │ • Log in      │  │ • Night Meal  │                  │
│  └───────────────┘  └───────────────┘                  │
│                                                         │
│  ┌───────────────┐  ┌───────────────┐                  │
│  │Medicine Sched.│  │  Family Plan  │                  │
│  │ • Morning Med │  │ • Features    │                  │
│  │ • Afternoon   │  │ • QR Connect  │                  │
│  │ • Night Med   │  │ • Family Alert│                  │
│  └───────────────┘  └───────────────┘                  │
│                                                         │
│  ┌───────────────┐  ┌───────────────┐                  │
│  │    Settings   │  │ Doctor View   │                  │
│  │ • Profile     │  │ • Dashboard   │                  │
│  │ • Language    │  │ • Monitoring  │                  │
│  │ • About       │  │ • Analytics   │                  │
│  └───────────────┘  └───────────────┘                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Bottom Navigation

| Tab | Icon | Label (Khmer) | Screen |
|-----|------|---------------|--------|
| 1 | 🏠 | ទំព័រដើម | Home/Dashboard |
| 2 | 💊 | ថ្នាំ | Medicine Schedule |
| 3 | 👨‍👩‍👧 | គ្រួសារ | Family Connection |
| 4 | ⚙️ | ការកំណត់ | Settings |

---

## UI Components

| Component | Description | Link |
|-----------|-------------|------|
| **Header** | App header with logo and profile | [Header UI](./header_ui/header_requirement_ui.md) |
| **Footer/Nav** | Bottom navigation bar | [Footer UI](./footer_ui/footer_requirement_ui.md) |
| **Login** | User authentication | [Login UI](./auth_ui/login_page_ui/user_login_ui.md) |
| **Register** | Patient/Doctor registration | [Register UI](./auth_ui/register_page_ui/) |
| **Patient Dashboard** | Medicine schedule & tracking | [Patient UI](./patient_dashboard_ui/README.md) |
| **Doctor Dashboard** | Patient monitoring | [Doctor UI](./doctor_dashboard_ui/README.md) |

---

## Mobile Frame
- **Target**: Android & iOS
- **Frame size**: 390 x 844 (iPhone 14 / modern Android)
- **Safe areas**: Respect system UI insets
