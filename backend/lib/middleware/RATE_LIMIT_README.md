# Rate Limiting Middleware

## Overview

The rate limiting middleware implements request throttling as specified in **Requirement 27: API Performance and Scalability**. It protects the API from abuse by limiting the number of requests a user or IP address can make within a time window.

## Features

- ✅ **100 requests per minute per user** (default, per Requirement 27)
- ✅ **HTTP 429 response** when rate limit is exceeded
- ✅ **Retry-After header** indicating when to retry
- ✅ **Redis-based tracking** for distributed rate limiting
- ✅ **Sliding window algorithm** for accurate request counting
- ✅ **Per-user rate limiting** (requires authentication)
- ✅ **Per-IP rate limiting** (fallback for unauthenticated requests)
- ✅ **Configurable limits** and time windows
- ✅ **Rate limit headers** (X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset)
- ✅ **Multi-language support** (Khmer/English error messages)
- ✅ **Graceful degradation** on Redis failures
- ✅ **Skip conditions** for bypassing rate limits

## Installation

The middleware is already installed and ready to use. It requires:
- Redis connection (configured in `lib/redis.ts`)
- i18n support (configured in `lib/i18n.ts`)

## Basic Usage

### With Authentication (Per-User Rate Limiting)

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRateLimit(async (req, { user }) => {
    // Your handler logic here
    return Response.json({ data: 'success' })
  })
)
```

### Without Authentication (Per-IP Rate Limiting)

```typescript
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const POST = withRateLimit(
  async (req) => {
    // Your handler logic here
    return Response.json({ data: 'success' })
  },
  { perUser: false, perIP: true }
)
```

## Configuration Options

```typescript
interface RateLimitOptions {
  maxRequests?: number        // Default: 100
  windowSeconds?: number      // Default: 60 (1 minute)
  perUser?: boolean          // Default: true
  perIP?: boolean            // Default: true
  keyPrefix?: string         // Default: 'ratelimit'
  skip?: (req, user?) => boolean | Promise<boolean>
}
```

## Custom Configuration

### Strict Rate Limiting (10 requests per minute)

```typescript
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const POST = withRateLimit(
  async (req) => {
    return Response.json({ data: 'success' })
  },
  {
    maxRequests: 10,
    windowSeconds: 60,
  }
)
```

### Lenient Rate Limiting (200 requests per minute)

```typescript
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withRateLimit(
  async (req) => {
    return Response.json({ data: 'success' })
  },
  {
    maxRequests: 200,
    windowSeconds: 60,
  }
)
```

### Skip Rate Limiting for Specific Users

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRateLimit(
    async (req, { user }) => {
      return Response.json({ data: 'success' })
    },
    {
      skip: async (req, user) => {
        // Skip rate limiting for premium users
        return user?.subscriptionTier === 'PREMIUM'
      }
    }
  )
)
```

## Predefined Rate Limiters

The middleware includes several predefined rate limiters for common use cases:

### Standard Rate Limiter (100 req/min)

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  rateLimiters.standard(async (req, { user }) => {
    return Response.json({ data: 'success' })
  })
)
```

### Strict Rate Limiter (10 req/min)

For sensitive endpoints like password changes:

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const POST = withAuth(
  rateLimiters.strict(async (req, { user }) => {
    // Change password logic
    return Response.json({ success: true })
  })
)
```

### Lenient Rate Limiter (200 req/min)

For public endpoints with higher traffic:

```typescript
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const GET = rateLimiters.lenient(async (req) => {
  return Response.json({ data: 'public data' })
})
```

### Authentication Rate Limiter (5 req/15min)

For login endpoints (per Requirement 1 - account lockout):

```typescript
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const POST = rateLimiters.auth(async (req) => {
  // Login logic
  return Response.json({ token: 'jwt-token' })
})
```

### OTP Rate Limiter (3 req/5min)

For OTP sending endpoints:

```typescript
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const POST = rateLimiters.otp(async (req) => {
  // Send OTP logic
  return Response.json({ success: true })
})
```

## Response Headers

The middleware adds the following headers to all responses:

- `X-RateLimit-Limit`: Maximum requests allowed in the window
- `X-RateLimit-Remaining`: Remaining requests in the current window
- `X-RateLimit-Reset`: Unix timestamp when the rate limit resets
- `Retry-After`: (Only when rate limit exceeded) Seconds until rate limit resets

## Error Response

When rate limit is exceeded, the API returns HTTP 429 with:

```json
{
  "error": {
    "message": "Rate limit exceeded. You have made too many requests. Please try again in 60 seconds.",
    "messageEn": "Rate limit exceeded. You have made too many requests. Please try again in 60 seconds.",
    "messageKm": "ចំនួនសំណើលើសកំណត់។ អ្នកបានធ្វើសំណើច្រើនពេក។ សូមព្យាយាមម្តងទៀតក្នុងរយៈពេល 60 វិនាទី។",
    "code": "RATE_LIMIT_EXCEEDED",
    "retryAfter": 60
  }
}
```

## Utility Functions

### Reset Rate Limit

```typescript
import { resetRateLimit } from '@/lib/middleware/rateLimit'

// Reset rate limit for a user
await resetRateLimit('user-123', 'user')

// Reset rate limit for an IP
await resetRateLimit('192.168.1.1', 'ip')
```

### Get Rate Limit Status

```typescript
import { getRateLimitStatus } from '@/lib/middleware/rateLimit'

const status = await getRateLimitStatus('user-123', 'user')
console.log(status)
// {
//   limit: 100,
//   remaining: 50,
//   reset: 1234567890,
//   retryAfter: undefined
// }
```

### Create Custom Rate Limiter

```typescript
import { createRateLimiter } from '@/lib/middleware/rateLimit'

const customRateLimiter = createRateLimiter({
  maxRequests: 50,
  windowSeconds: 120,
})

export const POST = customRateLimiter(async (req) => {
  return Response.json({ data: 'success' })
})
```

## How It Works

### Sliding Window Algorithm

The middleware uses a **sliding window** algorithm for accurate rate limiting:

1. Each request is stored in a Redis sorted set with its timestamp
2. Old requests outside the time window are automatically removed
3. The current request count is checked against the limit
4. If under the limit, the request proceeds; otherwise, HTTP 429 is returned

This approach is more accurate than fixed windows because it prevents burst traffic at window boundaries.

### Redis Data Structure

```
Key: ratelimit:user:{userId} or ratelimit:ip:{ipAddress}
Type: Sorted Set (ZSET)
Members: Request timestamps
Score: Unix timestamp in milliseconds
TTL: windowSeconds
```

### IP Address Detection

The middleware extracts the client IP from the following headers (in order):
1. `cf-connecting-ip` (Cloudflare)
2. `x-real-ip` (Nginx)
3. `x-forwarded-for` (Standard proxy header)

## Integration with Other Middleware

### With Authentication

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRateLimit(async (req, { user }) => {
    // Both authentication and rate limiting are enforced
    return Response.json({ userId: user.id })
  })
)
```

### With RBAC

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRBAC(
    withRateLimit(async (req, { user, checkPermission }) => {
      // Authentication, RBAC, and rate limiting are all enforced
      return Response.json({ data: 'success' })
    }),
    { requiredRole: 'DOCTOR' }
  )
)
```

## Error Handling

The middleware includes graceful error handling:

- **Redis connection failures**: Requests are allowed to proceed (fail-open)
- **Redis transaction errors**: Requests are allowed to proceed
- **Middleware errors**: Logged and requests proceed

This ensures that Redis issues don't cause complete API outages.

## Performance Considerations

- **Redis operations**: 4 Redis commands per request (ZREMRANGEBYSCORE, ZADD, ZCARD, EXPIRE)
- **Network latency**: Minimal impact due to Redis pipelining (MULTI/EXEC)
- **Memory usage**: Sorted sets are automatically cleaned up via TTL
- **Scalability**: Supports distributed deployments with shared Redis

## Testing

The middleware includes comprehensive tests covering:
- ✅ Requests within rate limit
- ✅ Requests exceeding rate limit
- ✅ Per-user rate limiting
- ✅ Per-IP rate limiting
- ✅ Skip conditions
- ✅ Redis error handling
- ✅ Multi-language error messages
- ✅ IP address extraction
- ✅ Sliding window behavior
- ✅ Integration with authentication

Run tests:
```bash
npm test -- rateLimit.test.ts
```

## Monitoring

To monitor rate limiting in production:

```typescript
import { getRateLimitStatus } from '@/lib/middleware/rateLimit'

// Check rate limit status for a user
const status = await getRateLimitStatus('user-123', 'user')

if (status.remaining < 10) {
  console.warn(`User ${userId} is approaching rate limit: ${status.remaining} requests remaining`)
}
```

## Best Practices

1. **Use per-user rate limiting** for authenticated endpoints
2. **Use per-IP rate limiting** for public endpoints
3. **Apply stricter limits** to sensitive endpoints (login, OTP, password reset)
4. **Apply lenient limits** to read-only public endpoints
5. **Skip rate limiting** for admin users or internal services
6. **Monitor rate limit headers** in client applications
7. **Implement exponential backoff** in clients when receiving 429 responses
8. **Log rate limit violations** for security monitoring

## Troubleshooting

### Rate limit not working

1. Check Redis connection: `redis-cli ping`
2. Verify environment variable: `REDIS_URL`
3. Check middleware order (rate limit should be after auth)
4. Verify Redis key exists: `redis-cli KEYS ratelimit:*`

### Rate limit too strict

1. Increase `maxRequests` or `windowSeconds`
2. Use predefined lenient rate limiter
3. Add skip condition for specific users

### Rate limit too lenient

1. Decrease `maxRequests` or `windowSeconds`
2. Use predefined strict rate limiter
3. Apply per-IP rate limiting in addition to per-user

## Related Requirements

- **Requirement 27**: API Performance and Scalability
  - 100 requests per minute per user
  - HTTP 429 with retry-after header
- **Requirement 1**: User Authentication and Authorization
  - Account lockout after 5 failed attempts (uses auth rate limiter)

## Related Files

- `lib/middleware/rateLimit.ts` - Main implementation
- `lib/middleware/rateLimit.test.ts` - Test suite
- `lib/redis.ts` - Redis client configuration
- `lib/i18n.ts` - Multi-language support

## Support

For issues or questions about rate limiting:
1. Check this documentation
2. Review test cases in `rateLimit.test.ts`
3. Check Redis logs for connection issues
4. Review API logs for rate limit violations
