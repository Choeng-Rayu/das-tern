# Das Tern Mobile App - Quick Start Guide

## 🚀 Getting Started

This guide will help you set up and run the Das Tern Mobile App MVP on your local machine.

---

## Prerequisites

### Required Software
- **Flutter SDK**: 3.10.7 or higher
- **Dart SDK**: Included with Flutter
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **VS Code** or **Android Studio** (recommended IDEs)

### Verify Installation
```bash
flutter doctor
```

Ensure all checkmarks are green for your target platform.

---

## Installation Steps

### 1. Clone the Repository
```bash
cd /path/to/das-tern
cd mobile_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Localization Files
```bash
flutter gen-l10n
```

### 4. Run the App

#### On Android Emulator/Device
```bash
flutter run
```

#### On iOS Simulator/Device (macOS only)
```bash
flutter run -d ios
```

#### On Chrome (Web)
```bash
flutter run -d chrome
```

---

## Project Structure

```
mobile_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── l10n/                        # Localization files
│   ├── models/                      # Data models
│   ├── providers/                   # State management
│   ├── services/                    # Business logic
│   └── ui/                          # User interface
│       ├── screens/                 # App screens
│       ├── widgets/                 # Reusable widgets
│       └── theme/                   # Theme configuration
├── pubspec.yaml                     # Dependencies
└── l10n.yaml                        # Localization config
```

---

## Key Features

### 1. Create Medication
- Tap the **+** button on the dashboard
- Fill in medication details
- Set reminder times
- Save to create

### 2. View Dashboard
- See today's medication schedule
- Grouped by daytime (6 AM - 6 PM) and night (6 PM - 6 AM)
- Progress bar shows completion status

### 3. Mark as Taken
- Tap the checkbox on a medication card
- Status updates to "Taken" or "Taken Late"
- Notification is cancelled

### 4. Change Language
- Go to Settings tab
- Tap Language
- Select English or Khmer

### 5. Change Theme
- Go to Settings tab
- Tap Theme
- Select Light, Dark, or System

---

## Development Workflow

### Hot Reload
While the app is running, press `r` in the terminal to hot reload changes.

### Hot Restart
Press `R` in the terminal to hot restart the app.

### Analyze Code
```bash
flutter analyze
```

### Format Code
```bash
flutter format lib/
```

### Run Tests
```bash
flutter test
```

---

## Database

The app uses **SQLite** for local storage with three tables:

### medications
- Stores medication information
- Fields: id, name, dosage, form, instructions, type, status, frequency, reminder_times, created_at, updated_at, synced

### dose_events
- Stores scheduled doses
- Fields: id, medication_id, scheduled_time, taken_time, status, notes, synced

### sync_queue
- Stores pending sync operations
- Fields: id, action, table_name, record_id, data, created_at

### View Database (Android)
```bash
adb shell
cd /data/data/com.example.mobile_app/databases
sqlite3 dastern.db
.tables
SELECT * FROM medications;
```

---

## Notifications

### Android Setup
Notifications are configured to work on Android 12+ with exact alarms.

### iOS Setup
Permissions are requested on first launch.

### Test Notifications
1. Create a medication with a reminder time 1-2 minutes in the future
2. Wait for the notification to appear
3. Tap the notification to open the app

---

## Offline Mode

The app is **offline-first**:
- All data is stored locally in SQLite
- Changes are queued for sync when offline
- Auto-syncs when connectivity is restored

### Test Offline Mode
1. Turn off WiFi and mobile data
2. Create a medication
3. Mark a dose as taken
4. Turn on connectivity
5. Check that changes sync to the backend

---

## Localization

### Add New Translation Keys

1. Edit `lib/l10n/app_en.arb`:
```json
"myNewKey": "My New Text",
"@myNewKey": {
  "description": "Description of the key"
}
```

2. Edit `lib/l10n/app_km.arb`:
```json
"myNewKey": "អត្ថបទថ្មីរបស់ខ្ញុំ"
```

3. Regenerate localization files:
```bash
flutter gen-l10n
```

4. Use in code:
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.myNewKey)
```

---

## Theming

### Modify Colors

Edit `lib/ui/theme/light_mode.dart` or `lib/ui/theme/dart_mode.dart`:

```dart
final lightTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Color(0xFF2D5BFF),      // Blue
    secondary: Color(0xFFFF6B35),    // Orange
    // ... other colors
  ),
);
```

---

## State Management

The app uses **Provider** for state management.

### Key Providers

- **MedicationProvider**: Manages medications
- **DoseEventProvider**: Manages dose events
- **ThemeProvider**: Manages theme mode
- **LocaleProvider**: Manages language

### Access Provider in Widget
```dart
// Read once
final provider = context.read<MedicationProvider>();

// Watch for changes
final provider = context.watch<MedicationProvider>();

// Use Consumer
Consumer<MedicationProvider>(
  builder: (context, provider, child) {
    return Text('${provider.medications.length} medications');
  },
)
```

---

## API Integration

### Configure Backend URL

Edit `lib/services/api_service.dart`:

```dart
final String baseUrl = 'https://your-api-url.com/api';
```

### API Endpoints

- `POST /medications` - Create medication
- `GET /medications` - Get all medications
- `PUT /medications/:id` - Update medication
- `POST /dose-events/sync` - Sync dose events
- `PUT /dose-events/:id` - Update dose event

---

## Troubleshooting

### Issue: Dependencies not resolving
```bash
flutter clean
flutter pub get
```

### Issue: Localization not working
```bash
flutter gen-l10n
flutter clean
flutter run
```

### Issue: Database not initializing
```bash
# Uninstall app from device/emulator
flutter clean
flutter run
```

### Issue: Notifications not appearing
- Check device notification settings
- Ensure app has notification permissions
- Check that reminder time is in the future

---

## Building for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS only)
```bash
flutter build ios --release
```
Then open Xcode to archive and upload to App Store.

---

## Useful Commands

```bash
# Check Flutter version
flutter --version

# List connected devices
flutter devices

# Run with specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release

# Generate app icons
flutter pub run flutter_launcher_icons:main

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [SQLite Package](https://pub.dev/packages/sqflite)
- [Local Notifications](https://pub.dev/packages/flutter_local_notifications)

---

## Support

For issues or questions:
- Check `IMPLEMENTATION_STATUS.md` for feature status
- Review code comments in source files
- Consult the main `README.md` in the project root

---

## Next Steps

1. ✅ Run the app and explore features
2. ✅ Create a test medication
3. ✅ Test notifications
4. ✅ Test offline mode
5. ✅ Switch languages and themes
6. 📝 Review code structure
7. 🧪 Write integration tests
8. 🚀 Deploy to production

Happy coding! 🎉
