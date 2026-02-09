# Providers Directory

## Purpose
This directory contains all state management providers using the Provider package.

## Providers

### LocaleProvider
- Manages app language (English/Khmer)
- Persists language preference
- Methods: `changeLocale()`, `loadLocalePreference()`

### MedicationProvider
- Manages medication CRUD operations
- Integrates with database and sync services
- Methods: `loadMedications()`, `createMedication()`, `updateMedicationStatus()`

### DoseEventProvider
- Manages dose event tracking
- Handles mark-as-taken functionality
- Methods: `loadTodayDoseEvents()`, `markAsTaken()`, `getDoseEventsByTimeGroup()`

## Usage

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider(create: (_) => MedicationProvider()),
    ChangeNotifierProvider(create: (_) => DoseEventProvider()),
  ],
  child: MyApp(),
)

// In widgets
final provider = context.watch<MedicationProvider>();
final provider = context.read<MedicationProvider>();
```

## Rules
- All providers extend `ChangeNotifier`
- Call `notifyListeners()` after state changes
- Use `context.watch` for UI updates
- Use `context.read` for one-time actions
