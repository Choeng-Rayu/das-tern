import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
    errorFormat: 'pretty',
  })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma

// Middleware for audit logging
prisma.$use(async (params, next) => {
  const before = Date.now()
  const result = await next(params)
  const after = Date.now()

  // Log slow queries in development
  if (process.env.NODE_ENV === 'development' && after - before > 1000) {
    console.warn(`Slow query detected: ${params.model}.${params.action} took ${after - before}ms`)
  }

  return result
})

export default prisma
