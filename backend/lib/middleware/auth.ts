import { NextRequest, NextResponse } from 'next/server'
import { getToken } from 'next-auth/jwt'
import { cache } from '../redis'
import { translate, getLanguageFromHeader, type Language } from '../i18n'

// Types for authenticated request context
export interface AuthUser {
  id: string
  role: 'PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER'
  language: Language
  theme: 'LIGHT' | 'DARK'
  subscriptionTier: 'FREEMIUM' | 'PREMIUM' | 'FAMILY_PREMIUM'
}

export interface AuthContext {
  user: AuthUser
  req: NextRequest
}

// Type for route handlers with authentication
export type AuthenticatedHandler = (
  req: NextRequest,
  context: AuthContext
) => Promise<Response> | Response

// Error response helper
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
        code: status === 401 ? 'UNAUTHORIZED' : 'FORBIDDEN',
      },
    },
    { status }
  )
}

/**
 * JWT Authentication Middleware for Next.js API Routes
 * 
 * Features:
 * - Verifies JWT tokens from Authorization header (Bearer token)
 * - Validates token expiration and signature
 * - Extracts user information from token (id, role, language, theme, subscriptionTier)
 * - Attaches user data to the request context
 * - Returns 401 errors for invalid/missing/expired tokens
 * - Supports token refresh mechanism via NextAuth.js
 * - Integrates with Redis for token blacklisting
 * 
 * Usage:
 * ```typescript
 * import { withAuth } from '@/lib/middleware/auth'
 * 
 * export const GET = withAuth(async (req, { user }) => {
 *   // user is available here with type safety
 *   return Response.json({ user })
 * })
 * ```
 * 
 * @param handler - The route handler function to wrap with authentication
 * @param options - Optional configuration for the middleware
 * @returns Wrapped handler with authentication
 */
export function withAuth(
  handler: AuthenticatedHandler,
  options?: {
    requiredRole?: 'PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER' | 'PATIENT' | 'DOCTOR'[]
    checkBlacklist?: boolean
  }
): (req: NextRequest) => Promise<Response> {
  return async (req: NextRequest): Promise<Response> => {
    try {
      // Get language preference from header
      const acceptLanguage = req.headers.get('accept-language') || undefined
      const language = getLanguageFromHeader(acceptLanguage)

      // Extract token from Authorization header
      const authHeader = req.headers.get('authorization')
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return createErrorResponse(
          'Missing or invalid authorization header. Please provide a valid Bearer token.',
          'បាត់បង់ឬមិនត្រឹមត្រូវនូវក្បាលការអនុញ្ញាត។ សូមផ្តល់នូវ Bearer token ត្រឹមត្រូវ។',
          401,
          language
        )
      }

      // Get JWT token using NextAuth.js
      const token = await getToken({
        req: req as any,
        secret: process.env.NEXTAUTH_SECRET,
      })

      if (!token) {
        return createErrorResponse(
          'Invalid or expired token. Please login again.',
          'Token មិនត្រឹមត្រូវ ឬផុតកំណត់។ សូមចូលម្តងទៀត។',
          401,
          language
        )
      }

      // Check if token is blacklisted (for logout functionality)
      if (options?.checkBlacklist !== false) {
        const isBlacklisted = await cache.exists(`blacklist:token:${token.jti || token.sub}`)
        if (isBlacklisted) {
          return createErrorResponse(
            'Token has been revoked. Please login again.',
            'Token ត្រូវបានដកហូត។ សូមចូលម្តងទៀត។',
            401,
            language
          )
        }
      }

      // Validate token expiration (NextAuth handles this, but double-check)
      if (token.exp && Date.now() >= token.exp * 1000) {
        return createErrorResponse(
          'Token has expired. Please refresh your token or login again.',
          'Token ផុតកំណត់។ សូមធ្វើបច្ចុប្បន្នភាព token របស់អ្នក ឬចូលម្តងទៀត។',
          401,
          language
        )
      }

      // Extract user information from token
      const user: AuthUser = {
        id: token.id as string || token.sub as string,
        role: token.role as AuthUser['role'],
        language: (token.language as Language) || 'english',
        theme: (token.theme as AuthUser['theme']) || 'LIGHT',
        subscriptionTier: (token.subscriptionTier as AuthUser['subscriptionTier']) || 'FREEMIUM',
      }

      // Validate required fields
      if (!user.id || !user.role) {
        return createErrorResponse(
          'Invalid token payload. Missing required user information.',
          'Token payload មិនត្រឹមត្រូវ។ បាត់បង់ព័ត៌មានអ្នកប្រើប្រាស់ចាំបាច់។',
          401,
          language
        )
      }

      // Check role-based access control if required
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

      // Create auth context
      const context: AuthContext = {
        user,
        req,
      }

      // Call the handler with authenticated context
      return await handler(req, context)
    } catch (error) {
      console.error('Authentication middleware error:', error)
      
      const acceptLanguage = req.headers.get('accept-language') || undefined
      const language = getLanguageFromHeader(acceptLanguage)

      return createErrorResponse(
        'Authentication failed. Please try again.',
        'ការផ្ទៀងផ្ទាត់បានបរាជ័យ។ សូមព្យាយាមម្តងទៀត។',
        401,
        language
      )
    }
  }
}

/**
 * Optional authentication middleware - doesn't fail if no token is provided
 * Useful for endpoints that work differently for authenticated vs anonymous users
 * 
 * Usage:
 * ```typescript
 * import { withOptionalAuth } from '@/lib/middleware/auth'
 * 
 * export const GET = withOptionalAuth(async (req, { user }) => {
 *   if (user) {
 *     // Authenticated user logic
 *   } else {
 *     // Anonymous user logic
 *   }
 *   return Response.json({ data })
 * })
 * ```
 */
export function withOptionalAuth(
  handler: (req: NextRequest, context: { user: AuthUser | null }) => Promise<Response> | Response
): (req: NextRequest) => Promise<Response> {
  return async (req: NextRequest): Promise<Response> => {
    try {
      // Try to get token
      const token = await getToken({
        req: req as any,
        secret: process.env.NEXTAUTH_SECRET,
      })

      let user: AuthUser | null = null

      if (token && token.id && token.role) {
        // Check if token is blacklisted
        const isBlacklisted = await cache.exists(`blacklist:token:${token.jti || token.sub}`)
        
        if (!isBlacklisted && (!token.exp || Date.now() < token.exp * 1000)) {
          user = {
            id: token.id as string || token.sub as string,
            role: token.role as AuthUser['role'],
            language: (token.language as Language) || 'english',
            theme: (token.theme as AuthUser['theme']) || 'LIGHT',
            subscriptionTier: (token.subscriptionTier as AuthUser['subscriptionTier']) || 'FREEMIUM',
          }
        }
      }

      return await handler(req, { user })
    } catch (error) {
      console.error('Optional authentication middleware error:', error)
      // For optional auth, continue without user on error
      return await handler(req, { user: null })
    }
  }
}

/**
 * Blacklist a token (for logout functionality)
 * Stores the token in Redis with expiration matching the token's expiration
 * 
 * @param tokenId - The token ID (jti) or subject (sub) to blacklist
 * @param expiresIn - Time in seconds until the token expires
 */
export async function blacklistToken(tokenId: string, expiresIn: number): Promise<void> {
  try {
    await cache.set(`blacklist:token:${tokenId}`, true, expiresIn)
  } catch (error) {
    console.error('Error blacklisting token:', error)
    throw new Error('Failed to blacklist token')
  }
}

/**
 * Check if a token is blacklisted
 * 
 * @param tokenId - The token ID (jti) or subject (sub) to check
 * @returns True if the token is blacklisted, false otherwise
 */
export async function isTokenBlacklisted(tokenId: string): Promise<boolean> {
  try {
    return await cache.exists(`blacklist:token:${tokenId}`)
  } catch (error) {
    console.error('Error checking token blacklist:', error)
    return false
  }
}

/**
 * Refresh token helper
 * This is handled by NextAuth.js refresh token rotation
 * Use the /api/auth/refresh endpoint to refresh tokens
 */
export async function refreshAuthToken(refreshToken: string): Promise<{
  accessToken: string
  refreshToken: string
} | null> {
  try {
    // NextAuth.js handles token refresh automatically
    // This function is a placeholder for custom refresh logic if needed
    // The actual refresh happens through the NextAuth.js session callback
    
    // For now, return null to indicate that refresh should be handled by NextAuth
    return null
  } catch (error) {
    console.error('Error refreshing token:', error)
    return null
  }
}

/**
 * Validate token without full authentication
 * Useful for checking token validity without enforcing authentication
 * 
 * @param req - The Next.js request object
 * @returns The user information if token is valid, null otherwise
 */
export async function validateToken(req: NextRequest): Promise<AuthUser | null> {
  try {
    const token = await getToken({
      req: req as any,
      secret: process.env.NEXTAUTH_SECRET,
    })

    if (!token || !token.id || !token.role) {
      return null
    }

    // Check if token is blacklisted
    const isBlacklisted = await cache.exists(`blacklist:token:${token.jti || token.sub}`)
    if (isBlacklisted) {
      return null
    }

    // Check expiration
    if (token.exp && Date.now() >= token.exp * 1000) {
      return null
    }

    return {
      id: token.id as string || token.sub as string,
      role: token.role as AuthUser['role'],
      language: (token.language as Language) || 'english',
      theme: (token.theme as AuthUser['theme']) || 'LIGHT',
      subscriptionTier: (token.subscriptionTier as AuthUser['subscriptionTier']) || 'FREEMIUM',
    }
  } catch (error) {
    console.error('Error validating token:', error)
    return null
  }
}
