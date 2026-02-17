#!/bin/bash

# Script to get SHA-1 certificate fingerprints for Google OAuth configuration
# This is needed to configure Google Sign-In without Firebase

echo "========================================="
echo "Das Tern MCP - SHA-1 Certificate Getter"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}Error: keytool not found!${NC}"
    echo "keytool is part of Java JDK. Please install Java JDK first."
    exit 1
fi

echo "Getting SHA-1 certificates..."
echo ""

# Debug keystore (for development)
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [ -f "$DEBUG_KEYSTORE" ]; then
    echo -e "${GREEN}✓ Debug Keystore Found${NC}"
    echo "Location: $DEBUG_KEYSTORE"
    echo ""
    echo "--- DEBUG SHA-1 (for development) ---"
    DEBUG_SHA1=$(keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -oP "SHA1: \K.*")
    
    if [ -n "$DEBUG_SHA1" ]; then
        echo -e "${GREEN}SHA-1: $DEBUG_SHA1${NC}"
    else
        echo -e "${RED}Failed to extract SHA-1${NC}"
    fi
    echo ""
else
    echo -e "${YELLOW}⚠ Debug keystore not found at: $DEBUG_KEYSTORE${NC}"
    echo "You may need to build the app first: cd android && ./gradlew assembleDebug"
    echo ""
fi

# Release keystore (if exists)
echo "--- RELEASE SHA-1 (for production) ---"
if [ -f "android/app/release.keystore" ]; then
    echo -e "${YELLOW}Enter release keystore password:${NC}"
    RELEASE_SHA1=$(keytool -list -v -keystore android/app/release.keystore 2>/dev/null | grep -oP "SHA1: \K.*")
    if [ -n "$RELEASE_SHA1" ]; then
        echo -e "${GREEN}SHA-1: $RELEASE_SHA1${NC}"
    fi
else
    echo -e "${YELLOW}No release keystore found (optional for now)${NC}"
fi

echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo ""
echo "1. Copy the DEBUG SHA-1 fingerprint above"
echo ""
echo "2. Go to Google Cloud Console:"
echo "   https://console.cloud.google.com/"
echo ""
echo "3. Select your project or create a new one"
echo ""
echo "4. Go to: APIs & Services > Credentials"
echo ""
echo "5. Click 'Create Credentials' > 'OAuth 2.0 Client ID'"
echo "   - Application type: Android"
echo "   - Name: Das Tern MCP Android"
echo "   - Package name: com.example.das_tern_mcp"
echo "   - SHA-1: Paste the fingerprint from above"
echo ""
echo "6. The OAuth Client ID should be:"
echo "   843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com"
echo "   (This is already configured in your .env files)"
echo ""
echo "7. Make sure to also create a Web application OAuth client"
echo "   with the same client ID for your backend"
echo ""
echo "========================================="
echo ""
