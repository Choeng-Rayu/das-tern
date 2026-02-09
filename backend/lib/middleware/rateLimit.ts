import { NextRequest, NextResponse } from 'next/server'
import { redis } from '../redis'
import { AuthUser, AuthContext } from './auth'
import { translate, getLanguageFromHeader, type Language } from '../i18n'

/**
 * Rate limit configuration options
 */
export interface RateLimitOptions {
  /**
   * Maximum number of requests allowed within the window
   * Default: 100 (per Requirement 27)
   */
  maxRequests?: number

  /**
   * Time window in seconds
   * Default: 60 (1 minute per Requirement 27)
   */
  windowSeconds?: number

  /**
   * Whether to use per-user rate limiting (requires authentication)
   * Default: true
   */
  perUser?: boolean

  /**
   * Whether to use per-IP rate limiting (fallback for unauthenticated requests)
   * Default: true
   */
  perIP?: boolean

  /**
   * Custom key prefix for Redis
   * Default: 'ratelimit'
   */
  keyPrefix?: string

  /**
   * Skip rate limiting for specific conditions
   */
  skip?: (req: NextRequest, user?: AuthUser) => boolean | Promise<boolean>
}

/**
 * Rate limit information returned in headers
 */
export interface RateLimitInfo {
  limit: number
  remaining: number
  reset: number // Unix timestamp in seconds
  retryAfter?: number // Seconds until rate limit resets
}

/**
 * Error response helper
 */
function createErrorResponse(
  message: string,
  messageKhmer: string,
  status: number,
  language: Language = 'english',
  rateLimitInfo?: RateLimitInfo
): NextResponse {
  const response = NextResponse.json(
    {
      error: {
        message: language === 'khmer' ? messageKhmer : message,
        messageEn: message,
        messageKm: messageKhmer,
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: rateLimitInfo?.retryAfter,
      },
    },
    { status }
  )

  // Add rate limit headers per Requirement 27
  if (rateLimitInfo) {
    response.headers.set('X-RateLimit-Limit', rateLimitInfo.limit.toString())
    response.headers.set('X-RateLimit-Remaining', rateLimitInfo.remaining.toString())
    response.headers.set('X-RateLimit-Reset', rateLimitInfo.reset.toString())
    
    if (rateLimitInfo.retryAfter) {
      response.headers.set('Retry-After', rateLimitInfo.retryAfter.toString())
    }
  }

  return response
}

/**
 * Add rate limit headers to a successful response
 */
function addRateLimitHeaders(response: Response, info: RateLimitInfo): Response {
  const newResponse = new Response(response.body, response)
  
  newResponse.headers.set('X-RateLimit-Limit', info.limit.toString())
  newResponse.headers.set('X-RateLimit-Remaining', info.remaining.toString())
  newResponse.headers.set('X-RateLimit-Reset', info.reset.toString())
  
  return newResponse
}

/**
 * Get client IP address from request
 */
function getClientIP(req: NextRequest): string {
  // Check various headers for the real IP
  const forwarded = req.headers.get('x-forwarded-for')
  const realIP = req.headers.get('x-real-ip')
  const cfConnectingIP = req.headers.get('cf-connecting-ip')
  
  if (cfConnectingIP) return cfConnectingIP
  if (realIP) return realIP
  if (forwarded) return forwarded.split(',')[0].trim()
  
  // Fallback to a default value (should not happen in production)
  return 'unknown'
}

/**
 * Check rate limit for a given key
 * 
 * @param key - Redis key for rate limiting
 * @param maxRequests - Maximum requests allowed
 * @param windowSeconds - Time window in seconds
 * @returns Rate limit information
 */
async function checkRateLimit(
  key: string,
  maxRequests: number,
  windowSeconds: number
): Promise<RateLimitInfo> {
  try {
    const now = Date.now()
    const windowStart = now - (windowSeconds * 1000)
    
    // Use Redis sorted set to track requests with timestamps
    // This allows for sliding window rate limiting
    const multi = redis.multi()
    
    // Remove old entries outside the window
    multi.zremrangebyscore(key, 0, windowStart)
    
    // Add current request
    multi.zadd(key, now, `${now}`)
    
    // Count requests in the current window
    multi.zcard(key)
    
    // Set expiration to clean up old keys
    multi.expire(key, windowSeconds)
    
    const results = await multi.exec()
    
    if (!results) {
      throw new Error('Redis transaction failed')
    }
    
    // Get the count from the ZCARD result
    const count = results[2][1] as number
    
    const remaining = Math.max(0, maxRequests - count)
    const reset = Math.ceil((now + (windowSeconds * 1000)) / 1000)
    
    return {
      limit: maxRequests,
      remaining,
      reset,
      retryAfter: remaining === 0 ? windowSeconds : undefined,
    }
  } catch (error) {
    console.error('Rate limit check error:', error)
    
    // On error, allow the request but log the issue
    // This prevents Redis failures from blocking all traffic
    return {
      limit: maxRequests,
      remaining: maxRequests,
      reset: Math.ceil((Date.now() + (windowSeconds * 1000)) / 1000),
    }
  }
}

/**
 * Rate limiting middleware for Next.js API routes
 * 
 * Implements rate limiting as specified in Requirement 27:
 * - 100 requests per minute per user (default)
 * - Returns HTTP 429 when rate limit is exceeded
 * - Includes Retry-After header
 * - Uses Redis for tracking request counts
 * - Supports both per-user and per-IP rate limiting
 * 
 * Features:
 * - Sliding window rate limiting for accurate request counting
 * - Per-user rate limiting (requires authentication)
 * - Per-IP rate limiting (fallback for unauthenticated requests)
 * - Configurable limits and time windows
 * - Rate limit headers (X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset)
 * - Retry-After header when limit is exceeded
 * - Multi-language error messages (Khmer/English)
 * - Graceful degradation on Redis failures
 * 
 * Usage with authentication:
 * ```typescript
 * import { withAuth } from '@/lib/middleware/auth'
 * import { withRateLimit } from '@/lib/middleware/rateLimit'
 * 
 * export const GET = withAuth(
 *   withRateLimit(async (req, { user }) => {
 *     return Response.json({ data: 'success' })
 *   })
 * )
 * ```
 * 
 * Usage without authentication (per-IP):
 * ```typescript
 * import { withRateLimit } from '@/lib/middleware/rateLimit'
 * 
 * export const POST = withRateLimit(
 *   async (req) => {
 *     return Response.json({ data: 'success' })
 *   },
 *   { perUser: false, perIP: true }
 * )
 * ```
 * 
 * Custom configuration:
 * ```typescript
 * export const POST = withRateLimit(
 *   async (req) => {
 *     return Response.json({ data: 'success' })
 *   },
 *   {
 *     maxRequests: 50,
 *     windowSeconds: 60,
 *     skip: async (req, user) => {
 *       // Skip rate limiting for admin users
 *       return user?.role === 'ADMIN'
 *     }
 *   }
 * )
 * ```
 * 
 * @param handler - The route handler function to wrap with rate limiting
 * @param options - Rate limit configuration options
 * @returns Wrapped handler with rate limiting
 */
export function withRateLimit<T extends (...args: any[]) => Promise<Response> | Response>(
  handler: T,
  options: RateLimitOptions = {}
): T {
  const {
    maxRequests = 100, // Per Requirement 27
    windowSeconds = 60, // Per Requirement 27 (1 minute)
    perUser = true,
    perIP = true,
    keyPrefix = 'ratelimit',
    skip,
  } = options

  return (async (...args: any[]) => {
    const req = args[0] as NextRequest
    const context = args[1] as AuthContext | undefined
    const user = context?.user

    try {
      const acceptLanguage = req.headers.get('accept-language') || undefined
      const language = getLanguageFromHeader(acceptLanguage)

      // Check if rate limiting should be skipped
      if (skip) {
        const shouldSkip = await skip(req, user)
        if (shouldSkip) {
          return await handler(...args)
        }
      }

      // Determine rate limit key based on configuration
      let rateLimitKey: string | null = null

      if (perUser && user) {
        // Per-user rate limiting (preferred)
        rateLimitKey = `${keyPrefix}:user:${user.id}`
      } else if (perIP) {
        // Per-IP rate limiting (fallback)
        const clientIP = getClientIP(req)
        rateLimitKey = `${keyPrefix}:ip:${clientIP}`
      }

      if (!rateLimitKey) {
        // No rate limiting configured
        return await handler(...args)
      }

      // Check rate limit
      const rateLimitInfo = await checkRateLimit(rateLimitKey, maxRequests, windowSeconds)

      // If rate limit exceeded, return 429 error
      if (rateLimitInfo.remaining === 0) {
        return createErrorResponse(
          `Rate limit exceeded. You have made too many requests. Please try again in ${rateLimitInfo.retryAfter} seconds.`,
          `ចំនួនសំណើលើសកំណត់។ អ្នកបានធ្វើសំណើច្រើនពេក។ សូមព្យាយាមម្តងទៀតក្នុងរយៈពេល ${rateLimitInfo.retryAfter} វិនាទី។`,
          429,
          language,
          rateLimitInfo
        )
      }

      // Call the handler
      const response = await handler(...args)

      // Add rate limit headers to successful response
      return addRateLimitHeaders(response, rateLimitInfo)
    } catch (error) {
      console.error('Rate limit middleware error:', error)
      
      // On error, allow the request to proceed
      // This prevents middleware failures from blocking all traffic
      return await handler(...args)
    }
  }) as T
}

/**
 * Create a rate limiter with specific configuration
 * Useful for creating reusable rate limiters with different settings
 * 
 * Usage:
 * ```typescript
 * const strictRateLimit = createRateLimiter({ maxRequests: 10, windowSeconds: 60 })
 * 
 * export const POST = withAuth(
 *   strictRateLimit(async (req, { user }) => {
 *     return Response.json({ data: 'success' })
 *   })
 * )
 * ```
 */
export function createRateLimiter(options: RateLimitOptions) {
  return <T extends (...args: any[]) => Promise<Response> | Response>(handler: T): T => {
    return withRateLimit(handler, options)
  }
}

/**
 * Reset rate limit for a specific user or IP
 * Useful for testing or administrative purposes
 * 
 * @param identifier - User ID or IP address
 * @param type - Type of identifier ('user' or 'ip')
 * @param keyPrefix - Key prefix (default: 'ratelimit')
 */
export async function resetRateLimit(
  identifier: string,
  type: 'user' | 'ip' = 'user',
  keyPrefix: string = 'ratelimit'
): Promise<void> {
  try {
    const key = `${keyPrefix}:${type}:${identifier}`
    await redis.del(key)
  } catch (error) {
    console.error('Error resetting rate limit:', error)
    throw new Error('Failed to reset rate limit')
  }
}

/**
 * Get current rate limit status for a user or IP
 * Useful for monitoring and debugging
 * 
 * @param identifier - User ID or IP address
 * @param type - Type of identifier ('user' or 'ip')
 * @param keyPrefix - Key prefix (default: 'ratelimit')
 * @param maxRequests - Maximum requests allowed (default: 100)
 * @param windowSeconds - Time window in seconds (default: 60)
 * @returns Current rate limit information
 */
export async function getRateLimitStatus(
  identifier: string,
  type: 'user' | 'ip' = 'user',
  keyPrefix: string = 'ratelimit',
  maxRequests: number = 100,
  windowSeconds: number = 60
): Promise<RateLimitInfo> {
  try {
    const key = `${keyPrefix}:${type}:${identifier}`
    const now = Date.now()
    const windowStart = now - (windowSeconds * 1000)
    
    // Count requests in the current window
    const count = await redis.zcount(key, windowStart, now)
    
    const remaining = Math.max(0, maxRequests - count)
    const reset = Math.ceil((now + (windowSeconds * 1000)) / 1000)
    
    return {
      limit: maxRequests,
      remaining,
      reset,
      retryAfter: remaining === 0 ? windowSeconds : undefined,
    }
  } catch (error) {
    console.error('Error getting rate limit status:', error)
    throw new Error('Failed to get rate limit status')
  }
}

/**
 * Predefined rate limiters for common use cases
 */
export const rateLimiters = {
  /**
   * Standard rate limiter (100 req/min per Requirement 27)
   */
  standard: createRateLimiter({
    maxRequests: 100,
    windowSeconds: 60,
  }),

  /**
   * Strict rate limiter for sensitive endpoints (10 req/min)
   */
  strict: createRateLimiter({
    maxRequests: 10,
    windowSeconds: 60,
  }),

  /**
   * Lenient rate limiter for public endpoints (200 req/min)
   */
  lenient: createRateLimiter({
    maxRequests: 200,
    windowSeconds: 60,
  }),

  /**
   * Authentication rate limiter (5 attempts per 15 minutes)
   * Per Requirement 1 (account lockout after 5 failed attempts)
   */
  auth: createRateLimiter({
    maxRequests: 5,
    windowSeconds: 900, // 15 minutes
    perUser: false,
    perIP: true,
  }),

  /**
   * OTP rate limiter (3 requests per 5 minutes)
   */
  otp: createRateLimiter({
    maxRequests: 3,
    windowSeconds: 300, // 5 minutes
    perUser: false,
    perIP: true,
  }),
}
