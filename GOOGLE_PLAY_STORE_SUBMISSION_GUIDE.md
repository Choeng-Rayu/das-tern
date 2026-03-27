# Google Play Store Submission Guide - Das Tern

## App Access Information for Google Play Console

This document provides all required information for submitting Das Tern (ដាស់ទើន) to the Google Play Store.

---

## 1. App Overview

App Name: Das Tern (ដាស់ទើន)  
Package Name: com.dastern.mcp  
Category: Medical / Health & Fitness  
Content Rating: Everyone  
Target Audience: Patients and Healthcare Providers in Cambodia

Description:  
Das Tern is a comprehensive medication management platform designed for Cambodia. The application enables patients to track medication schedules, manage prescriptions, monitor health vitals, and connect with family caregivers. Healthcare providers can monitor patient adherence and create digital prescriptions.

---

## 2. App Access Requirements

## 2. App Access Requirements

Authentication Required: Yes

Das Tern requires user registration and login to access the application. Users must create an account to utilize any features.

2.1 Available Login Methods

Method 1: Email/Phone and Password
- Users can register using an email address or phone number
- Password must be at least 6 characters in length
- OTP verification is required for phone-based registration

Method 2: Google OAuth Sign-In
- Single sign-on using Google account credentials
- No password required
- Account is automatically created upon first authentication

---

## 3. Test Account Credentials for Google Play Review

3.1 Patient Test Account

Email: testpatient@dastern.com  
Password: Test123456  
Role: PATIENT

Reviewers can test the following functionality:
- Medication dashboard viewing
- Daily medication schedule tracking
- Health vitals recording (blood pressure, glucose, weight, temperature, oxygen saturation)
- Adherence statistics and chart visualization
- Prescription QR code scanning
- Medication batch creation
- Family caregiver connection management
- Subscription plan management

3.2 Doctor Test Account

Email: testdoctor@dastern.com  
Password: Test123456  
Role: DOCTOR

Reviewers can test the following functionality:
- Doctor dashboard with patient statistics
- Patient list browsing
- Patient detail and adherence data viewing
- Digital prescription creation
- Patient health vital monitoring
- Prescription history review

---

## 4. Additional Access Information

4.1 Authentication Methods Not Required

The application does NOT require:
- Two-step verification (optional feature, not mandatory)
- QR codes for login authentication
- Hardware security tokens
- Biometric authentication (fingerprint or facial recognition)
- SMS verification codes for login (only used during registration)

4.2 Demo Mode Availability

The application does not provide a guest mode or demonstration mode. All features require user authentication.

4.3 Authentication Bypass

There is no mechanism to bypass the login screen. Users must either:
1. Create a new account using email/phone and password
2. Authenticate using Google OAuth
3. Use the provided test credentials listed in Section 3

---

## 5. Supported Languages

- English (en): Full support
- Khmer (km): Full support with native Khmer font (NotoSansKhmer)

Users can switch languages from the Settings interface.

---

## 6. Deep Links and QR Code Functionality

6.1 QR Code Usage (Not for Authentication)

The application utilizes QR codes for the following features:
- Family Connection: Patients generate QR codes to allow family members or caregivers to connect and monitor medication schedules
- Prescription Scanning: Scan prescription QR codes to import medication information
- Payment Processing: Display Bakong payment QR codes for subscription upgrades

Important Note: QR codes are NOT used for authentication or login purposes.

---

## 7. Application Features Overview

7.1 Patient Features

Medication Tracking:
- Daily medication schedule with reminder notifications
- Mark medications as taken, skipped, or missed
- Offline support with automatic synchronization

Health Monitoring:
- Record vital signs (blood pressure, glucose, weight, temperature, SpO₂)
- View trend charts and historical data
- Set personal alert thresholds
- Emergency contact management

Prescription Management:
- OCR prescription scanning using device camera
- Manual medication entry
- Batch tracking for medicine inventory
- View active and historical prescriptions

Family and Caregiver Access:
- Generate secure connection tokens
- Grant read-only or full access permissions to caregivers
- Revoke access at any time
- Configure grace period settings

Subscription Plans:
- Freemium plan (basic features)
- Premium plan (unlimited prescriptions, family access)
- Platinum plan (advanced analytics, priority support)
- Bakong payment system integration

7.2 Doctor Features

Patient Management:
- View patient list with search and filter capabilities
- Monitor patient adherence statistics
- View patient health vitals and trend analysis

Prescription Creation:
- Create digital prescriptions
- Multi-medication support
- Configure dosage, frequency, and time periods
- Add instructions and clinical notes

Dashboard Analytics:
- Total patient count
- Active prescription tracking
- Pending connection requests
- Daily health alert monitoring

---

## 8. Privacy and Security

8.1 Data Storage

- Encrypted Token Storage: JWT tokens stored using Android EncryptedSharedPreferences and iOS Keychain
- HTTPS Protocol: All API communication uses HTTPS encryption
- Local Database: SQLite database for offline data caching
- Secure Storage: flutter_secure_storage implementation for sensitive data

8.2 Required Permissions

- Camera: For prescription OCR scanning and QR code scanning
- Storage: For saving prescription images and reports
- Internet: For API communication and data synchronization
- Notifications: For medication reminder alerts

8.3 Data Collection

- User profile information (name, email, phone number)
- Health data (vitals, medications, prescriptions)
- Usage analytics (anonymized)
- No data is shared with third parties without explicit user consent

---

## 9. Geographic Availability

Primary Market: Cambodia  
Supported Languages: Khmer (km) and English (en)  
Currency: USD (for subscription payments)  
Payment Method: Bakong (Cambodia's national payment system)

---

## 10. Support and Contact Information

Developer: Das Tern Team  
Support Email: support@dastern.com  
Website: https://dastern.com  
Privacy Policy: [Your Privacy Policy URL]  
Terms of Service: [Your Terms of Service URL]

---

## 11. Technical Specifications

11.1 Minimum Requirements

- Android: Version 5.0 (API level 21) or higher
- iOS: Version 12.0 or higher
- Storage: 50 MB minimum
- Internet: Required for initial setup and synchronization

11.2 Development Framework

- Flutter SDK: Version 3.10.7 or higher
- Dart: Version 3.0 or higher

11.3 Backend Infrastructure

- API: NestJS REST API
- Database: PostgreSQL
- Storage: MinIO (S3-compatible)
- Cache: Redis
- Message Queue: RabbitMQ

---

## 12. Testing Instructions for Google Play Reviewers

Step 1: Installation and Launch
1. Install the application from the Google Play Store
2. Launch the application to view the splash screen followed by the login interface

Step 2: Authentication with Test Account

Option A - Patient Account:
Email: testpatient@dastern.com  
Password: Test123456

Option B - Doctor Account:
Email: testdoctor@dastern.com  
Password: Test123456

Step 3: Feature Exploration

For Patient Account:
1. Home Tab: View today's medication schedule
2. Medications Tab: Browse active prescriptions and medications
3. Scan Tab: Test camera access for QR scanning (optional)
4. Family Tab: View family connection features
5. Settings Tab: Change language (English to Khmer), theme (Light to Dark)

For Doctor Account:
1. Home Tab: View dashboard statistics
2. Patients Tab: Browse patient list
3. Prescriptions Tab: View active prescriptions
4. Settings Tab: Change language and theme preferences

Step 4: Core Functionality Testing
- Navigation between application tabs
- Language switching (English to Khmer)
- Theme switching (Light to Dark mode)
- View medication and prescription lists
- View charts and statistical data
- Logout and re-authentication

---

## 13. Important Notes for Reviewers

1. Internet Connection: The application requires an active internet connection for most features. Offline mode is available for viewing cached data.

2. Test Data: The test accounts contain sample data for demonstration purposes. All data is reset periodically.

3. Camera Permission: If testing QR code scanning functionality, please grant camera permission when prompted by the system.

4. Notifications: Local notifications are used for medication reminders. These are scheduled locally and do not require internet connectivity.

5. Data Privacy: Test accounts do not contain any real patient data or personal health information.

6. Language Support: The application fully supports Khmer language with proper font rendering. Switch language from Settings to verify functionality.

---

## 14. Google Play Console Form Response

For the field "Any other information required to access your app", please use the following text:

---

Das Tern requires user authentication to access all application features.

TEST CREDENTIALS FOR REVIEW:

Patient Account:
Email: testpatient@dastern.com
Password: Test123456

Doctor Account:
Email: testdoctor@dastern.com
Password: Test123456

AUTHENTICATION METHODS:
1. Email or Phone Number with Password (standard authentication)
2. Google OAuth Sign-In (single sign-on authentication)

ADDITIONAL INFORMATION:
- Two-step verification is not required for test accounts
- QR codes and biometric authentication are not required for login
- QR codes are used exclusively for family connections and prescription scanning, not for authentication
- Application requires internet connection for initial login and data synchronization
- Offline mode is available for viewing cached data
- Camera permission is required for prescription OCR scanning and QR code features
- Local notifications are used for medication reminders

LANGUAGE SUPPORT:
- English (en)
- Khmer (km) with full native support

The application is designed specifically for the Cambodian market with Bakong payment integration for subscription upgrades.

For any issues during the review process, please contact: support@dastern.com

---

## 15. Pre-Submission Checklist

Required Items:
- Test accounts are active and functional
- Privacy Policy URL is valid and accessible
- Terms of Service URL is valid and accessible
- Application screenshots prepared (phone and tablet formats)
- Feature graphic prepared (1024 x 500 pixels)
- Application icon prepared (512 x 512 pixels)
- Short description written (maximum 80 characters)
- Full description written (maximum 4000 characters)
- Content rating questionnaire completed
- Target audience selected
- Application category selected (Medical / Health & Fitness)
- Pricing configuration set (Free with in-app purchases)
- Countries and regions selected (Cambodia and additional markets)
- APK or AAB uploaded and tested
- All required permissions declared in manifest
- Crash-free rate exceeds 99 percent

---

## 16. Summary

Das Tern is a medication management application that requires user authentication for access. Reviewers can utilize the provided test credentials to access and evaluate all features. The application supports both English and Khmer languages, includes offline functionality, and integrates with Cambodia's Bakong payment system for subscription management.

No additional setup or configuration is required beyond using the test credentials provided in this document.

---

Document Version: 1.0  
Last Updated: March 26, 2026  
Prepared for: Google Play Store Submission
