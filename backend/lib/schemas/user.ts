import { z } from 'zod'
import {
  phoneNumberSchema,
  emailSchema,
  passwordSchema,
  pinCodeSchema,
  dateOfBirthSchema,
  genderSchema,
  languageSchema,
  themeSchema,
  userRoleSchema,
  subscriptionTierSchema,
  doctorSpecialtySchema,
  nonEmptyStringSchema,
  uuidSchema,
  optional,
} from './common'

/**
 * Patient registration schema
 */
export const patientRegistrationSchema = z.object({
  lastName: nonEmptyStringSchema.describe('Patient last name'),
  firstName: nonEmptyStringSchema.describe('Patient first name'),
  gender: genderSchema.describe('Patient gender'),
  dateOfBirth: dateOfBirthSchema.describe('Patient date of birth (must be at least 13 years old)'),
  idCardNumber: nonEmptyStringSchema.describe('National ID card number'),
  phoneNumber: phoneNumberSchema.describe('Phone number in Cambodia format (+855...)'),
  password: passwordSchema.describe('Password (minimum 6 characters)'),
  pinCode: pinCodeSchema.describe('4-digit PIN code for quick access'),
})

/**
 * Doctor registration schema
 */
export const doctorRegistrationSchema = z.object({
  fullName: nonEmptyStringSchema.describe('Doctor full name'),
  phoneNumber: phoneNumberSchema.describe('Phone number in Cambodia format (+855...)'),
  hospitalClinic: nonEmptyStringSchema.describe('Hospital or clinic name'),
  specialty: doctorSpecialtySchema.describe('Medical specialty'),
  licenseNumber: nonEmptyStringSchema.describe('Medical license number'),
  password: passwordSchema.describe('Password (minimum 6 characters)'),
  // Note: licensePhoto is handled separately as multipart/form-data
})

/**
 * Family member registration schema
 */
export const familyMemberRegistrationSchema = z.object({
  fullName: nonEmptyStringSchema.describe('Family member full name'),
  phoneNumber: phoneNumberSchema.describe('Phone number in Cambodia format (+855...)'),
  email: optional(emailSchema).describe('Email address (optional)'),
  password: passwordSchema.describe('Password (minimum 6 characters)'),
  relationshipToPatient: nonEmptyStringSchema.describe('Relationship to patient (e.g., spouse, child, parent)'),
})

/**
 * OTP send schema
 */
export const otpSendSchema = z.object({
  phoneNumber: phoneNumberSchema.describe('Phone number to send OTP to'),
})

/**
 * OTP verify schema
 */
export const otpVerifySchema = z.object({
  phoneNumber: phoneNumberSchema.describe('Phone number that received the OTP'),
  otp: z
    .string()
    .regex(/^\d{4}$/, { message: 'OTP must be exactly 4 digits' })
    .describe('4-digit OTP code'),
})

/**
 * Login schema
 */
export const loginSchema = z.object({
  identifier: z
    .string()
    .min(1, { message: 'Phone number or email is required' })
    .describe('Phone number or email address'),
  password: passwordSchema.describe('Password'),
})

/**
 * Refresh token schema
 */
export const refreshTokenSchema = z.object({
  refreshToken: nonEmptyStringSchema.describe('Refresh token'),
})

/**
 * User profile update schema
 */
export const userProfileUpdateSchema = z.object({
  firstName: optional(nonEmptyStringSchema).describe('First name'),
  lastName: optional(nonEmptyStringSchema).describe('Last name'),
  fullName: optional(nonEmptyStringSchema).describe('Full name'),
  email: optional(emailSchema).describe('Email address'),
  language: optional(languageSchema).describe('Preferred language'),
  theme: optional(themeSchema).describe('Preferred theme'),
  phoneNumber: optional(phoneNumberSchema).describe('Phone number'),
})

/**
 * Change password schema
 */
export const changePasswordSchema = z.object({
  currentPassword: passwordSchema.describe('Current password'),
  newPassword: passwordSchema.describe('New password (minimum 6 characters)'),
  confirmPassword: passwordSchema.describe('Confirm new password'),
})
  .refine((data) => data.newPassword === data.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  })
  .refine((data) => data.currentPassword !== data.newPassword, {
    message: 'New password must be different from current password',
    path: ['newPassword'],
  })

/**
 * Change PIN code schema
 */
export const changePinCodeSchema = z.object({
  currentPinCode: pinCodeSchema.describe('Current PIN code'),
  newPinCode: pinCodeSchema.describe('New 4-digit PIN code'),
  confirmPinCode: pinCodeSchema.describe('Confirm new PIN code'),
})
  .refine((data) => data.newPinCode === data.confirmPinCode, {
    message: 'PIN codes do not match',
    path: ['confirmPinCode'],
  })
  .refine((data) => data.currentPinCode !== data.newPinCode, {
    message: 'New PIN code must be different from current PIN code',
    path: ['newPinCode'],
  })

/**
 * User profile response schema
 */
export const userProfileSchema = z.object({
  id: uuidSchema.describe('User ID'),
  role: userRoleSchema.describe('User role'),
  firstName: optional(z.string()).describe('First name (for patients)'),
  lastName: optional(z.string()).describe('Last name (for patients)'),
  fullName: optional(z.string()).describe('Full name (for doctors and family members)'),
  phoneNumber: z.string().describe('Phone number'),
  email: optional(z.string()).describe('Email address'),
  language: languageSchema.describe('Preferred language'),
  theme: themeSchema.describe('Preferred theme'),
  subscriptionTier: subscriptionTierSchema.describe('Subscription tier'),
  storageUsed: z.number().nonnegative().describe('Storage used in bytes'),
  storageQuota: z.number().positive().describe('Storage quota in bytes'),
  storagePercentage: z.number().min(0).max(100).describe('Storage usage percentage'),
  dailyProgress: optional(z.number().min(0).max(100)).describe('Daily medication progress (for patients)'),
  hospitalClinic: optional(z.string()).describe('Hospital/clinic name (for doctors)'),
  specialty: optional(z.string()).describe('Medical specialty (for doctors)'),
  accountStatus: z.string().describe('Account status'),
  createdAt: z.string().datetime().describe('Account creation timestamp'),
})

/**
 * Storage info schema
 */
export const storageInfoSchema = z.object({
  used: z.number().nonnegative().describe('Storage used in bytes'),
  quota: z.number().positive().describe('Storage quota in bytes'),
  percentage: z.number().min(0).max(100).describe('Storage usage percentage'),
  breakdown: z.object({
    prescriptions: z.number().nonnegative().describe('Storage used by prescriptions'),
    doseEvents: z.number().nonnegative().describe('Storage used by dose events'),
    auditLogs: z.number().nonnegative().describe('Storage used by audit logs'),
    files: z.number().nonnegative().describe('Storage used by uploaded files'),
  }),
})

/**
 * User ID parameter schema
 */
export const userIdParamSchema = z.object({
  userId: uuidSchema.describe('User ID'),
})

/**
 * Type exports for TypeScript
 */
export type PatientRegistration = z.infer<typeof patientRegistrationSchema>
export type DoctorRegistration = z.infer<typeof doctorRegistrationSchema>
export type FamilyMemberRegistration = z.infer<typeof familyMemberRegistrationSchema>
export type OtpSend = z.infer<typeof otpSendSchema>
export type OtpVerify = z.infer<typeof otpVerifySchema>
export type Login = z.infer<typeof loginSchema>
export type RefreshToken = z.infer<typeof refreshTokenSchema>
export type UserProfileUpdate = z.infer<typeof userProfileUpdateSchema>
export type ChangePassword = z.infer<typeof changePasswordSchema>
export type ChangePinCode = z.infer<typeof changePinCodeSchema>
export type UserProfile = z.infer<typeof userProfileSchema>
export type StorageInfo = z.infer<typeof storageInfoSchema>
export type UserIdParam = z.infer<typeof userIdParamSchema>
