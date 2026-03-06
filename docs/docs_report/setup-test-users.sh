#!/bin/bash

BASE_URL="http://localhost:3001/api/v1"

echo "Setting up test users..."
echo ""

# Register Patient
echo "1. Registering Patient..."
PATIENT_REG=$(curl -s -X POST "$BASE_URL/auth/register/patient" \
    -H "Content-Type: application/json" \
    -d '{
        "firstName": "Test",
        "lastName": "Patient",
        "phoneNumber": "+855999888777",
        "password": "Test123!@#",
        "pinCode": "1234",
        "gender": "FEMALE",
        "dateOfBirth": "1990-01-15",
        "idCardNumber": "PID999888777"
    }')

echo "$PATIENT_REG" | jq '.'
USER_ID=$(echo "$PATIENT_REG" | jq -r '.userId')
echo "Patient User ID: $USER_ID"
echo ""

# Send OTP for patient
echo "2. Sending OTP for patient..."
OTP_SEND=$(curl -s -X POST "$BASE_URL/auth/otp/send" \
    -H "Content-Type: application/json" \
    -d '{
        "phoneNumber": "+855999888777"
    }')
echo "$OTP_SEND" | jq '.'
echo ""

# Wait for OTP log
echo "Waiting for OTP (check backend logs)..."
sleep 2

# Register Doctor
echo "3. Registering Doctor..."
DOCTOR_REG=$(curl -s -X POST "$BASE_URL/auth/register/doctor" \
    -H "Content-Type: application/json" \
    -d '{
        "fullName": "Dr. Test Caregiver",
        "phoneNumber": "+855888777666",
        "password": "Doctor123!@#",
        "hospitalClinic": "Test Hospital",
        "specialty": "GENERAL_PRACTICE",
        "licenseNumber": "DOC888777666"
    }')

echo "$DOCTOR_REG" | jq '.'
DOCTOR_ID=$(echo "$DOCTOR_REG" | jq -r '.userId')
echo "Doctor User ID: $DOCTOR_ID"
echo ""

# Send OTP for doctor
echo "4. Sending OTP for doctor..."
OTP_SEND2=$(curl -s -X POST "$BASE_URL/auth/otp/send" \
    -H "Content-Type: application/json" \
    -d '{
        "phoneNumber": "+855888777666"
    }')
echo "$OTP_SEND2" | jq '.'
echo ""

echo "================================================"
echo "Test users created. Check backend logs for OTPs."
echo "Patient: +855999888777 / Test123!@#"
echo "Doctor: +855888777666 / Doctor123!@#"
echo "================================================"
