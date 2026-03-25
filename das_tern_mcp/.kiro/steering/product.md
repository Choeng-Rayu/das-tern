# Product Overview

Das Tern (ដាស ទឺន) is a medication management platform for Cambodia that helps patients track medication adherence and enables doctors to monitor their patients remotely.

## Core Users

- **Patients**: Manage medications, track adherence, record vitals, grant caregiver access
- **Doctors**: Monitor patients, create prescriptions, view adherence analytics
- **Caregivers**: View patient doses and vitals with granted access levels

## Key Features

- Medication tracking with dose reminders (morning/afternoon/night)
- Offline-first architecture with automatic sync
- OCR prescription scanning
- Health vitals monitoring (BP, glucose, weight, temperature, SpO₂)
- Family/caregiver access management with QR code connection
- Bakong payment integration for subscriptions
- Bilingual support (English/Khmer)

## Backend

NestJS REST API at `/api/v1` with JWT authentication and automatic token refresh.
