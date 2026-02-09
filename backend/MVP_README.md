# Das Tern Backend API - MVP: Medicine & Reminder Generator

## Overview

This MVP implements the core functionality for **creating medicine prescriptions and automatically generating medication reminders** (dose events).

## Features Implemented

### ✅ 1. Prescription Creation
- Doctors can create prescriptions with multiple medications
- Each medication can have dosages for morning, daytime, and night
- Supports before/after meal indicators
- Khmer and English medication names
- Urgent prescription support

### ✅ 2. Automatic Reminder Generation
- Automatically generates dose events (reminders) when prescription is activated
- Generates reminders for the next 30 days
- Calculates reminder times based on meal time preferences
- Supports Cambodia timezone (Asia/Phnom_Penh)
- Groups reminders by time period (Daytime/Night)

### ✅ 3. Meal Time Preferences
- Patients can set their typical meal times
- Used to calculate optimal reminder times
- Supports before/after meal medication timing

### ✅ 4. Dose Schedule Viewing
- Patients can view their daily medication schedule
- Grouped by time period with color coding
- Shows daily progress percentage
- Displays medication details and reminder times

## API Endpoints

### 1. Create Prescription
```http
POST /api/prescriptions
Authorization: Bearer <doctor_token>
Content-Type: application/json

{
  "patientId": "uuid",
  "patientName": "Sokha Chan",
  "patientGender": "MALE",
  "patientAge": 34,
  "symptoms": "ឈឺក្បាល និង សម្ពាធឈាមខ្ពស់",
  "medications": [
    {
      "rowNumber": 1,
      "medicineName": "Amlodipine",
      "medicineNameKhmer": "អាមឡូឌីពីន",
      "morningDosage": {
        "amount": "5mg",
        "beforeMeal": false
      },
      "frequency": "1ដង/១ថ្ងៃ",
      "timing": "បន្ទាប់ពីអាហារ"
    }
  ],
  "status": "ACTIVE"
}
```

**Response:**
```json
{
  "message": "Prescription created successfully",
  "prescription": {
    "id": "uuid",
    "patientId": "uuid",
    "status": "ACTIVE",
    "medications": [...],
    "createdAt": "2025-02-08T10:00:00+07:00"
  }
}
```

### 2. Set Meal Time Preferences
```http
POST /api/onboarding/meal-times
Authorization: Bearer <patient_token>
Content-Type: application/json

{
  "morningMeal": "7-8AM",
  "afternoonMeal": "12-1PM",
  "nightMeal": "6-7PM"
}
```

### 3. View Dose Schedule (Reminders)
```http
GET /api/doses/schedule?groupBy=TIME_PERIOD
Authorization: Bearer <patient_token>
```

**Response:**
```json
{
  "date": "2025-02-08",
  "dailyProgress": 50,
  "groups": [
    {
      "period": "DAYTIME",
      "periodKhmer": "ពេលថ្ងៃ",
      "color": "#2D5BFF",
      "doses": [
        {
          "id": "uuid",
          "medicationName": "Amlodipine",
          "medicationNameKhmer": "អាមឡូឌីពីន",
          "scheduledTime": "2025-02-08T07:30:00+07:00",
          "reminderTime": "07:30",
          "status": "DUE",
          "frequency": "1ដង/១ថ្ងៃ",
          "timing": "បន្ទាប់ពីអាហារ"
        }
      ]
    },
    {
      "period": "NIGHT",
      "periodKhmer": "ពេលយប់",
      "color": "#6B4AA3",
      "doses": [...]
    }
  ]
}
```

### 4. Get Prescriptions
```http
GET /api/prescriptions?status=ACTIVE&page=1&limit=10
Authorization: Bearer <token>
```

## How It Works

### Reminder Generation Flow

1. **Doctor creates prescription** with medications and dosages
2. **Prescription is activated** (status = ACTIVE)
3. **System automatically generates dose events** for next 30 days:
   - For each medication
   - For each dosage time (morning/daytime/night)
   - Calculates reminder time based on meal preferences
   - Creates dose event in database with status "DUE"
4. **Patient views schedule** to see their reminders
5. **Mobile app can use reminders** to send push notifications

### Reminder Time Calculation

- **With meal preferences:**
  - Before meal: 30 minutes before meal time
  - After meal: 30 minutes after meal time
  
- **Without meal preferences (defaults):**
  - Morning: 7:30 AM
  - Daytime: 1:00 PM
  - Night: 7:00 PM

### Example

If patient sets:
- Morning meal: 7-8AM
- Afternoon meal: 12-1PM
- Night meal: 6-7PM

And medication is "after meals":
- Morning dose reminder: 7:30 AM
- Daytime dose reminder: 12:30 PM
- Night dose reminder: 6:30 PM

## Database Schema

### Key Tables

**prescriptions**
- id, patientId, doctorId
- patientName, patientGender, patientAge
- symptoms, status, isUrgent
- currentVersion, createdAt

**medications**
- id, prescriptionId, rowNumber
- medicineName, medicineNameKhmer
- morningDosage, daytimeDosage, nightDosage
- frequency, timing, imageUrl

**dose_events** (Generated Reminders)
- id, prescriptionId, medicationId, patientId
- scheduledTime, timePeriod, reminderTime
- status (DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED)
- takenAt, skipReason

**meal_time_preferences**
- id, userId
- morningMeal, afternoonMeal, nightMeal

## Testing

### 1. Start Services
```bash
docker compose up -d postgres redis
cd backend
npm run db:seed
```

### 2. Get Test Credentials
From seed data:
- **Doctor**: +85512345680 / password123
- **Patient**: +85512345678 / password123

### 3. Test Flow

1. **Login as doctor** to get token
2. **Create prescription** for patient
3. **Login as patient** to get token
4. **Set meal time preferences**
5. **View dose schedule** to see generated reminders

### Example cURL Commands

```bash
# 1. Login as doctor
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier": "+85512345680", "password": "password123"}'

# 2. Create prescription (use doctor token)
curl -X POST http://localhost:3000/api/prescriptions \
  -H "Authorization: Bearer <doctor_token>" \
  -H "Content-Type: application/json" \
  -d @prescription.json

# 3. Login as patient
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier": "+85512345678", "password": "password123"}'

# 4. Set meal times (use patient token)
curl -X POST http://localhost:3000/api/onboarding/meal-times \
  -H "Authorization: Bearer <patient_token>" \
  -H "Content-Type: application/json" \
  -d '{"morningMeal": "7-8AM", "afternoonMeal": "12-1PM", "nightMeal": "6-7PM"}'

# 5. View schedule (use patient token)
curl -X GET "http://localhost:3000/api/doses/schedule?groupBy=TIME_PERIOD" \
  -H "Authorization: Bearer <patient_token>"
```

## Files Created

### Core Services
- `backend/lib/services/doseGenerator.ts` - Reminder generation logic
- `backend/lib/utils/timezone.ts` - Cambodia timezone utilities

### Middleware
- `backend/lib/middleware/validation.ts` - Request validation
- `backend/lib/middleware/auth.ts` - JWT authentication (already existed)

### Schemas
- `backend/lib/schemas/prescription.ts` - Prescription validation
- `backend/lib/schemas/dose.ts` - Dose event validation
- `backend/lib/schemas/mealTime.ts` - Meal time validation

### API Endpoints
- `backend/app/api/prescriptions/route.ts` - Create/list prescriptions
- `backend/app/api/doses/schedule/route.ts` - View dose schedule
- `backend/app/api/onboarding/meal-times/route.ts` - Meal time preferences

## Next Steps

To complete the MVP, you may want to add:

1. **Mark dose as taken** - `POST /api/doses/:id/mark-taken`
2. **Skip dose** - `POST /api/doses/:id/skip`
3. **Update prescription** - `PATCH /api/prescriptions/:id`
4. **Prescription confirmation** - `POST /api/prescriptions/:id/confirm`

These endpoints are defined in the spec but not yet implemented.

## Architecture

```
Doctor creates prescription
         ↓
Prescription saved to DB
         ↓
If status = ACTIVE
         ↓
doseGenerator.generateDoseEventsFromPrescription()
         ↓
For each medication:
  For each dosage (morning/daytime/night):
    For next 30 days:
      Calculate reminder time (based on meal preferences)
      Create dose_event with status = DUE
         ↓
Patient views schedule
         ↓
Mobile app shows reminders
         ↓
Patient marks doses as taken
```

## Cambodia Timezone Support

All timestamps use Cambodia timezone (Asia/Phnom_Penh, UTC+7):
- Dose events scheduled in Cambodia time
- Reminder times calculated in Cambodia time
- API responses include timezone offset (+07:00)

## Multi-Language Support

- Error messages in Khmer and English
- Medication names in both languages
- UI text in both languages
- Language preference from user profile

## Summary

This MVP provides the essential functionality for:
✅ Creating medicine prescriptions
✅ Automatically generating medication reminders
✅ Viewing daily medication schedule
✅ Customizing reminder times via meal preferences

The system is ready for integration with a mobile app that can:
- Display the medication schedule
- Send push notifications at reminder times
- Allow patients to mark doses as taken
- Show daily progress

