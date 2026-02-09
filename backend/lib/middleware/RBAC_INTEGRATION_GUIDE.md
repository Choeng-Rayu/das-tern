# RBAC Integration Guide

## Overview

This guide shows how to integrate the RBAC middleware with the JWT authentication middleware to create secure, permission-aware API endpoints.

## Architecture

```
Request → withAuth → withRBAC → Handler
           ↓          ↓
        JWT Auth   Permission
        Validation  Checking
```

## Integration Pattern

The RBAC middleware is designed to work as a wrapper around handlers that are already wrapped with `withAuth`:

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

export const GET = withAuth(
  withRBAC(async (req, context) => {
    // Handler code
  })
)
```

## Context Flow

### Auth Context (from withAuth)

```typescript
interface AuthContext {
  user: AuthUser
  req: NextRequest
}

interface AuthUser {
  id: string
  role: 'PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER'
  language: Language
  theme: 'LIGHT' | 'DARK'
  subscriptionTier: 'FREEMIUM' | 'PREMIUM' | 'FAMILY_PREMIUM'
}
```

### RBAC Context (extends AuthContext)

```typescript
interface RBACContext extends AuthContext {
  checkPermission: (targetUserId: string, requiredLevel?: PermissionLevel) => Promise<boolean>
  getPermissionLevel: (targetUserId: string) => Promise<PermissionLevel | null>
}
```

## Complete Examples

### Example 1: Doctor Viewing Patient Prescriptions

```typescript
// File: backend/app/api/prescriptions/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'
import { prisma } from '@/lib/prisma'

export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      // Permission already checked by autoCheckPatientId
      const patientId = req.nextUrl.searchParams.get('patientId')

      // Fetch prescriptions
      const prescriptions = await prisma.prescription.findMany({
        where: { patientId },
        include: { medications: true },
      })

      return Response.json({ prescriptions })
    },
    {
      requiredRole: ['DOCTOR', 'PATIENT'], // Both can access
      autoCheckPatientId: true, // Auto-check permission
      requiredPermission: 'SELECTED', // Requires at least SELECTED
    }
  )
)
```

### Example 2: Doctor Creating Prescription

```typescript
// File: backend/app/api/prescriptions/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'
import { prisma } from '@/lib/prisma'

export const POST = withAuth(
  withRBAC(
    async (req, { user, checkPermission }) => {
      const body = await req.json()
      const { patientId, medications, symptoms } = body

      // Check if doctor has ALLOWED permission
      if (!await checkPermission(patientId, 'ALLOWED')) {
        return Response.json(
          { error: 'You need ALLOWED permission to create prescriptions' },
          { status: 403 }
        )
      }

      // Create prescription
      const prescription = await prisma.prescription.create({
        data: {
          patientId,
          doctorId: user.id,
          symptoms,
          medications: {
            create: medications,
          },
        },
      })

      return Response.json({ prescription }, { status: 201 })
    },
    {
      requiredRole: 'DOCTOR',
    }
  )
)
```

### Example 3: Patient Managing Connections

```typescript
// File: backend/app/api/connections/[connectionId]/permission/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'
import { prisma } from '@/lib/prisma'

export const PATCH = withAuth(
  withRBAC(
    async (req, { user }, { params }) => {
      const { connectionId } = params
      const { permissionLevel } = await req.json()

      // Verify the patient owns this connection
      const connection = await prisma.connection.findUnique({
        where: { id: connectionId },
      })

      if (!connection) {
        return Response.json(
          { error: 'Connection not found' },
          { status: 404 }
        )
      }

      // Only the patient (recipient) can change permission level
      if (connection.recipientId !== user.id) {
        return Response.json(
          { error: 'Only the patient can change permission levels' },
          { status: 403 }
        )
      }

      // Update permission level
      const updated = await prisma.connection.update({
        where: { id: connectionId },
        data: { permissionLevel },
      })

      return Response.json({ connection: updated })
    },
    {
      requiredRole: 'PATIENT',
    }
  )
)
```

### Example 4: Family Member Viewing Adherence

```typescript
// File: backend/app/api/adherence/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC, canFamilyMemberAccess } from '@/lib/middleware/rbac'
import { prisma } from '@/lib/prisma'

export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      const patientId = req.nextUrl.searchParams.get('patientId')

      if (!patientId) {
        return Response.json(
          { error: 'patientId is required' },
          { status: 400 }
        )
      }

      // Check family member access
      if (!await canFamilyMemberAccess(user.id, patientId)) {
        return Response.json(
          { error: 'You do not have access to this patient' },
          { status: 403 }
        )
      }

      // Calculate adherence
      const doseEvents = await prisma.doseEvent.findMany({
        where: {
          patientId,
          scheduledTime: {
            gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
          },
        },
      })

      const total = doseEvents.length
      const taken = doseEvents.filter(
        (d) => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE'
      ).length

      const adherencePercentage = total > 0 ? (taken / total) * 100 : 0

      return Response.json({
        adherencePercentage,
        total,
        taken,
        missed: total - taken,
      })
    },
    {
      requiredRole: 'FAMILY_MEMBER',
    }
  )
)
```

### Example 5: Multi-Level Permission Response

```typescript
// File: backend/app/api/patient-data/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'
import { prisma } from '@/lib/prisma'

export const GET = withAuth(
  withRBAC(async (req, { user, getPermissionLevel, checkPermission }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')

    if (!patientId) {
      return Response.json(
        { error: 'patientId is required' },
        { status: 400 }
      )
    }

    // Get permission level
    const permissionLevel = await getPermissionLevel(user.id, patientId)

    if (!permissionLevel || permissionLevel === 'NOT_ALLOWED') {
      return Response.json(
        { error: 'Access denied' },
        { status: 403 }
      )
    }

    // Build response based on permission level
    const response: any = {
      permissionLevel,
      patient: {
        id: patientId,
      },
    }

    // REQUEST: Only basic info
    if (await checkPermission(patientId, 'REQUEST')) {
      const patient = await prisma.user.findUnique({
        where: { id: patientId },
        select: { firstName: true, lastName: true, gender: true },
      })
      response.patient.basicInfo = patient
    }

    // SELECTED: Add selected prescriptions
    if (await checkPermission(patientId, 'SELECTED')) {
      const prescriptions = await prisma.prescription.findMany({
        where: {
          patientId,
          // In real implementation, filter by selected prescriptions
        },
        select: { id: true, status: true, createdAt: true },
      })
      response.patient.selectedPrescriptions = prescriptions
    }

    // ALLOWED: Add all data
    if (await checkPermission(patientId, 'ALLOWED')) {
      const prescriptions = await prisma.prescription.findMany({
        where: { patientId },
        include: { medications: true },
      })
      const doseEvents = await prisma.doseEvent.findMany({
        where: { patientId },
        orderBy: { scheduledTime: 'desc' },
        take: 100,
      })
      response.patient.allPrescriptions = prescriptions
      response.patient.recentDoses = doseEvents
    }

    return Response.json(response)
  })
)
```

## Error Handling

### Centralized Error Handler

```typescript
// File: backend/lib/middleware/error-handler.ts
export function handleRBACError(error: any, language: Language) {
  if (error.message.includes('connection')) {
    return Response.json(
      {
        error: {
          message: language === 'khmer'
            ? 'មិនមានការតភ្ជាប់'
            : 'No connection exists',
          code: 'NO_CONNECTION',
        },
      },
      { status: 403 }
    )
  }

  if (error.message.includes('permission')) {
    return Response.json(
      {
        error: {
          message: language === 'khmer'
            ? 'មិនមានការអនុញ្ញាតគ្រប់គ្រាន់'
            : 'Insufficient permission',
          code: 'INSUFFICIENT_PERMISSION',
        },
      },
      { status: 403 }
    )
  }

  return Response.json(
    {
      error: {
        message: language === 'khmer'
          ? 'កំហុសមិនស្គាល់'
          : 'Unknown error',
        code: 'UNKNOWN_ERROR',
      },
    },
    { status: 500 }
  )
}
```

### Using Error Handler

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC, validatePermission } from '@/lib/middleware/rbac'
import { handleRBACError } from '@/lib/middleware/error-handler'

export const POST = withAuth(
  withRBAC(async (req, { user }) => {
    const { patientId } = await req.json()

    try {
      await validatePermission(user.id, patientId, 'ALLOWED', user.language)
      
      // Proceed with operation
      return Response.json({ success: true })
    } catch (error) {
      return handleRBACError(error, user.language)
    }
  })
)
```

## Testing Integration

### Unit Test Example

```typescript
import { describe, it, expect, vi } from 'vitest'
import { GET } from './route'
import { NextRequest } from 'next/server'

describe('GET /api/prescriptions', () => {
  it('should allow doctor with SELECTED permission', async () => {
    // Mock auth
    vi.mock('@/lib/middleware/auth', () => ({
      withAuth: (handler: any) => handler,
    }))

    // Mock RBAC
    vi.mock('@/lib/middleware/rbac', () => ({
      withRBAC: (handler: any) => handler,
    }))

    // Mock Prisma
    vi.mock('@/lib/prisma', () => ({
      prisma: {
        prescription: {
          findMany: vi.fn().mockResolvedValue([]),
        },
      },
    }))

    const req = new NextRequest('http://localhost/api/prescriptions?patientId=patient-123')
    const context = {
      user: {
        id: 'doctor-123',
        role: 'DOCTOR',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'PREMIUM',
      },
      req,
      checkPermission: vi.fn().mockResolvedValue(true),
      getPermissionLevel: vi.fn().mockResolvedValue('SELECTED'),
    }

    const response = await GET(req, context)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.prescriptions).toBeDefined()
  })
})
```

## Best Practices

### 1. Always Use Both Middlewares

```typescript
// ✅ Good
export const GET = withAuth(
  withRBAC(async (req, context) => {
    // Handler
  })
)

// ❌ Bad - Missing auth
export const GET = withRBAC(async (req, context) => {
  // Handler
})
```

### 2. Use Auto-Check for Simple Cases

```typescript
// ✅ Good - Simple and secure
export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      // Handler
    },
    {
      autoCheckPatientId: true,
      requiredPermission: 'ALLOWED',
    }
  )
)

// ⚠️ Acceptable - More control
export const GET = withAuth(
  withRBAC(async (req, { user, checkPermission }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')
    if (!await checkPermission(patientId, 'ALLOWED')) {
      return Response.json({ error: 'Access denied' }, { status: 403 })
    }
    // Handler
  })
)
```

### 3. Match Permission Level to Operation

```typescript
// Read operations: SELECTED
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

// Write operations: ALLOWED
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

### 4. Use Validation Helpers for Complex Logic

```typescript
import { validateConnection, validatePermission } from '@/lib/middleware/rbac'

export const POST = withAuth(
  withRBAC(async (req, { user }) => {
    const { patientId } = await req.json()

    try {
      await validateConnection(user.id, patientId, user.language)
      await validatePermission(user.id, patientId, 'ALLOWED', user.language)
      
      // Proceed with operation
      return Response.json({ success: true })
    } catch (error) {
      return Response.json({ error: error.message }, { status: 403 })
    }
  })
)
```

### 5. Log Permission Checks

```typescript
import { auditLog } from '@/lib/audit'

export const GET = withAuth(
  withRBAC(async (req, { user, checkPermission }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')
    const hasPermission = await checkPermission(patientId, 'ALLOWED')

    // Log access attempt
    await auditLog({
      actorId: user.id,
      actionType: 'DATA_ACCESS',
      resourceType: 'PATIENT_DATA',
      resourceId: patientId,
      success: hasPermission,
      details: { permissionChecked: 'ALLOWED' },
    })

    if (!hasPermission) {
      return Response.json({ error: 'Access denied' }, { status: 403 })
    }

    // Proceed
    return Response.json({ data: 'Patient data' })
  })
)
```

## Migration Guide

### From Basic Auth to RBAC

**Before:**
```typescript
export const GET = withAuth(async (req, { user }) => {
  const patientId = req.nextUrl.searchParams.get('patientId')
  
  // No permission checking
  const data = await getPatientData(patientId)
  return Response.json({ data })
})
```

**After:**
```typescript
export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      const patientId = req.nextUrl.searchParams.get('patientId')
      
      // Permission automatically checked
      const data = await getPatientData(patientId)
      return Response.json({ data })
    },
    {
      autoCheckPatientId: true,
      requiredPermission: 'ALLOWED',
    }
  )
)
```

## Troubleshooting

### Issue: Permission check always fails

**Solution:** Ensure connection exists and is ACCEPTED

```typescript
// Check connection status
const connection = await prisma.connection.findFirst({
  where: {
    OR: [
      { initiatorId: doctorId, recipientId: patientId },
      { initiatorId: patientId, recipientId: doctorId },
    ],
  },
})

console.log('Connection:', connection)
// Should show status: 'ACCEPTED'
```

### Issue: Auto-check not working

**Solution:** Ensure patientId is in query parameters

```typescript
// ✅ Correct
GET /api/prescriptions?patientId=patient-123

// ❌ Wrong
GET /api/prescriptions?patient=patient-123
```

### Issue: Family member access denied

**Solution:** Use `canFamilyMemberAccess` instead of `checkPermission`

```typescript
// ✅ Correct for family members
const hasAccess = await canFamilyMemberAccess(familyId, patientId)

// ❌ Wrong - checkPermission is for doctors
const hasAccess = await checkPermission(familyId, patientId)
```

## Summary

The RBAC middleware integrates seamlessly with JWT authentication to provide:

- ✅ Permission-level access control
- ✅ Role-based access control
- ✅ Automatic permission checking
- ✅ Manual permission checking
- ✅ Prescription-specific access
- ✅ Family member access
- ✅ Bilingual error messages
- ✅ Type-safe context
- ✅ Comprehensive testing

For more information, see:
- `RBAC_README.md` - Full documentation
- `RBAC_QUICK_REFERENCE.md` - Quick reference
- `backend/app/api/example/rbac/` - Working examples
