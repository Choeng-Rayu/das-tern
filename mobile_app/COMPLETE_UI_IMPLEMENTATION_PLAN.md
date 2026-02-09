# Das Tern Mobile App - Complete UI Implementation Plan

**Based on**: Figma Design Documentation (`/docs/about_das_tern/ui_designs/`)  
**Created**: February 8, 2026  
**Status**: Planning Phase

---

## Overview

This document outlines the complete implementation plan for all UI screens and components based on the Figma designs. The implementation will be done in phases, building upon the existing MVP foundation.

---

## Current Status (MVP Completed)

### ✅ Already Implemented
- Basic patient dashboard with time groups
- Create medication screen
- Medication detail screen
- Settings screen (language & theme)
- Bottom navigation (basic structure)
- Theme system (light/dark)
- Localization (English/Khmer)
- Database and sync services
- Notification service

### 🔄 Needs Enhancement
- Patient dashboard (match Figma design exactly)
- Bottom navigation (add center FAB, update icons)
- Header component (add progress bar, greeting)
- Medication cards (match Figma styling)

### ❌ Not Yet Implemented
- Authentication screens (login, register, recovery)
- Doctor dashboard and features
- Family connection features
- Prescription scanning
- Medication analysis
- Onboarding survey
- Profile management

---

## Implementation Phases

```
Phase 1: Core UI Components & Auth (Week 1-2)
    ↓
Phase 2: Enhanced Patient Features (Week 3-4)
    ↓
Phase 3: Doctor Features (Week 5-6)
    ↓
Phase 4: Family & Advanced Features (Week 7-8)
    ↓
Phase 5: Polish & Testing (Week 9-10)
```

---

## PHASE 1: Core UI Components & Authentication (Priority: HIGH)

### Task 1.1: Design System Foundation
**Estimated Time**: 2 days

**Objective**: Create a centralized design system matching Figma specifications

**Subtasks**:
- [ ] Create `lib/ui/theme/design_tokens.dart` with all colors, typography, spacing
- [ ] Define color constants:
  - Primary Blue: `#2D5BFF`
  - Dark Blue: `#1A2744`
  - Alert Red: `#E53935`
  - Afternoon Orange: `#FF6B35`
  - Night Purple: `#6B4AA3`
  - Success Green: `#4CAF50`
  - Neutral Gray: `#9E9E9E`
  - Background: `#F5F5F5`
- [ ] Define typography scale (H1: 24px Bold, H2: 18px Semibold, Body: 14px, Caption: 12px)
- [ ] Create spacing constants (4px, 8px, 16px, 24px, 32px)
- [ ] Create border radius constants (4px, 8px, 12px, 16px)
- [ ] Update existing themes to use design tokens

**Files to Create**:
- `lib/ui/theme/design_tokens.dart`
- `lib/ui/theme/app_colors.dart`
- `lib/ui/theme/app_typography.dart`
- `lib/ui/theme/app_spacing.dart`

**Acceptance Criteria**:
- All Figma colors defined as constants
- Typography scale matches Figma specs
- Existing screens use design tokens

---

### Task 1.2: Global Header Component
**Estimated Time**: 2 days

**Objective**: Create reusable header component with greeting, progress bar, and notifications

**Subtasks**:
- [ ] Create `lib/ui/widgets/app_header.dart`
- [ ] Add app logo and "ដាស់តឿន" text
- [ ] Add personalized greeting "សួស្តី [Username] !"
- [ ] Add progress bar (daily medication completion)
- [ ] Add notification bell with badge count
- [ ] Create doctor variant with "វេជ្ជបណ្ឌិត" label
- [ ] Add tap handlers (logo → home, bell → notifications)
- [ ] Integrate with existing dashboard

**Files to Create**:
- `lib/ui/widgets/app_header.dart`
- `lib/models/user_model/user.dart` (if not exists)

**Acceptance Criteria**:
- Header displays on all main screens
- Progress bar updates based on dose events
- Notification badge shows unread count
- Doctor variant displays correctly
- Tapping logo navigates to home
- Tapping bell opens notifications

---

### Task 1.3: Enhanced Bottom Navigation with Center FAB
**Estimated Time**: 2 days

**Objective**: Update bottom navigation to match Figma design with raised center FAB

**Subtasks**:
- [ ] Update `lib/ui/widgets/patient_bottom_nav.dart`
- [ ] Add center FAB (raised 7px above nav bar)
- [ ] Update icons to match Figma (🏠 💊 📷 👨👩👧 ⚙️)
- [ ] Update labels: ទំព័រដើម, ការវិភាគថ្នាំ, ស្កេនវេជ្ជបញ្ជា, មុខងារគ្រួសារ, ការកំណត់
- [ ] Create `lib/ui/widgets/doctor_bottom_nav.dart`
- [ ] Add doctor tabs: ទំព័រដើម, តាមដានអ្នកជំងឺ, បង្កើតវេជ្ជបញ្ជា, ប្រវិត្តវេជ្ជបញ្ជារ, ការកំណត់
- [ ] Style active/inactive states (Blue #2D5BFF / Gray #9E9E9E)
- [ ] Add badge notification support
- [ ] Respect iOS safe area

**Files to Update/Create**:
- `lib/ui/widgets/patient_bottom_nav.dart` (update)
- `lib/ui/widgets/doctor_bottom_nav.dart` (create)
- `lib/ui/widgets/center_fab.dart` (create)

**Acceptance Criteria**:
- Center FAB is visually raised
- All icons and labels match Figma
- Active tab highlighted in blue
- Badge notifications display
- Safe area respected on iOS

---

### Task 1.4: Login Screen
**Estimated Time**: 3 days

**Objective**: Implement user login with phone/email and password

**Subtasks**:
- [ ] Create `lib/ui/screens/auth_ui/login_screen.dart`
- [ ] Dark blue background (#1A2744)
- [ ] Add app logo and "das-tern" text
- [ ] Add phone/email input field (label: លេខទូរសព្ទ ឬ អ៊ីមែល)
- [ ] Add password input field with eye icon toggle (label: លេខសម្ងាត់)
- [ ] Add "ភ្លេចលេខសម្ងាត់?" link
- [ ] Add "ចូលគណនី" button
- [ ] Add "មិនទាន់មានគណនីមែនទេ? ចុះឈ្មោះ" link
- [ ] Implement validation (phone format, email format, required fields)
- [ ] Add error messages in Khmer
- [ ] Integrate with auth service
- [ ] Handle loading state
- [ ] Navigate to dashboard on success

**Files to Create**:
- `lib/ui/screens/auth_ui/login_screen.dart`
- `lib/services/auth_service.dart`
- `lib/providers/auth_provider.dart`

**Localization Keys to Add**:
- phoneOrEmail, password, forgotPassword, login, noAccount, register
- Error messages: invalidPhone, invalidEmail, incorrectPassword, accountLocked, networkError

**Acceptance Criteria**:
- Login with phone number works
- Login with email works
- Password visibility toggle works
- Validation shows Khmer error messages
- Forgot password link navigates correctly
- Register link navigates correctly
- Loading state displays during authentication
- Account lockout after 5 failed attempts

---

### Task 1.5: Patient Registration Screen (3-Step Flow)
**Estimated Time**: 5 days

**Objective**: Implement 3-step patient registration (Personal Info → Credentials → OTP)

**Subtasks**:

**Step 1: Personal Information**
- [ ] Create `lib/ui/screens/auth_ui/register/patient_register_step1_screen.dart`
- [ ] Add fields: នាមត្រកូល, នាមខ្លួន, ភេទ, ថ្ងៃ ខែ ឆ្នាំ កំណើត, លេខអត្តសញ្ញាណប័ណ្ណ
- [ ] Add gender dropdown (ប្រុស, ស្រី, ផ្សេងទៀត)
- [ ] Add date picker (3-part: day, month, year)
- [ ] Validate age >= 13
- [ ] Add "បន្ត" button
- [ ] Add "បានបង្កើតគណនីពីមុន ចូលគណនី" link

**Step 2: Credentials**
- [ ] Create `lib/ui/screens/auth_ui/register/patient_register_step2_screen.dart`
- [ ] Add back button
- [ ] Add phone field with +855 prefix
- [ ] Add password field with eye icon
- [ ] Add confirm password field
- [ ] Add 4-digit PIN field
- [ ] Add terms checkbox "អានរួចរាល់"
- [ ] Add "បង្កើតគណនី" button
- [ ] Validate password strength (min 8 chars, 1 uppercase, 1 number)
- [ ] Validate password match
- [ ] Validate PIN is 4 digits

**Step 3: OTP Verification**
- [ ] Create `lib/ui/screens/auth_ui/register/patient_register_step3_screen.dart`
- [ ] Display phone number
- [ ] Add 6-digit OTP input fields
- [ ] Add countdown timer (60 seconds)
- [ ] Add "ផ្ញើរកូដម្តងទៀត" button
- [ ] Verify OTP with backend
- [ ] Navigate to onboarding survey on success

**Files to Create**:
- `lib/ui/screens/auth_ui/register/patient_register_step1_screen.dart`
- `lib/ui/screens/auth_ui/register/patient_register_step2_screen.dart`
- `lib/ui/screens/auth_ui/register/patient_register_step3_screen.dart`
- `lib/ui/widgets/otp_input_field.dart`
- `lib/models/user_model/patient.dart`

**Acceptance Criteria**:
- All 3 steps flow correctly
- Validation works on each step
- OTP is sent via SMS
- OTP verification works
- Terms must be accepted to proceed
- Back button works on step 2
- Error messages display in Khmer

---

### Task 1.6: Doctor Registration Screen
**Estimated Time**: 3 days

**Objective**: Implement doctor registration with license verification

**Subtasks**:
- [ ] Create `lib/ui/screens/auth_ui/register/doctor_register_screen.dart`
- [ ] Add all patient registration fields
- [ ] Add doctor-specific fields:
  - Medical license number (លេខអាជ្ញាប័ណ្ណវេជ្ជបណ្ឌិត)
  - Specialization (ជំនាញ)
  - Hospital/Clinic name (មន្ទីរពេទ្យ/គ្លីនិក)
- [ ] Add license document upload
- [ ] Add verification pending state
- [ ] Send verification request to admin

**Files to Create**:
- `lib/ui/screens/auth_ui/register/doctor_register_screen.dart`
- `lib/models/user_model/doctor.dart`

**Acceptance Criteria**:
- Doctor can register with license info
- Document upload works
- Verification pending message displays
- Admin receives verification request

---

### Task 1.7: Account Recovery Screen
**Estimated Time**: 2 days

**Objective**: Implement password reset flow

**Subtasks**:
- [ ] Create `lib/ui/screens/auth_ui/recovery_screen.dart`
- [ ] Add phone/email input
- [ ] Send OTP to phone/email
- [ ] Verify OTP
- [ ] Allow password reset
- [ ] Navigate back to login

**Files to Create**:
- `lib/ui/screens/auth_ui/recovery_screen.dart`

**Acceptance Criteria**:
- OTP sent to phone/email
- OTP verification works
- Password can be reset
- User can login with new password

---

## PHASE 2: Enhanced Patient Features (Priority: HIGH)

### Task 2.1: Onboarding Survey (Meal Times)
**Estimated Time**: 3 days

**Objective**: Collect patient meal times for reminder calculation

**Subtasks**:
- [ ] Create `lib/ui/screens/onboarding/meal_time_survey_screen.dart`
- [ ] Create 3 survey screens:
  - Morning meal time (តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលព្រឹក?)
  - Afternoon meal time (តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលរសៀល?)
  - Night meal time (តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលយប់?)
- [ ] Add radio button time options (6-7AM, 7-8AM, 8-9AM, 9-10AM, etc.)
- [ ] Save meal times to user profile
- [ ] Use meal times for "បន្ទាប់ពីអាហារ" reminder calculation
- [ ] Navigate to dashboard after completion

**Files to Create**:
- `lib/ui/screens/onboarding/meal_time_survey_screen.dart`
- `lib/models/user_model/meal_times.dart`

**Acceptance Criteria**:
- Survey appears after first login
- User can select meal times
- Meal times saved to profile
- Reminders calculated based on meal times
- Can skip survey (use defaults)

---

### Task 2.2: Enhanced Patient Dashboard
**Estimated Time**: 4 days

**Objective**: Update dashboard to match Figma design exactly

**Subtasks**:
- [ ] Update `lib/ui/screens/patient_ui/patient_dashboard_screen.dart`
- [ ] Add app header component
- [ ] Update medication card styling to match Figma
- [ ] Add medication images/thumbnails
- [ ] Update time group section styling
- [ ] Add "រួចរាល់" (done) state with green checkmark
- [ ] Add missed state with red indicator
- [ ] Update progress bar in header
- [ ] Add empty state illustration
- [ ] Add pull-to-refresh
- [ ] Optimize for Khmer text rendering

**Files to Update**:
- `lib/ui/screens/patient_ui/patient_dashboard_screen.dart`
- `lib/ui/widgets/medication_card.dart`
- `lib/ui/widgets/time_group_section.dart`

**Acceptance Criteria**:
- Dashboard matches Figma design
- Medication cards show images
- Time groups use correct colors (Blue #2D5BFF, Purple #6B4AA3)
- Done state shows "រួចរាល់" with green checkmark
- Missed state shows red indicator
- Progress bar updates correctly
- Empty state displays when no medications

---

### Task 2.3: Enhanced Medication Detail Screen
**Estimated Time**: 2 days

**Objective**: Update detail screen to match Figma design

**Subtasks**:
- [ ] Update `lib/ui/screens/patient_ui/medication_detail_screen.dart`
- [ ] Add back button "ថយក្រោយ"
- [ ] Display medication image
- [ ] Show frequency (ផាបញឹកញាប់): "3ដង/១ថ្ងៃ"
- [ ] Show timing (ពេលវេលា): "បន្ទាប់ពីអាហារ"
- [ ] Show recommended reminder times (ពេលវេលារំលឹកដែលបានណែនាំ)
- [ ] Add "កែប្រែការរុំលឹកពេលវេលា" button
- [ ] Add analysis section (ការវិភាគថ្នាំ) placeholder
- [ ] Match Figma styling

**Files to Update**:
- `lib/ui/screens/patient_ui/medication_detail_screen.dart`

**Acceptance Criteria**:
- Detail screen matches Figma design
- All fields display correctly in Khmer
- Edit reminder button navigates to editor
- Back button works

---

### Task 2.4: Reminder Time Editor
**Estimated Time**: 2 days

**Objective**: Allow editing reminder times for a medication

**Subtasks**:
- [ ] Create `lib/ui/screens/patient_ui/edit_reminder_times_screen.dart`
- [ ] Display current reminder times
- [ ] Allow adding/removing reminder times
- [ ] Use time picker for each reminder
- [ ] Save updated times
- [ ] Regenerate dose events
- [ ] Reschedule notifications

**Files to Create**:
- `lib/ui/screens/patient_ui/edit_reminder_times_screen.dart`

**Acceptance Criteria**:
- Can add/remove reminder times
- Time picker works
- Changes save correctly
- Notifications rescheduled
- Dose events regenerated

---

### Task 2.5: Medication Analysis Screen (Placeholder)
**Estimated Time**: 2 days

**Objective**: Create placeholder for medication analysis feature

**Subtasks**:
- [ ] Create `lib/ui/screens/patient_ui/medication_analysis_screen.dart`
- [ ] Add "Coming Soon" message
- [ ] Add placeholder charts/graphs
- [ ] Link from bottom navigation

**Files to Create**:
- `lib/ui/screens/patient_ui/medication_analysis_screen.dart`

**Acceptance Criteria**:
- Screen accessible from bottom nav
- Coming soon message displays
- Placeholder UI matches design

---

### Task 2.6: Prescription Scanning Screen (Placeholder)
**Estimated Time**: 3 days

**Objective**: Create camera/QR scanner for prescription import

**Subtasks**:
- [ ] Create `lib/ui/screens/patient_ui/scan_prescription_screen.dart`
- [ ] Add camera permission request
- [ ] Add camera preview
- [ ] Add QR code scanner
- [ ] Add manual entry option
- [ ] Parse prescription data (future)
- [ ] Create medications from scan (future)

**Files to Create**:
- `lib/ui/screens/patient_ui/scan_prescription_screen.dart`
- `lib/services/camera_service.dart`
- `lib/services/qr_scanner_service.dart`

**Dependencies**:
- camera: ^0.10.5
- qr_code_scanner: ^1.0.1

**Acceptance Criteria**:
- Camera opens when FAB tapped
- QR scanner works
- Manual entry option available
- Permissions handled correctly

---

## PHASE 3: Doctor Features (Priority: MEDIUM)

### Task 3.1: Doctor Dashboard
**Estimated Time**: 4 days

**Objective**: Create doctor dashboard with patient list and adherence monitoring

**Subtasks**:
- [ ] Create `lib/ui/screens/doctor_ui/doctor_dashboard_screen.dart`
- [ ] Add doctor header variant
- [ ] Display patient list
- [ ] Show patient cards with:
  - Name, gender, age, phone
  - Current symptoms
  - Adherence percentage bar
- [ ] Color-code adherence (Green >= 80%, Yellow 50-79%, Red < 50%)
- [ ] Add search/filter patients
- [ ] Tap patient card → patient detail

**Files to Create**:
- `lib/ui/screens/doctor_ui/doctor_dashboard_screen.dart`
- `lib/ui/widgets/patient_card.dart`
- `lib/models/patient_adherence_model.dart`

**Acceptance Criteria**:
- Patient list displays
- Adherence bars color-coded correctly
- Can search/filter patients
- Tapping card opens patient detail

---

### Task 3.2: Patient Detail Screen (Doctor View)
**Estimated Time**: 3 days

**Objective**: Show patient's medication schedule and adherence history

**Subtasks**:
- [ ] Create `lib/ui/screens/doctor_ui/patient_detail_screen.dart`
- [ ] Display patient info
- [ ] Show current prescriptions
- [ ] Show medication schedule (ពេលព្រឹក / ពេលថ្ងៃ / ពេលយប់)
- [ ] Show adherence chart
- [ ] Add "Create Prescription" button

**Files to Create**:
- `lib/ui/screens/doctor_ui/patient_detail_screen.dart`

**Acceptance Criteria**:
- Patient info displays
- Current prescriptions listed
- Medication schedule shows
- Adherence chart displays
- Can create new prescription

---

### Task 3.3: Prescription Creation Form
**Estimated Time**: 5 days

**Objective**: Create prescription form with medication grid

**Subtasks**:
- [ ] Create `lib/ui/screens/doctor_ui/create_prescription_screen.dart`
- [ ] Add patient info section (ឈ្មោះ, ភេទ, អាយុ, រោគសញ្ញា)
- [ ] Add medication grid table:
  - Columns: ល.រ, ឈ្មោះឱសថ, ពេលព្រឹក, ពេលថ្ងៃ, ពេលយប់
  - Before/after meal indicators
- [ ] Add "បន្ថែមថ្នាំ" button (add medication row)
- [ ] Add medication search/autocomplete
- [ ] Add dosage input for each time period
- [ ] Add "Send to Patient" button
- [ ] Validate all fields
- [ ] Send prescription to patient

**Files to Create**:
- `lib/ui/screens/doctor_ui/create_prescription_screen.dart`
- `lib/ui/widgets/medication_grid_table.dart`
- `lib/models/prescription_model/prescription.dart`

**Acceptance Criteria**:
- Form matches Figma design
- Can add multiple medications
- Grid table works correctly
- Before/after meal indicators work
- Validation prevents incomplete prescriptions
- Prescription sent to patient

---

### Task 3.4: Prescription for Patient View
**Estimated Time**: 3 days

**Objective**: Patient-facing prescription view with confirm/retake actions

**Subtasks**:
- [ ] Create `lib/ui/screens/patient_ui/prescription_view_screen.dart`
- [ ] Display doctor name and date
- [ ] Show diagnosis
- [ ] Show medication grid table
- [ ] Add "Confirm" button
- [ ] Add "Retake" button
- [ ] Add "បន្ថែមថ្នាំ" button
- [ ] Handle confirm action (create medications)
- [ ] Handle retake action (notify doctor)

**Files to Create**:
- `lib/ui/screens/patient_ui/prescription_view_screen.dart`

**Acceptance Criteria**:
- Prescription displays correctly
- Confirm creates medications
- Retake notifies doctor
- Can add additional medications

---

### Task 3.5: Urgent Prescription Update
**Estimated Time**: 3 days

**Objective**: Allow doctors to urgently update prescriptions with reason

**Subtasks**:
- [ ] Add "Urgent Update" option to prescription edit
- [ ] Require reason input
- [ ] Auto-apply changes to patient schedule
- [ ] Send notification to patient
- [ ] Log in audit trail

**Files to Update**:
- `lib/ui/screens/doctor_ui/create_prescription_screen.dart`
- `lib/services/prescription_service.dart`

**Acceptance Criteria**:
- Urgent flag can be set
- Reason is required
- Changes auto-apply
- Patient notified
- Audit trail logged

---

### Task 3.6: Prescription History Screen
**Estimated Time**: 2 days

**Objective**: Show doctor's past prescriptions

**Subtasks**:
- [ ] Create `lib/ui/screens/doctor_ui/prescription_history_screen.dart`
- [ ] List all prescriptions
- [ ] Filter by patient
- [ ] Filter by date range
- [ ] Tap prescription → view details

**Files to Create**:
- `lib/ui/screens/doctor_ui/prescription_history_screen.dart`

**Acceptance Criteria**:
- Prescription list displays
- Filters work
- Can view prescription details

---

## PHASE 4: Family & Advanced Features (Priority: LOW)

### Task 4.1: Family Connection Screen
**Estimated Time**: 4 days

**Objective**: Allow patients to connect with family members

**Subtasks**:
- [ ] Create `lib/ui/screens/patient_ui/family_connection_screen.dart`
- [ ] Add QR code generation for connection
- [ ] Add QR code scanner for connection
- [ ] Add phone/email invitation
- [ ] Show connected family members
- [ ] Set permissions for each family member
- [ ] Add remove family member option

**Files to Create**:
- `lib/ui/screens/patient_ui/family_connection_screen.dart`
- `lib/services/family_connection_service.dart`
- `lib/models/family_connection_model.dart`

**Acceptance Criteria**:
- QR code generation works
- QR code scanning works
- Can invite via phone/email
- Connected family members listed
- Permissions can be set
- Can remove family members

---

### Task 4.2: Family Alerts
**Estimated Time**: 3 days

**Objective**: Send missed-dose alerts to family members

**Subtasks**:
- [ ] Detect missed doses
- [ ] Send push notifications to family
- [ ] Show alert in family member's app
- [ ] Allow family to acknowledge alert
- [ ] Log family interactions

**Files to Update**:
- `lib/services/notification_service.dart`
- `lib/services/sync_service.dart`

**Acceptance Criteria**:
- Missed doses trigger family alerts
- Family receives notifications
- Alerts display in family app
- Family can acknowledge
- Interactions logged

---

### Task 4.3: Profile Management
**Estimated Time**: 3 days

**Objective**: Allow users to edit their profile

**Subtasks**:
- [ ] Create `lib/ui/screens/profile/profile_screen.dart`
- [ ] Display user info
- [ ] Allow editing name, phone, email
- [ ] Allow changing password
- [ ] Allow changing profile picture
- [ ] Save changes

**Files to Create**:
- `lib/ui/screens/profile/profile_screen.dart`

**Acceptance Criteria**:
- Profile displays correctly
- Can edit all fields
- Changes save correctly
- Password change works
- Profile picture upload works

---

### Task 4.4: Notifications Screen
**Estimated Time**: 2 days

**Objective**: Display all notifications

**Subtasks**:
- [ ] Create `lib/ui/screens/notifications/notifications_screen.dart`
- [ ] List all notifications
- [ ] Mark as read
- [ ] Delete notifications
- [ ] Filter by type

**Files to Create**:
- `lib/ui/screens/notifications/notifications_screen.dart`

**Acceptance Criteria**:
- Notifications list displays
- Can mark as read
- Can delete
- Filters work

---

## PHASE 5: Polish & Testing (Priority: HIGH)

### Task 5.1: UI Polish
**Estimated Time**: 5 days

**Subtasks**:
- [ ] Add loading skeletons
- [ ] Add smooth transitions
- [ ] Add haptic feedback
- [ ] Add animations (fade, slide, scale)
- [ ] Optimize Khmer font rendering
- [ ] Add empty states for all screens
- [ ] Add error states for all screens
- [ ] Improve accessibility (screen readers, contrast)
- [ ] Test on different screen sizes
- [ ] Test on Android and iOS

---

### Task 5.2: Integration Testing
**Estimated Time**: 5 days

**Subtasks**:
- [ ] Write integration tests for auth flow
- [ ] Write integration tests for medication creation
- [ ] Write integration tests for prescription flow
- [ ] Write integration tests for family connection
- [ ] Write integration tests for offline sync
- [ ] Test all user journeys end-to-end

---

### Task 5.3: Performance Optimization
**Estimated Time**: 3 days

**Subtasks**:
- [ ] Optimize database queries
- [ ] Implement pagination for lists
- [ ] Optimize image loading
- [ ] Reduce app size
- [ ] Improve startup time
- [ ] Profile and fix performance bottlenecks

---

### Task 5.4: Documentation
**Estimated Time**: 2 days

**Subtasks**:
- [ ] Update README with new features
- [ ] Document all screens
- [ ] Document all components
- [ ] Create user guide
- [ ] Create developer guide

---

## Summary

### Total Estimated Time: **90 days (18 weeks)**

### Task Count by Phase:
- **Phase 1**: 7 tasks (Core UI & Auth) - 22 days
- **Phase 2**: 6 tasks (Enhanced Patient) - 18 days
- **Phase 3**: 6 tasks (Doctor Features) - 24 days
- **Phase 4**: 4 tasks (Family & Advanced) - 12 days
- **Phase 5**: 4 tasks (Polish & Testing) - 15 days

### Priority Breakdown:
- **HIGH Priority**: 30 tasks (Phases 1, 2, 5)
- **MEDIUM Priority**: 6 tasks (Phase 3)
- **LOW Priority**: 4 tasks (Phase 4)

---

## Dependencies

### New Packages Required:
```yaml
dependencies:
  # Camera & QR
  camera: ^0.10.5
  qr_code_scanner: ^1.0.1
  qr_flutter: ^4.1.0
  
  # Image handling
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  
  # Charts (for analysis)
  fl_chart: ^0.66.2
  
  # Existing packages (already added)
  provider: ^6.1.1
  sqflite: ^2.3.0
  flutter_local_notifications: ^16.3.0
  http: ^1.1.2
  connectivity_plus: ^5.0.2
```

---

## Next Steps

1. **Review and approve this plan**
2. **Set up project tracking** (Jira, Trello, or GitHub Projects)
3. **Assign tasks to team members**
4. **Start with Phase 1** (Core UI & Auth)
5. **Weekly progress reviews**
6. **Adjust timeline as needed**

---

**Status**: ✅ Plan Complete - Ready for Implementation  
**Last Updated**: February 8, 2026
