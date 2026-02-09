import { withAuth } from '@/lib/middleware/auth'
import { withRBAC, canFamilyMemberAccess } from '@/lib/middleware/rbac'

/**
 * Example: Family member accessing patient data
 * 
 * This endpoint demonstrates:
 * 1. Family member access control
 * 2. Role-based access (FAMILY_MEMBER only)
 * 3. Simple connection-based access (no permission levels)
 * 
 * Usage:
 * GET /api/example/rbac/family-access?patientId=patient-123
 * 
 * Headers:
 * Authorization: Bearer <family-member-jwt-token>
 */
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

      // Check if family member has access to this patient
      const hasAccess = await canFamilyMemberAccess(user.id, patientId)

      if (!hasAccess) {
        return Response.json(
          {
            error: 'Access denied',
            message: 'You do not have a connection with this patient',
          },
          { status: 403 }
        )
      }

      // Access granted
      return Response.json({
        message: 'Access granted',
        familyMember: {
          id: user.id,
          role: user.role,
        },
        patient: {
          id: patientId,
          // In a real implementation, fetch patient data here
          // Family members typically see:
          // - Medication schedule
          // - Adherence status
          // - Missed dose alerts
          data: {
            schedule: 'Daily medication schedule',
            adherence: '85%',
            missedDoses: [],
          },
        },
      })
    },
    {
      requiredRole: 'FAMILY_MEMBER',
    }
  )
)
