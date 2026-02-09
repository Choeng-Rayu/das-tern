import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

/**
 * Example: Doctor accessing patient data with permission check
 * 
 * This endpoint demonstrates:
 * 1. Role-based access (DOCTOR only)
 * 2. Automatic permission checking for patientId query parameter
 * 3. Required permission level (ALLOWED)
 * 
 * Usage:
 * GET /api/example/rbac/patient-data?patientId=patient-123
 * 
 * Headers:
 * Authorization: Bearer <doctor-jwt-token>
 */
export const GET = withAuth(
  withRBAC(
    async (req, { user }) => {
      const patientId = req.nextUrl.searchParams.get('patientId')

      // Permission already checked by middleware
      // If we reach here, the doctor has ALLOWED permission

      return Response.json({
        message: 'Access granted',
        doctor: {
          id: user.id,
          role: user.role,
        },
        patient: {
          id: patientId,
          // In a real implementation, fetch patient data here
          data: 'Patient medical records, prescriptions, etc.',
        },
      })
    },
    {
      requiredRole: 'DOCTOR',
      autoCheckPatientId: true,
      requiredPermission: 'ALLOWED',
    }
  )
)
