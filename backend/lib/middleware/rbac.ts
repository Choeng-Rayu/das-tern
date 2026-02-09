import { NextRequest, NextResponse } from 'next/server'
import { AuthUser, AuthContext } from './auth'
import { prisma } from '../prisma'
import { translate, getLanguageFromHeader, type Language } from '../i18n'

/**
 * Permission levels for doctor-patient connections
 * Based on Requirement 3 (Doctor-Patient Connection Management)
 */
export type PermissionLevel = 'NOT_ALLOWED' | 'REQUEST' | 'SELECTED' | 'ALLOWED'

/**
 * RBAC context with permission checking capabilities
 */
export interface RBACContext extends AuthContext {
  checkPermission: (targetUserId: string, requiredLevel?: PermissionLevel) => Promise<boolean>
  getPermissionLevel: (targetUserId: string) => Promise<PermissionLevel | null>
}

/**
 * Type for route handlers with RBAC
 */
export type RBACHandler = (
  req: NextRequest,
  context: RBACContext
) => Promise<Response> | Response

/**
 * Error response helper
 */
function createErrorResponse(
  message: string,
  messageKhmer: string,
  status: number,
  language: Language = 'english'
): NextResponse {
  return NextResponse.json(
    {
      error: {
        message: language === 'khmer' ? messageKhmer : message,
        messageEn: message,
        messageKm: messageKhmer,
        code: status === 403 ? 'FORBIDDEN' : 'UNAUTHORIZED',
      },
    },
    { status }
  )
}

/**
 * Check if a connection exists and is accepted between two users
 * 
 * @param userId1 - First user ID
 * @param userId2 - Second user ID
 * @returns The connection if it exists and is accepted, null otherwise
 */
async function getAcceptedConnection(
  userId1: string,
  userId2: string
): Promise<{ permissionLevel: PermissionLevel } | null> {
  try {
    // Check both directions since connections are bidirectional
    const connection = await prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: userId1, recipientId: userId2, status: 'ACCEPTED' },
          { initiatorId: userId2, recipientId: userId1, status: 'ACCEPTED' },
        ],
      },
      select: {
        permissionLevel: true,
      },
    })

    return connection
  } catch (error) {
    console.error('Error checking connection:', error)
    return null
  }
}

/**
 * Get the permission level for a doctor accessing patient data
 * 
 * @param doctorId - The doctor's user ID
 * @param patientId - The patient's user ID
 * @returns The permission level or null if no connection exists
 */
export async function getPermissionLevel(
  doctorId: string,
  patientId: string
): Promise<PermissionLevel | null> {
  const connection = await getAcceptedConnection(doctorId, patientId)
  return connection ? connection.permissionLevel : null
}

/**
 * Check if a user has permission to access another user's data
 * 
 * @param actorId - The user attempting to access data
 * @param targetUserId - The user whose data is being accessed
 * @param requiredLevel - The minimum permission level required (default: ALLOWED)
 * @returns True if permission is granted, false otherwise
 */
export async function checkPermission(
  actorId: string,
  targetUserId: string,
  requiredLevel: PermissionLevel = 'ALLOWED'
): Promise<boolean> {
  // Users always have full access to their own data
  if (actorId === targetUserId) {
    return true
  }

  // Get the connection and permission level
  const connection = await getAcceptedConnection(actorId, targetUserId)
  
  if (!connection) {
    return false
  }

  const permissionLevel = connection.permissionLevel

  // Define permission hierarchy
  const permissionHierarchy: Record<PermissionLevel, number> = {
    NOT_ALLOWED: 0,
    REQUEST: 1,
    SELECTED: 2,
    ALLOWED: 3,
  }

  // Check if the user's permission level meets the required level
  return permissionHierarchy[permissionLevel] >= permissionHierarchy[requiredLevel]
}

/**
 * Middleware to enforce permission-level access control for doctor-patient connections
 * 
 * This middleware extends the basic role-based access control to include
 * permission levels for doctor-patient connections as specified in Requirement 3
 * and Requirement 16 (Data Privacy and Access Control).
 * 
 * Permission Levels:
 * - NOT_ALLOWED: Doctor has no access to patient data
 * - REQUEST: Doctor must request explicit approval for each access
 * - SELECTED: Doctor can only access explicitly selected prescriptions/data
 * - ALLOWED: Doctor has full access to patient data
 * 
 * Usage:
 * ```typescript
 * import { withRBAC } from '@/lib/middleware/rbac'
 * 
 * export const GET = withRBAC(async (req, { user, checkPermission }) => {
 *   const patientId = req.nextUrl.searchParams.get('patientId')
 *   
 *   // Check if the doctor has permission to access this patient's data
 *   const hasPermission = await checkPermission(patientId, 'ALLOWED')
 *   
 *   if (!hasPermission) {
 *     return Response.json({ error: 'Access denied' }, { status: 403 })
 *   }
 *   
 *   // Proceed with data access
 *   return Response.json({ data })
 * })
 * ```
 * 
 * @param handler - The route handler function to wrap with RBAC
 * @param options - Optional configuration for the middleware
 * @returns Wrapped handler with RBAC
 */
export function withRBAC(
  handler: RBACHandler,
  options?: {
    requiredRole?: 'PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER' | ('PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER')[]
    autoCheckPatientId?: boolean // Automatically check permission for patientId query param
    requiredPermission?: PermissionLevel // Required permission level for autoCheckPatientId
  }
): (req: NextRequest, context: AuthContext) => Promise<Response> {
  return async (req: NextRequest, context: AuthContext): Promise<Response> => {
    try {
      const { user } = context
      const acceptLanguage = req.headers.get('accept-language') || undefined
      const language = getLanguageFromHeader(acceptLanguage)

      // Check role-based access if required
      if (options?.requiredRole) {
        const requiredRoles = Array.isArray(options.requiredRole)
          ? options.requiredRole
          : [options.requiredRole]

        if (!requiredRoles.includes(user.role)) {
          return createErrorResponse(
            `Access denied. This endpoint requires one of the following roles: ${requiredRoles.join(', ')}`,
            `ការចូលប្រើត្រូវបានបដិសេធ។ endpoint នេះត្រូវការតួនាទីមួយក្នុងចំណោម: ${requiredRoles.join(', ')}`,
            403,
            language
          )
        }
      }

      // Create permission checking functions
      const checkPermissionFn = async (
        targetUserId: string,
        requiredLevel: PermissionLevel = 'ALLOWED'
      ): Promise<boolean> => {
        return checkPermission(user.id, targetUserId, requiredLevel)
      }

      const getPermissionLevelFn = async (
        targetUserId: string
      ): Promise<PermissionLevel | null> => {
        return getPermissionLevel(user.id, targetUserId)
      }

      // Auto-check permission for patientId if enabled
      if (options?.autoCheckPatientId) {
        const patientId = req.nextUrl.searchParams.get('patientId')
        
        if (patientId && patientId !== user.id) {
          const requiredLevel = options.requiredPermission || 'ALLOWED'
          const hasPermission = await checkPermissionFn(patientId, requiredLevel)
          
          if (!hasPermission) {
            const permissionLevel = await getPermissionLevelFn(patientId)
            
            let errorMessage = 'Access denied. You do not have permission to access this patient\'s data.'
            let errorMessageKhmer = 'ការចូលប្រើត្រូវបានបដិសេធ។ អ្នកមិនមានការអនុញ្ញាតក្នុងការចូលប្រើទិន្នន័យរបស់អ្នកជំងឺនេះទេ។'
            
            if (permissionLevel === 'NOT_ALLOWED') {
              errorMessage = 'Access denied. The patient has not allowed you to access their data.'
              errorMessageKhmer = 'ការចូលប្រើត្រូវបានបដិសេធ។ អ្នកជំងឺមិនបានអនុញ្ញាតឱ្យអ្នកចូលប្រើទិន្នន័យរបស់ពួកគេទេ។'
            } else if (permissionLevel === 'REQUEST') {
              errorMessage = 'Access denied. You must request explicit approval from the patient to access this data.'
              errorMessageKhmer = 'ការចូលប្រើត្រូវបានបដិសេធ។ អ្នកត្រូវស្នើសុំការអនុម័តច្បាស់លាស់ពីអ្នកជំងឺដើម្បីចូលប្រើទិន្នន័យនេះ។'
            } else if (permissionLevel === 'SELECTED') {
              errorMessage = 'Access denied. You can only access selected prescriptions or data explicitly shared by the patient.'
              errorMessageKhmer = 'ការចូលប្រើត្រូវបានបដិសេធ។ អ្នកអាចចូលប្រើតែវេជ្ជបញ្ជាដែលបានជ្រើសរើស ឬទិន្នន័យដែលបានចែករំលែកច្បាស់លាស់ដោយអ្នកជំងឺប៉ុណ្ណោះ។'
            } else if (!permissionLevel) {
              errorMessage = 'Access denied. No connection exists with this patient.'
              errorMessageKhmer = 'ការចូលប្រើត្រូវបានបដិសេធ។ មិនមានការតភ្ជាប់ជាមួយអ្នកជំងឺនេះទេ។'
            }
            
            return createErrorResponse(errorMessage, errorMessageKhmer, 403, language)
          }
        }
      }

      // Create RBAC context
      const rbacContext: RBACContext = {
        ...context,
        checkPermission: checkPermissionFn,
        getPermissionLevel: getPermissionLevelFn,
      }

      // Call the handler with RBAC context
      return await handler(req, rbacContext)
    } catch (error) {
      console.error('RBAC middleware error:', error)
      
      const acceptLanguage = req.headers.get('accept-language') || undefined
      const language = getLanguageFromHeader(acceptLanguage)

      return createErrorResponse(
        'Permission check failed. Please try again.',
        'ការពិនិត្យការអនុញ្ញាតបានបរាជ័យ។ សូមព្យាយាមម្តងទៀត។',
        500,
        language
      )
    }
  }
}

/**
 * Helper function to check if a doctor can access a specific prescription
 * 
 * @param doctorId - The doctor's user ID
 * @param prescriptionId - The prescription ID to check
 * @param requiredLevel - The minimum permission level required
 * @returns True if the doctor can access the prescription, false otherwise
 */
export async function canAccessPrescription(
  doctorId: string,
  prescriptionId: string,
  requiredLevel: PermissionLevel = 'ALLOWED'
): Promise<boolean> {
  try {
    // Get the prescription to find the patient
    const prescription = await prisma.prescription.findUnique({
      where: { id: prescriptionId },
      select: { patientId: true, doctorId: true },
    })

    if (!prescription) {
      return false
    }

    // If the doctor is the prescription author, they have access
    if (prescription.doctorId === doctorId) {
      return true
    }

    // Check permission level with the patient
    return checkPermission(doctorId, prescription.patientId, requiredLevel)
  } catch (error) {
    console.error('Error checking prescription access:', error)
    return false
  }
}

/**
 * Helper function to check if a family member can access patient data
 * 
 * @param familyMemberId - The family member's user ID
 * @param patientId - The patient's user ID
 * @returns True if the family member has access, false otherwise
 */
export async function canFamilyMemberAccess(
  familyMemberId: string,
  patientId: string
): Promise<boolean> {
  try {
    // Family members need an accepted connection
    const connection = await getAcceptedConnection(familyMemberId, patientId)
    
    // Family members have view permissions if connection is accepted
    // They don't use the same permission levels as doctors
    return connection !== null
  } catch (error) {
    console.error('Error checking family member access:', error)
    return false
  }
}

/**
 * Validate that a connection exists and is accepted
 * Throws an error with appropriate message if validation fails
 * 
 * @param userId1 - First user ID
 * @param userId2 - Second user ID
 * @param language - Language for error messages
 * @throws Error if connection doesn't exist or isn't accepted
 */
export async function validateConnection(
  userId1: string,
  userId2: string,
  language: Language = 'english'
): Promise<void> {
  const connection = await getAcceptedConnection(userId1, userId2)
  
  if (!connection) {
    const message = language === 'khmer'
      ? 'មិនមានការតភ្ជាប់ដែលបានទទួលយករវាងអ្នកប្រើប្រាស់ទាំងនេះទេ។'
      : 'No accepted connection exists between these users.'
    throw new Error(message)
  }
}

/**
 * Validate that a doctor has the required permission level to access patient data
 * Throws an error with appropriate message if validation fails
 * 
 * @param doctorId - The doctor's user ID
 * @param patientId - The patient's user ID
 * @param requiredLevel - The minimum permission level required
 * @param language - Language for error messages
 * @throws Error if permission is insufficient
 */
export async function validatePermission(
  doctorId: string,
  patientId: string,
  requiredLevel: PermissionLevel = 'ALLOWED',
  language: Language = 'english'
): Promise<void> {
  const hasPermission = await checkPermission(doctorId, patientId, requiredLevel)
  
  if (!hasPermission) {
    const message = language === 'khmer'
      ? 'អ្នកមិនមានការអនុញ្ញាតគ្រប់គ្រាន់ដើម្បីចូលប្រើទិន្នន័យនេះទេ។'
      : 'You do not have sufficient permission to access this data.'
    throw new Error(message)
  }
}
