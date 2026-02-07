# User Login Screen UI Specification

**Screen Name**: Log In Page
**Background Color**: Dark Blue (`#1A2744`)
**Target Device**: Mobile (430px width, iPhone 14 Pro Max)

---

## 1. Screen Overview

The login screen provides authentication for existing users (patients and doctors) via phone number or email address and password. The screen uses a dark blue (`#1A2744`) background with white text and input fields styled on a light gray background.

---

## 2. Screen Layout

```
+--------------------------------------------------+
|                                                    |
|              [App Logo]                            |
|              das-tern                              |
|                                                    |
|     Label: លេខទូរសព្ទ ឬ អ៊ីមែល                      |
|     +------------------------------------------+  |
|     | Placeholder: បញ្ចូលលេខទូរសព្ទ ឬ អ៊ីមែល     |  |
|     +------------------------------------------+  |
|                                                    |
|     Label: លេខសម្ងាត់                                |
|     +------------------------------------------+  |
|     | Placeholder: បញ្ចូលលេខសម្ងាត់    [Eye Icon] |  |
|     +------------------------------------------+  |
|                                                    |
|                        ភ្លេចលេខសម្ងាត់?              |
|                                                    |
|     +------------------------------------------+  |
|     |             ចូលគណនី                        |  |
|     +------------------------------------------+  |
|                                                    |
|        មិនទាន់មានគណនីមែនទេ? ចុះឈ្មោះ               |
|                                                    |
+--------------------------------------------------+
```

---

## 3. UI Elements

### 3.1 App Branding

| Element | Description |
|---------|-------------|
| Logo | DasTern app icon displayed at the top center of the screen |
| App Name | "das-tern" displayed below the logo in white text |

### 3.2 Input Fields

| Field | Label (Khmer) | Placeholder (Khmer) | Type | Required |
|-------|---------------|----------------------|------|----------|
| Phone/Email | លេខទូរសព្ទ ឬ អ៊ីមែល | បញ្ចូលលេខទូរសព្ទ ឬ អ៊ីមែល | text | Yes |
| Password | លេខសម្ងាត់ | បញ្ចូលលេខសម្ងាត់ | password | Yes |

### 3.3 Actions

| Element | Label (Khmer) | Action |
|---------|---------------|--------|
| Forgot Password Link | ភ្លេចលេខសម្ងាត់? | Navigate to account recovery screen |
| Login Button | ចូលគណនី | Submit credentials for authentication |
| Register Link | មិនទាន់មានគណនីមែនទេ? ចុះឈ្មោះ | Navigate to registration screen |

---

## 4. Input Field Styling

| Property | Value |
|----------|-------|
| Background Color | `#F5F5F5` (Light Gray) |
| Border Radius | 8px |
| Height | 48px |
| Horizontal Padding | 24px |
| Font Size | 16px |
| Font Weight | Regular |
| Text Color (input) | `#1A2744` (Dark Blue) |
| Placeholder Color | `#9E9E9E` (Gray) |
| Label Color | `#FFFFFF` (White) |
| Label Font Size | 14px |
| Label Font Weight | Regular |
| Label Margin Bottom | 8px |
| Field Spacing (between fields) | 16px |

### Password Field Additional Styling

| Property | Value |
|----------|-------|
| Toggle Visibility Icon | Eye icon aligned to the right inside the input |
| Icon Color | `#9E9E9E` (Gray) |
| Icon Size | 20px |

---

## 5. Button Styling

| Property | Value |
|----------|-------|
| Background Color | `#2D5BFF` (Primary Blue) |
| Text Color | `#FFFFFF` (White) |
| Font Size | 16px |
| Font Weight | Bold |
| Height | 48px |
| Border Radius | 8px |
| Width | 100% (full width within padding) |
| Horizontal Margin | 24px |

### Button States

| State | Background Color | Text Color |
|-------|------------------|------------|
| Default | `#2D5BFF` | `#FFFFFF` |
| Pressed | `#1A3FCC` | `#FFFFFF` |
| Disabled | `#9E9E9E` | `#FFFFFF` |
| Loading | `#2D5BFF` with spinner | `#FFFFFF` |

---

## 6. Link Styling

| Element | Color | Font Size | Font Weight | Alignment |
|---------|-------|-----------|-------------|-----------|
| Forgot Password | `#2D5BFF` | 14px | Regular | Right-aligned |
| Register Link ("ចុះឈ្មោះ") | `#2D5BFF` | 14px | Bold | Center |
| Register Prompt ("មិនទាន់មានគណនីមែនទេ?") | `#FFFFFF` | 14px | Regular | Center |

---

## 7. Validation Rules and Error Messages

### 7.1 Phone/Email Field

| Rule | Khmer Error Message |
|------|---------------------|
| Field is empty | សូមបញ្ចូលលេខទូរសព្ទ ឬ អ៊ីមែល |
| Invalid phone format (not starting with +855 or 0) | លេខទូរសព្ទមិនត្រឹមត្រូវ |
| Invalid email format | អ៊ីមែលមិនត្រឹមត្រូវ |
| Account not found | គណនីនេះមិនមានក្នុងប្រព័ន្ធទេ |

### 7.2 Password Field

| Rule | Khmer Error Message |
|------|---------------------|
| Field is empty | សូមបញ្ចូលលេខសម្ងាត់ |
| Password too short (less than 8 characters) | លេខសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៨ តួអក្សរ |
| Incorrect password | លេខសម្ងាត់មិនត្រឹមត្រូវ |

### 7.3 General Authentication

| Rule | Khmer Error Message |
|------|---------------------|
| Invalid credentials | លេខទូរសព្ទ/អ៊ីមែល ឬ លេខសម្ងាត់មិនត្រឹមត្រូវ |
| Account locked (too many attempts) | គណនីរបស់អ្នកត្រូវបានចាក់សោ សូមព្យាយាមម្ដងទៀតក្រោយ ១៥ នាទី |
| Network error | មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត |

### 7.4 Error Display Styling

| Property | Value |
|----------|-------|
| Error Text Color | `#E53935` (Alert Red) |
| Error Font Size | 12px |
| Error Position | Below the respective input field |
| Error Margin Top | 4px |

---

## 8. User Stories

### US-AUTH-001: User Login with Phone Number

**As a** registered user (patient or doctor),
**I want to** log in using my phone number and password,
**So that** I can access my dashboard and manage my medication or prescriptions.

**Priority**: High

### US-AUTH-002: User Login with Email

**As a** registered user (patient or doctor),
**I want to** log in using my email address and password,
**So that** I have an alternative authentication method if I prefer email over phone.

**Priority**: Medium

### US-AUTH-003: Password Visibility Toggle

**As a** user on the login screen,
**I want to** toggle the visibility of my password,
**So that** I can verify I have entered my password correctly before submitting.

**Priority**: Medium

### US-AUTH-004: Navigate to Account Recovery

**As a** user who has forgotten their password,
**I want to** tap the "ភ្លេចលេខសម្ងាត់?" link on the login screen,
**So that** I can begin the account recovery process and regain access.

**Priority**: High

---

## 9. Acceptance Criteria

### AC-001 (for US-AUTH-001)

- Given the user is on the login screen, when they enter a valid phone number (starting with +855 or 0) and the correct password, then they are authenticated and redirected to the appropriate dashboard (patient or doctor).
- Given the user enters an invalid phone number format, then the error message "លេខទូរសព្ទមិនត្រឹមត្រូវ" is displayed below the phone/email input field.
- Given the user leaves the phone/email field empty, then the error message "សូមបញ្ចូលលេខទូរសព្ទ ឬ អ៊ីមែល" is displayed.

### AC-002 (for US-AUTH-002)

- Given the user is on the login screen, when they enter a valid email address and the correct password, then they are authenticated and redirected to the appropriate dashboard.
- Given the user enters an invalid email format, then the error message "អ៊ីមែលមិនត្រឹមត្រូវ" is displayed below the phone/email input field.

### AC-003 (for US-AUTH-003)

- Given the user is on the login screen, when they tap the eye icon in the password field, then the password text toggles between hidden (dots) and visible (plain text).
- Given the password is visible, when the user taps the eye icon again, then the password is hidden.

### AC-004 (for US-AUTH-004)

- Given the user is on the login screen, when they tap the "ភ្លេចលេខសម្ងាត់?" link, then they are navigated to the account recovery screen.
- Given the user taps the "ចុះឈ្មោះ" link, then they are navigated to the registration screen.

### AC-005 (General)

- Given the user enters incorrect credentials 5 consecutive times, then the account is locked and the error message "គណនីរបស់អ្នកត្រូវបានចាក់សោ សូមព្យាយាមម្ដងទៀតក្រោយ ១៥ នាទី" is displayed.
- Given a network error occurs during login, then the error message "មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត" is displayed.
- The login button remains disabled until both input fields contain at least one character.

---

## 10. Integration Points

### Related Screens

| Screen | Path | Trigger |
|--------|------|---------|
| Patient Registration | [patient_register_ui.md](../register_page_ui/patient_register_ui.md) | User taps "ចុះឈ្មោះ" link |
| Doctor Registration | [doctor_register_ui.md](../register_page_ui/doctor_register_ui.md) | User selects doctor role during registration |
| Account Recovery | [recovery_account_ui.md](../recovery_account_ui/recovery_account_ui.md) | User taps "ភ្លេចលេខសម្ងាត់?" link |

### Post-Login Navigation

| User Role | Destination |
|-----------|-------------|
| Patient | Patient Dashboard (medication schedule) |
| Doctor | Doctor Dashboard (prescription management) |

---

*Last Updated: February 7, 2026*
