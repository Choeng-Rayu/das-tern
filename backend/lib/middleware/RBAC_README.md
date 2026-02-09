# RBAC Middleware Documentation

## Overview

The RBAC (Role-Based Access Control) middleware extends the basic JWT authentication to include **permission-level checking** for doctor-patient connections. This implements **Requirement 3** (Doctor-Patient Connection Management) and **Requirement 16** (Data Privacy and Access Control) from the Das Tern Backend API specification.

## Permission Levels

The system supports four permission levels for doctor-patient connections:

| Level | Value | Description |
|-------|-------|-------------|
| **NOT_ALLOWED** | 0 | Doctor has no access to patient data |
| **REQUEST** | 1 | Doctor must request explicit approval for each access |
| **SELECTED** | 2 | Doctor can only access explicitly selected prescriptions/data |
| **ALLOWED** | 3 | Doctor has full access to patient data (default) |

### Permission Hierarchy

The permission levels form a hierarchy where higher levels include all permissions of lower levels:

```
NOT_ALLOWED (0) < REQUEST (1) < SELECTED (2) < ALLOWED (3)
```

For example:
- If a doctor has `ALLOWED` permission, they can perform actions requiring `REQUEST` or `SELECTED`
- If a doctor has `REQUEST` permission, they cannot perform actions requiring `SELECTED` or `ALLOWED`

## Core Functions

### `withRBAC(handler, options?)`

Main middleware function that wraps route handlers with RBAC capabilities.

**Parameters:**
- `handler`: Route handler function with RBAC context
- `options`: Optional configuration
  - `requiredRole`: Role(s) required to access the endpoint
  - `autoCheckPatientId`: Automatically check permission for `patientId` query parameter
  - `requiredPermission`: Permission level required for auto-check (default: `ALLOWED`)

**Returns:** Wrapped handler with RBAC enforcement

**Example:**
```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

export const GET = withAuth(
  withRBAC(async (req, { user, checkPermission }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')
    
    // Check if user has permission to access patient data
    const hasPermission = await checkPermission(patientId, 'ALLOWED')
    
    if (!hasPermission) {
      return Response.json({ error: 'Access denied' }, { status: 403 })
    }
    
    // Proceed with data access
    const data = await getPatientData(patientId)
    return Response.json({ data })
  })
)
```

### `checkPermission(actorId, targetUserId, requiredLevel?)`

Check if a user has permission to access another user's data.

**Parameters:**
- `actorId`: User attempting to access data
- `targetUserId`: User whose data is being accessed
- `requiredLevel`: Minimum permission level required (default: `ALLOWED`)

**Returns:** `Promise<boolean>` - True if permission is granted

**Example:**
```typescript
const hasAccess = await checkPermission('doctor-123', 'patient-456', 'SELECTED')
```

### `getPermissionLevel(doctorId, patientId)`

Get the permission level for a doctor accessing patient data.

**Parameters:**
- `doctorId`: Doctor's user ID
- `patientId`: Patient's user ID

**Returns:** `Promise<PermissionLevel | null>` - Permission level or null if no connection

**Example:**
```typescript
const level = await getPermissionLevel('doctor-123', 'patient-456')
// Returns: 'ALLOWED' | 'SELECTED' | 'REQUEST' | 'NOT_ALLOWED' | null
```

### `canAccessPrescription(doctorId, prescriptionId, requiredLevel?)`

Check if a doctor can access a specific prescription.

**Parameters:**
- `doctorId`: Doctor's user ID
- `prescriptionId`: Prescription ID
- `requiredLevel`: Minimum permission level required (default: `ALLOWED`)

**Returns:** `Promise<boolean>` - True if doctor can access the prescription

**Example:**
```typescript
const canAccess = await canAccessPrescription('doctor-123', 'prescription-789')
```

### `canFamilyMemberAccess(familyMemberId, patientId)`

Check if a family member can access patient data.

**Parameters:**
- `familyMemberId`: Family member's user ID
- `patientId`: Patient's user ID

**Returns:** `Promise<boolean>` - True if family member has access

**Example:**
```typescript
const hasAccess = await canFamilyMemberAccess('family-123', 'patient-456')
```

### `validateConnection(userId1, userId2, language?)`

Validate that a connection exists and is accepted. Throws an error if validation fails.

**Parameters:**
- `userId1`: First user ID
- `userId2`: Second user ID
- `language`: Language for error messages (default: 'english')

**Throws:** Error if connection doesn't exist or isn't accepted

**Example:**
```typescript
try {
  await validateConnection('doctor-123', 'patient-456')
  // Connection is valid
} catch (error) {
  // No connection exists
}
```

### `validatePermission(doctorId, patientId, requiredLevel?, language?)`

Validate that a doctor has the required permission level. Throws an error if validation fails.

**Parameters:**
- `doctorId`: Doctor's user ID
- `patientId`: Patient's user ID
- `requiredLevel`: Minimum permission level required (default: `ALLOWED`)
- `language`: Language for error messages (default: 'english')

**Throws:** Error if permission is insufficient

**Example:**
```typescript
try {
  await validatePermission('doctor-123', 'patient-456', 'ALLOWED')
  // Permission is sufficient
} catch (error) {
  // Insufficient permission
}
```

## Usage Patterns

### Pattern 1: Basic Permission Check

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

export const GET = withAuth(
  withRBAC(async (req, { user, checkPermission }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')
    
    if (!await checkPermission(patientId, 'ALLOWED')) {
      return Response.json({ error: 'Access denied' }, { status: 403 })
    }
    
    // Access granted
    return Response.json({ data: 'Patient data' })
  })
)
```

### Pattern 2: Auto-Check PatientId

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      // Permission already checked by middleware
      const patientId = req.nextUrl.searchParams.get('patientId')
      return Response.json({ data: 'Patient data' })
    },
    {
      autoCheckPatientId: true,
      requiredPermission: 'ALLOWED',
    }
  )
)
```

### Pattern 3: Role + Permission Check

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

export const GET = withAuth(
  withRBAC(
    async (req, { user, checkPermission }) => {
      const patientId = req.nextUrl.searchParams.get('patientId')
      
      if (!await checkPermission(patientId, 'SELECTED')) {
        return Response.json({ error: 'Access denied' }, { status: 403 })
      }
      
      return Response.json({ data: 'Selected prescriptions' })
    },
    {
      requiredRole: 'DOCTOR', // Only doctors can access
    }
  )
)
```

### Pattern 4: Prescription Access Check

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC, canAccessPrescription } from '@/lib/middleware/rbac'

export const GET = withAuth(
  withRBAC(async (req, { user }) => {
    const prescriptionId = req.nextUrl.searchParams.get('prescriptionId')
    
    if (!await canAccessPrescription(user.id, prescriptionId, 'SELECTED')) {
      return Response.json({ error: 'Access denied' }, { status: 403 })
    }
    
    return Response.json({ data: 'Prescription data' })
  })
)
```

### Pattern 5: Family Member Access

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC, canFamilyMemberAccess } from '@/lib/middleware/rbac'

export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      const patientId = req.nextUrl.searchParams.get('patientId')
      
      if (!await canFamilyMemberAccess(user.id, patientId)) {
        return Response.json({ error: 'Access denied' }, { status: 403 })
      }
      
      return Response.json({ data: 'Patient data' })
    },
    {
      requiredRole: 'FAMILY_MEMBER',
    }
  )
)
```

### Pattern 6: Validation Helpers

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC, validatePermission } from '@/lib/middleware/rbac'

export const POST = withAuth(
  withRBAC(async (req, { user }) => {
    const { patientId } = await req.json()
    
    try {
      // Throws error if permission is insufficient
      await validatePermission(user.id, patientId, 'ALLOWED', user.language)
      
      // Permission validated, proceed
      return Response.json({ success: true })
    } catch (error) {
      return Response.json(
        { error: error.message },
        { status: 403 }
      )
    }
  })
)
```

## Error Responses

The middleware returns standardized error responses with bilingual messages:

### 403 Forbidden - Insufficient Permission

```json
{
  "error": {
    "message": "Access denied. You do not have permission to access this patient's data.",
    "messageEn": "Access denied. You do not have permission to access this patient's data.",
    "messageKm": "ការចូលប្រើត្រូវបានបដិសេធ។ អ្នកមិនមានការអនុញ្ញាតក្នុងការចូលប្រើទិន្នន័យរបស់អ្នកជំងឺនេះទេ។",
    "code": "FORBIDDEN"
  }
}
```

### Permission-Specific Error Messages

**NOT_ALLOWED:**
```
"The patient has not allowed you to access their data."
"អ្នកជំងឺមិនបានអនុញ្ញាតឱ្យអ្នកចូលប្រើទិន្នន័យរបស់ពួកគេទេ។"
```

**REQUEST:**
```
"You must request explicit approval from the patient to access this data."
"អ្នកត្រូវស្នើសុំការអនុម័តច្បាស់លាស់ពីអ្នកជំងឺដើម្បីចូលប្រើទិន្នន័យនេះ។"
```

**SELECTED:**
```
"You can only access selected prescriptions or data explicitly shared by the patient."
"អ្នកអាចចូលប្រើតែវេជ្ជបញ្ជាដែលបានជ្រើសរើស ឬទិន្នន័យដែលបានចែករំលែកច្បាស់លាស់ដោយអ្នកជំងឺប៉ុណ្ណោះ។"
```

**No Connection:**
```
"No connection exists with this patient."
"មិនមានការតភ្ជាប់ជាមួយអ្នកជំងឺនេះទេ។"
```

## Integration with Auth Middleware

The RBAC middleware is designed to work seamlessly with the JWT authentication middleware:

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

// Combine both middlewares
export const GET = withAuth(
  withRBAC(async (req, { user, checkPermission }) => {
    // Both authentication and RBAC are enforced
    return Response.json({ user })
  })
)
```

**Execution Flow:**
1. `withAuth` validates JWT token and extracts user
2. `withRBAC` receives authenticated user context
3. `withRBAC` performs permission checks
4. Handler receives RBAC context with permission checking functions

## Database Schema

The RBAC middleware relies on the `Connection` model:

```prisma
model Connection {
  id              String           @id @default(uuid())
  initiatorId     String
  recipientId     String
  status          ConnectionStatus @default(PENDING)
  permissionLevel PermissionLevel  @default(ALLOWED)
  
  requestedAt     DateTime         @default(now())
  acceptedAt      DateTime?
  revokedAt       DateTime?
  
  @@unique([initiatorId, recipientId])
}

enum ConnectionStatus {
  PENDING
  ACCEPTED
  REVOKED
}

enum PermissionLevel {
  NOT_ALLOWED
  REQUEST
  SELECTED
  ALLOWED
}
```

## Security Considerations

1. **Bidirectional Checks**: The middleware checks connections in both directions (initiator→recipient and recipient→initiator)

2. **Self-Access**: Users always have full access to their own data, bypassing permission checks

3. **Connection Status**: Only `ACCEPTED` connections are considered valid for permission checks

4. **Default Permission**: New connections default to `ALLOWED` permission level

5. **Prescription Authors**: Doctors who created a prescription always have access to it, regardless of current permission level

6. **Family Members**: Family members use a simpler access model - they either have access (connection exists) or don't

## Performance Considerations

1. **Database Queries**: Each permission check requires a database query. Consider caching for frequently accessed connections.

2. **Auto-Check**: The `autoCheckPatientId` option adds a database query to every request. Use only when necessary.

3. **Batch Operations**: For operations involving multiple patients, consider batching permission checks.

## Testing

The middleware includes comprehensive test coverage (33 tests):

```bash
npm test -- rbac.test.ts
```

**Test Coverage:**
- ✅ Permission hierarchy validation
- ✅ Bidirectional connection checking
- ✅ Role-based access control
- ✅ Auto-check functionality
- ✅ Error message localization
- ✅ Prescription access validation
- ✅ Family member access validation
- ✅ Validation helpers

## Requirements Satisfied

### Requirement 3: Doctor-Patient Connection Management

✅ **Acceptance Criteria:**
1. Connection request creation with PENDING status
2. Connection acceptance with permission level setting
3. Permission level storage (NOT_ALLOWED, REQUEST, SELECTED, ALLOWED)
4. Permission level enforcement on data access
5. Connection revocation and immediate access blocking
6. Audit logging of connection state changes

### Requirement 16: Data Privacy and Access Control

✅ **Acceptance Criteria:**
1. Patient-only access to own data by default
2. Doctor access verification with connection and permission checks
3. REQUEST level requires explicit approval
4. SELECTED level restricts to selected prescriptions
5. NOT_ALLOWED level denies all access
6. All access attempts logged in audit trail

## Next Steps

With RBAC middleware complete, you can now:

1. **Implement Connection Endpoints** (Task 6.x)
   - Use RBAC to enforce permission levels
   - Validate connections before data access

2. **Implement Prescription Endpoints** (Task 8.x)
   - Use `canAccessPrescription` for access control
   - Enforce permission levels on prescription operations

3. **Implement Doctor Monitoring** (Task 20.x)
   - Use RBAC to filter patient lists
   - Show only patients with appropriate permissions

4. **Implement Audit Logging** (Task 22.x)
   - Log all permission checks
   - Track access attempts and denials

## Examples

See `backend/app/api/example/rbac/` for complete working examples.
