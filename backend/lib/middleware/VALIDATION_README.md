# Request Validation Middleware

Zod-based request validation middleware for Next.js API routes that provides type-safe validation with comprehensive error handling in both Khmer and English.

## Features

- ✅ **Type-Safe**: Full TypeScript support with automatic type inference from Zod schemas
- ✅ **Multi-Language**: Error messages in both Khmer and English
- ✅ **Comprehensive**: Validates request body, query parameters, and path parameters
- ✅ **Field-Level Errors**: Detailed error messages for each invalid field
- ✅ **Standardized Format**: Consistent error response structure across all endpoints
- ✅ **Easy Integration**: Simple middleware wrapper pattern
- ✅ **Auth Integration**: Combined authentication and validation middleware

## Installation

The validation middleware is already set up in the project. Import it from:

```typescript
import { withValidation, withAuthValidation } from '@/lib/middleware/validation'
```

## Basic Usage

### Body Validation

```typescript
import { withValidation } from '@/lib/middleware/validation'
import { z } from 'zod'

const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().int().positive(),
})

export const POST = withValidation({
  body: createUserSchema
})(async (req, { body }) => {
  // body is typed as { name: string, email: string, age: number }
  // and guaranteed to be valid
  
  return Response.json({ user: body })
})
```

### Query Parameter Validation

```typescript
import { withValidation } from '@/lib/middleware/validation'
import { z } from 'zod'

const listQuerySchema = z.object({
  page: z.string().transform(Number).refine(n => n > 0),
  limit: z.string().transform(Number).refine(n => n > 0 && n <= 100),
  search: z.string().optional(),
})

export const GET = withValidation({
  query: listQuerySchema
})(async (req, { query }) => {
  // query is typed as { page: number, limit: number, search?: string }
  
  return Response.json({ 
    page: query.page,
    limit: query.limit,
    results: [] 
  })
})
```

### Path Parameter Validation

```typescript
import { withValidation } from '@/lib/middleware/validation'
import { z } from 'zod'

const userIdSchema = z.object({
  userId: z.string().uuid(),
})

export const GET = withValidation({
  params: userIdSchema
})(async (req, { params }) => {
  // params is typed as { userId: string } (validated UUID)
  
  return Response.json({ userId: params.userId })
})
```

### Combined Validation

```typescript
import { withValidation } from '@/lib/middleware/validation'
import { z } from 'zod'

export const POST = withValidation({
  body: z.object({ name: z.string() }),
  query: z.object({ notify: z.string().transform(v => v === 'true') }),
  params: z.object({ id: z.string().uuid() }),
})(async (req, { body, query, params }) => {
  // All three are validated and typed
  
  return Response.json({ 
    id: params.id,
    name: body.name,
    notify: query.notify 
  })
})
```

## Using Pre-Built Schemas

The project includes pre-built schemas for common use cases:

```typescript
import { withValidation } from '@/lib/middleware/validation'
import { prescriptionCreateSchema } from '@/lib/schemas/prescription'
import { userProfileUpdateSchema } from '@/lib/schemas/user'
import { markDoseTakenSchema } from '@/lib/schemas/dose'

// Prescription creation
export const POST = withValidation({
  body: prescriptionCreateSchema
})(async (req, { body }) => {
  // body is fully typed with all prescription fields
  return Response.json({ prescription: body })
})

// User profile update
export const PATCH = withValidation({
  body: userProfileUpdateSchema
})(async (req, { body }) => {
  // body is typed with optional user fields
  return Response.json({ user: body })
})
```

## Authentication + Validation

Use `withAuthValidation` to combine authentication and validation:

```typescript
import { withAuthValidation } from '@/lib/middleware/validation'
import { prescriptionCreateSchema } from '@/lib/schemas/prescription'

export const POST = withAuthValidation(
  { body: prescriptionCreateSchema },
  { requiredRole: 'DOCTOR' }
)(async (req, { user, body }) => {
  // Both user and body are available and typed
  // user.role is guaranteed to be 'DOCTOR'
  
  return Response.json({ 
    prescription: body,
    doctorId: user.id 
  })
})
```

## Error Response Format

When validation fails, the middleware returns a 400 response with this structure:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed. Please check the errors below.",
    "messageEn": "Validation failed. Please check the errors below.",
    "messageKm": "ការផ្ទៀងផ្ទាត់បានបរាជ័យ។ សូមពិនិត្យកំហុសខាងក្រោម។",
    "fields": {
      "email": ["Invalid email address"],
      "age": ["This field must be a number"],
      "password": ["Password must be at least 6 characters"]
    }
  }
}
```

## Common Validation Schemas

The project provides reusable schemas in `backend/lib/schemas/common.ts`:

### Basic Types

```typescript
import {
  phoneNumberSchema,      // Cambodia format: +855...
  emailSchema,            // Valid email
  passwordSchema,         // Min 6 characters
  pinCodeSchema,          // Exactly 4 digits
  uuidSchema,             // Valid UUID
  dateSchema,             // ISO 8601 date
  dateOfBirthSchema,      // At least 13 years old
} from '@/lib/schemas/common'
```

### Enums

```typescript
import {
  genderSchema,           // MALE | FEMALE | OTHER
  languageSchema,         // KHMER | ENGLISH
  themeSchema,            // LIGHT | DARK
  userRoleSchema,         // PATIENT | DOCTOR | FAMILY_MEMBER
  prescriptionStatusSchema, // DRAFT | ACTIVE | PAUSED | INACTIVE
  doseStatusSchema,       // DUE | TAKEN_ON_TIME | TAKEN_LATE | MISSED | SKIPPED
} from '@/lib/schemas/common'
```

### Helpers

```typescript
import {
  paginationSchema,       // page and limit with defaults
  timeSchema,             // HH:mm format
  nonEmptyStringSchema,   // String with min length 1
  positiveIntSchema,      // Positive integer
  khmerTextSchema,        // Khmer Unicode validation
} from '@/lib/schemas/common'
```

## Available Schema Modules

### User Schemas (`@/lib/schemas/user`)

- `patientRegistrationSchema` - Patient registration with all required fields
- `doctorRegistrationSchema` - Doctor registration with professional details
- `familyMemberRegistrationSchema` - Family member registration
- `loginSchema` - Login with identifier and password
- `userProfileUpdateSchema` - Update user profile fields
- `changePasswordSchema` - Change password with validation
- `changePinCodeSchema` - Change PIN code

### Prescription Schemas (`@/lib/schemas/prescription`)

- `prescriptionCreateSchema` - Create new prescription with medications
- `prescriptionUpdateSchema` - Update existing prescription
- `prescriptionQuerySchema` - Query filters for prescription list
- `prescriptionRetakeSchema` - Request prescription retake
- `medicationSchema` - Individual medication with dosages

### Medication Schemas (`@/lib/schemas/medication`)

- `medicationDetailSchema` - Medication details
- `medicationScheduleSchema` - Daily medication schedule
- `medicationSearchSchema` - Search medications
- `updateReminderTimeSchema` - Update reminder time

### Dose Schemas (`@/lib/schemas/dose`)

- `markDoseTakenSchema` - Mark dose as taken
- `skipDoseSchema` - Skip dose with reason
- `doseQuerySchema` - Query dose schedule
- `doseHistoryQuerySchema` - Query dose history

## Custom Validation Rules

You can create custom validation rules using Zod's `refine` method:

```typescript
const prescriptionSchema = z.object({
  isUrgent: z.boolean(),
  urgentReason: z.string().optional(),
}).refine(
  (data) => {
    // If urgent, reason must be provided
    if (data.isUrgent && !data.urgentReason) {
      return false
    }
    return true
  },
  {
    message: 'Urgent reason is required when marking as urgent',
    path: ['urgentReason'],
  }
)
```

## Transformations

Zod supports data transformations during validation:

```typescript
const querySchema = z.object({
  // Transform string to number
  page: z.string().transform(Number),
  
  // Transform string to boolean
  active: z.string().transform(v => v === 'true'),
  
  // Transform and validate
  limit: z.string()
    .transform(Number)
    .refine(n => n > 0 && n <= 100, {
      message: 'Limit must be between 1 and 100'
    }),
})
```

## Optional and Nullable Fields

```typescript
import { optional } from '@/lib/schemas/common'

const schema = z.object({
  // Optional field (can be undefined)
  email: z.string().email().optional(),
  
  // Nullable field (can be null)
  middleName: z.string().nullable(),
  
  // Both optional and nullable
  nickname: optional(z.string()),
})
```

## Array Validation

```typescript
const schema = z.object({
  // Array with minimum length
  medications: z.array(medicationSchema).min(1, {
    message: 'At least one medication is required'
  }),
  
  // Array with maximum length
  tags: z.array(z.string()).max(10),
  
  // Array with length range
  items: z.array(z.string()).min(1).max(100),
})
```

## Nested Object Validation

```typescript
const addressSchema = z.object({
  street: z.string(),
  city: z.string(),
  postalCode: z.string(),
})

const userSchema = z.object({
  name: z.string(),
  address: addressSchema,
  contacts: z.array(z.object({
    type: z.enum(['phone', 'email']),
    value: z.string(),
  })),
})
```

## Error Handling

The middleware automatically handles:

- **Invalid JSON**: Returns 400 with `INVALID_JSON` error code
- **Validation Errors**: Returns 400 with `VALIDATION_ERROR` and field-level errors
- **Server Errors**: Returns 500 with `INTERNAL_ERROR`

All errors include both English and Khmer messages based on the `Accept-Language` header.

## Testing

Example test for a validated endpoint:

```typescript
import { describe, it, expect } from 'vitest'
import { POST } from './route'

describe('POST /api/users', () => {
  it('should validate and create user', async () => {
    const req = new NextRequest('http://localhost/api/users', {
      method: 'POST',
      body: JSON.stringify({
        name: 'John Doe',
        email: 'john@example.com',
        age: 30,
      }),
      headers: { 'content-type': 'application/json' },
    })

    const response = await POST(req)
    expect(response.status).toBe(200)
  })

  it('should return 400 for invalid data', async () => {
    const req = new NextRequest('http://localhost/api/users', {
      method: 'POST',
      body: JSON.stringify({
        name: '',
        email: 'invalid-email',
        age: -5,
      }),
      headers: { 'content-type': 'application/json' },
    })

    const response = await POST(req)
    const data = await response.json()
    
    expect(response.status).toBe(400)
    expect(data.error.code).toBe('VALIDATION_ERROR')
    expect(data.error.fields.name).toBeDefined()
    expect(data.error.fields.email).toBeDefined()
    expect(data.error.fields.age).toBeDefined()
  })
})
```

## Best Practices

1. **Reuse Schemas**: Create reusable schemas in `lib/schemas/` for common patterns
2. **Type Exports**: Export TypeScript types from your schemas for use in other files
3. **Descriptive Messages**: Use `.describe()` to document what each field is for
4. **Fail Fast**: Validate early in the request pipeline
5. **Consistent Errors**: Always use the validation middleware for consistent error format
6. **Test Validation**: Write tests for both valid and invalid inputs
7. **Document Schemas**: Add comments explaining complex validation rules

## Migration from Manual Validation

Before (manual validation):

```typescript
export async function POST(req: NextRequest) {
  const body = await req.json()
  
  if (!body.name || typeof body.name !== 'string') {
    return NextResponse.json({ error: 'Invalid name' }, { status: 400 })
  }
  
  if (!body.email || !body.email.includes('@')) {
    return NextResponse.json({ error: 'Invalid email' }, { status: 400 })
  }
  
  // ... more validation
}
```

After (with validation middleware):

```typescript
const schema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

export const POST = withValidation({ body: schema })(
  async (req, { body }) => {
    // body is validated and typed
    return Response.json({ user: body })
  }
)
```

## Troubleshooting

### Issue: "Cannot read property 'parse' of undefined"

**Solution**: Make sure you're importing from the correct schema file and the schema is exported.

### Issue: Transform errors not being caught

**Solution**: The middleware catches both ZodError and transformation errors. Make sure you're using `.transform()` correctly.

### Issue: Optional fields showing as required

**Solution**: Use `.optional()` or `.nullable()` on the field schema, or use the `optional()` helper from common schemas.

### Issue: Array parameters not working

**Solution**: The middleware automatically handles array query parameters (e.g., `?tags=a&tags=b`). Make sure your schema expects an array.

## Related Documentation

- [Zod Documentation](https://zod.dev/)
- [Authentication Middleware](./README.md)
- [Error Handling](./IMPLEMENTATION_SUMMARY.md)
- [API Design Patterns](../../docs/architectures/README.md)
