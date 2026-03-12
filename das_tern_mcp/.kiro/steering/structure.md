# Project Structure - Clean Architecture (MVVM)

## Target Architecture Overview

Following Flutter's official architecture guidelines with MVVM + Clean Architecture pattern:

```
┌─────────────────────────────────────────┐
│            Presentation Layer           │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │    Views    │  │  View Models    │   │
│  │ (Widgets)   │  │ (Business Logic)│   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────┐
│            Domain Layer (Optional)      │
│  ┌─────────────────────────────────────┐ │
│  │         Use Cases/Interactors       │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────┐
│               Data Layer                │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │Repositories │  │    Services     │   │
│  │(SSOT/Cache) │  │  (API/Local)    │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
```

## New Directory Structure

```
lib/
├── main.dart                    # App entry point with DI setup
├── core/                        # Core infrastructure
│   ├── di/
│   │   └── service_locator.dart # Dependency injection (GetIt)
│   ├── errors/
│   │   ├── exceptions.dart      # Custom exceptions
│   │   └── failures.dart        # Failure handling
│   ├── network/
│   │   └── api_client.dart      # HTTP client wrapper
│   └── utils/
│       ├── constants.dart       # App constants
│       └── extensions.dart      # Dart extensions
├── data/                        # Data Layer
│   ├── datasources/
│   │   ├── local/
│   │   │   └── database_service.dart  # SQLite operations
│   │   └── remote/
│   │       ├── auth_api.dart          # Auth API endpoints
│   │       ├── prescription_api.dart  # Prescription API endpoints
│   │       ├── dose_api.dart          # Dose API endpoints
│   │       └── health_api.dart        # Health vitals API endpoints
│   ├── models/                  # Data transfer objects (DTOs)
│   │   ├── auth_model.dart
│   │   ├── prescription_model.dart
│   │   ├── dose_model.dart
│   │   └── health_model.dart
│   ├── repositories/            # Repository implementations
│   │   ├── auth_repository_impl.dart
│   │   ├── prescription_repository_impl.dart
│   │   ├── dose_repository_impl.dart
│   │   └── health_repository_impl.dart
│   └── services/                # Stateless data services
│       ├── auth_service.dart
│       ├── prescription_service.dart
│       ├── notification_service.dart
│       └── sync_service.dart
├── domain/                      # Domain Layer (Business Logic)
│   ├── entities/                # Business entities
│   │   ├── user.dart
│   │   ├── prescription.dart
│   │   ├── dose_event.dart
│   │   └── health_vital.dart
│   ├── repositories/            # Repository interfaces
│   │   ├── auth_repository.dart
│   │   ├── prescription_repository.dart
│   │   ├── dose_repository.dart
│   │   └── health_repository.dart
│   └── usecases/                # Use cases for complex logic
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   └── logout_usecase.dart
│       ├── prescription/
│       │   └── sync_prescriptions_usecase.dart
│       └── health/
│           └── sync_vitals_usecase.dart
├── presentation/                # Presentation Layer (UI)
│   ├── viewmodels/              # View Models (MVVM)
│   │   ├── auth_view_model.dart
│   │   ├── prescription_view_model.dart
│   │   ├── dose_view_model.dart
│   │   ├── health_view_model.dart
│   │   └── theme_view_model.dart
│   ├── views/                   # Views (Screens)
│   │   ├── auth/
│   │   │   ├── login_view.dart
│   │   │   ├── register_view.dart
│   │   │   └── otp_view.dart
│   │   ├── patient/
│   │   │   ├── dashboard_view.dart
│   │   │   ├── medications_view.dart
│   │   │   └── vitals_view.dart
│   │   ├── doctor/
│   │   │   ├── dashboard_view.dart
│   │   │   └── patients_view.dart
│   │   └── family/
│   │       └── caregiver_view.dart
│   └── widgets/                 # Reusable UI components
│       ├── common/
│       │   ├── loading_widget.dart
│       │   ├── error_widget.dart
│       │   └── empty_state_widget.dart
│       ├── auth/
│       │   └── login_form.dart
│       └── theme/
│           ├── app_colors.dart
│           ├── app_spacing.dart
│           └── app_typography.dart
├── l10n/                        # Localization
│   ├── app_en.arb
│   ├── app_km.arb
│   └── app_localizations.dart
└── utils/                       # Utilities
    ├── app_router.dart          # Navigation routing
    └── api_constants.dart       # API configuration
```

## Layer Responsibilities

### 1. Presentation Layer (`lib/presentation/`)

**Views (Widgets)**
- Stateless UI components that display data
- Handle user interactions through callbacks
- No business logic - only UI logic (animations, layout, routing)
- Consume ViewModels via Provider/Consumer

**ViewModels**
- Extend ChangeNotifier for state management
- Contain UI state and business logic
- Expose commands for user actions
- Communicate with repositories/use cases
- Transform data for UI consumption

### 2. Domain Layer (`lib/domain/`)

**Entities**
- Pure business objects with no dependencies
- Represent core business concepts
- Immutable data classes

**Repository Interfaces**
- Abstract contracts for data access
- Define what data operations are available
- No implementation details

**Use Cases (Optional)**
- Encapsulate complex business logic
- Coordinate between multiple repositories
- Reusable across different ViewModels
- Single responsibility per use case

### 3. Data Layer (`lib/data/`)

**Repository Implementations**
- Implement domain repository interfaces
- Single source of truth for each data type
- Handle caching, error handling, retry logic
- Coordinate between local and remote data sources

**Services**
- Stateless classes for specific operations
- Wrap external APIs and local storage
- No business logic - only data access logic

**Models (DTOs)**
- Data transfer objects for API/database
- Handle JSON serialization/deserialization
- Map to domain entities

## Naming Conventions

- **Files**: snake_case (e.g., `dose_event_model.dart`)
- **Classes**: PascalCase (e.g., `DoseEventModel`)
- **Variables/functions**: camelCase (e.g., `markDoseTaken`)
- **Constants**: camelCase for regular, SCREAMING_SNAKE_CASE for compile-time constants
- **Private members**: prefix with underscore (e.g., `_internalState`)

## Code Organization Rules

1. **No hardcoded strings** - All text through `AppLocalizations`
2. **No hardcoded colors/spacing** - Use `AppColors`, `AppSpacing`, `AppTypography` tokens
3. **Common widgets** in `lib/ui/widgets/common_widgets.dart`
4. **Feature-specific widgets** co-located with their screens
5. **Base widgets** with maximum configurability via constructor parameters
6. **Specialized widgets** compose or extend base widgets

## Offline Architecture

- **Connectivity detection**: `connectivity_plus` stream in SyncService
- **Local cache**: SQLite tables (dose_events, prescriptions, medications, vital_signs, notifications)
- **Sync queue**: Mutations stored in `sync_queue` table, replayed on reconnection
- **Providers**: Always attempt API first, fall through to SQLite cache on failure

## Localization Structure

- `lib/l10n/app_en.arb` - ~870 English string keys
- `lib/l10n/app_km.arb` - Full Khmer translation
- Generated delegates: `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_km.dart`
- Access via: `AppLocalizations.of(context)!.someKey`
## Architectural Patterns

### MVVM (Model-View-ViewModel)

**View** → **ViewModel** → **Repository** → **Service**

- **Views**: Stateless widgets that display UI
- **ViewModels**: Business logic and UI state management
- **Models**: Data representation (Entities + DTOs)

### Repository Pattern

```dart
// Abstract interface in domain layer
abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<AuthResult> login(String email, String password);
  Stream<User?> get userStream;
}

// Implementation in data layer
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final DatabaseService _databaseService;
  
  // Implementation with caching, error handling, offline support
}
```

### Command Pattern

ViewModels expose commands for user actions:

```dart
class AuthViewModel extends ChangeNotifier {
  // Commands (User Actions)
  Future<void> loginCommand(String email, String password) async {
    _setLoading(true);
    try {
      await _authRepository.login(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
```

## Dependency Injection

Using GetIt service locator pattern:

```dart
// lib/core/di/service_locator.dart
final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Services
  sl.registerLazySingleton<AuthService>(() => AuthService(sl()));
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  
  // ViewModels
  sl.registerFactory<AuthViewModel>(() => AuthViewModel(sl()));
}
```

## Data Flow

### Unidirectional Data Flow

1. **User Interaction** → View calls ViewModel command
2. **ViewModel** → Calls Repository method
3. **Repository** → Calls Service for data
4. **Service** → Makes API call or database query
5. **Data Returns** → Service → Repository → ViewModel
6. **State Update** → ViewModel notifies listeners
7. **UI Rebuild** → View rebuilds with new state

### Offline-First Architecture

- **Repository** acts as single source of truth
- **Local cache** via SQLite for offline access
- **Sync queue** for pending operations
- **Automatic sync** when connectivity returns

## Naming Conventions

### Files and Directories
- **snake_case** for files: `auth_view_model.dart`
- **snake_case** for directories: `presentation/viewmodels/`

### Classes and Methods
- **PascalCase** for classes: `AuthViewModel`
- **camelCase** for methods: `loginCommand()`
- **camelCase** for variables: `isLoading`
- **SCREAMING_SNAKE_CASE** for constants: `API_BASE_URL`

### Architecture-Specific Naming
- **Views**: `LoginView`, `DashboardView`
- **ViewModels**: `AuthViewModel`, `PrescriptionViewModel`
- **Repositories**: `AuthRepository`, `AuthRepositoryImpl`
- **Services**: `AuthService`, `NotificationService`
- **Use Cases**: `LoginUseCase`, `SyncDataUseCase`
- **Entities**: `User`, `Prescription`
- **Models/DTOs**: `UserModel`, `PrescriptionModel`

## Code Organization Rules

### 1. Separation of Concerns
- **Views**: Only UI logic (animations, layout, simple conditionals)
- **ViewModels**: Business logic, state management, data transformation
- **Repositories**: Data access coordination, caching, error handling
- **Services**: Raw data operations (API calls, database queries)

### 2. Dependency Rules
- **Presentation** depends on **Domain**
- **Data** depends on **Domain**
- **Domain** depends on nothing (pure business logic)
- Dependencies point inward (toward domain)

### 3. State Management Rules
- **Immutable state** in ViewModels
- **Single source of truth** via repositories
- **Reactive updates** via streams and ChangeNotifier
- **No direct widget state** for business data

### 4. Testing Strategy
- **Unit tests** for ViewModels, Repositories, Use Cases
- **Widget tests** for Views
- **Integration tests** for complete user flows
- **Mock dependencies** using abstract interfaces

## Migration Strategy

### Phase 1: Data Layer (Weeks 1-2)
1. Create repository interfaces in `domain/repositories/`
2. Implement repositories in `data/repositories/`
3. Refactor services to be stateless
4. Set up dependency injection

### Phase 2: Presentation Layer (Weeks 3-4)
1. Create ViewModels in `presentation/viewmodels/`
2. Extract logic from current providers
3. Refactor screens to be Views
4. Implement command pattern

### Phase 3: Domain Layer (Weeks 5-6)
1. Create entities in `domain/entities/`
2. Add use cases for complex logic
3. Implement cross-cutting concerns

### Phase 4: Testing & Polish (Weeks 7-8)
1. Write comprehensive tests
2. Performance optimization
3. Code cleanup and documentation

## Key Benefits

1. **Testability** - Each layer can be tested independently
2. **Scalability** - Easy to add features without breaking existing code
3. **Maintainability** - Clear separation makes code easier to understand
4. **Team Collaboration** - Standardized structure for team development
5. **Performance** - Optimized state management and data flow
6. **Offline Support** - Robust caching and sync mechanisms

## Localization Structure

- `lib/l10n/app_en.arb` - ~870 English string keys
- `lib/l10n/app_km.arb` - Full Khmer translation
- Generated delegates: `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_km.dart`
- Access via: `AppLocalizations.of(context)!.someKey`