const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

async function main() {
  try {
    console.log('Testing database connection...')
    const result = await prisma.$queryRaw`SELECT 1 as test`
    console.log('✅ Database connection successful:', result)
    
    // Check if tables exist
    const users = await prisma.user.count()
    console.log(`📊 Users in database: ${users}`)
    
    const prescriptions = await prisma.prescription.count()
    console.log(`📊 Prescriptions in database: ${prescriptions}`)
    
    const doseEvents = await prisma.doseEvent.count()
    console.log(`📊 Dose events in database: ${doseEvents}`)
    
  } catch (error) {
    console.error('❌ Database connection failed:', error.message)
    process.exit(1)
  } finally {
    await prisma.$disconnect()
  }
}

main()
