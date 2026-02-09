import { prisma } from '../prisma'
import {
  toCambodiaTime,
  parseTimeInCambodia,
  startOfDayInCambodia,
  addHoursInCambodia,
} from '../utils/timezone'
import type { Prescription, Medication, MealTimePreference } from '@prisma/client'

// Time period mapping
type TimePeriod = 'DAYTIME' | 'NIGHT'

/**
 * Generate dose events (reminders) from a prescription
 * This is the core reminder generator for the MVP
 * 
 * @param prescriptionId - ID of the prescription to generate doses for
 * @returns Array of created dose events
 */
export async function generateDoseEventsFromPrescription(
  prescriptionId: string
): Promise<any[]> {
  // Fetch prescription with medications
  const prescription = await prisma.prescription.findUnique({
    where: { id: prescriptionId },
    include: {
      medications: true,
      patient: {
        include: {
          mealTimePreference: true,
        },
      },
    },
  })

  if (!prescription) {
    throw new Error('Prescription not found')
  }

  if (prescription.status !== 'ACTIVE') {
    throw new Error('Can only generate doses for active prescriptions')
  }

  // Get meal time preferences for reminder time calculation
  const mealPreferences = prescription.patient.mealTimePreference

  // Generate dose events for each medication
  const doseEvents: any[] = []

  for (const medication of prescription.medications) {
    const medicationDoses = await generateDosesForMedication(
      prescription,
      medication,
      mealPreferences
    )
    doseEvents.push(...medicationDoses)
  }

  return doseEvents
}

/**
 * Generate dose events for a single medication
 */
async function generateDosesForMedication(
  prescription: Prescription & { patient: any },
  medication: Medication,
  mealPreferences: MealTimePreference | null
): Promise<any[]> {
  const doses: any[] = []
  const today = startOfDayInCambodia()

  // Generate doses for the next 30 days (or until prescription ends)
  const daysToGenerate = 30

  for (let day = 0; day < daysToGenerate; day++) {
    const scheduleDate = new Date(today)
    scheduleDate.setDate(scheduleDate.getDate() + day)

    // Morning dose
    if (medication.morningDosage) {
      const morningDose = await createDoseEvent(
        prescription,
        medication,
        scheduleDate,
        'DAYTIME',
        'morning',
        medication.morningDosage as any,
        mealPreferences
      )
      doses.push(morningDose)
    }

    // Daytime dose
    if (medication.daytimeDosage) {
      const daytimeDose = await createDoseEvent(
        prescription,
        medication,
        scheduleDate,
        'DAYTIME',
        'daytime',
        medication.daytimeDosage as any,
        mealPreferences
      )
      doses.push(daytimeDose)
    }

    // Night dose
    if (medication.nightDosage) {
      const nightDose = await createDoseEvent(
        prescription,
        medication,
        scheduleDate,
        'NIGHT',
        'night',
        medication.nightDosage as any,
        mealPreferences
      )
      doses.push(nightDose)
    }
  }

  return doses
}

/**
 * Create a single dose event
 */
async function createDoseEvent(
  prescription: Prescription & { patient: any },
  medication: Medication,
  scheduleDate: Date,
  timePeriod: TimePeriod,
  timeOfDay: 'morning' | 'daytime' | 'night',
  dosage: { amount: string; beforeMeal: boolean },
  mealPreferences: MealTimePreference | null
): Promise<any> {
  // Calculate scheduled time and reminder time
  const { scheduledTime, reminderTime } = calculateScheduledTime(
    scheduleDate,
    timeOfDay,
    dosage.beforeMeal,
    mealPreferences
  )

  // Create dose event in database
  const doseEvent = await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription.id,
      medicationId: medication.id,
      patientId: prescription.patientId,
      scheduledTime,
      timePeriod,
      reminderTime,
      status: 'DUE',
    },
  })

  return doseEvent
}

/**
 * Calculate scheduled time and reminder time based on meal preferences
 */
function calculateScheduledTime(
  baseDate: Date,
  timeOfDay: 'morning' | 'daytime' | 'night',
  beforeMeal: boolean,
  mealPreferences: MealTimePreference | null
): { scheduledTime: Date; reminderTime: string } {
  let hour: number
  let minute: number = 0

  // Default times if no meal preferences
  const defaultTimes = {
    morning: { hour: 7, minute: 30 },
    daytime: { hour: 13, minute: 0 },
    night: { hour: 19, minute: 0 },
  }

  if (mealPreferences) {
    // Use meal preferences to calculate time
    const mealTime = getMealTimeFromPreference(timeOfDay, mealPreferences)
    const parsedTime = parseMealTimeRange(mealTime)
    
    if (beforeMeal) {
      // 30 minutes before meal
      hour = parsedTime.hour
      minute = parsedTime.minute - 30
      if (minute < 0) {
        hour -= 1
        minute += 60
      }
    } else {
      // 30 minutes after meal
      hour = parsedTime.hour
      minute = parsedTime.minute + 30
      if (minute >= 60) {
        hour += 1
        minute -= 60
      }
    }
  } else {
    // Use default times
    const defaultTime = defaultTimes[timeOfDay]
    hour = defaultTime.hour
    minute = defaultTime.minute
  }

  // Create scheduled time in Cambodia timezone
  const scheduledTime = new Date(baseDate)
  scheduledTime.setHours(hour, minute, 0, 0)

  // Format reminder time as HH:mm
  const reminderTime = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`

  return { scheduledTime, reminderTime }
}

/**
 * Get meal time from preferences based on time of day
 */
function getMealTimeFromPreference(
  timeOfDay: 'morning' | 'daytime' | 'night',
  preferences: MealTimePreference
): string {
  switch (timeOfDay) {
    case 'morning':
      return preferences.morningMeal || '7-8AM'
    case 'daytime':
      return preferences.afternoonMeal || '12-1PM'
    case 'night':
      return preferences.nightMeal || '6-7PM'
  }
}

/**
 * Parse meal time range (e.g., "7-8AM") to hour and minute
 */
function parseMealTimeRange(timeRange: string): { hour: number; minute: number } {
  // Extract start time from range (e.g., "7-8AM" -> "7AM")
  const startTime = timeRange.split('-')[0]
  
  // Parse hour
  let hour = parseInt(startTime)
  const isPM = timeRange.includes('PM')
  
  if (isPM && hour !== 12) {
    hour += 12
  } else if (!isPM && hour === 12) {
    hour = 0
  }

  return { hour, minute: 0 }
}

/**
 * Regenerate dose events when prescription is updated
 * Deletes existing future doses and creates new ones
 */
export async function regenerateDoseEvents(prescriptionId: string): Promise<void> {
  // Delete future dose events (status = DUE)
  await prisma.doseEvent.deleteMany({
    where: {
      prescriptionId,
      status: 'DUE',
      scheduledTime: {
        gte: new Date(),
      },
    },
  })

  // Generate new dose events
  await generateDoseEventsFromPrescription(prescriptionId)
}

/**
 * Calculate default reminder times for PRN (as needed) medications
 * Returns 4 reminder times per day: morning, noon, evening, night
 */
export function calculatePRNReminderTimes(): string[] {
  return ['07:00', '12:00', '17:00', '21:00']
}
