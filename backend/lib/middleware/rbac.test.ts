import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'
import { NextRequest } from 'next/server'
import {
  withRBAC,
  checkPermission,
  getPermissionLevel,
  canAccessPrescription,
  canFamilyMemberAccess,
  validateConnection,
  validatePermission,
  type PermissionLevel,
} from './rbac'
import { AuthContext, AuthUser } from './auth'
import { prisma } from '../prisma'

// Mock Prisma
vi.mock('../prisma', () => ({
  prisma: {
    connection: {
      findFirst: vi.fn(),
    },
    prescription: {
      findUnique: vi.fn(),
    },
  },
}))

// Mock i18n
vi.mock('../i18n', () => ({
  translate: vi.fn((key: string) => key),
  getLanguageFromHeader: vi.fn(() => 'english'),
}))

describe('RBAC Middleware', () => {
  const mockDoctorUser: AuthUser = {
    id: 'doctor-123',
    role: 'DOCTOR',
    language: 'english',
    theme: 'LIGHT',
    subscriptionTier: 'PREMIUM',
  }

  const mockPatientUser: AuthUser = {
    id: 'patient-456',
    role: 'PATIENT',
    language: 'english',
    theme: 'LIGHT',
    subscriptionTier: 'FREEMIUM',
  }

  const mockFamilyUser: AuthUser = {
    id: 'family-789',
    role: 'FAMILY_MEMBER',
    language: 'english',
    theme: 'LIGHT',
    subscriptionTier: 'FREEMIUM',
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('checkPermission', () => {
    it('should allow users to access their own data', async () => {
      const result = await checkPermission('user-123', 'user-123', 'ALLOWED')
      expect(result).toBe(true)
    })

    it('should return false when no connection exists', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue(null)

      const result = await checkPermission('doctor-123', 'patient-456', 'ALLOWED')
      expect(result).toBe(false)
    })

    it('should return true when permission level is ALLOWED', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'ALLOWED',
      } as any)

      const result = await checkPermission('doctor-123', 'patient-456', 'ALLOWED')
      expect(result).toBe(true)
    })

    it('should return false when permission level is NOT_ALLOWED', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'NOT_ALLOWED',
      } as any)

      const result = await checkPermission('doctor-123', 'patient-456', 'ALLOWED')
      expect(result).toBe(false)
    })

    it('should respect permission hierarchy - REQUEST allows REQUEST', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'REQUEST',
      } as any)

      const result = await checkPermission('doctor-123', 'patient-456', 'REQUEST')
      expect(result).toBe(true)
    })

    it('should respect permission hierarchy - REQUEST does not allow ALLOWED', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'REQUEST',
      } as any)

      const result = await checkPermission('doctor-123', 'patient-456', 'ALLOWED')
      expect(result).toBe(false)
    })

    it('should respect permission hierarchy - SELECTED allows REQUEST', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'SELECTED',
      } as any)

      const result = await checkPermission('doctor-123', 'patient-456', 'REQUEST')
      expect(result).toBe(true)
    })

    it('should respect permission hierarchy - ALLOWED allows all levels', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'ALLOWED',
      } as any)

      const resultRequest = await checkPermission('doctor-123', 'patient-456', 'REQUEST')
      const resultSelected = await checkPermission('doctor-123', 'patient-456', 'SELECTED')
      const resultAllowed = await checkPermission('doctor-123', 'patient-456', 'ALLOWED')

      expect(resultRequest).toBe(true)
      expect(resultSelected).toBe(true)
      expect(resultAllowed).toBe(true)
    })

    it('should check both directions of connection', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'ALLOWED',
      } as any)

      await checkPermission('doctor-123', 'patient-456', 'ALLOWED')

      expect(prisma.connection.findFirst).toHaveBeenCalledWith({
        where: {
          OR: [
            { initiatorId: 'doctor-123', recipientId: 'patient-456', status: 'ACCEPTED' },
            { initiatorId: 'patient-456', recipientId: 'doctor-123', status: 'ACCEPTED' },
          ],
        },
        select: {
          permissionLevel: true,
        },
      })
    })
  })

  describe('getPermissionLevel', () => {
    it('should return permission level when connection exists', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'SELECTED',
      } as any)

      const result = await getPermissionLevel('doctor-123', 'patient-456')
      expect(result).toBe('SELECTED')
    })

    it('should return null when no connection exists', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue(null)

      const result = await getPermissionLevel('doctor-123', 'patient-456')
      expect(result).toBeNull()
    })
  })

  describe('withRBAC', () => {
    it('should call handler with RBAC context', async () => {
      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler)

      const req = new NextRequest('http://localhost/api/test')
      const context: AuthContext = {
        user: mockDoctorUser,
        req,
      }

      await wrappedHandler(req, context)

      expect(mockHandler).toHaveBeenCalledWith(
        req,
        expect.objectContaining({
          user: mockDoctorUser,
          checkPermission: expect.any(Function),
          getPermissionLevel: expect.any(Function),
        })
      )
    })

    it('should enforce role-based access control', async () => {
      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, { requiredRole: 'DOCTOR' })

      const req = new NextRequest('http://localhost/api/test')
      const context: AuthContext = {
        user: mockPatientUser,
        req,
      }

      const response = await wrappedHandler(req, context)
      const data = await response.json()

      expect(response.status).toBe(403)
      expect(data.error.code).toBe('FORBIDDEN')
      expect(mockHandler).not.toHaveBeenCalled()
    })

    it('should allow access when role matches', async () => {
      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, { requiredRole: 'DOCTOR' })

      const req = new NextRequest('http://localhost/api/test')
      const context: AuthContext = {
        user: mockDoctorUser,
        req,
      }

      await wrappedHandler(req, context)

      expect(mockHandler).toHaveBeenCalled()
    })

    it('should support multiple required roles', async () => {
      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, {
        requiredRole: ['DOCTOR', 'PATIENT'],
      })

      const req = new NextRequest('http://localhost/api/test')
      const contextDoctor: AuthContext = {
        user: mockDoctorUser,
        req,
      }
      const contextPatient: AuthContext = {
        user: mockPatientUser,
        req,
      }

      await wrappedHandler(req, contextDoctor)
      await wrappedHandler(req, contextPatient)

      expect(mockHandler).toHaveBeenCalledTimes(2)
    })

    it('should auto-check patientId when enabled', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'ALLOWED',
      } as any)

      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, {
        autoCheckPatientId: true,
        requiredPermission: 'ALLOWED',
      })

      const req = new NextRequest('http://localhost/api/test?patientId=patient-456')
      const context: AuthContext = {
        user: mockDoctorUser,
        req,
      }

      await wrappedHandler(req, context)

      expect(mockHandler).toHaveBeenCalled()
    })

    it('should deny access when auto-check fails', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'NOT_ALLOWED',
      } as any)

      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, {
        autoCheckPatientId: true,
        requiredPermission: 'ALLOWED',
      })

      const req = new NextRequest('http://localhost/api/test?patientId=patient-456')
      const context: AuthContext = {
        user: mockDoctorUser,
        req,
      }

      const response = await wrappedHandler(req, context)
      const data = await response.json()

      expect(response.status).toBe(403)
      expect(data.error.code).toBe('FORBIDDEN')
      expect(mockHandler).not.toHaveBeenCalled()
    })

    it('should skip auto-check when patientId matches user id', async () => {
      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, {
        autoCheckPatientId: true,
      })

      const req = new NextRequest('http://localhost/api/test?patientId=patient-456')
      const context: AuthContext = {
        user: mockPatientUser,
        req,
      }

      await wrappedHandler(req, context)

      expect(mockHandler).toHaveBeenCalled()
      expect(prisma.connection.findFirst).not.toHaveBeenCalled()
    })

    it('should provide appropriate error message for NOT_ALLOWED', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'NOT_ALLOWED',
      } as any)

      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, {
        autoCheckPatientId: true,
      })

      const req = new NextRequest('http://localhost/api/test?patientId=patient-456')
      const context: AuthContext = {
        user: mockDoctorUser,
        req,
      }

      const response = await wrappedHandler(req, context)
      const data = await response.json()

      expect(data.error.messageEn).toContain('not allowed')
    })

    it('should provide appropriate error message for REQUEST', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'REQUEST',
      } as any)

      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, {
        autoCheckPatientId: true,
        requiredPermission: 'ALLOWED',
      })

      const req = new NextRequest('http://localhost/api/test?patientId=patient-456')
      const context: AuthContext = {
        user: mockDoctorUser,
        req,
      }

      const response = await wrappedHandler(req, context)
      const data = await response.json()

      expect(data.error.messageEn).toContain('request explicit approval')
    })

    it('should provide appropriate error message for SELECTED', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'SELECTED',
      } as any)

      const mockHandler = vi.fn().mockResolvedValue(new Response('OK'))
      const wrappedHandler = withRBAC(mockHandler, {
        autoCheckPatientId: true,
        requiredPermission: 'ALLOWED',
      })

      const req = new NextRequest('http://localhost/api/test?patientId=patient-456')
      const context: AuthContext = {
        user: mockDoctorUser,
        req,
      }

      const response = await wrappedHandler(req, context)
      const data = await response.json()

      expect(data.error.messageEn).toContain('selected prescriptions')
    })
  })

  describe('canAccessPrescription', () => {
    it('should allow doctor who created the prescription', async () => {
      vi.mocked(prisma.prescription.findUnique).mockResolvedValue({
        id: 'prescription-123',
        patientId: 'patient-456',
        doctorId: 'doctor-123',
      } as any)

      const result = await canAccessPrescription('doctor-123', 'prescription-123')
      expect(result).toBe(true)
    })

    it('should check permission for other doctors', async () => {
      vi.mocked(prisma.prescription.findUnique).mockResolvedValue({
        id: 'prescription-123',
        patientId: 'patient-456',
        doctorId: 'doctor-999',
      } as any)

      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'ALLOWED',
      } as any)

      const result = await canAccessPrescription('doctor-123', 'prescription-123')
      expect(result).toBe(true)
    })

    it('should return false when prescription does not exist', async () => {
      vi.mocked(prisma.prescription.findUnique).mockResolvedValue(null)

      const result = await canAccessPrescription('doctor-123', 'prescription-123')
      expect(result).toBe(false)
    })

    it('should return false when permission is insufficient', async () => {
      vi.mocked(prisma.prescription.findUnique).mockResolvedValue({
        id: 'prescription-123',
        patientId: 'patient-456',
        doctorId: 'doctor-999',
      } as any)

      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'NOT_ALLOWED',
      } as any)

      const result = await canAccessPrescription('doctor-123', 'prescription-123')
      expect(result).toBe(false)
    })
  })

  describe('canFamilyMemberAccess', () => {
    it('should return true when connection exists', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'ALLOWED',
      } as any)

      const result = await canFamilyMemberAccess('family-789', 'patient-456')
      expect(result).toBe(true)
    })

    it('should return false when no connection exists', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue(null)

      const result = await canFamilyMemberAccess('family-789', 'patient-456')
      expect(result).toBe(false)
    })
  })

  describe('validateConnection', () => {
    it('should not throw when connection exists', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'ALLOWED',
      } as any)

      await expect(
        validateConnection('doctor-123', 'patient-456')
      ).resolves.not.toThrow()
    })

    it('should throw when connection does not exist', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue(null)

      await expect(
        validateConnection('doctor-123', 'patient-456')
      ).rejects.toThrow('No accepted connection')
    })

    it('should throw with Khmer message when language is khmer', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue(null)

      await expect(
        validateConnection('doctor-123', 'patient-456', 'khmer')
      ).rejects.toThrow('មិនមានការតភ្ជាប់')
    })
  })

  describe('validatePermission', () => {
    it('should not throw when permission is sufficient', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'ALLOWED',
      } as any)

      await expect(
        validatePermission('doctor-123', 'patient-456', 'ALLOWED')
      ).resolves.not.toThrow()
    })

    it('should throw when permission is insufficient', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'REQUEST',
      } as any)

      await expect(
        validatePermission('doctor-123', 'patient-456', 'ALLOWED')
      ).rejects.toThrow('sufficient permission')
    })

    it('should throw with Khmer message when language is khmer', async () => {
      vi.mocked(prisma.connection.findFirst).mockResolvedValue({
        permissionLevel: 'REQUEST',
      } as any)

      await expect(
        validatePermission('doctor-123', 'patient-456', 'ALLOWED', 'khmer')
      ).rejects.toThrow('មិនមានការអនុញ្ញាតគ្រប់គ្រាន់')
    })
  })
})
