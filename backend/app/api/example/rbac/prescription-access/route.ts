import { withAuth } from '@/lib/middleware/auth'
import { withRBAC, canAccessPrescription } from '@/lib/middleware/rbac'

/**
 * Example: Doctor accessing a specific prescription
 * 
 * This endpoint demonstrates:
 * 1. Manual permission checking using canAccessPrescription
 * 2. Different permission levels for different operations
 * 3. Detailed error responses
 * 
 * Usage:
 * GET /api/example/rbac/prescription-access?prescriptionId=prescription-123
 * 
 * Headers:
 * Authorization: Bearer <doctor-jwt-token>
 */
export const GET = withAuth(
  withRBAC(async (req, { user, getPermissionLevel }) => {
    const prescriptionId = req.nextUrl.searchParams.get('prescriptionId')

    if (!prescriptionId) {
      return Response.json(
        { error: 'prescriptionId is required' },
        { status: 400 }
      )
    }

    // Check if doctor can access this prescription
    const canAccess = await canAccessPrescription(
      user.id,
      prescriptionId,
      'SELECTED' // Requires at least SELECTED permission
    )

    if (!canAccess) {
      return Response.json(
        {
          error: 'Access denied',
          message: 'You do not have permission to access this prescription',
        },
        { status: 403 }
      )
    }

    // Access granted
    return Response.json({
      message: 'Access granted',
      prescription: {
        id: prescriptionId,
        // In a real implementation, fetch prescription data here
        data: 'Prescription details, medications, dosages, etc.',
      },
    })
  })
)

/**
 * Example: Doctor updating a prescription
 * 
 * This endpoint demonstrates:
 * 1. Higher permission level required for write operations
 * 2. Role-based access control
 * 
 * Usage:
 * PATCH /api/example/rbac/prescription-access?prescriptionId=prescription-123
 * 
 * Headers:
 * Authorization: Bearer <doctor-jwt-token>
 * 
 * Body:
 * {
 *   "medications": [...],
 *   "isUrgent": false
 * }
 */
export const PATCH = withAuth(
  withRBAC(
    async (req, { user }) => {
      const prescriptionId = req.nextUrl.searchParams.get('prescriptionId')

      if (!prescriptionId) {
        return Response.json(
          { error: 'prescriptionId is required' },
          { status: 400 }
        )
      }

      // For updates, require ALLOWED permission
      const canAccess = await canAccessPrescription(
        user.id,
        prescriptionId,
        'ALLOWED'
      )

      if (!canAccess) {
        return Response.json(
          {
            error: 'Access denied',
            message: 'You need ALLOWED permission to update prescriptions',
          },
          { status: 403 }
        )
      }

      const body = await req.json()

      // Update prescription
      return Response.json({
        message: 'Prescription updated successfully',
        prescription: {
          id: prescriptionId,
          ...body,
        },
      })
    },
    {
      requiredRole: 'DOCTOR',
    }
  )
)
