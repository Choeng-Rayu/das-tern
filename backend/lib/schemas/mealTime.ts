import { z } from 'zod'

// Meal time range options
const mealTimeRanges = [
  '6-7AM', '7-8AM', '8-9AM', '9-10AM',
  '12-1PM', '1-2PM', '2-3PM', '4-5PM',
  '6-7PM', '7-8PM', '8-9PM', '9-10PM',
] as const

// Meal time preference schema
export const mealTimePreferenceSchema = z.object({
  morningMeal: z.enum(mealTimeRanges),
  afternoonMeal: z.enum(mealTimeRanges),
  nightMeal: z.enum(mealTimeRanges),
})

// Export types
export type MealTimePreference = z.infer<typeof mealTimePreferenceSchema>
export type MealTimeRange = typeof mealTimeRanges[number]
