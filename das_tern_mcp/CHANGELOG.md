# Das Tern — Patient UI Development Changelog

> Branch: `elite`
> Scope: Patient-facing UI only (`lib/ui/screens/patient/`, `lib/ui/screens/family_ui/`, shared widgets)
> Doctor screens were never modified.

---

## Table of Contents

1. [Animated Dose Task List](#1-animated-dose-task-list)
2. [Checklist Revert Bug Fix](#2-checklist-revert-bug-fix)
3. [Medicine Form — Auto Time Slot Selection](#3-medicine-form--auto-time-slot-selection)
4. [Delete Prescription](#4-delete-prescription)
5. [Dose Toggle (Un-check Completed Doses)](#5-dose-toggle-un-check-completed-doses)
6. [Back Button Removed from Main Tabs](#6-back-button-removed-from-main-tabs)
7. [Medicine Intake Progress — Full-Day Only](#7-medicine-intake-progress--full-day-only)
8. [Fix Medication Time Showing 0:00](#8-fix-medication-time-showing-000)
9. [Today's Tasks Grouped by Time Period](#9-todays-tasks-grouped-by-time-period)
10. [Files Changed Summary](#10-files-changed-summary)

---

## 1. Animated Dose Task List

**Files:** `lib/ui/widgets/dose_task_card.dart` *(new)*, `patient_home_tab.dart`, `patient_medications_tab.dart`

### What was built

A fully animated `DoseTaskCard` widget shared between the home tab and the medications tab period view.

**Features:**
- Animated circular checkbox — animates from white → green over 300 ms when a dose is marked taken
- `AnimatedOpacity` dims the card to 65% opacity once completed
- Tap the card body → opens `DoseDetailSheet` bottom modal showing:
  - Medication name + Khmer name
  - Scheduled time and period (Morning / Afternoon / etc.)
  - Dosage
  - "Mark as Taken" button
- **"Mark All Done"** button appears in the header when there are 2+ pending doses — opens a bottom sheet with a checkbox list so the user can batch-confirm multiple doses at once
- **Collapsible completed section** — a labelled `ExpansionTile` (`Completed (N)`) collapses all done doses to keep the screen tidy

---

## 2. Checklist Revert Bug Fix

**File:** `lib/providers/dose_provider.dart`

### Problem

After tapping a dose card to mark it taken, the card would briefly animate green then snap back to unchecked.

### Root Cause

`markTaken()` applied an optimistic in-memory update (status → TAKEN), then called `fetchTodaySchedule(quietly: true)`. That re-fetch failed silently, fell back to the SQLite cache which still held the old `DUE` status, and overwrote the optimistic state — causing the visible revert.

### Fix

- Added `_applyStatusUpdate(doseId, status)` helper that immediately updates `_todaysDoses` and `_groupedDoses` in memory and calls `notifyListeners()`.
- Removed `fetchTodaySchedule(quietly: true)` from both `markTaken` and `skipDose` entirely.
- Added `{bool quietly = false}` parameter to `fetchTodaySchedule` to suppress the loading spinner on background refresh calls without triggering a cache fallback overwrite.

---

## 3. Medicine Form — Auto Time Slot Selection

**File:** `lib/ui/widgets/medicine_form_widget.dart`

### What was built

When creating a medication, pressing the frequency `+` stepper now automatically enables the next logical time slot instead of requiring the user to manually tick each period.

**Logic:**
- `_autoEnableNextSlot()` enables Morning → Afternoon → Night → Evening in order each time `+` is pressed
- `_submit()` fallback: if frequency > 0 but the user still hasn't selected any time slots, it auto-populates N slots from the default order with their default times
- Each time period has a `TimeOfDay` state variable with sensible defaults (Morning 08:00, Afternoon 13:00, Night 21:00, Evening 18:00)
- `_SlotTimeTile` widget — tapping the time badge opens the system `TimePicker`

---

## 4. Delete Prescription

**Files:** `patient_medications_tab.dart`, `app_en.arb`, `app_km.arb`

### What was built

A delete option on each prescription card in the Medications tab.

**Features:**
- Red trash icon (`Icons.delete_outline`) in the top-right corner of every ACTIVE and DRAFT prescription card
- Tapping shows an `AlertDialog` asking for confirmation before deleting
- On confirm: calls `PrescriptionProvider.deletePrescription(id)`, then refreshes the dose schedule so deleted medications no longer appear in the checklist
- On failure: shows a red `SnackBar` with the error message

**New ARB strings added:**
| Key | English |
|---|---|
| `deletePrescription` | Delete Prescription |
| `deletePrescriptionConfirm` | Are you sure you want to delete this prescription? |
| `prescriptionDeleted` | Prescription deleted successfully |

---

## 5. Dose Toggle (Un-check Completed Doses)

**Files:** `dose_task_card.dart`, `dose_provider.dart`, `api_service.dart`, `app_en.arb`, `app_km.arb`

### What was built

Dose card checkboxes are now toggleable — tapping a completed dose reverses it back to pending.

**How it works:**
- `handleCheck()` in `DoseTaskCard` checks current status:
  - **Pending → Taken:** animates checkbox forward (white → green), calls `DoseProvider.markTaken(id)`
  - **Taken → Pending:** animates checkbox backward (green → white), calls `DoseProvider.markUntaken(id)`
- Completed dose cards in the "Completed" `ExpansionTile` section are also clickable (the `readOnly` restriction was removed from checkbox `onTap`)
- `DoseDetailSheet` shows a **"Mark as Pending"** `OutlinedButton` (orange) for completed doses in addition to the "Mark as Taken" button for pending ones
- `DoseProvider.markUntaken(doseId)` applies an optimistic `_applyStatusUpdate(id, 'DUE')` immediately, then calls `PATCH /doses/:id/reset` best-effort (gracefully handles the case where the backend hasn't implemented this endpoint yet)
- `ApiService.resetDose(id)` — new method added for this endpoint

**New ARB strings added:**
| Key | English |
|---|---|
| `markAsPending` | Mark as Pending |

---

## 6. Back Button Removed from Main Tabs

**Files:** `lib/ui/widgets/header_widgets.dart`, `patient_home_tab.dart`, `patient_medications_tab.dart`

### Problem

The back button (← arrow) was appearing in the app bar of the Home and Medications main tabs because `Navigator.canPop(context)` returned `true` after navigating to the `PatientShell` from the login screen. Tapping the back button led nowhere useful.

### Fix

- Added `showBackButton: bool?` parameter to `PatientHeader`:
  - `null` (default) — auto-detect using `Navigator.canPop(context)` (keeps back button on sub-screens, e.g., Emergency, OCR Preview)
  - `false` — never show back button (used on main tab screens)
  - `true` — always show back button
- `PatientHomeTab` and `PatientMedicationsTab` both now pass `showBackButton: false`
- Sub-screens that navigate via `Navigator.push` continue to auto-detect, so their back buttons remain intact

---

## 7. Medicine Intake Progress — Full-Day Only

**Files:** `dose_provider.dart`, `patient_home_tab.dart`

### Problem

The circular progress indicator on the Home tab was advancing with every single dose taken, so checking off 1 out of 5 medications would move the ring 20%. The user wanted the progress to only advance when an **entire day's worth of medications** is completed.

### Fix

Added a new getter `effectiveDailyProgressCount` to `DoseProvider`:

```dart
int get effectiveDailyProgressCount =>
    _dailyProgress +
    (totalDoses > 0 && takenDoses == totalDoses ? 1 : 0);
```

- `_dailyProgress` is the server-reported count of previously completed full days (from the API response field `dailyProgress`)
- The `+1` is only added when **every** dose for today has been taken
- `monthlyProgress` (used by the circular indicator) is now computed from `effectiveDailyProgressCount / 30.0` instead of the per-dose ratio
- The day counter label and the circular ring both stay at their previous value until all of today's doses are done — then they jump by exactly 1

---

## 8. Fix Medication Time Showing 0:00

**File:** `lib/models/dose_event_model/dose_event.dart`

### Problem

Medication cards and the detail sheet were showing `00:00` as the scheduled time for all doses. The backend stores `scheduledTime` as UTC start-of-Cambodia-day (e.g., `2026-03-14T17:00:00Z` = Cambodia midnight), while the actual clock time for the dose is stored separately in `dosage.time` (e.g., `"07:00"`).

### Fix

Replaced the direct `DateTime.parse(scheduledTime)` call in `DoseEvent.fromJson` with a new static helper `_parseScheduledTime(json)`:

1. Parses the raw `scheduledTime` string and converts to local timezone
2. **If `dosage.time` is present** (e.g. `"07:00"`), always applies it as the H:MM over the local calendar date — this is the authoritative scheduled time
3. **If no `dosage.time`** and the local time resolves to midnight, falls back to period defaults:
   - MORNING → 08:00
   - AFTERNOON → 13:00
   - EVENING → 18:00
   - NIGHT → 21:00
4. Returns a local `DateTime` so `.hour` / `.minute` in the display layer are always correct

---

## 9. Today's Tasks Grouped by Time Period

**File:** `patient_home_tab.dart`

### What was built

The flat list of today's pending doses is now organized into named time-period sections that only appear when they contain doses. Empty periods take zero space.

**Section layout:**
```
🌅 Morning
  ┌─────────────────────────────────┐
  │ Metformin  500mg         07:00  │
  │ Aspirin    100mg         08:00  │
  └─────────────────────────────────┘

☀️ Afternoon
  ┌─────────────────────────────────┐
  │ Metformin  500mg         13:00  │
  └─────────────────────────────────┘

🌙 Night
  ┌─────────────────────────────────┐
  │ Metformin  500mg         21:00  │
  └─────────────────────────────────┘

▼ Completed (2)
  [collapsed]
```

**Period header styling:**

| Period | Icon | Color |
|---|---|---|
| Morning | `wb_twilight` | Amber `#FFA726` |
| Afternoon | `wb_sunny` | Yellow `#FFD600` |
| Evening | `wb_cloudy_outlined` | Orange-Red `#FF7043` |
| Night | `bedtime` | Indigo `#5C6BC0` |

**Other behaviour:**
- "Mark All Done" button still works — it flattens all pending doses across all periods into one confirm sheet
- Completed doses remain in a single collapsible `ExpansionTile` at the bottom regardless of period
- `_PeriodSectionHeader` is a private widget at the bottom of `patient_home_tab.dart`

---

## 10. Files Changed Summary

| File | Change type | Description |
|---|---|---|
| `lib/ui/widgets/dose_task_card.dart` | **New** | Animated dose card, toggle, detail sheet |
| `lib/ui/screens/patient/tab/patient_home_tab.dart` | Modified | Period-grouped tasks, progress fix, `showBackButton: false` |
| `lib/ui/screens/patient/tab/patient_medications_tab.dart` | Modified | DoseTaskCard integration, delete prescription, `showBackButton: false` |
| `lib/providers/dose_provider.dart` | Modified | `_applyStatusUpdate`, `markUntaken`, `dailyProgress`, `effectiveDailyProgressCount` |
| `lib/models/dose_event_model/dose_event.dart` | Modified | `_parseScheduledTime`, defensive JSON parsing, `toJson()` |
| `lib/services/api_service.dart` | Modified | `resetDose(id)` — `PATCH /doses/:id/reset` |
| `lib/ui/widgets/header_widgets.dart` | Modified | `showBackButton: bool?` parameter |
| `lib/ui/widgets/medicine_form_widget.dart` | Modified | `_autoEnableNextSlot`, time pickers, `_SlotTimeTile` |
| `lib/l10n/app_en.arb` | Modified | Added: `deletePrescription`, `markAsPending`, `markAllDone`, `completedCount`, `noPendingDoses`, `selectDosesToMark` |
| `lib/l10n/app_km.arb` | Modified | Khmer translations for all new strings |
| `lib/l10n/app_localizations*.dart` | Regenerated | Auto-generated from ARB files via `flutter gen-l10n` |
