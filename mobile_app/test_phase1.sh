#!/bin/bash

# Phase 1 Testing Script
# Tests: Models, Providers, API Service

echo "========================================="
echo "Phase 1: Testing Models & API Service"
echo "========================================="
echo ""

BASE_URL="http://localhost:3001/api/v1"

# Test 1: Check if backend is running
echo "Test 1: Backend Health Check"
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/users/profile" 2>&1 | grep -o "[0-9]*" | head -1)
if [ "$HEALTH" = "401" ] || [ "$HEALTH" = "200" ]; then
  echo "✅ Backend is running on port 3001"
else
  echo "❌ Backend not accessible (HTTP $HEALTH)"
  echo "   Please start backend: cd backend_nestjs && npm run start:prod"
  exit 1
fi

# Test 2: Register a test user
echo ""
echo "Test 2: User Registration"
REGISTER=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+85512345678",
    "password": "test123456",
    "pin": "1234",
    "firstName": "Test",
    "lastName": "User",
    "dateOfBirth": "2000-01-01",
    "gender": "MALE",
    "role": "PATIENT"
  }' 2>&1)

if echo "$REGISTER" | grep -q "id"; then
  echo "✅ User registration successful"
else
  echo "⚠️  User may already exist (continuing...)"
fi

# Test 3: Login
echo ""
echo "Test 3: User Login"
LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+85512345678",
    "password": "test123456"
  }')

TOKEN=$(echo "$LOGIN" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
  echo "✅ Login successful"
  echo "   Token: ${TOKEN:0:30}..."
else
  echo "❌ Login failed"
  echo "   Response: $LOGIN"
  exit 1
fi

# Test 4: Get Profile
echo ""
echo "Test 4: Get User Profile"
PROFILE=$(curl -s -X GET "$BASE_URL/users/profile" \
  -H "Authorization: Bearer $TOKEN")

USER_ID=$(echo "$PROFILE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -n "$USER_ID" ]; then
  echo "✅ Profile retrieved"
  echo "   User ID: $USER_ID"
else
  echo "❌ Failed to get profile"
  exit 1
fi

# Test 5: Create Prescription
echo ""
echo "Test 5: Create Prescription"
PRESCRIPTION=$(curl -s -X POST "$BASE_URL/prescriptions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patientName": "Test User",
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

PRESC_ID=$(echo "$PRESCRIPTION" | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -n "$PRESC_ID" ]; then
  echo "✅ Prescription created"
  echo "   Prescription ID: $PRESC_ID"
  echo "   Status: $(echo "$PRESCRIPTION" | grep -o '"status":"[^"]*' | cut -d'"' -f4)"
else
  echo "❌ Failed to create prescription"
  echo "   Response: $PRESCRIPTION"
  exit 1
fi

# Test 6: Get Prescriptions
echo ""
echo "Test 6: Get Prescriptions List"
PRESCRIPTIONS=$(curl -s -X GET "$BASE_URL/prescriptions" \
  -H "Authorization: Bearer $TOKEN")

COUNT=$(echo "$PRESCRIPTIONS" | grep -o '"id"' | wc -l)

if [ "$COUNT" -gt 0 ]; then
  echo "✅ Prescriptions retrieved"
  echo "   Count: $COUNT"
else
  echo "❌ No prescriptions found"
  exit 1
fi

# Test 7: Confirm Prescription
echo ""
echo "Test 7: Confirm Prescription (Generate Doses)"
CONFIRMED=$(curl -s -X POST "$BASE_URL/prescriptions/$PRESC_ID/confirm" \
  -H "Authorization: Bearer $TOKEN")

STATUS=$(echo "$CONFIRMED" | grep -o '"status":"[^"]*' | cut -d'"' -f4)

if [ "$STATUS" = "ACTIVE" ]; then
  echo "✅ Prescription confirmed"
  echo "   Status: $STATUS"
else
  echo "❌ Failed to confirm prescription"
  echo "   Response: $CONFIRMED"
  exit 1
fi

# Test 8: Get Dose Schedule
echo ""
echo "Test 8: Get Today's Dose Schedule"
TODAY=$(date +%Y-%m-%d)
SCHEDULE=$(curl -s -X GET "$BASE_URL/doses/schedule?date=$TODAY" \
  -H "Authorization: Bearer $TOKEN")

DAYTIME_COUNT=$(echo "$SCHEDULE" | grep -o '"timePeriod":"DAYTIME"' | wc -l)
NIGHT_COUNT=$(echo "$SCHEDULE" | grep -o '"timePeriod":"NIGHT"' | wc -l)

if [ "$DAYTIME_COUNT" -gt 0 ] || [ "$NIGHT_COUNT" -gt 0 ]; then
  echo "✅ Dose schedule retrieved"
  echo "   Daytime doses: $DAYTIME_COUNT"
  echo "   Night doses: $NIGHT_COUNT"
else
  echo "❌ No doses found"
  echo "   Response: $SCHEDULE"
  exit 1
fi

# Test 9: Mark Dose Taken
echo ""
echo "Test 9: Mark Dose as Taken"
DOSE_ID=$(echo "$SCHEDULE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -n "$DOSE_ID" ]; then
  MARKED=$(curl -s -X PATCH "$BASE_URL/doses/$DOSE_ID/mark-taken" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"takenAt": "'$(date -Iseconds)'"}')
  
  DOSE_STATUS=$(echo "$MARKED" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
  
  if [ "$DOSE_STATUS" = "TAKEN_ON_TIME" ] || [ "$DOSE_STATUS" = "TAKEN_LATE" ]; then
    echo "✅ Dose marked as taken"
    echo "   Status: $DOSE_STATUS"
  else
    echo "❌ Failed to mark dose"
    echo "   Response: $MARKED"
    exit 1
  fi
else
  echo "⚠️  No dose ID found to mark"
fi

# Test 10: Get Daily Progress
echo ""
echo "Test 10: Get Daily Progress"
PROGRESS=$(curl -s -X GET "$BASE_URL/users/daily-progress" \
  -H "Authorization: Bearer $TOKEN")

PERCENTAGE=$(echo "$PROGRESS" | grep -o '"percentage":[0-9]*' | cut -d':' -f2)

if [ -n "$PERCENTAGE" ]; then
  echo "✅ Daily progress retrieved"
  echo "   Progress: $PERCENTAGE%"
else
  echo "❌ Failed to get daily progress"
  exit 1
fi

echo ""
echo "========================================="
echo "Phase 1 Testing Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "✅ Backend API accessible"
echo "✅ User registration & login working"
echo "✅ Prescription model compatible"
echo "✅ Dose event model compatible"
echo "✅ API endpoints responding correctly"
echo ""
echo "Next: Update mobile app UI to use new models"
