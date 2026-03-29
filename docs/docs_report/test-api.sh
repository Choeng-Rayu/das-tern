#!/bin/bash

# Test script to verify backend API is working

echo "=== Testing DAS-TERN Backend API ==="
echo ""

# Test 1: Health endpoint (no auth required)
echo "1. Testing health endpoint..."
curl -s -w "\nStatus: %{http_code}\n" https://api.dastern.site/api/v1/health
echo ""

# Test 2: Login endpoint (should fail with 400 if no body, but should respond)
echo "2. Testing login endpoint (should respond even if fails)..."
curl -s -w "\nStatus: %{http_code}\n" -X POST https://api.dastern.site/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"test","password":"test"}'
echo ""

# Test 3: Register patient endpoint
echo "3. Testing register patient endpoint..."
curl -s -w "\nStatus: %{http_code}\n" -X POST https://api.dastern.site/api/v1/auth/register/patient \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+85512345678","password":"Test123!","firstName":"Test","lastName":"User","dateOfBirth":"2000-01-01"}'
echo ""

# Test 4: Check CORS headers
echo "4. Checking CORS headers..."
curl -s -i -X OPTIONS https://api.dastern.site/api/v1/auth/login \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST" | grep -i "access-control"
echo ""

echo "=== Test Complete ==="

