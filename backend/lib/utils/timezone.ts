import { format, toZonedTime, fromZonedTime } from 'date-fns-tz'

// Cambodia timezone constant
export const CAMBODIA_TIMEZONE = 'Asia/Phnom_Penh'

/**
 * Convert a date to Cambodia timezone
 * @param date - Date to convert
 * @returns Date in Cambodia timezone
 */
export function toCambodiaTime(date: Date | string): Date {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  return toZonedTime(dateObj, CAMBODIA_TIMEZONE)
}

/**
 * Convert a date from Cambodia timezone to UTC
 * @param date - Date in Cambodia timezone
 * @returns Date in UTC
 */
export function fromCambodiaTime(date: Date | string): Date {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  return fromZonedTime(dateObj, CAMBODIA_TIMEZONE)
}

/**
 * Format a date in Cambodia timezone
 * @param date - Date to format
 * @param formatStr - Format string (default: 'yyyy-MM-dd HH:mm:ss')
 * @returns Formatted date string
 */
export function formatCambodiaTime(
  date: Date | string,
  formatStr: string = 'yyyy-MM-dd HH:mm:ss'
): string {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  return format(toZonedTime(dateObj, CAMBODIA_TIMEZONE), formatStr, {
    timeZone: CAMBODIA_TIMEZONE,
  })
}

/**
 * Get current time in Cambodia timezone
 * @returns Current date in Cambodia timezone
 */
export function nowInCambodia(): Date {
  return toCambodiaTime(new Date())
}

/**
 * Create a date in Cambodia timezone from components
 * @param year - Year
 * @param month - Month (1-12)
 * @param day - Day
 * @param hour - Hour (0-23)
 * @param minute - Minute (0-59)
 * @param second - Second (0-59)
 * @returns Date in Cambodia timezone
 */
export function createCambodiaDate(
  year: number,
  month: number,
  day: number,
  hour: number = 0,
  minute: number = 0,
  second: number = 0
): Date {
  const date = new Date(year, month - 1, day, hour, minute, second)
  return fromCambodiaTime(date)
}

/**
 * Parse time string (HH:mm) and create a date for today in Cambodia timezone
 * @param timeStr - Time string in HH:mm format
 * @param baseDate - Base date (default: today)
 * @returns Date with the specified time in Cambodia timezone
 */
export function parseTimeInCambodia(timeStr: string, baseDate?: Date): Date {
  const [hours, minutes] = timeStr.split(':').map(Number)
  const base = baseDate || new Date()
  const cambodiaDate = toCambodiaTime(base)
  
  cambodiaDate.setHours(hours, minutes, 0, 0)
  return fromCambodiaTime(cambodiaDate)
}

/**
 * Get start of day in Cambodia timezone
 * @param date - Date (default: today)
 * @returns Start of day in Cambodia timezone
 */
export function startOfDayInCambodia(date?: Date): Date {
  const d = date || new Date()
  const cambodiaDate = toCambodiaTime(d)
  cambodiaDate.setHours(0, 0, 0, 0)
  return fromCambodiaTime(cambodiaDate)
}

/**
 * Get end of day in Cambodia timezone
 * @param date - Date (default: today)
 * @returns End of day in Cambodia timezone
 */
export function endOfDayInCambodia(date?: Date): Date {
  const d = date || new Date()
  const cambodiaDate = toCambodiaTime(d)
  cambodiaDate.setHours(23, 59, 59, 999)
  return fromCambodiaTime(cambodiaDate)
}

/**
 * Check if a date is today in Cambodia timezone
 * @param date - Date to check
 * @returns True if date is today in Cambodia timezone
 */
export function isTodayInCambodia(date: Date | string): boolean {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  const cambodiaDate = toCambodiaTime(dateObj)
  const today = toCambodiaTime(new Date())
  
  return (
    cambodiaDate.getFullYear() === today.getFullYear() &&
    cambodiaDate.getMonth() === today.getMonth() &&
    cambodiaDate.getDate() === today.getDate()
  )
}

/**
 * Add hours to a date in Cambodia timezone
 * @param date - Base date
 * @param hours - Hours to add
 * @returns New date with hours added
 */
export function addHoursInCambodia(date: Date | string, hours: number): Date {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  const cambodiaDate = toCambodiaTime(dateObj)
  cambodiaDate.setHours(cambodiaDate.getHours() + hours)
  return fromCambodiaTime(cambodiaDate)
}

/**
 * Calculate time difference in minutes between two dates
 * @param date1 - First date
 * @param date2 - Second date
 * @returns Difference in minutes
 */
export function diffInMinutes(date1: Date | string, date2: Date | string): number {
  const d1 = typeof date1 === 'string' ? new Date(date1) : date1
  const d2 = typeof date2 === 'string' ? new Date(date2) : date2
  return Math.floor((d1.getTime() - d2.getTime()) / (1000 * 60))
}

/**
 * Format date to ISO 8601 with Cambodia timezone offset
 * @param date - Date to format
 * @returns ISO 8601 string with +07:00 offset
 */
export function toISO8601Cambodia(date: Date | string): string {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  return formatCambodiaTime(dateObj, "yyyy-MM-dd'T'HH:mm:ssXXX")
}
