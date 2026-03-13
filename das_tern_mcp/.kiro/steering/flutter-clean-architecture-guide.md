# Executive Summary

This report synthesizes Flutter’s official guidance on app architecture (from flutter.dev’s “App architecture” section) into a concise, actionable refactoring guide. It covers key principles (separation of concerns, layers, single source of truth, unidirectional data flow, and immutable state【6†L622-L630】【7†L727-L735】), and explains why Flutter strongly recommends an MVVM-style pattern (Views + ViewModels) combined with a layered design. We compare MVVM, layered, and other approaches (e.g. reactive stream/BLoC style) in terms of responsibilities, pros/cons, testability, and performance. We then give a step-by-step refactoring checklist and migration plan for a messy project (including file structure, state management, DI, navigation, etc.), along with coding conventions and short example snippets showing View/ViewModel/Model/Repository interaction. Finally, we cover testing strategies (unit, widget, integration mapped to layers【28†L805-L812】), performance best practices (using `const` widgets, minimizing work in `build()`, etc.【30†L658-L667】【30†L675-L679】), metrics/tools to gauge improvements (Flutter DevTools, flutter_lints【34†L837-L840】), common anti-patterns to remove (logic-in-widgets【34†L669-L677】, multiple sources of truth【6†L668-L676】, etc.), and a quick-reference checklist. 

## 1. Key Principles & Definitions

- **Separation of concerns (SoC):** Divide your app into distinct layers and components by responsibility. Separate UI logic from business/data logic【6†L622-L630】. In practice, keep widgets *“lean”* and reusable, moving logic to other classes【6†L631-L634】. For example, authentication logic belongs in its own class, not mixed into the UI code【6†L622-L630】.  
- **Layered architecture:** Build in layers. Commonly, Flutter apps have:  
  - **UI layer:** Presentation/widgets (Views and ViewModels). Handles user interaction and displays data.  
  - **Logic/Domain layer (optional):** Business logic or use-cases. Only needed if app logic is very complex.  
  - **Data layer:** Repositories and Services. Manages data sources (APIs, databases, plugins)【6†L639-L648】【26†L799-L808】. Each layer only talks to adjacent layers (UI ↔ Logic ↔ Data)【6†L660-L664】.  
  【35†embed_image】 *Figure: Flutter promotes a UI-Logic-Data layered design【6†L639-L648】.*  
- **Single Source of Truth (SSOT):** Each piece of data has one authoritative source (usually a Repository in the data layer)【7†L668-L676】. Any change to data should happen there. This avoids duplication or inconsistent copies of the same data【7†L668-L676】.  
- **Unidirectional Data Flow:** Data flows one-way: from Data layer → Logic layer → UI layer. User events flow the opposite direction (UI → Logic → Data)【7†L702-L710】. For example, a button press in a View calls a ViewModel method, which calls a Repository to update data, then the ViewModel pushes new state back to the View【7†L705-L714】. This clear flow reduces bugs and keeps UI views stateless reflections of the underlying state【7†L702-L710】【7†L723-L731】.  
- **“UI is a function of (immutable) state”:** Flutter’s UI is declarative and should rebuild to reflect current state【7†L727-L735】. Views should display state passed in from ViewModels; they should not manage mutable data themselves. Data models should be immutable, so changes always produce new instances (helping unidirectional flow)【7†L727-L735】.  
- **Extensibility:** Each component (ViewModel, Repository, etc.) should expose a clear interface (inputs/outputs). This allows swapping implementations (e.g. mock vs real) without changing callers【7†L743-L751】.  
- **Testability:** The same modular structure that makes code extensible also makes it testable. ViewModels and Repositories can be unit-tested in isolation by mocking dependencies【7†L752-L760】【28†L805-L812】. Keeping logic out of widgets means UI can be widget-tested separately from business logic【7†L752-L760】【28†L805-L812】.

## 2. Recommended Architectures (Comparison Table)

Flutter’s docs *strongly recommend* an **MVVM-style layered architecture** (View + ViewModel in UI layer, with Repositories/Services in data layer)【9†L650-L658】【16†L650-L658】. Below we compare common patterns:

| Pattern             | Responsibilities                                     | Pros                                              | Cons                                                        | Testability                             | Perf Impact                                  |
|---------------------|------------------------------------------------------|---------------------------------------------------|-------------------------------------------------------------|-----------------------------------------|----------------------------------------------|
| **MVVM (recommended)**<br>(Views + ViewModels) | **UI layer:** Views (widgets) display state, forward events; ViewModels manage UI state and logic, call Repositories. **Data layer:** Repositories (SSOT, caching, error handling) and Services (API calls)【26†L813-L822】【26†L847-L856】. | Clear SoC: UI is “dumb”, logic centralized in ViewModels【34†L669-L677】. Easier maintenance and testing: mock Repos in ViewModel tests【7†L752-L760】【28†L805-L812】. Native Flutter support (ChangeNotifier, Provider)【9†L650-L658】. | More boilerplate classes. Can be overkill for trivial screens. | High – ViewModels and Repos are POJO/Dart classes (unit-testable)【28†L805-L812】. Widget tests for Views. | Neutral – additional classes have minimal overhead; promotes efficient rebuilds (const widgets etc). |
| **Layered (UI/Domain/Data)** | **UI:** Views/ViewModels. **Domain (optional):** Use-cases/interactors. **Data:** Repos/Services. Layers are strict, each only sees adjacent layers【6†L639-L648】【26†L875-L884】. | Excellent separation; clean handling of complex logic in Domain. Easy to swap data sources. | Increased complexity: more files, classes. Risk of “over-architecting” small apps【26†L894-L902】. | High – Domain/use-cases and ViewModels can be tested independently. | Neutral – minor overhead for call indirection; domain layer adds abstraction. |
| **Clean (Domain-driven)**<br>(Use-case centric) | ViewModel ➔ UseCases ➔ Repos ➔ Services. Business rules live in use-cases【26†L875-L884】. | Scales in very large apps: centralizes business logic, avoids duplication【26†L894-L902】. Improves readability in ViewModels【26†L894-L902】. | Boilerplate: many classes, extra DI. More code to maintain. ViewModels often need mocks for use-cases【26†L894-L902】. | Very high – use-cases and ViewModels are small units, each testable. | Negligible – mostly design overhead, no runtime penalty. |
| **Reactive / BLoC / Streams**<br>(e.g. flutter_bloc) | State managed by streams or BLoC objects. View listens to stream, BLoC exposes sinks/events and streams of state. Repos supply data. | Familiar to many; can enforce unidirectional flow. Good for complex async interactions. | Complexity learning curve. Boilerplate code (stream controllers, events, states). Overkill for simple CRUD. | Moderate – BLoCs are testable, but mocking streams can be intricate. Widget tests still needed. | Neutral – streams have some cost, but generally efficient. |
| **(Untiered/Flat)** | No clear layers: logic mixed in widgets or global statics. | Quick to code for tiny apps. | Very **bad** for maintenance: logic in widgets, tight coupling, global state. Hard to test or scale. | Very low – nearly untestable. | Poor – Widgets rebuild unpredictably; state duplication causes bugs. |

Flutter’s docs explicitly **favor MVVM with a layered structure** (UI, domain (if needed), data)【9†L650-L658】【26†L875-L884】. Other approaches (like BLoC) can work, but the *principles* (SoC, SSOT, unidirectional flow) still apply【4†L737-L744】. A mermaid diagram of the recommended flow:  

```mermaid
flowchart TD
    subgraph UI Layer
        View[View (Widget)]
        ViewModel[ViewModel (state & logic)]
    end
    subgraph Data Layer
        Repository[Repository (source of truth)]
        Service[Service (API / platform)]
    end
    View --> ViewModel
    ViewModel --> Repository
    Repository --> Service
```

## 3. Refactoring Checklist & Migration Plan

To transform a messy project into a clean architecture, follow these steps (each step may require its own commits or branch):

1. **Clarify architecture boundaries.** Decide on layers (UI, optional Domain, Data). Commit to MVVM with Repositories.  
2. **Reorganize project structure.** Use a *feature-first* + *layer* hybrid. For example【4†L667-L674】【4†L683-L691】:  
   ```
   lib/
     ui/
       core/ (shared widgets, themes)
       <featureA>/
         view_models/  (e.g. feature_a_view_model.dart)
         widgets/ (views/screens, other widgets)
       <featureB>/ ...
     domain/ (app-wide models)
       models/ (data types)
     data/
       repositories/ (feature-specific repo classes)
       services/ (API or plugin wrappers)
       models/ (API DTOs)
     routing/ (go_router setup)
     config/ (env, flavor config)
     utils/ (common utilities)
     main.dart, main_dev.dart, main_prod.dart
   ```
   This isolates shared UI in `ui/core` (like app-wide buttons) and keeps each feature’s view/viewmodel together【4†L667-L674】. The `domain/models` folder holds plain Dart classes for app data【4†L717-L725】.

3. **Implement dependency injection.** Introduce a DI mechanism (Flutter recommends Provider)【34†L753-L761】. Set up top-level Providers in `main.dart` (or use a `MultiProvider`) that supply repositories and viewmodels to the widget tree. This replaces global singletons. *Example:*  
   ```dart
   void main() {
     runApp(
       MultiProvider(
         providers: [
           Provider<UserRepository>(create: (_) => UserRepositoryImpl()),
           ChangeNotifierProvider<LoginViewModel>(
             create: (ctx) => LoginViewModel(ctx.read<UserRepository>()),
           ),
           // ... other services/repos/viewmodels
         ],
         child: MyApp(),
       ),
     );
   }
   ```
   (This aligns with “Use dependency injection”【34†L753-L761】 and encourages testing with fakes【28†L812-L819】.)

4. **Extract logic into ViewModels.** Move any business logic or data transformation out of widgets. Convert stateful widgets to *Stateless*, and use `ChangeNotifier` ViewModel for state. For each screen:  
   - Create a `XxxViewModel extends ChangeNotifier`. It holds state variables and methods to load/update data (calling repos).  
   - Refactor the widget to be a pure View: in its `build()`, watch the ViewModel (via Provider or context) and display its state. Handle user events by invoking ViewModel methods (as “commands”【26†L784-L792】).  
   - *Example snippet:*  
     ```dart
     class ProfileViewModel extends ChangeNotifier {
       final UserRepository _userRepo;
       UserProfile? profile;
       ProfileViewModel(this._userRepo) { loadProfile(); }
       Future<void> loadProfile() async {
         profile = await _userRepo.fetchUserProfile();
         notifyListeners();
       }
     }
     
     class ProfileView extends StatelessWidget {
       @override
       Widget build(BuildContext context) {
         final vm = context.watch<ProfileViewModel>();
         final profile = vm.profile;
         return Scaffold(
           appBar: AppBar(title: Text('Profile')),
           body: profile == null
             ? CircularProgressIndicator()
             : Text('Hello, ${profile.name}'),
         );
       }
     }
     ```
     This follows *no logic in View* except UI layout【34†L669-L677】.

5. **Create Repositories and Services.** For each data type (e.g. User, Trip, etc.), make a repository class (single source of truth)【7†L668-L676】【26†L813-L822】. Each repository uses one or more services for actual data fetching (HTTP, local DB, plugins)【26†L847-L856】. *Example:*  
   ```dart
   class UserRepository {
     final UserService _api;
     UserProfile? _cache;
     UserRepository(this._api);
     Future<UserProfile> fetchUserProfile() async {
       if (_cache != null) return _cache!;
       final dto = await _api.fetchProfileFromServer();
       final profile = UserProfile.fromDto(dto);
       _cache = profile;
       return profile;
     }
   }
   ```
   Handle caching, error handling, retries here【26†L820-L828】. Keep Repos stateless or minimally stateful (cache only) and use Streams or ChangeNotifiers to push updates if needed. **One repo per data type** is recommended【7†L668-L676】.

6. **Define data models as immutable classes.** Use `freezed` or similar to generate immutable model classes【34†L716-L724】. This enforces unidirectional flow (to change data you create a new instance). *Example:*  
   ```dart
   @freezed
   class Todo with _$Todo {
     const factory Todo({required String id, required String title}) = _Todo;
   }
   ```
   Use one model class per business entity. Separate domain models from API DTOs (use separate files or classes) to avoid scattering JSON logic in UI【34†L736-L743】.

7. **Adopt unidirectional data flow.** Ensure UI views only read state from ViewModels, and only update state by invoking methods on them (never mutating a model directly in the UI)【7†L702-L710】【34†L716-L724】. For user events, consider using the *Command* pattern (methods in ViewModels triggered by buttons)【26†L784-L792】.

8. **Navigation and Routing:** Use `go_router` (recommended) for navigation logic【34†L761-L768】. Define named routes and pass necessary parameters via a router. Keep routing decisions out of UI widgets where possible. Simple conditional navigation (e.g. `if (someFlag) Navigator.push(...)`) can remain in Views if trivial【34†L669-L677】.

9. **Error handling & logging:** In repositories, catch and log errors from services. Let ViewModels expose error states (e.g. an `errorMessage` field). Use Flutter’s `ErrorWidget` or show dialogs/snackbars in Views. Add logging (print or `debugPrint`) around unexpected failures. (While not detailed on flutter.dev, robust error handling belongs in Repositories/Services).

10. **Testing setup:** Create separate test folders mirroring `lib/` (see next section). Add fakes or mocks for dependencies (services, repos) as needed【28†L812-L819】. Use `flutter_lints` to enforce conventions【34†L837-L840】.

11. **Iterate feature-by-feature:** Refactor one screen/feature at a time. Migrate its widget into View/ViewModel, extract its data calls into a Repository, introduce tests for each piece. Run app to ensure behavior remains correct.

12. **Review & refine:** Once all code follows MVVM/layered structure, remove any leftover global state or intertwined logic. Ensure core shared widgets (like buttons, inputs) live under `ui/core/` (avoid naming confusion【34†L770-L779】).

By the end, you should have a clean architecture with separate UI and data layers, testable ViewModels and Repos, and no business logic in Widgets. 

## 4. Coding Conventions & Examples

Follow these naming and code patterns (from flutter.dev recommendations【34†L770-L779】):

- **Class and file names:** Include the architectural role. For example:  
  - `HomeView` (or `HomeScreen`): a Widget class that displays the Home feature.  
  - `HomeViewModel`: the ChangeNotifier class containing Home’s logic and state.  
  - `UserRepository`: the data source class.  
  - `ClientApiService`: a class wrapping HTTP or platform code.  
  Place each class in a file with the same name (e.g. `home_view.dart`, `home_view_model.dart`, etc.)【34†L770-L779】.

- **Views (Widgets):** Should be mostly `StatelessWidget` or `ConsumerWidget`. They **do not contain business logic**【34†L669-L677】. Only widget-specific logic (simple `if` to show/hide, animations, layouts) is allowed【34†L669-L677】. Example View (using Provider):  
  ```dart
  class CounterView extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final vm = context.watch<CounterViewModel>();
      return Scaffold(
        appBar: AppBar(title: Text('Counter')),
        body: Center(child: Text('Count: ${vm.count}')),
        floatingActionButton: FloatingActionButton(
          onPressed: vm.increment, // calls ViewModel
          child: Icon(Icons.add),
        ),
      );
    }
  }
  ```
  This view simply reads `vm.count` and calls `vm.increment()` – no logic beyond UI.

- **ViewModels:** Extend `ChangeNotifier` or similar. They *contain all the logic* to process data, update state, and notify the UI. For example:  
  ```dart
  class CounterViewModel extends ChangeNotifier {
    int _count = 0;
    int get count => _count;

    void increment() {
      _count++;
      notifyListeners();
    }
  }
  ```
  ViewModels fetch or compute data (often by calling Repositories) and hold it in properties. They expose “commands” (callbacks) for the View to call (e.g. `increment()` above). They **should never import Flutter UI classes**; they live in pure Dart code.

- **Models/Domain:** Simple immutable data classes (like `UserProfile`, `Todo`, etc.). They can be generated via `freezed` or written manually as plain Dart classes【34†L716-L724】. Example with `freezed`:  
  ```dart
  @freezed
  class TodoItem with _$TodoItem {
    const factory TodoItem({
      required String id,
      required String title,
      bool? completed,
    }) = _TodoItem;
  }
  ```
  These classes are used by both Repositories and ViewModels.

- **Repositories:** Classes that implement data access and hold the source-of-truth. Example:  
  ```dart
  class TodoRepository {
    final TodoService _service;
    final Map<String, TodoItem> _cache = {};

    TodoRepository(this._service);

    Future<TodoItem> fetchTodo(String id) async {
      if (_cache.containsKey(id)) return _cache[id]!;
      final dto = await _service.getTodoFromApi(id);
      final todo = TodoItem.fromDto(dto);
      _cache[id] = todo;
      return todo;
    }
  }
  ```
  Here the repo caches results and transforms DTOs into domain models. It is a good place for retry logic and error handling【26†L820-L828】.

- **Services:** Low-level classes for API calls or platform integration. They return raw data (e.g. JSON or API models). Services **do not** do business logic. Example:  
  ```dart
  class TodoService {
    final http.Client httpClient;
    TodoService(this.httpClient);

    Future<TodoDto> getTodoFromApi(String id) async {
      final resp = await httpClient.get(Uri.parse('https://api/.../todos/$id'));
      return TodoDto.fromJson(jsonDecode(resp.body));
    }
  }
  ```
- **Commands:** Methods in ViewModels that Views bind to (e.g. button presses). Flutter docs liken them to the Command pattern【26†L784-L792】. Example:  
  ```dart
  class FormViewModel extends ChangeNotifier {
    final FormRepository _repo;
    String name = '';
    String email = '';

    void submit() async {
      final success = await _repo.submitForm(name, email);
      if (success) { /* update state */ }
      notifyListeners();
    }
  }
  ```
  The View might attach `onPressed: vm.submit`. Commands ensure Views don’t contain business logic themselves【26†L784-L792】.

## 5. Testing Strategy

Apply a **layered testing approach**【28†L799-L807】:

- **Unit tests for Data layer:** Test each *Service* and *Repository* class in isolation. Mock HTTP or platform calls in Services. For Repositories, use fakes/mocks of Services (the docs call for “fakes” and highlight testing inputs/outputs【28†L812-L819】). Verify caching, error handling, and data transformations.  
- **Unit tests for ViewModels:** Mock Repositories and test ViewModel methods/state. For example, fake a `UserRepository` to return canned data, then ensure `loadUser()` correctly updates the ViewModel’s state【28†L805-L812】. This ensures business logic in the UI layer works.  
- **Widget tests for Views:** For each screen/View, write widget tests that pump the widget tree (with Providers injecting faked ViewModels) and verify that the UI renders correctly. Test navigation and dependency injection. Flutter docs specifically recommend widget tests for views including routing/DI【28†L805-L812】. For example, test that tapping a button calls a ViewModel command and leads to a new screen.  
- **Integration tests for flows:** Use Flutter integration tests (or `integration_test` package) to test end-to-end scenarios with a real or emulator device. This can catch issues spanning multiple layers (e.g. full login flow with a test server or mock).  

As per Flutter guidance: **test components separately, and together**【28†L805-L812】. Encourage writing code to support fakes (e.g. using abstract classes or interfaces for Repos, Services). Use `flutter_lints` to enforce test-friendly code (small functions, clear I/O)【34†L837-L840】.

## 6. Performance Best Practices

Flutter is fast by default, but follow these tips (from Flutter’s performance guide) when refactoring:

- **Minimize work in `build()`:** Don’t do expensive calculations or loops in `build()`, since it can be called often【30†L658-L667】. Extract UI into smaller widgets so that only parts that need updating rebuild. For example, if only one portion of the screen changes, keep that in a child widget with its own State/ViewModel, so you can call `notifyListeners()` only for the affected subtree.  
- **Split large widgets:** Avoid huge widgets with giant `build()` methods. Break complex UIs into nested `StatelessWidget` or `const` widgets【30†L658-L667】. This localizes rebuilds and keeps code maintainable.  
- **Use `const` constructors:** Wherever possible, mark widgets and other objects with `const`. This lets Flutter short-circuit rebuild work if nothing changes【30†L675-L679】. Enable the recommended lints (`flutter_lints`) to catch missing `const`s【30†L675-L679】.  
- **Prefer StatelessWidgets for pure UI:** For UI pieces that depend only on input props (not internal state), make them `StatelessWidget`. The guide notes preferring widgets over bare helper functions improves performance【30†L678-L682】.  
- **Efficient lists/grids:** In lists (`ListView`/`GridView`), avoid layouts that trigger intrinsic sizing (e.g. don’t use `GridView` that needs two passes to size every cell)【32†L854-L863】【32†L889-L898】. Use fixed extents or builders (`ListView.builder`) to avoid O(n²) layouts. If needed, enable DevTools’ “Track Layouts” to diagnose costly layout passes【32†L879-L888】.  
- **Frame budgeting:** Aim to build & render each frame within 16ms (8ms build + 8ms render on a 60Hz display)【32†L902-L911】. Use the Flutter Performance DevTools profiler to identify jank. Flutter’s docs note that if you meet 60fps consistently, you’re on track【32†L910-L919】.  
- **Avoid common pitfalls:** The docs caution against things like `Opacity` in animations, unnecessary overrides of `operator ==` on widgets, and always putting hidden children in lists (which waste rebuild time)【32†L938-L947】【32†L953-L962】. During refactoring, remove or optimize such patterns (e.g. use `AnimatedOpacity` if needed, avoid overriding `==` on complex widgets).

In short, keep the UI code *simple, const, and widgetized*. This aligns with the architectural goal of *lean, stateless views*【6†L631-L634】【30†L658-L667】.

## 7. Metrics and Tools

Measure improvements by comparing before/after metrics:

- **Frame rendering times:** Use **Flutter DevTools Performance View** to measure build/render times and frame rate. The plugin can highlight frames over 16ms【32†L902-L911】.  
- **Rebuild counts:** DevTools can show how often widgets rebuild. Fewer unnecessary rebuilds means better performance (enabled via “Show Rebuilds” or the `devtools` performance overlay).  
- **Debug banners:** The IDE’s **Flutter Performance Overlay** shows real-time FPS and can flag janky frames.  
- **Logging and Lints:** Use the **Logging View** in DevTools to catch errors and log output. Integrate the `flutter_lints` package【34†L837-L840】. Check for lint rules on naming, unused code, and best practices.  
- **Code complexity:** Tools like `dart analyze` (with custom lint rules) can catch large functions or poor patterns.  
- **Test coverage:** Track code coverage (e.g. using `flutter test --coverage`) to ensure the core logic layers are well-tested.  
- **Continuous profiling:** For a production app, consider periodic profiling (memory/CPU) using DevTools or `profile` mode.  

By monitoring these, you can verify that refactoring improved maintainability without regressing performance. Flutter’s docs specifically recommend DevTools and the `flutter_lints` toolchain for architecture and performance debugging【34†L837-L840】【30†L643-L652】.

## 8. Common Anti-Patterns to Remove

From flutter.dev guidance, avoid these pitfalls:

- **Logic inside Widgets:** (The biggest anti-pattern). As Flutter docs state: *“Do not put logic in widgets”*【34†L669-L677】. Views should not fetch data, perform calculations, or make service calls. Move all that into ViewModels or services. If you see `setState` managing complex logic or async calls in a widget, extract it.  
- **Multiple Sources of Truth:** Don’t duplicate state. If two places each fetch or store the same data, bugs ensue. Use a single Repository per data type【7†L668-L676】. For example, avoid holding a user’s profile in both a global map and in a page; unify under one repo.  
- **Mutable UI State:** Avoid widgets that manage business data in fields. Instead, use immutable models and let the UI rebuild from a changed ViewModel state【7†L727-L735】【34†L716-L724】.  
- **Massive Widgets (`GodWidget`):** Large widgets with dozens of properties/callbacks quickly become unmanageable. Break them down. The docs encourage small, reusable widgets (especially marked `const`)【30†L675-L682】.  
- **Tight Coupling:** Global singletons or tightly coupling classes to Flutter (e.g. using `BuildContext` inside service classes) should be removed. Instead, follow dependency injection via Provider【34†L753-L761】.  
- **Imperative Navigation or Business in UI:** Avoid triggers like `Navigator.push` scattered throughout UI code beyond simple cases; centralize routing (e.g. via `go_router`)【34†L761-L768】. Business logic should never be invoked inside the `onPressed` of a button directly; call ViewModel methods instead.  
- **Imperative State Changes:** Don’t call `setState()` on top-level widgets for global updates. Use ViewModels/ChangeNotifiers to update state smoothly.  
- **Ignoring Performance:** Using non-const widgets, performing heavy loops in `build()`, or using many opaque animations will hurt performance. Clean these up using best-practice patterns【30†L658-L667】【30†L675-L679】.

Removing these anti-patterns aligns your code with the principles above and greatly improves maintainability.

## 9. Quick-Reference Checklist

- **[ ] Separation of Concerns:** UI vs Data layers【6†L622-L630】.  
- **[ ] MVVM Pattern:** For each screen/feature, use one `XxxView` and one `XxxViewModel`【16†L650-L658】.  
- **[ ] File Structure:** Organize by feature: e.g. `ui/featureName/view_models/…`, `ui/featureName/widgets/…`, `data/repositories/…`, `data/services/…`【4†L667-L674】【4†L683-L691】.  
- **[ ] Stateless Widgets:** Convert Views to `StatelessWidget` or `ConsumerWidget`. All logic in ViewModels【34†L669-L677】.  
- **[ ] ViewModel Logic:** Move all data fetching, state handling, and “commands” into ViewModels. Notify listeners on state changes.  
- **[ ] Repositories:** One per data type; implement caching, error handling, etc.【7†L668-L676】【26†L820-L828】.  
- **[ ] Services:** One per API or platform source. Keep them simple and stateless【26†L847-L856】.  
- **[ ] Immutable Models:** Use `freezed` or similar to define data classes (no `var` fields)【34†L716-L724】.  
- **[ ] Unidirectional Flow:** UI → ViewModel → Repository → Service, and back UI via notifications【7†L702-L710】.  
- **[ ] Dependency Injection:** Use `Provider` (or similar) to inject Repos/Services into ViewModels【34†L753-L761】. Avoid globals.  
- **[ ] Navigation:** Use `go_router` for routes【34†L761-L768】; keep route definitions separate from business logic.  
- **[ ] Tests:** Write unit tests for each Service, Repository, and ViewModel【28†L805-L812】. Write widget tests for each View (include DI/routing). Use fakes for dependencies【28†L812-L819】.  
- **[ ] Performance:** Mark widgets `const` when possible; split large widgets; avoid heavy work in `build()`【30†L658-L667】【30†L675-L679】. Use DevTools to profile.  
- **[ ] Lints:** Enable `flutter_lints` and clean up issues (missing const, naming conventions, etc.)【34†L837-L840】.  
- **[ ] Anti-Patterns:** Remove logic from widgets【34†L669-L677】, duplicate state, global singletons, etc.  
- **[ ] Review Metrics:** Use DevTools (Performance, CPU, Memory tabs) to verify <16ms frames and reduced rebuilds.  

Following this checklist daily will help keep your Flutter codebase scalable, testable, and performant, exactly as the Flutter documentation recommends.  

**Sources:** Flutter documentation, *Architecture* section – especially *Common architecture concepts*, *Guide to app architecture*, *Architecture recommendations*, and *Performance best practices*【6†L622-L630】【16†L650-L658】【26†L794-L803】【30†L658-L667】.