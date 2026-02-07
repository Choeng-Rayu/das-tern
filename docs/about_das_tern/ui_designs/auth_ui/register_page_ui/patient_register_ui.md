# Patient Registration Screen UI Specification

**Screen Name**: Patient Registration
**Background Color**: Dark Blue (`#1A2744`)
**Target Device**: Mobile (430px width, iPhone 14 Pro Max)
**Flow**: 3-Step Registration (Welcome -> Sign Up -> OTP Verification)

---

## 1. Screen Overview

The patient registration flow guides new users through a 3-step process to create an account. Step 1 (Welcome) collects personal identity information. Step 2 (Sign Up) collects contact and security credentials. Step 3 (OTP Verification) confirms the phone number via a one-time password sent by SMS. All field labels and user-facing text are displayed in Khmer.

---

## 2. Registration Flow Diagram

```
+------------------+     +------------------+     +------------------+
|   Step 1         |     |   Step 2         |     |   Step 3         |
|   Welcome        | --> |   Sign Up        | --> |   OTP            |
|   (Personal      |     |   (Credentials)  |     |   Verification   |
|    Information)   |     |                  |     |                  |
+------------------+     +------------------+     +------------------+
```

---

## 3. Step 1 -- Welcome (Personal Information)

### 3.1 Screen Layout

```
+--------------------------------------------------+
|                                                    |
|              [App Logo]                            |
|              das-tern                              |
|                                                    |
|     Title: បង្កើតគណនីថ្មី                            |
|                                                    |
|     Label: នាមត្រកូល                                 |
|     +------------------------------------------+  |
|     | Placeholder: សូមបំពេញនាមត្រកូលរបស់អ្នក    |  |
|     +------------------------------------------+  |
|                                                    |
|     Label: នាមខ្លួន                                  |
|     +------------------------------------------+  |
|     | Placeholder: សូមបំពេញនាមខ្លួនរបស់អ្នក      |  |
|     +------------------------------------------+  |
|                                                    |
|     Label: ភេទ                                     |
|     +------------------------------------------+  |
|     | Placeholder: សូមបំពេញភេទរបស់អ្នក           |  |
|     +------------------------------------------+  |
|                                                    |
|     Label: ថ្ងៃ ខែ ឆ្នាំ កំណើត                        |
|     +------------+  +----------+  +-----------+   |
|     | ថ្ងៃទី       |  | ខែ       |  | ឆ្នាំ      |   |
|     +------------+  +----------+  +-----------+   |
|                                                    |
|     Label: លេខអត្តសញ្ញាណប័ណ្ណ                        |
|     +------------------------------------------+  |
|     | Placeholder: សូមបំពេញលេខអត្តសញ្ញាណប័ណ្ណ... |  |
|     +------------------------------------------+  |
|                                                    |
|     +------------------------------------------+  |
|     |               បន្ត                         |  |
|     +------------------------------------------+  |
|                                                    |
|        បានបង្កើតគណនីពីមុន  ចូលគណនី                  |
|                                                    |
+--------------------------------------------------+
```

### 3.2 Input Fields

| Field | Label (Khmer) | Placeholder (Khmer) | Type | Required |
|-------|---------------|----------------------|------|----------|
| Last Name | នាមត្រកូល | សូមបំពេញនាមត្រកូលរបស់អ្នក | text | Yes |
| First Name | នាមខ្លួន | សូមបំពេញនាមខ្លួនរបស់អ្នក | text | Yes |
| Gender | ភេទ | សូមបំពេញភេទរបស់អ្នក | dropdown | Yes |
| Date of Birth | ថ្ងៃ ខែ ឆ្នាំ កំណើត | ថ្ងៃទី / ខែ / ឆ្នាំ | date (3-part) | Yes |
| ID Card Number | លេខអត្តសញ្ញាណប័ណ្ណ | សូមបំពេញលេខអត្តសញ្ញាណប័ណ្ណរបស់អ្នក | text | Yes |

### 3.3 Actions

| Element | Label (Khmer) | Action |
|---------|---------------|--------|
| Continue Button | បន្ត | Validate fields and navigate to Step 2 |
| Sign In Link | បានបង្កើតគណនីពីមុន ចូលគណនី | Navigate to login screen |

### 3.4 Validation Rules

| Field | Rule | Khmer Error Message |
|-------|------|---------------------|
| Last Name | Field is empty | សូមបំពេញនាមត្រកូលរបស់អ្នក |
| Last Name | Contains numbers or special characters | នាមត្រកូលមិនត្រឹមត្រូវ |
| First Name | Field is empty | សូមបំពេញនាមខ្លួនរបស់អ្នក |
| First Name | Contains numbers or special characters | នាមខ្លួនមិនត្រឹមត្រូវ |
| Gender | No selection made | សូមបំពេញភេទរបស់អ្នក |
| Date of Birth | Field is empty | សូមជ្រើសរើសថ្ងៃខែឆ្នាំកំណើត |
| Date of Birth | Age is under 13 | អាយុមិនគ្រប់គ្រាន់សម្រាប់ការចុះឈ្មោះ |
| ID Card Number | Field is empty | សូមបំពេញលេខអត្តសញ្ញាណប័ណ្ណរបស់អ្នក |
| ID Card Number | Invalid format | លេខអត្តសញ្ញាណប័ណ្ណមិនត្រឹមត្រូវ |

---

## 4. Step 2 -- Sign Up (Contact and Credentials)

### 4.1 Screen Layout

```
+--------------------------------------------------+
|                                                    |
|     [Back Arrow]                                   |
|                                                    |
|              [App Logo]                            |
|              das-tern                              |
|                                                    |
|     Title: បង្កើតគណនីថ្មី                            |
|                                                    |
|     Label: លេខទូរស័ព្ទ                               |
|     +------+-----------------------------------+  |
|     | +855 | Placeholder: សូមបំពេញលេខទូរស័ព្ទ.. |  |
|     +------+-----------------------------------+  |
|                                                    |
|     Label: លេខកូខសម្ងាត់                              |
|     +------------------------------------------+  |
|     | Placeholder: សូមបំពេញលេខកូខសម្ងាត់  [Eye] |  |
|     +------------------------------------------+  |
|                                                    |
|     Label: បញ្ជាក់លេខកូខសម្ងាត់                       |
|     +------------------------------------------+  |
|     | Placeholder: សូមបំពេញ...ម្តងទៀត    [Eye] |  |
|     +------------------------------------------+  |
|                                                    |
|     Label: លេខកូខ៤ខ្ទង់                               |
|     +------------------------------------------+  |
|     | Placeholder: ****                        |  |
|     +------------------------------------------+  |
|                                                    |
|     សូមអានលក្ខខណ្ឌ និងច្បាប់មុនពេលប្រើប្រាស់កម្មវិធី  |
|     [ ] អានរួចរាល់                                   |
|                                                    |
|     +------------------------------------------+  |
|     |             បង្កើតគណនី                      |  |
|     +------------------------------------------+  |
|                                                    |
|        បានបង្កើតគណនីពីមុន  ចូលគណនី                  |
|                                                    |
+--------------------------------------------------+
```

### 4.2 Input Fields

| Field | Label (Khmer) | Placeholder (Khmer) | Type | Required |
|-------|---------------|----------------------|------|----------|
| Phone Number | លេខទូរស័ព្ទ | សូមបំពេញលេខទូរស័ព្ទរបស់អ្នក | tel | Yes |
| Password | លេខកូខសម្ងាត់ | សូមបំពេញលេខកូខសម្ងាត់របស់អ្នក | password | Yes |
| Confirm Password | បញ្ជាក់លេខកូខសម្ងាត់ | សូមបំពេញលេខកូខសម្ងាត់របស់អ្នកម្តងទៀត | password | Yes |
| PIN Code | លេខកូខ៤ខ្ទង់ | **** | number (4-digit) | Yes |

### 4.3 Phone Number Field Specification

| Property | Value |
|----------|-------|
| Country Code | +855 (Cambodia) |
| Country Code Display | Fixed prefix, non-editable |
| Accepted Formats | 0XX XXX XXXX or XX XXX XXXX (after +855) |
| Max Digits (after country code) | 9 |
| Keyboard Type | Numeric |

### 4.4 Actions

| Element | Label (Khmer) | Action |
|---------|---------------|--------|
| Back Arrow | ថយក្រោយ | Navigate back to Step 1 |
| Create Account Button | បង្កើតគណនី | Validate fields, send OTP, navigate to Step 3 |
| Terms Checkbox | អានរួចរាល់ | User confirms they have read the terms |
| Sign In Link | បានបង្កើតគណនីពីមុន ចូលគណនី | Navigate to login screen |

### 4.5 Validation Rules

| Field | Rule | Khmer Error Message |
|-------|------|---------------------|
| Phone Number | Field is empty | សូមបញ្ចូលលេខទូរស័ព្ទ |
| Phone Number | Invalid format (not matching +855 pattern) | លេខទូរស័ព្ទមិនត្រឹមត្រូវ |
| Phone Number | Already registered | លេខទូរស័ព្ទនេះបានចុះឈ្មោះរួចហើយ |
| Password | Field is empty | សូមបញ្ចូលពាក្យសម្ងាត់ |
| Password | Less than 6 characters | ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួ |
| Confirm Password | Field is empty | សូមបំពេញលេខកូខសម្ងាត់របស់អ្នកម្តងទៀត |
| Confirm Password | Does not match password | ពាក្យសម្ងាត់មិនត្រូវគ្នា |
| PIN Code | Field is empty | សូមបំពេញលេខកូខ៤ខ្ទង់ |
| PIN Code | Not exactly 4 digits | លេខកូខត្រូវមាន ៤ ខ្ទង់ |
| Terms Checkbox | Not checked | សូមអានលក្ខខណ្ឌ និងយល់ព្រមមុនពេលបន្ត |

---

## 5. Step 3 -- OTP Verification

### 5.1 Screen Layout

```
+--------------------------------------------------+
|                                                    |
|     [Back Arrow]                                   |
|                                                    |
|              [App Logo]                            |
|              das-tern                              |
|                                                    |
|     Title: បញ្ជាក់លេខទូរស័ព្ទ                        |
|                                                    |
|     Subtitle: យើងបានផ្ញើលេខកូដទៅកាន់              |
|               +855 XX XXX XXXX                     |
|                                                    |
|     +------+  +------+  +------+  +------+        |
|     |      |  |      |  |      |  |      |        |
|     +------+  +------+  +------+  +------+        |
|                                                    |
|     រង់ចាំ XX វិនាទី មុនពេលផ្ញើម្តងទៀត              |
|                                                    |
|     +------------------------------------------+  |
|     |             បញ្ជាក់                         |  |
|     +------------------------------------------+  |
|                                                    |
|     មិនទាន់ទទួលបានលេខកូដ? ផ្ញើម្តងទៀត              |
|                                                    |
+--------------------------------------------------+
```

### 5.2 OTP Input Specification

| Property | Value |
|----------|-------|
| Number of Fields | 4 individual digit fields |
| Field Width | 56px each |
| Field Height | 56px |
| Field Spacing | 16px |
| Border | 2px solid `#9E9E9E` (default) |
| Active Border | 2px solid `#2D5BFF` (focused) |
| Error Border | 2px solid `#E53935` (invalid) |
| Font Size | 24px |
| Font Weight | Bold |
| Text Alignment | Center |
| Keyboard Type | Numeric |
| Auto-advance | Yes (moves to next field on digit entry) |

### 5.3 OTP Behavior

| Behavior | Description |
|----------|-------------|
| OTP Length | 4 digits |
| OTP Delivery | Sent via SMS to the registered +855 phone number |
| OTP Expiry | 5 minutes from time of sending |
| Resend Cooldown | 60 seconds countdown before resend is enabled |
| Max Resend Attempts | 3 per registration session |
| Max Verification Attempts | 5 before temporary lockout |
| Lockout Duration | 15 minutes |
| Auto-submit | OTP is verified automatically when all 4 digits are entered |

### 5.4 Actions

| Element | Label (Khmer) | Action |
|---------|---------------|--------|
| Back Arrow | ថយក្រោយ | Navigate back to Step 2 |
| Verify Button | បញ្ជាក់ | Submit OTP for verification |
| Resend Link | ផ្ញើម្តងទៀត | Resend OTP to phone number |

### 5.5 OTP Display Text

| Element | Khmer Text |
|---------|------------|
| Title | បញ្ជាក់លេខទូរស័ព្ទ |
| Subtitle | យើងបានផ្ញើលេខកូដទៅកាន់ +855 XX XXX XXXX |
| Countdown | រង់ចាំ XX វិនាទី មុនពេលផ្ញើម្តងទៀត |
| Resend Prompt | មិនទាន់ទទួលបានលេខកូដ? |
| Resend Link | ផ្ញើម្តងទៀត |

### 5.6 Validation Rules

| Rule | Khmer Error Message |
|------|---------------------|
| OTP field is incomplete | សូមបញ្ចូលលេខកូដ ៤ ខ្ទង់ |
| OTP is incorrect | លេខកូដមិនត្រឹមត្រូវ សូមព្យាយាមម្តងទៀត |
| OTP has expired | លេខកូដផុតកំណត់ សូមស្នើសុំលេខកូដថ្មី |
| Max attempts exceeded | អ្នកបានព្យាយាមច្រើនដងពេក សូមរង់ចាំ ១៥ នាទី |
| Resend limit reached | អ្នកបានស្នើសុំលេខកូដអតិបរមាហើយ សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ |
| Network error | មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត |

---

## 6. Shared Styling

### 6.1 Input Field Styling

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

### 6.2 Password Field Additional Styling

| Property | Value |
|----------|-------|
| Toggle Visibility Icon | Eye icon aligned to the right inside the input |
| Icon Color | `#9E9E9E` (Gray) |
| Icon Size | 20px |

### 6.3 Button Styling

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

### 6.4 Button States

| State | Background Color | Text Color |
|-------|------------------|------------|
| Default | `#2D5BFF` | `#FFFFFF` |
| Pressed | `#1A3FCC` | `#FFFFFF` |
| Disabled | `#9E9E9E` | `#FFFFFF` |
| Loading | `#2D5BFF` with spinner | `#FFFFFF` |

### 6.5 Link Styling

| Element | Color | Font Size | Font Weight | Alignment |
|---------|-------|-----------|-------------|-----------|
| Sign In Link ("ចូលគណនី") | `#2D5BFF` | 14px | Bold | Center |
| Sign In Prompt ("បានបង្កើតគណនីពីមុន") | `#FFFFFF` | 14px | Regular | Center |
| Resend OTP Link ("ផ្ញើម្តងទៀត") | `#2D5BFF` | 14px | Bold | Center |

### 6.6 Error Display Styling

| Property | Value |
|----------|-------|
| Error Text Color | `#E53935` (Alert Red) |
| Error Font Size | 12px |
| Error Position | Below the respective input field |
| Error Margin Top | 4px |

### 6.7 Step Indicator (optional progress bar)

| Property | Value |
|----------|-------|
| Active Step Color | `#2D5BFF` (Primary Blue) |
| Inactive Step Color | `#9E9E9E` (Gray) |
| Completed Step Color | `#4CAF50` (Green) |
| Indicator Height | 4px |
| Indicator Spacing | 8px |

---

## 7. User Stories

### US-REG-001: Patient Enters Personal Information

**As a** new patient,
**I want to** enter my personal information including my last name (នាមត្រកូល), first name (នាមខ្លួន), gender (ភេទ), date of birth (ថ្ងៃ ខែ ឆ្នាំ កំណើត), and ID card number (លេខអត្តសញ្ញាណប័ណ្ណ) on the Welcome step,
**So that** my identity is recorded accurately in the system.

**Priority**: High

### US-REG-002: Patient Creates Account Credentials

**As a** new patient who has completed the Welcome step,
**I want to** enter my phone number (លេខទូរស័ព្ទ) with the +855 country code, create a password (លេខកូខសម្ងាត់), confirm it, set a 4-digit PIN (លេខកូខ៤ខ្ទង់), and accept the terms and conditions,
**So that** I have secure credentials to access my account.

**Priority**: High

### US-REG-003: Patient Verifies Phone Number via OTP

**As a** new patient who has submitted the Sign Up form,
**I want to** receive a 4-digit OTP via SMS to my +855 phone number and enter it on the verification screen,
**So that** my phone number is confirmed as valid and owned by me.

**Priority**: High

### US-REG-004: Patient Navigates Between Registration Steps

**As a** new patient in the registration flow,
**I want to** navigate forward by completing each step and backward using the back arrow (ថយក្រោយ),
**So that** I can review and correct my information before final submission.

**Priority**: Medium

---

## 8. Acceptance Criteria

### AC-001 (for US-REG-001)

- Given the user is on Step 1 (Welcome), when they fill in all required fields (នាមត្រកូល, នាមខ្លួន, ភេទ, ថ្ងៃ ខែ ឆ្នាំ កំណើត, លេខអត្តសញ្ញាណប័ណ្ណ) with valid data, then the "បន្ត" button becomes enabled.
- Given the user leaves any required field empty, then the corresponding Khmer error message is displayed below that field.
- Given the user enters a date of birth indicating age under 13, then the error message "អាយុមិនគ្រប់គ្រាន់សម្រាប់ការចុះឈ្មោះ" is displayed.
- Given the user taps "បន្ត" with all fields valid, then they are navigated to Step 2 (Sign Up).

### AC-002 (for US-REG-002)

- Given the user is on Step 2 (Sign Up), when they enter a valid +855 phone number, matching passwords of at least 6 characters, a 4-digit PIN, and check the terms checkbox, then the "បង្កើតគណនី" button becomes enabled.
- Given the user enters a phone number that is already registered, then the error message "លេខទូរស័ព្ទនេះបានចុះឈ្មោះរួចហើយ" is displayed.
- Given the passwords do not match, then the error message "ពាក្យសម្ងាត់មិនត្រូវគ្នា" is displayed below the confirm password field.
- Given the user has not checked the terms checkbox, then the "បង្កើតគណនី" button remains disabled.
- Given the user taps "បង្កើតគណនី" with all fields valid, then an OTP is sent to the phone number and they are navigated to Step 3 (OTP Verification).

### AC-003 (for US-REG-003)

- Given the user is on Step 3 (OTP Verification), when they enter the correct 4-digit OTP within the 5-minute expiry window, then the account is created and they are redirected to the patient dashboard.
- Given the user enters an incorrect OTP, then the error message "លេខកូដមិនត្រឹមត្រូវ សូមព្យាយាមម្តងទៀត" is displayed and the OTP fields are cleared.
- Given the OTP has expired, then the error message "លេខកូដផុតកំណត់ សូមស្នើសុំលេខកូដថ្មី" is displayed and the resend link is enabled.
- Given the user taps "ផ្ញើម្តងទៀត" during the cooldown period, then the resend link remains disabled and the countdown timer is visible.
- Given the user exceeds 5 verification attempts, then the error message "អ្នកបានព្យាយាមច្រើនដងពេក សូមរង់ចាំ ១៥ នាទី" is displayed and the verify button is disabled for 15 minutes.

### AC-004 (for US-REG-004)

- Given the user is on Step 2, when they tap the back arrow, then they are returned to Step 1 with all previously entered data preserved.
- Given the user is on Step 3, when they tap the back arrow, then they are returned to Step 2 with all previously entered data preserved.
- Given the user taps "បានបង្កើតគណនីពីមុន ចូលគណនី" on any step, then they are navigated to the login screen.

### AC-005 (General)

- All field labels, placeholders, error messages, and button text are displayed in Khmer.
- The phone number field enforces the +855 country code prefix.
- The "បន្ត" button on Step 1 and "បង្កើតគណនី" button on Step 2 remain disabled until all required fields are filled with valid data.
- A network error during OTP sending or verification displays "មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត".
- Registration success displays "ចុះឈ្មោះបានជោគជ័យ!" before redirecting to the patient dashboard.

---

## 9. Integration Points

### 9.1 Related Screens

| Screen | Path | Trigger |
|--------|------|---------|
| User Login | [user_login_ui.md](../login_page_ui/user_login_ui.md) | User taps "បានបង្កើតគណនីពីមុន ចូលគណនី" |
| Doctor Registration | [doctor_register_ui.md](doctor_register_ui.md) | User selects doctor role (future) |
| Account Recovery | [recovery_account_ui.md](../recovery_account_ui/recovery_account_ui.md) | Post-registration password reset |
| Patient Dashboard | Patient Dashboard | Successful registration and OTP verification |

### 9.2 Backend API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| /api/auth/register | POST | Submit patient registration data |
| /api/auth/otp/send | POST | Send OTP to the provided +855 phone number |
| /api/auth/otp/verify | POST | Verify the submitted OTP code |
| /api/auth/check-phone | POST | Check if a phone number is already registered |

### 9.3 Data Model References

| Model | Fields Used |
|-------|-------------|
| Patient | lastName, firstName, gender, dateOfBirth, idCardNumber, phoneNumber, password, pinCode |

### 9.4 Localization Keys

| Key | Khmer Value |
|-----|-------------|
| createNewAccount | បង្កើតគណនីថ្មី |
| lastName | នាមត្រកូល |
| fillLastName | សូមបំពេញនាមត្រកូលរបស់អ្នក |
| firstName | នាមខ្លួន |
| fillFirstName | សូមបំពេញនាមខ្លួនរបស់អ្នក |
| gender | ភេទ |
| fillGender | សូមបំពេញភេទរបស់អ្នក |
| dateOfBirth | ថ្ងៃ ខែ ឆ្នាំ កំណើត |
| idCardNumber | លេខអត្តសញ្ញាណប័ណ្ណ |
| fillIdCardNumber | សូមបំពេញលេខអត្តសញ្ញាណប័ណ្ណរបស់អ្នក |
| continueText | បន្ត |
| phoneNumber | លេខទូរស័ព្ទ |
| fillPhoneNumber | សូមបំពេញលេខទូរស័ព្ទរបស់អ្នក |
| password | លេខកូខសម្ងាត់ |
| fillPassword | សូមបំពេញលេខកូខសម្ងាត់របស់អ្នក |
| confirmPassword | បញ្ជាក់លេខកូខសម្ងាត់ |
| fillConfirmPassword | សូមបំពេញលេខកូខសម្ងាត់របស់អ្នកម្តងទៀត |
| pinCode | លេខកូខ៤ខ្ទង់ |
| readTerms | សូមអានលក្ខខណ្ឌ និងច្បាប់មុនពេលប្រើប្រាស់កម្មវិធី |
| alreadyRead | អានរួចរាល់ |
| alreadyCreatedAccount | បានបង្កើតគណនីពីមុន |
| signIn | ចូលគណនី |
| createAccount | បង្កើតគណនី |
| goBack | ថយក្រោយ |
| registerSuccess | ចុះឈ្មោះបានជោគជ័យ! |

---

*Last Updated: February 7, 2026*
