import { describe, it, expect, vi, beforeEach } from 'vitest'
import { NextRequest } from 'next/server'
import { z } from 'zod'
import { withValidation, withAuthValidation } from './validation'

// Mock the i18n module
vi.mock('../i18n', () => ({
  translate: vi.fn((key: string, lang: string) => key),
  getLanguageFromHeader: vi.fn(() => 'english'),
}))

// Mock the auth module
vi.mock('./auth', () => ({
  withAuth: vi.fn((handler: any) => handler),
}))

describe('withValidation middleware', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('body validation', () => {
    it('should validate and pass valid body data', async () => {
      const schema = z.object({
        name: z.string(),
        age: z.number(),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ name: 'John', age: 30 }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.success).toBe(true)
      expect(data.data).toEqual({ name: 'John', age: 30 })
    })

    it('should return 400 for invalid body data', async () => {
      const schema = z.object({
        name: z.string(),
        age: z.number(),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ name: 'John', age: 'invalid' }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.code).toBe('VALIDATION_ERROR')
      expect(data.error.fields).toBeDefined()
      expect(data.error.fields.age).toBeDefined()
    })

    it('should return 400 for invalid JSON', async () => {
      const schema = z.object({
        name: z.string(),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: 'invalid json{',
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.code).toBe('INVALID_JSON')
    })

    it('should handle missing required fields', async () => {
      const schema = z.object({
        name: z.string(),
        email: z.string().email(),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ name: 'John' }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.fields.email).toBeDefined()
    })

    it('should handle string length validation', async () => {
      const schema = z.object({
        password: z.string().min(6),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ password: '123' }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.fields.password).toBeDefined()
      expect(data.error.fields.password[0]).toContain('at least 6')
    })
  })

  describe('query validation', () => {
    it('should validate and pass valid query parameters', async () => {
      const schema = z.object({
        page: z.string().transform(Number),
        limit: z.string().transform(Number),
      })

      const handler = withValidation({ query: schema })(async (req, { query }) => {
        return Response.json({ success: true, data: query })
      })

      const req = new NextRequest('http://localhost:3000/api/test?page=1&limit=10', {
        method: 'GET',
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.success).toBe(true)
      expect(data.data).toEqual({ page: 1, limit: 10 })
    })

    it('should return 400 for invalid query parameters', async () => {
      const schema = z.object({
        page: z.string().transform((val) => {
          const num = Number(val)
          if (isNaN(num) || num <= 0) {
            throw new Error('Page must be a positive number')
          }
          return num
        }),
      })

      const handler = withValidation({ query: schema })(async (req, { query }) => {
        return Response.json({ success: true, data: query })
      })

      const req = new NextRequest('http://localhost:3000/api/test?page=invalid', {
        method: 'GET',
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.code).toBe('VALIDATION_ERROR')
    })

    it('should handle array query parameters', async () => {
      const schema = z.object({
        tags: z.array(z.string()).optional(),
      })

      const handler = withValidation({ query: schema })(async (req, { query }) => {
        return Response.json({ success: true, data: query })
      })

      const req = new NextRequest('http://localhost:3000/api/test?tags=a&tags=b&tags=c', {
        method: 'GET',
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.data.tags).toEqual(['a', 'b', 'c'])
    })
  })

  describe('params validation', () => {
    it('should validate and pass valid path parameters', async () => {
      const schema = z.object({
        id: z.string().uuid(),
      })

      const handler = withValidation({ params: schema })(async (req, { params }) => {
        return Response.json({ success: true, data: params })
      })

      const validUuid = '123e4567-e89b-12d3-a456-426614174000'
      const req = new NextRequest(`http://localhost:3000/api/test/${validUuid}`, {
        method: 'GET',
      })

      const response = await handler(req, { params: { id: validUuid } })
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.success).toBe(true)
      expect(data.data.id).toBe(validUuid)
    })

    it('should return 400 for invalid path parameters', async () => {
      const schema = z.object({
        id: z.string().uuid(),
      })

      const handler = withValidation({ params: schema })(async (req, { params }) => {
        return Response.json({ success: true, data: params })
      })

      const req = new NextRequest('http://localhost:3000/api/test/invalid-uuid', {
        method: 'GET',
      })

      const response = await handler(req, { params: { id: 'invalid-uuid' } })
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.code).toBe('VALIDATION_ERROR')
      expect(data.error.fields.id).toBeDefined()
    })
  })

  describe('combined validation', () => {
    it('should validate body, query, and params together', async () => {
      const schemas = {
        body: z.object({ name: z.string() }),
        query: z.object({ page: z.string().transform(Number) }),
        params: z.object({ id: z.string().uuid() }),
      }

      const handler = withValidation(schemas)(async (req, { body, query, params }) => {
        return Response.json({ success: true, data: { body, query, params } })
      })

      const validUuid = '123e4567-e89b-12d3-a456-426614174000'
      const req = new NextRequest(`http://localhost:3000/api/test/${validUuid}?page=1`, {
        method: 'POST',
        body: JSON.stringify({ name: 'John' }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req, { params: { id: validUuid } })
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.success).toBe(true)
      expect(data.data.body).toEqual({ name: 'John' })
      expect(data.data.query).toEqual({ page: 1 })
      expect(data.data.params.id).toBe(validUuid)
    })
  })

  describe('error message formatting', () => {
    it('should format enum validation errors', async () => {
      const schema = z.object({
        role: z.enum(['PATIENT', 'DOCTOR', 'FAMILY_MEMBER']),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ role: 'INVALID' }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.fields.role).toBeDefined()
      expect(data.error.fields.role[0]).toContain('one of')
    })

    it('should format type validation errors', async () => {
      const schema = z.object({
        age: z.number(),
        active: z.boolean(),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ age: 'not a number', active: 'not a boolean' }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.fields.age).toBeDefined()
      expect(data.error.fields.active).toBeDefined()
    })

    it('should provide both English and Khmer error messages', async () => {
      const schema = z.object({
        name: z.string(),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ name: 123 }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.messageEn).toBeDefined()
      expect(data.error.messageKm).toBeDefined()
    })
  })

  describe('edge cases', () => {
    it('should handle empty body when schema is not provided', async () => {
      const handler = withValidation({})(async (req, context) => {
        return Response.json({ success: true })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.success).toBe(true)
    })

    it('should handle optional fields correctly', async () => {
      const schema = z.object({
        name: z.string(),
        email: z.string().email().optional(),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ name: 'John' }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.data.name).toBe('John')
      expect(data.data.email).toBeUndefined()
    })

    it('should handle nested object validation', async () => {
      const schema = z.object({
        user: z.object({
          name: z.string(),
          address: z.object({
            street: z.string(),
            city: z.string(),
          }),
        }),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({
          user: {
            name: 'John',
            address: {
              street: '123 Main St',
              city: 'Phnom Penh',
            },
          },
        }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.data.user.name).toBe('John')
      expect(data.data.user.address.city).toBe('Phnom Penh')
    })

    it('should handle array validation', async () => {
      const schema = z.object({
        items: z.array(z.object({
          id: z.string(),
          quantity: z.number(),
        })).min(1),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({
          items: [
            { id: '1', quantity: 5 },
            { id: '2', quantity: 3 },
          ],
        }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.data.items).toHaveLength(2)
    })

    it('should return 400 for empty array when minimum is required', async () => {
      const schema = z.object({
        items: z.array(z.string()).min(1),
      })

      const handler = withValidation({ body: schema })(async (req, { body }) => {
        return Response.json({ success: true, data: body })
      })

      const req = new NextRequest('http://localhost:3000/api/test', {
        method: 'POST',
        body: JSON.stringify({ items: [] }),
        headers: {
          'content-type': 'application/json',
        },
      })

      const response = await handler(req)
      const data = await response.json()

      expect(response.status).toBe(400)
      expect(data.error.fields.items).toBeDefined()
    })
  })
})
