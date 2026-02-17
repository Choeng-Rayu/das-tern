#!/bin/bash

# Automated Google Sign-In Setup and Fix Script for Das Tern MCP
# This script helps diagnose and fix Google Sign-In issues

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Das Tern MCP - Google Sign-In Setup${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Check prerequisites
print_step "Step 1: Checking prerequisites..."

if ! command -v keytool &> /dev/null; then
    print_error "keytool not found. Please install Java JDK."
    exit 1
fi
print_success "keytool found"

if ! command -v flutter &> /dev/null; then
    print_error "Flutter not found. Please install Flutter."
    exit 1
fi
print_success "Flutter found ($(flutter --version | head -1))"

# Get SHA-1
print_step "Step 2: Getting SHA-1 certificate fingerprint..."

DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
if [ -f "$DEBUG_KEYSTORE" ]; then
    SHA1=$(keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -oP "SHA1: \K.*")
    if [ -n "$SHA1" ]; then
        print_success "SHA-1 extracted successfully"
        echo ""
        echo -e "${YELLOW}Your DEBUG SHA-1 Certificate:${NC}"
        echo -e "${GREEN}$SHA1${NC}"
        echo ""
    else
        print_error "Failed to extract SHA-1"
        exit 1
    fi
else
    print_error "Debug keystore not found at: $DEBUG_KEYSTORE"
    print_info "Building app to generate keystore..."
    cd android && ./gradlew assembleDebug && cd ..
    print_success "Build complete. Re-run this script."
    exit 0
fi

# Check package name
print_step "Step 3: Verifying package name..."

PACKAGE_NAME=$(grep "applicationId" android/app/build.gradle.kts | sed -n 's/.*applicationId = "\(.*\)"/\1/p' | tr -d '[:space:]')
if [ "$PACKAGE_NAME" = "com.example.das_tern_mcp" ]; then
    print_success "Package name correct: $PACKAGE_NAME"
else
    print_error "Package name mismatch: $PACKAGE_NAME (expected: com.example.das_tern_mcp)"
fi

# Check Google Client ID
print_step "Step 4: Checking Google Client ID configuration..."

if [ -f ".env" ]; then
    CLIENT_ID=$(grep "GOOGLE_CLIENT_ID" .env | cut -d '=' -f2)
    if [ -n "$CLIENT_ID" ]; then
        print_success "Google Client ID found: $CLIENT_ID"
    else
        print_error "GOOGLE_CLIENT_ID not found in .env"
    fi
else
    print_error ".env file not found"
fi

# Check backend configuration
print_step "Step 5: Checking backend configuration..."

BACKEND_ENV="../backend_nestjs/.env"
if [ -f "$BACKEND_ENV" ]; then
    BACKEND_CLIENT_ID=$(grep "GOOGLE_CLIENT_ID" "$BACKEND_ENV" | cut -d '=' -f2)
    if [ "$CLIENT_ID" = "$BACKEND_CLIENT_ID" ]; then
        print_success "Backend Google Client ID matches"
    else
        print_error "Backend Google Client ID mismatch"
        echo "  Flutter: $CLIENT_ID"
        echo "  Backend: $BACKEND_CLIENT_ID"
    fi
else
    print_error "Backend .env not found at $BACKEND_ENV"
fi

# Check if Firebase plugin was removed
print_step "Step 6: Verifying Firebase removal..."

if grep -q "google-services" android/app/build.gradle.kts; then
    print_error "Firebase plugin still present in build.gradle.kts"
    print_info "Removing Firebase dependency..."
    
    # Remove Firebase plugin
    sed -i '/google-services/d' android/app/build.gradle.kts
    sed -i '/google-services/d' android/build.gradle.kts
    
    print_success "Firebase plugin removed"
else
    print_success "Firebase plugin not present (correct!)"
fi

# Clean build
print_step "Step 7: Cleaning build..."

print_info "Running flutter clean..."
flutter clean > /dev/null 2>&1
print_success "Flutter clean complete"

print_info "Running gradle clean..."
cd android && ./gradlew clean > /dev/null 2>&1 && cd ..
print_success "Gradle clean complete"

# Get dependencies
print_step "Step 8: Getting Flutter dependencies..."

flutter pub get > /dev/null 2>&1
print_success "Dependencies fetched"

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}CRITICAL: You MUST configure Google Cloud Console${NC}"
echo ""
echo "1. Go to: ${BLUE}https://console.cloud.google.com/${NC}"
echo ""
echo "2. Navigate to: ${BLUE}APIs & Services > Credentials${NC}"
echo ""
echo "3. Click: ${BLUE}Create Credentials > OAuth 2.0 Client ID${NC}"
echo ""
echo "4. Configure for Android:"
echo "   • Application type: ${YELLOW}Android${NC}"
echo "   • Name: ${YELLOW}Das Tern MCP Android${NC}"
echo "   • Package name: ${YELLOW}$PACKAGE_NAME${NC}"
echo "   • SHA-1: ${YELLOW}$SHA1${NC}"
echo ""
echo "5. Also create Web OAuth client (if not exists):"
echo "   • Application type: ${YELLOW}Web application${NC}"
echo "   • Name: ${YELLOW}Das Tern Backend${NC}"
echo "   • Use the SAME client ID: ${YELLOW}$CLIENT_ID${NC}"
echo ""
echo -e "${GREEN}After configuring Google Cloud Console:${NC}"
echo "   • Wait 5-10 minutes for changes to propagate"
echo "   • Run: ${BLUE}flutter run${NC}"
echo "   • Test Google Sign-In"
echo ""
echo -e "${YELLOW}If still not working:${NC}"
echo "   • Clear app data: ${BLUE}adb shell pm clear $PACKAGE_NAME${NC}"
echo "   • Check logs: ${BLUE}adb logcat | grep -i google${NC}"
echo "   • Verify OAuth consent screen is configured"
echo ""
