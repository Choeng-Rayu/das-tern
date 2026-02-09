# Rate Limiting Middleware - Quick Reference

## Import

```typescript
import { withRateLimit, rateLimiters, createRateLimiter } from '@/lib/middleware/rateLimit'
```

## Basic Usage

### Authenticated Endpoint (Per-User)
```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRateLimit(async (req, { user }) => {
    return Response.json({ data: 'success' })
  })
)
```

### Public Endpoint (Per-IP)
```typescript
export const POST = withRateLimit(
  async (req) => {
    return Response.json({ data: 'success' })
  },
  { perUser: false, perIP: true }
)
```

## Predefined Rate Limiters

| Rate Limiter | Limit | Window | Use Case |
|--------------|-------|--------|----------|
| `rateLimiters.standard` | 100 req | 1 min | Default for most endpoints |
| `rateLimiters.strict` | 10 req | 1 min | Sensitive operations |
| `rateLimiters.lenient` | 200 req | 1 min | Public read-only endpoints |
| `rateLimiters.auth` | 5 req | 15 min | Login/authentication |
| `rateLimiters.otp` | 3 req | 5 min | OTP sending |

### Usage Example
```typescript
import { withAuth } from '@/lib/middleware/auth'
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const POST = withAuth(
  rateLimiters.strict(async (req, { user }) => {
    // Sensitive operation
    return Response.json({ success: true })
  })
)
```

## Configuration Options

```typescript
{
  maxRequests: 100,        // Max requests in window
  windowSeconds: 60,       // Time window in seconds
  perUser: true,          // Use user ID for rate limiting
  perIP: true,            // Use IP address for rate limiting
  keyPrefix: 'ratelimit', // Redis key prefix
  skip: (req, user) => boolean // Skip condition
}
```

## Custom Rate Limiter

```typescript
const customRateLimiter = createRateLimiter({
  maxRequests: 50,
  windowSeconds: 120,
})

export const POST = customRateLimiter(async (req) => {
  return Response.json({ data: 'success' })
})
```

## Skip Conditions

```typescript
export const GET = withAuth(
  withRateLimit(
    async (req, { user }) => {
      return Response.json({ data: 'success' })
    },
    {
      skip: async (req, user) => {
        // Skip for premium users
        return user?.subscriptionTier === 'PREMIUM'
      }
    }
  )
)
```

## Response Headers

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Maximum requests allowed |
| `X-RateLimit-Remaining` | Remaining requests |
| `X-RateLimit-Reset` | Unix timestamp when limit resets |
| `Retry-After` | Seconds until retry (only on 429) |

## Error Response (HTTP 429)

```json
{
  "error": {
    "message": "Rate limit exceeded...",
    "messageEn": "Rate limit exceeded...",
    "messageKm": "ចំនួនសំណើលើសកំណត់...",
    "code": "RATE_LIMIT_EXCEEDED",
    "retryAfter": 60
  }
}
```

## Utility Functions

### Reset Rate Limit
```typescript
import { resetRateLimit } from '@/lib/middleware/rateLimit'

await resetRateLimit('user-123', 'user')
await resetRateLimit('192.168.1.1', 'ip')
```

### Get Rate Limit Status
```typescript
import { getRateLimitStatus } from '@/lib/middleware/rateLimit'

const status = await getRateLimitStatus('user-123', 'user')
// { limit: 100, remaining: 50, reset: 1234567890 }
```

## Middleware Stacking

```typescript
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRBAC(
    withRateLimit(async (req, { user, checkPermission }) => {
      return Response.json({ data: 'success' })
    }),
    { requiredRole: 'DOCTOR' }
  )
)
```

## Common Patterns

### Login Endpoint
```typescript
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const POST = rateLimiters.auth(async (req) => {
  // Login logic (5 attempts per 15 minutes)
  return Response.json({ token: 'jwt' })
})
```

### OTP Endpoint
```typescript
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const POST = rateLimiters.otp(async (req) => {
  // Send OTP (3 attempts per 5 minutes)
  return Response.json({ success: true })
})
```

### Password Reset
```typescript
import { withAuth } from '@/lib/middleware/auth'
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const POST = withAuth(
  rateLimiters.strict(async (req, { user }) => {
    // Password reset (10 attempts per minute)
    return Response.json({ success: true })
  })
)
```

### Public API
```typescript
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const GET = rateLimiters.lenient(async (req) => {
  // Public data (200 requests per minute)
  return Response.json({ data: 'public' })
})
```

## Testing

```bash
npm test -- rateLimit.test.ts
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Rate limit not working | Check Redis connection |
| Too strict | Increase `maxRequests` or use lenient limiter |
| Too lenient | Decrease `maxRequests` or use strict limiter |
| Redis errors | Check `REDIS_URL` environment variable |

## Requirements

- ✅ Requirement 27: 100 requests per minute per user
- ✅ HTTP 429 with Retry-After header
- ✅ Redis for tracking
- ✅ Per-user and per-IP support
