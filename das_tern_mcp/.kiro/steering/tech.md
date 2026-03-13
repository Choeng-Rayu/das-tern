# Tech Stack

## Framework & Language

- **Flutter** SDK `^3.10.7`
- **Dart** language
- Target platforms: Android, iOS

## State Management

- **Provider** `^6.1.1` with ChangeNotifier pattern
- All providers registered in MultiProvider at app root

## Networking & Storage

- **http** `^1.1.2` for REST API calls
- **flutter_secure_storage** `^9.2.4` for encrypted token storage (Android EncryptedSharedPreferences, iOS Keychain)
- **sqflite** `^2.3.0` for offline SQLite database
- **shared_preferences** `^2.2.2` for lightweight key-value storage

## Key Libraries

- **flutter_local_notifications** `^17.2.3` + **timezone** `^0.9.4` for dose reminders
- **google_sign_in** `^6.1.0` for OAuth
- **connectivity_plus** `^5.0.2` for network state monitoring
- **fl_chart** `^0.69.0` for adherence and vitals charts
- **qr_flutter** `^4.1.0` + **mobile_scanner** `^7.0.0` for QR code generation/scanning
- **image_picker** `^1.0.7` for OCR prescription scanning
- **intl** `^0.20.2` for i18n (English/Khmer via ARB files)

## Common Commands

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Code quality checks (REQUIRED before any PR)
flutter analyze
flutter analyze --no-fatal-infos
flutter test

# Generate localizations
flutter gen-l10n

# Clean build artifacts
flutter clean
```

## Development Configuration

- Backend API URL configured in `.env` file (`API_BASE_URL`)
- For physical device testing, update `hostIpAddress` in `lib/utils/api_constants.dart` to your machine's LAN IP
- Use `--dart-define=USE_ANDROID_EMULATOR=true` to switch to emulator host `10.0.2.2`

## Code Quality Requirements

All code must pass these checks before being considered complete:

1. `flutter analyze` - must show 0 issues
2. `flutter analyze --no-fatal-infos` - stricter pass with no info-level warnings
3. `flutter test` - all widget/unit tests must pass
