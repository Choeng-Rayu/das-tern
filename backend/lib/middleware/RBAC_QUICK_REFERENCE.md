# RBAC Middleware - Quick Reference

## Permission Levels

```
NOT_ALLOWED (0) < REQUEST (1) < SELECTED (2) < ALLOWED (3)
```

- **NOT_ALLOWED**: No access to patient data
- **REQUEST**: Can request explicit approval for each access
- **SELECTED**: Can access only selected prescriptions/data
- **ALLOWED**: Full access to patient data (default)

## Basic Usage

### Auto-Check PatientId

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      // Permission already checked
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

### Manual Permission Check

```typescript
export const GET = withAuth(
  withRBAC(async (req, { user, checkPermission }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')
    
    if (!await checkPermission(patientId, 'ALLOWED')) {
      return Response.json({ error: 'Access denied' }, { status: 403 })
    }
    
    return Response.json({ data: 'Patient data' })
  })
)
```

### Get Permission Level

```typescript
export const GET = withAuth(
  withRBAC(async (req, { user, getPermissionLevel }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')
    const level = await getPermissionLevel(user.id, patientId)
    
    return Response.json({ permissionLevel: level })
  })
)
```

### Prescription Access

```typescript
import { canAccessPrescription } from '@/lib/middleware/rbac'

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

### Family Member Access

```typescript
import { canFamilyMemberAccess } from '@/lib/middleware/rbac'

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

### Role-Based Access

```typescript
export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      return Response.json({ data: 'Doctor-only data' })
    },
    {
      requiredRole: 'DOCTOR',
    }
  )
)
```

### Multiple Roles

```typescript
export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      return Response.json({ data: 'Doctor or Patient data' })
    },
    {
      requiredRole: ['DOCTOR', 'PATIENT'],
    }
  )
)
```

### Validation Helpers

```typescript
import { validateConnection, validatePermission } from '@/lib/middleware/rbac'

export const POST = withAuth(
  withRBAC(async (req, { user }) => {
    const { patientId } = await req.json()
    
    try {
      // Throws if connection doesn't exist
      await validateConnection(user.id, patientId, user.language)
      
      // Throws if permission is insufficient
      await validatePermission(user.id, patientId, 'ALLOWED', user.language)
      
      return Response.json({ success: true })
    } catch (error) {
      return Response.json({ error: error.message }, { status: 403 })
    }
  })
)
```

## Common Patterns

### Read vs Write Permissions

```typescript
// Read: Requires SELECTED
export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      // Read data
    },
    {
      autoCheckPatientId: true,
      requiredPermission: 'SELECTED',
    }
  )
)

// Write: Requires ALLOWED
export const POST = withAuth(
  withRBAC(
    async (req, { user }) => {
      // Write data
    },
    {
      autoCheckPatientId: true,
      requiredPermission: 'ALLOWED',
    }
  )
)
```

### Different Responses by Permission Level

```typescript
export const GET = withAuth(
  withRBAC(async (req, { user, getPermissionLevel }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')
    const level = await getPermissionLevel(user.id, patientId)
    
    switch (level) {
      case 'ALLOWED':
        return Response.json({ data: 'Full data' })
      case 'SELECTED':
        return Response.json({ data: 'Selected data only' })
      case 'REQUEST':
        return Response.json({ data: 'Limited data, can request more' })
      case 'NOT_ALLOWED':
      default:
        return Response.json({ error: 'Access denied' }, { status: 403 })
    }
  })
)
```

## Error Responses

### 403 Forbidden

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

## Key Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `withRBAC(handler, options?)` | Main middleware | Wrapped handler |
| `checkPermission(actorId, targetUserId, level?)` | Check permission | `Promise<boolean>` |
| `getPermissionLevel(doctorId, patientId)` | Get permission level | `Promise<PermissionLevel \| null>` |
| `canAccessPrescription(doctorId, prescriptionId, level?)` | Check prescription access | `Promise<boolean>` |
| `canFamilyMemberAccess(familyId, patientId)` | Check family access | `Promise<boolean>` |
| `validateConnection(userId1, userId2, lang?)` | Validate connection | `Promise<void>` (throws on error) |
| `validatePermission(doctorId, patientId, level?, lang?)` | Validate permission | `Promise<void>` (throws on error) |

## Options

### withRBAC Options

```typescript
{
  requiredRole?: 'PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER' | Array<...>
  autoCheckPatientId?: boolean
  requiredPermission?: PermissionLevel
}
```

## Important Notes

1. **Self-Access**: Users always have full access to their own data
2. **Bidirectional**: Connections are checked in both directions
3. **Connection Status**: Only ACCEPTED connections grant access
4. **Prescription Authors**: Doctors who created prescriptions always have access
5. **Family Members**: Use simple connection-based access (no permission levels)
6. **Default Permission**: New connections default to ALLOWED

## Examples

See `backend/app/api/example/rbac/` for complete working examples.

## Documentation

- Full documentation: `backend/lib/middleware/RBAC_README.md`
- Completion summary: `backend/lib/middleware/TASK_3.2_COMPLETION_SUMMARY.md`
- Test suite: `backend/lib/middleware/rbac.test.ts` (33 tests)
