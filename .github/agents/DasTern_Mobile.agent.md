---
description: "Flutter + NestJS fullstack agent. Plan → Implement → Analyze → Fix → Verify. Follows Flutter MVVM architecture (docs.flutter.dev/app-architecture/case-study) with scalable folder structure, clean data/domain/UI layers, and best performance practices."
tools: [vscode/getProjectSetupInfo, vscode/installExtension, vscode/memory, vscode/newWorkspace, vscode/runCommand, vscode/vscodeAPI, vscode/extensions, vscode/askQuestions, execute/runNotebookCell, execute/testFailure, execute/getTerminalOutput, execute/awaitTerminal, execute/killTerminal, execute/runTask, execute/createAndRunTask, execute/runInTerminal, execute/runTests, read/getNotebookSummary, read/problems, read/readFile, read/readNotebookCellOutput, read/terminalSelection, read/terminalLastCommand, read/getTaskOutput, agent/runSubagent, edit/createDirectory, edit/createFile, edit/createJupyterNotebook, edit/editFiles, edit/editNotebook, edit/rename, search/changes, search/codebase, search/fileSearch, search/listDirectory, search/searchResults, search/textSearch, search/usages, web/fetch, web/githubRepo, browser/openBrowserPage, browser/readPage, browser/screenshotPage, browser/navigatePage, browser/clickElement, browser/dragElement, browser/hoverElement, browser/typeInPage, browser/runPlaywrightCode, browser/handleDialog, figma/add_code_connect_map, figma/create_design_system_rules, figma/generate_diagram, figma/get_code_connect_map, figma/get_code_connect_suggestions, figma/get_design_context, figma/get_figjam, figma/get_metadata, figma/get_screenshot, figma/get_variable_defs, figma/send_code_connect_mappings, figma/whoami, dart-sdk-mcp-server/connect_dart_tooling_daemon, dart-sdk-mcp-server/create_project, dart-sdk-mcp-server/flutter_driver, dart-sdk-mcp-server/get_active_location, dart-sdk-mcp-server/get_app_logs, dart-sdk-mcp-server/get_runtime_errors, dart-sdk-mcp-server/get_selected_widget, dart-sdk-mcp-server/get_widget_tree, dart-sdk-mcp-server/hot_reload, dart-sdk-mcp-server/hot_restart, dart-sdk-mcp-server/hover, dart-sdk-mcp-server/launch_app, dart-sdk-mcp-server/list_devices, dart-sdk-mcp-server/list_running_apps, dart-sdk-mcp-server/pub, dart-sdk-mcp-server/pub_dev_search, dart-sdk-mcp-server/resolve_workspace_symbol, dart-sdk-mcp-server/set_widget_selection_mode, dart-sdk-mcp-server/signature_help, dart-sdk-mcp-server/stop_app, ms-azuretools.vscode-containers/containerToolsConfig, todo]
---

## Workflow

1. **Plan** — Outline the approach, identify affected layers, list files to create/modify.
2. **Implement** — Write code following the architecture rules below.
3. **Format** — Run `dart format .` inside `das_tern_mobile/`.
4. **Analyze** — Run `flutter analyze` inside `das_tern_mobile/`. Fix all errors, then re-run until clean.
5. **Verify** — Run the app or relevant tests to confirm correct behavior.

---

## Project Structure (this project is focus only android/ios mobile app not web or desktop)

| Service | Path | Stack |
|---|---|---|
| Main mobile | `das_tern_mobile/` | Flutter (MVVM) |
| Main backend | `backend_nestjs/` | NestJS |
| OCR service | `ocr/` | Python |

> All other mobile/backend directories are **test projects only** — do not modify them as production code.

**Always `cd` into the target directory before running any command.**
```bash
# Examples
cd /home/rayu/das-tern/das_tern_mobile && flutter analyze
cd /home/rayu/das-tern/backend_nestjs && npm run start:dev
cd /home/rayu/das-tern/ocr && python main.py
```

---

## Flutter Architecture (MVVM — Official Pattern)

Follow the [Flutter app architecture case study](https://docs.flutter.dev/app-architecture/case-study) strictly.

### Folder Structure
```
lib/
|__ l10n/                      # Localization ARB files + generated delegates
├── ui/
│   ├── core/
│   │   ├── ui/               # Shared widgets (buttons, cards, loaders)
│   │   └── themes/           # App theme, colors, typography
│   └── <feature_name>/
│       ├── view_models/
│       │   └── <feature>_viewmodel.dart
│       └── widgets/
│           ├── <feature>_screen.dart
│           └── <other_widgets>.dart
├── models/               # Pure Dart data models (no Flutter deps)
│       └── <model_name>.dart
├── data/
│   ├── repositories/         # Abstraction over data sources
│   │   └── <name>_repository.dart
│   ├── services/             # HTTP clients, local storage, device APIs
│   │   └── <name>_service.dart
│   └── model/                # API/DTO models (JSON serialization)
│       └── <name>_api_model.dart
├── config/                   # Environment configs, constants
├── utils/                    # Pure helper functions
├── services/                  # GoRouter or Navigator route definitions
├── main.dart                 # Production entry point
├── main_development.dart     # Development entry point
└── main_staging.dart         # Staging entry point

test/                         # Mirrors lib/ structure
testing/                      # Shared fakes/mocks used across tests
```

---

## Architecture Rules

### UI Layer (View + ViewModel)
- **View** (Screen/Widget): Only renders UI. Reads state from ViewModel. Calls ViewModel methods on user interaction. No business logic.
- **ViewModel**: Extends `ChangeNotifier`. Holds UI state. Calls repositories/services. Uses the **Command pattern** for async operations to safely track loading/error/success states.
- One ViewModel per screen/feature. Never share a ViewModel across unrelated screens.
```dart
// ✅ Command pattern for async operations
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository {
    load = Command0(_load)..execute();
    deleteBooking = Command1(_deleteBooking);
  }

  final BookingRepository _bookingRepository;
  List<BookingSummary> _bookings = [];
  List<BookingSummary> get bookings => _bookings;

  late final Command0 load;
  late final Command1<void, String> deleteBooking;

  Future<Result<void>> _load() async {
    final result = await _bookingRepository.getBookingList();
    if (result is Ok<List<BookingSummary>>) {
      _bookings = result.value;
    }
    notifyListeners();
    return result;
  }
}
```

### Data Layer (Repository + Service)
- **Repository**: Single source of truth for a domain entity. Combines/caches data from one or more services. Returns domain models.
- **Service**: Talks to one external source (REST API, local DB, device sensor). Returns raw/DTO models.
- Repositories and services are **interface-first** — define an abstract class, then implement it. This enables easy mocking in tests.
```dart
// ✅ Interface-first repository
abstract class BookingRepository {
  Future<Result<List<BookingSummary>>> getBookingList();
  Future<Result<void>> deleteBooking(String id);
}

class BookingRepositoryImpl implements BookingRepository { ... }
```

### Domain Layer
- Plain Dart classes only. No Flutter imports. No JSON logic.
- These are the canonical data types shared across UI and Data layers.

### Dependency Injection
- Use `package:provider` (or `get_it` for larger scale) to inject repositories into ViewModels.
- Wire everything at the app entry point (`main.dart`), not inside widgets.
```dart
// ✅ Provider setup at root
MultiProvider(
  providers: [
    Provider(create: (_) => BookingRepositoryImpl(apiService: ...)),
    ChangeNotifierProvider(
      create: (ctx) => HomeViewModel(
        bookingRepository: ctx.read<BookingRepositoryImpl>(),
      ),
    ),
  ],
  child: const MyApp(),
)
```

---

## Performance Best Practices

- Use `const` constructors everywhere possible.
- Prefer `ListView.builder` / `GridView.builder` over `.children` for lists.
- Avoid rebuilding entire trees — scope `ChangeNotifierProvider` to the subtree that needs it.
- Use `select<T>()` on Provider to subscribe to only the specific fields a widget needs.
- Offload heavy computation (JSON parsing, image processing) to an `Isolate` or `compute()`.
- Cache network images with `cached_network_image`.
- Use `RepaintBoundary` to isolate expensive widgets from frequent repaints.

---

## API Communication (NestJS Backend)

- All HTTP calls live in a **Service** class under `data/services/`.
- Use `Result<T>` (sealed class pattern) to represent `Ok<T>` / `Error` — never throw exceptions across layers.
- Handle all API error codes explicitly; surface user-friendly messages through the ViewModel.
- Use environment-specific base URLs via `main_development.dart` / `main_staging.dart` / `main.dart`.

---

## Testing Strategy

| Layer | Test type | What to test |
|---|---|---|
| Service | Unit | HTTP responses, serialization |
| Repository | Unit | Business logic, data merging, caching |
| ViewModel | Unit | State transitions, Command outcomes |
| Screen | Widget | Rendering given ViewModel state |
| Critical flows | Integration | End-to-end user journeys |

Use the `testing/fakes/` directory for shared fake implementations of repository interfaces.

---

## Code Quality Gates (run in order before done)
```bash
cd /home/rayu/das-tern/das_tern_mobile
dart format .
flutter analyze          # Must return: No issues found!
flutter test             # All tests must pass
```