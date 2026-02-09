# Rate Limiting Middleware - Usage Examples

## Table of Contents
1. [Basic Examples](#basic-examples)
2. [Authentication Endpoints](#authentication-endpoints)
3. [User Profile Endpoints](#user-profile-endpoints)
4. [Prescription Endpoints](#prescription-endpoints)
5. [Doctor Endpoints](#doctor-endpoints)
6. [Public Endpoints](#public-endpoints)
7. [Advanced Patterns](#advanced-patterns)

## Basic Examples

### Simple Rate Limited Endpoint

```typescript
// app/api/test/route.ts
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withRateLimit(async (req) => {
  return Response.json({ message: 'Hello World' })
})
```

### With Custom Configuration

```typescript
// app/api/test/route.ts
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withRateLimit(
  async (req) => {
    return Response.json({ message: 'Hello World' })
  },
  {
    maxRequests: 50,
    windowSeconds: 60,
  }
)
```

## Authentication Endpoints

### Login Endpoint (5 attempts per 15 minutes)

```typescript
// app/api/auth/login/route.ts
import { rateLimiters } from '@/lib/middleware/rateLimit'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

export const POST = rateLimiters.auth(async (req) => {
  const { identifier, password } = await req.json()

  // Find user
  const user = await prisma.user.findFirst({
    where: {
      OR: [
        { phoneNumber: identifier },
        { email: identifier },
      ],
    },
  })

  if (!user || !await bcrypt.compare(password, user.passwordHash)) {
    return Response.json(
      { error: 'Invalid credentials' },
      { status: 401 }
    )
  }

  // Generate JWT token
  const token = generateToken(user)

  return Response.json({ token, user })
})
```

### OTP Send Endpoint (3 attempts per 5 minutes)

```typescript
// app/api/auth/otp/send/route.ts
import { rateLimiters } from '@/lib/middleware/rateLimit'
import { sendSMS } from '@/lib/sms'

export const POST = rateLimiters.otp(async (req) => {
  const { phoneNumber } = await req.json()

  // Generate OTP
  const otp = Math.floor(1000 + Math.random() * 9000).toString()

  // Store OTP in Redis
  await redis.setex(`otp:${phoneNumber}`, 300, otp)

  // Send SMS
  await sendSMS(phoneNumber, `Your OTP is: ${otp}`)

  return Response.json({
    message: 'OTP sent successfully',
    expiresIn: 300,
  })
})
```

### OTP Verify Endpoint

```typescript
// app/api/auth/otp/verify/route.ts
import { rateLimiters } from '@/lib/middleware/rateLimit'
import { redis } from '@/lib/redis'

export const POST = rateLimiters.auth(async (req) => {
  const { phoneNumber, otp } = await req.json()

  // Get stored OTP
  const storedOTP = await redis.get(`otp:${phoneNumber}`)

  if (!storedOTP || storedOTP !== otp) {
    return Response.json(
      { error: 'Invalid or expired OTP' },
      { status: 401 }
    )
  }

  // Delete OTP
  await redis.del(`otp:${phoneNumber}`)

  // Create user session
  const token = generateToken({ phoneNumber })

  return Response.json({ token })
})
```

### Patient Registration

```typescript
// app/api/auth/register/patient/route.ts
import { rateLimiters } from '@/lib/middleware/rateLimit'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

export const POST = rateLimiters.strict(async (req) => {
  const {
    firstName,
    lastName,
    phoneNumber,
    password,
    pinCode,
    dateOfBirth,
  } = await req.json()

  // Validate phone number format
  if (!phoneNumber.startsWith('+855')) {
    return Response.json(
      { error: 'Phone number must start with +855' },
      { status: 400 }
    )
  }

  // Hash password and PIN
  const passwordHash = await bcrypt.hash(password, 10)
  const pinCodeHash = await bcrypt.hash(pinCode, 10)

  // Create user
  const user = await prisma.user.create({
    data: {
      firstName,
      lastName,
      phoneNumber,
      passwordHash,
      pinCodeHash,
      dateOfBirth: new Date(dateOfBirth),
      role: 'PATIENT',
    },
  })

  return Response.json({
    message: 'Registration successful',
    requiresOTP: true,
  })
})
```

## User Profile Endpoints

### Get Profile (Standard Rate Limit)

```typescript
// app/api/users/profile/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'
import { prisma } from '@/lib/prisma'

export const GET = withAuth(
  withRateLimit(async (req, { user }) => {
    const profile = await prisma.user.findUnique({
      where: { id: user.id },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        phoneNumber: true,
        email: true,
        language: true,
        theme: true,
        subscriptionTier: true,
      },
    })

    return Response.json({ profile })
  })
)
```

### Update Profile (Strict Rate Limit)

```typescript
// app/api/users/profile/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { rateLimiters } from '@/lib/middleware/rateLimit'
import { prisma } from '@/lib/prisma'

export const PATCH = withAuth(
  rateLimiters.strict(async (req, { user }) => {
    const updates = await req.json()

    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: updates,
    })

    return Response.json({ user: updatedUser })
  })
)
```

### Change Password (Very Strict)

```typescript
// app/api/users/password/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { createRateLimiter } from '@/lib/middleware/rateLimit'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

const veryStrictRateLimit = createRateLimiter({
  maxRequests: 3,
  windowSeconds: 300, // 5 minutes
})

export const POST = withAuth(
  veryStrictRateLimit(async (req, { user }) => {
    const { currentPassword, newPassword } = await req.json()

    // Verify current password
    const dbUser = await prisma.user.findUnique({
      where: { id: user.id },
    })

    if (!await bcrypt.compare(currentPassword, dbUser.passwordHash)) {
      return Response.json(
        { error: 'Current password is incorrect' },
        { status: 401 }
      )
    }

    // Update password
    const newPasswordHash = await bcrypt.hash(newPassword, 10)
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: newPasswordHash },
    })

    return Response.json({ message: 'Password updated successfully' })
  })
)
```

## Prescription Endpoints

### Create Prescription (Standard Rate Limit)

```typescript
// app/api/prescriptions/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'
import { withRateLimit } from '@/lib/middleware/rateLimit'
import { prisma } from '@/lib/prisma'

export const POST = withAuth(
  withRBAC(
    withRateLimit(async (req, { user, checkPermission }) => {
      const { patientId, medications, symptoms } = await req.json()

      // Check permission
      const hasPermission = await checkPermission(patientId, 'ALLOWED')
      if (!hasPermission) {
        return Response.json(
          { error: 'Access denied' },
          { status: 403 }
        )
      }

      // Create prescription
      const prescription = await prisma.prescription.create({
        data: {
          patientId,
          doctorId: user.id,
          symptoms,
          status: 'DRAFT',
          currentVersion: 1,
          medications: {
            create: medications,
          },
        },
        include: {
          medications: true,
        },
      })

      return Response.json({ prescription })
    }),
    { requiredRole: 'DOCTOR' }
  )
)
```

### Get Prescriptions (Standard Rate Limit)

```typescript
// app/api/prescriptions/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'
import { prisma } from '@/lib/prisma'

export const GET = withAuth(
  withRateLimit(async (req, { user }) => {
    const { searchParams } = req.nextUrl
    const status = searchParams.get('status')
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '50')

    const where = user.role === 'PATIENT'
      ? { patientId: user.id }
      : { doctorId: user.id }

    if (status) {
      where.status = status
    }

    const [prescriptions, total] = await Promise.all([
      prisma.prescription.findMany({
        where,
        include: {
          medications: true,
        },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.prescription.count({ where }),
    ])

    return Response.json({
      prescriptions,
      total,
      page,
      pages: Math.ceil(total / limit),
    })
  })
)
```

## Doctor Endpoints

### Get Patient List (Standard Rate Limit)

```typescript
// app/api/doctor/patients/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRBAC } from '@/lib/middleware/rbac'
import { withRateLimit } from '@/lib/middleware/rateLimit'
import { prisma } from '@/lib/prisma'

export const GET = withAuth(
  withRBAC(
    withRateLimit(async (req, { user }) => {
      // Get all patients connected to this doctor
      const connections = await prisma.connection.findMany({
        where: {
          OR: [
            { initiatorId: user.id, status: 'ACCEPTED' },
            { recipientId: user.id, status: 'ACCEPTED' },
          ],
        },
        include: {
          initiator: true,
          recipient: true,
        },
      })

      // Extract patient information
      const patients = connections.map(conn => {
        const patient = conn.initiatorId === user.id
          ? conn.recipient
          : conn.initiator
        
        return {
          id: patient.id,
          name: `${patient.firstName} ${patient.lastName}`,
          phoneNumber: patient.phoneNumber,
          // Calculate adherence percentage
          adherencePercentage: 85, // TODO: Calculate from dose events
        }
      })

      return Response.json({ patients })
    }),
    { requiredRole: 'DOCTOR' }
  )
)
```

## Public Endpoints

### Health Check (Lenient Rate Limit)

```typescript
// app/api/health/route.ts
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const GET = rateLimiters.lenient(async (req) => {
  return Response.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
  })
})
```

### Public Documentation (Lenient Rate Limit)

```typescript
// app/api/docs/route.ts
import { rateLimiters } from '@/lib/middleware/rateLimit'

export const GET = rateLimiters.lenient(async (req) => {
  return Response.json({
    version: '1.0.0',
    endpoints: [
      '/api/auth/login',
      '/api/auth/register',
      '/api/prescriptions',
    ],
  })
})
```

## Advanced Patterns

### Skip Rate Limiting for Premium Users

```typescript
// app/api/premium/feature/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRateLimit(
    async (req, { user }) => {
      return Response.json({ data: 'premium feature' })
    },
    {
      skip: async (req, user) => {
        return user?.subscriptionTier === 'PREMIUM' ||
               user?.subscriptionTier === 'FAMILY_PREMIUM'
      }
    }
  )
)
```

### Different Limits Based on User Role

```typescript
// app/api/data/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRateLimit(
    async (req, { user }) => {
      return Response.json({ data: 'success' })
    },
    {
      maxRequests: 100,
      windowSeconds: 60,
      skip: async (req, user) => {
        // Doctors get higher limits
        if (user?.role === 'DOCTOR') {
          // Apply separate rate limit for doctors
          return false // Don't skip, but could implement custom logic
        }
        return false
      }
    }
  )
)
```

### Multiple Rate Limiters

```typescript
// app/api/sensitive/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { createRateLimiter } from '@/lib/middleware/rateLimit'

// Per-user rate limit
const perUserLimit = createRateLimiter({
  maxRequests: 10,
  windowSeconds: 60,
  perUser: true,
  perIP: false,
})

// Per-IP rate limit (additional layer)
const perIPLimit = createRateLimiter({
  maxRequests: 50,
  windowSeconds: 60,
  perUser: false,
  perIP: true,
})

export const POST = withAuth(
  perUserLimit(
    perIPLimit(async (req, { user }) => {
      // Both rate limits are enforced
      return Response.json({ data: 'success' })
    })
  )
)
```

### Dynamic Rate Limits Based on Time of Day

```typescript
// app/api/dynamic/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit } from '@/lib/middleware/rateLimit'

export const GET = withAuth(
  withRateLimit(
    async (req, { user }) => {
      return Response.json({ data: 'success' })
    },
    {
      maxRequests: 100,
      windowSeconds: 60,
      skip: async (req, user) => {
        // Skip rate limiting during off-peak hours (midnight to 6am)
        const hour = new Date().getHours()
        return hour >= 0 && hour < 6
      }
    }
  )
)
```

### Rate Limit with Custom Error Response

```typescript
// app/api/custom-error/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { withRateLimit, getRateLimitStatus } from '@/lib/middleware/rateLimit'

export const GET = withAuth(async (req, { user }) => {
  // Check rate limit manually
  const status = await getRateLimitStatus(user.id, 'user')

  if (status.remaining === 0) {
    return Response.json(
      {
        error: 'Custom rate limit message',
        retryAfter: status.retryAfter,
        limit: status.limit,
      },
      {
        status: 429,
        headers: {
          'Retry-After': status.retryAfter?.toString() || '60',
        },
      }
    )
  }

  // Continue with normal logic
  return Response.json({ data: 'success' })
})
```

### Monitoring Rate Limit Usage

```typescript
// app/api/admin/rate-limits/route.ts
import { withAuth } from '@/lib/middleware/auth'
import { getRateLimitStatus } from '@/lib/middleware/rateLimit'

export const GET = withAuth(async (req, { user }) => {
  // Only allow admin users
  if (user.role !== 'ADMIN') {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }

  const userId = req.nextUrl.searchParams.get('userId')
  
  if (!userId) {
    return Response.json({ error: 'userId required' }, { status: 400 })
  }

  const status = await getRateLimitStatus(userId, 'user')

  return Response.json({
    userId,
    rateLimit: status,
    percentageUsed: ((status.limit - status.remaining) / status.limit) * 100,
  })
})
```

## Testing Rate Limits

```typescript
// __tests__/rateLimit.integration.test.ts
import { describe, it, expect } from 'vitest'

describe('Rate Limit Integration', () => {
  it('should enforce rate limits', async () => {
    const responses = []
    
    // Make 101 requests (exceeds 100 limit)
    for (let i = 0; i < 101; i++) {
      const response = await fetch('http://localhost:3000/api/test', {
        headers: {
          'Authorization': 'Bearer test-token',
        },
      })
      responses.push(response)
    }

    // First 100 should succeed
    expect(responses.slice(0, 100).every(r => r.status === 200)).toBe(true)
    
    // 101st should be rate limited
    expect(responses[100].status).toBe(429)
    
    // Check headers
    const lastResponse = responses[100]
    expect(lastResponse.headers.get('Retry-After')).toBeTruthy()
  })
})
```
