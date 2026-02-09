import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'

/**
 * Example: Manual permission checking with detailed responses
 * 
 * This endpoint demonstrates:
 * 1. Manual permission checking using checkPermission
 * 2. Getting permission level using getPermissionLevel
 * 3. Different responses based on permission level
 * 4. Multiple permission checks in one endpoint
 * 
 * Usage:
 * GET /api/example/rbac/manual-check?patientId=patient-123
 * 
 * Headers:
 * Authorization: Bearer <doctor-jwt-token>
 */
export const GET = withAuth(
  withRBAC(async (req, { user, checkPermission, getPermissionLevel }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')

    if (!patientId) {
      return Response.json(
        { error: 'patientId is required' },
        { status: 400 }
      )
    }

    // Get the permission level
    const permissionLevel = await getPermissionLevel(user.id, patientId)

    if (!permissionLevel) {
      return Response.json(
        {
          error: 'No connection',
          message: 'You do not have a connection with this patient',
        },
        { status: 403 }
      )
    }

    // Check different permission levels
    const canRequest = await checkPermission(patientId, 'REQUEST')
    const canViewSelected = await checkPermission(patientId, 'SELECTED')
    const canViewAll = await checkPermission(patientId, 'ALLOWED')

    // Return different data based on permission level
    const response: any = {
      message: 'Access granted',
      permissionLevel,
      capabilities: {
        canRequest,
        canViewSelected,
        canViewAll,
      },
      patient: {
        id: patientId,
      },
    }

    // Add data based on permission level
    if (canViewAll) {
      response.patient.fullData = {
        prescriptions: 'All prescriptions',
        doseHistory: 'Complete dose history',
        adherence: 'Full adherence data',
      }
    } else if (canViewSelected) {
      response.patient.selectedData = {
        prescriptions: 'Selected prescriptions only',
        doseHistory: 'Limited dose history',
      }
    } else if (canRequest) {
      response.patient.limitedData = {
        message: 'You can request access to specific data',
      }
    } else {
      return Response.json(
        {
          error: 'Access denied',
          message: 'The patient has not allowed you to access their data',
          permissionLevel,
        },
        { status: 403 }
      )
    }

    return Response.json(response)
  })
)

/**
 * Example: Requesting access to patient data
 * 
 * This endpoint demonstrates:
 * 1. REQUEST permission level usage
 * 2. Creating access requests
 * 
 * Usage:
 * POST /api/example/rbac/manual-check?patientId=patient-123
 * 
 * Headers:
 * Authorization: Bearer <doctor-jwt-token>
 * 
 * Body:
 * {
 *   "reason": "Need to review medication history",
 *   "dataType": "prescriptions"
 * }
 */
export const POST = withAuth(
  withRBAC(async (req, { user, checkPermission, getPermissionLevel }) => {
    const patientId = req.nextUrl.searchParams.get('patientId')

    if (!patientId) {
      return Response.json(
        { error: 'patientId is required' },
        { status: 400 }
      )
    }

    // Check if doctor has at least REQUEST permission
    const canRequest = await checkPermission(patientId, 'REQUEST')

    if (!canRequest) {
      const permissionLevel = await getPermissionLevel(user.id, patientId)
      return Response.json(
        {
          error: 'Access denied',
          message:
            permissionLevel === 'NOT_ALLOWED'
              ? 'The patient has not allowed you to request access'
              : 'You do not have a connection with this patient',
          permissionLevel,
        },
        { status: 403 }
      )
    }

    const body = await req.json()

    // In a real implementation, create an access request record
    // and notify the patient

    return Response.json({
      message: 'Access request created',
      request: {
        doctorId: user.id,
        patientId,
        reason: body.reason,
        dataType: body.dataType,
        status: 'PENDING',
        createdAt: new Date().toISOString(),
      },
    })
  })
)
