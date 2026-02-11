# Design Document: Family Connection + Missed Dose Alert

## Overview

This design extends the existing Das Tern medication management platform to support family member connections with QR code-based onboarding, automatic missed dose detection with grace periods, caregiver alerts, and nudge functionality. The system builds upon the existing Connection model and notification infrastructure while adding new components for token generation, scheduled jobs for missed dose detection, and enhanced UI flows for family caregivers.

**Key Design Principles:**
- Reuse existing Connection model and infrastructure
- Extend, don't replace, current doctor-patient connection system
- Offline-first with sync capabilities
- Privacy-first with granular permission controls
- Bilingual support (Khmer/English) throughout

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App (Flutter)                     │
├──────────────────────┬──────────────────────────────────────┤
│  Patient Screens     │  Caregiver Screens                   │
│  - Token Generation  │  - QR Scanner                        │
│  - Family Access List│  - Patient Dashboard View            │
│  - Connection History│  - Nudge Interface                   │
└──────────────────────┴──────────────────────────────────────┘
                              │
                              │ HTTPS/REST API
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Backend API (NestJS + TypeScript)               │
├──────────────────────┬──────────────────────────────────────┤
│  New Modules         │  Extended Modules                    │
│  - Token Service     │  - Connections (enhanced)            │
│  - Missed Dose Job   │  - Notifications (enhanced)          │
│  - Nudge Service     │  - Doses (grace period logic)        │
└──────────────────────┴──────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                PostgreSQL Database (Prisma)                  │
├──────────────────────┬──────────────────────────────────────┤
│  New Tables          │  Extended Tables                     │
│  - connection_tokens │  - connections (metadata JSON)       │
│                      │  - users (grace_period_minutes)      │
│                      │  - notifications (new types)         │
└──────────────────────┴──────────────────────────────────────┘
```

### Data Flow: Family Connection Setup

```
Patient                    Backend                    Caregiver
   │                          │                           │
   │ 1. Generate Token        │                           │
   ├─────────────────────────>│                           │
   │                          │ Create token in DB        │
   │<─────────────────────────┤                           │
   │ Display QR + Code        │                           │
   │                          │                           │
   │                          │    2. Scan QR/Enter Code  │
   │                          │<──────────────────────────┤
   │                          │ Validate token            │
   │                          │ Create pending connection │
   │                          ├──────────────────────────>│
   │                          │    Show preview           │
   │                          │                           │
   │ 3. Receive notification  │                           │
   │<─────────────────────────┤                           │
   │ Approve/Deny             │                           │
   ├─────────────────────────>│                           │
   │                          │ Update connection status  │
   │                          ├──────────────────────────>│
   │                          │    Confirmation           │
```

### Data Flow: Missed Dose Alert

```
Scheduled Job          Backend              Patient          Caregiver
      │                   │                    │                 │
      │ Check doses       │                    │                 │
      ├──────────────────>│                    │                 │
      │                   │ Find DUE doses     │                 │
      │                   │ past grace period  │                 │
      │                   │                    │                 │
      │                   │ Mark as MISSED     │                 │
      │                   ├───────────────────>│                 │
      │                   │ Send notification  │                 │
      │                   │                    │                 │
      │                   │ Query caregivers   │                 │
      │                   │ with alerts ON     │                 │
      │                   ├────────────────────┼────────────────>│
      │                   │                    │  Alert sent     │
      │                   │                    │                 │
      │                   │                    │  Nudge patient  │
      │                   │<────────────────────────────────────┤
      │                   ├───────────────────>│                 │
      │                   │ Nudge notification │                 │
```

## Components and Interfaces

### Backend Components

#### 1. Connection Token Service

**Purpose:** Generate, validate, and manage time-limited connection tokens for QR code-based onboarding.

**Interface:**
```typescript
interface ConnectionTokenService {
  generateToken(patientId: string, permissionLevel: PermissionLevel): Promise<ConnectionToken>;
  validateToken(token: string): Promise<TokenValidationResult>;
  consumeToken(token: string, caregiverId: string): Promise<Connection>;
  cleanupExpiredTokens(): Promise<number>;
}

interface ConnectionToken {
  id: string;
  patientId: string;
  token: string;  // 8-12 character alphanumeric
  permissionLevel: PermissionLevel;
  expiresAt: Date;
  usedAt: Date | null;
  usedBy: string | null;
  createdAt: Date;
}

interface TokenValidationResult {
  valid: boolean;
  patientId?: string;
  patientName?: string;
  permissionLevel?: PermissionLevel;
  error?: string;
}
```

**Implementation Details:**
- Token generation: Use `crypto.randomBytes(6).toString('base64url')` for 8-character codes
- Store tokens in new `connection_tokens` table
- Implement automatic cleanup job (runs daily, deletes tokens older than 48 hours)
- Validate: check expiration, check not already used, check patient exists

#### 2. Missed Dose Detection Job

**Purpose:** Scheduled job that runs every 5 minutes to detect doses past their grace period and mark them as missed.

**Interface:**
```typescript
interface MissedDoseJob {
  execute(): Promise<void>;
  findDosesPastGracePeriod(): Promise<DoseEvent[]>;
  markAsMissed(doseId: string): Promise<void>;
  triggerCaregiverAlerts(doseId: string): Promise<void>;
}
```

**Implementation Details:**
- Use NestJS `@Cron` decorator: `@Cron('*/5 * * * *')` (every 5 minutes)
- Query: `status = 'DUE' AND scheduledTime + grace_period_minutes < NOW()`
- For each dose found:
  1. Update status to 'MISSED'
  2. Create AuditLog entry
  3. Send notification to patient
  4. Query caregivers with alerts enabled
  5. Send MISSED_DOSE_ALERT to each caregiver

#### 3. Nudge Service

**Purpose:** Handle caregiver nudges to patients about missed doses with rate limiting.

**Interface:**
```typescript
interface NudgeService {
  sendNudge(caregiverId: string, patientId: string, doseId: string): Promise<NudgeResult>;
  checkRateLimit(caregiverId: string, doseId: string): Promise<boolean>;
  recordNudge(caregiverId: string, doseId: string): Promise<void>;
}

interface NudgeResult {
  success: boolean;
  message: string;
  rateLimitExceeded?: boolean;
}
```

**Implementation Details:**
- Store nudge count in Connection metadata JSON: `{ nudges: { [doseId]: count } }`
- Rate limit: max 2 nudges per dose per caregiver
- Create FAMILY_ALERT notification for patient
- Create AuditLog entry with actionType NOTIFICATION_SENT

#### 4. Enhanced Connections Service

**Purpose:** Extend existing ConnectionsService with family-specific features.

**New Methods:**
```typescript
interface ConnectionsService {
  // Existing methods...
  
  // New methods:
  getCaregiverLimit(patientId: string): Promise<{ current: number; limit: number }>;
  toggleAlerts(connectionId: string, enabled: boolean): Promise<void>;
  getConnectionHistory(userId: string, filters: HistoryFilters): Promise<AuditLog[]>;
  validateCaregiverLimit(patientId: string): Promise<boolean>;
}
```

**Implementation Details:**
- Query Subscription table to get tier and calculate limit
- Store alert toggle in Connection metadata: `{ alertsEnabled: boolean }`
- Filter AuditLog by relevant actionTypes for history

### Mobile App Components

#### 1. Family Connect Flow Screens

**FamilyConnectIntroScreen**
- Hero illustration
- Benefits list
- "Generate Code" button → AccessLevelSelectionScreen
- "View Existing Connections" button → FamilyAccessListScreen

**AccessLevelSelectionScreen**
- Three radio options: View Only (REQUEST), View + Remind (SELECTED), View + Manage (ALLOWED)
- Description for each option
- "Continue" button → TokenDisplayScreen

**TokenDisplayScreen**
- Large QR code (using `qr_flutter` package)
- Alphanumeric code with copy button
- Countdown timer showing expiration
- "Share" button (native share sheet)
- "Done" button to dismiss

#### 2. Caregiver Onboarding Screens

**CaregiverOnboardingScreen**
- Four tiles: Scan QR, Enter Code, Search by Phone (disabled), Ask Later
- Scan QR → QRScannerScreen
- Enter Code → CodeEntryScreen

**QRScannerScreen**
- Camera view with overlay (using `mobile_scanner` package)
- Framing guide
- On scan success → ConnectionPreviewModal

**CodeEntryScreen**
- Text input field (8-12 characters)
- "Validate" button
- On success → ConnectionPreviewModal

**ConnectionPreviewModal**
- Patient name
- Requested access level
- "Send Request" button
- "Cancel" button

#### 3. Family Access List Screen

**FamilyAccessListScreen**
- Header: "X / Y family members"
- List of connection cards:
  - Caregiver name
  - Access level badge
  - Status indicator (Active/Pending)
  - Alert toggle switch
  - Overflow menu (Change Permission, Remove)
- "Add Family Member" FAB → FamilyConnectIntroScreen

**CaregiverDetailScreen**
- Caregiver info
- Current permissions
- Alert history (from AuditLog)
- Connection date
- "Change Permission" button
- "Remove Connection" button

#### 4. Caregiver Dashboard

**CaregiverDashboardScreen**
- Patient selector dropdown (if multiple patients)
- Patient name header
- Today's medications list
- Adherence percentage
- Missed doses section with "Nudge" buttons
- Deep link handling for notifications

#### 5. Connection History Screen

**ConnectionHistoryScreen**
- Filter chips: All, Requests, Approvals, Changes, Removals
- Date range selector
- List of audit log entries:
  - Timestamp
  - Caregiver name
  - Action type
  - Access level
- Infinite scroll pagination

### Data Models

#### New Table: connection_tokens

```sql
CREATE TABLE connection_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(12) NOT NULL UNIQUE,
  permission_level permission_level NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  used_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  INDEX idx_token (token),
  INDEX idx_patient_id (patient_id),
  INDEX idx_expires_at (expires_at)
);
```

#### Extended Table: users

```sql
ALTER TABLE users ADD COLUMN grace_period_minutes INTEGER DEFAULT 30;
```

#### Extended Table: connections

Add metadata JSON field usage:
```json
{
  "alertsEnabled": true,
  "nudges": {
    "dose-id-1": 2,
    "dose-id-2": 1
  },
  "lastAlertSent": "2025-01-20T10:30:00Z"
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Token Generation Uniqueness and Expiration
*For any* patient ID and permission level, generating a connection token should produce a unique 8-12 character alphanumeric code that expires exactly 24 hours from creation time.
**Validates: Requirements 1.1, 1.5**

### Property 2: Token Structure Completeness
*For any* generated connection token, the database record should contain all required fields: id, patientId, token, permissionLevel, expiresAt, usedAt (null initially), createdAt.
**Validates: Requirements 1.2, 1.7**

### Property 3: Token Single-Use Enforcement
*For any* connection token, after it is successfully used once to create a connection, any subsequent validation attempt should fail with an "already used" error.
**Validates: Requirements 1.3, 1.6, 19.2**

### Property 4: Token Expiration Enforcement
*For any* connection token, validation attempts after the expiresAt timestamp should fail with an "expired" error, regardless of whether it was previously used.
**Validates: Requirements 1.6, 19.1**

### Property 5: QR Code Generation Validity
*For any* connection token string, generating a QR code and then scanning it should decode back to the original token string.
**Validates: Requirements 1.4, 6.3**

### Property 6: Navigation Consistency
*For any* family connection entry point (dashboard chip, settings menu, medications FAB, first-time banner), tapping it should navigate to the same FamilyConnectIntroScreen route.
**Validates: Requirements 2.5**

### Property 7: Connection State Transition - Approval
*For any* connection in PENDING status, when approved by the patient, the status should change to ACCEPTED and the acceptedAt timestamp should be set to the current time.
**Validates: Requirements 7.6**

### Property 8: Connection State Transition - Denial
*For any* connection in PENDING status, when denied by the patient, the status should change to REVOKED.
**Validates: Requirements 7.7**

### Property 9: Connection Request Notification
*For any* valid connection token used by a caregiver, a Notification record with type CONNECTION_REQUEST should be created for the patient.
**Validates: Requirements 7.2**

### Property 10: Grace Period Missed Dose Detection
*For any* DoseEvent with status DUE where scheduledTime + grace_period_minutes < current time, the scheduled job should update the status to MISSED.
**Validates: Requirements 10.3**

### Property 11: Comprehensive Audit Logging
*For any* significant event (dose marked MISSED, notification sent, nudge sent, patient response), an AuditLog entry with the appropriate actionType should be created.
**Validates: Requirements 10.4, 12.7, 13.8**

### Property 12: Patient Missed Dose Notification
*For any* DoseEvent that transitions to MISSED status, a Notification with type MISSED_DOSE_ALERT should be created for the patient.
**Validates: Requirements 11.1**

### Property 13: Missed Dose Notification Format
*For any* MISSED_DOSE_ALERT notification, the message should follow the format "[Patient Name] missed the [Time] dose of [Medication Name]" and include deep link data with patientId, doseEventId, and prescriptionId.
**Validates: Requirements 11.2, 12.3, 12.4**

### Property 14: Late Dose Marking Time Window
*For any* MISSED DoseEvent, marking it as taken should succeed if within 24 hours of scheduledTime, and fail if more than 24 hours have passed.
**Validates: Requirements 11.6**

### Property 15: Caregiver Alert Broadcasting
*For any* DoseEvent that transitions to MISSED status, a MISSED_DOSE_ALERT notification should be created for each ACCEPTED connection where the patient is connected, the connection role is FAMILY_MEMBER, and alertsEnabled is true in the connection metadata.
**Validates: Requirements 12.1, 12.2, 12.6, 14.4**

### Property 16: Alert Respect for Disabled Preferences
*For any* connection where alertsEnabled is false in metadata, no MISSED_DOSE_ALERT notifications should be created for that caregiver when doses are missed.
**Validates: Requirements 12.6**

### Property 17: Nudge Notification Creation
*For any* nudge request from a caregiver, a Notification with type FAMILY_ALERT should be created for the patient with the message "Your family is checking on you. Did you take your medicine?"
**Validates: Requirements 13.2, 13.3**

### Property 18: Bidirectional Nudge Response
*For any* patient response to a FAMILY_ALERT notification, a corresponding Notification should be created for the caregiver with the response details and timestamp.
**Validates: Requirements 13.5**

### Property 19: Nudge Rate Limiting
*For any* DoseEvent and caregiver pair, after sending 2 nudges, the 3rd nudge attempt should fail with a rate limit error.
**Validates: Requirements 13.7**

### Property 20: Subscription Tier Caregiver Limits
*For any* patient with subscription tier FREEMIUM, attempting to create a 2nd family connection should fail; for PREMIUM, the 6th should fail; for FAMILY_PREMIUM, the 11th should fail.
**Validates: Requirements 14.1**

### Property 21: Connection History Filtering
*For any* audit log query with actionType filter set to [CONNECTION_REQUEST, CONNECTION_ACCEPT, CONNECTION_REVOKE, PERMISSION_CHANGE, DATA_ACCESS], all returned entries should have actionType matching one of the filter values.
**Validates: Requirements 15.2, 15.4**

### Property 22: Offline Request Queueing
*For any* connection request or approval/denial action performed while offline, the operation should be stored in local SQLite database and automatically synced to the backend when network connectivity is restored.
**Validates: Requirements 17.1, 17.2, 17.3**

### Property 23: Offline Sync Retry Logic
*For any* queued offline operation, if sync fails 3 consecutive times, a notification should be displayed to the user with a manual retry option.
**Validates: Requirements 17.5**

### Property 24: Self-Connection Prevention
*For any* connection token validation where the caregiver ID equals the patient ID, the validation should fail with error "You cannot connect to your own account".
**Validates: Requirements 19.4**

### Property 25: Notification Preference Enforcement
*For any* notification type where the user has disabled that preference, no Notification records of that type should be created for that user.
**Validates: Requirements 20.3, 20.5**

### Property 26: Notification Preference Persistence
*For any* notification preference change, the preference should be persisted locally and synced to the backend, and subsequent app launches should reflect the saved preference.
**Validates: Requirements 20.4**

## Error Handling

### Backend Error Handling

**Token Service Errors:**
- `TOKEN_EXPIRED`: Return 400 with message "This code has expired. Please ask the patient for a new code."
- `TOKEN_ALREADY_USED`: Return 400 with message "This code has already been used. Please request a new code."
- `TOKEN_INVALID`: Return 400 with message "Invalid code. Please check and try again."
- `PATIENT_NOT_FOUND`: Return 404 with message "Patient account not found."

**Connection Errors:**
- `SELF_CONNECTION`: Return 400 with message "You cannot connect to your own account."
- `LIMIT_REACHED`: Return 403 with message "Family connection limit reached for your subscription tier."
- `DUPLICATE_CONNECTION`: Return 409 with message "Connection already exists with this user."
- `CONNECTION_NOT_FOUND`: Return 404 with message "Connection not found."
- `UNAUTHORIZED_ACTION`: Return 403 with message "You don't have permission to perform this action."

**Nudge Errors:**
- `RATE_LIMIT_EXCEEDED`: Return 429 with message "Maximum nudges reached for this dose. Please wait before sending another."
- `DOSE_NOT_MISSED`: Return 400 with message "Can only nudge for missed doses."
- `NO_PERMISSION`: Return 403 with message "You don't have permission to nudge this patient."

### Mobile App Error Handling

**Network Errors:**
- Display toast: "Connection failed. Please check your internet and try again."
- Provide retry button
- Queue operation for offline sync if applicable

**Validation Errors:**
- Display inline error messages below input fields
- Highlight invalid fields in red
- Provide specific guidance (e.g., "Code must be 8-12 characters")

**Permission Errors:**
- Display dialog explaining the issue
- Provide "Contact Support" button
- Log error for debugging

**Camera Errors:**
- Request permission if not granted
- Display message: "Camera access is required to scan QR codes"
- Provide "Open Settings" button

## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests** focus on:
- Specific UI screen rendering (example-based)
- Navigation flows between screens
- Error message display
- Edge cases (expired tokens, rate limits)
- Integration between components

**Property-Based Tests** focus on:
- Token generation and validation across all inputs
- State transitions for connections and doses
- Notification creation rules
- Audit logging completeness
- Subscription limit enforcement
- Offline sync behavior

### Property Test Configuration

- **Library**: Use `fast-check` for TypeScript backend, `test` package with custom generators for Flutter
- **Iterations**: Minimum 100 iterations per property test
- **Tagging**: Each property test must reference its design document property

Example tag format:
```typescript
// Feature: family-connection-missed-dose-alert, Property 1: Token Generation Uniqueness and Expiration
test('token generation produces unique tokens with 24h expiration', async () => {
  await fc.assert(
    fc.asyncProperty(
      fc.uuid(), // patientId
      fc.constantFrom('REQUEST', 'SELECTED', 'ALLOWED'), // permissionLevel
      async (patientId, permissionLevel) => {
        const token1 = await tokenService.generateToken(patientId, permissionLevel);
        const token2 = await tokenService.generateToken(patientId, permissionLevel);
        
        expect(token1.token).not.toBe(token2.token);
        expect(token1.token).toMatch(/^[A-Za-z0-9]{8,12}$/);
        
        const expiresIn = token1.expiresAt.getTime() - token1.createdAt.getTime();
        expect(expiresIn).toBeCloseTo(24 * 60 * 60 * 1000, -2); // 24 hours ±100ms
      }
    ),
    { numRuns: 100 }
  );
});
```

### Unit Test Examples

**Token Display Screen:**
```typescript
describe('TokenDisplayScreen', () => {
  it('should display QR code and alphanumeric code', () => {
    const token = 'ABC123XYZ';
    render(<TokenDisplayScreen token={token} />);
    
    expect(screen.getByTestId('qr-code')).toBeInTheDocument();
    expect(screen.getByText(token)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /copy/i })).toBeInTheDocument();
  });
  
  it('should show "Generate new code" when token is expired', () => {
    const expiredToken = { token: 'ABC123', expiresAt: new Date('2020-01-01') };
    render(<TokenDisplayScreen token={expiredToken} />);
    
    expect(screen.queryByTestId('qr-code')).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: /generate new code/i })).toBeInTheDocument();
  });
});
```

**Missed Dose Job:**
```typescript
describe('MissedDoseJob', () => {
  it('should mark doses as missed after grace period', async () => {
    const patient = await createTestPatient({ gracePeriodMinutes: 30 });
    const dose = await createTestDose({
      patientId: patient.id,
      status: 'DUE',
      scheduledTime: new Date(Date.now() - 35 * 60 * 1000) // 35 minutes ago
    });
    
    await missedDoseJob.execute();
    
    const updatedDose = await prisma.doseEvent.findUnique({ where: { id: dose.id } });
    expect(updatedDose.status).toBe('MISSED');
  });
  
  it('should not mark doses within grace period', async () => {
    const patient = await createTestPatient({ gracePeriodMinutes: 30 });
    const dose = await createTestDose({
      patientId: patient.id,
      status: 'DUE',
      scheduledTime: new Date(Date.now() - 25 * 60 * 1000) // 25 minutes ago
    });
    
    await missedDoseJob.execute();
    
    const updatedDose = await prisma.doseEvent.findUnique({ where: { id: dose.id } });
    expect(updatedDose.status).toBe('DUE');
  });
});
```

## Implementation Notes

### Technology Choices

**Backend:**
- NestJS `@nestjs/schedule` for cron jobs
- `crypto` module for token generation
- Prisma for database operations
- Existing notification infrastructure

**Mobile:**
- `qr_flutter` (^4.1.0) for QR code generation
- `mobile_scanner` (^3.5.0) for QR code scanning
- `sqflite` (existing) for offline storage
- `connectivity_plus` (existing) for network status
- Existing i18n infrastructure for localization

### Database Migrations

**Migration 1: Add connection_tokens table**
```sql
CREATE TABLE connection_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(12) NOT NULL UNIQUE,
  permission_level permission_level NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  used_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_connection_tokens_token ON connection_tokens(token);
CREATE INDEX idx_connection_tokens_patient_id ON connection_tokens(patient_id);
CREATE INDEX idx_connection_tokens_expires_at ON connection_tokens(expires_at);
```

**Migration 2: Add grace_period_minutes to users**
```sql
ALTER TABLE users ADD COLUMN grace_period_minutes INTEGER DEFAULT 30;
```

**Migration 3: Add metadata to connections (if not exists)**
```sql
-- Check if metadata column exists, if not add it
ALTER TABLE connections ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
```

### API Endpoints

**New Endpoints:**

```
POST   /api/connections/tokens              - Generate connection token
GET    /api/connections/tokens/:token       - Validate token
POST   /api/connections/tokens/:token/use   - Consume token and create connection
DELETE /api/connections/tokens/:token       - Invalidate token

GET    /api/connections/:id/history         - Get connection history
PATCH  /api/connections/:id/alerts          - Toggle alerts for connection

POST   /api/nudges                          - Send nudge to patient
GET    /api/nudges/:doseId/count            - Get nudge count for dose

GET    /api/users/me/caregiver-limit        - Get current and max caregiver count
```

**Extended Endpoints:**
- `GET /api/connections` - Add query param `?role=FAMILY_MEMBER` to filter
- `GET /api/audit-logs` - Add query params for filtering by actionType

### Scheduled Jobs

**Missed Dose Detection Job:**
```typescript
@Injectable()
export class MissedDoseJob {
  @Cron('*/5 * * * *') // Every 5 minutes
  async handleMissedDoses() {
    const now = new Date();
    
    // Find all DUE doses past grace period
    const missedDoses = await this.prisma.doseEvent.findMany({
      where: {
        status: 'DUE',
        scheduledTime: {
          lt: this.prisma.$queryRaw`NOW() - INTERVAL '1 minute' * users.grace_period_minutes`
        }
      },
      include: { patient: true, medication: true }
    });
    
    for (const dose of missedDoses) {
      await this.markAsMissed(dose);
      await this.notifyPatient(dose);
      await this.notifyCaregivers(dose);
    }
  }
}
```

**Token Cleanup Job:**
```typescript
@Injectable()
export class TokenCleanupJob {
  @Cron('0 2 * * *') // Daily at 2 AM
  async cleanupExpiredTokens() {
    const result = await this.prisma.connectionToken.deleteMany({
      where: {
        expiresAt: { lt: new Date(Date.now() - 48 * 60 * 60 * 1000) } // Older than 48 hours
      }
    });
    
    this.logger.log(`Cleaned up ${result.count} expired tokens`);
  }
}
```

### Security Considerations

1. **Token Security:**
   - Tokens are single-use and time-limited
   - Use cryptographically secure random generation
   - Store tokens hashed in database (optional enhancement)
   - Rate limit token generation (max 5 per patient per hour)

2. **Connection Authorization:**
   - Verify patient owns the token before allowing connection
   - Verify caregiver has FAMILY_MEMBER role
   - Enforce subscription limits before creating connections
   - Validate permission levels against allowed values

3. **Nudge Authorization:**
   - Verify caregiver has active ACCEPTED connection
   - Verify dose belongs to connected patient
   - Enforce rate limits per caregiver per dose
   - Log all nudge attempts for audit

4. **Data Access:**
   - Caregivers can only access data for connected patients
   - Respect permission levels (VIEW_ONLY, SELECTED, ALLOWED)
   - Filter sensitive data based on permission level
   - Log all data access in audit trail

### Performance Considerations

1. **Missed Dose Job:**
   - Index on (status, scheduledTime) for efficient queries
   - Batch process doses in chunks of 100
   - Use database-level date arithmetic for grace period calculation
   - Consider using message queue for notification sending

2. **Caregiver Alerts:**
   - Batch notification creation for multiple caregivers
   - Use database transactions to ensure consistency
   - Consider async notification delivery
   - Cache connection metadata to avoid repeated queries

3. **Connection History:**
   - Implement pagination (20 entries per page)
   - Index on (actorId, createdAt, actionType) for efficient filtering
   - Consider caching recent history entries
   - Implement infinite scroll on mobile

4. **QR Code Generation:**
   - Generate QR codes on-demand (don't store)
   - Cache QR code images in memory for current session
   - Use appropriate error correction level (M or Q)
   - Optimize QR code size for mobile displays

## Deployment Considerations

### Backend Deployment

1. **Database Migrations:**
   - Run migrations in order: tokens table → users column → connections metadata
   - Verify indexes are created
   - Test rollback procedures

2. **Scheduled Jobs:**
   - Ensure cron jobs are enabled in production
   - Monitor job execution logs
   - Set up alerts for job failures
   - Consider using distributed job scheduler for multiple instances

3. **Feature Flags:**
   - Use feature flag for family connections (gradual rollout)
   - Separate flags for: token generation, missed dose alerts, nudges
   - Monitor error rates and performance metrics

### Mobile App Deployment

1. **Phased Rollout:**
   - Phase 1: Token generation and connection flow (20% users)
   - Phase 2: Missed dose alerts (50% users)
   - Phase 3: Nudge functionality (100% users)

2. **Backward Compatibility:**
   - Ensure app works with older backend versions
   - Handle missing API endpoints gracefully
   - Provide fallback UI for unsupported features

3. **Offline Support:**
   - Test offline queueing thoroughly
   - Verify sync behavior on network restore
   - Handle conflicts (e.g., connection approved offline then denied online)

4. **Localization:**
   - Verify all new strings are translated to Khmer
   - Test UI layout with both languages
   - Ensure notification messages are localized

## Future Enhancements

1. **Advanced Nudge Features:**
   - Custom nudge messages
   - Scheduled nudges (e.g., "Remind me in 1 hour")
   - Voice call nudges for critical medications

2. **Enhanced Analytics:**
   - Caregiver dashboard with adherence trends
   - Predictive alerts for likely missed doses
   - Medication adherence reports for doctors

3. **Group Connections:**
   - Family groups with shared access
   - Group chat for medication discussions
   - Coordinated care plans

4. **Smart Notifications:**
   - ML-based optimal notification timing
   - Adaptive grace periods based on patient behavior
   - Context-aware notifications (location, activity)

5. **Integration:**
   - Calendar integration for medication schedules
   - Health app integration (Apple Health, Google Fit)
   - Pharmacy integration for refill reminders
