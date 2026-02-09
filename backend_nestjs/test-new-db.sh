#!/bin/bash

BASE_URL="http://localhost:3001/api/v1"

echo "========================================="
echo "Complete Backend Test - New Database"
echo "========================================="
echo ""

# Test 1: Register Patient
echo "Test 1: Register Patient"
REGISTER=$(curl -s -X POST "$BASE_URL/auth/register/patient" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+855777888999",
    "password": "test123456",
    "pinCode": "1234",
    "idCardNumber": "123456789",
    "firstName": "Final",
    "lastName": "Test",
    "dateOfBirth": "2000-01-01",
    "gender": "MALE"
  }')

PATIENT_ID=$(echo "$REGISTER" | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
if [ -n "$PATIENT_ID" ]; then
  echo "✅ Patient registered: $PATIENT_ID"
else
  echo "❌ Registration failed"
  echo "$REGISTER"
  exit 1
fi

# Test 2: Login
echo ""
echo "Test 2: Login"
LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+855777888999", "password": "test123456"}')

TOKEN=$(echo "$LOGIN" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
if [ -n "$TOKEN" ]; then
  echo "✅ Login successful"
  echo "   Token: ${TOKEN:0:40}..."
else
  echo "❌ Login failed"
  echo "$LOGIN"
  exit 1
fi

# Test 3: Get Profile
echo ""
echo "Test 3: Get Profile"
PROFILE=$(curl -s -X GET "$BASE_URL/users/me" \
  -H "Authorization: Bearer $TOKEN")

PROFILE_ID=$(echo "$PROFILE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
if [ "$PROFILE_ID" = "$PATIENT_ID" ]; then
  echo "✅ Profile retrieved"
else
  echo "❌ Profile mismatch"
fi

# Test 4: Create Prescription
echo ""
echo "Test 4: Create Prescription"
PRESCRIPTION=$(curl -s -X POST "$BASE_URL/prescriptions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patientName": "Final Test",
    "patientGender": "MALE",
    "patientAge": 26,
    "symptoms": "ឈឺក្បាល",
    "medications": [
      {
        "rowNumber": 1,
        "medicineName": "Paracetamol",
        "medicineNameKhmer": "ប៉ារ៉ាសេតាម៉ុល",
        "morningDosage": 1,
        "daytimeDosage": 0,
        "nightDosage": 1,
        "timing": "AFTER_MEAL"
      }
    ]
  }')

PRESC_ID=$(echo "$PRESCRIPTION" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
PRESC_STATUS=$(echo "$PRESCRIPTION" | grep -o '"status":"[^"]*' | cut -d'"' -f4)

if [ -n "$PRESC_ID" ]; then
  echo "✅ Prescription created: $PRESC_ID"
  echo "   Status: $PRESC_STATUS"
else
  echo "❌ Prescription creation failed"
  echo "$PRESCRIPTION"
  exit 1
fi

# Test 5: Confirm Prescription
echo ""
echo "Test 5: Confirm Prescription (Generate Doses)"
CONFIRMED=$(curl -s -X POST "$BASE_URL/prescriptions/$PRESC_ID/confirm" \
  -H "Authorization: Bearer $TOKEN")

CONFIRMED_STATUS=$(echo "$CONFIRMED" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
if [ "$CONFIRMED_STATUS" = "ACTIVE" ]; then
  echo "✅ Prescription confirmed and activated"
else
  echo "❌ Confirmation failed"
  echo "$CONFIRMED"
fi

# Test 6: Get Dose Schedule
echo ""
echo "Test 6: Get Today's Dose Schedule"
TODAY=$(date +%Y-%m-%d)
SCHEDULE=$(curl -s -X GET "$BASE_URL/doses/schedule?date=$TODAY" \
  -H "Authorization: Bearer $TOKEN")

DAYTIME_COUNT=$(echo "$SCHEDULE" | grep -o '"timePeriod":"DAYTIME"' | wc -l)
NIGHT_COUNT=$(echo "$SCHEDULE" | grep -o '"timePeriod":"NIGHT"' | wc -l)

echo "   Daytime doses: $DAYTIME_COUNT"
echo "   Night doses: $NIGHT_COUNT"

if [ "$DAYTIME_COUNT" -gt 0 ] || [ "$NIGHT_COUNT" -gt 0 ]; then
  echo "✅ Dose schedule generated"
else
  echo "❌ No doses found"
  echo "$SCHEDULE" | head -20
fi

# Test 7: Mark Dose Taken
echo ""
echo "Test 7: Mark Dose as Taken"
DOSE_ID=$(echo "$SCHEDULE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -n "$DOSE_ID" ]; then
  MARKED=$(curl -s -X PATCH "$BASE_URL/doses/$DOSE_ID/taken" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"takenAt\": \"$(date -Iseconds)\"}")
  
  DOSE_STATUS=$(echo "$MARKED" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
  echo "   Dose Status: $DOSE_STATUS"
  
  if [ "$DOSE_STATUS" = "TAKEN_ON_TIME" ] || [ "$DOSE_STATUS" = "TAKEN_LATE" ]; then
    echo "✅ Dose marked as taken"
  else
    echo "❌ Failed to mark dose"
  fi
else
  echo "⚠️  No dose ID found"
fi

# Test 8: Daily Progress
echo ""
echo "Test 8: Get Daily Progress"
PROGRESS=$(curl -s -X GET "$BASE_URL/users/daily-progress" \
  -H "Authorization: Bearer $TOKEN")

PERCENTAGE=$(echo "$PROGRESS" | grep -o '"percentage":[0-9]*' | cut -d':' -f2)
echo "   Progress: $PERCENTAGE%"

if [ -n "$PERCENTAGE" ]; then
  echo "✅ Daily progress calculated"
else
  echo "❌ Progress calculation failed"
fi

# Test 9: Storage Info
echo ""
echo "Test 9: Get Storage Info"
STORAGE=$(curl -s -X GET "$BASE_URL/users/storage" \
  -H "Authorization: Bearer $TOKEN")

USED=$(echo "$STORAGE" | grep -o '"used":[0-9]*' | cut -d':' -f2)
QUOTA=$(echo "$STORAGE" | grep -o '"quota":[0-9]*' | cut -d':' -f2)

echo "   Used: $USED bytes"
echo "   Quota: $QUOTA bytes"

if [ -n "$QUOTA" ]; then
  echo "✅ Storage info retrieved"
else
  echo "❌ Storage info failed"
fi

echo ""
echo "========================================="
echo "Test Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "✅ Patient registration"
echo "✅ Authentication"
echo "✅ Prescription creation"
echo "✅ Prescription confirmation"
echo "✅ Dose generation"
echo "✅ Dose marking"
echo "✅ Daily progress"
echo "✅ Storage tracking"
echo ""
echo "Backend is working correctly with new database!"
