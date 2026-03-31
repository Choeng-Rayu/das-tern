# Das Tern: Local Data Storage & Medical Reminders Implementation

## Table of Contents
1. [Local Data Storage](#local-data-storage)
2. [Medical Reminder System](#medical-reminder-system)
3. [Complete End-to-End Flow](#complete-end-to-end-flow)
4. [Code Implementation Details](#code-implementation-details)

---

## Local Data Storage

### Yes, Data IS Kept Locally on User Device

The Das Tern mobile app stores data locally on the user's device using **SQLite** for offline access and reliability. This enables the app to work even when offline.

### Storage Architecture

#### 1. **SQLite Database** (`das_tern.db`)
**Location:** Device's application documents directory  
**Version:** v3  
**Size:** Lightweight, optimized for mobile  
**Purpose:** Offline-first caching and sync queue management

**Database Schema (5 Main Tables):**

```sql
-- 1. DOSE EVENTS TABLE (most critical for reminders)
CREATE TABLE dose_events (
  id TEXT PRIMARY KEY,
  prescription_id TEXT NOT NULL,
  medication_id TEXT NOT NULL,
  patient_id TEXT NOT NULL,
  scheduled_time TEXT NOT NULL,         -- When dose is due (ISO 8601)
  time_period TEXT NOT NULL,             -- MORNING, AFTERNOON, EVENING, NIGHT
  reminder_time TEXT NOT NULL,           -- When notification triggers
  status TEXT NOT NULL DEFAULT 'DUE',    -- DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED
  taken_at TEXT,                         -- When user marked as taken
  skip_reason TEXT,                      -- Why user skipped
  was_offline INTEGER NOT NULL DEFAULT 0, -- Whether dose was taken offline (1=yes)
  medication_name TEXT NOT NULL DEFAULT '',
  dosage TEXT NOT NULL DEFAULT '',
  medication_json TEXT,                  -- Full med details (JSON serialized)
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  synced INTEGER NOT NULL DEFAULT 1      -- 1=synced to server, 0=pending
);

-- 2. SYNC QUEUE TABLE (offline action replaying)
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action TEXT NOT NULL,                  -- e.g., "mark_taken", "skip", "snooze"
  endpoint TEXT NOT NULL,                -- API endpoint to call
  method TEXT NOT NULL,                  -- GET, POST, PUT, PATCH
  body TEXT,                             -- JSON payload
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT                        -- Last error message if retry failed
);

-- 3. PRESCRIPTIONS TABLE (cached rx data)
CREATE TABLE prescriptions (
  id TEXT PRIMARY KEY,
  data_json TEXT NOT NULL,               -- Full prescription object (JSON)
  updated_at TEXT NOT NULL
);

-- 4. HEALTH VITALS TABLE (vitals tracking)
CREATE TABLE health_vitals (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  vital_type TEXT NOT NULL,              -- BP, HR, Glucose, Temp, Weight, SpO2
  value REAL NOT NULL,
  value_secondary REAL,                  -- Diastolic (for BP)
  unit TEXT NOT NULL,
  measured_at TEXT NOT NULL,
  notes TEXT,
  is_abnormal INTEGER NOT NULL DEFAULT 0,
  source TEXT,
  created_at TEXT NOT NULL,
  synced INTEGER NOT NULL DEFAULT 1
);

-- 5. MEDICATION BATCHES TABLE (grouped medications)
CREATE TABLE medication_batches (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  name TEXT NOT NULL,
  scheduled_time TEXT NOT NULL,         -- Time all meds in batch are due
  is_active INTEGER NOT NULL DEFAULT 1,
  data_json TEXT NOT NULL,              -- Batch configuration (JSON)
  synced INTEGER NOT NULL DEFAULT 1
);

-- INDEXES for fast queries
CREATE INDEX idx_dose_scheduled ON dose_events(scheduled_time);
CREATE INDEX idx_dose_status ON dose_events(status);
CREATE INDEX idx_sync_queue_created ON sync_queue(created_at);
CREATE INDEX idx_vital_type ON health_vitals(vital_type);
CREATE INDEX idx_vital_measured ON health_vitals(measured_at);
```

#### 2. **SharedPreferences** (Key-Value Store)
**Purpose:** App settings and pending notification actions  
**Specific Uses:**
```dart
// Language preference (set by user in settings)
'languageCode' → 'en' or 'km' (English or Khmer)

// Pending notification actions (queued from background notifications)
'pending_notification_actions' → JSON list of user actions
  {
    'action': 'mark_taken' | 'skip' | 'snooze',
    'payload': doseId,
    'timestamp': '2026-03-31T14:30:00.000Z'
  }
```

#### 3. **Flutter Secure Storage** (Encrypted Keychain/Keystore)
**Purpose:** Securely store sensitive tokens  
**Specific Uses:**
```dart
// JWT access token (15-minute lifetime)
'auth_token' → eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

// JWT refresh token (7-day lifetime)
'refresh_token' → eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

// User ID and email (for quick app initialization)
'user_id' → UUID
'user_email' → user@example.com
```

**Encryption Details:**
- **Android:** Uses `EncryptedSharedPreferences` (AES-256-GCM)
- **iOS:** Uses Keychain with `first_unlock` accessibility (accessible after first device unlock)

---

### Data Synchronization Strategy

#### **Offline-First Architecture**

When the app is **ONLINE**:
1. ✅ Doses are stored in **SQLite locally** (cache)
2. ✅ **Immediately synced** to backend API
3. ✅ Backend is the **source of truth** for dose history

When the app is **OFFLINE**:
1. ✅ Doses are recorded **locally in SQLite**
2. ✅ Status marked as `synced=0` (not synced)
3. ✅ Action queued in `sync_queue` table
4. ✅ When back online → **auto-sync to backend** (replay queue)

#### **Sync Process (4-Step Flow)**

```
[User marks dose as taken] 
    ↓
[Online?]
├─ YES → Immediately call API + update SQLite ✅
│        (backend = source of truth)
│
└─ NO → Queue in sync_queue + update SQLite locally
        Mark as synced=0
        ↓
        [Device comes online?]
        ├─ YES → SyncService.syncAll() triggers
        │        1. Push sync_queue (replay all queued actions)
        │        2. Push unsynced dose status changes
        │        3. Pull fresh dose schedule
        │        4. Pull fresh prescriptions
        │        5. Pull fresh medication batches
        │        ✅ Local cache now matches backend
        │
        └─ NO → Stay offline, retry next time online
```

#### **Code: Full Sync Cycle** (`sync_service.dart:106-144`)
```dart
/// Run a full sync: push pending → pull fresh data.
Future<void> syncAll() async {
  if (_isSyncing) return;          // Prevent double-sync
  if (!_isOnline) return;           // Only sync when online
  
  _isSyncing = true;
  notifyListeners();
  
  try {
    // Step 1: Push offline actions from sync queue
    await _processSyncQueue();
    
    // Step 2: Push unsynced dose status changes (taken/skipped)
    await _pushUnsyncedDoses();
    
    // Step 3: Pull fresh dose schedule for today
    await _pullDoseSchedule();
    
    // Step 4: Pull fresh prescriptions (in case updated)
    await _pullPrescriptions();
    
    // Step 5: Pull fresh medication batches
    await _pullBatches();
    
    _log.success('SyncService', 'Sync complete');
  } catch (e) {
    _log.error('SyncService', 'Sync error', e);
  } finally {
    _isSyncing = false;
    notifyListeners();
  }
}
```

#### **Connectivity Monitoring** (`sync_service.dart:45-80`)
```dart
/// Start listening for connectivity changes
Future<void> startListening() async {
  // Check initial connectivity state
  final result = await _connectivity.checkConnectivity();
  _isOnline = _isConnected(result);  // mobile, wifi, or ethernet
  
  // Listen for changes
  _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
    final wasOnline = _isOnline;
    _isOnline = _isConnected(result);
    
    // Just came back online → auto-sync
    if (!wasOnline && _isOnline) {
      _log.info('SyncService', 'Back online – syncing pending changes');
      syncAll();  // ← Auto-triggers full sync
    }
    
    notifyListeners();
  });
}
```

---

## Medical Reminder System

### How Reminders Work: Complete Implementation

The reminder system uses **local OS notifications** scheduled ahead of time, with a **3-attempt retry strategy** (at reminder time, +10 min, +20 min).

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Das Tern Reminder System Architecture                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. FETCH SCHEDULE (DoseProvider)                           │
│     ├─ Online: GET /api/v1/doses/schedule?date=2026-03-31  │
│     └─ Offline: SQLite.getCachedDosesByDate()              │
│                                                              │
│  2. CACHE TO LOCAL DB (DatabaseService)                    │
│     └─ INSERT INTO dose_events (... status='DUE')          │
│                                                              │
│  3. SCHEDULE NOTIFICATIONS (NotificationService)            │
│     ├─ 3 notifications per dose (0, 10, 20 min offsets)    │
│     ├─ Use timezone: Asia/Phnom_Penh (Cambodia Time)       │
│     ├─ Platform: Android (exact alarms) + iOS (local notif)│
│     └─ Actions: "Mark as Taken", "Snooze 10min", "Skip"   │
│                                                              │
│  4. NOTIFICATION TRIGGER (OS Level)                        │
│     ├─ At scheduled time → OS fires notification           │
│     ├─ User can tap action button or notification body     │
│     └─ Action queued (foreground) or stored (background)   │
│                                                              │
│  5. PROCESS USER ACTION (App)                              │
│     ├─ If app is open: _onNotificationResponse()           │
│     ├─ If app is closed: onBackgroundNotificationAction()  │
│     └─ Store in SharedPreferences pending_actions queue    │
│                                                              │
│  6. SYNC ACTION (Online/Offline)                           │
│     ├─ Online: Immediately POST to /api/v1/doses/mark-taken
│     └─ Offline: Queue in sync_queue, replay on reconnect   │
│                                                              │
│  7. UPDATE LOCAL STATE (DoseProvider)                      │
│     └─ Mark dose as TAKEN_ON_TIME or TAKEN_LATE           │
│        Refresh UI with updated adherence progress          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step-by-Step Implementation

#### **Step 1: Fetch Dose Schedule**

**File:** `dose_provider.dart:58-150`

```dart
/// Fetch today's dose schedule.
/// Online → API + cache to SQLite + schedule notifications.
/// Offline → load from SQLite cache.
Future<void> fetchTodaySchedule({bool quietly = false}) async {
  _isLoading = true;
  notifyListeners();
  
  try {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (_sync.isOnline) {
      // ONLINE: Fetch from backend API
      final result = await _api.getDoseSchedule(
        date: today,
        groupBy: 'timePeriod',  // Group by MORNING, AFTERNOON, etc.
      );
      
      // Backend returns: { date, dailyProgress, groups: [{period, doses}] }
      final allDoses = <Map<String, dynamic>>[];
      for (final group in result['groups']) {
        final doseMaps = group['doses'] as List;
        allDoses.addAll(doseMaps);
      }
      
      // Cache to SQLite for offline access
      await _db.cacheDoseEvents(allDoses);
      
      // Schedule local notifications ← Step 3
      await _notif.scheduleAllReminders(allDoses);
      
      _todaysDoses = allDoses.map((d) => DoseEvent.fromJson(d)).toList();
      _log.success('DoseProvider', 'Schedule fetched and cached');
    } else {
      // OFFLINE: Load from SQLite cache
      final cached = await _db.getCachedDosesByDate(today);
      _todaysDoses = cached.map((d) => DoseEvent.fromJson(d)).toList();
      
      // Schedule notifications from cached data
      await _notif.scheduleAllReminders(cached);
      _log.info('DoseProvider', 'Schedule loaded from cache');
    }
  } catch (e) {
    _error = e.toString();
    _log.error('DoseProvider', 'Failed to fetch', e);
    // Fallback to cache even on API error
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Sample API Response:**
```json
{
  "date": "2026-03-31",
  "dailyProgress": 12,
  "groups": [
    {
      "period": "MORNING",
      "doses": [
        {
          "id": "dose_1234",
          "prescriptionId": "rx_5678",
          "medicationId": "med_9012",
          "medicationName": "Metformin",
          "dosage": "500mg",
          "scheduledTime": "2026-03-31T07:00:00Z",
          "reminderTime": "2026-03-31T06:50:00Z",
          "timePeriod": "MORNING",
          "status": "DUE",
          "takenAt": null
        }
      ]
    },
    {
      "period": "AFTERNOON",
      "doses": [...]
    }
  ]
}
```

#### **Step 2: Cache to SQLite**

**File:** `database_service.dart:53-73, 400+`

```dart
// In DatabaseService
Future<void> cacheDoseEvents(List<Map<String, dynamic>> doses) async {
  final db = await database;
  
  for (final dose in doses) {
    await db.insert(
      'dose_events',
      {
        'id': dose['id'],
        'prescription_id': dose['prescriptionId'],
        'medication_id': dose['medicationId'],
        'patient_id': dose['patientId'],
        'scheduled_time': dose['scheduledTime'],
        'time_period': dose['timePeriod'],
        'reminder_time': dose['reminderTime'],
        'status': dose['status'] ?? 'DUE',
        'medication_name': dose['medicationName'] ?? '',
        'dosage': dose['dosage'] ?? '',
        'medication_json': jsonEncode(dose),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 1,  // ← From backend, so synced
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

// Later: retrieve from cache
Future<List<Map<String, dynamic>>> getCachedDosesByDate(String date) async {
  final db = await database;
  return db.query(
    'dose_events',
    where: 'DATE(scheduled_time) = ?',
    whereArgs: [date],
    orderBy: 'scheduled_time ASC',
  );
}
```

#### **Step 3: Schedule Notifications (3 Retries)**

**File:** `notification_service.dart:92-101, 217-298`

```dart
class NotificationService {
  static const List<int> retryOffsets = [0, 10, 20];  // minutes
  
  /// Initialize the notification system (runs at app startup)
  Future<void> init() async {
    if (_initialized) return;
    
    // Initialize timezone to Cambodia
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Phnom_Penh'));
    
    // Setup Android & iOS specific settings
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',  // Icon in system tray
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _plugin.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: 
          onBackgroundNotificationAction,
    );
    
    // Request notification permissions (Android 13+)
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
        // Also request exact alarm permission
        await android.requestExactAlarmsPermission();
      }
    }
    
    _initialized = true;
  }
  
  /// Schedule a single dose with 3 retry notifications
  Future<void> scheduleDoseWithRetries({
    required String doseId,
    required String medicationName,
    required String dosage,
    required DateTime reminderTime,
    required String timePeriod,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    
    // Get localized strings (EN or KM based on app language)
    final s = await _strings();
    final period = s.periodLabel(timePeriod);  // "Morning", "ព្រឹក", etc.
    
    // Schedule 3 notifications: immediate, +10min, +20min
    for (final offsetMinutes in retryOffsets) {
      final time = reminderTime.add(Duration(minutes: offsetMinutes));
      
      // Skip if time is already past
      if (time.isBefore(DateTime.now())) continue;
      
      // Build unique ID for this notification
      // Example: "dose_1234_retry_0" → hash → notification ID
      final uniqueId = '${doseId}_retry_$offsetMinutes';
      final id = uniqueId.hashCode.abs() % 2147483647;
      
      // Notification title (with "Retry" tag if this is 2nd or 3rd attempt)
      final isRetry = offsetMinutes > 0;
      final title = s.reminderTitle + 
                    (isRetry ? s.reminderRetryTag : '');
      // Example: "Medication Reminder [Retry]"
      
      // Schedule the notification on both platforms
      await _plugin.zonedSchedule(
        id,
        title,
        s.singleBody(medicationName, dosage, period),
        // Body example: "Metformin 500mg - Morning"
        tz.TZDateTime.from(time, tz.local),  // Convert to TZDateTime
        NotificationDetails(
          android: AndroidNotificationDetails(
            'dose_reminders',  // Channel ID
            s.channelDoseRemindersName,  // "Dose Reminders"
            channelDescription: s.channelDoseRemindersDesc,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@drawable/ic_notification',
            // Action buttons user can tap
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_taken',
                s.actionMarkTaken,  // "Mark as Taken"
                showsUserInterface: false,
                cancelNotification: true,  // Dismiss after tap
              ),
              AndroidNotificationAction(
                'snooze',
                s.actionSnooze,  // "Snooze 10m"
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'skip',
                s.actionSkip,  // "Skip"
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Use exact scheduling so reminders are precise
        // On Android, this is only possible with SCHEDULE_EXACT_ALARM permission
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: doseId,  // Pass doseId so we know which dose when tapped
      );
    }
    
    _log.info('NotificationService', 
              'Scheduled dose reminders',
              {'doseId': doseId, 'attempts': retryOffsets.length});
  }
  
  /// Schedule reminders for multiple doses at same time (batch)
  /// Shows one notification listing all medications
  Future<void> scheduleBatchDoseWithRetries({
    required List<String> doseIds,
    required List<String> medicationNames,
    required DateTime reminderTime,
    required String timePeriod,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (doseIds.isEmpty) return;
    
    final s = await _strings();
    final period = s.periodLabel(timePeriod);
    
    // Use first dose ID as batch key
    final batchKey = 'dose_batch_${doseIds.first}';
    
    for (final offsetMinutes in retryOffsets) {
      final time = reminderTime.add(Duration(minutes: offsetMinutes));
      if (time.isBefore(DateTime.now())) continue;
      
      final isRetry = offsetMinutes > 0;
      final title = s.reminderTitle + 
                    (isRetry ? s.reminderRetryTag : '');
      
      // Build medicine list for notification body
      // Example: "Morning Medications:\n  - Metformin 500mg\n  - Atorvastatin 10mg"
      final medicineLines = medicationNames.map((n) => '  - $n').join('\n');
      final body = '${s.batchBodyHeader(period)}\n$medicineLines';
      
      final uniqueId = '${batchKey}_retry_$offsetMinutes';
      final id = uniqueId.hashCode.abs() % 2147483647;
      
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(time, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'dose_reminders',
            s.channelDoseRemindersName,
            channelDescription: s.channelDoseRemindersDesc,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@drawable/ic_notification',
            styleInformation: BigTextStyleInformation(body),
            // Same action buttons
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_taken',
                s.actionMarkTaken,
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'snooze',
                s.actionSnooze,
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'skip',
                s.actionSkip,
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Payload = comma-separated dose IDs (all marked taken on one action)
        payload: doseIds.join(','),
      );
    }
  }
}
```

#### **Step 4: OS Fires Notification**

When the scheduled time arrives:
- **Android:** OS uses `AlarmManager` with exact alarm scheduling
- **iOS:** Uses `UserNotifications` framework
- **Both:** Display notification in system tray with action buttons

#### **Step 5: User Taps Action Button**

**File:** `notification_service.dart:22-47, 143-179`

The action can be from **foreground** (app open) or **background** (app closed).

```dart
/// Handle notification action when app is CLOSED (background)
/// This runs in an isolate - only lightweight work allowed
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) {
  debugPrint('[NotificationService] Background action: ${response.actionId}');
  
  final payload = response.payload;  // doseId(s)
  final actionId = response.actionId; // mark_taken, snooze, skip
  if (payload == null || actionId == null) return;
  
  // Queue the action for processing when app opens
  // We can't call API here (no Flutter engine in isolate)
  // So we store in SharedPreferences to process later
  SharedPreferences.getInstance().then((prefs) {
    final pending = prefs.getStringList('pending_notification_actions') ?? [];
    pending.add(jsonEncode({
      'action': actionId,      // mark_taken, skip, snooze
      'payload': payload,      // doseId(s)
      'timestamp': DateTime.now().toIso8601String(),
    }));
    prefs.setStringList('pending_notification_actions', pending);
    debugPrint('[NotificationService] Queued for later: $actionId');
  });
}

/// Handle notification action when app is OPEN (foreground)
void _onNotificationResponse(NotificationResponse response) {
  debugPrint(
    '[NotificationService] Foreground response: '
    'actionId=${response.actionId} payload=${response.payload}',
  );
  
  final payload = response.payload;
  if (payload == null) return;
  
  final actionId = response.actionId;
  
  if (actionId == null || actionId.isEmpty) {
    // User tapped notification body (not an action button)
    // Navigate into the app
    onNotificationTapped?.call(payload);
    return;
  }
  
  // User tapped action button while app is open
  // Queue it using same mechanism as background
  SharedPreferences.getInstance().then((prefs) {
    final pending = prefs.getStringList('pending_notification_actions') ?? [];
    pending.add(jsonEncode({
      'action': actionId,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    prefs.setStringList('pending_notification_actions', pending);
  });
  
  // Special case: if user tapped "Snooze", reschedule immediately
  if (actionId == 'snooze') {
    _handleSnoozeAction(payload);  // Reschedule +10 minutes
  }
}
```

#### **Step 6: Process Queued Actions**

**File:** `dose_provider.dart:150+` and sync on app startup

When app resumes (or at startup):

```dart
/// Call this when app starts or returns to foreground
Future<void> processPendingNotificationActions() async {
  final actions = await _notif.consumePendingActions();
  
  for (final action in actions) {
    final actionType = action['action'] as String;
    final payload = action['payload'] as String;  // doseId(s)
    
    switch (actionType) {
      case 'mark_taken':
        // Mark dose(s) as taken
        await markDoseTaken(payload);  // Can be single or batch (CSV)
        break;
        
      case 'skip':
        // Mark dose(s) as skipped
        await skipDose(payload);
        break;
        
      case 'snooze':
        // Already rescheduled by _handleSnoozeAction()
        break;
    }
  }
}

Future<void> markDoseTaken(String doseIdCsv) async {
  final doseIds = doseIdCsv.split(',');
  
  for (final doseId in doseIds) {
    try {
      if (_sync.isOnline) {
        // ONLINE: Call API immediately
        await _api.markDoseTaken(
          doseId: doseId,
          takenAt: DateTime.now().toIso8601String(),
        );
        _log.success('DoseProvider', 'Marked taken (online)');
      } else {
        // OFFLINE: Queue for later sync
        final db = await _db.database;
        await db.insert(
          'sync_queue',
          {
            'action': 'mark_taken',
            'endpoint': '/doses/$doseId/mark-taken',
            'method': 'POST',
            'body': jsonEncode({
              'takenAt': DateTime.now().toIso8601String(),
            }),
            'retry_count': 0,
          },
        );
        _log.info('DoseProvider', 'Queued mark_taken for later sync');
      }
      
      // Update local SQLite regardless of online/offline
      final db = await _db.database;
      await db.update(
        'dose_events',
        {
          'status': 'TAKEN_ON_TIME',
          'taken_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'synced': _sync.isOnline ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [doseId],
      );
      
      // Refresh UI
      notifyListeners();
      
    } catch (e) {
      _log.error('DoseProvider', 'Failed to mark taken', e);
    }
  }
}
```

#### **Step 7: Sync to Backend**

When device comes online, `SyncService.syncAll()` is triggered:

```dart
// In sync_service.dart

/// Step 1: Replay sync_queue (all queued API calls)
Future<void> _processSyncQueue() async {
  final db = await _db.database;
  final queue = await db.query('sync_queue');
  
  for (final item in queue) {
    try {
      final method = item['method'] as String;
      final endpoint = item['endpoint'] as String;
      final bodyStr = item['body'] as String?;
      
      http.Response response;
      
      if (method == 'POST') {
        response = await http.post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: bodyStr,
        );
      } else if (method == 'PUT') {
        response = await http.put(
          Uri.parse('$_baseUrl$endpoint'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: bodyStr,
        );
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success: remove from queue
        await db.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        _log.success('SyncService', 'Synced queued action');
      } else {
        // Failure: increment retry count
        await db.update(
          'sync_queue',
          {
            'retry_count': (item['retry_count'] as int) + 1,
            'last_error': response.body,
          },
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        _log.warning('SyncService', 'Failed to sync, will retry');
      }
    } catch (e) {
      _log.error('SyncService', 'Error processing sync queue', e);
    }
  }
}

/// Step 2: Push unsynced dose status changes
Future<void> _pushUnsyncedDoses() async {
  final db = await _db.database;
  final unsynced = await db.query(
    'dose_events',
    where: 'synced = ?',
    whereArgs: [0],
  );
  
  for (final dose in unsynced) {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/doses/${dose['id']}'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': dose['status'],  // TAKEN_ON_TIME, TAKEN_LATE, SKIPPED
          'takenAt': dose['taken_at'],
          'skipReason': dose['skip_reason'],
        }),
      );
      
      if (response.statusCode == 200) {
        // Mark as synced in local DB
        await db.update(
          'dose_events',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [dose['id']],
        );
      }
    } catch (e) {
      _log.error('SyncService', 'Failed to push dose', e);
    }
  }
}

/// Step 3: Pull fresh dose schedule
Future<void> _pullDoseSchedule() async {
  final today = DateTime.now().toIso8601String().split('T')[0];
  
  final response = await http.get(
    Uri.parse('$_baseUrl/doses/schedule?date=$today'),
    headers: {'Authorization': 'Bearer $_token'},
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map;
    final doses = data['doses'] as List? ?? [];
    
    // Replace local cache with fresh data from server
    await _db.cacheDoseEvents(
      List<Map<String, dynamic>>.from(doses),
    );
    
    _log.success('SyncService', 'Pulled fresh schedule');
  }
}
```

---

## Complete End-to-End Flow

### Scenario: User Gets Notification & Marks Dose as Taken

```
T0: 06:50 AM (Reminder Time - 10 minutes early)
├─ DoseProvider.fetchTodaySchedule() called at app startup
│  ├─ Online? YES → GET /api/v1/doses/schedule?date=2026-03-31
│  ├─ Backend returns: { doses: [{
│  │     id: "dose_abc123",
│  │     medicationName: "Metformin",
│  │     dosage: "500mg",
│  │     scheduledTime: "2026-03-31T07:00:00Z",
│  │     reminderTime: "2026-03-31T06:50:00Z",
│  │     timePeriod: "MORNING",
│  │     status: "DUE"
│  │   }]
│  │ }
│  ├─ DatabaseService.cacheDoseEvents() → INSERT INTO SQLite
│  └─ NotificationService.scheduleAllReminders() → Schedule 3 alarms
│     ├─ Alarm 1: 06:50 (T+0)
│     ├─ Alarm 2: 07:00 (T+10)
│     └─ Alarm 3: 07:10 (T+20)

T1: 06:50 AM
├─ OS AlarmManager fires first notification
├─ System notification appears in tray:
│  │ [NOTIFICATION]
│  │ Medication Reminder
│  │ Metformin 500mg - Morning
│  │ [Mark as Taken] [Snooze 10m] [Skip]
│  └─
├─ User taps "Mark as Taken" button

T2: ~06:50:05 AM (user taps button)
├─ App is CLOSED → onBackgroundNotificationAction() runs in isolate
├─ Action stored in SharedPreferences:
│  └─ pending_notification_actions: [
│       {action: "mark_taken", payload: "dose_abc123", 
│        timestamp: "2026-03-31T06:50:05Z"}
│     ]
├─ Notification dismissed

T3: ~06:50:10 AM
├─ App stays closed (user set reminder but won't open yet)
├─ Nothing happens - waiting for app to open

T4: 07:00 AM
├─ OS fires 2nd retry notification
├─ System notification shows again (same dose)
├─ User is getting ready, still hasn't opened app

T5: 07:10 AM
├─ OS fires 3rd retry notification
├─ User finally opens the app

T6: ~07:12 AM (app opened)
├─ main() → MultiProvider initialization
├─ App calls NotificationService.init()
├─ App calls DoseProvider.fetchTodaySchedule()
│  ├─ Online? YES
│  ├─ Fetches fresh schedule again (latest from backend)
│  └─ Reschedules notifications (cancels old ones)
├─ App calls SyncService.startListening()
├─ App calls processPendingNotificationActions()
│  ├─ Read pending_notification_actions from SharedPreferences
│  ├─ Found: { action: "mark_taken", payload: "dose_abc123" }
│  └─ Call DoseProvider.markDoseTaken("dose_abc123")

T7: ~07:12:05 AM
├─ DoseProvider.markDoseTaken("dose_abc123"):
│  ├─ Online? YES
│  ├─ POST /api/v1/doses/dose_abc123/mark-taken
│  │   body: { takenAt: "2026-03-31T07:12:05Z" }
│  ├─ Backend returns: { status: 200, dose: {..., status: "TAKEN_LATE"} }
│  ├─ Update local SQLite:
│  │   UPDATE dose_events 
│  │   SET status='TAKEN_LATE', taken_at='2026-03-31T07:12:05Z'
│  │   WHERE id='dose_abc123'
│  ├─ Clear pending actions from SharedPreferences
│  ├─ Cancel all retry notifications for this dose
│  └─ notifyListeners() → UI refreshes
│     ├─ Show check mark ✓ next to Metformin
│     ├─ Update adherence: 1/10 doses taken today
│     ├─ Animate progress bar
│     └─ Show toast: "Dose marked as taken"

T8: App displays updated UI
├─ User sees:
│  │ Today's Doses
│  │
│  │ ✓ Metformin 500mg (07:12) ← Late (should be 07:00)
│  │ ○ Atorvastatin 10mg (due at 13:00)
│  │ ○ Lisinopril 20mg (due at 21:00)
│  │
│  │ Adherence: 1/3 (33%)
│  │ ▓░░░░░░░░░░░░░░░░░░ Progress

DONE
```

### Scenario: User Offline, Then Marks Dose, Then Comes Online

```
T0: 06:50 AM
├─ Device is OFFLINE (no WiFi, no cellular)
├─ DoseProvider.fetchTodaySchedule():
│  ├─ SyncService.isOnline? NO
│  ├─ Load from SQLite cache: getCachedDosesByDate('2026-03-31')
│  ├─ Got 3 cached doses from yesterday's sync
│  └─ NotificationService.scheduleAllReminders(cachedDoses)
│     └─ Schedules from cached data

T1: 07:00 AM (scheduled reminder time)
├─ OS fires notification (even offline!)
├─ User marks as taken while device is offline

T2: 07:01 AM (user taps "Mark as Taken")
├─ App is open → _onNotificationResponse() (foreground)
├─ DoseProvider.markDoseTaken("dose_abc123"):
│  ├─ SyncService.isOnline? NO
│  ├─ Instead of calling API:
│  │   INSERT INTO sync_queue:
│  │   {
│  │     action: 'mark_taken',
│  │     endpoint: '/doses/dose_abc123/mark-taken',
│  │     method: 'POST',
│  │     body: '{"takenAt":"2026-03-31T07:01:00Z"}',
│  │     retry_count: 0
│  │   }
│  ├─ Update local SQLite:
│  │   UPDATE dose_events 
│  │   SET status='TAKEN_ON_TIME', 
│  │       taken_at='2026-03-31T07:01:00Z',
│  │       synced=0  ← Mark as NOT synced (pending)
│  │   WHERE id='dose_abc123'
│  ├─ UI updates immediately (optimistic update)
│  └─ Show: "✓ Metformin (saved offline - will sync)"

T3: User sees sync queue status
├─ DoseProvider shows: "1 dose pending sync"
├─ UI shows loading indicator (waiting to sync)

T4: 09:30 AM
├─ User turns on WiFi or goes to area with cellular
├─ SyncService.onConnectivityChanged() detects connection
│  └─ Was offline? YES, now online? YES
│  └─ Trigger: syncAll()

T5: ~09:30:05 AM
├─ SyncService.syncAll():
│  ├─ _processSyncQueue():
│  │   └─ Replay all 1 queued action:
│  │       POST /api/v1/doses/dose_abc123/mark-taken
│  │       with takenAt='2026-03-31T07:01:00Z'
│  │       ✓ Success 200 → DELETE from sync_queue
│  ├─ _pushUnsyncedDoses():
│  │   └─ UPDATE dose_events SET synced=1 WHERE synced=0
│  ├─ _pullDoseSchedule():
│  │   └─ GET /api/v1/doses/schedule?date=2026-03-31
│  │       → Fetch fresh schedule from server
│  │       → Replace local cache
│  ├─ _pullPrescriptions():
│  │   └─ Fetch any updated prescriptions
│  ├─ _pullBatches():
│  │   └─ Fetch any updated medication batches
│  └─ isSyncing = false
│     └─ notifyListeners() → UI shows "Synced ✓"

T6: UI confirms sync complete
├─ Show: "All changes synced"
├─ Badge count goes to 0
├─ Pending indicator disappears

DONE (Local data now matches server)
```

---

## Code Implementation Details

### Key Files & Line References

| File | Purpose | Key Methods | Lines |
|------|---------|------------|-------|
| `database_service.dart` | Local SQLite storage | `cacheDoseEvents()`, `getCachedDosesByDate()` | 50-622 |
| `notification_service.dart` | Schedule & handle notifications | `scheduleDoseWithRetries()`, `scheduleAllReminders()`, `processPendingActions()` | 61-761 |
| `sync_service.dart` | Monitor connectivity & auto-sync | `startListening()`, `syncAll()` | 15-347 |
| `dose_provider.dart` | Dose management state | `fetchTodaySchedule()`, `markDoseTaken()`, `processPendingNotificationActions()` | 11-343 |

### Summary Table: Where Data Lives

| Data Type | Storage Location | Online | Offline | Synced? | Auto-Clear |
|-----------|-----------------|--------|---------|---------|-----------|
| Dose Schedule | SQLite `dose_events` | ✅ Cached | ✅ Read | Flag | End of day |
| Sync Queue Actions | SQLite `sync_queue` | ✅ Processed | ✅ Queued | Flagged | On success |
| Prescriptions | SQLite `prescriptions` | ✅ Cached | ✅ Read | Flagged | On update |
| Health Vitals | SQLite `health_vitals` | ✅ Cached | ✅ Read | Flagged | Manual |
| JWT Token | FlutterSecureStorage | ✅ Encrypted | ✅ Encrypted | N/A | On logout |
| Language Pref | SharedPreferences | N/A | N/A | N/A | Never |
| Pending Actions | SharedPreferences | ✅ Processed | ✅ Queued | N/A | After process |

---

## Security & Best Practices

### ✅ Data Protection

1. **Encryption in Transit:** All API calls use HTTPS + TLS
2. **Encryption at Rest:** 
   - SQLite: Unencrypted but device-protected
   - Tokens: FlutterSecureStorage with OS-level encryption
3. **No Sensitive Data in Logs:** Passwords, tokens filtered out
4. **Timezone Consistency:** All times in UTC, converted to `Asia/Phnom_Penh` for display

### ✅ Offline Resilience

1. **No Data Loss:** SQLite cache persists across app restarts
2. **Automatic Sync:** Reconnection triggers `syncAll()` automatically
3. **Retry Logic:** Failed syncs retry with exponential backoff
4. **Conflict Resolution:** Server is always source of truth (local overwrites server on sync)

### ✅ Reminder Reliability

1. **Persistent Scheduling:** Notifications survive app restart/reboot
2. **Retry Strategy:** 3 attempts (0, 10, 20 min) ensures user sees reminder
3. **Device Reboot Support:** OS automatically reschedules on boot (via `ScheduledNotificationBootReceiver`)
4. **Batch Notifications:** Multiple doses at same time = 1 smart notification

