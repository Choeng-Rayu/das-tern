# JWT Authentication Middleware - Usage Examples

This document provides practical examples of using the JWT authentication middleware in the Das Tern Backend API.

## Table of Contents

1. [Basic Protected Endpoint](#basic-protected-endpoint)
2. [Role-Based Access Control](#role-based-access-control)
3. [Optional Authentication](#optional-authentication)
4. [Logout Implementation](#logout-implementation)
5. [Token Validation](#token-validation)
6. [Error Handling](#error-handling)
7. [Testing Protected Endpoints](#testing-protected-endpoints)

## Basic Protected Endpoint

The simplest use case - protect an endpoint that requires authentication:

```typescript
// app/api/users/profile/route.ts
import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'
import { prisma } from '@/lib/prisma'

export const GET = withAuth(async (req: NextRequest, { user }) => {
  // User is automatically authenticated
  // Access user information from the context
  
  const userProfile = await prisma.user.findUnique({
    where: { id: user.id },
    include: {
      subscription: true,
    },
  })

  if (!userProfile) {
    return Response.json(
      { error: 'User not found' },
      { status: 404 }
    )
  }

  return Response.json({
    id: userProfile.id,
    role: userProfile.role,
    firstName: userProfile.firstName,
    lastName: userProfile.lastName,
    email: userProfile.email,
    phoneNumber: userProfile.phoneNumber,
    language: userProfile.language,
    theme: userProfile.theme,
    subscriptionTier: userProfile.subscription?.tier,
  })
})

export const PATCH = withAuth(async (req: NextRequest, { user }) => {
  const body = await req.json()
  
  // Validate and update user profile
  const updatedUser = await prisma.user.update({
    where: { id: user.id },
    data: {
      language: body.language,
      theme: body.theme,
    },
  })

  return Response.json({
    message: 'Profile updated successfully',
    user: updatedUser,
  })
})
```

## Role-Based Access Control

### Doctor-Only Endpoint

```typescript
// app/api/prescriptions/create/route.ts
import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'
import { prisma } from '@/lib/prisma'

export const POST = withAuth(
  async (req: NextRequest, { user }) => {
    // Only doctors can create prescriptions
    const body = await req.json()
    
    // Validate doctor-patient connection
    const connection = await prisma.connection.findFirst({
      where: {
        doctorId: user.id,
        patientId: body.patientId,
        status: 'ACCEPTED',
      },
    })

    if (!connection) {
      return Response.json(
        { error: 'No active connection with this patient' },
        { status: 403 }
      )
    }

    // Create prescription
    const prescription = await prisma.prescription.create({
      data: {
        doctorId: user.id,
        patientId: body.patientId,
        medications: body.medications,
        status: 'DRAFT',
      },
    })

    return Response.json({
      message: 'Prescription created successfully',
      prescription,
    })
  },
  {
    requiredRole: 'DOCTOR',
  }
)
```

### Patient-Only Endpoint

```typescript
// app/api/doses/mark-taken/route.ts
import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'
import { prisma } from '@/lib/prisma'

export const POST = withAuth(
  async (req: NextRequest, { user }) => {
    // Only patients can mark doses as taken
    const body = await req.json()
    
    const dose = await prisma.doseEvent.update({
      where: {
        id: body.doseId,
        patientId: user.id, // Ensure patient owns this dose
      },
      data: {
        status: 'TAKEN_ON_TIME',
        takenAt: new Date(),
      },
    })

    return Response.json({
      message: 'Dose marked as taken',
      dose,
    })
  },
  {
    requiredRole: 'PATIENT',
  }
)
```

### Multi-Role Endpoint

```typescript
// app/api/connections/list/route.ts
import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'
import { prisma } from '@/lib/prisma'

export const GET = withAuth(
  async (req: NextRequest, { user }) => {
    // Both doctors and patients can view their connections
    
    const connections = await prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: user.id },
          { recipientId: user.id },
        ],
      },
      include: {
        initiator: {
          select: {
            id: true,
            fullName: true,
            role: true,
          },
        },
        recipient: {
          select: {
            id: true,
            fullName: true,
            role: true,
          },
        },
      },
    })

    return Response.json({ connections })
  },
  {
    requiredRole: ['DOCTOR', 'PATIENT'],
  }
)
```

## Optional Authentication

Endpoints that work differently for authenticated vs anonymous users:

```typescript
// app/api/public/features/route.ts
import { NextRequest } from 'next/server'
import { withOptionalAuth } from '@/lib/middleware/auth'

export const GET = withOptionalAuth(async (req: NextRequest, { user }) => {
  const baseFeatures = {
    medicationReminders: true,
    basicTracking: true,
    offlineMode: true,
  }

  if (user) {
    // Authenticated user - return personalized features
    const premiumFeatures = user.subscriptionTier !== 'FREEMIUM' ? {
      advancedAnalytics: true,
      familySharing: true,
      unlimitedPrescriptions: true,
      prioritySupport: true,
    } : {}

    return Response.json({
      authenticated: true,
      userId: user.id,
      subscriptionTier: user.subscriptionTier,
      features: {
        ...baseFeatures,
        ...premiumFeatures,
      },
    })
  } else {
    // Anonymous user - return public features
    return Response.json({
      authenticated: false,
      features: baseFeatures,
      upgradeMessage: 'Login to unlock premium features',
    })
  }
})
```

## Logout Implementation

Implement secure logout with token blacklisting:

```typescript
// app/api/auth/logout/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { getToken } from 'next-auth/jwt'
import { blacklistToken } from '@/lib/middleware/auth'
import { translate, getLanguageFromHeader } from '@/lib/i18n'

export async function POST(req: NextRequest) {
  try {
    const acceptLanguage = req.headers.get('accept-language') || undefined
    const language = getLanguageFromHeader(acceptLanguage)

    const token = await getToken({
      req: req as any,
      secret: process.env.NEXTAUTH_SECRET,
    })

    if (!token) {
      return NextResponse.json(
        {
          error: {
            message: translate('auth.unauthorized', language),
            code: 'UNAUTHORIZED',
          },
        },
        { status: 401 }
      )
    }

    // Calculate remaining time until token expiration
    const now = Math.floor(Date.now() / 1000)
    const expiresIn = token.exp ? token.exp - now : 900

    // Blacklist the token
    const tokenId = token.jti || token.sub || token.id
    if (tokenId) {
      await blacklistToken(tokenId as string, Math.max(expiresIn, 0))
    }

    return NextResponse.json({
      message: translate('auth.logoutSuccess', language),
      success: true,
    })
  } catch (error) {
    console.error('Logout error:', error)
    return NextResponse.json(
      {
        error: {
          message: 'Logout failed',
          code: 'SERVER_ERROR',
        },
      },
      { status: 500 }
    )
  }
}
```

## Token Validation

Validate tokens without full authentication enforcement:

```typescript
// app/api/auth/validate/route.ts
import { NextRequest } from 'next/server'
import { validateToken } from '@/lib/middleware/auth'

export async function GET(req: NextRequest) {
  const user = await validateToken(req)
  
  if (user) {
    return Response.json({
      valid: true,
      user: {
        id: user.id,
        role: user.role,
        subscriptionTier: user.subscriptionTier,
      },
    })
  } else {
    return Response.json({
      valid: false,
      message: 'Token is invalid or expired',
    })
  }
}
```

## Error Handling

Handle authentication errors gracefully:

```typescript
// app/api/users/settings/route.ts
import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'
import { prisma } from '@/lib/prisma'

export const PATCH = withAuth(async (req: NextRequest, { user }) => {
  try {
    const body = await req.json()
    
    // Validate input
    if (!body.language && !body.theme) {
      return Response.json(
        {
          error: {
            message: 'At least one field (language or theme) is required',
            code: 'VALIDATION_ERROR',
          },
        },
        { status: 400 }
      )
    }

    // Update settings
    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: {
        ...(body.language && { language: body.language }),
        ...(body.theme && { theme: body.theme }),
      },
    })

    return Response.json({
      message: 'Settings updated successfully',
      settings: {
        language: updatedUser.language,
        theme: updatedUser.theme,
      },
    })
  } catch (error) {
    console.error('Settings update error:', error)
    
    return Response.json(
      {
        error: {
          message: 'Failed to update settings',
          code: 'SERVER_ERROR',
        },
      },
      { status: 500 }
    )
  }
})
```

## Testing Protected Endpoints

### Using cURL

```bash
# Get access token from login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "+855123456789",
    "password": "password123"
  }'

# Use the token to access protected endpoint
curl -X GET http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Access doctor-only endpoint (will fail if not a doctor)
curl -X POST http://localhost:3000/api/prescriptions/create \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "patient-123",
    "medications": [...]
  }'

# Logout
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Using Fetch API

```typescript
// Login
const loginResponse = await fetch('http://localhost:3000/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    identifier: '+855123456789',
    password: 'password123',
  }),
})

const { accessToken } = await loginResponse.json()

// Access protected endpoint
const profileResponse = await fetch('http://localhost:3000/api/users/profile', {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
  },
})

const profile = await profileResponse.json()

// Logout
await fetch('http://localhost:3000/api/auth/logout', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
  },
})
```

### Integration Test Example

```typescript
import { describe, it, expect, beforeAll } from 'vitest'
import { NextRequest } from 'next/server'

describe('Protected Endpoint Integration', () => {
  let accessToken: string

  beforeAll(async () => {
    // Login to get access token
    const response = await fetch('http://localhost:3000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        identifier: 'test@example.com',
        password: 'password123',
      }),
    })
    
    const data = await response.json()
    accessToken = data.accessToken
  })

  it('should access protected endpoint with valid token', async () => {
    const response = await fetch('http://localhost:3000/api/users/profile', {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    })

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.id).toBeDefined()
    expect(data.role).toBeDefined()
  })

  it('should reject access without token', async () => {
    const response = await fetch('http://localhost:3000/api/users/profile')
    expect(response.status).toBe(401)
  })

  it('should reject access with invalid token', async () => {
    const response = await fetch('http://localhost:3000/api/users/profile', {
      headers: {
        'Authorization': 'Bearer invalid-token',
      },
    })
    expect(response.status).toBe(401)
  })
})
```

## Best Practices

1. **Always use HTTPS in production** - JWT tokens should never be transmitted over unencrypted connections

2. **Store tokens securely** - Use httpOnly cookies or secure storage mechanisms in the client

3. **Implement token refresh** - Use refresh tokens to get new access tokens without requiring re-authentication

4. **Validate on every request** - Never trust client-side validation alone

5. **Use role-based access control** - Implement the principle of least privilege

6. **Log authentication events** - Track login, logout, and failed authentication attempts

7. **Handle errors gracefully** - Provide clear error messages in both Khmer and English

8. **Test thoroughly** - Write comprehensive tests for all authentication scenarios

9. **Monitor token usage** - Track token expiration and refresh patterns

10. **Implement rate limiting** - Prevent brute force attacks on authentication endpoints

## Common Pitfalls

1. **Not checking token expiration** - Always validate token expiration on the server side

2. **Forgetting to blacklist on logout** - Tokens remain valid until expiration unless blacklisted

3. **Exposing sensitive data** - Never include passwords or sensitive data in JWT payload

4. **Not handling token refresh** - Implement proper token refresh to avoid forcing users to re-login

5. **Ignoring role validation** - Always validate user roles for protected endpoints

6. **Poor error messages** - Provide clear, actionable error messages to users

7. **Not testing edge cases** - Test expired tokens, blacklisted tokens, and invalid payloads

8. **Hardcoding secrets** - Always use environment variables for secrets

## Related Documentation

- [Authentication Middleware README](./README.md)
- [NextAuth.js Documentation](https://next-auth.js.org/)
- [Das Tern API Design](../../../.kiro/specs/das-tern-backend-api/design.md)
