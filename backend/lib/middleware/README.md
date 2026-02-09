# JWT Authentication Middleware

This directory contains the JWT authentication middleware for the Das Tern Backend API. The middleware integrates with NextAuth.js v5 to provide secure, token-based authentication for API routes.

## Features

- ✅ **JWT Token Verification**: Validates JWT tokens from Authorization header (Bearer token)
- ✅ **Token Expiration**: Automatically checks and enforces token expiration (15 minutes for access tokens)
- ✅ **User Context**: Extracts and provides user information (id, role, language, theme, subscriptionTier)
- ✅ **Token Blacklisting**: Supports token revocation via Redis for logout functionality
- ✅ **Role-Based Access Control**: Enforces role requirements on protected endpoints
- ✅ **Multi-Language Support**: Returns error messages in Khmer and English
- ✅ **Type Safety**: Full TypeScript support with type-safe user context
- ✅ **Optional Authentication**: Supports endpoints that work for both authenticated and anonymous users
- ✅ **NextAuth.js Integration**: Seamlessly integrates with NextAuth.js session management

## Installation

The middleware is already set up in the project. No additional installation is required.

## Usage

### Basic Authentication

Protect an API route by wrapping your handler with `withAuth`:

```typescript
import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'

export const GET = withAuth(async (req: NextRequest, { user }) => {
  // User is automatically authenticated and available here
  return Response.json({
    message: 'Hello, authenticated user!',
    userId: user.id,
    role: user.role,
  })
})
```

### Role-Based Access Control

Restrict access to specific roles:

```typescript
import { withAuth } from '@/lib/middleware/auth'

// Only doctors can access this endpoint
export const POST = withAuth(
  async (req, { user }) => {
    // Only DOCTOR role can reach here
    return Response.json({ message: 'Doctor-only endpoint' })
  },
  {
    requiredRole: 'DOCTOR',
  }
)

// Multiple roles allowed
export const PATCH = withAuth(
  async (req, { user }) => {
    // Both DOCTOR and PATIENT roles can reach here
    return Response.json({ message: 'Multi-role endpoint' })
  },
  {
    requiredRole: ['DOCTOR', 'PATIENT'],
  }
)
```

### Optional Authentication

For endpoints that work differently for authenticated vs anonymous users:

```typescript
import { withOptionalAuth } from '@/lib/middleware/auth'

export const GET = withOptionalAuth(async (req, { user }) => {
  if (user) {
    // Authenticated user logic
    return Response.json({
      message: 'Welcome back!',
      premium: user.subscriptionTier !== 'FREEMIUM',
    })
  } else {
    // Anonymous user logic
    return Response.json({
      message: 'Please login for premium features',
      premium: false,
    })
  }
})
```

### Token Blacklisting (Logout)

Implement logout by blacklisting the current token:

```typescript
import { getToken } from 'next-auth/jwt'
import { blacklistToken } from '@/lib/middleware/auth'

export async function POST(req: NextRequest) {
  const token = await getToken({ req, secret: process.env.NEXTAUTH_SECRET })
  
  if (token) {
    const tokenId = token.jti || token.sub
    const expiresIn = token.exp ? token.exp - Math.floor(Date.now() / 1000) : 900
    
    await blacklistToken(tokenId, expiresIn)
  }
  
  return Response.json({ message: 'Logged out successfully' })
}
```

### Token Validation

Validate a token without full authentication:

```typescript
import { validateToken } from '@/lib/middleware/auth'

export async function GET(req: NextRequest) {
  const user = await validateToken(req)
  
  if (user) {
    // Token is valid
    return Response.json({ valid: true, userId: user.id })
  } else {
    // Token is invalid or missing
    return Response.json({ valid: false })
  }
}
```

## API Reference

### `withAuth(handler, options?)`

Main authentication middleware that enforces authentication on API routes.

**Parameters:**
- `handler: AuthenticatedHandler` - The route handler function to wrap
- `options?: object` - Optional configuration
  - `requiredRole?: string | string[]` - Required user role(s) to access the endpoint
  - `checkBlacklist?: boolean` - Whether to check token blacklist (default: true)

**Returns:** Wrapped handler function

**Throws:** Returns 401 or 403 HTTP responses for authentication/authorization failures

### `withOptionalAuth(handler)`

Optional authentication middleware that doesn't fail if no token is provided.

**Parameters:**
- `handler: (req, context) => Response` - The route handler function

**Returns:** Wrapped handler function

### `blacklistToken(tokenId, expiresIn)`

Blacklist a token to prevent its use (for logout functionality).

**Parameters:**
- `tokenId: string` - The token ID (jti) or subject (sub) to blacklist
- `expiresIn: number` - Time in seconds until the token expires

**Returns:** `Promise<void>`

### `isTokenBlacklisted(tokenId)`

Check if a token is blacklisted.

**Parameters:**
- `tokenId: string` - The token ID to check

**Returns:** `Promise<boolean>`

### `validateToken(req)`

Validate a token without enforcing authentication.

**Parameters:**
- `req: NextRequest` - The Next.js request object

**Returns:** `Promise<AuthUser | null>` - User information if valid, null otherwise

## Types

### `AuthUser`

```typescript
interface AuthUser {
  id: string
  role: 'PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER'
  language: 'khmer' | 'english'
  theme: 'LIGHT' | 'DARK'
  subscriptionTier: 'FREEMIUM' | 'PREMIUM' | 'FAMILY_PREMIUM'
}
```

### `AuthContext`

```typescript
interface AuthContext {
  user: AuthUser
  req: NextRequest
}
```

## Authentication Flow

1. **Client Request**: Client sends request with `Authorization: Bearer <token>` header
2. **Token Extraction**: Middleware extracts token from Authorization header
3. **Token Verification**: NextAuth.js verifies token signature and expiration
4. **Blacklist Check**: Middleware checks if token is blacklisted in Redis
5. **User Extraction**: User information is extracted from token payload
6. **Role Check**: If required, user role is validated against endpoint requirements
7. **Handler Execution**: If all checks pass, the route handler is executed with user context

## Error Responses

All authentication errors return standardized JSON responses with both Khmer and English messages:

### 401 Unauthorized

```json
{
  "error": {
    "message": "Invalid or expired token. Please login again.",
    "messageEn": "Invalid or expired token. Please login again.",
    "messageKm": "Token មិនត្រឹមត្រូវ ឬផុតកំណត់។ សូមចូលម្តងទៀត។",
    "code": "UNAUTHORIZED"
  }
}
```

### 403 Forbidden

```json
{
  "error": {
    "message": "Access denied. This endpoint requires DOCTOR role.",
    "messageEn": "Access denied. This endpoint requires DOCTOR role.",
    "messageKm": "ការចូលប្រើត្រូវបានបដិសេធ។ endpoint នេះត្រូវការតួនាទី DOCTOR",
    "code": "FORBIDDEN"
  }
}
```

## Token Configuration

### Access Token
- **Expiry**: 15 minutes
- **Storage**: JWT (stateless)
- **Refresh**: Via NextAuth.js refresh token rotation

### Refresh Token
- **Expiry**: 7 days
- **Storage**: Redis with expiration
- **Rotation**: Automatic on refresh

## Security Considerations

1. **Token Blacklisting**: Tokens are blacklisted in Redis on logout to prevent reuse
2. **Expiration Enforcement**: Both access and refresh tokens have strict expiration times
3. **Role Validation**: Role-based access control is enforced at the middleware level
4. **Secure Storage**: Refresh tokens are stored in Redis with automatic expiration
5. **HTTPS Only**: All authentication should be done over HTTPS in production

## Testing

Run the test suite:

```bash
npm test backend/lib/middleware/auth.test.ts
```

The test suite covers:
- Valid token authentication
- Missing/invalid token handling
- Token expiration
- Token blacklisting
- Role-based access control
- Multi-language error messages
- Optional authentication
- Token validation

## Integration with NextAuth.js

This middleware integrates seamlessly with NextAuth.js v5:

1. **Token Generation**: NextAuth.js generates JWT tokens on login
2. **Token Verification**: NextAuth.js verifies token signatures
3. **Session Management**: NextAuth.js manages session state
4. **Token Refresh**: NextAuth.js handles automatic token refresh

The middleware extends NextAuth.js with:
- Token blacklisting for logout
- Role-based access control
- Multi-language error messages
- Type-safe user context

## Examples

See the following files for complete examples:
- `backend/app/api/example/protected/route.ts` - Basic authentication and RBAC
- `backend/app/api/example/optional-auth/route.ts` - Optional authentication
- `backend/app/api/auth/logout/route.ts` - Logout with token blacklisting

## Troubleshooting

### "Missing or invalid authorization header"
- Ensure the Authorization header is present
- Verify the format is `Bearer <token>`
- Check that the token is not empty

### "Invalid or expired token"
- Token may have expired (15 minutes for access tokens)
- Token signature may be invalid
- Use the refresh token to get a new access token

### "Token has been revoked"
- Token was blacklisted (user logged out)
- User needs to login again

### "Access denied"
- User role doesn't match required role(s)
- Check the `requiredRole` option in `withAuth`

## Related Documentation

- [NextAuth.js Documentation](https://next-auth.js.org/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Das Tern API Design Document](../../../.kiro/specs/das-tern-backend-api/design.md)
- [Das Tern API Requirements](../../../.kiro/specs/das-tern-backend-api/requirements.md)
