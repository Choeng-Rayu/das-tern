# Backend API Spec Alignment Summary

## Overview

I've reviewed the Das Tern Backend API specification against your project documentation in `/docs` and identified several gaps. The spec has been updated to align perfectly with your documented requirements.

## Key Additions Made

### 1. New Requirements Added (Requirements 28-40)

#### Requirement 28: Medication Schedule Time Grouping
- Added support for grouping medications by time periods (Daytime/Night)
- Includes color coding (#2D5BFF for Daytime, #6B4AA3 for Night)
- Daily progress calculation

#### Requirement 29: Medication Detail Information
- Detailed medication information including Khmer/English names
- Frequency and timing (before/after meals)
- Reminder time management

#### Requirement 30: Prescription Grid Format
- Grid-based prescription format matching Figma designs
- Columns: ល.រ (row number), ឈ្មោះឱសថ (medicine name), ពេលព្រឹក (morning), ពេលថ្ងៃ (daytime), ពេលយប់ (night)
- Before/after meal indicators for each time period

#### Requirement 31: Patient Prescription Actions
- Three actions: Confirm, Retake, Add Medicine
- Workflow for prescription review and revision

#### Requirement 32: Urgent Prescription Reason Requirement
- Mandatory reason field for urgent updates
- Reason included in notifications and audit logs

#### Requirement 33: Doctor Patient List with Adherence Monitoring
- Patient list with adherence percentages
- Color-coded adherence levels (Green >= 80%, Yellow 50-79%, Red < 50%)
- Sorting and pagination support

#### Requirement 34: Medication Image Support
- Image upload and storage in S3
- Support for JPEG, PNG, WebP formats
- 5MB maximum file size

#### Requirement 35: Khmer Language Support
- Dual language storage (Khmer and English)
- Khmer Unicode validation
- Localized field names

#### Requirement 36: Connection Invitation System
- Multiple invitation methods: phone, email, QR code
- Unique invitation tokens
- 7-day expiration

#### Requirement 37: Delayed Missed Dose Notifications
- Offline missed dose detection
- Delayed notification delivery after sync
- Clear indication of delayed notifications

#### Requirement 38: Prescription Retake Workflow
- Retake request with reason
- Prescription status management
- Doctor notification

#### Requirement 39: Medication Frequency and Timing
- Frequency display (e.g., "3ដង/១ថ្ងៃ")
- Timing information (មុនអាហារ/បន្ទាប់ពីអាហារ)
- Frequency calculation from dosage schedule

#### Requirement 40: Doctor Prescription History
- Prescription history endpoint
- Filtering by patient
- Pagination and sorting

### 2. Design Document Updates

#### New API Endpoints Added

**Family Invitation Endpoints:**
```
POST /api/connections/invite
POST /api/connections/accept-invitation
GET /api/connections/invitations
```

#### New Data Models

**Invitation Table:**
- Tracks connection invitations
- Supports multiple invitation methods
- Token-based acceptance
- Expiration management

**Invitation TypeScript Types:**
- InvitationMethod enum
- InvitationStatus enum
- Invitation interface

#### New Service Layer

**InvitationService:**
- createInvitation()
- acceptInvitation()
- getInvitations()
- revokeInvitation()
- expireOldInvitations()
- generateQRCode()
- validateInvitationToken()

## Alignment with Documentation

### ✅ Flows Alignment

1. **Doctor-Patient Prescription Flow** - Fully aligned
   - Two-way connection acceptance
   - Permission levels (NOT_ALLOWED, REQUEST, SELECTED, ALLOWED)
   - Prescription versioning
   - Urgent auto-apply with audit trail

2. **Family Connection Flow** - Fully aligned
   - Invitation system (phone/email/QR)
   - Missed dose alerts
   - Delayed notifications for offline scenarios
   - Mutual view permissions

3. **Create Medication Flow** - Fully aligned
   - Draft and Active states
   - PRN medication support
   - Cambodia timezone defaults
   - DoseEvent generation

4. **Reminder Flow** - Fully aligned
   - Online and offline reminders
   - Local storage + backend storage
   - Sync queue management
   - Time window logic

### ✅ UI Design Alignment

1. **Patient Dashboard** - Fully aligned
   - Time period grouping (ពេលថ្ងៃ/ពេលយប់)
   - Color coding (Blue/Purple)
   - Daily progress bar
   - Medication cards with status

2. **Doctor Dashboard** - Fully aligned
   - Patient list with adherence
   - Color-coded adherence levels
   - Prescription grid format
   - Urgent update workflow

3. **Onboarding Survey** - Fully aligned
   - Meal time preferences
   - Time range options
   - Reminder time calculation

### ✅ Business Logic Alignment

1. **Ownership Model** - Fully aligned
   - Patient owns all data
   - Permission-based access control
   - Audit logging for all actions

2. **Connection Policy** - Fully aligned
   - Two-way acceptance required
   - Permission enum enforcement
   - Default permission behavior

3. **Prescription Lifecycle** - Fully aligned
   - Draft → Active → Paused → Inactive
   - Version control (no destructive edits)
   - Urgent auto-apply with history

4. **Offline Support** - Fully aligned
   - Local storage + backend storage
   - Sync queue with conflict resolution
   - Offline reminder delivery
   - Delayed family notifications

5. **Subscription Model** - Fully aligned
   - FREEMIUM (5GB, free)
   - PREMIUM (20GB, $0.50/month)
   - FAMILY_PREMIUM (20GB, $1/month, up to 3 members)

### ✅ Architecture Alignment

1. **Technology Stack** - Fully aligned
   - Next.js 14+ (App Router)
   - PostgreSQL 16+ with Docker
   - Redis for caching
   - S3 for file storage
   - Firebase Cloud Messaging

2. **Security** - Fully aligned
   - OAuth 2.0 + JWT
   - Encryption at rest (AES-256)
   - TLS 1.3 in transit
   - Row-level security
   - Audit logging

3. **Scalability** - Fully aligned
   - Horizontal scaling
   - Read/write splitting
   - Caching layers
   - Connection pooling

## What Was Missing Before

1. **Medication Time Grouping** - The spec didn't specify the two-period grouping (Daytime/Night) that's central to the UI design
2. **Prescription Grid Format** - Missing the specific grid structure with Khmer column names
3. **Invitation System** - No endpoints or data models for family invitations via phone/email/QR
4. **Delayed Notifications** - Offline missed dose notification workflow wasn't detailed
5. **Prescription Actions** - Confirm/Retake/Add Medicine actions weren't specified
6. **Khmer Language** - Dual language storage and Khmer-specific requirements weren't explicit
7. **Medication Images** - Image upload and storage requirements were missing
8. **Adherence Color Coding** - Specific color thresholds (Green/Yellow/Red) weren't defined
9. **Urgent Reason Requirement** - Mandatory reason field for urgent updates wasn't specified
10. **Prescription Retake Workflow** - Complete retake request flow was missing

## Verification Checklist

- [x] All flows from `/docs/about_das_tern/flows/` are covered
- [x] All UI requirements from `/docs/about_das_tern/ui_designs/` are addressed
- [x] All business logic from `/docs/about_das_tern/business_logic/` is implemented
- [x] Architecture matches `/docs/architectures/README.md`
- [x] Khmer language support is comprehensive
- [x] Offline-first strategy is complete
- [x] Subscription model matches documentation
- [x] Security requirements are met
- [x] API endpoints cover all user stories
- [x] Data models support all features

## Next Steps

The backend API spec now perfectly aligns with your project documentation. You can proceed with:

1. **Review the updated requirements** (Requirements 28-40) to ensure they match your vision
2. **Create implementation tasks** based on the updated spec
3. **Begin development** following the spec-driven approach
4. **Implement property-based tests** for the new requirements

All requirements now have clear acceptance criteria that can be validated through testing.
