import { z } from 'zod'

/**
 * Common validation schemas for reusable field types
 */

// Phone number validation (Cambodia format: +855...)
export const phoneNumberSchema = z
  .string()
  .regex(/^\+855\d{8,9}$/, {
    message: 'Phone number must be in Cambodia format (+855 followed by 8-9 digits)',
  })

// Email validation
export const emailSchema = z
  .string()
  .email({ message: 'Invalid email address' })
  .toLowerCase()

// Password validation (minimum 6 characters)
export const passwordSchema = z
  .string()
  .min(6, { message: 'Password must be at least 6 characters' })

// PIN code validation (exactly 4 digits)
export const pinCodeSchema = z
  .string()
  .regex(/^\d{4}$/, { message: 'PIN code must be exactly 4 digits' })

// UUID validation
export const uuidSchema = z.string().uuid({ message: 'Invalid ID format' })

// Date validation (ISO 8601 format)
export const dateSchema = z
  .string()
  .datetime({ message: 'Invalid date format. Use ISO 8601 format.' })
  .or(z.date())

// Date of birth validation (must be at least 13 years old)
export const dateOfBirthSchema = z
  .string()
  .or(z.date())
  .refine(
    (date) => {
      const birthDate = typeof date === 'string' ? new Date(date) : date
      const today = new Date()
      const age = today.getFullYear() - birthDate.getFullYear()
      const monthDiff = today.getMonth() - birthDate.getMonth()
      const dayDiff = today.getDate() - birthDate.getDate()
      
      // Adjust age if birthday hasn't occurred this year
      const adjustedAge = monthDiff < 0 || (monthDiff === 0 && dayDiff < 0) ? age - 1 : age
      
      return adjustedAge >= 13
    },
    { message: 'You must be at least 13 years old' }
  )

// Gender enum
export const genderSchema = z.enum(['MALE', 'FEMALE', 'OTHER'], {
  errorMap: () => ({ message: 'Gender must be MALE, FEMALE, or OTHER' }),
})

// Language enum
export const languageSchema = z.enum(['KHMER', 'ENGLISH'], {
  errorMap: () => ({ message: 'Language must be KHMER or ENGLISH' }),
})

// Theme enum
export const themeSchema = z.enum(['LIGHT', 'DARK'], {
  errorMap: () => ({ message: 'Theme must be LIGHT or DARK' }),
})

// User role enum
export const userRoleSchema = z.enum(['PATIENT', 'DOCTOR', 'FAMILY_MEMBER'], {
  errorMap: () => ({ message: 'Role must be PATIENT, DOCTOR, or FAMILY_MEMBER' }),
})

// Subscription tier enum
export const subscriptionTierSchema = z.enum(['FREEMIUM', 'PREMIUM', 'FAMILY_PREMIUM'], {
  errorMap: () => ({ message: 'Subscription tier must be FREEMIUM, PREMIUM, or FAMILY_PREMIUM' }),
})

// Prescription status enum
export const prescriptionStatusSchema = z.enum(['DRAFT', 'ACTIVE', 'PAUSED', 'INACTIVE'], {
  errorMap: () => ({ message: 'Prescription status must be DRAFT, ACTIVE, PAUSED, or INACTIVE' }),
})

// Dose status enum
export const doseStatusSchema = z.enum([
  'DUE',
  'TAKEN_ON_TIME',
  'TAKEN_LATE',
  'MISSED',
  'SKIPPED',
], {
  errorMap: () => ({
    message: 'Dose status must be DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, or SKIPPED',
  }),
})

// Time period enum
export const timePeriodSchema = z.enum(['DAYTIME', 'NIGHT'], {
  errorMap: () => ({ message: 'Time period must be DAYTIME or NIGHT' }),
})

// Permission level enum
export const permissionLevelSchema = z.enum(['NOT_ALLOWED', 'REQUEST', 'SELECTED', 'ALLOWED'], {
  errorMap: () => ({
    message: 'Permission level must be NOT_ALLOWED, REQUEST, SELECTED, or ALLOWED',
  }),
})

// Connection status enum
export const connectionStatusSchema = z.enum(['PENDING', 'ACCEPTED', 'REVOKED'], {
  errorMap: () => ({ message: 'Connection status must be PENDING, ACCEPTED, or REVOKED' }),
})

// Meal time range enum
export const mealTimeRangeSchema = z.enum([
  '6-7AM',
  '7-8AM',
  '8-9AM',
  '9-10AM',
  '12-1PM',
  '1-2PM',
  '2-3PM',
  '4-5PM',
  '6-7PM',
  '7-8PM',
  '8-9PM',
  '9-10PM',
], {
  errorMap: () => ({ message: 'Invalid meal time range' }),
})

// Doctor specialty enum
export const doctorSpecialtySchema = z.enum([
  'GENERAL_PRACTICE',
  'INTERNAL_MEDICINE',
  'CARDIOLOGY',
  'ENDOCRINOLOGY',
  'OTHER',
], {
  errorMap: () => ({ message: 'Invalid doctor specialty' }),
})

// Pagination schema
export const paginationSchema = z.object({
  page: z
    .string()
    .optional()
    .default('1')
    .transform((val) => parseInt(val, 10))
    .refine((val) => val > 0, { message: 'Page must be greater than 0' }),
  limit: z
    .string()
    .optional()
    .default('50')
    .transform((val) => parseInt(val, 10))
    .refine((val) => val > 0 && val <= 100, {
      message: 'Limit must be between 1 and 100',
    }),
})

// Sort order enum
export const sortOrderSchema = z.enum(['asc', 'desc'], {
  errorMap: () => ({ message: 'Sort order must be asc or desc' }),
})

// Time in HH:mm format
export const timeSchema = z
  .string()
  .regex(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'Time must be in HH:mm format (e.g., 09:30)',
  })

// URL validation
export const urlSchema = z.string().url({ message: 'Invalid URL format' })

// Non-empty string
export const nonEmptyStringSchema = z
  .string()
  .min(1, { message: 'This field cannot be empty' })
  .trim()

// Positive integer
export const positiveIntSchema = z
  .number()
  .int({ message: 'Must be an integer' })
  .positive({ message: 'Must be a positive number' })

// Non-negative integer
export const nonNegativeIntSchema = z
  .number()
  .int({ message: 'Must be an integer' })
  .nonnegative({ message: 'Must be a non-negative number' })

// Khmer text validation (allows Khmer Unicode characters)
export const khmerTextSchema = z
  .string()
  .regex(/^[\u1780-\u17FF\s\d.,!?()-]+$/, {
    message: 'Text must contain valid Khmer characters',
  })

// Optional Khmer text
export const optionalKhmerTextSchema = z
  .string()
  .regex(/^[\u1780-\u17FF\s\d.,!?()-]*$/, {
    message: 'Text must contain valid Khmer characters',
  })
  .optional()

// File size validation (in bytes)
export const fileSizeSchema = (maxSizeInMB: number) =>
  z.number().max(maxSizeInMB * 1024 * 1024, {
    message: `File size must not exceed ${maxSizeInMB}MB`,
  })

// Image file type validation
export const imageFileTypeSchema = z.enum(['image/jpeg', 'image/png', 'image/webp'], {
  errorMap: () => ({ message: 'File must be JPEG, PNG, or WebP format' }),
})

/**
 * Helper to create optional fields that can be null or undefined
 */
export const optional = <T extends z.ZodTypeAny>(schema: T) =>
  schema.optional().nullable()

/**
 * Helper to create a schema that transforms empty strings to undefined
 */
export const emptyStringToUndefined = <T extends z.ZodTypeAny>(schema: T) =>
  z.preprocess((val) => (val === '' ? undefined : val), schema)
