import { z } from 'zod'

// Mark dose as taken schema
export const markDoseTakenSchema = z.object({
  takenAt: z.string().datetime().optional(),
  offline: z.boolean().default(false),
})

// Skip dose schema
export const skipDoseSchema = z.object({
  reason: z.string().min(1, 'Skip reason is required'),
})

// Update reminder time schema
export const updateReminderTimeSchema = z.object({
  reminderTime: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Invalid time format. Use HH:mm'),
})

// Dose schedule query schema
export const doseScheduleQuerySchema = z.object({
  date: z.string().datetime().optional(),
  groupBy: z.enum(['TIME_PERIOD']).optional(),
})

// Dose history query schema
export const doseHistoryQuerySchema = z.object({
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  status: z.enum(['DUE', 'TAKEN_ON_TIME', 'TAKEN_LATE', 'MISSED', 'SKIPPED']).optional(),
  page: z.string().transform(Number).pipe(z.number().int().positive()).default('1'),
  limit: z.string().transform(Number).pipe(z.number().int().min(1).max(100)).default('50'),
})

// Export types
export type MarkDoseTaken = z.infer<typeof markDoseTakenSchema>
export type SkipDose = z.infer<typeof skipDoseSchema>
export type UpdateReminderTime = z.infer<typeof updateReminderTimeSchema>
export type DoseScheduleQuery = z.infer<typeof doseScheduleQuerySchema>
export type DoseHistoryQuery = z.infer<typeof doseHistoryQuerySchema>
