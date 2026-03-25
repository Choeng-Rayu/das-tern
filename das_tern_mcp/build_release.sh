#!/bin/bash

# Das Tern - Production Release Build Script
# This script builds the release Android App Bundle (.aab) for Google Play deployment
# Google Play requires .aab format, not .apk

set -e

echo "=============================================="
echo "  Das Tern - Production Build Script (.aab)"
echo "=============================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if keystore exists
if [ ! -f "android/app/release.keystore" ]; then
    echo -e "${RED}ERROR: release.keystore not found!${NC}"
    echo "Please ensure the keystore is in: android/app/release.keystore"
    exit 1
fi

# Check if keystore.properties exists
if [ ! -f "android/keystore.properties" ]; then
    echo -e "${RED}ERROR: keystore.properties not found!${NC}"
    echo "Please ensure keystore.properties is in: android/"
    exit 1
fi

echo -e "${GREEN}✓${NC} Keystore files found"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
flutter pub get
echo ""

# Build release Android App Bundle (.aab) - REQUIRED for Google Play
echo "Building release Android App Bundle (.aab)..."
flutter build appbundle --release

# Verify output
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo ""
    echo -e "${GREEN}✓${NC} Release AAB built successfully!"
    echo ""
    echo "Output: build/app/outputs/bundle/release/app-release.aab"
    echo ""
    
    # Show file size
    SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo -e "${GREEN}Size:${NC} $SIZE"
    
    # Verify signature
    echo ""
    echo "Verifying signature..."
    /usr/lib/jvm/java-21-openjdk/bin/keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep "SHA-1"
    echo ""
    echo "Should match:"
    echo "SHA-1: F8:98:7F:E8:97:0B:76:1F:00:F5:B7:CB:52:92:2D:A4:76:37:6D:53"
    echo ""
    echo "=============================================="
    echo -e "${GREEN}Build complete! Ready for Play Store.${NC}"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "1. Go to Google Play Console: https://play.google.com/console"
    echo "2. Create new app or select existing app"
    echo "3. Go to Production > Create release"
    echo "4. Upload the .aab file:"
    echo "   build/app/outputs/bundle/release/app-release.aab"
else
    echo ""
    echo -e "${RED}ERROR: Build failed!${NC}"
    exit 1
fi
