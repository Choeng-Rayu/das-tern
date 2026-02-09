# 🔄 Mobile App ↔ Backend Alignment Analysis

**Date**: 2026-02-09  
**Status**: ⚠️ MISALIGNMENT DETECTED

---

## 🔍 Critical Mismatches

### 1. API Base URL ❌

| Component | Current URL | Expected |
|-----------|-------------|----------|
| **Mobile App** | `http://localhost:3000/api` | Should be `http://localhost:3001/api/v1` |
| **Backend** | `http://localhost:3001/api/v1` | ✅ Correct |

**Impact**: Mobile app cannot connect to backend

**Fix Required**: Update mobile app `api_service.dart`

---

### 2. Data Model Mismatch ❌

#### Mobile App Expects:
```dart
// Simple Medication model
class Medication {
  int? id;
  String name;
  String dosage;
  String form;
  String? instructions;
  MedicationType type;
  MedicationStatus status;
  int frequency;
  List<String> reminderTimes;
}
```

#### Backend Provides:
```typescript
// Prescription with nested Medications
interface Prescription {
  id: string;
  patientId: string;
  doctorId: string;
  status: PrescriptionStatus;
  medications: Medication[]; // Array of medications
}

interface Medication {
  id: string;
  prescriptionId: string;
  medicineName: string;
  medicineNameKhmer: string;
  morningDosage: number;
  daytimeDosage: number;
  nightDosage: number;
  frequency: string; // "2ដង/១ថ្ងៃ"
  timing: string; // "មុនអាហារ"
}
```

**Impact**: Data structure incompatibility

---

### 3. Missing Endpoints ❌

Mobile app expects these endpoints that **DON'T EXIST** in backend:

| Mobile Expects | Backend Has | Status |
|----------------|-------------|--------|
| `POST /api/medications` | ❌ None | Missing |
| `GET /api/medications` | ❌ None | Missing |
| `PUT /api/medications/:id` | ❌ None | Missing |
| `POST /api/dose-events/sync` | ❌ None | Missing |
| `PUT /api/dose-events/:id` | ✅ `PATCH /api/v1/doses/:id/mark-taken` | Partial |

**Impact**: Mobile app API calls will fail

---

### 4. Endpoint Mapping

#### What Mobile Needs vs What Backend Has:

| Mobile Function | Mobile Endpoint | Backend Equivalent | Match? |
|-----------------|-----------------|-------------------|--------|
| Create medication | `POST /medications` | `POST /prescriptions` | ❌ Different |
| Get medications | `GET /medications` | `GET /prescriptions` | ❌ Different |
| Update medication | `PUT /medications/:id` | `PUT /prescriptions/:id` | ❌ Different |
| Sync dose events | `POST /dose-events/sync` | None | ❌ Missing |
| Update dose event | `PUT /dose-events/:id` | `PATCH /doses/:id/mark-taken` | ⚠️ Partial |
| Mark dose taken | None | `PATCH /doses/:id/mark-taken` | ✅ Backend only |
| Skip dose | None | `PATCH /doses/:id/skip` | ✅ Backend only |

---

## 🎯 Alignment Strategy

### Option A: Update Mobile App (Recommended)

**Pros**:
- Backend follows README spec correctly
- Backend has complete business logic
- Backend is production-ready

**Cons**:
- More mobile code changes needed

**Changes Required**:
1. Update API base URL to `http://localhost:3001/api/v1`
2. Replace `Medication` model with `Prescription` model
3. Update API service to use prescription endpoints
4. Add dose marking endpoints (mark-taken, skip)
5. Remove sync endpoint (use individual updates)

---

### Option B: Add Compatibility Layer to Backend

**Pros**:
- Minimal mobile app changes
- Backward compatibility

**Cons**:
- Duplicate endpoints
- Maintenance overhead
- Not following README spec

**Changes Required**:
1. Add `/api/v1/medications` endpoints (wrapper around prescriptions)
2. Add `/api/v1/dose-events/sync` batch endpoint
3. Add data transformation layer

---

## ✅ Recommended Solution

**Use Option A: Update Mobile App**

The backend correctly implements the README specification with:
- ✅ Prescription-based architecture
- ✅ Doctor-patient connection flow
- ✅ Permission system
- ✅ Versioning
- ✅ Dose event generation
- ✅ Time window logic
- ✅ Khmer language support

The mobile app needs to align with this architecture.

---

## 🔧 Required Mobile App Changes

### 1. Update API Service

**File**: `lib/services/api_service.dart`

```dart
class ApiService {
  // Change base URL
  final String baseUrl = 'http://localhost:3001/api/v1';
  
  // Replace medication endpoints with prescription endpoints
  Future<Prescription> createPrescription(Prescription prescription) async {
    final response = await http.post(
      Uri.parse('$baseUrl/prescriptions'),
      headers: headers,
      body: jsonEncode(prescription.toJson()),
    );
    return Prescription.fromJson(jsonDecode(response.body));
  }
  
  Future<List<Prescription>> getPrescriptions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions'),
      headers: headers,
    );
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Prescription.fromJson(json)).toList();
  }
  
  // Add dose marking endpoints
  Future<DoseEvent> markDoseTaken(String doseId, DateTime takenAt) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/doses/$doseId/mark-taken'),
      headers: headers,
      body: jsonEncode({'takenAt': takenAt.toIso8601String()}),
    );
    return DoseEvent.fromJson(jsonDecode(response.body));
  }
  
  Future<DoseEvent> skipDose(String doseId, String reason) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/doses/$doseId/skip'),
      headers: headers,
      body: jsonEncode({'reason': reason}),
    );
    return DoseEvent.fromJson(jsonDecode(response.body));
  }
}
```

---

### 2. Add Prescription Model

**File**: `lib/models/prescription_model/prescription.dart`

```dart
class Prescription {
  final String? id;
  final String patientId;
  final String? doctorId;
  final String patientName;
  final String patientGender;
  final int patientAge;
  final String symptoms;
  final PrescriptionStatus status;
  final List<Medication> medications;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ... toJson, fromJson methods
}

class Medication {
  final String? id;
  final String prescriptionId;
  final int rowNumber;
  final String medicineName;
  final String medicineNameKhmer;
  final String? imageUrl;
  final double morningDosage;
  final double daytimeDosage;
  final double nightDosage;
  final String frequency; // "2ដង/១ថ្ងៃ"
  final String timing; // "មុនអាហារ"
  
  // ... toJson, fromJson methods
}
```

---

### 3. Update Dose Event Model

**File**: `lib/models/dose_event_model/dose_event.dart`

```dart
class DoseEvent {
  final String? id;
  final String prescriptionId;
  final String medicationId;
  final String patientId;
  final DateTime scheduledTime;
  final String timePeriod; // "DAYTIME" or "NIGHT"
  final DateTime reminderTime;
  final DoseStatus status; // "DUE", "TAKEN_ON_TIME", "TAKEN_LATE", "MISSED", "SKIPPED"
  final DateTime? takenAt;
  final String? skipReason;
  final bool wasOffline;
  
  // ... toJson, fromJson methods
}
```

---

### 4. Update Providers

**File**: `lib/providers/medication_provider.dart` → Rename to `prescription_provider.dart`

```dart
class PrescriptionProvider extends ChangeNotifier {
  List<Prescription> _prescriptions = [];
  
  Future<void> loadPrescriptions() async {
    _prescriptions = await ApiService.instance.getPrescriptions();
    notifyListeners();
  }
  
  Future<void> createPrescription(Prescription prescription) async {
    final created = await ApiService.instance.createPrescription(prescription);
    _prescriptions.add(created);
    notifyListeners();
  }
}
```

---

### 5. Update UI Screens

**Files to Update**:
- `patient_dashboard_screen.dart` - Use prescriptions instead of medications
- `create_medication_screen.dart` - Rename to `create_prescription_screen.dart`
- `medication_detail_screen.dart` - Update to show prescription details
- All other screens referencing medications

---

## 📊 Backend Endpoints Reference

### Authentication
- `POST /api/v1/auth/register` - Register user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - Logout

### Users
- `GET /api/v1/users/profile` - Get profile
- `PATCH /api/v1/users/profile` - Update profile
- `GET /api/v1/users/storage` - Get storage info
- `GET /api/v1/users/daily-progress` - Get daily progress

### Prescriptions
- `POST /api/v1/prescriptions` - Create prescription
- `GET /api/v1/prescriptions` - List prescriptions
- `GET /api/v1/prescriptions/:id` - Get prescription
- `PUT /api/v1/prescriptions/:id` - Update prescription
- `POST /api/v1/prescriptions/:id/confirm` - Confirm prescription (generates doses)
- `DELETE /api/v1/prescriptions/:id` - Delete prescription

### Doses
- `GET /api/v1/doses/schedule` - Get dose schedule
- `GET /api/v1/doses/history` - Get dose history
- `PATCH /api/v1/doses/:id/mark-taken` - Mark dose taken
- `PATCH /api/v1/doses/:id/skip` - Skip dose

### Connections
- `POST /api/v1/connections` - Create connection
- `GET /api/v1/connections` - List connections
- `PATCH /api/v1/connections/:id/accept` - Accept connection
- `PATCH /api/v1/connections/:id/permission` - Update permission
- `DELETE /api/v1/connections/:id` - Revoke connection

### Notifications
- `GET /api/v1/notifications` - List notifications
- `PATCH /api/v1/notifications/:id/read` - Mark as read

### Subscriptions
- `GET /api/v1/subscriptions/current` - Get current subscription
- `POST /api/v1/subscriptions/upgrade` - Upgrade subscription

### Audit
- `GET /api/v1/audit/logs` - Get audit logs

---

## 🚀 Implementation Priority

### Phase 1: Critical Fixes (Required for MVP)
1. ✅ Update API base URL
2. ✅ Add Prescription model
3. ✅ Update API service
4. ✅ Update providers
5. ✅ Update dashboard screen

### Phase 2: Feature Alignment
1. ⏳ Add connection management UI
2. ⏳ Add permission settings UI
3. ⏳ Add prescription confirmation flow
4. ⏳ Add dose marking UI

### Phase 3: Advanced Features
1. ⏳ Add offline sync logic
2. ⏳ Add notification handling
3. ⏳ Add subscription management
4. ⏳ Add audit log viewer

---

## 📝 Summary

**Current State**: Mobile app and backend are **NOT ALIGNED**

**Root Cause**: Mobile app was built with simplified architecture, backend follows complete README spec

**Solution**: Update mobile app to match backend architecture

**Effort**: ~2-3 days of mobile development

**Benefit**: Full feature parity with README specification

---

**Next Steps**: 
1. Update mobile app API service (30 min)
2. Add Prescription model (1 hour)
3. Update providers (1 hour)
4. Update UI screens (4-6 hours)
5. Test integration (2 hours)

**Total Estimated Time**: 8-10 hours
