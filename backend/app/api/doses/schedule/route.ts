import { NextRequest } from 'next/server'
import { withAuth } from '@/lib/middleware/auth'
import { prisma } from '@/lib/prisma'
import { startOfDayInCambodia, endOfDayInCambodia, formatCambodiaTime } from '@/lib/utils/timezone'

/**
 * GET /api/doses/schedule
 * Get medication schedule (dose events) for a specific date
 * 
 * This endpoint shows the generated reminders for the patient
 * Grouped by time period (Daytime/Night) with color coding
 */
export const GET = withAuth(async (req, { user }) => {
  try {
    // Only patients can view their own schedule
    if (user.role !== 'PATIENT') {
      return Response.json(
        {
          error: {
            message: 'Only patients can view medication schedule',
            messageEn: 'Only patients can view medication schedule',
            messageKm: 'មានតែអ្នកជំងឺទេដែលអាចមើលកាលវិភាគថ្នាំ',
            code: 'FORBIDDEN',
          },
        },
        { status: 403 }
      )
    }

    // Parse query parameters
    const url = new URL(req.url)
    const dateParam = url.searchParams.get('date')
    const groupBy = url.searchParams.get('groupBy')

    // Use provided date or default to today
    const targetDate = dateParam ? new Date(dateParam) : new Date()
    const startOfDay = startOfDayInCambodia(targetDate)
    const endOfDay = endOfDayInCambodia(targetDate)

    // Fetch dose events for the day
    const doseEvents = await prisma.doseEvent.findMany({
      where: {
        patientId: user.id,
        scheduledTime: {
          gte: startOfDay,
          lte: endOfDay,
        },
      },
      include: {
        medication: {
          select: {
            medicineName: true,
            medicineNameKhmer: true,
            imageUrl: true,
            frequency: true,
            timing: true,
          },
        },
        prescription: {
          select: {
            id: true,
            status: true,
          },
        },
      },
      orderBy: {
        scheduledTime: 'asc',
      },
    })

    // Calculate daily progress
    const totalDoses = doseEvents.length
    const completedDoses = doseEvents.filter(
      (dose) => dose.status === 'TAKEN_ON_TIME' || dose.status === 'TAKEN_LATE'
    ).length
    const dailyProgress = totalDoses > 0 ? Math.round((completedDoses / totalDoses) * 100) : 0

    // Group by time period if requested
    if (groupBy === 'TIME_PERIOD') {
      const daytimeDoses = doseEvents.filter((dose) => dose.timePeriod === 'DAYTIME')
      const nightDoses = doseEvents.filter((dose) => dose.timePeriod === 'NIGHT')

      return Response.json({
        date: formatCambodiaTime(targetDate, 'yyyy-MM-dd'),
        dailyProgress,
        groups: [
          {
            period: 'DAYTIME',
            periodKhmer: 'ពេលថ្ងៃ',
            color: '#2D5BFF',
            doses: daytimeDoses.map(formatDoseEvent),
          },
          {
            period: 'NIGHT',
            periodKhmer: 'ពេលយប់',
            color: '#6B4AA3',
            doses: nightDoses.map(formatDoseEvent),
          },
        ],
      })
    }

    // Return ungrouped doses
    return Response.json({
      date: formatCambodiaTime(targetDate, 'yyyy-MM-dd'),
      dailyProgress,
      doses: doseEvents.map(formatDoseEvent),
    })
  } catch (error) {
    console.error('Error fetching dose schedule:', error)
    
    return Response.json(
      {
        error: {
          message: 'Failed to fetch dose schedule',
          messageEn: 'Failed to fetch dose schedule',
          messageKm: 'បរាជ័យក្នុងការទាញយកកាលវិភាគថ្នាំ',
          code: 'INTERNAL_ERROR',
        },
      },
      { status: 500 }
    )
  }
})

/**
 * Format dose event for response
 */
function formatDoseEvent(dose: any) {
  return {
    id: dose.id,
    medicationName: dose.medication.medicineName,
    medicationNameKhmer: dose.medication.medicineNameKhmer,
    imageUrl: dose.medication.imageUrl,
    scheduledTime: dose.scheduledTime.toISOString(),
    reminderTime: dose.reminderTime,
    status: dose.status,
    timePeriod: dose.timePeriod,
    frequency: dose.medication.frequency,
    timing: dose.medication.timing,
    takenAt: dose.takenAt?.toISOString(),
    skipReason: dose.skipReason,
  }
}
