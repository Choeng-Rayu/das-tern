import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'

/**
 * Example protected API route using JWT authentication middleware
 * 
 * This endpoint demonstrates:
 * - Basic authentication with withAuth
 * - Accessing authenticated user data
 * - Type-safe user context
 */
export const GET = withAuth(async (req: NextRequest, { user }) => {
  // User is automatically authenticated and available here
  // TypeScript provides full type safety for user object
  
  return Response.json({
    message: 'Successfully authenticated',
    user: {
      id: user.id,
      role: user.role,
      language: user.language,
      theme: user.theme,
      subscriptionTier: user.subscriptionTier,
    },
    timestamp: new Date().toISOString(),
  })
})

/**
 * Example protected POST endpoint with role-based access control
 * Only DOCTOR role can access this endpoint
 */
export const POST = withAuth(
  async (req: NextRequest, { user }) => {
    const body = await req.json()
    
    return Response.json({
      message: 'Doctor-only endpoint accessed successfully',
      doctor: {
        id: user.id,
        role: user.role,
      },
      data: body,
    })
  },
  {
    requiredRole: 'DOCTOR',
  }
)

/**
 * Example protected PATCH endpoint with multiple allowed roles
 * Both DOCTOR and PATIENT roles can access this endpoint
 */
export const PATCH = withAuth(
  async (req: NextRequest, { user }) => {
    const body = await req.json()
    
    return Response.json({
      message: 'Multi-role endpoint accessed successfully',
      user: {
        id: user.id,
        role: user.role,
      },
      data: body,
    })
  },
  {
    requiredRole: ['DOCTOR', 'PATIENT'] as any,
  }
)
