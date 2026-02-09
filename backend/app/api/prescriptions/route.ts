import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'
import { withValidation } from '@/lib/middleware/validation'
import { prescriptionCreateSchema, prescriptionQuerySchema } from '@/lib/schemas/prescription'
import { prisma } from '@/lib/prisma'
import { generateDoseEventsFromPrescription } from '@/lib/services/doseGenerator'

/**
 * POST /api/prescriptions
 * Create a new prescription with medications
 * 
 * This is the core MVP endpoint for creating medicine prescriptions
 * Automatically generates dose events (reminders) when status is ACTIVE
 */
export const POST = withAuth(
  withValidation(prescriptionCreateSchema)(async (req, { user, body }) => {
    try {
      // Only doctors can create prescriptions
      if (user.role !== 'DOCTOR') {
        return Response.json(
          {
            error: {
              message: 'Only doctors can create prescriptions',
              messageEn: 'Only doctors can create prescriptions',
              messageKm: 'មានតែវេជ្ជបណ្ឌិតទេដែលអាចបង្កើតវេជ្ជបញ្ជា',
              code: 'FORBIDDEN',
            },
          },
          { status: 403 }
        )
      }

      // Verify patient exists
      const patient = await prisma.user.findUnique({
        where: { id: body.patientId },
      })

      if (!patient || patient.role !== 'PATIENT') {
        return Response.json(
          {
            error: {
              message: 'Patient not found',
              messageEn: 'Patient not found',
              messageKm: 'រកមិនឃើញអ្នកជំងឺ',
              code: 'NOT_FOUND',
            },
          },
          { status: 404 }
        )
      }

      // TODO: Verify doctor-patient connection and permissions
      // For MVP, we'll skip this check

      // Create prescription with medications in a transaction
      const prescription = await prisma.$transaction(async (tx) => {
        // Create prescription
        const newPrescription = await tx.prescription.create({
          data: {
            patientId: body.patientId,
            doctorId: user.id,
            patientName: body.patientName,
            patientGender: body.patientGender,
            patientAge: body.patientAge,
            symptoms: body.symptoms,
            status: body.status,
            isUrgent: body.isUrgent,
            urgentReason: body.urgentReason,
            currentVersion: 1,
          },
        })

        // Create medications
        const medications = await Promise.all(
          body.medications.map((med) =>
            tx.medication.create({
              data: {
                prescriptionId: newPrescription.id,
                rowNumber: med.rowNumber,
                medicineName: med.medicineName,
                medicineNameKhmer: med.medicineNameKhmer,
                imageUrl: med.imageUrl,
                morningDosage: med.morningDosage,
                daytimeDosage: med.daytimeDosage,
                nightDosage: med.nightDosage,
                frequency: med.frequency,
                timing: med.timing,
              },
            })
          )
        )

        // Create initial version
        await tx.prescriptionVersion.create({
          data: {
            prescriptionId: newPrescription.id,
            versionNumber: 1,
            authorId: user.id,
            changeReason: 'Initial prescription',
            medicationsSnapshot: body.medications,
          },
        })

        return { ...newPrescription, medications }
      })

      // Generate dose events if prescription is active
      if (body.status === 'ACTIVE') {
        await generateDoseEventsFromPrescription(prescription.id)
      }

      // TODO: Create audit log entry
      // TODO: Send notification to patient

      return Response.json(
        {
          message: 'Prescription created successfully',
          messageEn: 'Prescription created successfully',
          messageKm: 'បង្កើតវេជ្ជបញ្ជាបានជោគជ័យ',
          prescription: {
            id: prescription.id,
            patientId: prescription.patientId,
            patientName: prescription.patientName,
            status: prescription.status,
            isUrgent: prescription.isUrgent,
            medications: prescription.medications,
            createdAt: prescription.createdAt,
          },
        },
        { status: 201 }
      )
    } catch (error) {
      console.error('Error creating prescription:', error)
      
      return Response.json(
        {
          error: {
            message: 'Failed to create prescription',
            messageEn: 'Failed to create prescription',
            messageKm: 'បរាជ័យក្នុងការបង្កើតវេជ្ជបញ្ជា',
            code: 'INTERNAL_ERROR',
          },
        },
        { status: 500 }
      )
    }
  })
)

/**
 * GET /api/prescriptions
 * Get prescriptions with optional filters
 */
export const GET = withAuth(async (req, { user }) => {
  try {
    const url = new URL(req.url)
    const query: any = {}
    
    url.searchParams.forEach((value, key) => {
      query[key] = value
    })

    // Validate query parameters
    const validatedQuery = prescriptionQuerySchema.parse(query)

    // Build where clause based on user role
    const where: any = {}

    if (user.role === 'PATIENT') {
      // Patients can only see their own prescriptions
      where.patientId = user.id
    } else if (user.role === 'DOCTOR') {
      // Doctors can see prescriptions they created
      where.doctorId = user.id
      
      // Or filter by patient if specified
      if (validatedQuery.patientId) {
        where.patientId = validatedQuery.patientId
        delete where.doctorId
      }
    }

    // Add status filter if specified
    if (validatedQuery.status) {
      where.status = validatedQuery.status
    }

    // Calculate pagination
    const skip = (validatedQuery.page - 1) * validatedQuery.limit
    const take = validatedQuery.limit

    // Fetch prescriptions
    const [prescriptions, total] = await Promise.all([
      prisma.prescription.findMany({
        where,
        include: {
          medications: true,
          doctor: {
            select: {
              id: true,
              fullName: true,
              hospitalClinic: true,
              specialty: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
        skip,
        take,
      }),
      prisma.prescription.count({ where }),
    ])

    return Response.json({
      prescriptions,
      pagination: {
        page: validatedQuery.page,
        limit: validatedQuery.limit,
        total,
        totalPages: Math.ceil(total / validatedQuery.limit),
      },
    })
  } catch (error) {
    console.error('Error fetching prescriptions:', error)
    
    return Response.json(
      {
        error: {
          message: 'Failed to fetch prescriptions',
          messageEn: 'Failed to fetch prescriptions',
          messageKm: 'បរាជ័យក្នុងការទាញយកវេជ្ជបញ្ជា',
          code: 'INTERNAL_ERROR',
        },
      },
      { status: 500 }
    )
  }
})
