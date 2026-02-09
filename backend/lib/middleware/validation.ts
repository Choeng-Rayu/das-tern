import { NextRequest, NextResponse } from 'next/server'
import { z, ZodError, ZodSchema } from 'zod'
import { getLanguageFromHeader, type Language } from '../i18n'

// Type for validated request context
export interface ValidatedContext<T = any> {
  body: T
  query: Record<string, string>
  params: Record<string, string>
}

// Type for route handlers with validation
export type ValidatedHandler<T = any> = (
  req: NextRequest,
  context: ValidatedContext<T>
) => Promise<Response> | Response

/**
 * Request validation middleware using Zod
 * 
 * Features:
 * - Validates request body against Zod schemas
 * - Validates query parameters
 * - Returns 400 errors with field-level error messages
 * - Multi-language support (Khmer/English)
 * - Type-safe validated data
 * 
 * Usage:
 * ```typescript
 * import { withValidation } from '@/lib/middleware/validation'
 * import { prescriptionCreateSchema } from '@/lib/schemas/prescription'
 * 
 * export const POST = withValidation(prescriptionCreateSchema)(
 *   async (req, { body }) => {
 *     // body is typed and validated
 *     return Response.json({ data: body })
 *   }
 * )
 * ```
 */
export function withValidation<T extends ZodSchema>(
  schema: T,
  options?: {
    validateQuery?: boolean
    validateParams?: boolean
  }
) {
  return (
    handler: ValidatedHandler<z.infer<T>>
  ): ((req: NextRequest) => Promise<Response>) => {
    return async (req: NextRequest): Promise<Response> => {
      try {
        const acceptLanguage = req.headers.get('accept-language') || undefined
        const language = getLanguageFromHeader(acceptLanguage)

        // Parse request body
        let body: any = {}
        const contentType = req.headers.get('content-type')
        
        if (contentType?.includes('application/json')) {
          try {
            body = await req.json()
          } catch (e) {
            return createValidationErrorResponse(
              'Invalid JSON in request body',
              'JSON មិនត្រឹមត្រូវក្នុងតួ request',
              [],
              language
            )
          }
        }

        // Validate body against schema
        const validationResult = schema.safeParse(body)

        if (!validationResult.success) {
          const errors = formatZodErrors(validationResult.error, language)
          return createValidationErrorResponse(
            'Validation failed',
            'ការផ្ទៀងផ្ទាត់បានបរាជ័យ',
            errors,
            language
          )
        }

        // Parse query parameters
        const query: Record<string, string> = {}
        const url = new URL(req.url)
        url.searchParams.forEach((value, key) => {
          query[key] = value
        })

        // Parse path parameters (if any)
        const params: Record<string, string> = {}

        // Create validated context
        const context: ValidatedContext<z.infer<T>> = {
          body: validationResult.data,
          query,
          params,
        }

        // Call handler with validated data
        return await handler(req, context)
      } catch (error) {
        console.error('Validation middleware error:', error)
        
        const acceptLanguage = req.headers.get('accept-language') || undefined
        const language = getLanguageFromHeader(acceptLanguage)

        return createValidationErrorResponse(
          'Validation error occurred',
          'កំហុសក្នុងការផ្ទៀងផ្ទាត់',
          [],
          language
        )
      }
    }
  }
}

/**
 * Format Zod validation errors into user-friendly messages
 */
function formatZodErrors(error: ZodError, language: Language): Array<{
  field: string
  message: string
  messageEn: string
  messageKm: string
}> {
  return error.errors.map((err) => {
    const field = err.path.join('.')
    const messageEn = err.message
    const messageKm = translateValidationError(err.message, err.code)

    return {
      field,
      message: language === 'khmer' ? messageKm : messageEn,
      messageEn,
      messageKm,
    }
  })
}

/**
 * Translate validation error messages to Khmer
 */
function translateValidationError(message: string, code: string): string {
  const translations: Record<string, string> = {
    'Required': 'ចាំបាច់',
    'Invalid type': 'ប្រភេទមិនត្រឹមត្រូវ',
    'Invalid email': 'អ៊ីមែលមិនត្រឹមត្រូវ',
    'String must contain at least': 'ខ្សែអក្សរត្រូវតែមានយ៉ាងតិច',
    'String must contain at most': 'ខ្សែអក្សរត្រូវតែមានយ៉ាងច្រើន',
    'Number must be greater than': 'លេខត្រូវតែធំជាង',
    'Number must be less than': 'លេខត្រូវតែតូចជាង',
    'Invalid date': 'កាលបរិច្ឆេទមិនត្រឹមត្រូវ',
    'Invalid enum value': 'តម្លៃ enum មិនត្រឹមត្រូវ',
  }

  for (const [key, value] of Object.entries(translations)) {
    if (message.includes(key)) {
      return message.replace(key, value)
    }
  }

  return message
}

/**
 * Create validation error response
 */
function createValidationErrorResponse(
  message: string,
  messageKhmer: string,
  errors: Array<any>,
  language: Language
): NextResponse {
  return NextResponse.json(
    {
      error: {
        message: language === 'khmer' ? messageKhmer : message,
        messageEn: message,
        messageKm: messageKhmer,
        code: 'VALIDATION_ERROR',
        errors,
      },
    },
    { status: 400 }
  )
}

/**
 * Validate query parameters
 */
export function validateQuery<T extends ZodSchema>(
  schema: T,
  query: Record<string, string>
): z.infer<T> | null {
  const result = schema.safeParse(query)
  return result.success ? result.data : null
}

/**
 * Validate path parameters
 */
export function validateParams<T extends ZodSchema>(
  schema: T,
  params: Record<string, string>
): z.infer<T> | null {
  const result = schema.safeParse(params)
  return result.success ? result.data : null
}
