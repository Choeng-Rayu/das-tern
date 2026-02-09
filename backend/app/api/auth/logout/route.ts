import { NextRequest, NextResponse } from 'next/server'
import { getToken } from 'next-auth/jwt'
import { blacklistToken } from '@/lib/middleware/auth'
import { translate, getLanguageFromHeader } from '@/lib/i18n'

/**
 * Logout endpoint
 * 
 * This endpoint:
 * - Blacklists the current JWT token
 * - Prevents the token from being used again
 * - Returns success message in user's preferred language
 * 
 * The token is stored in Redis with expiration matching the token's expiration
 * This ensures the blacklist doesn't grow indefinitely
 */
export async function POST(req: NextRequest) {
  try {
    // Get language preference
    const acceptLanguage = req.headers.get('accept-language') || undefined
    const language = getLanguageFromHeader(acceptLanguage)

    // Get the current token
    const token = await getToken({
      req: req as any,
      secret: process.env.NEXTAUTH_SECRET,
    })

    if (!token) {
      return NextResponse.json(
        {
          error: {
            message: translate('auth.unauthorized', language),
            messageEn: translate('auth.unauthorized', 'english'),
            messageKm: translate('auth.unauthorized', 'khmer'),
            code: 'UNAUTHORIZED',
          },
        },
        { status: 401 }
      )
    }

    // Calculate remaining time until token expiration
    const now = Math.floor(Date.now() / 1000)
    const expiresIn = token.exp ? token.exp - now : 900 // Default 15 minutes if no exp

    // Blacklist the token
    const tokenId = token.jti || token.sub || token.id
    if (tokenId) {
      await blacklistToken(tokenId as string, Math.max(expiresIn, 0))
    }

    return NextResponse.json({
      message: translate('auth.logoutSuccess', language),
      messageEn: translate('auth.logoutSuccess', 'english'),
      messageKm: translate('auth.logoutSuccess', 'khmer'),
      success: true,
    })
  } catch (error) {
    console.error('Logout error:', error)

    const acceptLanguage = req.headers.get('accept-language') || undefined
    const language = getLanguageFromHeader(acceptLanguage)

    return NextResponse.json(
      {
        error: {
          message: translate('errors.serverError', language),
          messageEn: translate('errors.serverError', 'english'),
          messageKm: translate('errors.serverError', 'khmer'),
          code: 'SERVER_ERROR',
        },
      },
      { status: 500 }
    )
  }
}
