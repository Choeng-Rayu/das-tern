# About DasTern

DasTern is a **medication management platform** designed to help patients track prescriptions, receive reminders, and maintain adherence with support from family and healthcare providers.

---

## Platform Overview

DasTern enables:
- 📋 **Prescription Management** - Create and manage medication schedules
- ⏰ **Smart Reminders** - Online and offline reminder delivery
- 👨‍👩‍👧 **Family Support** - Connect family members for adherence support
- 👨‍⚕️ **Doctor Integration** - Healthcare provider connection and monitoring
- 📊 **Adherence Tracking** - Comprehensive dose history and reporting

---

## Core Principles

### Patient Ownership
> The patient is always the owner of their medical data. All access by Family or Doctor must be explicitly permitted by the patient.

### Key Features

| Feature | Description |
|---------|-------------|
| **Two-way Connection** | Doctor-patient connection requires mutual acceptance |
| **Permission Control** | Patient controls doctor permission: `NOT_ALLOWED`, `REQUEST`, `SELECTED`, `ALLOWED` |
| **Version History** | Prescription updates create new versions, never destructive edits |
| **Urgent Updates** | Urgent prescription changes may auto-apply but must appear in history/audit |
| **Offline Support** | Reminders must function offline and sync actions later |
| **Audit Trail** | All actions logged for transparency |

---

## User Roles

| Role | Capabilities |
|------|--------------|
| **Patient** | Owns data, manages prescriptions, controls permissions |
| **Family/Caregiver** | Receives missed-dose alerts, views permitted history |
| **Doctor** | Updates prescriptions, monitors adherence (with permission) |

---

## Subscription Plans

| Plan | Price | Storage | Description |
|------|-------|---------|-------------|
| **Freemium** | Free | 5GB | MVP features: manual medication, reminders, records |
| **Premium** | $0.50/month | 20GB | All features enabled |
| **Family Premium** | $1/month | 20GB | Premium + up to 3 family members |

**User Story:**
- As a user, I can choose a plan that matches my needs and storage usage.

---

## Documentation Structure

```
about_das_tern/
├── README.md                    # This file
├── business_logic/              # Core rules and behaviors
├── flows/                       # Application flow documentation
│   ├── create_medication_flow/
│   ├── doctor_send_prescription_to_patient_flow/
│   ├── family_connection_flow/
│   └── reminder_flow/
└── ui_designs/                  # UI specifications
    ├── auth_ui/
    ├── doctor_dashboard_ui/
    ├── patient_dashboard_ui/
    ├── header_ui/
    └── footer_ui/
```

---

## Quick Links

- [Business Logic](./business_logic/README.md) - Detailed platform rules
- [Application Flows](./flows/README.md) - User journey documentation
- [UI Designs](./ui_designs/README.md) - Interface specifications
