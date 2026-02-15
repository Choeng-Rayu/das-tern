# Design Document: Manual Prescription and Medication Creation

## Overview

The Manual Prescription and Medication Creation feature provides a form-based interface for patients to create and manage prescription and medication records in the Das Tern platform. The system consists of a Flutter mobile application (frontend) and a NestJS backend API with PostgreSQL database storage.

The design leverages the existing Prisma schema models (Prescription, Medication) and extends the prescriptions module to support patient-initiated prescription creation. The architecture follows a clean separation between presentation (Flutter UI), business logic (NestJS services), and data persistence (Prisma ORM + PostgreSQL).

Key design principles:
- **Offline-first**: All operations work offline with automatic sync when online
- **Bilingual support**: Full Khmer and English language support throughout
- **Theme flexibility**: Light and dark mode support
- **Data integrity**: Strong validation and referential integrity
- **Security**: Authentication, authorization, and encrypted data transmission

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Presentation Layer                        │ │
│  │  - Prescription Form Screen                            │ │
│  │  - Medication Form Screen                              │ │
│  │  - Prescription List Screen                            │ │
│  │  - Medication Detail Screen                            │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Business Logic Layer                      │ │
│  │  - Prescription Provider (State Management)            │ │
│  │  - Medication Provider (State Management)              │ │
│  │  - Validation Service                                  │ │
│  │  - Sync Service                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Data Layer                                │ │
│  │  - Local Database (SQLite/Hive)                        │ │
│  │  - API Client                                          │ │
│  │  - Offline Queue                                       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS/TLS 1.3
                            │
┌─────────────────────────────────────────────────────────────┐
│                     NestJS Backend API                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              API Layer                                 │ │
│  │  - Prescriptions Controller                            │ │
│  │  - Medications Controller                              │ │
│  │  - Auth Guards & Middleware                            │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Service Layer                             │ │
│  │  - Prescriptions Service                               │ │
│  │  - Medications Service                                 │ │
│  │  - Validation Service                                  │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Data Access Layer                         │ │
│  │  - Prisma Service                                      │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
                            │
┌─────────────────────────────────────────────────────────────┐
│                  PostgreSQL Database                         │
│  - prescriptions table                                       │
│  - medications table                                         │
│  - users table                                               │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**Prescription Creation Flow:**
1. User fills Prescription Form in Mobile App
2. Mobile App validates input locally
3. Mobile App stores prescription in Local Database
4. If online: Mobile App sends POST request to Backend API
5. Backend API validates and authenticates request
6. Backend API stores prescription in PostgreSQL via Prisma
7. Backend API returns created prescription with ID
8. Mobile App updates local record with server ID

**Offline Sync Flow:**
1. Sync Service detects network connectivity
2. Sync Service retrieves pending operations from Offline Queue
3. For each operation: Send request to Backend API
4. On success: Remove from queue and update local database
5. On failure: Retry with exponential backoff

## Components and Interfaces

### Mobile App Components

#### 1. Prescription Form Screen
**Purpose**: UI for creating/editing prescriptions

**State:**
- `prescriberName: string`
- `prescriptionDate: DateTime`
- `notes: string`
- `isLoading: boolean`
- `errors: Map<string, string>`

**Methods:**
- `validateForm(): boolean` - Validates all form fields
- `submitPrescription(): Future<Prescription>` - Creates prescription
- `loadPrescription(id: string): Future<void>` - Loads existing prescription for editing

#### 2. Medication Form Screen
**Purpose**: UI for creating/editing medications

**State:**
- `prescriptionId: string`
- `medicationName: string`
- `dosage: string`
- `frequency: string`
- `timing: string`
- `duration: string`
- `notes: string`
- `isLoading: boolean`
- `errors: Map<string, string>`

**Methods:**
- `validateForm(): boolean` - Validates all form fields
- `submitMedication(): Future<Medication>` - Creates medication
- `loadMedication(id: string): Future<void>` - Loads existing medication for editing

#### 3. Prescription Provider
**Purpose**: State management for prescriptions

**State:**
- `prescriptions: List<Prescription>`
- `currentPrescription: Prescription?`
- `isLoading: boolean`
- `error: string?`

**Methods:**
- `createPrescription(data: PrescriptionInput): Future<Prescription>`
- `updatePrescription(id: string, data: PrescriptionInput): Future<Prescription>`
- `deletePrescription(id: string): Future<void>`
- `getPrescriptions(page: int, limit: int): Future<List<Prescription>>`
- `getPrescriptionById(id: string): Future<Prescription>`

#### 4. Medication Provider
**Purpose**: State management for medications

**State:**
- `medications: List<Medication>`
- `currentMedication: Medication?`
- `isLoading: boolean`
- `error: string?`

**Methods:**
- `createMedication(data: MedicationInput): Future<Medication>`
- `updateMedication(id: string, data: MedicationInput): Future<Medication>`
- `deleteMedication(id: string): Future<void>`
- `getMedicationsByPrescription(prescriptionId: string): Future<List<Medication>>`

#### 5. Validation Service
**Purpose**: Client-side validation logic

**Methods:**
- `validatePrescriberName(name: string): ValidationResult`
- `validatePrescriptionDate(date: DateTime): ValidationResult`
- `validateMedicationName(name: string): ValidationResult`
- `validateDosage(dosage: string): ValidationResult`
- `validateFrequency(frequency: string): ValidationResult`

#### 6. Sync Service
**Purpose**: Manages offline/online synchronization

**State:**
- `pendingOperations: Queue<SyncOperation>`
- `isOnline: boolean`
- `isSyncing: boolean`

**Methods:**
- `queueOperation(operation: SyncOperation): void`
- `syncAll(): Future<SyncResult>`
- `syncOperation(operation: SyncOperation): Future<void>`
- `handleConnectivityChange(isOnline: boolean): void`

### Backend API Components

#### 1. Prescriptions Controller
**Purpose**: HTTP endpoints for prescription operations

**Endpoints:**
- `POST /prescriptions` - Create prescription
- `GET /prescriptions` - List prescriptions (paginated)
- `GET /prescriptions/:id` - Get prescription by ID
- `PATCH /prescriptions/:id` - Update prescription
- `DELETE /prescriptions/:id` - Delete prescription

**Guards:**
- `JwtAuthGuard` - Validates JWT token
- `RolesGuard` - Ensures user is a patient

#### 2. Medications Controller
**Purpose**: HTTP endpoints for medication operations

**Endpoints:**
- `POST /medications` - Create medication
- `GET /medications` - List medications by prescription
- `GET /medications/:id` - Get medication by ID
- `PATCH /medications/:id` - Update medication
- `DELETE /medications/:id` - Delete medication

**Guards:**
- `JwtAuthGuard` - Validates JWT token
- `RolesGuard` - Ensures user is a patient

#### 3. Prescriptions Service
**Purpose**: Business logic for prescription operations

**Methods:**
- `create(userId: string, data: CreatePrescriptionDto): Promise<Prescription>`
- `findAll(userId: string, page: number, limit: number): Promise<PaginatedResult<Prescription>>`
- `findOne(userId: string, id: string): Promise<Prescription>`
- `update(userId: string, id: string, data: UpdatePrescriptionDto): Promise<Prescription>`
- `remove(userId: string, id: string): Promise<void>`
- `validateOwnership(userId: string, prescriptionId: string): Promise<boolean>`

#### 4. Medications Service
**Purpose**: Business logic for medication operations

**Methods:**
- `create(userId: string, data: CreateMedicationDto): Promise<Medication>`
- `findByPrescription(userId: string, prescriptionId: string): Promise<Medication[]>`
- `findOne(userId: string, id: string): Promise<Medication>`
- `update(userId: string, id: string, data: UpdateMedicationDto): Promise<Medication>`
- `remove(userId: string, id: string): Promise<void>`
- `validatePrescriptionOwnership(userId: string, prescriptionId: string): Promise<boolean>`

## Data Models

### Prescription Model (Existing - Adapted)

```typescript
interface Prescription {
  id: string;                    // UUID
  patientId: string;             // UUID - references User
  doctorId: string | null;       // UUID - references User (null for patient-created)
  
  // Patient Info (snapshot at creation)
  patientName: string;           // Max 200 chars
  patientGender: Gender;         // Enum: MALE, FEMALE, OTHER
  patientAge: number;            // Integer
  symptoms: string;              // Text
  
  // Prescription Details
  status: PrescriptionStatus;    // Enum: DRAFT, ACTIVE, COMPLETED, CANCELLED
  currentVersion: number;        // Integer, default 1
  isUrgent: boolean;             // Default false
  urgentReason: string | null;   // Text
  
  // Timestamps
  createdAt: Date;               // Timestamptz
  updatedAt: Date;               // Timestamptz
  
  // Relations
  patient: User;
  doctor: User | null;
  medications: Medication[];
  doseEvents: DoseEvent[];
  versions: PrescriptionVersion[];
}
```

**Adaptations for Patient-Created Prescriptions:**
- `doctorId` will be `null` for patient-created prescriptions
- `symptoms` field will be repurposed to store "notes" from patient
- `status` will default to `ACTIVE` for patient-created prescriptions
- `patientName`, `patientGender`, `patientAge` will be populated from authenticated user

### Medication Model (Existing - Adapted)

```typescript
interface Medication {
  id: string;                    // UUID
  prescriptionId: string;        // UUID - references Prescription
  rowNumber: number;             // Integer - order within prescription
  
  // Medication Details
  medicineName: string;          // Max 255 chars
  medicineNameKhmer: string | null; // Max 255 chars
  imageUrl: string | null;       // Text (reserved for future use)
  
  // Dosage Information (JSONB for flexibility)
  morningDosage: Json | null;    // JSONB
  daytimeDosage: Json | null;    // JSONB
  nightDosage: Json | null;      // JSONB
  
  // Additional Info
  frequency: string | null;      // Max 100 chars
  timing: string | null;         // Max 100 chars
  
  // Timestamps
  createdAt: Date;               // Timestamptz
  updatedAt: Date;               // Timestamptz
  
  // Relations
  prescription: Prescription;
  doseEvents: DoseEvent[];
}
```

**Adaptations for Manual Entry:**
- `medicineName` stores the medication name in entered language
- `medicineNameKhmer` stores Khmer translation if entered in English (optional)
- `frequency` stores free-form frequency text (e.g., "3 times daily", "២ដងក្នុងមួយថ្ងៃ")
- `timing` stores timing instructions (e.g., "after meals", "before bed")
- `morningDosage`, `daytimeDosage`, `nightDosage` can store structured dosage info as JSON

### DTOs (Data Transfer Objects)

#### CreatePrescriptionDto
```typescript
interface CreatePrescriptionDto {
  prescriberName: string;        // Required, max 200 chars
  prescriptionDate: Date;        // Required, not in future
  notes: string;                 // Optional, max 1000 chars
}
```

#### UpdatePrescriptionDto
```typescript
interface UpdatePrescriptionDto {
  prescriberName?: string;       // Optional, max 200 chars
  prescriptionDate?: Date;       // Optional, not in future
  notes?: string;                // Optional, max 1000 chars
}
```

#### CreateMedicationDto
```typescript
interface CreateMedicationDto {
  prescriptionId: string;        // Required, valid UUID
  medicationName: string;        // Required, max 255 chars
  medicationNameKhmer?: string;  // Optional, max 255 chars
  dosage: string;                // Required, max 100 chars
  frequency: string;             // Required, max 100 chars
  timing?: string;               // Optional, max 100 chars
  duration?: string;             // Optional, max 100 chars
  notes?: string;                // Optional, max 500 chars
}
```

#### UpdateMedicationDto
```typescript
interface UpdateMedicationDto {
  medicationName?: string;       // Optional, max 255 chars
  medicationNameKhmer?: string;  // Optional, max 255 chars
  dosage?: string;               // Optional, max 100 chars
  frequency?: string;            // Optional, max 100 chars
  timing?: string;               // Optional, max 100 chars
  duration?: string;             // Optional, max 100 chars
  notes?: string;                // Optional, max 500 chars
}
```

### Local Storage Models (Mobile App)

#### LocalPrescription
```dart
class LocalPrescription {
  String? id;                    // Null if not synced
  String? serverId;              // Server-assigned ID after sync
  String prescriberName;
  DateTime prescriptionDate;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;
  
  Map<String, dynamic> toJson();
  factory LocalPrescription.fromJson(Map<String, dynamic> json);
}
```

#### LocalMedication
```dart
class LocalMedication {
  String? id;                    // Null if not synced
  String? serverId;              // Server-assigned ID after sync
  String prescriptionId;         // Local prescription ID
  String medicationName;
  String? medicationNameKhmer;
  String dosage;
  String frequency;
  String? timing;
  String? duration;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;
  
  Map<String, dynamic> toJson();
  factory LocalMedication.fromJson(Map<String, dynamic> json);
}
```

#### SyncOperation
```dart
enum SyncOperationType { CREATE, UPDATE, DELETE }

class SyncOperation {
  String id;                     // Unique operation ID
  SyncOperationType type;
  String entityType;             // "prescription" or "medication"
  String entityId;               // Local entity ID
  Map<String, dynamic> data;     // Entity data
  int retryCount;
  DateTime createdAt;
  DateTime? lastAttempt;
  
  Map<String, dynamic> toJson();
  factory SyncOperation.fromJson(Map<String, dynamic> json);
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Future Date Rejection
*For any* date that is in the future, the prescription date validation SHALL reject it with an appropriate error message.
**Validates: Requirements 1.4**

### Property 2: Prescription Creation Success
*For any* valid prescription input (non-empty prescriber name, valid date, optional notes), submitting the form SHALL create a prescription record with a unique ID.
**Validates: Requirements 1.5**

### Property 3: Bilingual Input Acceptance
*For any* text field in medication or prescription forms, the system SHALL accept and store both Khmer Unicode characters (U+1780 to U+17FF) and English ASCII characters without modification or rejection.
**Validates: Requirements 2.2, 3.2**

### Property 4: Auto-Complete Matching
*For any* search string and database of previous entries (prescribers or medications), the auto-complete SHALL return all entries that contain the search string as a substring (case-insensitive for English, exact match for Khmer).
**Validates: Requirements 1.2, 2.3, 3.3**

### Property 5: Dosage Format Acceptance
*For any* string containing alphanumeric characters and common units (mg, tablets, teaspoon, ml, etc.), the dosage field SHALL accept the input without rejection.
**Validates: Requirements 2.4**

### Property 6: Frequency Input Flexibility
*For any* frequency input (predefined option or custom text), the system SHALL accept and store the value without modification.
**Validates: Requirements 2.5**

### Property 7: Language Round-Trip Integrity
*For any* medication or prescription data entered in either Khmer or English, storing and then retrieving the data SHALL return the exact same text without translation or modification.
**Validates: Requirements 3.4, 3.5**

### Property 8: Required Field Validation
*For any* medication form submission where required fields (medication name, dosage, frequency) are empty, the validation SHALL fail and prevent submission.
**Validates: Requirements 4.1, 4.3, 4.4**

### Property 9: Localized Error Messages
*For any* validation error and selected language (Khmer or English), the error message SHALL be displayed in the selected language.
**Validates: Requirements 4.2**

### Property 10: Valid Medication Creation
*For any* valid medication input (all required fields filled, linked to existing prescription), submission SHALL create a medication record linked to the correct prescription via foreign key.
**Validates: Requirements 4.5**

### Property 11: Multiple Medication Association
*For any* sequence of medications created for the same prescription, all medications SHALL have the same prescriptionId value.
**Validates: Requirements 5.3**

### Property 12: Medication Summary Completeness
*For any* prescription with N medications, the summary view SHALL display exactly N medications with no duplicates or omissions.
**Validates: Requirements 5.4**

### Property 13: Summary Edit and Delete Operations
*For any* medication in the summary view, edit and delete operations SHALL successfully modify or remove that specific medication without affecting other medications in the prescription.
**Validates: Requirements 5.5**

### Property 14: Offline Creation Capability
*For any* valid prescription or medication input, the creation operation SHALL succeed regardless of network connectivity status.
**Validates: Requirements 6.1**

### Property 15: Offline Local Storage
*For any* prescription or medication created while offline, the data SHALL be stored in Local_Cache with isSynced flag set to false.
**Validates: Requirements 6.2**

### Property 16: Online Sync Trigger
*For any* cached data with isSynced=false, transitioning from offline to online SHALL trigger automatic synchronization to the Backend_API.
**Validates: Requirements 6.3, 12.5, 13.5**

### Property 17: Local-First Conflict Resolution
*For any* sync conflict between local and server data, the system SHALL prefer the local version and overwrite server data.
**Validates: Requirements 6.4**

### Property 18: Exponential Backoff Retry
*For any* failed sync operation, the system SHALL retry with exponentially increasing delays (e.g., 1s, 2s, 4s, 8s, 16s) up to a maximum retry count.
**Validates: Requirements 6.5**

### Property 19: Unique Prescription Identifiers
*For any* prescription created via the Backend_API, the system SHALL assign a unique UUID that is different from all existing prescription IDs.
**Validates: Requirements 7.1**

### Property 20: Medication Foreign Key Integrity
*For any* medication creation request with a prescriptionId, the Backend_API SHALL verify the prescription exists before creating the medication, or reject with a referential integrity error.
**Validates: Requirements 7.2, 7.3**

### Property 21: Prescription with Medications Retrieval
*For any* prescription ID, fetching the prescription SHALL return the prescription data along with all associated medications in a single response.
**Validates: Requirements 7.4**

### Property 22: Pagination Correctness
*For any* page number N and page size S, the pagination SHALL return exactly S prescriptions (or fewer if on the last page) starting from offset N*S, ordered by creation date descending.
**Validates: Requirements 7.5**

### Property 23: Authentication Enforcement
*For any* API request to create, read, update, or delete prescriptions or medications without a valid JWT token, the Backend_API SHALL reject the request with 401 Unauthorized.
**Validates: Requirements 8.3**

### Property 24: Authorization Enforcement
*For any* API request to access a prescription or medication, the Backend_API SHALL verify the requesting user's ID matches the prescription's patientId, or reject with 403 Forbidden.
**Validates: Requirements 8.4**

### Property 25: Audit Logging
*For any* successful prescription or medication operation (create, read, update, delete), the Backend_API SHALL create an audit log entry with timestamp, user ID, operation type, and entity ID.
**Validates: Requirements 8.5**

### Property 26: Preference Persistence
*For any* user preference change (language or theme), the Mobile_App SHALL store the preference locally and restore it on next app launch.
**Validates: Requirements 9.1, 9.4, 10.1, 10.4**

### Property 27: UI Language Reactivity
*For any* language change (Khmer to English or vice versa), all UI text, labels, error messages, and form fields SHALL immediately update to the selected language without requiring app restart.
**Validates: Requirements 9.3, 9.5**

### Property 28: UI Theme Reactivity
*For any* theme change (Light, Dark, or System Default), all UI components SHALL immediately update colors and contrast ratios to match the selected theme.
**Validates: Requirements 10.3**

### Property 29: System Theme Synchronization
*For any* system theme change when "System Default" is selected, the Mobile_App SHALL automatically switch to match the system theme within 1 second.
**Validates: Requirements 10.5**

### Property 30: Prescription List Ordering
*For any* list of prescriptions, they SHALL be ordered by createdAt timestamp in descending order (most recent first).
**Validates: Requirements 11.1**

### Property 31: Prescription List Item Content
*For any* prescription displayed in the list, the item SHALL include prescriberName, prescriptionDate, and the count of associated medications.
**Validates: Requirements 11.2**

### Property 32: Prescription Detail Navigation
*For any* prescription selected from the list, the detail view SHALL display the prescription data and all associated medications.
**Validates: Requirements 11.3**

### Property 33: Medication Display Content
*For any* medication displayed, the view SHALL include medicationName, dosage, frequency, and timing (if present).
**Validates: Requirements 11.4**

### Property 34: Search Result Accuracy
*For any* search query string, the search results SHALL include all prescriptions or medications where any text field contains the query as a substring (case-insensitive).
**Validates: Requirements 11.5**

### Property 35: Edit Form Pre-Population
*For any* prescription or medication edit operation, the form SHALL be pre-populated with all existing field values from the database.
**Validates: Requirements 12.1, 12.2**

### Property 36: Edit Validation Consistency
*For any* field validation rule, the rule SHALL be applied identically during both creation and editing operations.
**Validates: Requirements 12.3**

### Property 37: Update Persistence
*For any* valid edit submission, the changes SHALL be persisted to the database and retrievable in subsequent queries.
**Validates: Requirements 12.4**

### Property 38: Cascade Deletion
*For any* prescription deletion, all medications with matching prescriptionId SHALL also be deleted from the database.
**Validates: Requirements 13.2**

### Property 39: Selective Medication Deletion
*For any* medication deletion, only that specific medication SHALL be removed, and the associated prescription and other medications SHALL remain unchanged.
**Validates: Requirements 13.4**

## Error Handling

### Client-Side Error Handling (Mobile App)

**Validation Errors:**
- Display inline error messages below invalid fields
- Use red color for error text (light theme) or light red (dark theme)
- Prevent form submission until all errors are resolved
- Show localized error messages based on selected language

**Network Errors:**
- Detect network connectivity using connectivity_plus package
- Show toast notification when offline: "You are offline. Changes will sync when online."
- Queue operations in offline queue with visual indicator
- Show sync status in UI (syncing, synced, pending)

**API Errors:**
- Handle 401 Unauthorized: Redirect to login screen
- Handle 403 Forbidden: Show "Access denied" message
- Handle 404 Not Found: Show "Resource not found" message
- Handle 500 Server Error: Show "Server error. Please try again later."
- Handle timeout: Retry with exponential backoff

**Data Errors:**
- Handle corrupt local data: Clear cache and re-sync from server
- Handle sync conflicts: Prefer local changes (last-write-wins)
- Handle missing foreign keys: Show "Prescription not found" error

### Server-Side Error Handling (Backend API)

**Validation Errors:**
- Return 400 Bad Request with detailed error messages
- Use class-validator decorators for DTO validation
- Return structured error response: `{ statusCode, message, errors: [] }`

**Authentication Errors:**
- Return 401 Unauthorized for missing or invalid JWT
- Return 403 Forbidden for insufficient permissions
- Log authentication failures for security monitoring

**Database Errors:**
- Handle unique constraint violations: Return 409 Conflict
- Handle foreign key violations: Return 400 Bad Request with "Invalid prescription ID"
- Handle connection errors: Return 503 Service Unavailable
- Wrap database operations in try-catch blocks
- Log all database errors for debugging

**Business Logic Errors:**
- Validate prescription ownership before operations
- Validate medication belongs to user's prescription
- Return 404 Not Found for non-existent resources
- Return 400 Bad Request for invalid operations

## Testing Strategy

### Dual Testing Approach

The testing strategy employs both unit tests and property-based tests to ensure comprehensive coverage:

**Unit Tests:**
- Specific examples demonstrating correct behavior
- Edge cases (empty strings, boundary values, special characters)
- Error conditions (invalid inputs, missing data, unauthorized access)
- Integration points between components
- UI component rendering and interaction

**Property-Based Tests:**
- Universal properties that hold for all inputs
- Comprehensive input coverage through randomization
- Validation logic across all possible inputs
- Data integrity and consistency properties
- Round-trip properties (serialize/deserialize, create/retrieve)

### Property-Based Testing Configuration

**Library Selection:**
- **Flutter/Dart**: Use `test` package with custom property test helpers or `faker` for data generation
- **NestJS/TypeScript**: Use `fast-check` library for property-based testing

**Test Configuration:**
- Minimum 100 iterations per property test (due to randomization)
- Each property test references its design document property
- Tag format: `Feature: ocr-prescription-scanning, Property {number}: {property_text}`

**Example Property Test Structure (TypeScript with fast-check):**
```typescript
import * as fc from 'fast-check';

describe('Feature: ocr-prescription-scanning', () => {
  it('Property 1: Future Date Rejection', () => {
    fc.assert(
      fc.property(
        fc.date({ min: new Date(Date.now() + 86400000) }), // Future dates
        (futureDate) => {
          const result = validatePrescriptionDate(futureDate);
          expect(result.isValid).toBe(false);
          expect(result.error).toContain('future');
        }
      ),
      { numRuns: 100 }
    );
  });
});
```

### Test Coverage Requirements

**Mobile App (Flutter):**
- Widget tests for all form screens
- Unit tests for validation logic
- Property tests for data integrity
- Integration tests for offline sync
- Minimum 80% code coverage

**Backend API (NestJS):**
- Unit tests for all service methods
- Property tests for validation and business logic
- Integration tests for API endpoints
- E2E tests for complete workflows
- Minimum 85% code coverage

### Testing Priorities

1. **Critical Path**: Prescription and medication creation (online and offline)
2. **Data Integrity**: Foreign key relationships, cascade deletion
3. **Security**: Authentication, authorization, data isolation
4. **Sync Logic**: Offline queue, conflict resolution, retry mechanism
5. **Validation**: Required fields, date validation, input acceptance
6. **Localization**: Language switching, bilingual input
7. **UI/UX**: Theme switching, form pre-population, error display
