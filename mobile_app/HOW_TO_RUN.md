# Running Das Tern Mobile App

## ⚠️ Important: Platform Requirements

This app is designed for **mobile platforms** (Android/iOS) and uses SQLite for local storage, which **does not work on web browsers**.

---

## ✅ Correct Way to Run

### Option 1: Android Emulator (Recommended)
```bash
# Start Android emulator first
# Then run:
cd /home/rayu/das-tern/mobile_app
flutter run
```

### Option 2: Physical Device
```bash
# Connect your Android/iOS device via USB
# Enable USB debugging on Android
cd /home/rayu/das-tern/mobile_app
flutter run
```

### Option 3: iOS Simulator (macOS only)
```bash
# Start iOS simulator first
cd /home/rayu/das-tern/mobile_app
flutter run
```

---

## ❌ What NOT to Do

### Don't Run on Web/Chrome
```bash
# This will FAIL with SQLite error:
flutter run -d chrome  # ❌ Don't do this
flutter run -d web     # ❌ Don't do this
```

**Why?** SQLite doesn't work in web browsers. The app needs native mobile platform.

---

## 🔧 Setup Instructions

### 1. Check Available Devices
```bash
flutter devices
```

You should see something like:
```
Android SDK built for x86 (mobile) • emulator-5554 • android-x86 • Android 11 (API 30)
Chrome (web)                       • chrome        • web-javascript • Google Chrome 120.0
```

### 2. Run on Android Emulator
```bash
# If you see an Android device in the list:
flutter run -d emulator-5554

# Or just:
flutter run
# (Flutter will automatically choose the first available device)
```

### 3. If No Emulator is Running

**Start Android Emulator:**
```bash
# List available emulators
emulator -list-avds

# Start an emulator (replace with your AVD name)
emulator -avd Pixel_4_API_30 &

# Wait for emulator to boot, then:
flutter run
```

---

## 🐛 Troubleshooting

### Error: "databaseFactory not initialized"
**Cause**: You're running on web/Chrome  
**Solution**: Run on Android/iOS emulator or device

### Error: "No devices found"
**Solution**: Start an Android emulator or connect a physical device

### Error: "Unable to locate Android SDK"
**Solution**: Install Android Studio and Android SDK

---

## 📱 Recommended Setup

### For Development:
1. **Install Android Studio**
2. **Create an Android Virtual Device (AVD)**
   - Open Android Studio
   - Tools → Device Manager
   - Create Device → Pixel 4
   - System Image → Android 11 (API 30)
3. **Start the emulator**
4. **Run the app**: `flutter run`

---

## ✅ Quick Start (If Emulator is Ready)

```bash
cd /home/rayu/das-tern/mobile_app
flutter run
```

That's it! The app will:
1. Start on the login screen
2. Initialize SQLite database
3. Set up local notifications
4. Enable offline sync

---

## 🎯 Testing the App

Once running on mobile:

1. **Login Screen**
   - Dark blue background
   - Enter any phone/email
   - Enter any password
   - Tap "Login"

2. **Dashboard**
   - See bottom navigation
   - Tap Settings tab
   - Change language (EN/KM)
   - Change theme (Light/Dark/System)

3. **Create Medication**
   - Tap + button
   - Fill in medication details
   - Save

---

## 📝 Notes

- **Web support** will be added in future phases with alternative storage
- **Current focus** is mobile-first (Android/iOS)
- **SQLite** is essential for offline-first architecture
- **Local notifications** only work on mobile

---

## 🚀 Next Steps

After running successfully:
1. Test login flow
2. Test theme switching
3. Test language switching
4. Test medication creation
5. Test offline mode

---

**Last Updated**: February 9, 2026
