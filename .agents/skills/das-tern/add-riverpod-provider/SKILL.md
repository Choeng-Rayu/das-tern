# Skill: add-riverpod-provider

Add a new Riverpod provider to the Das Tern Flutter app.

## When to use
When a feature needs to expose state, a repository, or an async value to the UI.

## Provider type selection

| Need | Provider type |
|---|---|
| Singleton (DB, Supabase client, config) | `Provider<T>` |
| Async one-shot (remote fetch) | `FutureProvider<T>` |
| Reactive stream (Drift watch, Realtime) | `StreamProvider<T>` |
| User-controlled mutable state | `StateNotifierProvider<N, T>` |
| Parameterised / family | `*Provider.family<T, P>` |

## Template

```dart
// lib/features/<name>/presentation/providers/<name>_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/<name>_repository_impl.dart';
import '../../domain/<name>_repository.dart';
import '../../../../core/storage/drift/app_database.dart';
import '../../../../core/sync/sync_engine.dart';

// Repository provider
final <name>RepositoryProvider = Provider<<Name>Repository>(
  (ref) => <Name>RepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    sync: ref.watch(syncEngineProvider),
  ),
);

// Data provider (stream example)
final <name>ListProvider = StreamProvider<List<<Name>>>(
  (ref) => ref.watch(<name>RepositoryProvider).watchAll(),
);
```

## Rules
- Name ends in `Provider`.
- Always type the provider explicitly — never `var` or `final x = Provider(...)`.
- UI uses `ref.watch` in `build`; `ref.read` outside build.
- Invalidate with `ref.invalidate(<provider>)` after mutations.
- Override in tests with `ProviderScope(overrides: [...])`.

## Verify
```bash
flutter analyze --fatal-warnings --fatal-infos
flutter test
```
