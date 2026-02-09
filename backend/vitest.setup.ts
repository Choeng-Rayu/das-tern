import { beforeAll, afterAll, afterEach } from 'vitest'

// Setup environment variables for testing
beforeAll(() => {
  process.env.NEXTAUTH_SECRET = 'test-secret-key-for-testing-only'
  process.env.REDIS_URL = 'redis://localhost:6379'
})

// Cleanup after each test
afterEach(() => {
  // Clear all mocks after each test
})

// Cleanup after all tests
afterAll(() => {
  // Cleanup resources
})
