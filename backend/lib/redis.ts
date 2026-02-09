import Redis from 'ioredis'

const getRedisUrl = () => {
  if (process.env.REDIS_URL) {
    return process.env.REDIS_URL
  }
  throw new Error('REDIS_URL is not defined')
}

// Create Redis client
export const redis = new Redis(getRedisUrl(), {
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000)
    return delay
  },
  reconnectOnError: (err) => {
    const targetError = 'READONLY'
    if (err.message.includes(targetError)) {
      // Only reconnect when the error contains "READONLY"
      return true
    }
    return false
  },
})

redis.on('connect', () => {
  console.log('✅ Redis connected')
})

redis.on('error', (err) => {
  console.error('❌ Redis error:', err)
})

// Cache helper functions
export const cache = {
  // Get cached data
  async get<T>(key: string): Promise<T | null> {
    try {
      const data = await redis.get(key)
      return data ? JSON.parse(data) : null
    } catch (error) {
      console.error(`Cache get error for key ${key}:`, error)
      return null
    }
  },

  // Set cached data with TTL (in seconds)
  async set(key: string, value: any, ttl: number = 300): Promise<void> {
    try {
      await redis.setex(key, ttl, JSON.stringify(value))
    } catch (error) {
      console.error(`Cache set error for key ${key}:`, error)
    }
  },

  // Delete cached data
  async del(key: string): Promise<void> {
    try {
      await redis.del(key)
    } catch (error) {
      console.error(`Cache delete error for key ${key}:`, error)
    }
  },

  // Delete multiple keys by pattern
  async delPattern(pattern: string): Promise<void> {
    try {
      const keys = await redis.keys(pattern)
      if (keys.length > 0) {
        await redis.del(...keys)
      }
    } catch (error) {
      console.error(`Cache delete pattern error for ${pattern}:`, error)
    }
  },

  // Check if key exists
  async exists(key: string): Promise<boolean> {
    try {
      const result = await redis.exists(key)
      return result === 1
    } catch (error) {
      console.error(`Cache exists error for key ${key}:`, error)
      return false
    }
  },

  // Increment counter
  async incr(key: string): Promise<number> {
    try {
      return await redis.incr(key)
    } catch (error) {
      console.error(`Cache incr error for key ${key}:`, error)
      return 0
    }
  },

  // Set expiration
  async expire(key: string, seconds: number): Promise<void> {
    try {
      await redis.expire(key, seconds)
    } catch (error) {
      console.error(`Cache expire error for key ${key}:`, error)
    }
  },
}

export default redis
