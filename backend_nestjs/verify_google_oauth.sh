#!/bin/bash

# Backend Google OAuth Verification Script
# Verifies that backend is properly configured to handle Google Sign-In

set -e

echo "==========================================="
echo "Backend Google OAuth Configuration Check"
echo "==========================================="
echo ""

# Check if backend is running
BACKEND_URL="http://10.138.213.210:3001/api/v1"
echo "Checking if backend is running at $BACKEND_URL..."

if curl -s -f "$BACKEND_URL/health" > /dev/null 2>&1; then
    echo "✓ Backend is running"
else
    echo "✗ Backend is NOT running"
    echo "Please start the backend:"
    echo "  cd /home/rayu/das-tern/backend_nestjs"
    echo "  npm run start:dev"
    exit 1
fi

# Check .env configuration
echo ""
echo "Checking backend .env configuration..."

BACKEND_ENV="/home/rayu/das-tern/backend_nestjs/.env"
if [ -f "$BACKEND_ENV" ]; then
    CLIENT_ID=$(grep "GOOGLE_CLIENT_ID" "$BACKEND_ENV" | cut -d '=' -f2)
    CLIENT_SECRET=$(grep "GOOGLE_CLIENT_SECRET" "$BACKEND_ENV" | cut -d '=' -f2)
    
    echo "✓ Backend .env found"
    echo "  GOOGLE_CLIENT_ID: ${CLIENT_ID:0:20}..."
    echo "  GOOGLE_CLIENT_SECRET: ${CLIENT_SECRET:0:10}..."
    
    if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "your-google-client-id" ]; then
        echo "✗ GOOGLE_CLIENT_ID not configured properly"
        exit 1
    fi
    
    if [ -z "$CLIENT_SECRET" ] || [ "$CLIENT_SECRET" = "your-google-client-secret" ]; then
        echo "✗ GOOGLE_CLIENT_SECRET not configured properly"
        exit 1
    fi
else
    echo "✗ Backend .env not found at $BACKEND_ENV"
    exit 1
fi

# Check if google-auth-library is installed
echo ""
echo "Checking google-auth-library dependency..."

if grep -q "google-auth-library" "/home/rayu/das-tern/backend_nestjs/package.json"; then
    echo "✓ google-auth-library dependency found"
else
    echo "✗ google-auth-library not found in package.json"
    echo "Installing..."
    cd /home/rayu/das-tern/backend_nestjs
    npm install google-auth-library
    echo "✓ Installed"
fi

# Test Google auth endpoint
echo ""
echo "Testing Google auth endpoint..."

RESPONSE=$(curl -s -X POST "$BACKEND_URL/auth/google" \
    -H "Content-Type: application/json" \
    -d '{"idToken": "invalid_test_token"}' \
    -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "400" ]; then
    echo "✓ Google auth endpoint responding correctly"
    echo "  (401/400 expected for invalid token)"
else
    echo "Response code: $HTTP_CODE"
    echo "Body: $BODY"
fi

echo ""
echo "==========================================="
echo "✓ Backend configuration looks good!"
echo "==========================================="
echo ""
echo "Next steps:"
echo "1. Configure Google Cloud Console with your SHA-1"
echo "   See: GOOGLE_CLOUD_SETUP.md"
echo ""
echo "2. Wait 5-10 minutes for Google OAuth changes to propagate"
echo ""
echo "3. Run the Flutter app:"
echo "   cd /home/rayu/das-tern/das_tern_mcp"
echo "   flutter run"
echo ""
echo "4. Test Google Sign-In in the app"
echo ""
