#!/bin/bash

# Test Google OAuth Configuration
# Run this after creating the Android OAuth client in Google Cloud Console

echo "========================================="
echo " Google OAuth Configuration Test"
echo "========================================="
echo ""

cd /home/rayu/das-tern/das_tern_mcp

echo "✓ Package Name: com.example.das_tern_mcp"
echo "✓ SHA-1: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF"
echo ""

echo "Checking .env configuration..."
if grep -q "265372630808-uebdmc8rr9kr8vffs0brluuelkh3ofkp" .env; then
    echo "✓ GOOGLE_CLIENT_ID is set correctly"
else
    echo "✗ GOOGLE_CLIENT_ID not found or incorrect"
    exit 1
fi
echo ""

echo "Checking auth_provider.dart..."
if grep -q "serverClientId: dotenv.env\['GOOGLE_CLIENT_ID'\]" lib/providers/auth_provider.dart; then
    echo "✓ serverClientId is configured"
else    
    echo "✗ serverClientId not configured properly"
    exit 1
fi
echo ""

echo "========================================="
echo " Next Steps:"
echo "========================================="
echo ""
echo "1. Create Android OAuth client in Google Cloud Console:"
echo "   https://console.cloud.google.com/apis/credentials?project=das-tern"
echo ""
echo "2. Use these values when creating:"
echo "   Package: com.example.das_tern_mcp"
echo "   SHA-1: DC:9E:6E:71:D7:32:B2:44:B3:40:42:A4:8D:D4:4F:AA:E3:B4:8A:DF"
echo ""
echo "3. Wait 5-10 minutes for Google to sync"
echo ""
echo "4. Clean and rebuild:"
echo "   flutter clean && flutter pub get && flutter run"
echo ""
echo "========================================="
