# Quick Start: Medicine & Reminder Generator MVP

## Prerequisites

- Docker and Docker Compose installed
- Node.js 22+ installed
- npm 10+ installed

## Setup (5 minutes)

### 1. Start Database Services
```bash
docker compose up -d postgres redis
```

### 2. Setup Backend
```bash
cd backend
npm install
npm run db:generate
npm run db:migrate
npm run db:seed
```

### 3. Start Development Server
```bash
npm run dev
```

Server will start at: http://localhost:3000

## Test the MVP (2 minutes)

### Get Test Credentials

From the seed data:
- **Doctor**: Phone: `+85512345680`, Password: `password123`
- **Patient**: Phone: `+85512345678`, Password: `password123`

### Test Flow

#### 1. Login as Doctor
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "+85512345680",
    "password": "password123"
  }'
```

Save the `accessToken` from the response.

#### 2. Create a Prescription
```bash
curl -X POST http://localhost:3000/api/prescriptions \
  -H "Authorization: Bearer YOUR_DOCTOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "PATIENT_ID_FROM_SEED",
    "patientName": "Test Patient",
    "patientGender": "MALE",
    "patientAge": 30,
    "symptoms": "ឈឺក្បាល (Headache)",
    "medications": [
      {
        "rowNumber": 1,
        "medicineName": "Paracetamol",
        "medicineNameKhmer": "ប៉ារ៉ាសេតាម៉ុល",
        "morningDosage": {
          "amount": "500mg",
          "beforeMeal": false
        },
        "nightDosage": {
          "amount": "500mg",
          "beforeMeal": false
        },
        "frequency": "2ដង/១ថ្ងៃ",
        "timing": "បន្ទាប់ពីអាហារ"
      }
    ],
    "status": "ACTIVE"
  }'
```

**Result:** System automatically generates 60 dose events (2 per day × 30 days)!

#### 3. Login as Patient
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "+85512345678",
    "password": "password123"
  }'
```

Save the `accessToken` from the response.

#### 4. View Today's Medication Schedule
```bash
curl -X GET "http://localhost:3000/api/doses/schedule?groupBy=TIME_PERIOD" \
  -H "Authorization: Bearer YOUR_PATIENT_TOKEN"
```

**Result:** You'll see today's reminders grouped by Daytime and Night!

```json
{
  "date": "2025-02-08",
  "dailyProgress": 0,
  "groups": [
    {
      "period": "DAYTIME",
      "periodKhmer": "ពេលថ្ងៃ",
      "color": "#2D5BFF",
      "doses": [
        {
          "id": "...",
          "medicationName": "Paracetamol",
          "medicationNameKhmer": "ប៉ារ៉ាសេតាម៉ុល",
          "scheduledTime": "2025-02-08T07:30:00+07:00",
          "reminderTime": "07:30",
          "status": "DUE",
          "frequency": "2ដង/១ថ្ងៃ"
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

## What Just Happened?

1. ✅ Doctor created a prescription with 2 daily doses (morning & night)
2. ✅ System automatically generated 60 reminders (30 days × 2 doses/day)
3. ✅ Patient can view today's schedule with reminder times
4. ✅ All times are in Cambodia timezone (UTC+7)
5. ✅ Everything is in Khmer and English

## Customize Reminder Times

Patients can set their meal times to get personalized reminder times:

```bash
curl -X POST http://localhost:3000/api/onboarding/meal-times \
  -H "Authorization: Bearer YOUR_PATIENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "morningMeal": "7-8AM",
    "afternoonMeal": "12-1PM",
    "nightMeal": "6-7PM"
  }'
```

Now when a new prescription is created, reminder times will be calculated based on these preferences!

## View All Prescriptions

```bash
# As doctor - see prescriptions you created
curl -X GET "http://localhost:3000/api/prescriptions?status=ACTIVE" \
  -H "Authorization: Bearer YOUR_DOCTOR_TOKEN"

# As patient - see your prescriptions
curl -X GET "http://localhost:3000/api/prescriptions" \
  -H "Authorization: Bearer YOUR_PATIENT_TOKEN"
```

## Database Inspection

View the generated data:

```bash
# Open Prisma Studio (database GUI)
cd backend
npm run db:studio
```

Navigate to:
- `prescriptions` - See created prescriptions
- `medications` - See medication details
- `dose_events` - See all generated reminders!
- `meal_time_preferences` - See meal time settings

## Troubleshooting

### Database connection error
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Restart if needed
docker compose restart postgres
```

### Redis connection error
```bash
# Check if Redis is running
docker ps | grep redis

# Restart if needed
docker compose restart redis
```

### Port already in use
```bash
# Change port in backend/.env
NEXT_PUBLIC_API_URL=http://localhost:3001

# Or stop the process using port 3000
lsof -ti:3000 | xargs kill -9
```

## Next Steps

Now that the MVP is working, you can:

1. **Integrate with mobile app** - Use these APIs in your Flutter app
2. **Add push notifications** - Send notifications at reminder times
3. **Implement dose tracking** - Let patients mark doses as taken
4. **Add more features** - See `backend/MVP_README.md` for ideas

## API Documentation

Full API documentation: `backend/MVP_README.md`

## Support

- Check logs: `docker logs dastern-postgres`
- View API errors: Check terminal where `npm run dev` is running
- Database issues: `npm run db:studio` to inspect data

## Summary

You now have a working **Medicine & Reminder Generator** that:
- ✅ Creates prescriptions
- ✅ Generates reminders automatically
- ✅ Displays medication schedules
- ✅ Supports Khmer and English
- ✅ Uses Cambodia timezone
- ✅ Calculates personalized reminder times

Ready for mobile app integration! 🎉

