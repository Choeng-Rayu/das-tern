import { NextRequest } from 'next/server'
import { withOptionalAuth } from '@/lib/middleware/auth'

/**
 * Example API route with optional authentication
 * 
 * This endpoint demonstrates:
 * - Optional authentication (works for both authenticated and anonymous users)
 * - Different behavior based on authentication status
 * - Graceful handling of missing authentication
 */
export const GET = withOptionalAuth(async (req: NextRequest, { user }) => {
  if (user) {
    // Authenticated user - return personalized data
    return Response.json({
      message: 'Welcome back!',
      authenticated: true,
      user: {
        id: user.id,
        role: user.role,
        language: user.language,
        theme: user.theme,
        subscriptionTier: user.subscriptionTier,
      },
      features: {
        premium: user.subscriptionTier !== 'FREEMIUM',
        storage: user.subscriptionTier === 'FREEMIUM' ? '5GB' : '20GB',
      },
    })
  } else {
    // Anonymous user - return public data
    return Response.json({
      message: 'Welcome! Please login for personalized features.',
      authenticated: false,
      features: {
        premium: false,
        storage: 'N/A',
      },
    })
  }
})
