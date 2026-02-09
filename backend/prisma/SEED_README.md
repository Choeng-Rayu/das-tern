# Database Seed Data Documentation

## Overview

This seed script (`backend/prisma/seed.ts`) populates the database with comprehensive test data for development and testing purposes. The script is idempotent and can be run multiple times safely.

## Running the Seed Script

```bash
# From the backend directory
npm run db:seed

# Or directly with tsx
npx tsx prisma/seed.ts
```

## Seed Data Summary

### Users (11 total)

#### Patients (4)
1. **Sokha Chan** - Male, 34 years old
   - Phone: +85512345678
   - Email: sokha.chan@example.com
   - Subscription: FREEMIUM
   - Language: Khmer

2. **Sreymom Pich** - Female, 39 years old
   - Phone: +85512345679
   - Email: sreymom.pich@example.com
   - Subscription: PREMIUM
   - Language: Khmer

3. **Bopha Lim** - Female, 29 years old
   - Phone: +85512345682
   - Email: bopha.lim@example.com
   - Subscription: FAMILY_PREMIUM
   - Language: English

4. **Virak Heng** - Male, 46 years old
   - Phone: +85512345683
   - Email: virak.heng@example.com
   - Subscription: FREEMIUM
   - Language: Khmer

#### Doctors (4)
1. **Dr. Vanna Sok** - Internal Medicine, Calmette Hospital
   - Phone: +85512345680
   - Email: vanna.sok@hospital.com
   - Status: VERIFIED

2. **Dr. Sophea Meas** - Cardiology, Khmer-Soviet Friendship Hospital
   - Phone: +85512345684
   - Email: sophea.meas@hospital.com
   - Status: VERIFIED

3. **Dr. Ratana Chea** - Endocrinology, Royal Phnom Penh Hospital
   - Phone: +85512345685
   - Email: ratana.chea@hospital.com
   - Status: VERIFIED

4. **Dr. Kosal Rath** - General Practice, Sunrise Japan Hospital
   - Phone: +85512345686
   - Email: kosal.rath@hospital.com
   - Status: VERIFIED

#### Family Members (3)
1. **Dara Chan** - Connected to Sokha Chan
   - Phone: +85512345681
   - Email: dara.chan@example.com

2. **Chenda Pich** - Connected to Sreymom Pich
   - Phone: +85512345687
   - Email: chenda.pich@example.com

3. **Samnang Lim** - Connected to Bopha Lim
   - Phone: +85512345688
   - Email: samnang.lim@example.com

### Subscriptions (4)
- 2 FREEMIUM (5GB storage)
- 1 PREMIUM (20GB storage)
- 1 FAMILY_PREMIUM (20GB storage)

### Connections (8)
- 4 Doctor-Patient connections with different permission levels:
  - ALLOWED (2)
  - SELECTED (1)
  - REQUEST (1)
- 3 Family-Patient connections
- 1 Pending connection request

### Prescriptions (5)
1. **Active** - Sokha Chan (Hypertension)
   - 2 medications: Amlodipine, Paracetamol
   - Doctor: Dr. Vanna Sok

2. **Active** - Sreymom Pich (Diabetes)
   - 3 medications: Metformin, Ibuprofen, Vitamin D
   - Doctor: Dr. Sophea Meas
   - Version 2 (updated)

3. **Draft** - Bopha Lim (Fatigue)
   - 1 medication: Multivitamin
   - Doctor: Dr. Ratana Chea

4. **Active (Urgent)** - Virak Heng (Chest Pain)
   - 3 medications: Aspirin, Atorvastatin, Nitroglycerin
   - Doctor: Dr. Kosal Rath
   - Marked as urgent with reason

5. **Paused** - Sokha Chan (Stomach Pain)
   - 1 medication: Omeprazole
   - Doctor: Dr. Vanna Sok

### Medications (11)
All medications include:
- English and Khmer names
- Dosage schedules (morning, daytime, night)
- Before/after meal indicators
- Frequency information
- Some with image URLs

Examples:
- Amlodipine (អាមឡូឌីពីន) - Hypertension
- Metformin (មេតហ្វរមីន) - Diabetes
- Paracetamol (ប៉ារ៉ាសេតាម៉ុល) - Pain relief
- Aspirin (អាស្ពីរីន) - Heart health
- Nitroglycerin (នីត្រូគ្លីសេរីន) - PRN medication

### Prescription Versions (4)
- Version history tracking for prescription changes
- Includes change reasons and medication snapshots
- Demonstrates version control functionality

### Dose Events (15)
Various statuses demonstrating different scenarios:
- **TAKEN_ON_TIME** - Doses taken within the allowed window
- **TAKEN_LATE** - Doses taken after the window but before cutoff
- **MISSED** - Doses not taken by cutoff time
- **SKIPPED** - Doses intentionally skipped with reasons
- **DUE** - Upcoming doses not yet taken
- **Offline sync** - Dose recorded while offline (wasOffline: true)

Time periods:
- DAYTIME (ពេលថ្ងៃ) - Morning and afternoon doses
- NIGHT (ពេលយប់) - Evening doses

### Notifications (8)
Different notification types:
- CONNECTION_REQUEST - New connection requests
- PRESCRIPTION_UPDATE - New or updated prescriptions
- URGENT_PRESCRIPTION_CHANGE - Urgent prescription changes
- MISSED_DOSE_ALERT - Alerts to family members about missed doses
- FAMILY_ALERT - General family member notifications

### Audit Logs (13)
Comprehensive tracking of all actions:
- Connection requests and acceptances
- Prescription creation and updates
- Dose events (taken, skipped, missed)
- Permission changes
- Data access logs
- Notification deliveries
- Subscription changes

### Meal Time Preferences (4)
Sample meal time preferences for all patients:
- Morning: 6-7AM, 7-8AM, 8-9AM
- Afternoon: 12-1PM, 1-2PM
- Night: 6-7PM, 7-8PM, 8-9PM

## Login Credentials

All test users use the same credentials:
- **Password**: `password123`
- **PIN Code**: `1234`

### Quick Access Accounts

**Patient Account:**
- Phone: +85512345678
- Email: sokha.chan@example.com

**Doctor Account:**
- Phone: +85512345680
- Email: vanna.sok@hospital.com

**Family Member Account:**
- Phone: +85512345681
- Email: dara.chan@example.com

## Features Demonstrated

### 1. Multi-Language Support
- Khmer Unicode text in medication names and symptoms
- Both Khmer and English field values
- Language preferences per user

### 2. Cambodia Timezone
- All timestamps use Cambodia timezone (UTC+7)
- Dates formatted with +07:00 offset

### 3. Subscription Tiers
- FREEMIUM: 5GB storage
- PREMIUM: 20GB storage
- FAMILY_PREMIUM: 20GB storage with family sharing

### 4. Permission Levels
- ALLOWED: Full access
- SELECTED: Limited access to specific data
- REQUEST: Requires approval for each access
- NOT_ALLOWED: No access

### 5. Prescription Lifecycle
- DRAFT: Not yet active
- ACTIVE: Currently in use
- PAUSED: Temporarily stopped
- INACTIVE: Completed or cancelled

### 6. Dose Tracking
- Time window logic (on-time vs late)
- Missed dose detection
- Skip reasons
- Offline synchronization

### 7. Version Control
- Prescription version history
- Change reasons tracked
- Medication snapshots preserved

### 8. Audit Trail
- All actions logged
- Actor, action type, and timestamp recorded
- IP addresses tracked
- Immutable audit records

## Data Relationships

```
Users (11)
├── Patients (4)
│   ├── Subscriptions (4)
│   ├── Meal Preferences (4)
│   ├── Prescriptions (5)
│   │   ├── Medications (11)
│   │   ├── Versions (4)
│   │   └── Dose Events (15)
│   └── Connections (8)
├── Doctors (4)
│   └── Connections (4)
└── Family Members (3)
    └── Connections (3)

Notifications (8)
Audit Logs (13)
```

## Testing Scenarios

The seed data supports testing of:

1. **User Authentication**
   - Patient, Doctor, and Family Member login
   - Different language preferences
   - Different themes

2. **Connection Management**
   - Pending, accepted, and revoked connections
   - Different permission levels
   - Doctor-patient and family-patient relationships

3. **Prescription Management**
   - Creating and updating prescriptions
   - Version control
   - Urgent prescriptions
   - Draft and active states

4. **Medication Scheduling**
   - Multiple time periods (morning, daytime, night)
   - Before/after meal timing
   - PRN (as needed) medications
   - Khmer and English names

5. **Dose Tracking**
   - Taking doses on time
   - Late doses
   - Missed doses
   - Skipping doses with reasons
   - Offline synchronization

6. **Notifications**
   - Connection requests
   - Prescription updates
   - Missed dose alerts to family
   - Urgent changes

7. **Audit Logging**
   - All action types
   - System-generated logs
   - User-initiated actions

8. **Subscription Management**
   - Different tiers
   - Storage quotas
   - Family sharing

## Maintenance

To update the seed data:

1. Edit `backend/prisma/seed.ts`
2. Run `npm run db:seed` to apply changes
3. The script will clear existing data and recreate it

**Note**: This seed script is for development/testing only. Do not run in production!

## Verification

To verify the seed data was created successfully:

```bash
# Check user count
npx prisma studio

# Or query directly
docker exec dastern-postgres psql -U dastern_user -d dastern -c "SELECT COUNT(*) FROM users;"
```

Expected counts:
- Users: 11
- Subscriptions: 4
- Connections: 8
- Prescriptions: 5
- Medications: 11
- Dose Events: 15
- Notifications: 8
- Audit Logs: 13
