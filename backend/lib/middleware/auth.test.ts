import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { NextRequest } from 'next/server'
import { type AuthUser } from './auth'

// Mock dependencies BEFORE importing the module
vi.mock('next-auth/jwt', () => ({
  getToken: vi.fn(),
}))

vi.mock('../redis', () => ({
  cache: {
    exists: vi.fn(),
    set: vi.fn(),
    get: vi.fn(),
    del: vi.fn(),
  },
  redis: {},
}))

// Now import the modules that depend on the mocks
import { withAuth, withOptionalAuth, blacklistToken, isTokenBlacklisted, validateToken } from './auth'
import { getToken } from 'next-auth/jwt'
import { cache } from '../redis'

const mockGetToken = vi.mocked(getToken)
const mockCache = vi.mocked(cache)

describe('JWT Authentication Middleware', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    process.env.NEXTAUTH_SECRET = 'test-secret'
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('withAuth', () => {
    it('should authenticate valid token and call handler', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) + 3600, // 1 hour from now
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(false)

      const mockHandler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const authenticatedHandler = withAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer valid-token',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(mockGetToken).toHaveBeenCalledWith({
        req: expect.any(Object),
        secret: 'test-secret',
      })
      expect(mockCache.exists).toHaveBeenCalledWith('blacklist:token:user-123')
      expect(mockHandler).toHaveBeenCalledWith(
        req,
        expect.objectContaining({
          user: {
            id: 'user-123',
            role: 'PATIENT',
            language: 'english',
            theme: 'LIGHT',
            subscriptionTier: 'FREEMIUM',
          },
        })
      )
      expect(response.status).toBe(200)
    })

    it('should return 401 when authorization header is missing', async () => {
      // Arrange
      const mockHandler = vi.fn()
      const authenticatedHandler = withAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test')

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(401)
      expect(mockHandler).not.toHaveBeenCalled()
      
      const body = await response.json()
      expect(body.error.code).toBe('UNAUTHORIZED')
      expect(body.error.message).toContain('authorization header')
    })

    it('should return 401 when authorization header is invalid format', async () => {
      // Arrange
      const mockHandler = vi.fn()
      const authenticatedHandler = withAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'InvalidFormat token',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(401)
      expect(mockHandler).not.toHaveBeenCalled()
    })

    it('should return 401 when token is invalid', async () => {
      // Arrange
      mockGetToken.mockResolvedValue(null)

      const mockHandler = vi.fn()
      const authenticatedHandler = withAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer invalid-token',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(401)
      expect(mockHandler).not.toHaveBeenCalled()
      
      const body = await response.json()
      expect(body.error.message).toContain('Invalid or expired token')
    })

    it('should return 401 when token is expired', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) - 3600, // 1 hour ago
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(false)

      const mockHandler = vi.fn()
      const authenticatedHandler = withAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer expired-token',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(401)
      expect(mockHandler).not.toHaveBeenCalled()
      
      const body = await response.json()
      expect(body.error.message).toContain('expired')
    })

    it('should return 401 when token is blacklisted', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) + 3600,
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(true) // Token is blacklisted

      const mockHandler = vi.fn()
      const authenticatedHandler = withAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer blacklisted-token',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(401)
      expect(mockHandler).not.toHaveBeenCalled()
      
      const body = await response.json()
      expect(body.error.message).toContain('revoked')
    })

    it('should return 403 when user role does not match required role', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) + 3600,
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(false)

      const mockHandler = vi.fn()
      const authenticatedHandler = withAuth(mockHandler, {
        requiredRole: 'DOCTOR',
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer valid-token',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(403)
      expect(mockHandler).not.toHaveBeenCalled()
      
      const body = await response.json()
      expect(body.error.message).toContain('Access denied')
    })

    it('should allow access when user role matches one of required roles', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'DOCTOR',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'PREMIUM',
        exp: Math.floor(Date.now() / 1000) + 3600,
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(false)

      const mockHandler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const authenticatedHandler = withAuth(mockHandler, {
        requiredRole: ['DOCTOR', 'PATIENT'] as any,
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer valid-token',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(200)
      expect(mockHandler).toHaveBeenCalled()
    })

    it('should return Khmer error messages when Accept-Language is Khmer', async () => {
      // Arrange
      mockGetToken.mockResolvedValue(null)

      const mockHandler = vi.fn()
      const authenticatedHandler = withAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer invalid-token',
          'accept-language': 'km-KH',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(401)
      
      const body = await response.json()
      expect(body.error.messageKm).toBeDefined()
      expect(body.error.messageEn).toBeDefined()
    })

    it('should return 401 when token payload is missing required fields', async () => {
      // Arrange
      const mockToken = {
        sub: 'user-123',
        // Missing id and role
        language: 'english',
        theme: 'LIGHT',
        exp: Math.floor(Date.now() / 1000) + 3600,
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(false)

      const mockHandler = vi.fn()
      const authenticatedHandler = withAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer incomplete-token',
        },
      })

      // Act
      const response = await authenticatedHandler(req)

      // Assert
      expect(response.status).toBe(401)
      expect(mockHandler).not.toHaveBeenCalled()
      
      const body = await response.json()
      expect(body.error.message).toContain('Invalid token payload')
    })
  })

  describe('withOptionalAuth', () => {
    it('should call handler with user when valid token is provided', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) + 3600,
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(false)

      const mockHandler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const optionalAuthHandler = withOptionalAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer valid-token',
        },
      })

      // Act
      const response = await optionalAuthHandler(req)

      // Assert
      expect(mockHandler).toHaveBeenCalledWith(
        req,
        expect.objectContaining({
          user: {
            id: 'user-123',
            role: 'PATIENT',
            language: 'english',
            theme: 'LIGHT',
            subscriptionTier: 'FREEMIUM',
          },
        })
      )
      expect(response.status).toBe(200)
    })

    it('should call handler with null user when no token is provided', async () => {
      // Arrange
      mockGetToken.mockResolvedValue(null)

      const mockHandler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const optionalAuthHandler = withOptionalAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test')

      // Act
      const response = await optionalAuthHandler(req)

      // Assert
      expect(mockHandler).toHaveBeenCalledWith(
        req,
        expect.objectContaining({
          user: null,
        })
      )
      expect(response.status).toBe(200)
    })

    it('should call handler with null user when token is blacklisted', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) + 3600,
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(true) // Blacklisted

      const mockHandler = vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ success: true }), { status: 200 })
      )

      const optionalAuthHandler = withOptionalAuth(mockHandler)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer blacklisted-token',
        },
      })

      // Act
      const response = await optionalAuthHandler(req)

      // Assert
      expect(mockHandler).toHaveBeenCalledWith(
        req,
        expect.objectContaining({
          user: null,
        })
      )
    })
  })

  describe('blacklistToken', () => {
    it('should add token to blacklist with expiration', async () => {
      // Arrange
      const tokenId = 'token-123'
      const expiresIn = 900 // 15 minutes

      mockCache.set.mockResolvedValue(undefined)

      // Act
      await blacklistToken(tokenId, expiresIn)

      // Assert
      expect(mockCache.set).toHaveBeenCalledWith(
        'blacklist:token:token-123',
        true,
        900
      )
    })

    it('should throw error when blacklisting fails', async () => {
      // Arrange
      const tokenId = 'token-123'
      const expiresIn = 900

      mockCache.set.mockRejectedValue(new Error('Redis error'))

      // Act & Assert
      await expect(blacklistToken(tokenId, expiresIn)).rejects.toThrow(
        'Failed to blacklist token'
      )
    })
  })

  describe('isTokenBlacklisted', () => {
    it('should return true when token is blacklisted', async () => {
      // Arrange
      const tokenId = 'token-123'
      mockCache.exists.mockResolvedValue(true)

      // Act
      const result = await isTokenBlacklisted(tokenId)

      // Assert
      expect(result).toBe(true)
      expect(mockCache.exists).toHaveBeenCalledWith('blacklist:token:token-123')
    })

    it('should return false when token is not blacklisted', async () => {
      // Arrange
      const tokenId = 'token-123'
      mockCache.exists.mockResolvedValue(false)

      // Act
      const result = await isTokenBlacklisted(tokenId)

      // Assert
      expect(result).toBe(false)
    })

    it('should return false when check fails', async () => {
      // Arrange
      const tokenId = 'token-123'
      mockCache.exists.mockRejectedValue(new Error('Redis error'))

      // Act
      const result = await isTokenBlacklisted(tokenId)

      // Assert
      expect(result).toBe(false)
    })
  })

  describe('validateToken', () => {
    it('should return user when token is valid', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) + 3600,
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(false)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer valid-token',
        },
      })

      // Act
      const user = await validateToken(req)

      // Assert
      expect(user).toEqual({
        id: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
      })
    })

    it('should return null when token is invalid', async () => {
      // Arrange
      mockGetToken.mockResolvedValue(null)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer invalid-token',
        },
      })

      // Act
      const user = await validateToken(req)

      // Assert
      expect(user).toBeNull()
    })

    it('should return null when token is blacklisted', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) + 3600,
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(true)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer blacklisted-token',
        },
      })

      // Act
      const user = await validateToken(req)

      // Assert
      expect(user).toBeNull()
    })

    it('should return null when token is expired', async () => {
      // Arrange
      const mockToken = {
        id: 'user-123',
        sub: 'user-123',
        role: 'PATIENT',
        language: 'english',
        theme: 'LIGHT',
        subscriptionTier: 'FREEMIUM',
        exp: Math.floor(Date.now() / 1000) - 3600, // Expired
      }

      mockGetToken.mockResolvedValue(mockToken as any)
      mockCache.exists.mockResolvedValue(false)

      const req = new NextRequest('http://localhost:3000/api/test', {
        headers: {
          authorization: 'Bearer expired-token',
        },
      })

      // Act
      const user = await validateToken(req)

      // Assert
      expect(user).toBeNull()
    })
  })
})
