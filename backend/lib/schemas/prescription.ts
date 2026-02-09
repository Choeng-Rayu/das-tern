import { z } from 'zod'

// Dosage schema for medication grid
export const dosageSchema = z.object({
  amount: z.string().min(1, 'Dosage amount is required'),
  beforeMeal: z.boolean(),
}).optional()

// Medication schema for prescription creation
export const medicationSchema = z.object({
  rowNumber: z.number().int().positive(),
  medicineName: z.string().min(1, 'Medicine name is required'),
  medicineNameKhmer: z.string().optional(),
  imageUrl: z.string().url().optional(),
  morningDosage: dosageSchema,
  daytimeDosage: dosageSchema,
  nightDosage: dosageSchema,
  frequency: z.string().optional(),
  timing: z.string().optional(),
}).refine(
  (data) => data.morningDosage || data.daytimeDosage || data.nightDosage,
  {
    message: 'At least one dosage (morning, daytime, or night) must be specified',
  }
)

// Prescription creation schema
export const prescriptionCreateSchema = z.object({
  patientId: z.string().uuid('Invalid patient ID'),
  patientName: z.string().min(1, 'Patient name is required'),
  patientGender: z.enum(['MALE', 'FEMALE', 'OTHER']),
  patientAge: z.number().int().min(0).max(150),
  symptoms: z.string().min(1, 'Symptoms are required'),
  medications: z.array(medicationSchema).min(1, 'At least one medication is required'),
  status: z.enum(['DRAFT', 'ACTIVE']).default('DRAFT'),
  isUrgent: z.boolean().default(false),
  urgentReason: z.string().optional(),
}).refine(
  (data) => {
    // If urgent, reason is required
    if (data.isUrgent && !data.urgentReason) {
      return false
    }
    return true
  },
  {
    message: 'Urgent reason is required when prescription is marked as urgent',
    path: ['urgentReason'],
  }
)

// Prescription update schema
export const prescriptionUpdateSchema = z.object({
  status: z.enum(['DRAFT', 'ACTIVE', 'PAUSED', 'INACTIVE']).optional(),
  medications: z.array(medicationSchema).optional(),
  isUrgent: z.boolean().optional(),
  urgentReason: z.string().optional(),
  symptoms: z.string().optional(),
}).refine(
  (data) => {
    // If urgent, reason is required
    if (data.isUrgent && !data.urgentReason) {
      return false
    }
    return true
  },
  {
    message: 'Urgent reason is required when prescription is marked as urgent',
    path: ['urgentReason'],
  }
)

// Prescription confirm schema (patient accepting prescription)
export const prescriptionConfirmSchema = z.object({
  confirmed: z.boolean(),
})

// Prescription retake schema (patient requesting revision)
export const prescriptionRetakeSchema = z.object({
  reason: z.string().min(1, 'Reason for retake is required'),
})

// Prescription query filters
export const prescriptionQuerySchema = z.object({
  patientId: z.string().uuid().optional(),
  doctorId: z.string().uuid().optional(),
  status: z.enum(['DRAFT', 'ACTIVE', 'PAUSED', 'INACTIVE']).optional(),
  page: z.string().transform(Number).pipe(z.number().int().positive()).default('1'),
  limit: z.string().transform(Number).pipe(z.number().int().min(1).max(100)).default('50'),
})

// Export types
export type PrescriptionCreate = z.infer<typeof prescriptionCreateSchema>
export type PrescriptionUpdate = z.infer<typeof prescriptionUpdateSchema>
export type PrescriptionConfirm = z.infer<typeof prescriptionConfirmSchema>
export type PrescriptionRetake = z.infer<typeof prescriptionRetakeSchema>
export type PrescriptionQuery = z.infer<typeof prescriptionQuerySchema>
export type Medication = z.infer<typeof medicationSchema>
export type Dosage = z.infer<typeof dosageSchema>
