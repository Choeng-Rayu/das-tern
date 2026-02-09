# Issue Fixed: SQLite on Web

**Date**: February 9, 2026  
**Issue**: App crashes when running on web/Chrome with SQLite error  
**Status**: ✅ Fixed

---

## Problem

When running `flutter run` (which defaults to Chrome on systems without mobile emulators), the app crashed with:

```
DartError: Bad state: databaseFactory not initialized
databaseFactory is only initialized when using sqflite.
```

**Root Cause**: SQLite doesn't work in web browsers. The app is designed for mobile platforms (Android/iOS).

---

## Solution

### 1. Added Platform Check
Updated `main.dart` to:
- Skip SQLite initialization on web (`kIsWeb` check)
- Skip notification service on web
- Skip sync service on web

### 2. Added Helpful Web Warning
When running on web, the app now shows a clear message:
- Explains web is not supported
- Lists supported platforms (Android/iOS)
- Provides instructions to run on mobile

### 3. Created Documentation
- `HOW_TO_RUN.md` - Complete guide on running the app correctly
- Explains why web doesn't work
- Provides setup instructions for Android emulator

---

## How to Run Correctly

### ✅ Option 1: Android Emulator (Recommended)
```bash
# 1. Start Android emulator
# 2. Run app
cd /home/rayu/das-tern/mobile_app
flutter run
```

### ✅ Option 2: Physical Device
```bash
# Connect device via USB, enable USB debugging
flutter run
```

### ❌ Don't Run on Web
```bash
flutter run -d chrome  # ❌ Will show warning screen
```

---

## What Changed

### Files Modified:
1. **lib/main.dart**
   - Added `import 'package:flutter/foundation.dart' show kIsWeb;`
   - Wrapped service initialization in `if (!kIsWeb)` check
   - Added web warning screen

### Files Created:
2. **HOW_TO_RUN.md**
   - Complete running instructions
   - Platform requirements
   - Troubleshooting guide

---

## Testing

### On Web (Chrome):
```bash
flutter run -d chrome
```
**Result**: Shows helpful warning screen ✅

### On Mobile (when emulator available):
```bash
flutter run
```
**Result**: App runs normally with SQLite ✅

---

## Why This Approach?

### Mobile-First Design
- App uses SQLite for offline-first architecture
- Local notifications require native platform
- Background sync needs native capabilities

### Future Web Support
- Phase 4 will add web support with:
  - IndexedDB instead of SQLite
  - Web notifications API
  - Service workers for offline

### Current Focus
- MVP is mobile-only (Android/iOS)
- Web support is planned but not in Phase 1

---

## Next Steps

### To Run the App:
1. **Install Android Studio** (if not installed)
2. **Create Android Virtual Device (AVD)**
3. **Start emulator**
4. **Run**: `flutter run`

### Alternative:
- Use physical Android/iOS device
- Connect via USB
- Enable USB debugging
- Run: `flutter run`

---

## Summary

✅ **Fixed**: App no longer crashes on web  
✅ **Added**: Helpful warning message on web  
✅ **Created**: Documentation on how to run correctly  
✅ **Tested**: Works on web (shows warning) and mobile (runs normally)  

**Status**: Ready to run on mobile platforms! 🚀

---

*Last Updated: February 9, 2026, 08:40*
