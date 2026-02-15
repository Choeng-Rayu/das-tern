# DAS TERN MCP - Comprehensive Logging Guide

## Overview
The app now has structured, colored, timestamped logging throughout all critical services and providers. All logs are prefixed with **[timestamp][level][source]** for easy filtering.

---

## Log Levels

| Level | Color | When to Use |
|-------|-------|-------------|
| `DEBUG` | Cyan | Development-only detailed traces (auto-disabled in release) |
| `INFO` | Blue | Important informational events |
| `WARN` | Yellow | Warnings that don't break functionality |
| `ERROR` | Red | Errors with exception details and stack traces |
| `SUCCESS` | Green | Successful completion of operations |
| `API→` | Magenta | Outgoing API requests |
| `API←` | Green/Red | API responses (green=2xx, red=error) |
| `STATE` | Cyan | Provider state changes |
| `DB` | Blue | Database operations |
| `SYNC` | Magenta | Sync operations |
| `NOTIF` | Yellow | Notification operations |

---

## Logging by Component

### 🔐 Authentication (`AuthProvider`)
```
[INFO][AuthProvider] Login attempt
[SUCCESS][AuthProvider] Login successful
[ERROR][AuthProvider] Login failed
[INFO][AuthProvider] Loading auth state from storage
[SUCCESS][AuthProvider] User authenticated
[WARNING][AuthProvider] Access token invalid, trying refresh
[INFO][AuthProvider] Logout initiated
[STATE][AuthProvider] idle → loading
```

### 🌐 API Service (`ApiService`)
```
[API→][ApiService] POST /auth/login
[API←][ApiService] POST /auth/login [200]
[DEBUG][ApiService] Saving tokens to secure storage
[SUCCESS][ApiService] Tokens saved successfully
[INFO][ApiService] Attempting to refresh access token
[WARNING][ApiService] Token refresh failed [401]
[ERROR][ApiService] Request failed [500]: Internal server error
```

### 💾 Database (`DatabaseService`)
```
[INFO][DatabaseService] Initializing database
[DEBUG][DatabaseService] Database path: /data/user/0/.../das_tern.db
[SUCCESS][DatabaseService] Database schema created successfully
[DB][DatabaseService] CACHE on dose_events
[DB][DatabaseService] INSERT on sync_queue
[WARNING][DatabaseService] Clearing all local data
```

### 🔄 Sync Service (`SyncService`)
```
[INFO][SyncService] Starting connectivity monitoring
[INFO][SyncService] Initial connectivity state
[STATE][SyncService] offline → online (wifi)
[INFO][SyncService] Back online – syncing pending changes
[INFO][SyncService] Starting full sync cycle
[SYNC][SyncService] Processing sync queue
[SYNC][SyncService] Pushing unsynced doses
[SUCCESS][SyncService] Sync complete
[WARNING][SyncService] Cannot sync: device is offline
```

### 💊 Dose Provider (`DoseProvider`)
```
[INFO][DoseProvider] Fetching today's schedule
[DEBUG][DoseProvider] Fetching from API (online)
[SUCCESS][DoseProvider] Schedule fetched from API
[WARNING][DoseProvider] Device offline, loading from cache
[INFO][DoseProvider] Marking dose taken
[SUCCESS][DoseProvider] Dose marked taken (online)
[INFO][DoseProvider] Dose marked taken (offline, queued for sync)
[ERROR][DoseProvider] Failed to fetch schedule
```

### 🔔 Notifications (`NotificationService`)
```
[NOTIF][NotificationService] Initialized
[NOTIF][NotificationService] Scheduling reminder for dose
[NOTIF][NotificationService] Cancelled all reminders
```

### 🚀 App Lifecycle (`main.dart`)
```
[INFO][App] 🚀 Starting DAS TERN MCP App
[DEBUG][App] Loading environment variables
[SUCCESS][App] Environment loaded
[INFO][App] Initializing services
[SUCCESS][App] Services initialized
[ERROR][FlutterError] Uncaught Flutter error
```

---

## How to Debug Issues

### 1. **Login Issues**
Filter logs by `[AuthProvider]` and `[ApiService]`:
```
[INFO][AuthProvider] Login attempt
[API→][ApiService] POST /auth/login
[API←][ApiService] POST /auth/login [401]
[ERROR][AuthProvider] Login failed: Invalid credentials
```

### 2. **Network/Connectivity Issues**
Filter logs by `[SyncService]`:
```
[STATE][SyncService] online → offline (none)
[WARNING][SyncService] Cannot sync: device is offline
[INFO][SyncService] Back online – syncing pending changes
```

### 3. **Database Issues**
Filter logs by `[DatabaseService]` or `[DB]`:
```
[INFO][DatabaseService] Initializing database
[DB][DatabaseService] CACHE on dose_events
[ERROR][DatabaseService] Failed to cache doses
```

### 4. **API Call Failures**
Filter logs by `[API→]` and `[API←]`:
```
[API→][ApiService] GET /doses/schedule
[API←][ApiService] GET /doses/schedule [500]
[ERROR][ApiService] Request failed [500]: Internal server error
  ↳ Data: {"message":"Database connection lost"}
```

### 5. **Offline Sync Issues**
Filter logs by `[SYNC]`:
```
[SYNC][SyncService] Processing sync queue
[DEBUG][SyncService] Replaying: PATCH /doses/abc-123/taken
[SUCCESS][SyncService] Sync complete
```

### 6. **Token/Security Issues**
Filter logs by token-related messages:
```
[DEBUG][ApiService] Saving tokens to secure storage
[INFO][ApiService] Attempting to refresh access token
[WARNING][ApiService] Token refresh failed [401]
[WARNING][ApiService] Clearing all tokens from secure storage
```

---

## Filtering Logs in Android Studio / VS Code

### Android Studio (Logcat)
1. Open **Logcat** panel
2. Use regex filter: `\[(INFO|ERROR|WARN|SUCCESS)\]\[AuthProvider\]`
3. Or search: `[ApiService]`, `[SyncService]`, etc.

### VS Code (Terminal)
```bash
flutter run | grep "\\[ERROR\\]"          # All errors
flutter run | grep "\\[AuthProvider\\]"   # Auth logs
flutter run | grep "\\[API→\\]"           # API requests
flutter run | grep "\\[SYNC\\]"           # Sync operations
```

### ADB Logcat (Direct)
```bash
adb logcat | grep "flutter"
adb logcat | grep "\\[ERROR\\]"
adb logcat -s flutter:* | grep AuthProvider
```

---

## Log Output Examples

### Successful Login Flow
```
[16:24:15.123][INFO][AuthProvider] Login attempt
[16:24:15.124][API→][ApiService] POST /auth/login
  ↳ Data: {phoneNumber: +85512345678}
[16:24:15.456][API←][ApiService] POST /auth/login [200]
  ↳ Data: {user: abc-123}
[16:24:15.457][DEBUG][ApiService] Saving tokens to secure storage
[16:24:15.478][SUCCESS][ApiService] Tokens saved successfully
[16:24:15.479][SUCCESS][AuthProvider] Login successful
  ↳ Data: {userId: abc-123, role: PATIENT}
[16:24:15.480][STATE][AuthProvider] loading → idle
```

### Offline Dose Marking
```
[16:25:30.123][INFO][DoseProvider] Marking dose taken
  ↳ Data: {doseId: dose-001, online: false}
[16:25:30.145][DB][DatabaseService] INSERT on sync_queue
  ↳ Data: {action: mark_taken, endpoint: /doses/dose-001/taken}
[16:25:30.146][INFO][DoseProvider] Dose marked taken (offline, queued for sync)
[16:25:30.200][NOTIF][NotificationService] Cancelled reminder for dose-001
```

### Sync When Back Online
```
[16:26:00.000][STATE][SyncService] offline → online (wifi)
[16:26:00.001][INFO][SyncService] Back online – syncing pending changes
[16:26:00.002][INFO][SyncService] Starting full sync cycle
[16:26:00.003][SYNC][SyncService] Processing sync queue
  ↳ Data: {items: 3}
[16:26:00.004][DEBUG][SyncService] Replaying: PATCH /doses/dose-001/taken
[16:26:00.234][API←][ApiService] PATCH /doses/dose-001/taken [200]
[16:26:00.500][SYNC][SyncService] Pushing unsynced doses
  ↳ Data: {count: 0}
[16:26:00.800][SUCCESS][SyncService] Sync complete
```

---

## Performance Notes

- **DEBUG logs**: Only shown in debug mode, zero overhead in release builds
- **Color codes**: Terminal-compatible ANSI escape sequences
- **Data truncation**: Long data objects automatically truncated to 500 chars
- **Timestamp format**: `HH:mm:ss.SSS` for precise timing

---

## Adding Custom Logs

### In Your Code
```dart
final log = LoggerService.instance;

// Info
log.info('MyComponent', 'User action', {'action': 'button_tap'});

// Debug (dev only)
log.debug('MyComponent', 'Internal state', stateObject);

// Warning
log.warning('MyComponent', 'Deprecated API used');

// Error
log.error('MyComponent', 'Operation failed', exception, stackTrace);

// Success
log.success('MyComponent', 'Data saved');
```

---

## Next Steps for Enhanced Debugging

1. **Add crashlytics**: Firebase Crashlytics for production error tracking
2. **Remote logging**: Send ERROR-level logs to monitoring service
3. **Performance monitoring**: Add timing logs for slow operations
4. **User action tracking**: Log critical user flows (register → verify → login)

---

**All logs are now enabled! Run the app and watch the console for detailed insights.** 🎯
