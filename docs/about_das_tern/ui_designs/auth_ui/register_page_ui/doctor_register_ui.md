# Doctor Registration UI - DasTern

## Overview

Registration flow for healthcare providers with license verification.

---

## Flow Steps

1. **Personal Details** - Name, phone, hospital, specialty
2. **License Verification** - License number + photo upload
3. **Password Setup** - Create account password

---

## Personal Details Screen

| Field | Label (Khmer) | Type |
|-------|---------------|------|
| Full Name | ឈ្មោះពេញ | Text |
| Phone | លេខទូរស័ព្ទ | Tel (+855) |
| Hospital/Clinic | មន្ទីរពេទ្យ / គ្លីនិក | Text |
| Specialty | ជំនាញ | Dropdown |

---

## License Verification

| Field | Label | Type |
|-------|-------|------|
| License Number | លេខអាជ្ញាប័ណ្ណ | Text |
| License Photo | រូបថតអាជ្ញាប័ណ្ណ | Image upload |

> [!NOTE]
> License verified within 24-48 hours.

---

## Specialty Options

- General Practice (វេជ្ជសាស្រ្តទូទៅ)
- Internal Medicine (វេជ្ជសាស្រ្តផ្ទៃក្នុង)
- Cardiology (បេះដូង)
- Endocrinology (អង់ដូគ្រីន)
- Other (ផ្សេងទៀត)

---

## Acceptance Criteria

- [ ] Doctor-specific registration fields
- [ ] License photo upload
- [ ] Verification pending notice
- [ ] Password setup step
