#!/bin/bash

# Comprehensive Family Connection + Missed Dose Alert API Testing Script
# Tests all new endpoints added for the family connection feature

BASE_URL="http://localhost:3001/api/v1"
PATIENT_TOKEN=""
DOCTOR_TOKEN=""
CONNECTION_TOKEN=""
CONNECTION_ID=""

echo "================================================"
echo "Family Connection API Testing - Full Coverage"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

test_result() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $2"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAILED${NC}: $2"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# Step 1: Login as Patient
echo -e "${YELLOW}=== Step 1: Patient Login ===${NC}"
PATIENT_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
        "phoneNumber": "+855123456788",
        "password": "Patient123!"
    }')

PATIENT_TOKEN=$(echo $PATIENT_RESPONSE | jq -r '.accessToken')
if [ "$PATIENT_TOKEN" != "null" ] && [ -n "$PATIENT_TOKEN" ]; then
    test_result 0 "Patient login successful"
    echo "Patient Token: ${PATIENT_TOKEN:0:50}..."
else
    test_result 1 "Patient login failed"
    echo "Response: $PATIENT_RESPONSE"
    exit 1
fi

# Step 2: Login as Doctor (Caregiver)
echo -e "${YELLOW}=== Step 2: Doctor Login ===${NC}"
DOCTOR_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
        "phoneNumber": "+855012345678",
        "password": "Doctor123!"
    }')

DOCTOR_TOKEN=$(echo $DOCTOR_RESPONSE | jq -r '.accessToken')
if [ "$DOCTOR_TOKEN" != "null" ] && [ -n "$DOCTOR_TOKEN" ]; then
    test_result 0 "Doctor login successful"
    echo "Doctor Token: ${DOCTOR_TOKEN:0:50}..."
else
    test_result 1 "Doctor login failed"
    echo "Response: $DOCTOR_RESPONSE"
    exit 1
fi

# Step 3: Generate Connection Token (Patient)
echo -e "${YELLOW}=== Step 3: Generate Connection Token ===${NC}"
TOKEN_GEN_RESPONSE=$(curl -s -X POST "$BASE_URL/connections/tokens/generate" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $PATIENT_TOKEN" \
    -d '{
        "permissionLevel": "ALLOWED"
    }')

CONNECTION_TOKEN=$(echo $TOKEN_GEN_RESPONSE | jq -r '.token')
if [ "$CONNECTION_TOKEN" != "null" ] && [ -n "$CONNECTION_TOKEN" ]; then
    test_result 0 "Connection token generated successfully"
    echo "Token: $CONNECTION_TOKEN"
    echo "Permission Level: $(echo $TOKEN_GEN_RESPONSE | jq -r '.permissionLevel')"
    echo "Expires At: $(echo $TOKEN_GEN_RESPONSE | jq -r '.expiresAt')"
else
    test_result 1 "Failed to generate connection token"
    echo "Response: $TOKEN_GEN_RESPONSE"
fi

# Step 4: Validate Token (Doctor)
echo -e "${YELLOW}=== Step 4: Validate Connection Token ===${NC}"
TOKEN_VAL_RESPONSE=$(curl -s -X POST "$BASE_URL/connections/tokens/validate" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DOCTOR_TOKEN" \
    -d "{
        \"token\": \"$CONNECTION_TOKEN\"
    }")

PATIENT_NAME=$(echo $TOKEN_VAL_RESPONSE | jq -r '.patient.fullName')
if [ "$PATIENT_NAME" != "null" ] && [ -n "$PATIENT_NAME" ]; then
    test_result 0 "Token validation successful"
    echo "Patient Name: $PATIENT_NAME"
    echo "Permission Level: $(echo $TOKEN_VAL_RESPONSE | jq -r '.permissionLevel')"
else
    test_result 1 "Token validation failed"
    echo "Response: $TOKEN_VAL_RESPONSE"
fi

# Step 5: Consume Token to Create Connection (Doctor)
echo -e "${YELLOW}=== Step 5: Consume Token (Create Connection) ===${NC}"
CONSUME_RESPONSE=$(curl -s -X POST "$BASE_URL/connections/tokens/consume" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DOCTOR_TOKEN" \
    -d "{
        \"token\": \"$CONNECTION_TOKEN\"
    }")

CONNECTION_ID=$(echo $CONSUME_RESPONSE | jq -r '.id')
if [ "$CONNECTION_ID" != "null" ] && [ -n "$CONNECTION_ID" ]; then
    test_result 0 "Connection created successfully"
    echo "Connection ID: $CONNECTION_ID"
    echo "Status: $(echo $CONSUME_RESPONSE | jq -r '.status')"
else
    test_result 1 "Failed to consume token"
    echo "Response: $CONSUME_RESPONSE"
fi

# Step 6: Get Caregivers List (Patient)
echo -e "${YELLOW}=== Step 6: Get Patient's Caregivers ===${NC}"
CAREGIVERS_RESPONSE=$(curl -s -X GET "$BASE_URL/connections/caregivers" \
    -H "Authorization: Bearer $PATIENT_TOKEN")

CAREGIVER_COUNT=$(echo $CAREGIVERS_RESPONSE | jq '. | length')
if [ "$CAREGIVER_COUNT" -ge 1 ]; then
    test_result 0 "Retrieved caregivers list (count: $CAREGIVER_COUNT)"
    echo "Caregivers:"
    echo "$CAREGIVERS_RESPONSE" | jq -r '.[] | "  - \(.initiator.fullName // .recipient.fullName) (\(.status))"'
else
    test_result 1 "Failed to retrieve caregivers or list is empty"
    echo "Response: $CAREGIVERS_RESPONSE"
fi

# Step 7: Get Connected Patients (Doctor)
echo -e "${YELLOW}=== Step 7: Get Doctor's Patients ===${NC}"
PATIENTS_RESPONSE=$(curl -s -X GET "$BASE_URL/connections/patients" \
    -H "Authorization: Bearer $DOCTOR_TOKEN")

PATIENT_COUNT=$(echo $PATIENTS_RESPONSE | jq '. | length')
if [ "$PATIENT_COUNT" -ge 1 ]; then
    test_result 0 "Retrieved connected patients (count: $PATIENT_COUNT)"
    echo "Patients:"
    echo "$PATIENTS_RESPONSE" | jq -r '.[] | "  - \(.initiator.fullName // .recipient.fullName) (\(.status))"'
else
    test_result 1 "Failed to retrieve patients or list is empty"
    echo "Response: $PATIENTS_RESPONSE"
fi

# Step 8: Get Caregiver Limit (Patient)
echo -e "${YELLOW}=== Step 8: Check Caregiver Limit ===${NC}"
LIMIT_RESPONSE=$(curl -s -X GET "$BASE_URL/connections/caregiver-limit" \
    -H "Authorization: Bearer $PATIENT_TOKEN")

CURRENT_COUNT=$(echo $LIMIT_RESPONSE | jq -r '.current')
MAX_ALLOWED=$(echo $LIMIT_RESPONSE | jq -r '.limit')
if [ "$CURRENT_COUNT" != "null" ] && [ "$MAX_ALLOWED" != "null" ]; then
    test_result 0 "Retrieved caregiver limit"
    echo "Current: $CURRENT_COUNT / Max: $MAX_ALLOWED"
    echo "Can Add More: $(echo $LIMIT_RESPONSE | jq -r '.canAddMore')"
else
    test_result 1 "Failed to get caregiver limit"
    echo "Response: $LIMIT_RESPONSE"
fi

# Step 9: Toggle Alerts (Patient)
echo -e "${YELLOW}=== Step 9: Toggle Alerts (Disable) ===${NC}"
ALERT_OFF_RESPONSE=$(curl -s -X PATCH "$BASE_URL/connections/$CONNECTION_ID/alerts" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $PATIENT_TOKEN" \
    -d '{
        "enabled": false
    }')

ALERTS_ENABLED=$(echo $ALERT_OFF_RESPONSE | jq -r '.metadata.alertsEnabled')
if [ "$ALERTS_ENABLED" == "false" ]; then
    test_result 0 "Alerts disabled successfully"
else
    test_result 1 "Failed to disable alerts"
    echo "Response: $ALERT_OFF_RESPONSE"
fi

echo -e "${YELLOW}=== Step 10: Toggle Alerts (Enable) ===${NC}"
ALERT_ON_RESPONSE=$(curl -s -X PATCH "$BASE_URL/connections/$CONNECTION_ID/alerts" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $PATIENT_TOKEN" \
    -d '{
        "enabled": true
    }')

ALERTS_ENABLED=$(echo $ALERT_ON_RESPONSE | jq -r '.metadata.alertsEnabled')
if [ "$ALERTS_ENABLED" == "true" ]; then
    test_result 0 "Alerts enabled successfully"
else
    test_result 1 "Failed to enable alerts"
    echo "Response: $ALERT_ON_RESPONSE"
fi

# Step 11: Update Grace Period (Patient)
echo -e "${YELLOW}=== Step 11: Update Grace Period ===${NC}"
GRACE_RESPONSE=$(curl -s -X PATCH "$BASE_URL/users/me/grace-period" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $PATIENT_TOKEN" \
    -d '{
        "gracePeriodMinutes": 60
    }')

GRACE_PERIOD=$(echo $GRACE_RESPONSE | jq -r '.gracePeriodMinutes')
if [ "$GRACE_PERIOD" == "60" ]; then
    test_result 0 "Grace period updated to 60 minutes"
else
    test_result 1 "Failed to update grace period"
    echo "Response: $GRACE_RESPONSE"
fi

# Step 12: Get Connection History (Patient)
echo -e "${YELLOW}=== Step 12: Get Connection History ===${NC}"
HISTORY_RESPONSE=$(curl -s -X GET "$BASE_URL/connections/history" \
    -H "Authorization: Bearer $PATIENT_TOKEN")

HISTORY_COUNT=$(echo $HISTORY_RESPONSE | jq '. | length')
if [ "$HISTORY_COUNT" -ge 1 ]; then
    test_result 0 "Retrieved connection history (count: $HISTORY_COUNT)"
    echo "Recent connections:"
    echo "$HISTORY_RESPONSE" | jq -r '.[] | "  - \(.status) at \(.createdAt)"'
else
    test_result 1 "Failed to retrieve history or list is empty"
    echo "Response: $HISTORY_RESPONSE"
fi

# Step 13: Get Connection History with Filter (Accepted only)
echo -e "${YELLOW}=== Step 13: Get Connection History (Accepted Only) ===${NC}"
HISTORY_ACCEPTED=$(curl -s -X GET "$BASE_URL/connections/history?status=ACCEPTED" \
    -H "Authorization: Bearer $PATIENT_TOKEN")

ACCEPTED_COUNT=$(echo $HISTORY_ACCEPTED | jq '. | length')
if [ "$ACCEPTED_COUNT" -ge 0 ]; then
    test_result 0 "Retrieved accepted connections (count: $ACCEPTED_COUNT)"
else
    test_result 1 "Failed to retrieve accepted connections"
    echo "Response: $HISTORY_ACCEPTED"
fi

# Step 14: Test Invalid Token Validation
echo -e "${YELLOW}=== Step 14: Test Invalid Token ===${NC}"
INVALID_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/connections/tokens/validate" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DOCTOR_TOKEN" \
    -d '{
        "token": "INVALID12"
    }')

HTTP_CODE=$(echo "$INVALID_TOKEN_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "404" ]; then
    test_result 0 "Invalid token properly rejected (HTTP $HTTP_CODE)"
else
    test_result 1 "Invalid token not properly rejected (HTTP $HTTP_CODE)"
fi

# Step 15: Test Duplicate Token Consumption
echo -e "${YELLOW}=== Step 15: Test Duplicate Token Consumption ===${NC}"
DUPLICATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/connections/tokens/consume" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DOCTOR_TOKEN" \
    -d "{
        \"token\": \"$CONNECTION_TOKEN\"
    }")

HTTP_CODE=$(echo "$DUPLICATE_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "409" ]; then
    test_result 0 "Duplicate token consumption properly rejected (HTTP $HTTP_CODE)"
else
    test_result 1 "Duplicate token consumption not properly rejected (HTTP $HTTP_CODE)"
fi

# Note: Steps 16-17 require actual dose data to test nudges
echo -e "${YELLOW}=== Step 16-17: Nudge System (Skipped - Requires Dose Data) ===${NC}"
echo "To test nudge system:"
echo "  1. Create a prescription for the patient"
echo "  2. Wait for a missed dose (scheduledTime + gracePeriod passed)"
echo "  3. POST /connections/nudge with patientId and doseId"
echo "  4. POST /connections/nudge/respond with caregiverId, doseId, and response"
echo ""

# Final Summary
echo "================================================"
echo -e "${YELLOW}Test Summary${NC}"
echo "================================================"
echo -e "Total Tests: ${TOTAL_TESTS}"
echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    exit 1
fi
