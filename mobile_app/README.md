# 📱 Das Tern Mobile App

> **Flutter-based medication management app with offline-first architecture, multi-language support, and adaptive theming**

---

## 📖 Overview

Das Tern mobile app is a cross-platform Flutter application that serves patients, doctors, and family caregivers. The app features robust offline capabilities, bilingual support (English/Khmer), and adaptive light/dark themes.

### ✨ Key Features

- 🌍 **Multi-language Support** - English and Khmer (Cambodia)
- 🎨 **Theme Switching** - Light and Dark mode with role-based color schemes
- 📱 **Offline-First** - Full functionality without internet
- 🔔 **Smart Reminders** - Local notifications for medication schedules
- 👥 **Multi-Role UI** - Single app adapts for Patient/Doctor/Family roles
- 🔐 **Secure Storage** - Encrypted local data persistence

---

## 🌍 Language Switching Implementation

### Architecture

The app uses Flutter's built-in internationalization (i18n) system with ARB (Application Resource Bundle) files for translations.

#### File Structure

```
lib/l10n/
├── README.md                      # Localization guidelines
├── app_en.arb                     # English translations
├── app_km.arb                     # Khmer translations
├── app_localizations.dart         # Generated base class
├── app_localizations_en.dart      # Generated English class
└── app_localizations_km.dart      # Generated Khmer class
```

### Supported Languages

| Language | Locale Code | ARB File | Status |
|----------|-------------|----------|--------|
| **English** | `en` | `app_en.arb` | ✅ Active |
| **Khmer** | `km` | `app_km.arb` | ✅ Active |

### How It Works

#### 1. ARB Files Structure

Each translation is defined as a key-value pair with metadata:

**English (`app_en.arb`):**
```json
{
  "@@locale": "en",
  "appTitle": "DasTern",
  "@appTitle": {
    "description": "The application title"
  },
  "createNewAccount": "Create a new account",
  "@createNewAccount": {
    "description": "Create a new account"
  },
  "firstName": "First name / Given name",
  "lastName": "Last name / Surname",
  "gender": "Gender",
  "dateOfBirth": "Date of birth (Day, Month, Year)"
}
```

**Khmer (`app_km.arb`):**
```json
{
  "@@locale": "km",
  "appTitle": "DasTern",
  "createNewAccount": "បង្កើតគណនីថ្មី",
  "firstName": "នាមខ្លួន",
  "lastName": "នាមត្រកូល",
  "gender": "ភេទ",
  "dateOfBirth": "ថ្ងៃ ខែ ឆ្នាំ កំណើត"
}
```

#### 2. Generated Localization Classes

Flutter automatically generates type-safe localization classes:

```dart
// lib/l10n/app_localizations.dart
abstract class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate = 
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('km')
  ];

  String get appTitle;
  String get createNewAccount;
  String get firstName;
  // ... other getters
}
```

#### 3. Usage in Widgets

Access translations using `AppLocalizations.of(context)`:

```dart
import 'package:mobile_app/l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Text(l10n.appTitle); // Displays "DasTern" or "DasTern" based on locale
  }
}
```

#### 4. App Configuration

Configure in `MaterialApp`:

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: currentLocale, // From state management
  home: MyHomePage(),
)
```

### Language Switching Flow

```
┌─────────────────────────────────────────────────────────┐
│  USER ACTION                                            │
├─────────────────────────────────────────────────────────┤
│  User taps language selector in Settings               │
│  • English / Khmer toggle                               │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  STATE MANAGEMENT                                       │
├─────────────────────────────────────────────────────────┤
│  1. Update locale in app state (Riverpod/Bloc)         │
│  2. Save preference to local storage                    │
│     • SharedPreferences: "locale" → "en" or "km"        │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  UI REBUILD                                             │
├─────────────────────────────────────────────────────────┤
│  1. MaterialApp rebuilds with new locale                │
│  2. All widgets using AppLocalizations.of(context)      │
│     automatically display new language                  │
│  3. No app restart required                             │
└─────────────────────────────────────────────────────────┘
```

### Adding New Languages

1. **Create ARB file**: `lib/l10n/app_[locale].arb`
2. **Add translations**: Copy structure from `app_en.arb`
3. **Run code generation**:
   ```bash
   flutter gen-l10n
   ```
4. **Update supported locales**: Automatically detected from ARB files

### Default Behavior

- **System Language Detection**: App defaults to device language if supported
- **Fallback**: English (`en`) if device language not supported
- **Persistence**: User's language choice saved locally and persists across sessions
- **Cambodia Default**: For PRN medications, system uses Cambodia timezone (UTC+7)

---

## 🎨 Theme Switching Implementation

### Architecture

The app supports both light and dark themes with role-specific color schemes for Patient and Doctor interfaces.

#### File Structure

```
lib/ui/theme/
├── README.md              # Theme guidelines
├── main_theme.dart        # Theme configuration and switching logic
├── light_mode.dart        # Light theme definitions
└── dark_mode.dart         # Dark theme definitions
```

### Theme System

#### Color Palette

**Light Mode:**
| Role | Primary | Secondary | Background | Surface |
|------|---------|-----------|------------|---------|
| **Patient** | Blue `#2D5BFF` | Orange `#FF6B35` | White `#FFFFFF` | Gray `#F5F5F5` |
| **Doctor** | Dark Blue `#1A2744` | Teal `#00897B` | White `#FFFFFF` | Gray `#F5F5F5` |

**Dark Mode:**
| Role | Primary | Secondary | Background | Surface |
|------|---------|-----------|------------|---------|
| **Patient** | Light Blue `#5C7CFF` | Orange `#FF8A5B` | Dark `#121212` | Dark Gray `#1E1E1E` |
| **Doctor** | Blue Gray `#37474F` | Teal `#26A69A` | Dark `#121212` | Dark Gray `#1E1E1E` |

**Semantic Colors (Both Modes):**
- **Success**: Green `#4CAF50` (taken medication)
- **Warning**: Orange `#FF6B35` (late dose)
- **Error**: Red `#E53935` (missed dose)
- **Info**: Blue `#2196F3` (reminders)

#### Time-Based Color Coding

Medication sections use time-specific colors:

| Time Period | Color | Hex | Usage |
|-------------|-------|-----|-------|
| 🌅 **Morning** | Blue | `#2D5BFF` | Morning medication section |
| ☀️ **Afternoon** | Orange | `#FF6B35` | Afternoon medication section |
| 🌙 **Night** | Purple | `#6B4AA3` | Night medication section |

### How It Works

#### 1. Theme Data Definition

**Light Theme (`light_mode.dart`):**
```dart
import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Color(0xFF2D5BFF),      // Primary Blue
    secondary: Color(0xFFFF6B35),    // Afternoon Orange
    surface: Color(0xFFF5F5F5),      // Background
    error: Color(0xFFE53935),        // Alert Red
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF1A2744),    // Dark Blue text
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF2D5BFF),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: Color(0xFFF5F5F5),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A2744),
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      color: Color(0xFF1A2744),
    ),
  ),
);
```

**Dark Theme (`dark_mode.dart`):**
```dart
import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF5C7CFF),      // Light Blue
    secondary: Color(0xFFFF8A5B),    // Light Orange
    surface: Color(0xFF1E1E1E),      // Dark Gray
    error: Color(0xFFEF5350),        // Light Red
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF121212),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: Color(0xFF1E1E1E),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      color: Colors.white,
    ),
  ),
);
```

#### 2. Theme Management (`main_theme.dart`)

```dart
import 'package:flutter/material.dart';
import 'light_mode.dart';
import 'dark_mode.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    _saveThemePreference(isDark);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
```

#### 3. App Configuration

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/theme/main_theme.dart';
import 'ui/theme/light_mode.dart';
import 'ui/theme/dark_mode.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider()..loadThemePreference(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Das Tern',
      theme: lightTheme,           // Light theme
      darkTheme: darkTheme,         // Dark theme
      themeMode: themeProvider.themeMode, // Current mode
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}
```

#### 4. Usage in Widgets

Access theme colors using `Theme.of(context)`:

```dart
class MedicationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.cardTheme.color,
      child: ListTile(
        leading: Icon(
          Icons.medication,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          'Aspirin',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
```

### Theme Switching Flow

```
┌─────────────────────────────────────────────────────────┐
│  USER ACTION                                            │
├─────────────────────────────────────────────────────────┤
│  User toggles theme in Settings                         │
│  • Light / Dark / System toggle                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  STATE MANAGEMENT                                       │
├─────────────────────────────────────────────────────────┤
│  1. ThemeProvider.toggleTheme(isDark)                   │
│  2. Update _themeMode (light/dark/system)               │
│  3. Save to SharedPreferences                           │
│     • Key: "isDarkMode" → true/false                    │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  UI REBUILD                                             │
├─────────────────────────────────────────────────────────┤
│  1. notifyListeners() triggers rebuild                  │
│  2. MaterialApp switches theme                          │
│  3. All widgets using Theme.of(context) update          │
│  4. Smooth transition animation                         │
└─────────────────────────────────────────────────────────┘
```

### Theme Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| **Light** | Always light theme | User preference |
| **Dark** | Always dark theme | User preference |
| **System** | Follows device settings | Default behavior |

### Adaptive Features

- **Status Bar**: Automatically adjusts color based on theme
- **Navigation Bar**: Matches theme background
- **Splash Screen**: Adapts to system theme on launch
- **Illustrations**: SVG assets with theme-aware colors
- **Icons**: Use theme's `iconTheme` for consistent coloring

### Default Behavior

- **Initial Load**: Follows system theme preference
- **Persistence**: User's choice saved and restored on app restart
- **Smooth Transitions**: Animated theme switching (no flicker)
- **Accessibility**: High contrast ratios maintained in both modes

---

## 🏗️ Project Structure

```
mobile_app/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── data/                      # Data layer
│   │   └── README.md
│   ├── l10n/                      # Localization
│   │   ├── README.md
│   │   ├── app_en.arb            # English translations
│   │   ├── app_km.arb            # Khmer translations
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   └── app_localizations_km.dart
│   ├── models/                    # Data models
│   │   ├── README.md
│   │   ├── enums_model/
│   │   └── users_models/
│   ├── services/                  # Business logic services
│   │   └── README.md
│   ├── ui/                        # User interface
│   │   ├── README.md
│   │   ├── screens/              # App screens
│   │   │   ├── patient_ui/
│   │   │   ├── doctor_ui/
│   │   │   └── tabs/
│   │   ├── theme/                # Theme configuration
│   │   │   ├── README.md
│   │   │   ├── main_theme.dart
│   │   │   ├── light_mode.dart
│   │   │   └── dark_mode.dart
│   │   └── widgets/              # Reusable widgets
│   └── utils/                     # Utility functions
│       └── README.md
├── pubspec.yaml                   # Dependencies
└── README.md                      # This file
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.7 or higher
- Dart SDK 3.10.7 or higher
- Android Studio / VS Code with Flutter extensions
- iOS development: Xcode (macOS only)

### Installation

1. **Clone the repository**
   ```bash
   cd /home/rayu/das-tern/mobile_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate localization files**
   ```bash
   flutter gen-l10n
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Development Commands

```bash
# Run on specific device
flutter run -d <device_id>

# Build for production
flutter build apk --release          # Android
flutter build ios --release          # iOS

# Generate localization files
flutter gen-l10n

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

---

## 📦 Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # State Management
  # provider: ^6.0.0  # or riverpod/bloc
  
  # Localization (built-in)
  flutter_localizations:
    sdk: flutter
  intl: any
  
  # Local Storage
  # shared_preferences: ^2.2.0
  # flutter_secure_storage: ^9.0.0
  # sqflite: ^2.3.0
  
  # Networking
  # dio: ^5.3.0
  
  # Notifications
  # flutter_local_notifications: ^16.0.0
  # firebase_messaging: ^14.7.0
```

---

## 🧪 Testing

### Localization Testing

```dart
testWidgets('Language switches correctly', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Verify English
  expect(find.text('Create a new account'), findsOneWidget);
  
  // Switch to Khmer
  // ... trigger language change
  await tester.pumpAndSettle();
  
  // Verify Khmer
  expect(find.text('បង្កើតគណនីថ្មី'), findsOneWidget);
});
```

### Theme Testing

```dart
testWidgets('Theme switches correctly', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Verify light theme
  final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
  expect(lightScaffold.backgroundColor, Colors.white);
  
  // Switch to dark theme
  // ... trigger theme change
  await tester.pumpAndSettle();
  
  // Verify dark theme
  final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
  expect(darkScaffold.backgroundColor, Color(0xFF121212));
});
```

---

## 📝 Contributing

### Adding New Translations

1. Add key-value pairs to both `app_en.arb` and `app_km.arb`
2. Run `flutter gen-l10n` to regenerate localization classes
3. Use the new keys in your widgets via `AppLocalizations.of(context)`

### Modifying Themes

1. Update color definitions in `light_mode.dart` or `dark_mode.dart`
2. Ensure color contrast ratios meet accessibility standards (WCAG AA)
3. Test both themes thoroughly across all screens

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` before committing
- Run `flutter analyze` to catch potential issues
- Write widget tests for new features

---

## 🔒 Security

- **Encrypted Storage**: Sensitive data stored using `flutter_secure_storage`
- **Local Database**: SQLite with encryption for offline data
- **No Hardcoded Secrets**: API keys managed via environment variables
- **HTTPS Only**: All network requests use secure connections

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

## 📞 Support

For questions or issues:
- 📧 Email: support@dastern.com
- 🌐 Website: https://dastern.com
- 📱 Documentation: [/docs](../docs)

---

<div align="center">

**Built with Flutter 💙 for better medication adherence**

[⬆ Back to Top](#-das-tern-mobile-app)

</div>
