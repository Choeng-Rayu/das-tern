# Backend-Database Spec Updates

## Summary

I've reviewed the backend-database spec against the project documentation in `/docs/about_das_tern/` and identified several gaps. The spec has been updated to align with the documented requirements.

## Key Updates Made

### 1. **Requirement 6: Prescription Schema** ✅
- Added clarification that `patientGender` is an enum snapshot at creation
- Added composite index `(patientId, status)` for better query performance
- Added unique constraint on `(prescriptionId, versionNumber)` for version control
- Emphasized support for PRN (as needed) medications

### 2. **Requirement 8: Audit Log** ✅
- Added requirement to record urgent prescription changes with full context
- Added requirement to record offline sync events with late notification indicators
- Added index on `actionType` for better filtering
- Clarified that `actorRole` is nullable to support system actions

### 3. **Requirement 11: Meal Time Preferences** ✅
- Added default Cambodia timezone presets (07:00 AM, 12:00 PM, 06:00 PM, 09:00 PM)
- Added requirement to use preferences for PRN medications
- Added requirement to apply defaults when user hasn't configured custom times

### 4. **NEW Requirement 35: Offline Sync Support** ✅
- Added comprehensive offline sync requirements
- Batch sync endpoint for offline actions
- Conflict detection and resolution
- Late notification handling for family alerts
- Idempotency for sync operations
- Support for up to 100 actions per batch

### 5. **Requirement 35 → 36: Monitoring** ✅
- Renumbered due to new requirement insertion
- Added metrics for offline sync success rate
- Added tracking for late notification delivery

### 6. **NEW Requirement 41: Urgent Prescription Auto-Apply** ✅
- Auto-apply urgent prescription changes without patient confirmation
- Store urgent flag and reason
- Immediate notification to patient
- Full audit trail with context
- Validate doctor permissions

### 7. **NEW Requirement 42: Connection Mutual Acceptance** ✅
- Support both doctor-initiated and patient-initiated connections
- Mutual acceptance required from both parties
- Patient controls permission levels (regardless of who initiated)
- Default permission level: ALLOWED (history/report view)
- Permission levels: NOT_ALLOWED, REQUEST, SELECTED, ALLOWED
- Connection revocation support

### 8. **NEW Requirement 43: Family Connection & Missed Dose Alerts** ✅
- Family connection flow with mutual acceptance
- Missed dose alerts to connected family members
- Immediate alerts when online
- Late alerts after offline sync with indicator
- Mutual view of history records (permission-controlled)
- Connection revocation with immediate access removal

## Alignment with Documentation

The spec now properly reflects:

### From `business_logic/README.md`:
- ✅ Patient ownership principle
- ✅ Two-way connection acceptance (doctor or patient initiated)
- ✅ Permission enum: NOT_ALLOWED, REQUEST, SELECTED, ALLOWED
- ✅ Default permission behavior
- ✅ Prescription versioning (no destructive edits)
- ✅ Urgent auto-apply with audit trail
- ✅ Dose event states and time windows
- ✅ Offline reminder support
- ✅ PRN medication with default times
- ✅ Family missed-dose alerts (online and offline)
- ✅ Subscription tiers and storage quotas

### From `flows/doctor_send_prescription_to_patient_flow/`:
- ✅ Doctor-initiated connection flow
- ✅ Patient-initiated connection flow
- ✅ Normal prescription modification flow
- ✅ Urgent auto-apply prescription flow
- ✅ Permission control after connection

### From `flows/family_connection_flow/`:
- ✅ Family invitation and acceptance
- ✅ Missed-dose alert delivery (online/offline)
- ✅ Shared history view with permissions
- ✅ Connection revocation

### From `flows/reminder_flow/`:
- ✅ Offline reminder delivery
- ✅ Offline action sync queue
- ✅ Late family notifications after reconnect
- ✅ Dual storage (backend + local device)

### From `flows/create_medication_flow/`:
- ✅ PRN medication support
- ✅ Default Cambodia timezone presets
- ✅ Draft vs Active prescription states

## Database Schema Alignment

The existing Prisma schema in `backend/prisma/schema.prisma` already implements most requirements correctly:

✅ All enums match the spec
✅ User table with all required fields
✅ Connection table with proper relationships
✅ Prescription and PrescriptionVersion tables
✅ Medication table with JSONB dosage fields
✅ DoseEvent table with offline support (`wasOffline` flag)
✅ Notification table with proper types
✅ AuditLog table with flexible details
✅ Subscription and FamilyMember tables
✅ MealTimePreference table

## What Still Needs Implementation

The spec is now complete and aligned with documentation. The following need to be implemented in code:

1. **API Endpoints** for:
   - Offline sync batch processing (`/api/sync/batch`)
   - Connection mutual acceptance flow
   - Urgent prescription auto-apply
   - Family missed-dose alert delivery

2. **Service Layer** for:
   - Offline sync conflict resolution
   - Late notification handling
   - Permission level enforcement
   - Urgent prescription processing

3. **Business Logic** for:
   - PRN default time calculation
   - Dose window time calculations
   - Offline action queue processing
   - Family alert escalation rules

## Next Steps

1. Review and approve these spec updates
2. Begin implementation of missing API endpoints
3. Implement service layer business logic
4. Add comprehensive tests for offline sync
5. Add tests for urgent prescription flow
6. Add tests for connection mutual acceptance

## Notes

- The spec now has 43 requirements (was 40)
- All requirements are traceable to documentation
- Database schema is already well-aligned
- Focus should be on implementing the service layer and API endpoints
