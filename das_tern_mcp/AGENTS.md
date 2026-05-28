# AGENTS.md — Das Tern Development Guide

**Last Updated:** 2026-03-26  
**Project:** Das Tern (ដាស ទឺន) — Medication Management Platform for Cambodia  
**Stack:** Flutter 3.10.7+ (MVVM Architecture) | NestJS Backend | Python OCR Service

This guide is for AI coding agents operating in the das_tern_mcp repository.

---

## 🚀 Quick Commands

### Essential Commands (Always run from project root)
```bash
# Navigate to mobile app directory
cd /home/rayu/das-tern/das_tern_mcp

# Format code (must run before commits)
dart format .

# Analyze code (must be clean before commits)
flutter analyze

# Run all tests
flutter test

# Run specific test file
flutter test test/ui/auth/login_screen_test.dart

# Run specific test by name
flutter test --name "should login successfully"

# Run app in debug mode
flutter run

# Build release AAB for Google Play
./build_release.sh
```

### Code Quality Gates (run in order before marking work complete)
```bash
cd /home/rayu/das-tern/das_tern_mcp
dart format .              # Auto-format all Dart files
flutter analyze            # Must show: "No issues found!"
flutter test               # All tests must pass
```

---

## 📁 Project Structure

This is a **Flutter-only mobile app** (Android/iOS). Focus on `das_tern_mcp/` only.

```
/home/rayu/das-tern/
├── das_tern_mcp/          ← MAIN FLUTTER APP (work here)
├── backend_nestjs/        ← NestJS backend (reference only)
├── ocr/                   ← Python OCR service (reference only)
└── das_tern_mobile/       ← Test project (DO NOT MODIFY)

das_tern_mcp/lib/
├── main.dart              # App entry point with MultiProvider setup
├── l10n/                  # Localization (EN/KM - 870+ strings)
│   ├── app_en.arb         # English translations
│   └── app_km.arb         # Khmer translations
├── models/                # Pure Dart data models (16 subdirectories)
│   ├── user_model/
│   ├── medication_model/
│   ├── prescription_model/
│   └── ...
├── providers/             # State management (ChangeNotifier)
│   ├── auth_provider.dart
│   ├── dose_provider.dart
│   ├── prescription_provider.dart
│   └── ...                (13 total providers)
├── services/              # Infrastructure layer
│   ├── api_service.dart          # HTTP client (1479 lines)
│   ├── database_service.dart     # SQLite offline storage
│   ├── notification_service.dart # Local dose reminders
│   ├── sync_service.dart         # Offline sync queue
│   └── ...
├── ui/
│   ├── screens/           # Screen widgets (grouped by feature)
│   │   ├── auth/          # 7 auth screens (login, register, reset, etc.)
│   │   ├── patient/       # 22 patient screens
│   │   ├── doctor/        # 10 doctor screens
│   │   └── family_ui/     # 10 caregiver screens
│   ├── theme/             # App colors, typography, spacing
│   └── widgets/           # Shared reusable widgets
└── utils/
    ├── api_constants.dart # Backend endpoint constants
    └── app_router.dart    # 85+ named routes
```

**Architecture:** MVVM with Provider state management (see `.kiro/steering/flutter-clean-architecture-guide.md` for target architecture).

---

## 🏗️ Flutter Architecture (MVVM — Official Pattern)

Follow [Flutter app architecture case study](https://docs.flutter.dev/app-architecture/case-study) strictly.

### Core Principles

#### 1. **Separation of Concerns**
- **View (Screen/Widget):** Only renders UI. Reads state from Provider. Calls Provider methods on user interaction. Zero business logic.
- **ViewModel (Provider):** Extends `ChangeNotifier`. Holds UI state. Calls services. Notifies listeners on state changes.
- **Service:** Talks to external sources (API, database, device sensors). Returns raw/DTO data.

#### 2. **Provider-Based State Management**
- All providers are registered in `MultiProvider` at app entry point (`main.dart`).
- Views consume providers via `Provider.of<T>(context)`, `context.watch<T>()`, or `context.read<T>()`.
- Use `context.read<T>()` in callbacks to avoid unnecessary rebuilds.
- Use `context.watch<T>()` or `Consumer<T>` when widget needs to rebuild on state changes.

#### 3. **Dependency Injection**
- Inject services into providers via constructor parameters.
- Wire all dependencies in `main.dart`, never inside widgets.

Example:
```dart
// ✅ GOOD: Inject dependencies at app root
MultiProvider(
  providers: [
    Provider(create: (_) => ApiService()),
    ChangeNotifierProvider(
      create: (ctx) => AuthProvider(
        apiService: ctx.read<ApiService>(),
        databaseService: ctx.read<DatabaseService>(),
      ),
    ),
  ],
  child: const MyApp(),
)

// ❌ BAD: Creating dependencies inside widgets
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider(
      apiService: ApiService(), // ❌ Don't do this
    );
  }
}
```

---

## 🎨 Code Style Guidelines

### Imports
```dart
// Order: dart → flutter → package → relative
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import '../services/api_service.dart';
```

### Formatting
- **Always run `dart format .` before committing.**
- Line length: 80 characters (enforced by formatter).
- Use trailing commas for multi-line function calls/constructors to enable better formatting.

### Types
- Always use explicit types for public APIs (methods, properties).
- Use `var` for local variables when type is obvious from initializer.
- Use `final` for variables that won't be reassigned.
- Use `const` for compile-time constants.

```dart
// ✅ GOOD
final String userName = 'John';
const int maxRetries = 3;
var items = <String>[];  // Type obvious from initializer

// ❌ BAD
String userName = 'John';  // Should be final
int maxRetries = 3;        // Should be const
var userName = 'John';     // Not obvious it's a String
```

### Naming Conventions
- **Classes:** `PascalCase` (e.g., `AuthProvider`, `MedicationModel`)
- **Files:** `snake_case` (e.g., `auth_provider.dart`, `medication_model.dart`)
- **Variables/Functions:** `camelCase` (e.g., `userName`, `fetchMedications()`)
- **Constants:** `lowerCamelCase` (e.g., `maxRetries`, `apiTimeout`)
- **Private members:** Prefix with `_` (e.g., `_userId`, `_loadData()`)

### Error Handling
- Never throw exceptions across service boundaries.
- Return error states via provider properties or callback parameters.
- Display user-friendly error messages (localized via `AppLocalizations`).

```dart
// ✅ GOOD: Handle errors in provider
class AuthProvider extends ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> login(String email, String password) async {
    try {
      _errorMessage = null;
      notifyListeners();
      
      final response = await _apiService.login(email, password);
      // Handle success
    } catch (e) {
      _errorMessage = 'Failed to login. Please try again.';
      notifyListeners();
    }
  }
}

// ❌ BAD: Throwing exceptions from providers
Future<void> login(String email, String password) async {
  final response = await _apiService.login(email, password);
  if (response.statusCode != 200) {
    throw Exception('Login failed'); // ❌ Don't throw
  }
}
```

### Async/Await
- Always use `async`/`await` for asynchronous operations.
- Never use `.then()` chains (prefer async/await for readability).
- Always handle errors with try-catch in async methods.

---

## 🧪 Testing Strategy

| Layer | Test Type | What to Test | Example |
|---|---|---|---|
| **Service** | Unit | HTTP responses, JSON serialization, error handling | `test/services/database_service_test.dart` |
| **Provider** | Unit | State transitions, error states, notifyListeners calls | `test/providers/auth_provider_test.dart` |
| **Screen** | Widget | Rendering given provider state, user interactions | `test/ui/auth/login_screen_test.dart` |
| **Critical flows** | Integration | End-to-end user journeys (login → dose tracking) | `test/qa/comprehensive_qa_test.dart` |

### Running Tests
```bash
# All tests
flutter test

# Specific file
flutter test test/ui/auth/login_screen_test.dart

# Specific test by name
flutter test --name "should show error on invalid credentials"

# With coverage
flutter test --coverage
```

---

## 🌍 Localization

- All user-facing strings MUST be localized.
- Use `AppLocalizations.of(context)!.keyName` to access translations.
- Add new strings to both `lib/l10n/app_en.arb` and `lib/l10n/app_km.arb`.

```dart
// ✅ GOOD
Text(AppLocalizations.of(context)!.loginButton)

// ❌ BAD
Text('Login') // Hardcoded string
```

---

## ⚡ Performance Best Practices

1. **Use `const` constructors** wherever possible to avoid unnecessary rebuilds.
2. **Prefer `.builder` constructors** for lists (ListView.builder, GridView.builder).
3. **Scope providers tightly** — only wrap the subtree that needs to rebuild.
4. **Use `Selector` or `Consumer`** to subscribe to specific fields instead of entire provider.
5. **Cache network images** with `cached_network_image` package.
6. **Offload heavy computation** to `Isolate` or `compute()` for JSON parsing/image processing.
7. **Use `RepaintBoundary`** to isolate expensive widgets from frequent repaints.

---

## 🔌 API Communication

- All HTTP calls live in `services/api_service.dart` (1479 lines).
- Base URL: Defined in `utils/api_constants.dart`.
- Authentication: JWT tokens stored in `flutter_secure_storage`.
- Error handling: Parse status codes explicitly and return user-friendly messages.

---

## 🐛 Common Pitfalls

### ❌ DON'T: Mutate state without notifying listeners
```dart
void updateName(String name) {
  _userName = name;
  // ❌ Missing notifyListeners()
}
```

### ✅ DO: Always call notifyListeners()
```dart
void updateName(String name) {
  _userName = name;
  notifyListeners(); // ✅
}
```

### ❌ DON'T: Use context.watch() in callbacks
```dart
onPressed: () {
  context.watch<AuthProvider>().login(); // ❌ Causes error
}
```

### ✅ DO: Use context.read() in callbacks
```dart
onPressed: () {
  context.read<AuthProvider>().login(); // ✅
}
```

### ❌ DON'T: Create providers inside build methods
```dart
Widget build(BuildContext context) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(), // ❌ Recreates on every build
    child: LoginScreen(),
  );
}
```

### ✅ DO: Provide at app root or use Consumer
```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()), // ✅
  ],
)
```

---

## 📦 Key Dependencies

- **State Management:** `provider ^6.1.1`
- **Networking:** `http ^1.1.2`
- **Storage:** `flutter_secure_storage ^9.2.4`, `sqflite ^2.3.0`
- **Notifications:** `flutter_local_notifications ^17.2.3`
- **Auth:** `google_sign_in ^6.1.0`
- **i18n:** `intl ^0.20.2`

---

## 📚 Additional Resources

- **Architecture Guide:** `.kiro/steering/flutter-clean-architecture-guide.md`
- **Project Structure:** `.kiro/steering/structure.md`
- **API Endpoints:** `API_ENDPOINTS.md`
- **Backend Setup:** `FLUTTER_BACKEND_SETUP.md`
- **Quick Start:** `QUICK_START.md`

---

**Remember:** Always format, analyze, and test before committing. Quality gates are non-negotiable.


<claude-mem-context>
# Memory Context

# claude-mem status

This project has no memory yet. The current session will seed it; subsequent sessions will receive auto-injected context for relevant past work.

Memory injection starts on your second session in a project.

`/learn-codebase` is available if the user wants to front-load the entire repo into memory in a single pass (~5 minutes on a typical repo, optional). Otherwise memory builds passively as work happens.

Live activity: http://localhost:37700
How it works: `/how-it-works`

This message disappears once the first observation lands.
</claude-mem-context>