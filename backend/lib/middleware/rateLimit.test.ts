import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { NextRequest } from 'next/server'
import {
  withRateLimit,
  createRateLimiter,
  resetRateLimit,
  getRateLimitStatus,
  rateLimiters,
} from './rateLimit'
import { redis } from '../redis'
import { AuthContext, AuthUser } from './auth'

// Mock Redis
vi.mock('../redis', () => ({
  redis: {
    multi: vi.fn(),
    del: vi.fn(),
    zcount: vi.fn(),
  },
}))

// Mock i18n
vi.mock('../i18n', () => ({
  translate: vi.fn((key: string) => key),
  getLanguageFromHeader: vi.fn(() => 'english'),
}))

describe('Rate Limiting Middleware', () => {
  let mockRequest: NextRequest
  let mockUser: AuthUser
  let mockContext: AuthContext

  beforeEach(() => {
    // Reset all mocks
    vi.clearAllMocks()

    // Create mock request
    mockRequest = new NextRequest('http://localhost:3000/api/test', {
      method: 'GET',
      headers: {
        'x-forwarded-for': '192.168.1.1',
      },
    })

    // Create mock user
    mockUser = {
      id: 'user-123',
      role: 'PATIENT',
      language: 'english',
      theme: 'LIGHT',
      subscriptionTier: 'FREEMIUM',
    }

    // Create mock context
    mockContext = {
      user: mockUser,
      req: mockRequest,
    }
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('withRateLimit', () => {
    it('should allow requests within rate limit', async () => {
      // Mock Redis to return count below limit
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 0], // zremrangebyscore
          [null, 1], // zadd
          [null, 50], // zcard - 50 requests
          [null, 1], // expire
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        maxRequests: 100,
        windowSeconds: 60,
      })

      const response = await rateLimitedHandler(mockRequest, mockContext)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data).toEqual({ success: true })
      expect(handler).toHaveBeenCalledWith(mockRequest, mockContext)

      // Check rate limit headers
      expect(response.headers.get('X-RateLimit-Limit')).toBe('100')
      expect(response.headers.get('X-RateLimit-Remaining')).toBe('50')
      expect(response.headers.get('X-RateLimit-Reset')).toBeTruthy()
    })

    it('should block requests when rate limit is exceeded', async () => {
      // Mock Redis to return count at limit
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 0], // zremrangebyscore
          [null, 1], // zadd
          [null, 100], // zcard - 100 requests (at limit)
          [null, 1], // expire
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        maxRequests: 100,
        windowSeconds: 60,
      })

      const response = await rateLimitedHandler(mockRequest, mockContext)
      const data = await response.json()

      expect(response.status).toBe(429)
      expect(data.error.code).toBe('RATE_LIMIT_EXCEEDED')
      expect(data.error.retryAfter).toBe(60)
      expect(handler).not.toHaveBeenCalled()

      // Check rate limit headers
      expect(response.headers.get('X-RateLimit-Limit')).toBe('100')
      expect(response.headers.get('X-RateLimit-Remaining')).toBe('0')
      expect(response.headers.get('Retry-After')).toBe('60')
    })

    it('should use per-user rate limiting when authenticated', async () => {
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 0],
          [null, 1],
          [null, 10],
          [null, 1],
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        maxRequests: 100,
        windowSeconds: 60,
        perUser: true,
      })

      await rateLimitedHandler(mockRequest, mockContext)

      // Verify Redis was called with user-based key
      expect(mockMulti.zremrangebyscore).toHaveBeenCalled()
      expect(mockMulti.zadd).toHaveBeenCalled()
    })

    it('should use per-IP rate limiting when not authenticated', async () => {
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 0],
          [null, 1],
          [null, 10],
          [null, 1],
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        maxRequests: 100,
        windowSeconds: 60,
        perUser: false,
        perIP: true,
      })

      // Call without context (unauthenticated)
      await rateLimitedHandler(mockRequest)

      // Verify Redis was called
      expect(mockMulti.zremrangebyscore).toHaveBeenCalled()
      expect(mockMulti.zadd).toHaveBeenCalled()
    })

    it('should skip rate limiting when skip function returns true', async () => {
      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        maxRequests: 100,
        windowSeconds: 60,
        skip: async (req, user) => user?.role === 'PATIENT',
      })

      const response = await rateLimitedHandler(mockRequest, mockContext)

      expect(response.status).toBe(200)
      expect(handler).toHaveBeenCalled()
      expect(redis.multi).not.toHaveBeenCalled()
    })

    it('should handle Redis errors gracefully', async () => {
      // Mock Redis to throw error
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockRejectedValue(new Error('Redis connection failed')),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        maxRequests: 100,
        windowSeconds: 60,
      })

      const response = await rateLimitedHandler(mockRequest, mockContext)

      // Should allow request on Redis error (graceful degradation)
      expect(response.status).toBe(200)
      expect(handler).toHaveBeenCalled()
    })

    it('should return Khmer error message when language is Khmer', async () => {
      // Mock language detection to return Khmer
      const { getLanguageFromHeader } = await import('../i18n')
      ;(getLanguageFromHeader as any).mockReturnValue('khmer')

      // Mock Redis to return count at limit
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 0],
          [null, 1],
          [null, 100],
          [null, 1],
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        maxRequests: 100,
        windowSeconds: 60,
      })

      const response = await rateLimitedHandler(mockRequest, mockContext)
      const data = await response.json()

      expect(response.status).toBe(429)
      expect(data.error.messageKm).toContain('ចំនួនសំណើលើសកំណត់')
    })

    it('should extract IP from various headers', async () => {
      const testCases = [
        { header: 'cf-connecting-ip', value: '1.2.3.4' },
        { header: 'x-real-ip', value: '5.6.7.8' },
        { header: 'x-forwarded-for', value: '9.10.11.12, 13.14.15.16' },
      ]

      for (const testCase of testCases) {
        const request = new NextRequest('http://localhost:3000/api/test', {
          method: 'GET',
          headers: {
            [testCase.header]: testCase.value,
          },
        })

        const mockMulti = {
          zremrangebyscore: vi.fn().mockReturnThis(),
          zadd: vi.fn().mockReturnThis(),
          zcard: vi.fn().mockReturnThis(),
          expire: vi.fn().mockReturnThis(),
          exec: vi.fn().mockResolvedValue([
            [null, 0],
            [null, 1],
            [null, 10],
            [null, 1],
          ]),
        }
        ;(redis.multi as any).mockReturnValue(mockMulti)

        const handler = vi.fn().mockResolvedValue(
          new Response(JSON.stringify({ success: true }), { status: 200 })
        )

        const rateLimitedHandler = withRateLimit(handler, {
          perUser: false,
          perIP: true,
        })

        await rateLimitedHandler(request)

        expect(mockMulti.zadd).toHaveBeenCalled()
      }
    })
  })

  describe('createRateLimiter', () => {
    it('should create a reusable rate limiter with custom config', async () => {
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 0],
          [null, 1],
          [null, 5],
          [null, 1],
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const customRateLimiter = createRateLimiter({
        maxRequests: 10,
        windowSeconds: 30,
      })

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = customRateLimiter(handler)
      const response = await rateLimitedHandler(mockRequest, mockContext)

      expect(response.status).toBe(200)
      expect(response.headers.get('X-RateLimit-Limit')).toBe('10')
    })
  })

  describe('resetRateLimit', () => {
    it('should reset rate limit for a user', async () => {
      ;(redis.del as any).mockResolvedValue(1)

      await resetRateLimit('user-123', 'user')

      expect(redis.del).toHaveBeenCalledWith('ratelimit:user:user-123')
    })

    it('should reset rate limit for an IP', async () => {
      ;(redis.del as any).mockResolvedValue(1)

      await resetRateLimit('192.168.1.1', 'ip')

      expect(redis.del).toHaveBeenCalledWith('ratelimit:ip:192.168.1.1')
    })

    it('should handle Redis errors', async () => {
      ;(redis.del as any).mockRejectedValue(new Error('Redis error'))

      await expect(resetRateLimit('user-123', 'user')).rejects.toThrow(
        'Failed to reset rate limit'
      )
    })
  })

  describe('getRateLimitStatus', () => {
    it('should return current rate limit status', async () => {
      ;(redis.zcount as any).mockResolvedValue(50)

      const status = await getRateLimitStatus('user-123', 'user', 'ratelimit', 100, 60)

      expect(status.limit).toBe(100)
      expect(status.remaining).toBe(50)
      expect(status.reset).toBeGreaterThan(Date.now() / 1000)
      expect(status.retryAfter).toBeUndefined()
    })

    it('should return retryAfter when limit is exceeded', async () => {
      ;(redis.zcount as any).mockResolvedValue(100)

      const status = await getRateLimitStatus('user-123', 'user', 'ratelimit', 100, 60)

      expect(status.remaining).toBe(0)
      expect(status.retryAfter).toBe(60)
    })

    it('should handle Redis errors', async () => {
      ;(redis.zcount as any).mockRejectedValue(new Error('Redis error'))

      await expect(
        getRateLimitStatus('user-123', 'user', 'ratelimit', 100, 60)
      ).rejects.toThrow('Failed to get rate limit status')
    })
  })

  describe('Predefined rate limiters', () => {
    it('should have standard rate limiter (100 req/min)', () => {
      expect(rateLimiters.standard).toBeDefined()
    })

    it('should have strict rate limiter (10 req/min)', () => {
      expect(rateLimiters.strict).toBeDefined()
    })

    it('should have lenient rate limiter (200 req/min)', () => {
      expect(rateLimiters.lenient).toBeDefined()
    })

    it('should have auth rate limiter (5 req/15min)', () => {
      expect(rateLimiters.auth).toBeDefined()
    })

    it('should have OTP rate limiter (3 req/5min)', () => {
      expect(rateLimiters.otp).toBeDefined()
    })
  })

  describe('Sliding window behavior', () => {
    it('should remove old requests outside the window', async () => {
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 5], // 5 old requests removed
          [null, 1],
          [null, 50],
          [null, 1],
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        maxRequests: 100,
        windowSeconds: 60,
      })

      await rateLimitedHandler(mockRequest, mockContext)

      // Verify old requests were removed
      expect(mockMulti.zremrangebyscore).toHaveBeenCalled()
    })
  })

  describe('Integration with authentication', () => {
    it('should work with authenticated requests', async () => {
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 0],
          [null, 1],
          [null, 10],
          [null, 1],
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ userId: mockUser.id }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler)

      const response = await rateLimitedHandler(mockRequest, mockContext)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.userId).toBe('user-123')
    })

    it('should work with unauthenticated requests', async () => {
      const mockMulti = {
        zremrangebyscore: vi.fn().mockReturnThis(),
        zadd: vi.fn().mockReturnThis(),
        zcard: vi.fn().mockReturnThis(),
        expire: vi.fn().mockReturnThis(),
        exec: vi.fn().mockResolvedValue([
          [null, 0],
          [null, 1],
          [null, 10],
          [null, 1],
        ]),
      }
      ;(redis.multi as any).mockReturnValue(mockMulti)

      const handler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ public: true }), { status: 200 })
      )

      const rateLimitedHandler = withRateLimit(handler, {
        perUser: false,
        perIP: true,
      })

      const response = await rateLimitedHandler(mockRequest)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.public).toBe(true)
    })
  })
})
