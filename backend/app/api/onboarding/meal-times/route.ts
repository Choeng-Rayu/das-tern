import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'
import { withValidation } from '@/lib/middleware/validation'
import { mealTimePreferenceSchema } from '@/lib/schemas/mealTime'
import { prisma } from '@/lib/prisma'

/**
 * POST /api/onboarding/meal-times
 * Save meal time preferences for reminder calculation
 */
export const POST = withAuth(
  withValidation(mealTimePreferenceSchema)(async (req, { user, body }) => {
    try {
      // Only patients can set meal time preferences
      if (user.role !== 'PATIENT') {
        return Response.json(
          {
            error: {
              message: 'Only patients can set meal time preferences',
              messageEn: 'Only patients can set meal time preferences',
              messageKm: 'មានតែអ្នកជំងឺទេដែលអាចកំណត់ពេលវេលាអាហារ',
              code: 'FORBIDDEN',
            },
          },
          { status: 403 }
        )
      }

      // Upsert meal time preference
      const mealTimePreference = await prisma.mealTimePreference.upsert({
        where: { userId: user.id },
        update: {
          morningMeal: body.morningMeal,
          afternoonMeal: body.afternoonMeal,
          nightMeal: body.nightMeal,
        },
        create: {
          userId: user.id,
          morningMeal: body.morningMeal,
          afternoonMeal: body.afternoonMeal,
          nightMeal: body.nightMeal,
        },
      })

      return Response.json({
        message: 'Meal time preferences saved successfully',
        messageEn: 'Meal time preferences saved successfully',
        messageKm: 'រក្សាទុកការកំណត់ពេលវេលាអាហារបានជោគជ័យ',
        mealTimePreference,
      })
    } catch (error) {
      console.error('Error saving meal time preferences:', error)
      
      return Response.json(
        {
          error: {
            message: 'Failed to save meal time preferences',
            messageEn: 'Failed to save meal time preferences',
            messageKm: 'បរាជ័យក្នុងការរក្សាទុកការកំណត់ពេលវេលាអាហារ',
            code: 'INTERNAL_ERROR',
          },
        },
        { status: 500 }
      )
    }
  })
)

/**
 * GET /api/onboarding/meal-times
 * Get current meal time preferences
 */
export const GET = withAuth(async (req, { user }) => {
  try {
    // Only patients can view their meal time preferences
    if (user.role !== 'PATIENT') {
      return Response.json(
        {
          error: {
            message: 'Only patients can view meal time preferences',
            messageEn: 'Only patients can view meal time preferences',
            messageKm: 'មានតែអ្នកជំងឺទេដែលអាចមើលការកំណត់ពេលវេលាអាហារ',
            code: 'FORBIDDEN',
          },
        },
        { status: 403 }
      )
    }

    const mealTimePreference = await prisma.mealTimePreference.findUnique({
      where: { userId: user.id },
    })

    if (!mealTimePreference) {
      return Response.json({
        message: 'No meal time preferences found',
        messageEn: 'No meal time preferences found. Using default times.',
        messageKm: 'រកមិនឃើញការកំណត់ពេលវេលាអាហារ។ ប្រើពេលវេលាលំនាំដើម។',
        mealTimePreference: null,
        defaults: {
          morningMeal: '7-8AM',
          afternoonMeal: '12-1PM',
          nightMeal: '6-7PM',
        },
      })
    }

    return Response.json({
      mealTimePreference,
    })
  } catch (error) {
    console.error('Error fetching meal time preferences:', error)
    
    return Response.json(
      {
        error: {
          message: 'Failed to fetch meal time preferences',
          messageEn: 'Failed to fetch meal time preferences',
          messageKm: 'បរាជ័យក្នុងការទាញយកការកំណត់ពេលវេលាអាហារ',
          code: 'INTERNAL_ERROR',
        },
      },
      { status: 500 }
    )
  }
})
