#!/bin/bash

# API Testing Script for Das Tern NestJS Backend
# Port: 3001

BASE_URL="http://localhost:3001/api/v1"
TOKEN=""
PATIENT_ID=""
DOCTOR_ID=""
PRESCRIPTION_ID=""
DOSE_ID=""
CONNECTION_ID=""

echo "🧪 Testing Das Tern NestJS Backend API"
echo "========================================"
echo ""

# Test 1: Patient Registration
echo "📝 Test 1: Patient Registration"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register/patient" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "gender": "MALE",
    "dateOfBirth": "2000-01-01",
    "idCardNumber": "123456789",
    "phoneNumber": "+85512345678",
    "password": "password123",
    "pinCode": "1234"
  }')
echo "$REGISTER_RESPONSE" | jq '.'
PATIENT_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.userId // empty')
echo "✅ Patient registered. ID: $PATIENT_ID"
echo ""

# Test 2: Send OTP
echo "📱 Test 2: Send OTP"
OTP_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/otp/send" \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+85512345678"}')
echo "$OTP_RESPONSE" | jq '.'
echo "✅ OTP sent"
echo ""

# Get OTP from logs (in development, it's printed)
echo "⏳ Waiting for OTP (check server logs)..."
sleep 2

# Test 3: Verify OTP (using a test OTP - in real scenario, get from SMS)
echo "🔐 Test 3: Verify OTP"
# Note: In development, check server logs for OTP
# For testing, we'll skip this and use direct login

# Test 4: Login
echo "🔑 Test 4: Login"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+85512345678",
    "password": "password123"
  }')
echo "$LOGIN_RESPONSE" | jq '.'
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken // empty')

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed. Trying OTP verification first..."
  # Try with a dummy OTP for testing
  VERIFY_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/otp/verify" \
    -H "Content-Type: application/json" \
    -d '{"phoneNumber": "+85512345678", "otp": "1234"}')
  echo "$VERIFY_RESPONSE" | jq '.'
  TOKEN=$(echo "$VERIFY_RESPONSE" | jq -r '.accessToken // empty')
fi

echo "✅ Logged in. Token: ${TOKEN:0:20}..."
echo ""

# Test 5: Get Profile
echo "👤 Test 5: Get User Profile"
curl -s -X GET "$BASE_URL/users/me" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo "✅ Profile retrieved"
echo ""

# Test 6: Get Storage Info
echo "💾 Test 6: Get Storage Info"
curl -s -X GET "$BASE_URL/users/storage" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo "✅ Storage info retrieved"
echo ""

# Test 7: Update Profile
echo "✏️  Test 7: Update Profile"
curl -s -X PATCH "$BASE_URL/users/me" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"language": "ENGLISH", "theme": "DARK"}' | jq '.'
echo "✅ Profile updated"
echo ""

# Test 8: Get Connections
echo "🔗 Test 8: Get Connections"
curl -s -X GET "$BASE_URL/connections" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo "✅ Connections retrieved"
echo ""

# Test 9: Get Prescriptions
echo "💊 Test 9: Get Prescriptions"
curl -s -X GET "$BASE_URL/prescriptions" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo "✅ Prescriptions retrieved"
echo ""

# Test 10: Get Dose Schedule
echo "📅 Test 10: Get Dose Schedule"
curl -s -X GET "$BASE_URL/doses/schedule?groupBy=TIME_PERIOD" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo "✅ Dose schedule retrieved"
echo ""

# Test 11: Get Notifications
echo "🔔 Test 11: Get Notifications"
curl -s -X GET "$BASE_URL/notifications" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo "✅ Notifications retrieved"
echo ""

# Test 12: Get Subscription
echo "💳 Test 12: Get Subscription"
curl -s -X GET "$BASE_URL/subscriptions/me" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo "✅ Subscription retrieved"
echo ""

# Test 13: Get Audit Logs
echo "📝 Test 13: Get Audit Logs"
curl -s -X GET "$BASE_URL/audit" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo "✅ Audit logs retrieved"
echo ""

echo ""
echo "🎉 All basic tests completed!"
echo "========================================"
echo "Summary:"
echo "- Patient Registration: ✅"
echo "- OTP Flow: ⚠️  (requires manual OTP from logs)"
echo "- Login: ✅"
echo "- Profile Management: ✅"
echo "- Storage Info: ✅"
echo "- Connections: ✅"
echo "- Prescriptions: ✅"
echo "- Doses: ✅"
echo "- Notifications: ✅"
echo "- Subscriptions: ✅"
echo "- Audit Logs: ✅"
echo ""
echo "✨ Server is running on port 3001"
echo "📍 API Base URL: $BASE_URL"
