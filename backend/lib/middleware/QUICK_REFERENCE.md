# JWT Authentication Middleware - Quick Reference

## Import

```typescript
import { withAuth, withOptionalAuth, blacklistToken } from '@/lib/middleware/auth'
```

## Basic Usage

### Protected Endpoint
```typescript
export const GET = withAuth(async (req, { user }) => {
  // user.id, user.role, user.language, user.theme, user.subscriptionTier
  return Response.json({ userId: user.id })
})
```

### Doctor Only
```typescript
export const POST = withAuth(
  async (req, { user }) => { /* ... */ },
  { requiredRole: 'DOCTOR' }
)
```

### Patient Only
```typescript
export const POST = withAuth(
  async (req, { user }) => { /* ... */ },
  { requiredRole: 'PATIENT' }
)
```

### Multiple Roles
```typescript
export const GET = withAuth(
  async (req, { user }) => { /* ... */ },
  { requiredRole: ['DOCTOR', 'PATIENT'] }
)
```

### Optional Auth
```typescript
export const GET = withOptionalAuth(async (req, { user }) => {
  if (user) {
    // Authenticated
  } else {
    // Anonymous
  }
})
```

### Logout
```typescript
import { getToken } from 'next-auth/jwt'
import { blacklistToken } from '@/lib/middleware/auth'

const token = await getToken({ req, secret: process.env.NEXTAUTH_SECRET })
const tokenId = token.jti || token.sub
const expiresIn = token.exp - Math.floor(Date.now() / 1000)
await blacklistToken(tokenId, expiresIn)
```

## User Object

```typescript
interface AuthUser {
  id: string
  role: 'PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER'
  language: 'khmer' | 'english'
  theme: 'LIGHT' | 'DARK'
  subscriptionTier: 'FREEMIUM' | 'PREMIUM' | 'FAMILY_PREMIUM'
}
```

## Error Responses

### 401 Unauthorized
```json
{
  "error": {
    "message": "Invalid or expired token",
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

## Client Usage

### cURL
```bash
curl -X GET http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer <token>"
```

### Fetch
```typescript
const response = await fetch('/api/users/profile', {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
  },
})
```

## Testing

```bash
# Run tests
npm test -- lib/middleware/auth.test.ts

# Run with coverage
npm test -- lib/middleware/auth.test.ts --coverage

# Run in watch mode
npm test -- lib/middleware/auth.test.ts --watch
```

## Common Patterns

### Get Current User
```typescript
export const GET = withAuth(async (req, { user }) => {
  const userProfile = await prisma.user.findUnique({
    where: { id: user.id }
  })
  return Response.json(userProfile)
})
```

### Check Ownership
```typescript
export const DELETE = withAuth(async (req, { user }) => {
  const resource = await prisma.resource.findUnique({
    where: { id: params.id }
  })
  
  if (resource.ownerId !== user.id) {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }
  
  await prisma.resource.delete({ where: { id: params.id } })
  return Response.json({ success: true })
})
```

### Language-Specific Response
```typescript
export const GET = withAuth(async (req, { user }) => {
  const message = user.language === 'khmer' 
    ? 'សូមស្វាគមន៍' 
    : 'Welcome'
  return Response.json({ message })
})
```

### Subscription Check
```typescript
export const POST = withAuth(async (req, { user }) => {
  if (user.subscriptionTier === 'FREEMIUM') {
    return Response.json(
      { error: 'Premium feature' },
      { status: 403 }
    )
  }
  // Premium feature logic
})
```

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| Missing authorization header | No Bearer token | Add `Authorization: Bearer <token>` header |
| Invalid token | Token expired or invalid | Refresh token or login again |
| Token revoked | User logged out | Login again |
| Access denied | Wrong role | Check endpoint role requirements |

## Environment Variables

```env
NEXTAUTH_SECRET=your-secret-key-here
REDIS_URL=redis://localhost:6379
```

## Links

- [Full Documentation](./README.md)
- [Usage Examples](./USAGE_EXAMPLES.md)
- [Implementation Summary](./IMPLEMENTATION_SUMMARY.md)
