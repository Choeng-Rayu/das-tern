import { z } from 'zod'
import {
  uuidSchema,
  nonEmptyStringSchema,
  urlSchema,
  timeSchema,
  optional,
  imageFileTypeSchema,
  fileSizeSchema,
} from './common'

/**
 * Medication image upload schema
 */
export const medicationImageUploadSchema = z.object({
  medicationId: uuidSchema.describe('Medication ID'),
  file: z.object({
    name: nonEmptyStringSchema.describe('File name'),
    type: imageFileTypeSchema.describe('File MIME type'),
    size: fileSizeSchema(5).describe('File size in bytes (max 5MB)'),
  }),
})

/**
 * Medication detail schema
 */
export const medicationDetailSchema = z.object({
  id: uuidSchema.describe('Medication ID'),
  name: nonEmptyStringSchema.describe('Medication name in English'),
  nameKhmer: optional(z.string()).describe('Medication name in Khmer'),
  dosage: nonEmptyStringSchema.describe('Dosage amount'),
  quantity: nonEmptyStringSchema.describe('Quantity per dose'),
  frequency: nonEmptyStringSchema.describe('Frequency (e.g., "3 times per day")'),
  timing: nonEmptyStringSchema.describe('Timing (before/after meals)'),
  imageUrl: optional(urlSchema).describe('URL to medication image'),
  reminderTime: optional(timeSchema).describe('Reminder time in HH:mm format'),
})

/**
 * Medication schedule item schema
 */
export const medicationScheduleItemSchema = z.object({
  id: uuidSchema.describe('Dose event ID'),
  medicationName: nonEmptyStringSchema.describe('Medication name in English'),
  medicationNameKhmer: optional(z.string()).describe('Medication name in Khmer'),
  dosage: nonEmptyStringSchema.describe('Dosage amount'),
  quantity: nonEmptyStringSchema.describe('Quantity per dose'),
  imageUrl: optional(urlSchema).describe('URL to medication image'),
  scheduledTime: z.string().datetime().describe('Scheduled time in ISO 8601 format'),
  status: z
    .enum(['DUE', 'TAKEN_ON_TIME', 'TAKEN_LATE', 'MISSED', 'SKIPPED'])
    .describe('Dose status'),
  frequency: nonEmptyStringSchema.describe('Frequency'),
  timing: nonEmptyStringSchema.describe('Timing (before/after meals)'),
  reminderTime: timeSchema.describe('Reminder time in HH:mm format'),
})

/**
 * Medication schedule group schema (by time period)
 */
export const medicationScheduleGroupSchema = z.object({
  period: z.enum(['DAYTIME', 'NIGHT']).describe('Time period'),
  periodKhmer: z.string().describe('Time period in Khmer (ពេលថ្ងៃ or ពេលយប់)'),
  color: z.string().describe('Color code for the time period (#2D5BFF or #6B4AA3)'),
  doses: z.array(medicationScheduleItemSchema).describe('List of doses in this time period'),
})

/**
 * Medication schedule response schema
 */
export const medicationScheduleSchema = z.object({
  date: z.string().describe('Date in ISO 8601 format'),
  dailyProgress: z
    .number()
    .min(0)
    .max(100)
    .describe('Daily progress percentage (0-100)'),
  groups: z
    .array(medicationScheduleGroupSchema)
    .describe('Medication groups by time period'),
})

/**
 * Medication search query schema
 */
export const medicationSearchSchema = z.object({
  query: nonEmptyStringSchema.describe('Search query (Khmer or English)'),
  limit: z
    .string()
    .optional()
    .default('20')
    .transform((val) => parseInt(val, 10))
    .refine((val) => val > 0 && val <= 50, {
      message: 'Limit must be between 1 and 50',
    }),
})

/**
 * Update medication reminder time schema
 */
export const updateReminderTimeSchema = z.object({
  reminderTime: timeSchema.describe('New reminder time in HH:mm format'),
})

/**
 * Type exports for TypeScript
 */
export type MedicationImageUpload = z.infer<typeof medicationImageUploadSchema>
export type MedicationDetail = z.infer<typeof medicationDetailSchema>
export type MedicationScheduleItem = z.infer<typeof medicationScheduleItemSchema>
export type MedicationScheduleGroup = z.infer<typeof medicationScheduleGroupSchema>
export type MedicationSchedule = z.infer<typeof medicationScheduleSchema>
export type MedicationSearch = z.infer<typeof medicationSearchSchema>
export type UpdateReminderTime = z.infer<typeof updateReminderTimeSchema>
